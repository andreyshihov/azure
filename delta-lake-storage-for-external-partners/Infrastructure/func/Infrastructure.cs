using System.Threading.Tasks;
using func.Model;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace func
{
    public static class Infrastructure
    {
        [FunctionName("Infrastructure")]
        public static async Task Run(
                [QueueTrigger("infrastructure")] string myQueueItem,
                ILogger log)
        {
            BlobMetadata blobMetadata = BlobMetadata.Parse(myQueueItem);

            switch (blobMetadata.Command)
            {
                case Command.Delete:
                    await Common.DeleteBlobAsync(blobMetadata, log);
                    break;
                case Command.InitContainer:
                    await Common.InitContainerAsync(blobMetadata, log);
                    break;
            }
        }
    }
}
