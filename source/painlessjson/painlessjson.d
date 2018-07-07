module painlessjson.painlessjson;

import std.algorithm : map;
import std.string;
import std.conv;
import std.json;
import std.range;
import std.traits;
import std.typecons : Tuple;
import std.typetuple : TypeTuple;
import painlessjson.annotations;
import painlessjson.string;
import painlesstraits;

version (unittest)
{
    import std.stdio : writeln;
    import painlessjson.unittesttypes;
    import dunit.toolkit;
}

struct SerializationOptions
{
    bool alsoAcceptUnderscore;
    bool convertToUnderscore;
}

enum defaultSerializatonOptions =  SerializationOptions(true, false);

// staticIota is not available in newer phobos versions
// Implement my own version (copied from phobos) 
template myStaticIota(int beg, int end)
{
    static if (beg + 1 >= end)
    {
        static if (beg >= end)
        {
            alias myStaticIota = TypeTuple!();
        }
        else
        {
            alias myStaticIota = TypeTuple!(+beg);
        }
    }
    else
    {
        enum mid = beg + (end - beg) / 2;
        alias myStaticIota = TypeTuple!(myStaticIota!(beg, mid), myStaticIota!(mid, end));
    }
}

//See if we can use something else than __traits(compiles, (T t){JSONValue(t);})
private JSONValue defaultToJSONImpl(T, SerializationOptions options)(in T object) if (__traits(compiles, (in T t) {
    JSONValue(t);
}))
{
    return JSONValue(object);
}

//See if we can use something else than !__traits(compiles, (T t){JSONValue(t);})
private JSONValue defaultToJSONImpl(T, SerializationOptions options)(in T object) if (isArray!T && !__traits(compiles, (in T t) {
    JSONValue(t);
}))
{
    JSONValue[] jsonRange;
    jsonRange = map!((el) => el.toJSON)(object).array;
    return JSONValue(jsonRange);
}

// AA for simple types, excluding those handled by the JSONValue constructor
private JSONValue defaultToJSONImpl(T, SerializationOptions options)(in T object)
    if (isAssociativeArray!T && isBuiltinType!(KeyType!T) && !isAssociativeArray!(KeyType!T) &&
        !__traits(compiles, (in T t) { JSONValue(t);}))
{
    JSONValue[string] jsonAA;
    foreach (key, value; object)
    {
        
        jsonAA[to!string(key)] = value.toJSON;
    }
    return JSONValue(jsonAA);
}

// AA for compound types
private JSONValue defaultToJSONImpl(T, SerializationOptions options)(in T object) if (isAssociativeArray!T && (!isBuiltinType!(KeyType!T) || isAssociativeArray!(KeyType!T)))
{
    JSONValue[string] jsonAA;
    foreach (key, value; object)
    {

        jsonAA[key.toJSON.toString] = value.toJSON;
    }
    return JSONValue(jsonAA);
}

private JSONValue defaultToJSONImpl(T, SerializationOptions options )(in T object) if (!isBuiltinType!T
        && !__traits(compiles, (in T t) { JSONValue(t); }))
{
    JSONValue[string] json;
    // Getting all member variables (there is probably an easier way)
    foreach (name; __traits(allMembers, T))
    {
        static if (__traits(compiles,
                {
                    json[serializationToName!(__traits(getMember, object, name), name, false)] = __traits(getMember,
                        object, name).toJSON;
                }) && !hasAnyOfTheseAnnotations!(__traits(getMember, object,
            name), SerializeIgnore, SerializeToIgnore)
            && isFieldOrProperty!(__traits(getMember, object, name)))
        {
            json[serializationToName!(__traits(getMember, object, name), name,(options.convertToUnderscore))] = __traits(getMember,
                object, name).toJSON;
        }
    }
    return JSONValue(json);
}

/++
 Convert any type to JSON<br />
 Can be overridden by &#95;toJSON
 +/
JSONValue defaultToJSON(T, SerializationOptions options = defaultSerializatonOptions)(in T t){
    return defaultToJSONImpl!(T, options)(t);
}

