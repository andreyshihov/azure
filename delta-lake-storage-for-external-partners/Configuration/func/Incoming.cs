using System.IO;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace func
{
    public static class Incoming
    {
        [FunctionName("Incoming_d7339ff0")]
        public static async Task Run_d7339ff0(
            [BlobTrigger("d7339ff0/Incoming/{name}")] Stream newBlob,
            string name,
            IBinder binder,
            ILogger log)
        {
            await Common.BindAsync("d7339ff0", newBlob, name, binder, log);
        }

        [FunctionName("Incoming_874e4c60")]
        public static async Task Run_874e4c60(
            [BlobTrigger("874e4c60/Incoming/{name}")] Stream newBlob,
            string name,
            IBinder binder,
            ILogger log)
        {
            await Common.BindAsync("874e4c60", newBlob, name, binder, log);
        }
    }
}
