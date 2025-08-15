#!/bin/bash
# AWS Connection Diagnostics

echo "🔍 AWS Connection Diagnostics"
echo "=============================="

echo "1. Checking AWS CLI configuration..."
aws configure list

echo -e "\n2. Testing AWS credentials..."
echo "Attempting to get caller identity..."

if aws sts get-caller-identity; then
    echo "✅ AWS credentials are valid!"
    
    echo -e "\n3. Testing S3 access..."
    echo "Listing S3 buckets..."
    if aws s3 ls; then
        echo "✅ S3 access works!"
        
        echo -e "\n4. Testing specific bucket access..."
        echo "Trying to access divvybikes-dev-bronze-96wb3c9c..."
        if aws s3 ls s3://divvybikes-dev-bronze-96wb3c9c/; then
            echo "✅ Can access Divvy Bikes S3 bucket!"
        else
            echo "❌ Cannot access Divvy Bikes S3 bucket (permission denied)"
            echo "This IAM user needs S3 permissions for the divvybikes bucket"
        fi
    else
        echo "❌ No S3 access (permission denied)"
    fi
    
else
    echo "❌ AWS credentials are invalid or expired"
    echo ""
    echo "Possible solutions:"
    echo "1. Run 'aws configure' with valid access keys"
    echo "2. Check that the access keys are active in the AWS IAM console"
    echo "3. Verify the access keys were entered correctly"
fi

echo -e "\n📝 Current credentials show as:"
aws configure get aws_access_key_id
echo "Secret key: [hidden for security]"
echo "Region: $(aws configure get region)"
