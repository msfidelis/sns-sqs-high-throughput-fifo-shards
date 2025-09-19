#!/bin/bash

# Quick test script for SNS FIFO High Throughput
# Usage: ./quick-test.sh [topic-arn] [num-messages]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEFAULT_MESSAGES=5000

# Get topic ARN from terraform output or parameter
if [ -z "$1" ]; then
    echo -e "${BLUE}🔍 Getting topic ARN from Terraform...${NC}"
    TOPIC_ARN=$(cd .. && terraform output -raw sns_fifo_topic_arn 2>/dev/null || echo "")
    
    if [ -z "$TOPIC_ARN" ]; then
        echo -e "${RED}❌ Error: Could not get topic ARN from Terraform output${NC}"
        echo -e "${YELLOW}💡 Usage: $0 [topic-arn] [num-messages]${NC}"
        echo -e "${YELLOW}💡 Or make sure Terraform is applied with outputs available${NC}"
        exit 1
    fi
else
    TOPIC_ARN="$1"
fi

# Get number of messages
NUM_MESSAGES="${2:-$DEFAULT_MESSAGES}"

echo -e "${BLUE}🚀 SNS FIFO High Performance Load Test${NC}"
echo -e "${BLUE}📡 Topic ARN: ${TOPIC_ARN}${NC}"
echo -e "${BLUE}📦 Messages: ${NUM_MESSAGES}${NC}"
echo ""

# Build the application
echo -e "${YELLOW}🔨 Building application...${NC}"
cd app
go build -o sns-load-test main.go

# Run the test
echo -e "${GREEN}⚡ Starting load test...${NC}"
echo ""

SNS_TOPIC_ARN="$TOPIC_ARN" NUM_MESSAGES="$NUM_MESSAGES" ./sns-load-test

# Cleanup
rm -f sns-load-test

echo ""
echo -e "${GREEN}✅ Load test completed!${NC}"
echo -e "${BLUE}💡 To run different test sizes:${NC}"
echo -e "${BLUE}   Small (1k):   $0 $TOPIC_ARN 1000${NC}"
echo -e "${BLUE}   Medium (5k):  $0 $TOPIC_ARN 5000${NC}"
echo -e "${BLUE}   Large (20k):  $0 $TOPIC_ARN 20000${NC}"
echo -e "${BLUE}   Extreme (50k): $0 $TOPIC_ARN 50000${NC}"