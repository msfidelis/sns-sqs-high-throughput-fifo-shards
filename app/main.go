package main

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"runtime"
	"strconv"
	"sync"
	"sync/atomic"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sns"
)

type Message struct {
	OrderID    string    `json:"order_id"`
	CustomerID string    `json:"customer_id"`
	ProductID  string    `json:"product_id"`
	Amount     float64   `json:"amount"`
	Status     string    `json:"status"`
	Timestamp  time.Time `json:"timestamp"`
}

type TestResult struct {
	Sent        int64
	Failed      int64
	ElapsedTime time.Duration
}

const limit = 1000
const workers = 80

// calculateShard calcula o shard baseado no hash consistente da chave
// Retorna um valor entre 0 e numShards-1
func calculateShard(key string, numShards int) (int, string) {
	// Criar hash SHA256 da chave
	hasher := sha256.New()
	hasher.Write([]byte(key))
	hashBytes := hasher.Sum(nil)

	// Converter para hex string para debug
	hashHex := hex.EncodeToString(hashBytes)

	// Usar os primeiros 4 bytes como um int32 para calcular o shard
	hashValue := uint32(hashBytes[0])<<24 | uint32(hashBytes[1])<<16 | uint32(hashBytes[2])<<8 | uint32(hashBytes[3])

	shard := int(hashValue % uint32(numShards))

	return shard, hashHex[:16] // Retorna shard e primeiros 16 chars do hash para debug
}

type HighPerformancePublisher struct {
	snsClient   *sns.SNS
	topicArn    string
	numWorkers  int
	rateLimiter chan struct{}
}

func NewHighPerformancePublisher(snsClient *sns.SNS, topicArn string) *HighPerformancePublisher {
	return &HighPerformancePublisher{
		snsClient:   snsClient,
		topicArn:    topicArn,
		numWorkers:  workers,
		rateLimiter: make(chan struct{}, limit),
	}
}

func main() {
	topicArn := os.Getenv("SNS_TOPIC_ARN")
	if topicArn == "" {
		log.Fatal("SNS_TOPIC_ARN environment variable is required")
	}

	numMessages := 50000 // Default optimized for testing
	if arg := os.Getenv("NUM_MESSAGES"); arg != "" {
		if n, err := strconv.Atoi(arg); err == nil {
			numMessages = n
		}
	}

	fmt.Printf("Topic ARN: %s\n", topicArn)
	fmt.Printf("Messages: %d\n", numMessages)
	fmt.Printf("Workers: %d\n", workers)
	fmt.Printf("CPU Cores: %d\n", runtime.NumCPU())
	fmt.Printf("Sharding: 3 shards (using CustomerID as shard key)\n")

	// Optimized AWS session
	sess, err := session.NewSession(&aws.Config{
		Region:     aws.String("us-east-1"),
		MaxRetries: aws.Int(1), // No retries for max speed
	})
	if err != nil {
		log.Fatalf("Failed to create AWS session: %v", err)
	}

	snsClient := sns.New(sess)
	publisher := NewHighPerformancePublisher(snsClient, topicArn)

	fmt.Println("\n🚀 Starting main load test...")
	result := publisher.testHighPerformance(numMessages)

	// Print detailed results
	fmt.Printf("\nPERFORMANCE RESULTS:\n")
	fmt.Printf("Sent: %d\n", result.Sent)
	fmt.Printf("Failed: %d\n", result.Failed)
	fmt.Printf("Total Time: %v\n", result.ElapsedTime)

	if result.ElapsedTime.Seconds() > 0 {
		rate := float64(result.Sent) / result.ElapsedTime.Seconds()
		fmt.Printf("Throughput: %.2f msg/s\n", rate)

		efficiency := (rate / limit) * 100 // limit is SNS FIFO theoretical max
		fmt.Printf("Efficiency: %.1f%% of SNS FIFO limit\n", efficiency)
	}

	successRate := float64(result.Sent) / float64(result.Sent+result.Failed) * 100
	fmt.Printf("Success Rate: %.2f%%\n", successRate)

	if result.Failed > 0 {
		fmt.Printf("Failed messages might be due to rate limiting\n")
	}

}

