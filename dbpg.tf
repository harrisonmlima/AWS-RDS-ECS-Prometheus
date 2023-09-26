resource "aws_db_parameter_group" "dbpg" {
  name   = "postdb"
  family = "postgres15"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}