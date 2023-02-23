variable "region" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "public_subnet" {
  type = number
}

variable "private_subnet" {
  type = number
}

variable "public_availability_zones" {
  type = number
}

variable "private_availability_zones" {
  type = number
}

variable "vpc_id" {
  type = number
}

variable "profile" {
  type = string
}

variable "ami_id" {
  type = string
}