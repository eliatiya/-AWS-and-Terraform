resource "aws_instance" "web_app" {
	count         = var.instance_count
	ami           = var.instance_ami
	instance_type = var.instance_type
	key_name = "develop"
	vpc_security_group_ids = [aws_security_group.public.id]
    subnet_id = "${element(aws_subnet.public_subnet.*.id, count.index)}"
	iam_instance_profile   = aws_iam_instance_profile.instance_profile.id
	user_data = local.user_data_nginx

    root_block_device {
		volume_size           = "10"
		volume_type           = "gp2"
		encrypted             = false
		delete_on_termination = true
	}
    ebs_block_device {
		device_name = "/dev/sdb"
		volume_size           = "10"
		volume_type           = "gp2"
		encrypted             = true
		delete_on_termination = true
	}

	tags = {
			name = "nginx_server-${count.index+1}"
		}
}
resource "aws_instance" "db_app" {

	count         = var.instance_count
	ami           = var.instance_ami
	instance_type = var.instance_type
	key_name = "develop"
	vpc_security_group_ids = [aws_security_group.private.id]
    subnet_id = "${element(aws_subnet.private_subnet.*.id, count.index)}"
  	user_data = local.user_data_db

    root_block_device {
		volume_size           = "10"
		volume_type           = "gp2"
		encrypted             = false
		delete_on_termination = true
	}

	tags = {
			name = "db-server-${count.index+1}"
		}
}