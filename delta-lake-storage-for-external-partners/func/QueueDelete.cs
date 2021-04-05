using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Azure.Storage.Blobs;
using Azure;
using func.Model;
using System;
using Azure.Identity;
using func;

public class QueueDelete
{
    [FunctionName("QueueDelete")]
    public static async Task Run(
                [QueueTrigger("delete")] string myQueueItem,
                ILogger log)
    {
        log.LogInformation($"Delete queue process item: {myQueueItem}");

        BlobMetadata blobMetadata = BlobMetadata.Parse(myQueueItem);
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
            log.LogInformation($"Failed to complete blob deleting operation: {myQueueItem}");
            throw;
        }
    }
}
