using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Azure.Storage.Blobs;
using Azure;
using func;
using System;
using Azure.Identity;

public partial class IncomingFiles
{
    [FunctionName("Delete")]
    public static async Task Run(
                [QueueTrigger("delete")] string myQueueItem,
                ILogger log)
    {
        log.LogInformation($"Delete queue process item: {myQueueItem}");

        BlobMetadata blobMetadata = BlobMetadata.Parse(myQueueItem);
        string containerEndpoint = string.Format("https://{0}.blob.core.windows.net/", Common.GetEnvironmentVariable("SA_NAME"));
        BlobServiceClient blobServiceClient = new BlobServiceClient(new Uri(containerEndpoint), new DefaultAzureCredential());

        // formatting new blob path and name
        var blobPathAndName = $"{blobMetadata.BlobPath}/{blobMetadata.BlobName}";

        // Get a credential and create a client object for the blob container.
        var sourceBlobContainerClient = blobServiceClient.GetBlobContainerClient(blobMetadata.ContainerName);

        try
        {
            if (sourceBlobContainerClient.Exists())
            {
                await Common.DeleteBlobAsync(sourceBlobContainerClient, blobPathAndName);
            }
        }
        catch (RequestFailedException)
        {
            log.LogInformation($"Failed to complete blob deleting operation: {myQueueItem}");
            throw;
        }
    }
}
