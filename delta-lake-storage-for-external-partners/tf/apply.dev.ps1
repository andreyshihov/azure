# Apply Step 1
Set-Location -Path ./step1/ #-PassThru
terraform init
terraform apply -auto-approve

# Apply Step 2
Set-Location -Path ../step2/dev/ #-PassThru
terraform init
terraform apply -auto-approve

# Go Home
Set-Location ../../
