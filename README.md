# rds-postgres-slowquery-to-es

[AWS SAM](https://aws.amazon.com/serverless/sam/) project that sends RDS(PostgreSQL) slowqueries from CloudWatch Logs to Elasticsearch.

## Setup

```sh
#pip install awscli
#pip install aws-sam-cli (>= 0.35.0)
#aws s3 mb aws s3://s3_bucket_for_sam_app
bundle install
bundle exec rake docker:lambda-ruby-bundle:build
bundle exec rake sam:bundle
bundle exec rake pt-fingerprint:download

cp template.yaml.sample template.yaml
vi template.yaml # Fix Role/ELASTICSEARCH_URL
```

### Environment variables

```sh
export AWS_DEFAULT_REGION=ap-northeast-1
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export S3_BUCKET=... # e.g. S3_BUCKET=s3_bucket_for_sam_app
```

### Setup AWS resources using [Terraform](https://www.terraform.io)

```sh
cd terraform
cp terraform.tfvars.sample terraform.tfvars
vi terraform.tfvars
terraform init
terraform plan
terraform apply

# After deploying SAM app
vi cloudwatch_logs.tf
# Uncomment aws_cloudwatch_log_subscription_filter.sam_rds_postgresql_slowquery_to_es
terraform plan
terraform apply
```

## Invoke Lambda locally

```sh
docker-compose up -d
bundle exec rake sam:local:invoke
open http://localhost:5601
```

## Run tests

TODO:

## Deploy

```sh
bundle exec rake sam:deploy-noop
bundle exec rake sam:deploy
```

## Invoke Lambda remotely

```sh
# tail -f function log
sam logs -n sam-rds-postgresql-slowquery-to-es -t
```

```sh
bundle exec rake sam:invoke
```

## Delete AWS resources

```sh
aws cloudformation delete-stack --stack-name sam-rds-postgresql-slowquery-to-es
cd terraform
terraform destroy
```
