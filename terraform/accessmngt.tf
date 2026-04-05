
resource "aws_iam_role" "ec2-role" {
  name               = "ec2-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ec2-assume_role.json
}

resource "aws_iam_instance_profile" "ec2-instance-profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2-role.name
}

resource "aws_iam_role_policy" "ec2-role-policy" {
  name = "ec2-role-policy"
  role = aws_iam_role.ec2-role.id
  
  policy = data.aws_iam_policy_document.ec2-role-polices.json
}