/// Template function that converts any object to JSON
JSONValue toJSON(T, SerializationOptions options = defaultSerializatonOptions)(in T t)
{
    static if (__traits(compiles, (in T t) { return t._toJSON(); }))
    {
        return t._toJSON();
    }
    else
        return defaultToJSON!(T, options)(t);
}

/// Converting common types
unittest
{
    assertEqual(5.toJSON!int, JSONValue(5));
    assert(4.toJSON != JSONValue(5)); //TODO: Wait for DUnit to implement assertNotEqual
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
    auto pnt = p.toJSON.fromJSON!PointPrivate;
    assertEqual(p.x, -1);
    assertEqual(p.y, 2);
}

/// User class with defaultToJSON
unittest
{
    PointDefaultFromJSON p = new PointDefaultFromJSON(-1, 2);
    assertEqual(toJSON(p).toString, q{{"_x":-1,"y":2}});
    auto pnt = p.toJSON.fromJSON!PointDefaultFromJSON;
    assertEqual(p.x, -1);
    assertEqual(p.y, 2);
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
    assertEqual(toJSON(p)["xOut"].floating, -1);
    assertEqual(toJSON(p)["yOut"].floating, 2);
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
    assert(aa.toJSON.toString == q{{"0":"a","1":"b"}});
    Point[int] aaStruct = [0 : Point(-1, 1), 1 : Point(2, 0)];
    assertEqual(aaStruct.toJSON.toString, q{{"0":{"x":-1,"y":1},"1":{"x":2,"y":0}}});
    assertEqual(["key": "value"].toJSON.toString, q{{"key":"value"}});
}

/// Associative array containing struct
unittest
{
    assertEqual(["test": SimpleStruct("test2")].toJSON().toString, q{{"test":{"str":"test2"}}});
}

/// Associative array with struct key
unittest
{
    assertEqual([SimpleStruct("key"): "value", SimpleStruct("key2"): "value2"].toJSON().toString, q{{"{\"str\":\"key\"}":"value","{\"str\":\"key2\"}":"value2"}});
}

/// struct with inner struct and AA
unittest
{
    auto testStruct = StructWithStructAndAA(["key1": "value1"], ["key2": StructWithStructAndAA.Inner("value2")]);
    auto converted = testStruct.toJSON();
    assertEqual(converted["stringToInner"].toString, q{{"key2":{"str":"value2"}}});
    assertEqual(converted["stringToString"].toString, q{{"key1":"value1"}});
}

/// Unnamed tuples
unittest
{
    Tuple!(int, int) point;
    point[0] = 5;
    point[1] = 6;
    assert(toJSON(point).toString == q{{"_0LU":5,"_1LU":6}} ||
        toJSON(point).toString == q{{"_0":5,"_1":6}});
}

/// Named tuples
unittest
{
    Tuple!(int, "x", int, "y") point;
    point.x = 5;
    point.y = 6;
    assertEqual(point, fromJSON!(Tuple!(int, "x", int, "y"))(parseJSON(q{{"x":5,"y":6}})));
}

/// Convert camel case to underscore automatically
unittest
{
    CamelCaseConversion value;
    value.wasCamelCase = 5;
    value.was_underscore = 7;

    auto valueAsJSON = value.toJSON!(CamelCaseConversion,SerializationOptions(false, true));
    
    assertEqual(valueAsJSON["was_camel_case"].integer, 5); 
    assertEqual(valueAsJSON["was_underscore"].integer, 7);
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
    assertEqual(z.toJSON["x"].floating, 0);
    assertEqual(z.toJSON["y"].floating, 1);
    assertEqual(z.toJSON["add"].str, "bla");
}

private T defaultFromJSONImpl(T, SerializationOptions options)(in JSONValue json) if (is(T == JSONValue))
{
    return json;
}

private T defaultFromJSONImpl(T, SerializationOptions options)(in JSONValue json) if (isIntegral!T)
{
    return to!T(json.integer);
}

