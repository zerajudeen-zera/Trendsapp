# Deployed The application successfully to EKS cluster using jenkins to build and automate the workflow.

Cloned the repo and created a docker image to verify whether the application is running fine.

Pushed the docker image to docker hub.

setup an ec2 machine with a dedicated VPC, IAM using terraform script
then ran 
terraform init
terraform plan
terraform apply

once the infrastructure was set up

then ran eksctl commands to create and configure EKS cluster

Then using the jenkins installedd on EC2 created by main.tf ran created a pipeline in Jenkins.
the pipeline will be triggered automatically whenever there is a commit/push to the githubrepo

the application will be containerized and build, pushed and deployed to EKS using a jenkins declarative pipeline script from github.

All the SS are attached here

https://docs.google.com/document/d/1sMPNZT__NuAHpyqGq7R8tcZgZ8ZHwgaUnHBaDpN60ws/edit?tab=t.0#heading=h.om483ueayxd7
