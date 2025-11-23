terraform {
  backend "s3" {
    bucket  = "terraform-state-tismed"
    key     = "frontend/admin.tfstate"
    region  = "us-east-1"
    encrypt = true
    use_lockfile = true
  }
}