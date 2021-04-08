using System;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Azure.Storage.Blobs;
using Azure.Storage.Files.DataLake;
using func.Model;
using Azure.Identity;
using Azure;
using System.Collections.Generic;

namespace func
{
    class Common
    {
        public static async Task DeleteBlobAsync(BlobContainerClient sourceContainer, string blobName)
        {
            // Create a BlobClient representing the source blob to copy.
            BlobClient blob = sourceContainer.GetBlobClient(blobName);

            // Ensure that the source blob exists.
            if (await blob.ExistsAsync())
            {
                // Delete blob
                await blob.DeleteAsync();
            }
        }

        public static string GetEnvironmentVariable(string name)
        {
            return Environment.GetEnvironmentVariable(name, EnvironmentVariableTarget.Process);
        }

        public static async Task InitContainerAsync(BlobMetadata blobMetadata, ILogger log)
        {
            log.LogInformation($"Start to init container: {blobMetadata.ContainerName}");

            string serviceEndpoint = string.Format("https://{0}.blob.core.windows.net/", Common.GetEnvironmentVariable("SA_NAME"));
            List<string> directories = new List<string> { "Incoming", "Ok", "Fail", "Report" };

            try
            {
                foreach (var directory in directories)
                {
                    DataLakeServiceClient dataLakeServiceClient = new DataLakeServiceClient(new Uri(serviceEndpoint), new DefaultAzureCredential());
                    DataLakeFileSystemClient dataLakeFileSystemClient = dataLakeServiceClient.GetFileSystemClient(blobMetadata.ContainerName);
                    DataLakeDirectoryClient dataLakeDirectoryClient = dataLakeFileSystemClient.GetDirectoryClient(directory);
                    await dataLakeDirectoryClient.CreateIfNotExistsAsync();
                }
            }
            catch (RequestFailedException)
            {
                log.LogInformation($"Failed to complete container initialisation operation: {blobMetadata.ContainerName}");
                throw;
            }
        }

        public static async Task DeleteBlobAsync(BlobMetadata blobMetadata, ILogger log)
        {
            log.LogInformation($"Delete queue process item: {blobMetadata}");

            string containerEndpoint = string.Format("https://{0}.blob.core.windows.net/{1}", Common.GetEnvironmentVariable("SA_NAME"), blobMetadata.ContainerName);

            // Formatting new blob path and name.
            var blobPathAndName = $"{blobMetadata.BlobPath}/{blobMetadata.BlobName}";

            // Get blob client
            BlobContainerClient sourceBlobContainerClient = new BlobContainerClient(new Uri(containerEndpoint), new DefaultAzureCredential());

            try
            {
                if (sourceBlobContainerClient.Exists())
                {
                    await Common.DeleteBlobAsync(sourceBlobContainerClient, blobPathAndName);
                }
            }
            catch (RequestFailedException)
            {
                log.LogInformation($"Failed to complete blob deleting operation: {blobMetadata}");
                throw;
            }
        }
    }
}