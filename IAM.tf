terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "iam_user_name" {
  description = "IAM user name to create"
  type        = string
  default     = "contractor-user"
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs the Contractors group can access"
  type        = list(string)
  default     = ["arn:aws:s3:::example-bucket"]
}

variable "eks_cluster_arns" {
  description = "List of EKS cluster ARNs the Contractors group can access"
  type        = list(string)
  default     = ["*"]
}

resource "aws_iam_group" "contractors" {
  name = "Contractors"
  path = "/contractors/"
}

resource "aws_iam_user" "contractor" {
  name = var.iam_user_name
  path = "/contractors/"
}

resource "aws_iam_user_group_membership" "contractor_membership" {
  user   = aws_iam_user.contractor.name
  groups = [aws_iam_group.contractors.name]
}

resource "aws_iam_policy" "contractors_access" {
  name        = "ContractorsAccessPolicy"
  description = "Custom access for Contractors group to EC2, S3, and EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2Access"
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RebootInstances",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyInstanceAttribute"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3BucketListAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = var.s3_bucket_arns
      },
      {
        Sid    = "S3ObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [for arn in var.s3_bucket_arns : "${arn}/*"]
      },
      {
        Sid    = "EKSAccess"
        Effect = "Allow"
        Action = [
          "eks:ListClusters",
          "eks:DescribeCluster",
          "eks:ListNodegroups",
          "eks:DescribeNodegroup",
          "eks:AccessKubernetesApi"
        ]
        Resource = var.eks_cluster_arns
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "contractors_attach" {
  group      = aws_iam_group.contractors.name
  policy_arn = aws_iam_policy.contractors_access.arn
}

output "iam_user_name" {
  value = aws_iam_user.contractor.name
}

output "iam_group_name" {
  value = aws_iam_group.contractors.name
}

output "policy_arn" {
  value = aws_iam_policy.contractors_access.arn
}