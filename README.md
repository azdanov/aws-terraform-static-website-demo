# AWS Terraform Static Website Demo

This is a demo of how to use Terraform to host a static website on AWS.
Using S3 and CloudFront and Terraform automation.
The end result is a personal alternative to Vercel or Netlify.

You can read the full blog post on https://azdanov.dev/articles/aws-terraform-static-website

## Pre-requisites

- [Terraform](https://www.terraform.io/downloads.html) installed.
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) installed.
- AWS credentials configured.
- Domain name registered with [Route53](https://aws.amazon.com/route53/).
- [S3 bucket](https://aws.amazon.com/s3/) manually created to store Terraform state.
- [DynamoDB table](https://aws.amazon.com/dynamodb/) manually created to lock Terraform state.

## What will Terraform create?

- [S3 bucket](https://aws.amazon.com/s3/) created to store the website files.
- [CloudFront](https://aws.amazon.com/cloudfront/) distribution created to serve the website.
- [ACM](https://aws.amazon.com/certificate-manager/) SSL certificate for CloudFront.
- [Route53](https://aws.amazon.com/route53/) hosted zone created to manage the domain name, it will have CloudFront and ACM connected to custom domain.

