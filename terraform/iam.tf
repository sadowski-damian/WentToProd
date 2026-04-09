
resource "aws_iam_role" "ec2_role" {
  name               = "ec2-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy" "ec2_role_policy" {
  name = "ec2-role-policy"
  role = aws_iam_role.ec2_role.id

  policy = data.aws_iam_policy_document.ec2_role_polices.json
}

resource "aws_iam_role_policy_attachment" "ec2_role_policy_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_role" "ec2_role_prometheus" {
  name               = "ec2-role-prometheus"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_instance_profile" "ec2_instance_profile_prometheus" {
  name = "ec2-instance-profile-prometheus"
  role = aws_iam_role.ec2_role_prometheus.name
}

resource "aws_iam_role_policy_attachment" "ec2_role_policy_prometheus" {
  role       = aws_iam_role.ec2_role_prometheus.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "prometheus_ec2_discovery" {
  name   = "prometheus-ec2-discovery"
  role   = aws_iam_role.ec2_role_prometheus.id
  policy = data.aws_iam_policy_document.prometheus_ec2_discovery.json
} 