using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Microsoft.WindowsAzure.Storage.Queue;
using lib.Model;
using lib;

namespace func
{
    class Common
    {
        const string INFRASTRUCTURE_QUEUE_NAME = "infrastructure";
        public static async Task BindAsync(string container, Stream newBlob, string name, IBinder binder, ILogger log)
        {
            log.LogInformation($"Incoming blob detected\n Name:{name} \n Size: {newBlob.Length} Bytes");

            var newBlobName = $"{container}.{Guid.NewGuid().ToString().Substring(0, 8)}.{name}";

            // A new name for the blob. It should follow naming convention rule as follows
            // ingest/<External Party Identifier>.<Unique String>.<Original File Name>
            var ingestBlobPath = $"ingest/{newBlobName}";

            // This is one aspect of back-end interface implementation
            // The file has to be moved into Ingest folder for the back-end system to begin processing it
            using (var newMovedBlob = await binder.BindAsync<Stream>(new BlobAttribute(ingestBlobPath, FileAccess.Write)))
            {
                // Direct copy from blob to blob in the same storage
                await newBlob.CopyToAsync(newMovedBlob);

                log.LogInformation($"Incoming blob has been moved and renamed\n New location and name:{ingestBlobPath}");
            };

            // This is Audit non-functional requirement implementation
            // The file has to be moved into Archive folder for auditing purposes
            newBlob.Position = 0;

            var archiveBlobPath = $"archive/{newBlobName}";
            using (var newMovedBlob = await binder.BindAsync<Stream>(new BlobAttribute(archiveBlobPath, FileAccess.Write)))
            {
                // Direct copy from blob to blob in the same storage
                await newBlob.CopyToAsync(newMovedBlob);

                log.LogInformation($"Incoming blob has been moved and renamed\n New location and name:{ingestBlobPath}");
            };

            // Blob metadata to be serialized and added in the queue for deletion
            BlobMetadata blobMetadata = new BlobMetadata(Command.Delete, name, "Incoming", container);

            // After we have completed our business with the original file, we are safe to delete it
            var cloudQueue = await binder.BindAsync<CloudQueue>(new QueueAttribute(INFRASTRUCTURE_QUEUE_NAME));
            await cloudQueue.AddMessageAsync(new CloudQueueMessage(blobMetadata.ToString()));

            log.LogInformation($"Incoming blob has been queued for deletion\n Name:{name}");
        }
    }
}