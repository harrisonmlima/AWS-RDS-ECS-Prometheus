provider "aws" {
  region = "us-east-1"
}

locals {
  aws_region   = "us-east-1"
  imagem       = "233181867717.dkr.ecr.us-east-1.amazonaws.com/web-ecr:latest"
  imagem-prometheus = "233181867717.dkr.ecr.us-east-1.amazonaws.com/prometheus:latest"
  imagem-alert-manager = "233181867717.dkr.ecr.us-east-1.amazonaws.com/alertmanager:0.26.0"
  service_name = "kube-news"
  service_port = 8080
  service_port-prometheus = 9090
  service_port-alertmanager = 9093
}

resource "aws_db_instance" "rds" {
  identifier             = "postgresdb"
  db_name                = "postgresdb"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "15.3"
  username               = "postgresuser"
  password               = "postgrespwd"
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db-sg.id]
  parameter_group_name   = aws_db_parameter_group.dbpg.name
  availability_zone      = "us-east-1a"
  publicly_accessible    = false
  skip_final_snapshot    = true
}

resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = "web-ecs"
  tags = {
    Name = "web-ecs"
  }
}

resource "aws_ecs_task_definition" "aws-ecs-task" {
  family = "web-task"

  container_definitions = <<DEFINITION
  [
    {
      "name": "${local.service_name}",
      "image": "${local.imagem}",
      "environment": ${jsonencode(
  [
    {
      "name" : "DB_HOST",
      "value" : "${aws_db_instance.rds.address}"
    },
    {
      "name" : "DB_DATABASE",
      "value" : "${aws_db_instance.rds.db_name}"
    },
    {
      "name" : "DB_USERNAME",
      "value" : "${aws_db_instance.rds.username}"
    },
    {
      "name" : "DB_PASSWORD",
      "value" : "${aws_db_instance.rds.password}"
    }
])},
      "essential": true,
      "portMappings": [
        {
          "containerPort": ${local.service_port},
          "hostPort": ${local.service_port}
        }
      ],
      "cpu": 512,
      "memory": 1024,
      "networkMode": "awsvpc"
    }
  ]
  DEFINITION

requires_compatibilities = ["FARGATE"]
network_mode             = "awsvpc"
memory                   = "1024"
cpu                      = "512"
execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn

tags = {
  Name = "web-ecs-td"
}
depends_on = [aws_db_instance.rds]
}

data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.aws-ecs-task.family
}

resource "aws_ecs_service" "aws-ecs-service" {
  name            = "${local.service_name}-service"
  cluster         = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition = "${aws_ecs_task_definition.aws-ecs-task.family}:${max(aws_ecs_task_definition.aws-ecs-task.revision, data.aws_ecs_task_definition.main.revision)}"
  launch_type     = "FARGATE"
  desired_count   = 1
  network_configuration {
    subnets         = [aws_subnet.main-subnet-private-1a.id, aws_subnet.main-subnet-private-1b.id]
    security_groups = [aws_security_group.web-sg.id]
  }
  service_registries {
    registry_arn = "${aws_service_discovery_service.sds.arn}"
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = local.service_name
    container_port   = local.service_port
  }

}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [aws_ecs_service.aws-ecs-service]

  create_duration = "60s"
}


resource "aws_ecs_task_definition" "prometheus" {
  family = "prometheus"

  container_definitions = <<DEFINITION
  [
    {
      "name": "prometheus",
      "image": "${local.imagem-prometheus}",
      "entryPoint": [],
      
      "essential": true,
      "portMappings": [
        {
          "containerPort": ${local.service_port-prometheus},
          "hostPort": ${local.service_port-prometheus}
        }
      ],
      "cpu": 256,
      "memory": 512,
      "networkMode": "awsvpc"
    }
  ]
  DEFINITION

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn

  tags = {
    Name        = "prometheus-td"
  }
}

resource "aws_ecs_service" "prometheus" {
  name                 = "prometheus"
  cluster              = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition      = "${aws_ecs_task_definition.prometheus.family}:${max(aws_ecs_task_definition.prometheus.revision)}"
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true
  service_registries {
    registry_arn = "${aws_service_discovery_service.sds.arn}"
  }
  network_configuration {
    subnets         = [aws_subnet.main-subnet-private-1a.id, aws_subnet.main-subnet-private-1b.id]
    security_groups = [aws_security_group.web-sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group-prometheus.arn
    container_name   = "prometheus"
    container_port   = local.service_port-prometheus
  }

  depends_on = [time_sleep.wait_60_seconds]
}


resource "aws_ecs_task_definition" "alert-manager" {
  family = "alert-manager"

  container_definitions = <<DEFINITION
  [
    {
      "name": "alert-manager",
      "image": "${local.imagem-alert-manager}",
      "entryPoint": [],
      
      "essential": true,
      "portMappings": [
        {
          "containerPort": ${local.service_port-alertmanager},
          "hostPort": ${local.service_port-alertmanager}
        }
      ],
      "cpu": 256,
      "memory": 512,
      "networkMode": "awsvpc"
    }
  ]
  DEFINITION

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn

  tags = {
    Name        = "alert-manager-td"
  }
}

resource "aws_ecs_service" "alert-manager" {
  name                 = "alert-manager"
  cluster              = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition      = "${aws_ecs_task_definition.alert-manager.family}:${max(aws_ecs_task_definition.alert-manager.revision)}"
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true
  service_registries {
    registry_arn = "${aws_service_discovery_service.sds.arn}"
  }
  network_configuration {
    subnets         = [aws_subnet.main-subnet-private-1a.id, aws_subnet.main-subnet-private-1b.id]
    security_groups = [aws_security_group.web-sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group-alertmanager.arn
    container_name   = "alert-manager"
    container_port   = local.service_port-alertmanager
  }

  depends_on = [time_sleep.wait_60_seconds]
}