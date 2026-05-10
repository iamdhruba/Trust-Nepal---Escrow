#!/bin/bash
# inject_prod_secrets.sh
# 
# This script securely updates the placeholder values created by Terraform
# in AWS Secrets Manager with actual production credentials.
# Run this from a secure machine with AWS CLI access.
# DO NOT COMMIT ACTUAL SECRETS.

set -e

echo "🔒 NepalTrust Production Secrets Injector"
echo "Make sure you are authenticated with the production AWS account."

# eSewa
echo "Updating eSewa Production Credentials..."
read -sp "Enter eSewa secret_key: " ESEWA_SECRET
echo ""
aws secretsmanager put-secret-value \
  --secret-id "nepaltrust/esewa/production" \
  --secret-string "{\"secret_key\":\"${ESEWA_SECRET}\",\"product_code\":\"NEPALTRUST_PROD\"}" \
  --region ap-south-1
echo "✅ eSewa updated."

# Khalti
echo "Updating Khalti Production Credentials..."
read -sp "Enter Khalti live_secret_key: " KHALTI_SECRET
echo ""
read -sp "Enter Khalti public_key: " KHALTI_PUB
echo ""
aws secretsmanager put-secret-value \
  --secret-id "nepaltrust/khalti/production" \
  --secret-string "{\"live_secret_key\":\"${KHALTI_SECRET}\",\"public_key\":\"${KHALTI_PUB}\"}" \
  --region ap-south-1
echo "✅ Khalti updated."

# connectIPS
echo "Updating connectIPS Production Credentials..."
read -sp "Enter connectIPS credential_name: " CIPS_CRED
echo ""
read -sp "Enter connectIPS app_id: " CIPS_APP_ID
echo ""
read -sp "Enter connectIPS app_name: " CIPS_APP_NAME
echo ""
read -sp "Enter connectIPS username: " CIPS_USERNAME
echo ""
read -sp "Enter connectIPS password: " CIPS_PASSWORD
echo ""
echo "Please place the RSA private key in connectips_private.key in this directory."
read -p "Press Enter when ready..."
if [ -f "connectips_private.key" ]; then
  CIPS_RSA_KEY=$(cat connectips_private.key | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g')
  
  JSON_PAYLOAD="{\"credential_name\":\"${CIPS_CRED}\",\"app_id\":\"${CIPS_APP_ID}\",\"app_name\":\"${CIPS_APP_NAME}\",\"username\":\"${CIPS_USERNAME}\",\"password\":\"${CIPS_PASSWORD}\",\"private_key\":\"${CIPS_RSA_KEY}\"}"
  
  aws secretsmanager put-secret-value \
    --secret-id "nepaltrust/connectips/production" \
    --secret-string "${JSON_PAYLOAD}" \
    --region ap-south-1
  
  # Clean up the key file securely
  rm connectips_private.key
  echo "✅ connectIPS updated."
else
  echo "❌ Error: connectips_private.key not found. Skipping connectIPS."
fi

echo "🎉 All production secrets have been securely injected into AWS Secrets Manager."
