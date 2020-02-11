data "aws_iam_policy_document" "rds_postgresql_slowquery_to_es_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_postgresql_slowquery_to_es" {
  name               = "rds-postgresql-slowquery-to-es"
  assume_role_policy = data.aws_iam_policy_document.rds_postgresql_slowquery_to_es_assume_role.json
}

resource "aws_iam_role_policy_attachment" "rds_postgresql_slowquery_to_es_aws_lambda_basic_execution_role" {
  role       = aws_iam_role.rds_postgresql_slowquery_to_es.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

output "RdsPostgresqlSlowqueryToEsFunction_IAM_Role" {
  value = aws_iam_role.rds_postgresql_slowquery_to_es.arn
}
