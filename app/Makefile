.PHONY: build run test-small test-medium test-large clean

# Build the application
build:
	@echo "🔨 Building SNS FIFO load test..."
	cd app && go build -o sns-load-test main.go

# Quick test with 1000 messages
test-small: build
	@echo "🧪 Running small load test (1000 messages)..."
	cd app && SNS_TOPIC_ARN="$(SNS_TOPIC_ARN)" NUM_MESSAGES=1000 ./sns-load-test

# Medium test with 5000 messages
test-medium: build
	@echo "🚀 Running medium load test (5000 messages)..."
	cd app && SNS_TOPIC_ARN="$(SNS_TOPIC_ARN)" NUM_MESSAGES=5000 ./sns-load-test

# Large test with 20000 messages
test-large: build
	@echo "💥 Running large load test (20000 messages)..."
	cd app && SNS_TOPIC_ARN="$(SNS_TOPIC_ARN)" NUM_MESSAGES=20000 ./sns-load-test

# Custom test
test-custom: build
	@echo "⚡ Running custom load test..."
	cd app && SNS_TOPIC_ARN="$(SNS_TOPIC_ARN)" NUM_MESSAGES="$(NUM_MESSAGES)" ./sns-load-test

# Run with default settings
run: build
	@echo "🚀 Running default load test..."
	cd app && SNS_TOPIC_ARN="$(SNS_TOPIC_ARN)" ./sns-load-test

# Clean build artifacts
clean:
	@echo "🧹 Cleaning..."
	rm -f app/sns-load-test

# Help
help:
	@echo "📖 Available commands:"
	@echo "  make build          - Build the application"
	@echo "  make test-small     - Test with 1,000 messages"
	@echo "  make test-medium    - Test with 5,000 messages"
	@echo "  make test-large     - Test with 20,000 messages"
	@echo "  make test-custom    - Test with custom NUM_MESSAGES"
	@echo "  make run            - Run with default settings"
	@echo "  make clean          - Clean build artifacts"
	@echo ""
	@echo "📋 Required environment variables:"
	@echo "  SNS_TOPIC_ARN       - ARN of the SNS FIFO topic"
	@echo ""
	@echo "📋 Optional environment variables:"
	@echo "  NUM_MESSAGES        - Number of messages to send"
	@echo ""
	@echo "🚀 Examples:"
	@echo "  SNS_TOPIC_ARN=arn:aws:sns:us-east-1:123:topic.fifo make test-medium"
	@echo "  SNS_TOPIC_ARN=arn:aws:sns:us-east-1:123:topic.fifo NUM_MESSAGES=50000 make test-custom"