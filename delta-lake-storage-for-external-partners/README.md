# Solution Building Block (SBB): Enable secure data ingestion gateway capability for the External Parties (Customers)

## Part 1. Definition

Every business need secure and reliable way to receive data from its customers, partners or suppliers. They could be called - External Parties (EP). This data considered as Bronze Grade data, that is - it has to be validated and transformed before it can reach production analytics engines, AI/ML modeling tools, destination systems and data stores.

The SBB should be cost effective, easy to maintain and use available tools and services, including free, secure options. To comply with this principles, [Azure Storage Explorer](https://docs.microsoft.com/en-us/azure/vs-azure-tools-storage-manage-with-storage-explorer?tabs=windows) tool has been chosen to facilitate secure and reliable data upload capability.

## Solution's Architecture

![Architecture](./img/scope.PNG)

## Logical Interface Definition

The interface of the system implemented using defined directories structure in Data Lake's Hierarchical Name Space (directories) and special naming convention of the blobs (files) stored in it. Interface is defined by combined activities of Terraform script and Function App.

### External Party's interface (Front-End)

External Parties (EP) accessing Azure Data Lake using Azure Storage Explorer that provides access to EP's Home Directory. Home Directory contains specially defined directories allowing users to interact.

### System's interface (Back-End)

System responsible for data ingest, e.g. Azure Data Factory (ADF), regularly scanning defined folder for the new files to be processed.

### File naming convention

EPs' uploaded files should be renamed following defined naming convention. This naming convention should:

* guarantee unique files' naming in the organisation's global namespace
* contain meta-information allowing ADF map new data to the relevant EPs in the internal data stores

## Detailed Interface Definition

### Front-End Interface

After successful EP's authentication, its Home Directory contains following folders

* Incoming - drop-off zone for the new data files
* Report - Human readable data ingest results report for each data file
* OK - 0KB files indicating successful ingest
* Fail - 0KB files indication failed ingest

### Back-End Interface

Following containers defining Back-End interface

* Ingest - contains data files ready to be processed by data ingestion system
* Log - contains data file life cycle log in the scope of this SBB, mainly produced by Function App
* Archive - contains original EPs files for audit purposes

## Solution's Scope

This SBB focuses on deploying Azure cloud-native infrastructure capability allowing External Parties (EP) securely upload their data files into the organisation's data ingestion gateway. It is built with [Terraform](https://www.terraform.io/intro/index.html) and Azure Function Apps.

### It is expected to do

* Using Terraform capabilities

  * Deploy Azure Data Lake
  * Deploy secure *Service* Containers to be used by data transformation and ingestion tools e.g. Azure Data Factory. This is implementation of the Back-End interface
  * Deploy Security Groups for each EP based on the deployment environment e.g. do not deploy PROD Security Groups in DEV environment
  * Deploy secure *EPs'* Containers that can only be accessed by the members of specifically deployed Security Group (created earlier). This is implementation of the Front-End interface

* Using Azure Functions Apps capabilities

  * Ensure newly uploaded files renamed to contain appropriate meta-data in the file name and uniquely identifiable
  * Ensure newly uploaded files moved into appropriate location for further processing by data ingestion systems (Back-End interface) and archiving

* Using PowerShell capabilities (Terraform embedded idempotent script)

  * Ensure *EPs'* Containers include required directories implementing Front-End interface

### It expected NOT to do

* Update content of the files
* Exercise any validation and transformation activities on data files
* Move data files anywhere outside of the deployed Azure Data Lake

## What this solution CAN and CAN'T do (room for improvement)

### It can

* Deploy new Security Group for each EP. (Note *prevent_duplicate_names = true*)
* Deploy new tagged Resource Group
* Deploy new tagged Storage Account with enabled Hierarchical Name Space (Data Lake Store)
* Accept parameters for the deployment environment e.g. DEV, TEST, PROD
* Move originally uploaded EPs' files into Archive Container with *Archive access tier* enabled
* Move originally uploaded EPs' files into Ingest Container and rename them following appropriate naming convention defined by an interface (see above)

### It can't

* Use existing Security Groups. Use *terraform import* to converge states or change *resource* blocks to *data* blocks for Security Groups deployment
* Create new B2B Guest Users and add them to the Security Groups. This option is currently [unavailable](https://github.com/hashicorp/terraform-provider-azuread/issues/41) in Terraform
* Purging old files after expiration of the retention period

## Debatable decisions

### Data Lake Gen 2 vs Blob Storage

Pros and Cons are analyzed in the scope of this solution only. For overall comparison check-out [Introduction to Azure Data Lake Storage Gen2](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction) and [Introduction to Blob Storage](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction).

#### Azure Data Lake Gen 2 Pros and Cons

Pros | Cons
-----| -----
By design, it's a set of capabilities dedicated to data analytics | .
Various file formats suitable for ADF and HDInsights | .
Hierarchical namespace support | .
A superset of POSIX permissions support | .

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

## Workspace

At the moment, the workspace is running on a local machine in Visual Studio Code (VSC). Terraform commands are executed from VSC Terminal. It is enabled to run [Terraform using Azure PowerShell](https://docs.microsoft.com/en-us/azure/developer/terraform/get-started-powershell) capability. All code is tracked in Git and ready for DevSecOps

When running powershell scripts, regardless of workspace (local machine, CI/CD pipeline), PowerShell execution policies issue might occure. Solution might be found in [About PowerShell Execution Policies](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.1) article.

## Prerequisites

* [Visual Studio Code](https://code.visualstudio.com/) or another Development Environment
* Prepare your workspace environment by completing [Quickstart: Configure Terraform using Azure PowerShell](https://docs.microsoft.com/en-us/azure/developer/terraform/get-started-powershell) tutorial including terraform installation steps

## Part 2. Implementation

To be continued...

### Useful links

[Use PowerShell to manage directories and files in Azure Data Lake Storage Gen2](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-directory-file-acl-powershell)

[Run PowerShell from Terraform](https://markgossa.blogspot.com/2019/04/run-powershell-from-terraform.html)

[Azure Blob storage trigger for Azure Functions](https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-storage-blob-trigger?tabs=csharp#poison-blobs)

### Improvements (Standard Naming Convention)
terraform
├── main.tf
├── outputs.tf
├── terraform.tfvars
└── variables.tf
