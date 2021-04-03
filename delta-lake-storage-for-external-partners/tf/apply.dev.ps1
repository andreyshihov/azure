# Apply Step 1
Set-Location -Path ./step1/
terraform init
terraform apply -auto-approve

# Build the Function App
Set-Location -Path ../../func/
dotnet publish -o ./publish -c Release

# Apply Step 2
Set-Location -Path ../tf/step2/dev/
terraform init
terraform apply -auto-approve

# Go Home
Set-Location ../../
