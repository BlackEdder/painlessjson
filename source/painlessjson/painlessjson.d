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
    import dunit.toolkit;
}

//See if we can use something else than __traits(compiles, (T t){JSONValue(t);})
private JSONValue toJSONImpl(T)(in T object) if (__traits(compiles, (in T t)
{
    JSONValue(t);
}
))
{
    return JSONValue(object);
}


//See if we can use something else than !__traits(compiles, (T t){JSONValue(t);})
private JSONValue toJSONImpl(T)(in T object) if (isArray!T && !__traits(compiles,
    (in T t)
    {
        JSONValue(t);
}
))
{
    JSONValue[] jsonRange;
    jsonRange = map!((el) => el.toJSON)(object).array;
    return JSONValue(jsonRange);
}

private JSONValue toJSONImpl(T)(in T object) if (isAssociativeArray!T)
{
    JSONValue[string] jsonAA;
    foreach (key, value; object)
    {
        jsonAA[key.toJSON.toString] = value.toJSON;
    }
    return JSONValue(jsonAA);
}

private JSONValue toJSONImpl(T)(in T object) if (!isBuiltinType!T && !__traits(compiles,
    (in T t)
    {
        JSONValue(t);
}
))
{
    static if (__traits(compiles, (in T t)
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
JSONValue toJSON(T)(in T t)
{
    return toJSONImpl!T(t);
}


/// Converting common types
unittest
{
    assertEqual(5.toJSON!int, JSONValue(5));
    assert(4.toJSON != JSONValue(5));//TODO: Wait for DUnit to implement assertNotEqual
    assertEqual(5.4.toJSON, JSONValue(5.4));
    assertEqual(toJSON("test"), JSONValue("test"));
    assertEqual(toJSON(JSONValue("test")), JSONValue("test"));
}


/// Converting InputRanges
unittest
{
    assertEqual([1, 2].toJSON.toString, "[1,2]");
}


/// User structs
unittest
{
    Point p;
    assertEqual(toJSON(p).toString, q{{"x":0,"y":1}});
}


/// Array of structs
unittest
{
    Point[] ps = [Point(-1, 1), Point(2, 3)];
    assertEqual(toJSON(ps).toString, q{[{"x":-1,"y":1},{"x":2,"y":3}]});
}


/// User class
unittest
{
    PointC p = new PointC(1, -2);
    assertEqual(toJSON(p).toString, q{{"x":1,"y":-2}});
}


/// User class with private fields
unittest
{
    PointPrivate p = new PointPrivate(-1, 2);
    assertEqual(toJSON(p).toString, q{{"x":-1,"y":2}});
}


/// User class with private fields and @property
unittest
{
    auto p = PointPrivateProperty(-1, 2);
    assertEqual(toJSON(p).toString, q{{"x":-1,"y":2,"z":1}});
}


/// User class with SerializedName annotation
unittest
{
    auto p = PointSerializationName(-1, 2);
    assertEqual(toJSON(p).toString, q{{"yOut":2,"xOut":-1}});
}


/// User class with SerializeIgnore annotations
unittest
{
    auto p = PointSerializationIgnore(-1, 5, 4);
    assertEqual(toJSON(p).toString, q{{"z":5}});
}


/// Array of classes
unittest
{
    PointC[] ps = [new PointC(-1, 1), new PointC(2, 3)];
    assertEqual(toJSON(ps).toString, q{[{"x":-1,"y":1},{"x":2,"y":3}]});
}


/// Associative array
unittest
{
    string[int] aa = [0 : "a", 1 : "b"];
    // In JSON (D) only string based associative arrays are supported, so:
    assert(aa.toJSON.toString == q{{"0":"a","1":"b"}});
    Point[int] aaStruct = [0 : Point(-1, 1), 1 : Point(2, 0)];
    assertEqual(aaStruct.toJSON.toString, q{{"0":{"x":-1,"y":1},"1":{"x":2,"y":0}}});
}


/// Unnamed tuples
unittest
{
    Tuple!(int, int) point;
    point[0] = 5;
    point[1] = 6;
    assertEqual(toJSON(point).toString, q{{"_0":5,"_1":6}});
}


/// Named tuples
unittest
{
    Tuple!(int, "x", int, "y") point;
    point.x = 5;
    point.y = 6;
    assertEqual(point, fromJSON!(Tuple!(int, "x", int, "y"))(parseJSON(q{{"x":5,"y":6}})));
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
    assertEqual(a.toJSON.toString, q{{"x":0}});
    
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
    assertEqual(b.toJSON.toString, q{{"x":0,"y":1}});
    
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
    assertEqual(z.toJSON.toString, q{{"x":0,"y":1,"add":"bla"}});
}

private T fromJSONImpl(T)(in JSONValue json) if (is(T == JSONValue))
{
    return json;
}

private T fromJSONImpl(T)(in JSONValue json) if (isIntegral!T)
{
    return to!T(json.integer);
}

private T fromJSONImpl(T)(in JSONValue json) if (isFloatingPoint!T)
{
    if (json.type == JSON_TYPE.INTEGER)
        return to!T(json.integer);
    else return to!T(json.floating);
}

private T fromJSONImpl(T)(in JSONValue json) if (is(T == string))
{
    return to!T(json.str);
}

private T fromJSONImpl(T)(in JSONValue json) if (isBoolean!T)
{
    if (json.type == JSON_TYPE.TRUE)
        return true;
    else return false;
}

private T fromJSONImpl(T)(in JSONValue json) if (isArray!T && !is(T == string))
{
    T t; //Se is we can find another way of finding t.front
    return map!((js) => fromJSON!(typeof(t.front))(js))(json.array).array;
}

private T fromJSONImpl(T)(in JSONValue json) if (isAssociativeArray!T)
{
    T t;
    const  JSONValue[string] jsonAA = json.object;
    foreach (k, v; jsonAA)
    {
        t[fromJSON!(typeof(t.keys.front))(parseJSON(k))] = fromJSON!(typeof(t
            .values.front))(v);
    }
    return t;
}

private T fromJSONImpl(T)(in JSONValue json) if (!isBuiltinType!T && !is(T
    == JSONValue))
{
    static if (__traits(compiles, 
    {
        return T._fromJSON(json);
    }
    ))
    {
        return T._fromJSON(json);
    }
    else static if (hasAccessibleDefaultsConstructor!(T))
    {
        T t = getIntstanceFromDefaultConstructor!T;
        mixin ("const  JSONValue[string] jsonAA = json.object;");
        foreach (name; __traits(allMembers, T))
        {
            static if (__traits(compiles, mixin ("t." ~ name ~ "= fromJSON!("
                ~ (typeof(__traits(getMember, t, name))).stringof
                ~ ")(jsonAA[\"aFieldName\"])")) && !hasAnyOfTheseAnnotations!(__traits(getMember,
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
    }
    else static if (hasAccessibleConstructor!T)
    {
        if (__traits(hasMember, T, "__ctor"))
        {
            alias Overloads = TypeTuple!(__traits(getOverloads, T, "__ctor"));
            alias constructorFunctionType = T function(JSONValue value) @system;
            ulong bestOverloadScore = ulong.max;
            constructorFunctionType bestOverload;
            
            // Find the constructor overloads that matches our json content the best
            foreach (overload; Overloads)
            {
                static if (__traits(compiles, 
                {
                    return getInstanceFromCustomConstructor!(T, overload)(json);
                }
                ))
                {
                    if (jsonValueHasAllFieldsNeeded!(overload)(json))
                    {
                        ulong overloadScore = constructorOverloadScore!(overload)(json);
                        if (overloadScore < bestOverloadScore)
                        {
                            bestOverload = function(JSONValue value)
                            {
                                return getInstanceFromCustomConstructor!(T,
                                    overload)(value);
                            }

                            ;
                            bestOverloadScore = overloadScore;
                        }
                    }
                }
            }
            if (bestOverloadScore < ulong.max)
            {
                return bestOverload(json);
            }
            throw jsonExceptionCantSatisyConstructor(json);
        }
    }
}

private JSONException jsonExceptionCantSatisyConstructor(in JSONValue json){
    /+
        toPrettyString does not work with an in/const variable on older D compilers.
        So if toPrettyString can't be use we fall back to a less constructve error message.
    +/
    static if (__traits(compiles,json.toPrettyString()))
    {
        return new JSONException("JSONValue can't satisfy any constructor: "
                ~ json.toPrettyString);
    } else {
        return new JSONException("JSONValue can't satisfy any constructor.");
    }
    
}

/// Convert from JSONValue to any other type
T fromJSON(T)(in JSONValue json)
{
    return fromJSONImpl!T(json);
}

template hasAccessibleDefaultsConstructor(T)
{
    static bool helper()
    {
        return (is(T == struct) && __traits(compiles, 
        {
            T t;
        }
        )) || (is(T == class) && __traits(compiles, 
        {
            T t = new T;
        }
        ));
    }

    enum bool hasAccessibleDefaultsConstructor = helper();
}

T getIntstanceFromDefaultConstructor(T)()
{
    static if (is(T == struct) && __traits(compiles, 
    {
        T t;
    }
    ))
    {
        return T();
    }
    else static if (is(T == class) && __traits(compiles, 
    {
        T t = new T;
    }
    ))
    {
        return new T();
    }
}

T getInstanceFromCustomConstructor(T, alias Ctor)(in JSONValue json)
{
    import std.typecons : staticIota;

    enum params = ParameterIdentifierTuple!(Ctor);
    alias defaults = ParameterDefaultValueTuple!(Ctor);
    alias Types = ParameterTypeTuple!(Ctor);
    Tuple!(Types) args;
    foreach (i; staticIota!(0, params.length))
    {
        enum paramName = params[i];
        if (paramName in json.object)
        {
            args[i] = fromJSON!(Types[i])(json[paramName]);
        }
        else
        {
             // no value specified in json
            static if (is(defaults[i] == void))
            {
                throw new JSONException("parameter " ~ paramName
                    ~ " has no default value and was not specified");
            }
            else
            {
                args[i] = defaults[i];
            }
        }
    }
    static if (is(T == class))
    {
        return new T(args.expand);
    }
    else
    {
        return T(args.expand);
    }
}

bool jsonValueHasAllFieldsNeeded(alias Ctor)(in JSONValue json)
{
    import std.typecons : staticIota;

    enum params = ParameterIdentifierTuple!(Ctor);
    alias defaults = ParameterDefaultValueTuple!(Ctor);
    alias Types = ParameterTypeTuple!(Ctor);
    Tuple!(Types) args;
    foreach (i; staticIota!(0, params.length))
    {
        enum paramName = params[i];
        if (!(paramName in json.object) && is(defaults[i] == void))
        {
            return false;
        }
    }
    return true;
}

ulong constructorOverloadScore(alias Ctor)(in JSONValue json)
{
    import std.typecons : staticIota;

    enum params = ParameterIdentifierTuple!(Ctor);
    alias defaults = ParameterDefaultValueTuple!(Ctor);
    alias Types = ParameterTypeTuple!(Ctor);
    Tuple!(Types) args;
    ulong overloadScore = json.object.length;
    foreach (i; staticIota!(0, params.length))
    {
        enum paramName = params[i];
        if (paramName in json.object)
        {
            overloadScore--;
        }
    }
    return overloadScore;
}

template hasAccessibleConstructor(T)
{
    static bool helper()
    {
        if (__traits(hasMember, T, "__ctor"))
        {
            alias Overloads = TypeTuple!(__traits(getOverloads, T, "__ctor"));
            foreach (overload; Overloads)
            {
                if (__traits(compiles, getInstanceFromCustomConstructor!(T,
                    overload)(JSONValue())))
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
    assertEqual(fromJSON!int(JSONValue(1)), 1);
    assertEqual(fromJSON!double(JSONValue(1.0)), 1);
    assertEqual(fromJSON!double(JSONValue(1.3)), 1.3);
    assertEqual(fromJSON!string(JSONValue("str")), "str");
    assertEqual(fromJSON!bool(JSONValue(true)), true);
    assertEqual(fromJSON!bool(JSONValue(false)), false);
    assertEqual(fromJSON!JSONValue(JSONValue(true)), JSONValue(true));
}


/// Converting arrays
unittest
{
    assertEqual(fromJSON!(int[])(toJSON([1, 2])), [1, 2]);
}


/// Associative arrays
unittest
{
    string[int] aa = [0 : "a", 1 : "b"];
    auto aaCpy = fromJSON!(string[int])(toJSON(aa));
    foreach (k, v; aa)
    {
        assertEqual(aaCpy[k], v);
    }
}


/// Structs from JSON
unittest
{
    auto p = fromJSON!Point(parseJSON(q{{"x":-1,"y":2}}));
    assertEqual(p.x, -1);
    assertEqual(p.y, 2);
    p = fromJSON!Point(parseJSON(q{{"x":2}}));
    assertEqual(p.x, 2);
    assertEqual(p.y, 1);
    p = fromJSON!Point(parseJSON(q{{"y":3}}));
    assertEqual(p.x, 0);
    assertEqual(p.y, 3);
    p = fromJSON!Point(parseJSON(q{{"x":-1,"y":2,"z":3}}));
    assertEqual(p.x, -1);
    assertEqual(p.y, 2);
}


/// Class from JSON
unittest
{
    auto p = fromJSON!PointC(parseJSON(q{{"x":-1,"y":2}}));
    assertEqual(p.x, -1);
    assertEqual(p.y, 2);
}


/**
    Convert class from JSON using "_fromJSON"
    */

unittest
{
    auto p = fromJSON!PointPrivate(parseJSON(q{{"x":-1,"y":2}}));
    assertEqual(p.x, -1);
    assertEqual(p.y, 2);
}


/// Convert struct from JSON using properties

unittest
{
    auto p = fromJSON!PointPrivateProperty(parseJSON(q{{"x":-1,"y":2,"z":3}}));
    assertEqual(p.x, -1);
    assertEqual(p.y, 2);
}


/// User class with SerializedName annotation
unittest
{
    auto p = fromJSON!PointSerializationName(parseJSON(q{{"xOut":-1,"yOut":2}}));
    assertEqual(p.x, 2);
    assertEqual(p.y, -1);
}


/// User class with SerializeIgnore annotations
unittest
{
    auto p = fromJSON!PointSerializationIgnore(parseJSON(q{{"z":15}}));
    assertEqual(p.x, 0);
    assertEqual(p.y, 1);
    assertEqual(p.z, 15);
}


/// Unnamed tuples
unittest
{
    Tuple!(int, int) point;
    point[0] = 5;
    point[1] = 6;
    assertEqual(point, fromJSON!(Tuple!(int, int))(parseJSON(q{{"_0":5,"_1":6}})));
}


/// No default constructor
unittest
{
    auto p = fromJSON!PointUseConstructor(parseJSON(q{{"x":2, "y":5}}));
    assertEqual(p.x, 2);
    assertEqual(p.y, 5);
}


/// Multiple constructors and all JSON-values are there
unittest
{
    auto person = fromJSON!IdAndName(parseJSON(q{{"id":34, "name": "Jason Pain"}}));
    assertEqual(person.id, 34);
    assertEqual(person.name, "Jason Pain");
}


/// Multiple constructors and some JSON-values are missing
unittest
{
    auto person = fromJSON!IdAndName(parseJSON(q{{"id":34}}));
    assertEqual(person.id, 34);
    assertEqual(person.name, "Undefined");
}
