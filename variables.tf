variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "cidr_block" {

}
variable "availability_zones" {
  type = list(string)
}

variable "subnet_cidrs_public" {
  type = list(string)
}

variable "subnet_cidrs_private_app" {
  type = list(string)
}

variable "subnet_cidrs_private_db" {
  type = list(string)
}
