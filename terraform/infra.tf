# ASG Launch template
resource "aws_launch_template" "ec2-launch-template" {
  name                   = "ec2-launch-template"
  update_default_version = true

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2-instance-profile.name
  }

  image_id      = var.amazon-linux-2023-6_1-AMI
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.security-group-ec2.id]
  }


  user_data = filebase64("${path.module}/../userDataEC2.sh")

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "EC2-instance-ASG"
    }
  }
}

# ASG
resource "aws_autoscaling_group" "main-asg" {
  availability_zones = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1

  launch_template {
    id      = aws_launch_template.ec2-launch-template.id
    version = "$Latest"
  }
}