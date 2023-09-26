resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db_subnet_group"
  subnet_ids = [aws_subnet.main-subnet-private-1a.id, aws_subnet.main-subnet-private-1b.id]

  tags = {
    Name = "db_subnet_group"
  }
}