func (p *HighPerformancePublisher) testHighPerformance(numMessages int) TestResult {
	var sent, failed int64
	startTime := time.Now()

	// Buffered channel for work distribution
	workCh := make(chan int, p.numWorkers*4)

	// Worker pool with optimized goroutines
	var wg sync.WaitGroup
	for i := 0; i < p.numWorkers; i++ {
		wg.Add(1)
		go func(workerID int) {
			defer wg.Done()

			for msgIndex := range workCh {
				// Rate limiting - acquire token
				p.rateLimiter <- struct{}{}

				// Create optimized message
				message := Message{
					OrderID:    fmt.Sprintf("ORD-%08d", msgIndex),
					CustomerID: fmt.Sprintf("CUST-%04d", msgIndex%2000), // 2000 customers for variety
					ProductID:  fmt.Sprintf("PROD-%03d", msgIndex%200),  // 200 products
					Amount:     float64(10 + (msgIndex % 990)),          // Vary amounts
					Status:     "processing",
					Timestamp:  time.Now(),
				}

				messageJSON, _ := json.Marshal(message)

				// Calcular shard baseado no CustomerID para distribuição consistente
				// Usar CustomerID como chave de sharding para garantir que
				// mensagens do mesmo cliente sempre vão para o mesmo shard
				shardKey := message.CustomerID
				shard, hashHex := calculateShard(shardKey, 3) // 3 shards/SQS

				// Smart grouping - usar shard no groupID para distribuição adequada
				groupID := fmt.Sprintf("shard-%d-group-%d", shard, msgIndex%10) // 10 groups por shard

				// Optimized deduplication ID
				dedupID := fmt.Sprintf("%08d-%d", msgIndex, time.Now().UnixNano())

				input := &sns.PublishInput{
					TopicArn:               aws.String(p.topicArn),
					Message:                aws.String(string(messageJSON)),
					MessageGroupId:         aws.String(groupID),
					MessageDeduplicationId: aws.String(dedupID),
					MessageAttributes: map[string]*sns.MessageAttributeValue{
						"shard": {
							DataType:    aws.String("String"),
							StringValue: aws.String(fmt.Sprintf("%d", shard)),
						},
						"hash": {
							DataType:    aws.String("String"),
							StringValue: aws.String(hashHex),
						},
					},
				}

				// Fast publish with timeout
				ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
				_, err := p.snsClient.PublishWithContext(ctx, input)
				cancel()

				if err != nil {
					fmt.Println(err.Error())
					atomic.AddInt64(&failed, 1)
				} else {
					atomic.AddInt64(&sent, 1)
				}

				// Real-time progress (every 500 messages) with shard info
				currentSent := atomic.LoadInt64(&sent)
				if currentSent%500 == 0 && currentSent > 0 {
					elapsed := time.Since(startTime)
					rate := float64(currentSent) / elapsed.Seconds()
					fmt.Printf("📈 %d/%d (%.1f msg/s, %.1fs elapsed) [Shard: %d, Key: %s]\n",
						currentSent, numMessages, rate, elapsed.Seconds(), shard, shardKey)
				}

				// Release rate limiter token
				<-p.rateLimiter
			}
		}(i)
	}

	// Feed work to workers as fast as possible
	go func() {
		defer close(workCh)
		for i := 0; i < numMessages; i++ {
			workCh <- i
		}
	}()

	// Wait for all workers to complete
	wg.Wait()

	return TestResult{
		Sent:        atomic.LoadInt64(&sent),
		Failed:      atomic.LoadInt64(&failed),
		ElapsedTime: time.Since(startTime),
	}
}
