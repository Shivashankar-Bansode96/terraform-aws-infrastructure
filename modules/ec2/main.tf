data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "this" {
  ami           = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.instance_type

  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl enable nginx
              systemctl start nginx

              cat > /usr/share/nginx/html/index.html <<'HTML'
              <html>
                <head>
                  <title>Terraform Dev Environment</title>
                </head>
                <body>
                  <h1>Hello from Terraform!</h1>
                  <p>Environment: ${var.environment}</p>
                  <p>Infrastructure managed with Terraform.</p>
                </body>
              </html>
              HTML
              EOF

  tags = {
    Name        = "${var.environment}-web-server"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "terraform-aws-infrastructure"
  }
}