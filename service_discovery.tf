
resource "aws_service_discovery_private_dns_namespace" "nome" {
  name = "dnsname"
  description = "Dominio de todos os serviços"
  vpc = aws_vpc.main.id
}

resource "aws_service_discovery_service" "sds" {
  name = "sds"
  dns_config {
    namespace_id = "${aws_service_discovery_private_dns_namespace.nome.id}"
    routing_policy = "MULTIVALUE"
    dns_records {
      ttl = 10
      type = "A"
    }
  }
  health_check_custom_config {
    failure_threshold = 5
  }
}