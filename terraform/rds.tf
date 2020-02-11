resource "aws_rds_cluster" "slowquery_source" {
  cluster_identifier              = "slowquery-source"
  engine                          = "aurora-postgresql"
  master_username                 = "postgres"
  master_password                 = "postgres"
  db_subnet_group_name            = var.db_subnet_group_name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.slowquery_source_dbcluster_aurora_postgresql.name
  skip_final_snapshot             = true
  apply_immediately               = true

  vpc_security_group_ids = [
    data.aws_security_group.default.id
  ]

  enabled_cloudwatch_logs_exports = [
    "postgresql",
  ]
}

resource "aws_rds_cluster_instance" "slowquery_source" {
  identifier              = "slowquery-source"
  cluster_identifier      = aws_rds_cluster.slowquery_source.id
  engine                  = aws_rds_cluster.slowquery_source.engine
  instance_class          = "db.t3.medium"
  db_parameter_group_name = aws_db_parameter_group.slowquery_source_aurora_postgresql.name
  publicly_accessible     = true
  apply_immediately       = true
}

output "RDS_ENDPOINT" {
  value = aws_rds_cluster.slowquery_source.endpoint
}
