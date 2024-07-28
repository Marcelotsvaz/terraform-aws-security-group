resource aws_security_group main {
	vpc_id = var.vpc_id
	
	tags = {
		Name = "${var.name_prefix} ${var.name} Security Group"
	}
	
	lifecycle {
		create_before_destroy = true
	}
}


locals {
	unique_fields = [
		"cidr_ipv4",
		"cidr_ipv6",
		"from_security_group",
	]
	
	# Split rules that have more than one "unique field" defined.
	expanded_rules = flatten( [
		for field in local.unique_fields:
		[
			for rule in var.ingress_from:
			merge(
				rule,
				# Clear all unique fields.
				{ for null_field in local.unique_fields: null_field => null },
				# Set only the current one.
				{ "${field}" = lookup( rule, field ) },
			)
			if lookup( rule, field ) != null
		]
	] )
	
	rule_list = [
		for rule in local.expanded_rules:
		merge(
			rule,
			{
				source_name = coalesce(
					rule.cidr_ipv4,
					rule.cidr_ipv6,
					try( rule.from_security_group.name, null ),
				)
			},
		)
	]
	
	enabled_rule_map = {
		for rule in local.rule_list:
		lower(
			replace(
				"${rule.name}-from-${rule.source_name}-to-${var.name}",
				" ",
				"_",
			),
		) => rule
		if rule.enabled
	}
}


resource aws_vpc_security_group_ingress_rule main {
	for_each = local.enabled_rule_map
	
	security_group_id = aws_security_group.main.id
	
	description = "Allow ingress ${each.value.name} traffic from ${each.value.source_name} to ${var.name}."
	
	ip_protocol = coalesce( each.value.protocol, "all" )
	from_port = each.value.port
	to_port = coalesce( each.value.to_port, each.value.port )
	
	cidr_ipv4 = each.value.cidr_ipv4
	cidr_ipv6 = each.value.cidr_ipv6
	referenced_security_group_id = try( each.value.from_security_group.id, null )
	
	tags = {
		Name = "${each.value.name} (${each.value.source_name} to ${var.name}) SG Rule"
	}
}


resource aws_vpc_security_group_egress_rule all_from_group_to_all_ipv4 {
	count = var.allow_all_egress ? 1 : 0
	
	security_group_id = aws_security_group.main.id
	
	description = "Allow all egress traffic from ${var.name} to 0.0.0.0/0."
	
	ip_protocol = "all"
	cidr_ipv4 = "0.0.0.0/0"
	
	tags = {
		Name = "All (${var.name} to 0.0.0.0/0) SG Rule"
	}
}


resource aws_vpc_security_group_egress_rule all_from_group_to_all_ipv6 {
	count = var.allow_all_egress ? 1 : 0
	
	security_group_id = aws_security_group.main.id
	
	description = "Allow all egress traffic from ${var.name} to ::/0."
	
	ip_protocol = "all"
	cidr_ipv6 = "::/0"
	
	tags = {
		Name = "All (${var.name} to ::/0) SG Rule"
	}
}