# tf-gcp-infra
    A repository to provision infrastructure for GCP services through Terraform.
    The IaC will provision the following Google Cloud Services - VPC, Compute Engine, Cloud SQL, Cloud Function, DNS, Load balancer, AutoScaler, SSL, Logging, CMEK.
    You will need to use your own terrafor.tfvars file with appropriate values to populate the variables

Set up Google Cloud (MAC)
> sudo tar -xvzf google-cloud-cli-463.0.0-darwin-x86_64.tar.gz -C /usr/local
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

Initialise a terraform repo and depploy:
> terraform init
> terrraform validate
> terraform plan
> terraform apply

To destroy the resouce
> terraform destroy

Terraofrm credential
> gcloud auth application-default login
