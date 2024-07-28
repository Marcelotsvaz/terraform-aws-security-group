output id {
	value = aws_security_group.main.id
	description = "ID of the security group."
}

output name {
	value = var.name
	description = "Name of the security group."
}