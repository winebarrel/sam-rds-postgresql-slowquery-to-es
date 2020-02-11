resource "aws_cloudwatch_log_group" "slowquery_source_postgresql" {
  name = "/aws/rds/cluster/${aws_rds_cluster.slowquery_source.id}/postgresql"
}

/* TODO: After deploying SAM app
data "aws_lambda_function" "sam_rds_postgresql_slowquery_to_es" {
  function_name = "sam-rds-postgresql-slowquery-to-es"
}

resource "aws_lambda_permission" "invoke_rds_postgresql_slowquery_to_es_from_slowquery_source_postgresql" {
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.sam_rds_postgresql_slowquery_to_es.function_name
  principal     = "logs.${data.aws_region.current.name}.amazonaws.com"
  source_arn    = aws_cloudwatch_log_group.slowquery_source_postgresql.arn
}

resource "aws_cloudwatch_log_subscription_filter" "rds_postgresql_slowquery_to_es" {
  name            = "LambdaStream_${data.aws_lambda_function.sam_rds_postgresql_slowquery_to_es.function_name}"
  distribution    = "ByLogStream"
  log_group_name  = aws_cloudwatch_log_group.slowquery_source_postgresql.name
  filter_pattern  = ""
  destination_arn = data.aws_lambda_function.sam_rds_postgresql_slowquery_to_es.arn
}
*/
