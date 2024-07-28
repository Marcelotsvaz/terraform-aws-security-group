variable vpc_id {
	description = "ID of the VPC where this security group will be created."
	type = string
}

variable name {
	description = "Name of the security group. Also used for describing relations in rules."
	type = string
}

variable tag_prefix {
	description = "Prefix for resource tags."
	type = string
}

variable allow_all_egress {
	description = "Create rules to allow all egress traffic."
	type = bool
	default = false
}

variable ingress_from {
	description = "Set of ingress rules."
	type = set(
		object( {
			enabled = optional( bool, true )
			
			name = string
			
			cidr_ipv4 = optional( string )
			cidr_ipv6 = optional( string )
			from_security_group = optional( object( {
				id = string
				name = string
			} ) )
			
			protocol = optional( string )
			port = optional( number )
			to_port = optional( number )
		} )
	)
	default = []
	
	validation {
		condition = alltrue( [
			for rule in var.ingress_from:
			( ( rule.cidr_ipv4 != null || rule.cidr_ipv6 != null ) && rule.from_security_group == null ) ||
			( rule.from_security_group != null && rule.cidr_ipv4 == null && rule.cidr_ipv6 == null )
		] )
		error_message = "`from_security_group` can't be used together with `cidr_ipv4` or `cidr_ipv6`."
	}
}