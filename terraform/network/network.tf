# Creating VPC in eu-central-1, everything else lives inside this VPC
# CIDR block - defines IP address range for the entire VPC. 
# Also we add a tag to the resource, we can see that tag in the AWS Console
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# Creating public subnets in eu-central-1a and eu-central-1b
# Instead of writing one resource block per subnet, we loop over map defined in locals.
resource "aws_subnet" "public_subnet" {
  for_each          = local.public_subnets
  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = {
    Name = "public-subnet-${each.key}"
    type = "public"
  }
}

# Creating private subnets in eu-central-1a and eu-central-1b
# Instead of writing one resource block per subnet, we loop over map defined in locals.
resource "aws_subnet" "private_subnet" {
  for_each          = local.private_subnets
  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = {
    Name = "private-subnet-${each.key}"
    type = "private"
  }
}

# Creating internet gateway for our VPC
# This is the entry/exit point between VPC and public internet - without it, nothing inside our VPC can communicate with the outside world.
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "internet-gateway"
  }
}

# Creating route table for public subnets
# It defines a set of rules that tells AWS where to send packet when its destined for this IP range.
# Every subnet has to be associated with only one route table
# In this route table any traffic is going straight to the internet gateway
resource "aws_route_table" "public_subnets" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "public-subnets-route-table"
  }
}

# Creating association between public subnets and our public route table
# Again we loop over public subnets, but now over subnets that we created earlier - this links each subnet to the route table
resource "aws_route_table_association" "public_route_table_association" {
  for_each       = aws_subnet.public_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_subnets.id
}

# Creates an empty Security Group for the EC2 instances - rules are defined separately below to avoid circular dependency with LB security group
# EC2 will only accept traffic from ALB and monitoring instance, never directly from the internet
resource "aws_security_group" "security_group_ec2" {
  name        = "security_group_ec2"
  description = "Security group rules for ec2"
  vpc_id      = aws_vpc.main.id
}

# Creates an empty Security Group for the load balancer - this is the only resource in our infrastructure directly exposed to the internet
# Rules are defined separately below, it accepts HTTP and HTTPS from anywhere and forwards traffic to EC2 instances
resource "aws_security_group" "security_group_lb" {
  name        = "security_group_lb"
  description = "Security group rules for load balancer"
  vpc_id      = aws_vpc.main.id
}

# Creates an empty Security Group for the monitoring EC2 instance - it has no inbound rules at all
# Monitoring only needs outbound traffic to scrape metrics from EC2 instances and send alerts to Slack
resource "aws_security_group" "security_group_monitoring" {
  name        = "security_group_monitoring"
  description = "Security group rules for monitoring instance"
  vpc_id      = aws_vpc.main.id
}

# Creates an empty Security Group for the RDS instance - it only accepts PostgreSQL traffic from EC2 instances
# RDS is never reachable from the internet or from monitoring, only the application can connect to it
resource "aws_security_group" "security_group_rds" {
  name        = "security_group_rds"
  description = "Security group rules for rds"
  vpc_id      = aws_vpc.main.id
}

