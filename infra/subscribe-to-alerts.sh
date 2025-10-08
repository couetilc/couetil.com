#!/bin/bash
# Subscribe to SNS alert topics for www.couetil.com infrastructure
#
# Usage: ./subscribe-to-alerts.sh <email-address>
#
# This script subscribes the provided email address to both CloudWatch alerts
# and billing alerts SNS topics. You'll receive confirmation emails that must
# be clicked to complete the subscription.

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <email-address>"
  echo ""
  echo "Example: $0 your@email.com"
  exit 1
fi

EMAIL="$1"

# Validate email format (basic check)
if [[ ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
  echo "Error: Invalid email address format"
  exit 1
fi

echo "Subscribing $EMAIL to alert topics..."
echo ""

# Get SNS topic ARNs from Terraform outputs
echo "Retrieving SNS topic ARNs..."
ALERTS_TOPIC=$(terraform output -raw sns_alerts_topic_arn 2>/dev/null)
BILLING_TOPIC=$(terraform output -raw sns_billing_alerts_topic_arn 2>/dev/null)

if [ -z "$ALERTS_TOPIC" ] || [ -z "$BILLING_TOPIC" ]; then
  echo "Error: Could not retrieve SNS topic ARNs from Terraform outputs"
  echo "Make sure you've run 'terraform apply' first"
  exit 1
fi

echo "Found topics:"
echo "  - CloudWatch alerts: $ALERTS_TOPIC"
echo "  - Billing alerts: $BILLING_TOPIC"
echo ""

# Subscribe to CloudWatch alerts
echo "Subscribing to CloudWatch alerts..."
aws sns subscribe \
  --topic-arn "$ALERTS_TOPIC" \
  --protocol email \
  --notification-endpoint "$EMAIL" \
  --output json | jq -r '.SubscriptionArn // "Pending confirmation"'

# Subscribe to billing alerts
echo "Subscribing to billing alerts..."
aws sns subscribe \
  --topic-arn "$BILLING_TOPIC" \
  --protocol email \
  --notification-endpoint "$EMAIL" \
  --output json | jq -r '.SubscriptionArn // "Pending confirmation"'

echo ""
echo "✓ Subscription requests sent!"
echo ""
echo "Next steps:"
echo "  1. Check $EMAIL for two confirmation emails from AWS"
echo "  2. Click the 'Confirm subscription' links in both emails"
echo "  3. You'll start receiving alerts when thresholds are exceeded"
echo ""
echo "Note: Billing alerts require enabling 'Receive Billing Alerts' in AWS Console:"
echo "  AWS Billing → Billing Preferences → Receive Billing Alerts"
