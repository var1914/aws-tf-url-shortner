# URL Shortener

A serverless URL shortener built with Terraform and AWS, featuring API Gateway, Lambda, and DynamoDB.

## Architecture

Simple serverless setup: API Gateway → Lambda → DynamoDB. Handles URL creation with API key auth and public redirects.

## Project Structure

```
├── infra/terraform-deployments/
│   ├── main-api-gw.tf      # API Gateway config
│   ├── main-lambda.tf      # Lambda functions & IAM
│   ├── main-db.tf          # DynamoDB table
│   ├── main-monitoring.tf  # CloudWatch alarms
│   ├── locals.tf           # API configuration
│   ├── variables.tf        # Input variables
│   ├── outputs.tf          # Useful outputs
│   ├── providers.tf        # AWS provider & backend
│   └── versions.tf         # Terraform version constraints
├── src/
├── ├── create-url.ts           # URL creation Lambda
├── ├── redirect-url.ts         # URL redirect Lambda
├── package.json
└── README.md
```

## Quick Deploy

```bash
terraform init
terraform apply -var="environment=dev"
```

## Testing with cURL

**Creating short URL:**
```bash
curl -X POST https://your-api-id.execute-api.us-east-1.amazonaws.com/your-env-name/shorten \
  -H "Authorization: Bearer {API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://google.com"}'
```

**Testing:**
```bash
curl -I https://your-api-id.execute-api.us-east-1.amazonaws.com/your-env-name/short-id-which-you-got
```

**Expected responses:**
- Create: `201` with JSON containing `shortUrl` --> For Creating short URL
- Redirect: `302` with `Location` heade --> For Testing

## Future Enhancements

**Terraform Modules** - Break into reusable modules:
```
terraform-modules/
├── api-gateway/
├── lambda-function/
├── monitoring/
└── storage/
```

**Better Terraform** - More loops, less repetition:

**Security Layer** - Add WAF protection:

**Performance** - CloudFront CDN:

## Environment Variables:

Set these under dev.tfvar/prod.tfvar:
- `api_keys`: Comma-separated API keys
- `alert_email`: Your notification email
- `aws_region`: Target AWS region
- `envenvironment`: Environment Name

Note: 
- I have not added `api_keys` as part of git repo, just following best practise, but in your local setup you can add and deploy...
- In real world, keys are managed using secrets manager or vaults, but for demo and time constraint, I will add to future enhancements
- CORS OPTIONS method not defined in API Gateway - handled in Lambda, In production, consider adding OPTIONS method for better browser compatibility
- Need to Add AWS_ACCESS_KEY and AWS_SECRET_ACCESS_KEY secrets in github repo settings, to make CICD working