# EC2 rules - inbound from ALB and monitoring on app port, inbound from monitoring on node exporter port
resource "aws_vpc_security_group_ingress_rule" "ec2_from_lb" {
  security_group_id            = aws_security_group.security_group_ec2.id
  referenced_security_group_id = aws_security_group.security_group_lb.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ec2_from_monitoring_app" {
  security_group_id            = aws_security_group.security_group_ec2.id
  referenced_security_group_id = aws_security_group.security_group_monitoring.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ec2_from_monitoring_node_exporter" {
  security_group_id            = aws_security_group.security_group_ec2.id
  referenced_security_group_id = aws_security_group.security_group_monitoring.id
  from_port                    = 9100
  to_port                      = 9100
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ec2_all_outbound" {
  security_group_id = aws_security_group.security_group_ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ALB rules - inbound HTTP and HTTPS from internet
resource "aws_vpc_security_group_ingress_rule" "lb_http" {
  security_group_id = aws_security_group.security_group_lb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "lb_https" {
  security_group_id = aws_security_group.security_group_lb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "lb_all_outbound" {
  security_group_id = aws_security_group.security_group_lb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Monitoring rules - outbound all traffic so it can scrape metrics from EC2 instances and send alerts to Slack
resource "aws_vpc_security_group_egress_rule" "monitoring_all_outbound" {
  security_group_id = aws_security_group.security_group_monitoring.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# RDS rules - inbound PostgreSQL from EC2 only
resource "aws_vpc_security_group_ingress_rule" "rds_from_ec2" {
  security_group_id            = aws_security_group.security_group_rds.id
  referenced_security_group_id = aws_security_group.security_group_ec2.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

# Creating subnet group for RDS - it tells RDS which subnets it can use
# We pass both private subnets from different AZs - this is required for Multi-AZ deployment
resource "aws_db_subnet_group" "db_rds_subnet_group" {
  name       = "db-rds-subnet-group"
  subnet_ids = [aws_subnet.private_subnet[data.aws_availability_zones.available.names[0]].id, aws_subnet.private_subnet[data.aws_availability_zones.available.names[1]].id]

  tags = {
    Name = "RDS subnet group"
  }
}

# Creating Route53 hosted zone for our domain - this is where all DNS records for damiansadowski.cloud will live
resource "aws_route53_zone" "main" {
  name = "damiansadowski.cloud"
}

# Creating wildcard SSL/TLS certificate for our domain - it covers all subdomains like wenttoprod.damiansadowski.cloud
# We use DNS validation method - AWS will create a DNS record to prove we own the domain
# create_before_destroy - new certificate is created before old one is destroyed so there is no downtime
resource "aws_acm_certificate" "cert" {
  domain_name       = "*.damiansadowski.cloud"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Creating DNS record required for certificate validation - AWS needs this to verify we own the domain
# We take the validation options directly from the certificate resource and create the required DNS record in our hosted zone
resource "aws_route53_record" "site_cert_dns" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_type
  zone_id         = aws_route53_zone.main.id
  ttl             = 60
}

# Waits for the certificate to be fully validated - Terraform will stop here until AWS confirms the certificate is issued
resource "aws_acm_certificate_validation" "site_cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.site_cert_dns.fqdn]
}

# Creating CloudWatch log group for VPC Flow Logs - all network traffic in our VPC will be logged here
# retention_in_days - logs are automatically deleted after 30 days to keep costs low
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "VPC-FlowLogs"
  retention_in_days = 30
}

# IAM policy document that allows the VPC Flow Logs service to assume our role
data "aws_iam_policy_document" "vpc_flow_logs_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

# IAM policy document that grants permissions to write logs to CloudWatch
data "aws_iam_policy_document" "vpc_flow_logs_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    #tfsec:ignore:aws-iam-no-policy-wildcards
    resources = [
      aws_cloudwatch_log_group.vpc_flow_logs.arn,
      "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
    ]
  }
}

# Creating IAM role for VPC Flow Logs - this role allows the service to send logs to CloudWatch
resource "aws_iam_role" "vpc_flow_logs" {
  name               = "vpc-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.vpc_flow_logs_assume.json
}

# Attaching the policy to our role - without this the role would have no permissions to actually write logs
resource "aws_iam_role_policy" "vpc_flow_logs" {
  name   = "vpc-flow-logs-policy"
  role   = aws_iam_role.vpc_flow_logs.id
  policy = data.aws_iam_policy_document.vpc_flow_logs_policy.json
}

# Enabling VPC Flow Logs - records all inbound and outbound traffic in our VPC
# traffic_type ALL - captures both accepted and rejected traffic
resource "aws_flow_log" "main" {
  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
}

# Enabling GuardDuty, service that monitors for suspicious activity
# It automatically analyzes CloudTrail logs, VPC Flow Logs and DNS logs looking for threats
resource "aws_guardduty_detector" "main" {
  enable = true
}

# Creating KMS key for CloudTrail, all audit logs will be encrypted with this key
# enable_key_rotation, AWS automatically rotates the key every year
resource "aws_kms_key" "cloudtrail" {
  description             = "KMS key for CloudTrail"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# Attaching the policy to our KMS key without this nobody could use the key to encrypt or decrypt anything
resource "aws_kms_key_policy" "cloudtrail" {
  key_id = aws_kms_key.cloudtrail.id
  policy = data.aws_iam_policy_document.cloudtrail_kms.json
}

# IAM policy document for KMS key, it defines two principals that can use the key
# Root account gets full access, CloudTrail service can only generate data keys and describe the key
data "aws_iam_policy_document" "cloudtrail_kms" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["kms:GenerateDataKey*", "kms:DescribeKey"]
    resources = ["*"]
  }
}

# Enabling CloudTrail it records every API call made in our AWS account like who did it and when
# is_multi_region_trail captures events from all regions not just eu-central-1
# enable_log_file_validation, detects if log files were modified or deleted after creation
# Logs are encrypted with our KMS key and stored in S3 in cloudtrail/
resource "aws_cloudtrail" "main" {
  name                          = "main-trail"
  s3_bucket_name                = aws_s3_bucket.monitoring_config.id
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.cloudtrail.arn
}