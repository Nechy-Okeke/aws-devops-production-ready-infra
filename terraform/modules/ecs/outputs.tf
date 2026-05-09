output "ecs_cluster_id" {
  value = aws_ecs_cluster.this.id
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

# Used by ALB module for wiring (target group)
output "ecs_container_name" {
  value = aws_ecs_task_definition.app.family
}
