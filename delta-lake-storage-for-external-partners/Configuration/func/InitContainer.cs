using System.IO;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace func
{
    public static class InitContainer
    {
        [FunctionName("Service")]
        public static async Task Service(
            [BlobTrigger("service/{name}")] Stream newBlob,
            string name,
            IBinder binder,
            ILogger log)
        {
            if (name.EndsWith("-init-container"))
            {
                await Common.InitContainer(name.Replace("-init-container", string.Empty), binder, log);
            }
        }
    }
}