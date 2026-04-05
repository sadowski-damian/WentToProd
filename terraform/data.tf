# List all available AZs in our region
data "aws_availability_zones" "available" {
  state = "available"
}

# Policy document for our EC2 instances
data "aws_iam_policy_document" "ec2-assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2-role-polices" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = ["arn:aws:ssm:*:*:parameter/prod/*"]
  }
}

data "aws_iam_policy_document" "prometheus-ec2-discovery" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
  }
}
