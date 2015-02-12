module painlessjson.painlessjson;

import std.conv;
import std.json;
import std.range;
import std.traits;
import painlessjson.traits;
import painlessjson.annotations;

version(unittest)
{
    import std.algorithm;
    import std.stdio;
    import painlessjson.unittesttypes;
	import std.typecons;

    bool jsonEquals(string value1, string value2)
    {
        return jsonEquals(parseJSON(value1), value2);
    }

    bool jsonEquals(JSONValue value1, string value2)
    {
        return jsonEquals(value1, parseJSON(value2));
    }

    bool jsonEquals(string value1, JSONValue value2)
    {
        return jsonEquals(parseJSON(value1), value2);
    }

    bool jsonEquals(JSONValue value1, JSONValue value2)
    {
        return value1.toString == value2.toString;
    }

}

//See if we can use something else than __traits(compiles, (T t){JSONValue(t);})
private JSONValue toJSONImpl(T)(T object) if (__traits(compiles, (T t){JSONValue(t);})){
    return JSONValue(object);
}


//See if we can use something else than !__traits(compiles, (T t){JSONValue(t);})
private JSONValue toJSONImpl(T)(T object) if (isArray!T && !__traits(compiles, (T t){JSONValue(t);}))
{
    JSONValue[] jsonRange;
    jsonRange = map!((el) => el.toJSON)(object).array;
    return JSONValue(jsonRange);
}

private JSONValue toJSONImpl(T)(T object)if (isAssociativeArray!T)
{
    JSONValue[string] jsonAA;
    foreach (key, value; object)
    {
        jsonAA[key.toJSON.toString] = value.toJSON;
    }
    return JSONValue(jsonAA);
}
    


private JSONValue toJSONImpl(T)(T object)if (!isBuiltinType!T && !__traits(compiles, (T t){JSONValue(t);}))
{
  static if (__traits(compiles, (T t)
    {
        return object._toJSON();
    }
    ))
    {
        return object._toJSON();
    }
    else
    {
        JSONValue[string] json;
        // Getting all member variables (there is probably an easier way)
        foreach (name; __traits(allMembers, T))
        {
            static if (__traits(compiles, 
            {
                json[serializationToName!(__traits(getMember, object, name), name)]
                    = __traits(getMember, object, name).toJSON;
            }
            ) && !hasAnyOfTheseAnnotations!(__traits(getMember, object, name),
                SerializeIgnore, SerializeToIgnore) && isFieldOrProperty!(__traits(getMember,
                object, name)))
            {
                json[serializationToName!(__traits(getMember, object, name), name)]
                    = __traits(getMember, object, name).toJSON;
            }
        }
        return JSONValue(json);
    }
}

/// Template function that converts any object to JSON
JSONValue toJSON(T)(T t){
    return toJSONImpl!T(t);
}

/// Converting common types
unittest
{
    assert(5.toJSON!int == JSONValue(5));
    assert(4.toJSON != JSONValue(5));
    assert(5.4.toJSON == JSONValue(5.4));
    assert(toJSON("test") == JSONValue("test"));
    assert(toJSON(JSONValue("test")) == JSONValue("test"));
}


/// Converting InputRanges
unittest
{
    assert([1, 2].toJSON.toString == "[1,2]");
}


/// User structs
unittest
{
    Point p;
    assert(toJSON(p).toString == q{{"x":0,"y":1}});
}


/// Array of structs
unittest
{
    Point[] ps = [Point(-1, 1), Point(2, 3)];
    assert(toJSON(ps).toString == q{[{"x":-1,"y":1},{"x":2,"y":3}]});
}


/// User class
unittest
{
    PointC p = new PointC(1, -2);
    assert(toJSON(p).toString == q{{"x":1,"y":-2}});
}


/// User class with private fields
unittest
{
    PointPrivate p = new PointPrivate(-1, 2);
    assert(toJSON(p).toString == q{{"x":-1,"y":2}});
}


