using System;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Azure.Storage.Blobs;
using Azure.Storage.Files.DataLake;
using lib.Model;
using Azure.Identity;
using Azure;
using System.Collections.Generic;
using Azure.Storage.Blobs.Models;

namespace func
{
    class Common
    {
        public static string GetEnvironmentVariable(string name)
        {
            return Environment.GetEnvironmentVariable(name, EnvironmentVariableTarget.Process);
        }

        public static async Task InitContainerAsync(string containerName, ILogger log)
        {
            log.LogInformation($"Start to init container: {containerName}");

            string serviceEndpoint = string.Format("https://{0}.blob.core.windows.net/", Common.GetEnvironmentVariable("SA_NAME"));
            List<string> directories = new List<string> { "Incoming", "Ok", "Fail", "Report" };

            try
            {
                foreach (var directory in directories)
                {
                    DataLakeServiceClient dataLakeServiceClient = new DataLakeServiceClient(new Uri(serviceEndpoint), new DefaultAzureCredential());
                    DataLakeFileSystemClient dataLakeFileSystemClient = dataLakeServiceClient.GetFileSystemClient(containerName);
                    DataLakeDirectoryClient dataLakeDirectoryClient = dataLakeFileSystemClient.GetDirectoryClient(directory);
                    await dataLakeDirectoryClient.CreateIfNotExistsAsync();
                    log.LogInformation($"Initialisation complete: {containerName}");
                }
            }
            catch (RequestFailedException)
            {
                log.LogInformation($"Failed to complete container initialisation operation: {containerName}");
                throw;
            }
        }

        public static async Task DeleteBlobAsync(BlobMetadata blobMetadata, ILogger log)
        {
            log.LogInformation($"Delete queue process item: {blobMetadata}");

            string containerEndpoint = string.Format("https://{0}.blob.core.windows.net/{1}", Common.GetEnvironmentVariable("SA_NAME"), blobMetadata.ContainerName);

            var blobPathAndName = $"{blobMetadata.BlobPath}/{blobMetadata.BlobName}";

            BlobContainerClient sourceBlobContainerClient = new BlobContainerClient(new Uri(containerEndpoint), new DefaultAzureCredential());

            try
            {
                if (await sourceBlobContainerClient.ExistsAsync())
                {
                    BlobClient blob = sourceBlobContainerClient.GetBlobClient(blobPathAndName);

                    if (await blob.ExistsAsync())
                    {
                        await blob.DeleteAsync();
                        log.LogInformation($"Blob {blobMetadata.BlobName} is deleted");
                    }
                }
            }
            catch (RequestFailedException)
            {
                log.LogInformation($"Failed to complete blob deleting operation: {blobMetadata}");
                throw;
            }
        }

        public static async Task ArchiveBlobAsync(string blobName, ILogger log)
        {
            log.LogInformation($"Archiving blob: {blobName}");

            string containerEndpoint = string.Format("https://{0}.blob.core.windows.net/archive", Common.GetEnvironmentVariable("SA_NAME"));

            BlobContainerClient sourceBlobContainerClient = new BlobContainerClient(new Uri(containerEndpoint), new DefaultAzureCredential());

            try
            {
                if (await sourceBlobContainerClient.ExistsAsync())
                {
                    BlobClient blob = sourceBlobContainerClient.GetBlobClient(blobName);

                    if (await blob.ExistsAsync())
                    {
                        await blob.SetAccessTierAsync(AccessTier.Archive);
                        log.LogInformation($"Access tier set to Archive. Blob name: {blobName}");
                    }
                }
            }
            catch (RequestFailedException)
            {
                log.LogInformation($"Failed to complete blob archiving operation: {blobName}");
                throw;
            }
        }
    }
}