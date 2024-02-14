# tf-gcp-infra
A Terraform Repository to handle infrastructure for GCP services

Set up Google Cloud (MAC)
>  sudo tar -xvzf google-cloud-cli-463.0.0-darwin-x86_64.tar.gz -C /usr/local
>  cd /usr/local/google-cloud-sdk
>  ./install.sh
>  gcloud auth login

Run script to disable services not required:
> ./disable_services.sh

Install Terraform (MAC)
> brew tap hashicorp/tap
> brew install hashicorp/tap/terraform
> brew upgrade hashicorp/tap/terraform
> terraform -help

Initialise a terraform repo with main.tf file:
> terraform init
> terrraform validate
> terraform plan
> terraform apply

To destroy the resouce
> terraform destroy

Terraofrm credenrial
> gcloud auth application-default login
