module painlessjson.annotations;


struct SerializedToName
{
    string name;
}

struct SerializedFromName
{
    string name;
}
struct SerializedName
{
    string to;
    string from;
    this(string serializedName)
    {
        to = from = serializedName;
    }
    this(string to, string from)
    {
        this.to = to;
        this.from = from;
    }
}
struct SerializeIgnore
{
}

struct SerializeToIgnore
{
}

struct SerializeFromIgnore
{
}

