using System.IO;
using System.Threading.Tasks;
using lib.Model;
using lib;
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
            }
        }

        [FunctionName("Service")]
        public static async Task ServiceRun(
            [BlobTrigger("service/{name}")] Stream newBlob,
            string name,
            ILogger log)
        {
            if (name.EndsWith("-init-container"))
            {
                await Common.InitContainerAsync(name.Replace("-init-container", string.Empty), log);
            }
        }
    }
}
