module painlessjson.annotations;

import painlessjson.traits;

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

template serializationToName(alias T, string defaultName)
{
    static string helper()
    {
        static if (hasValueAnnotation!(T, SerializedName) && getAnnotation!(T,
            SerializedName).to)
        {
            return getAnnotation!(T, SerializedName).to;
        }
        else static if (hasValueAnnotation!(T, SerializedToName)
            && getAnnotation!(T, SerializedToName).name)
        {
            return getAnnotation!(T, SerializedToName).name;
        }
        else
        {
            return defaultName;
        }
    }

    enum string serializationToName = helper;
}

template serializationFromName(alias T, string defaultName)
{
    static string helper()
    {
        static if (hasValueAnnotation!(T, SerializedName) && getAnnotation!(T,
            SerializedName).from)
        {
            return getAnnotation!(T, SerializedName).from;
        }
        else static if (hasValueAnnotation!(T, SerializedFromName)
            && getAnnotation!(T, SerializedFromName).name)
        {
            return getAnnotation!(T, SerializedFromName).name;
        }
        else
        {
            return defaultName;
        }
    }

    enum string serializationFromName = helper;
}
