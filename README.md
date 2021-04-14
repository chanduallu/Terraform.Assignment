

# Terraform.Assignment

Pre-requistes:

Configure terraform host machine with aws access/secret keys with default region as ap-south-east-1 to provision resources in AWS.
Create s3 bucket(terraform-sbx-s3) to store terraform backend.

The following the modules are used for this assignment and are referenced in terraform files :

EC2:
        alb,
        autoscaling,
        ec2-iam-role,
        ec2-intance,
        security group.

S3

VPC

Provisioning resources:

VPC:

    To create VPC Change Directory to sbx-vpc and execute terraform commands.
    
Provision a static Java application with High Availability:
    
    Change Directory to sbx-webserver and execute terraform commands which will provision alb, ec2 autoscaling and s3 buckets.
    
Terraform Commands:

    terraform init

    terraform plan

    terraform apply

Expected Output:

enter the alb dns in browser

![image](https://user-images.githubusercontent.com/36153046/114770806-7a211180-9d89-11eb-9e4c-d6d9ef619a20.png)

    
    
