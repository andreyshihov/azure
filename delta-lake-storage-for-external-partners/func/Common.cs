using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Microsoft.WindowsAzure.Storage.Queue;
using Azure.Storage.Blobs;

namespace func
{
    class Common
    {
        public static async Task BindAsync(string container, Stream newBlob, string name, IBinder binder, ILogger log)
        {
            log.LogInformation($"Incoming blob detected\n Name:{name} \n Size: {newBlob.Length} Bytes");

            // A new name for the blob. It should follow naming convention rule as follows
            // ingest/<External Party Identifier>.<Unique String>.<Original File Name>
            var newBlobName = $"ingest/{container}.{Guid.NewGuid().ToString().Substring(0, 8)}.{name}";

            // Imperative binding to the output Blob. Has been done this way so we could give it a arbitrary name
            using (var newMovedBlob = await binder.BindAsync<Stream>(new BlobAttribute(newBlobName, FileAccess.Write)))
            {
                // Direct copy from blob to blob in the same storage
                await newBlob.CopyToAsync(newMovedBlob);

                log.LogInformation($"Incoming blob has been moved and renamed\n New location and name:{newBlobName}");
            };

            // Blob metadata to be serialized and added in the queue
            BlobMetadata blobMetadata = new BlobMetadata(name, "Incoming", container);

            // Imperative binding to the output Queue. Has been done this way so we ensure that deleting happens after blob move and rename
            var cloudQueue = await binder.BindAsync<CloudQueue>(new QueueAttribute("delete"));
            await cloudQueue.AddMessageAsync(new CloudQueueMessage(blobMetadata.ToString()));

            log.LogInformation($"Incoming blob has been queued for deletion\n Name:{name}");
        }

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
    }
}