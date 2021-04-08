# Solution Building Block (SBB): Enable secure data ingestion gateway capability for the External Parties (Customers)

> The work on this solution is still in progress

## Part 1. Definition

Every business need secure and reliable way to receive data from its customers, partners or suppliers. They could be called - External Parties (EP). This data considered as Bronze Grade data, that is - it has to be validated and transformed before it can reach production analytics engines, AI/ML modeling tools, destination systems and data stores.

The SBB should be cost effective, easy to maintain and use available tools and services, including free, secure options. To comply with this principles, [Azure Storage Explorer](https://docs.microsoft.com/en-us/azure/vs-azure-tools-storage-manage-with-storage-explorer?tabs=windows) tool has been chosen to facilitate secure and reliable data upload capability.

## Solution's Architecture

![Architecture](./img/scope.PNG)

## Logical Interface Definition

The interface of the system implemented using defined directories structure in Data Lake's Hierarchical Name Space (directories) and special naming convention of the blobs (files) stored in it. Interface is defined by combined activities of Terraform script and Function App.

### External Party's interface (Front-End)

External Parties (EP) accessing Azure Data Lake using Azure Storage Explorer that provides access to EP's Home Container. Home Container contains specially defined directories allowing users to interact.

### System's interface (Back-End)

System responsible for data ingest, e.g. Azure Data Factory (ADF), regularly scanning defined folder for the new files to be processed.

### File naming convention

EPs' uploaded files should be renamed following defined naming convention. This naming convention should:

* guarantee unique file naming in the organisation's global namespace
* contain meta-information allowing ADF map new data to the relevant EPs in the internal data stores

## Detailed Interface Definition

### Front-End Interface

After successful EP's authentication, its Home Container contains following directories

* Incoming - drop-off zone for the new data files
* Report - Human readable data ingest results report for each data file
* OK - 0KB files indicating successful ingest
* Fail - 0KB files indication failed ingest

### Back-End Interface

Following containers defining Back-End interface

* Ingest - contains data files ready to be processed by data ingestion system e.g. ADF
* Archive - contains original EPs files for audit purposes

## Solution's Scope

This SBB focuses on deploying Azure cloud-native infrastructure capability allowing External Parties (EP) securely upload their data files into the organisation's data ingestion gateway. It is built with [Terraform](https://www.terraform.io/intro/index.html) and Azure Function Apps.

### It is expected to do

* Using Terraform capabilities

  * Deploy Azure Data Lake, Application Service Plan, Function Apps, Security Groups Assignments, etc
  * Deploy secure *Service* Containers to be used by data transformation and ingestion tools e.g. Azure Data Factory. This is implementation of the Back-End interface
  * Deploy Security Groups for each EP based on the deployment environment e.g. do not deploy PROD Security Groups in DEV environment
  * Deploy secure *EPs'* Containers that can only be accessed by the members of specifically deployed Security Group (created earlier). This is implementation of the Front-End interface

* Using Azure Functions Apps capabilities

  * Ensure newly uploaded files renamed to contain appropriate meta-data in the file name and uniquely identifiable
  * Ensure newly uploaded files moved into appropriate location for further processing by data ingestion systems (Back-End interface) and archiving
  * Ensure *EPs'* Containers include required directories implementing Front-End interface

### It expected NOT to do

* Update content of the files
* Exercise any validation and transformation activities on data files
* Move data files anywhere outside of the deployed Azure Data Lake

## What this solution CAN and CAN'T do (room for improvement)

This solution will not be tested to process large files. This solution should be concidered as a prototype and proof-of-concept. Deciding to use it in production environment is at your own risk.

### It can

* Deploy new Security Group for each EP. (Note *prevent_duplicate_names = true*)
* Deploy new tagged Resource Group
* Deploy new tagged Storage Account with enabled Hierarchical Name Space (Data Lake Store)
* Deploy App Insights to analyze Function App activities
* Handle environment specific Terraform.tfvars files to support various deployment environment e.g. DEV, TEST, PROD
* Move originally uploaded EPs' files into Archive Container with *Archive access tier* enabled (not implemented yet)
* Move originally uploaded EPs' files into Ingest Container and rename them following appropriate naming convention defined by an interface (see above)

### It can't

* Use existing Security Groups. As a workaround, use *terraform import* to converge states or change *resource* blocks to *data* blocks for Security Groups deployment
* Create new B2B Guest Users and add them to the Security Groups. This option is currently [unavailable](https://github.com/hashicorp/terraform-provider-azuread/issues/41) in Terraform
* Purging old files after expiration of the retention period

## Debatable decisions

### IaC and CaC

This SBB logically separates Infrastructure Plane from Configuration Plane. The idea is to get all nessessary Infrastructure components to be deployed and maintained in Infrastructure Plane and Configuration Components to be deployed and maintained in Configuration Plane. Commands from Configuration Plane to Infrastructure Plane issued via Queue.

**Infrastructure Plane** suppose to ensure that all nesessary resources are available and frequent change to these resources is not expected.

**Configuration Plane** suppose to easier adapt to the standard change. The standard change is adding and removing new EP profiles in configuration file and Function App, then running terraform apply to deploy/remove Containers, Security Groups and Function Apps. It is designed to be smaller resposibility scope and easier to maintain.

### Data Lake Gen 2 vs Blob Storage

Pros and Cons are analyzed in the scope of this solution only. For overall comparison check-out [Introduction to Azure Data Lake Storage Gen2](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction) and [Introduction to Blob Storage](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction).

#### Azure Data Lake Gen 2 Pros and Cons

Pros | Cons
-----| -----
By design, it's a set of capabilities dedicated to data analytics | .
Various file formats suitable for ADF and HDInsights | .
Hierarchical namespace support | .
A superset of POSIX permissions support | .
Front-End interface is suitable for the automated integration | .

#### Azure Blog Storage Pros and Cons

Pros | Cons
-----| -----
. | By design, it's a object storage solution
. | Virtual directories

In case if basic user experience capabilities are enough for the EPs interation, then Hierarchical Namespace capability might be disable and Blog Storage can be used instead of Data Lake Gen 2 Storage.

### Hot vs Cool access tiers

#### All catalogs except Archive

Main expected capability of this SBB is to provide a secure gateway for EPs' data files transmission that doesn't require various copies of original files to be stored in it for a long period of time. In addition, access to this files is frequent and with high availability requirement for the data to be ingested ASAP. Based on this conclusion, all containers except Archive should be running on *Hot* access tier.

#### Archive catalog

To support audit requirements, all originally submitted files should be archived for potential analysis/investigation in the future. The volume of this data files is large, but access is rare and doesn't need to be immediate, therefore default access tier for the Archive catalog is *Archive*

### Archive & Log Catalogs

To reduce potential security vulnerability surface, Archive and Log catalogs could be deployed in a publically inaccessible data store.

### In-process vs Out-of-process (Isolated) Function App

This solution uses In-process Function App Implementation which imposes some fine-tune disadvantages. It is possible to implement it in Isolated process but potentially requires more coding as some features like Imperative Binding aren't available in Isolated mode. To get to know pros/cons and limitations of both modes read [Guide for running functions on .NET 5.0 in Azure](https://docs.microsoft.com/en-us/azure/azure-functions/dotnet-isolated-process-guide#differences-with-net-class-library-functions)

## Workspace

At the moment, the workspace is running on a local machine in Visual Studio Code (VSC). Terraform commands are executed from VSC Terminal. It is enabled to run [Terraform using Azure PowerShell](https://docs.microsoft.com/en-us/azure/developer/terraform/get-started-powershell) capability. All code is tracked in Git and ready for DevSecOps

When running powershell scripts, regardless of workspace (local machine, CI/CD pipeline), PowerShell execution policies issue might occure. Solution might be found in [About PowerShell Execution Policies](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.1) article.

## Prerequisites

* [Visual Studio Code](https://code.visualstudio.com/) or another Development Environment
* Prepare your workspace environment by completing [Quickstart: Configure Terraform using Azure PowerShell](https://docs.microsoft.com/en-us/azure/developer/terraform/get-started-powershell) tutorial including terraform installation steps

## Part 2. Implementation

To be continued...

* Add conclusion (mention shared service plan used in DEV Env)
* TerraformPrinciple account security review

## Known issues

* First time terraform scripts application might lead to Function App deployment hanging up in "Still creating..." state for the long time. Workaround: run _terraform apply_ command again.

Picture 1. Known issue 1.
![Known issue 1](./img/known_issue_2.PNG)

Picture 2. Known issue 1.
![Known issue 1](./img/fapp_init_failure.PNG)

### References

[Use PowerShell to manage directories and files in Azure Data Lake Storage Gen2](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-directory-file-acl-powershell)

[Azure Blob storage trigger for Azure Functions](https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-storage-blob-trigger?tabs=csharp#poison-blobs)

[Using Managed Identity between Azure Functions and Azure Storage](https://docs.microsoft.com/en-us/samples/azure-samples/functions-storage-managed-identity/using-managed-identity-between-azure-functions-and-azure-storage/)

[Authorize access to blob and queue data with managed identities for Azure resources](https://docs.microsoft.com/en-us/azure/storage/common/storage-auth-aad-msi)

[How to rename a blob file in Azure Blob Storage (using a code snippet)](https://github.com/Azure-Samples/storage-blobs-dotnet-rename-blob)