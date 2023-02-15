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
var.cidr_block  
    Enter a value: 10.0.0.0/16

var.private_availability_zones 
    Enter a value: ["us-east-1a","us-east-1b","us-east-1c"]

var.private_subnet
    Enter a value: ["10.0.4.0/24","10.0.5.0/24","10.0.6.0/24"]

var.public_availability_zones  
    Enter a value: ["us-east-1a","us-east-1b","us-east-1c"]

var.public_subnet  
    Enter a value: ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
    
var.region  
    Enter a value: us-east-1

```