private T defaultFromJSONImpl(T, SerializationOptions options)(in JSONValue json) if (isFloatingPoint!T)
{
    if (json.type == JSON_TYPE.INTEGER)
        return to!T(json.integer);
    else
        return to!T(json.floating);
}

private T defaultFromJSONImpl(T, SerializationOptions options)(in JSONValue json) if (is(T == string))
{
    return to!T(json.str);
}

private T defaultFromJSONImpl(T, SerializationOptions options)(in JSONValue json) if (isBoolean!T)
{
    if (json.type == JSON_TYPE.TRUE)
        return true;
    else
        return false;
}

private T defaultFromJSONImpl(T, SerializationOptions options)(in JSONValue json) if (isArray!T &&  !is(T == string))
{
    T t; //Se is we can find another way of finding t.front
    return map!((js) => fromJSON!(typeof(t.front))(js))(json.array).array;
}

// AA for simple keys
private T defaultFromJSONImpl(T, SerializationOptions options)(in JSONValue json) if (isAssociativeArray!T && isBuiltinType!(KeyType!T) && !isAssociativeArray!(KeyType!T))
{
    T t;
    const JSONValue[string] jsonAA = json.object;
    foreach (k, v; jsonAA)
    {
        t[to!(KeyType!T)(k)] = fromJSON!(ValueType!T)(v);
    }
    return t;
}

// AA for compound keys
private T defaultFromJSONImpl(T, SerializationOptions options)(in JSONValue json) if (isAssociativeArray!T && (!isBuiltinType!(KeyType!T) || isAssociativeArray!(KeyType!T)))
{
    KeyType!T keyConverter(string stringKey) {
        try{
            return fromJSON!(KeyType!T)(parseJSON(stringKey));
        }
        catch(JSONException) {
            throw new Exception("Couldn't convert JSON key \"" ~ stringKey ~ "\" to " ~ KeyType!T.stringof ~ " which is the key type of " ~ T.stringof);
        }
    }

    T t;
    const JSONValue[string] jsonAA = json.object;
    foreach (k, v; jsonAA)
    {
            t[keyConverter(k)] = fromJSON!(ValueType!T)(v);
        
    }
    return t;
}

/++
 Convert to given type from JSON.<br />
 Can be overridden by &#95;fromJSON.
 +/
private T defaultFromJSONImpl(T, SerializationOptions options)(in JSONValue json) if (!isBuiltinType!T &&  !is(T == JSONValue))
{
    static if (hasAccessibleDefaultsConstructor!(T))
    {
        T t = getIntstanceFromDefaultConstructor!T;
        mixin("const  JSONValue[string] jsonAA = json.object;");
        foreach (name; __traits(allMembers, T))
        {

            static if (__traits(compiles,{mixin("import " ~ moduleName!(__traits(getMember, t, name)) ~ ";");}))
                {
                    mixin("import " ~ moduleName!(__traits(getMember, t, name)) ~ ";");
                }

            static if (__traits(compiles,
                    mixin(
                    "t." ~ name ~ "= fromJSON!(" ~ fullyQualifiedName!(typeof(__traits(getMember,
                    t, name))) ~ ")(jsonAA[\"aFieldName\"])"))
                    && !hasAnyOfTheseAnnotations!(__traits(getMember, t, name),
                    SerializeIgnore, SerializeFromIgnore)
                    && isFieldOrProperty!(__traits(getMember, t, name)))
            {
                enum string fromName = serializationFromName!(__traits(getMember, t,
                        name), name);
                mixin(
                    "if ( \"" ~ fromName ~ "\" in jsonAA) t." ~ name ~ "= fromJSON!(" ~ fullyQualifiedName!(
                    typeof(__traits(getMember, t, name))) ~ ")(jsonAA[\"" ~ fromName ~ "\"]);");
                static if(options.alsoAcceptUnderscore)
                {
                    mixin(
                    "if ( \"" ~ camelCaseToUnderscore(fromName) ~ "\" in jsonAA) t." ~ name ~ "= fromJSON!(" ~ fullyQualifiedName!(
                    typeof(__traits(getMember, t, name))) ~ ")(jsonAA[\"" ~ camelCaseToUnderscore(fromName) ~ "\"]);");
                }
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
                            return getInstanceFromCustomConstructor!(T, overload, false)(json);
                        }))
                {
                    if (jsonValueHasAllFieldsNeeded!(overload, (options.alsoAcceptUnderscore))(json))
                    {
                        ulong overloadScore = constructorOverloadScore!(overload, (options.alsoAcceptUnderscore))(json);
                        if (overloadScore < bestOverloadScore)
                        {
                            bestOverload = function(JSONValue value) {
                                return getInstanceFromCustomConstructor!(T, overload, (options.alsoAcceptUnderscore))(value);
                            };
                            bestOverloadScore = overloadScore;
                        }
                    }
                }
            }
            if (bestOverloadScore < ulong.max)
            {
                return bestOverload(json);
            }
            throw new JSONException(
                "JSONValue can't satisfy any constructor: " ~ json.toPrettyString);
        }
    }
}

