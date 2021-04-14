using System.Text.Json;

namespace func.Model
{
    internal class BlobMetadata
    {
        // Required for Deserializer
        // TODO - empty constructor code smell should be reviewed
        public BlobMetadata()
        {
        }

        public BlobMetadata(Command command, string blobName, string blobPath, string containerName, object payload)
        {
            Command = command;
            BlobName = blobName;
            BlobPath = blobPath;
            ContainerName = containerName;
            Payload = payload;
        }

        public Command Command { get; set; }
        public string BlobName { get; set; }
        public string BlobPath { get; set; }
        public string ContainerName { get; set; }
        public object Payload { get; set; }

        public override string ToString()
        {
            return JsonSerializer.Serialize(this);
        }

        public static BlobMetadata Parse(string json)
        {
            return JsonSerializer.Deserialize<BlobMetadata>(json);
        }
    }
}