using System.Text.Json;

namespace func
{
    internal class BlobMetadata
    {
        // Required for Deserializer
        // TODO - empty constructor code smell should be reviewed
        public BlobMetadata()
        {
        }

        public BlobMetadata(string blobName, string blobPath, string containerName)
        {
            BlobName = blobName;
            BlobPath = blobPath;
            ContainerName = containerName;
        }

        public string BlobName { get; set; }
        public string BlobPath { get; set; }
        public string ContainerName { get; set; }

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