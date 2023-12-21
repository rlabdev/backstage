terraform {
  required_version = "1.5.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.20.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  profile = "sandbox"
}

terraform {
  backend "s3" {
    bucket = "backstage-bucket"
    key    = "aws-lambda/${{ values.name }}/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_caller_identity" "current" {}

data "aws_ecr_image" "this" {
  repository_name = "${{ values.name }}"
  most_recent     = true
}

locals {
  account = data.aws_caller_identity.current.account_id
}

module "lambda_function" {
  source                                  = "terraform-aws-modules/lambda/aws"
  version                                 = "6.0.1"
  function_name                           = "${{ values.name }}"
  description                             = "${{ values.description }}"
  timeout                                 = ${{ values.timeout }}
  cloudwatch_logs_retention_in_days       = 5
  ignore_source_code_hash                 = true
  create_role                             = true
  create_current_version_allowed_triggers = false
  create_function                         = true
  create_package                          = false
  image_uri                               = "222222222222.dkr.ecr.us-east-1.amazonaws.com/${{ values.name }}:${element(data.aws_ecr_image.this.image_tags, 0)}"
  package_type                            = "Image"
  memory_size                             = ${{ values.memory }}
  {%- if values.vpc %}
  vpc_subnet_ids                          = ["subnet-000000aaaaaa00000"]
  attach_network_policy                   = true
  vpc_security_group_ids                  = [aws_security_group.security_group.id]{% endif %}
}
