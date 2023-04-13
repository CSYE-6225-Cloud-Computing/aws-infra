# aws-infra

## CSYE6225: Network Structures & Cloud Computing

<br>
<strong>Milestone:</strong> Assignment 03 <br>
<strong>Developer:</strong> SaiMahith Chigurupati <br>
<strong>NUID:</strong> 002700539 <br>
<strong>Email:</strong> chigurupati.sa@northeastern.edu <br>
<br>

## Instruction to run the project

```
// initializing terraform
terraform init

//previewing the infrastructure
terraform plan

// creating the infrastructure in aws
terraform apply

```

## Sample Data

```
// provide cidr range
var.cidr_block  
    Enter a value: 10.0.0.0/16

// providing number of private availability zones required
var.private_availability_zones 
    Enter a value: 3

// providing number of private subnets to be created
var.private_subnet
    Enter a value: 3

// providing number of public availability zones required
var.public_availability_zones  
    Enter a value: 3

// providing number of public subnets to be created
var.public_subnet  
    Enter a value: 3
    
// region in which VPC gets created
var.region  
    Enter a value: us-east-1 || us-west-2

```

## Commands to import certificates

aws acm import-certificate \
--certificate fileb://demo_mahithchigurupati_me.crt \
--certificate-chain fileb://demo_mahithchigurupati_me.ca-bundle \
--private-key fileb://private.key \
--region us-east-1 \
--profile demo