/// User class with private fields and @property
unittest
{
    auto p = PointPrivateProperty(-1, 2);
    assert(jsonEquals(toJSON(p), q{{"x":-1,"y":2,"z":1}}));
}


/// User class with SerializedName annotation
unittest
{
    auto p = PointSerializationName(-1, 2);
    assert(jsonEquals(toJSON(p), q{{"xOut":-1,"yOut":2}}));
}


/// User class with SerializeIgnore annotations
unittest
{
    auto p = PointSerializationIgnore(-1, 5, 4);
    assert(jsonEquals(toJSON(p), q{{"z":5}}));
}


/// Array of classes
unittest
{
    PointC[] ps = [new PointC(-1, 1), new PointC(2, 3)];
    assert(toJSON(ps).toString == q{[{"x":-1,"y":1},{"x":2,"y":3}]});
}


/// Associative array
unittest
{
    string[int] aa = [0 : "a", 1 : "b"];
    // In JSON (D) only string based associative arrays are supported, so:
    assert(aa.toJSON.toString == q{{"0":"a","1":"b"}});
    Point[int] aaStruct = [0 : Point(-1, 1), 1 : Point(2, 0)];
    assert(aaStruct.toJSON.toString == q{{"0":{"x":-1,"y":1},"1":{"x":2,"y":0}}});
}

/// Unnamed tuples
unittest
{
	Tuple!(int, int) point;
	point[0] = 5;
	point[1] = 6;
	assert(jsonEquals(toJSON(point), q{{"_0":5,"_1":6}}));
}

/// Named tuples
unittest
{
	Tuple!(int, "x", int, "y") point;
	point.x = 5;
	point.y = 6;
	assert(point== fromJSON!(Tuple!(int,"x",int,"y"))(parseJSON(q{{"x":5,"y":6}})));
}

/// Overloaded toJSON
unittest
{
    class A
    {
        double x = 0;
        double y = 1;
        JSONValue toJSON()
        {
            JSONValue[string] json;
            json["x"] = x;
            return JSONValue(json);
        }

    }

    auto a = new A;
    assert(a.toJSON.toString == q{{"x":0}});
    
    class B
    {
        double x = 0;
        double y = 1;
    }

    
    // Both templates will now work for B, so this is ambiguous in D.
    // Under dmd it looks like the toJSON!T that is loaded first is the one used
    JSONValue toJSON(T : B)(T b)
    {
        JSONValue[string] json;
        json["x"] = b.x;
        return JSONValue(json);
    }

    auto b = new B;
    assert(b.toJSON.toString == q{{"x":0,"y":1}});
    
    class Z
    {
        double x = 0;
        double y = 1;
        // Adding an extra value
        JSONValue toJSON()
        {
            JSONValue[string] json = painlessjson.toJSON!Z(this).object;
            json["add"] = "bla".toJSON;
            return JSONValue(json);
        }

    }

    auto z = new Z;
    assert(z.toJSON.toString == q{{"x":0,"y":1,"add":"bla"}});
}


private T fromJSONImpl(T)(JSONValue json) if(is(T == JSONValue)){
    return json;
}

private T fromJSONImpl(T)(JSONValue json) if(isIntegral!T){
    return to!T(json.integer);
}

private T fromJSONImpl(T)(JSONValue json) if (isFloatingPoint!T)
{
    if (json.type == JSON_TYPE.INTEGER)
        return to!T(json.integer);
    else
        return to!T(json.floating);
}

private T fromJSONImpl(T)(JSONValue json) if (is(T == string))
{
    return to!T(json.str);
}

private T fromJSONImpl(T)(JSONValue json) if (isBoolean!T)
{
    if (json.type == JSON_TYPE.TRUE)
        return true;
    else
        return false;
}



