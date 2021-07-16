# Terraform CloudFront Builder

This terraform script creates an AWS CloudFront website by building out the following infrastructure:

## ACM TLS Certificate
* This includes a DNS entry for domain validation

## Route53 DNS entries for:
* An `Apex` *A record alias* pointing to the newly created CloudFront domain
* * Example: `example.com`
* A `www` *CNAME record* also pointing the the CloudFront domain
* * Example: `www.example.com`

## S3 bucket
* Static web site hosting
* * Bucket name: `www.example.com`
* Bucket Versioning is enabled
* Logging is enable, using a predefined *logs* bucket
* * The *logs* bucket is defined in a `.tfvars` file *(see example below)*
* Bucket AES256 encryption
* An example `index.html` file will be uploaded

## S3 bucket permissions
* `Block public access` is enabled
* `Bucket Policy` allows access *only* from the newly created `CloudFront Origin Access Identity`

## CloudFront Origin Access Identity
* Used by the CloudFront Distribution
* Used by the S3 bucket permission policy

## CloudFront Distribution
* Use only North America and Europe *(lowest/free pricing tier)*
* Alternative domain names for:
* * The Apex - `example.com`
* * `www.example.com`
* Custom SSL certificate *(just created in ACM)*
* TLSv1.2_2021
* Standard logging enabled
* `Origins` - Used the newly created `CF OAI`
* `Viewer Protocol` - Redirect HTTP to HTTPS

## CloudFront Function
* The included `redirect.js` file will be used to redirect the following:
* * `www.example.com/something` *redirects to* `www.example.com/something/index.html`
___

## Example Config
* [example.tfvars](example.tfvars)
* To use this config, you would run: 
* * `tf init`
* * `tf validate`
* * `tf plan`
* * `tf apply -var-file="example.tfvars"`
* The `apply` command will take about 5 minutes to complete
