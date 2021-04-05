using System.IO;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace func
{
    public static class InitContainer
    {
        [FunctionName("InitContainer_d7339ff0")]
        public static async Task InitContainer_d7339ff0(
            [BlobTrigger("d7339ff0/{name}")] Stream newBlob,
            string name,
            ILogger log)
        {
            if (string.Equals(name, "init-container.json"))
            {
                await Common.InitContainer("d7339ff0", newBlob, log);
            }
        }
    }
}