private T fromJSONImpl(T)(JSONValue json) if (isArray!T && !is(T == string))
{
    T t; //Se is we can find another way of finding t.front
    return map!((js) => fromJSON!(typeof(t.front))(js))(json.array).array;
}

private T fromJSONImpl(T)(JSONValue json) if (isAssociativeArray!T)
{
    T t;
    JSONValue[string] jsonAA = json.object;
    foreach (k, v; jsonAA)
    {
        t[fromJSON!(typeof(t.keys.front))(parseJSON(k))] = fromJSON!(typeof(t
            .values.front))(v);
    }
    return t;
}

private T fromJSONImpl(T)(JSONValue json) if(!isBuiltinType!T && !is(T==JSONValue))
{
    static if (__traits(compiles, 
    {
        return T._fromJSON(json);
    }
    ))
    {
        return T._fromJSON(json);
    }
    else static if(hasAccessibleDefaultsConstructor!(T))
    {
        T t = getIntstanceFromDefaultConstructor!T;
        
        
            mixin ("JSONValue[string] jsonAA = json.object;");
            foreach (name; __traits(allMembers, T))
            {
                static if (__traits(compiles, mixin ("t." ~ name
                    ~ "= fromJSON!(" ~ (typeof(__traits(getMember, t, name)))
                    .stringof ~ ")(jsonAA[\"aFieldName\"])")) && !hasAnyOfTheseAnnotations!(__traits(getMember,
                    t, name), SerializeIgnore, SerializeFromIgnore)
                    && isFieldOrProperty!(__traits(getMember, t, name)))
                {
                    enum string fromName = serializationFromName!(__traits(getMember,
                        t, name), name);
                    mixin ("if ( \"" ~ fromName ~ "\" in jsonAA) t." ~ name
                        ~ "= fromJSON!(" ~ (typeof(__traits(getMember, t, name)))
                        .stringof ~ ")(jsonAA[\"" ~ fromName ~ "\"]);");
                }
            }
        
        return t;
    } else static if(hasAccessibleConstructor!T)
    {
        pragma(msg, "hasAccessibleConstructor");
        if (__traits(hasMember, T, "__ctor"))
        {
            alias Overloads = TypeTuple!(__traits(getOverloads, T, "__ctor"));
            foreach(overload ; Overloads)
            {
                static if(__traits(compiles, {return getInstanceFromCustomConstructor!(T, overload)(json);}))
                {
                    return getInstanceFromCustomConstructor!(T, overload)(json);
                }
            }
            assert(0);
        }
    }
}


/// Convert from JSONValue to any other type
T fromJSON(T)(JSONValue json){
    return fromJSONImpl!T(json);
}


template hasAccessibleDefaultsConstructor(T)
{
    static bool helper()
    {
        return (is(T==struct) && __traits(compiles,{T t;}))
            || (is(T==class) && __traits(compiles, {T t = new T;}));
    }

    enum bool hasAccessibleDefaultsConstructor = helper();
}

T getIntstanceFromDefaultConstructor(T)()
{
    static if(is(T==struct) && __traits(compiles,{T t;}))
    {
        return T();
    } else static if(is(T==class) && __traits(compiles, {T t = new T;}))
    {
        return new T();
    }
}

T getInstanceFromCustomConstructor(T, alias Ctor)(JSONValue json)
{
    import std.typecons : staticIota;
    enum params = ParameterIdentifierTuple!(Ctor);
    alias defaults = ParameterDefaultValueTuple!(Ctor);
    alias Types = ParameterTypeTuple!(Ctor);
    Tuple!(Types) args;
    foreach(i ; staticIota!(0, params.length))
    {
        enum paramName = params[i];
        if (paramName in json)
        {
            args[i] = fromJSON!(Types[i])(json[paramName]);
        }
        else
        { // no value specified in json
            static if (is(defaults[i] == void))
            {
                throw new JSONException("parameter " ~ paramName ~ " has no default value and was not specified");
            }
            else
            {
                args[i] = defaults[i];
            }
        }
    }
    static if (is(T == class)) {
    return new T(args.expand);
    }
    else {
    return T(args.expand);
    }
}

