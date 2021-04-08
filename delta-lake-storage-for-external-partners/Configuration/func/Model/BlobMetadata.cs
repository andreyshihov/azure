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

        public BlobMetadata(Command command, PayloadType payloadType, string blobName, string blobPath, string containerName, object payload)
        {
            PayloadType = payloadType;
            Command = command;
            BlobName = blobName;
            BlobPath = blobPath;
            ContainerName = containerName;
            Payload = payload;
        }

        public PayloadType PayloadType { get; set; }
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