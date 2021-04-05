using System.Text.Json;

namespace func.Model
{
    public class InitContainer
    {
        // Required for Deserializer
        // TODO - empty constructor code smell should be reviewed
        public InitContainer()
        {
        }

        public InitContainer(string[] directories)
        {
            Directories = directories;
        }

        public string[] Directories { get; set; }

        public override string ToString()
        {
            return JsonSerializer.Serialize(this);
        }

        public static InitContainer Parse(string json)
        {
            return JsonSerializer.Deserialize<InitContainer>(json);
        }
    }
}