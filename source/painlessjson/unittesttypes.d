module painlessjson.unittesttypes;
import painlessjson.annotations;
import std.json;
import std.algorithm;
import std.stdio;
import painlessjson.painlessjson;

struct Point
{
    double x = 0;
    double y = 1;
    this(double x_, double y_)
    {
        x = x_;
        y = y_;
    }

    string foo()
    {
        writeln("Functions should not be called");
        return "Noooooo!";
    }

    static string bar()
    {
        writeln("Static functions should not be called");
        return "Noooooo!";
    }

}

class PointC
{
    double x = 0;
    double y = 1;
    this()
    {
    }

    this(double x_, double y_)
    {
        x = x_;
        y = y_;
    }

    string foo()
    {
        writeln("Class functions should not be called");
        return "Noooooo!";
    }

}

class PointPrivate
{
    private double _x;
    private double _y;
    this(double x_, double y_)
    {
        _x = x_;
        _y = y_;
    }

    string foo()
    {
        writeln("Class functions should not be called");
        return "Noooooo!";
    }

    double x()
    {
        return _x;
    }

    double y()
    {
        return _y;
    }

    static PointPrivate _fromJSON(JSONValue value)
    {
        return new PointPrivate(fromJSON!double(value["x"]), fromJSON!double(value["y"]));
    }

    JSONValue _toJSON()
    {
        JSONValue[string] json;
        json["x"] = JSONValue(x);
        json["y"] = JSONValue(y);
        return JSONValue(json);
    }

}

struct PointPrivateProperty
{
    private double _x;
    private double _y;
    this(double x_, double y_)
    {
        _x = x_;
        _y = y_;
    }

    string foo()
    {
        writeln("Class functions should not be called");
        return "Noooooo!";
    }

    @property double x()
    {
        return _x;
    }

    @property void x(double x_)
    {
        _x = x_;
    }


    @property double y()
    {
        return _y;
    }

    @property void y(double y_)
    {
        _y = y_;
    }

}

struct PointSerializationName
{
    @SerializedName("xOut","yOut") double x = 0;
    @SerializedToName("yOut") @SerializedFromName("xOut") double y = 1;
    this(double x_, double y_)
    {
        x = x_;
        y = y_;
    }

    string foo()
    {
        writeln("Functions should not be called");
        return "Noooooo!";
    }

    static string bar()
    {
        writeln("Static functions should not be called");
        return "Noooooo!";
    }
}