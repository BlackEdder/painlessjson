module painlessjson.unittesttypes;

import painlessjson.annotations;
import std.json;
import std.algorithm;
import std.stdio;
import painlessjson.painlessjson;

///
struct Point
{
    double x = 0; ///
    double y = 1; ///
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

///
class PointC
{
    ///
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

    const double x()
    {
        return _x;
    }

    const double y()
    {
        return _y;
    }

    static PointPrivate _fromJSON(JSONValue value)
    {
        return new PointPrivate(fromJSON!double(value["x"]), fromJSON!double(value["y"]));
    }

    const JSONValue _toJSON()
    {
        JSONValue[string] json;
        json["x"] = JSONValue(x);
        json["y"] = JSONValue(y);
        return JSONValue(json);
    }

}

class PointDefaultFromJSON
{
    double _x;
    private double _y;

    this()
    {
    }

    this(double x_, double y_)
    {
        _x = x_;
        _y = y_;
    }

    const double x()
    {
        return _x;
    }

    const double y()
    {
        return _y;
    }

    static PointDefaultFromJSON _fromJSON(JSONValue value)
    {
        auto pnt = defaultFromJSON!PointDefaultFromJSON(value);
        pnt._y = fromJSON!double(value["y"]);
        return pnt;
    }

    const JSONValue _toJSON()
    {
        JSONValue[string] json;
        json = this.defaultToJSON.object;
        json["y"] = JSONValue(_y);
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

    const string foo()
    {
        writeln("Class functions should not be called");
        return "Noooooo!";
    }

    const @property double x()
    {
        return _x;
    }

    @property void x(double x_)
    {
        _x = x_;
    }

    const @property double y()
    {
        return _y;
    }

    @property void y(double y_)
    {
        _y = y_;
    }

    const @property double z()
    {
        return 1.0;
    }

    const @property void bar(double a, double b)
    {
        writeln(
            "Functions annotated with @property and more than one variable should not be called");
        assert(0);
    }

}

struct PointSerializationName
{
    @SerializedName("xOut", "yOut") double x = 0;
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

struct SimpleStruct {
    string str;
}

struct StructWithStructAndAA {
    struct Inner {
        string str;
    }
    string[string] stringToString;
    Inner[string] stringToInner;
}

///
struct PointSerializationIgnore
{
    @SerializeIgnore double x = 0; ///
    @SerializedToName("z") @SerializeFromIgnore double y = 1; ///
    @SerializeToIgnore double z = 2; ///

    ///
    this(double x_, double y_, double z_)
    {
        x = x_;
        y = y_;
        z = z_;
    }

    ///
    @SerializeIgnore @property double foo()
    {
        return 0.1;
    }

    ///
    @SerializeIgnore @property void foo(double a)
    {
    }

}

///
struct PointUseConstructor
{
    @disable this();
    immutable double x; ///
    private double _y; ///
    this(double x = 0, double y = 1)
    {
        this.x = x;
        this._y = y;
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

    @property double y()
    {
        return _y;
    }
}

///
class IdAndName
{
    immutable string name; ///
    immutable int id; ///

    this(string name)
    {
        this.id = -1;
        this.name = name;
    }

    this(int id, string name)
    {
        this.id = id;
        this.name = name;
    }

    this(int id)
    {
        this.id = id;
        this.name = "Undefined";
    }
}

struct CamelCaseConversion
{
    int wasCamelCase;
    int was_underscore;
}