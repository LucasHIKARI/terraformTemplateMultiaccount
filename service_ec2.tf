locals {
  ec2_name = coalesce(var.ec2_name, "${var.name}-EC2")
  ec2_tags = merge({
    Project = "${var.name}"
  }, var.ec2_tags, var.common_tags)
  user_data = <<-EOF
  #!/usr/bin/env bash
  cd /home/ec2-user
  aws s3 cp "s3://${module.s3_data_bucket.bucket.bucket_name}/server/server.zip" ./
  chown ec2-user:ec2-user server.zip
  unzip -o server.zip
  cd server
  chmod +x startup.sh watcher.sh update.sh
  chown -R ec2-user:ec2-user ./
  sudo -u ec2-user bash ./startup.sh
  sudo -u ec2-user bash ./watcher.sh
  EOF
}

module "ec2_instance" {
  source = "./modules/ec2"

  create        = true
  name          = local.ec2_name
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.ec2_instance_type
  instance_tags = local.ec2_tags
  key_name      = var.ec2_keyname

  availability_zone           = local.available_zones[var.ec2_instance_subnet_num]
  subnet_id                   = module.vpc.vpc.subnets[var.ec2_instance_subnet_num].id
  private_ip                  = local.ec2_instance_private_ip
  vpc_security_group_ids      = [module.vpc.vpc.security_group["EC2"].id]
  associate_public_ip_address = true

  instance_iam_profile = module.iam.service_profile[local.role_idx_ec2].name
  user_data            = join("\n", [local.user_data, file("./script/server_info.sh")])
}