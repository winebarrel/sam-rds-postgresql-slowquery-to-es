resource "aws_rds_cluster_parameter_group" "slowquery_source_dbcluster_aurora_postgresql" {
  name        = "slowquery-source-dbcluster-aurora-postgresql"
  description = "slowquery-source-dbcluster-aurora-postgresql"
  family      = "aurora-postgresql10"

  parameter {
    name         = "log_min_duration_statement"
    value        = "1000"
    apply_method = "immediate"
  }
}

resource "aws_db_parameter_group" "slowquery_source_aurora_postgresql" {
  name        = "slowquery-source-aurora-postgresql"
  family      = "aurora-postgresql10"
  description = "slowquery-source-aurora-postgresql"
}