/++
 Convert to given type from JSON.<br />
 Can be overridden by &#95;fromJSON.
 +/
T defaultFromJSON(T, SerializationOptions options = defaultSerializatonOptions)(in JSONValue json){
    return defaultFromJSONImpl!(T, options)(json);
}

template hasAccessibleDefaultsConstructor(T)
{
    static bool helper()
    {
        return (is(T == struct) && __traits(compiles, { T t; }))
            || (is(T == class) && __traits(compiles, { T t = new T; }));
    }

    enum bool hasAccessibleDefaultsConstructor = helper();
}

T getIntstanceFromDefaultConstructor(T)()
{
    static if (is(T == struct) && __traits(compiles, { T t; }))
    {
        return T();
    }
    else static if (is(T == class) && __traits(compiles, { T t = new T; }))
    {
        return new T();
    }
}

T getInstanceFromCustomConstructor(T, alias Ctor, bool alsoAcceptUnderscore)(in JSONValue json)
{
    enum params = ParameterIdentifierTuple!(Ctor);
    alias defaults = ParameterDefaultValueTuple!(Ctor);
    alias Types = ParameterTypeTuple!(Ctor);
    Tuple!(Types) args;
    foreach (i; myStaticIota!(0, params.length))
    {
        enum paramName = params[i];
        if (paramName in json.object)
        {
            args[i] = fromJSON!(Types[i])(json[paramName]);
        } else if( alsoAcceptUnderscore && camelCaseToUnderscore(paramName)){
            args[i] = fromJSON!(Types[i])(json[camelCaseToUnderscore(paramName)]);
        }
        else
        {
            // no value specified in json
            static if (is(defaults[i] == void))
            {
                throw new JSONException(
                    "parameter " ~ paramName ~ " has no default value and was not specified");
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

bool jsonValueHasAllFieldsNeeded(alias Ctor, bool alsoAcceptUnderscore)(in JSONValue json)
{
    enum params = ParameterIdentifierTuple!(Ctor);
    alias defaults = ParameterDefaultValueTuple!(Ctor);
    alias Types = ParameterTypeTuple!(Ctor);
    Tuple!(Types) args;
    foreach (i; myStaticIota!(0, params.length))
    {
        enum paramName = params[i];
        if (!((paramName in json.object) || ( alsoAcceptUnderscore && (camelCaseToUnderscore(paramName) in json.object))) && is(defaults[i] == void))
        {
            return false;
        }
    }
    return true;
}

ulong constructorOverloadScore(alias Ctor, bool alsoAcceptUnderscore)(in JSONValue json)
{
    enum params = ParameterIdentifierTuple!(Ctor);
    alias defaults = ParameterDefaultValueTuple!(Ctor);
    alias Types = ParameterTypeTuple!(Ctor);
    Tuple!(Types) args;
    ulong overloadScore = json.object.length;
    foreach (i; myStaticIota!(0, params.length))
    {
        enum paramName = params[i];
        if (paramName in json.object || ( alsoAcceptUnderscore && (camelCaseToUnderscore(paramName) in json.object)))
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
            bool anyInstanciates = false;
            foreach (overload; Overloads)
            {
                anyInstanciates |= __traits(compiles, getInstanceFromCustomConstructor!(T,
                        overload, false)(JSONValue()));
            }
            return anyInstanciates;
        }
    }

    enum bool hasAccessibleConstructor = helper();
}

/// Convert from JSONValue to any other type
T fromJSON(T, SerializationOptions options = defaultSerializatonOptions)(in JSONValue json)
{
    static if (__traits(compiles, { return T._fromJSON(json); }))
    {
        return T._fromJSON(json);
    }
    else 
    {
        if (json.type == JSON_TYPE.NULL)
            return T.init;
        return defaultFromJSON!(T,options)(json);
    }
}

unittest {
    struct P
    { string name; }

    auto jv = parseJSON(`{"name": null}`);
    auto j = fromJSON!P(jv);
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
    assertEqual(fromJSON!(Point[])(parseJSON(q{[{"x":-1,"y":2},{"x":3,"y":4}]})), [Point(-1,2),Point(3,4)]);
}

/// Array as member of other class
unittest
{
    // Types need to be defined in different module, otherwise 
    // type is not known at compile time
    import painlessjson.unittesttypes_local_import;

    string jsonString = q{[ {"duration": "10"} ]};
    Route[] routes = parseJSON(jsonString).fromJSON!(Route[]);
    assertEqual(routes.length, 1);

    jsonString = q{{"routes":[ {"duration": "10"} ] }};
    JourneyPlan jp;
    jp = parseJSON(jsonString).fromJSON!JourneyPlan;
    assertEqual(jp.routes.length, 1);
}

/// Associative arrays
unittest
{
    string[int] aaInt = [0 : "a", 1 : "b"];
    assertEqual(aaInt, fromJSON!(string[int])(parseJSON(q{{"0" : "a", "1": "b"}})));

    string[string] aaString = ["hello" : "world", "json" : "painless"];
    assertEqual(aaString, fromJSON!(string[string])(parseJSON(q{{"hello" : "world", "json" : "painless"}})));
}

/// Associative array containing struct
unittest
{
    auto parsed = fromJSON!(SimpleStruct[string])(parseJSON(q{{"key": {"str": "value"}}}));
    assertEqual(parsed , ["key": SimpleStruct("value")]);
}

/// Associative array with struct key
unittest
{
    JSONValue value = parseJSON(q{{"{\"str\":\"key\"}":"value", "{\"str\":\"key2\"}":"value2"}});
    auto parsed = fromJSON!(string[SimpleStruct])(value);
    assertEqual(
        parsed
        , [SimpleStruct("key"): "value", SimpleStruct("key2"): "value2"]);
}

/// struct with inner struct and AA
unittest
{
    auto testStruct = StructWithStructAndAA(["key1": "value1"], ["key2": StructWithStructAndAA.Inner("value2")]);
    auto testJSON = parseJSON(q{{"stringToInner":{"key2":{"str":"value2"}},"stringToString":{"key1":"value1"}}});
    assertEqual(fromJSON!StructWithStructAndAA(testJSON), testStruct);
}

/// Error reporting from inner objects
unittest
{
    import std.exception : collectExceptionMsg;
    import std.algorithm : canFind;
    void throwFunc() {
        fromJSON!(string[SimpleStruct])(parseJSON(q{{"{\"str\": \"key1\"}": "value", "key2":"value2"}}));
    }
    auto errorMessage = collectExceptionMsg(throwFunc());
    assert(errorMessage.canFind("key2"));
    assert(errorMessage.canFind("string[SimpleStruct]"));
    assert(!errorMessage.canFind("key1"));
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
    assertEqual(point, 
      fromJSON!(Tuple!(int, int))(toJSON(point)));
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

/// Accept underscore and convert it to camelCase automatically
unittest
{
    auto value = fromJSON!CamelCaseConversion(parseJSON(q{{"was_camel_case":8,"was_underscore":9}}));
    assertEqual(value.wasCamelCase, 8);
    assertEqual(value.was_underscore, 9);
}
