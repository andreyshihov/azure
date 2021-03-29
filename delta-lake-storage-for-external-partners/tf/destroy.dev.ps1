# Destroy Step 2
Set-Location -Path ./step2/dev/ #-PassThru
terraform destroy -auto-approve

# Destroy Step 1
Set-Location -Path ../../step1/ #-PassThru
terraform destroy -auto-approve

# Go Home
Set-Location ../