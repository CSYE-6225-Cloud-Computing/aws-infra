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

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type = string
}

variable "db_engine" {
  type = string
}

variable "db_version" {
  type = string
}

variable "rsa_public" {
  type      = string
  sensitive = true
}

variable "domain_name" {
  type = string
}