template hasAccessibleConstructor(T)
{
    static bool helper()
    {
        if (__traits(hasMember, T, "__ctor"))
        {
            alias Overloads = TypeTuple!(__traits(getOverloads, T, "__ctor"));
            foreach(overload ; Overloads)
            {
                if(__traits(compiles, getInstanceFromCustomConstructor!(T, overload)(JSONValue())))
                {
                    return true;
                }
            }
            return false;
        }
    }

    enum bool hasAccessibleConstructor = helper();
}


/// Converting common types
unittest
{
    assert(fromJSON!int(JSONValue(1)) == 1);
    assert(fromJSON!double(JSONValue(1.0)) == 1);
    assert(fromJSON!double(JSONValue(1.3)) == 1.3);
    assert(fromJSON!string(JSONValue("str")) == "str");
    assert(fromJSON!bool(JSONValue(true)) == true);
    assert(fromJSON!bool(JSONValue(false)) == false);
    assert(fromJSON!JSONValue(JSONValue(true)) == JSONValue(true));
}


/// Converting arrays
unittest
{
    assert(equal(fromJSON!(int[])(toJSON([1, 2])), [1, 2]));
}


/// Associative arrays
unittest
{
    string[int] aa = [0 : "a", 1 : "b"];
    auto aaCpy = fromJSON!(string[int])(toJSON(aa));
    foreach (k, v; aa)
    {
        assert(aaCpy[k] == v);
    }
}


/// Structs from JSON
unittest
{
    auto p = fromJSON!Point(parseJSON(q{{"x":-1,"y":2}}));
    assert(p.x == -1);
    assert(p.y == 2);
    p = fromJSON!Point(parseJSON(q{{"x":2}}));
    assert(p.x == 2);
    assert(p.y == 1);
    p = fromJSON!Point(parseJSON(q{{"y":3}}));
    assert(p.x == 0);
    assert(p.y == 3);
    p = fromJSON!Point(parseJSON(q{{"x":-1,"y":2,"z":3}}));
    assert(p.x == -1);
    assert(p.y == 2);
}


/// Class from JSON
unittest
{
    auto p = fromJSON!PointC(parseJSON(q{{"x":-1,"y":2}}));
    assert(p.x == -1);
    assert(p.y == 2);
}


/**
    Convert class from JSON using "_fromJSON"
    */

unittest
{
    auto p = fromJSON!PointPrivate(parseJSON(q{{"x":-1,"y":2}}));
    assert(p.x == -1);
    assert(p.y == 2);
}


/// Convert struct from JSON using properties

unittest
{
    auto p = fromJSON!PointPrivateProperty(parseJSON(q{{"x":-1,"y":2,"z":3}}));
    assert(p.x == -1);
    assert(p.y == 2);
}


/// User class with SerializedName annotation
unittest
{
    auto p = fromJSON!PointSerializationName(parseJSON(q{{"xOut":-1,"yOut":2}}));
    assert(p.x == 2);
    assert(p.y == -1);
}


/// User class with SerializeIgnore annotations
unittest
{
    auto p = fromJSON!PointSerializationIgnore(parseJSON(q{{"z":15}}));
    assert(p.x == 0);
    assert(p.y == 1);
    assert(p.z == 15);
}

/// Unnamed tuples
unittest
{
	Tuple!(int, int) point;
	point[0] = 5;
	point[1] = 6;
	assert(point== fromJSON!(Tuple!(int,int))(parseJSON(q{{"_0":5,"_1":6}})));
}

/// No default constructor
unittest
{
    auto p = fromJSON!PointUseConstructor(parseJSON(q{{"x":2, "y":5}}));
    assert(p.x == 2);
    assert(p.y == 5);
}