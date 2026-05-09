output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "alb_arn" {
  value = aws_lb.this.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "alb_security_group_id" {
  description = "Security group ID attached to the ALB"
  value       = aws_security_group.alb.id
}
