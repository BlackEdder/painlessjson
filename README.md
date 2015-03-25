# Painless JSON [![Build Status](https://travis-ci.org/BlackEdder/painlessjson.svg?branch=master)](https://travis-ci.org/BlackEdder/painlessjson)

Library to painlessly convert your custom types (structs and classes) to and from JSON. This library provides the function toJSON and fromJSON to automatically convert any type to and from JSON. It is possible to override the implementation by defining your own \_toJSON and \_fromJSON member functions for a type or with User Defined Attributes. The default conversion works by converting all member variables of a type to and from JSON (including functions with the @property attribute). Constructors will be used automatically if no default-constructor is available.

Painlessjson works by serializing a class/struct using compile time reflection and converts the public fields to a JSON object. You can influence the serialisation/seserialization with the following User Defined Attributes:


- @SerializeToIgnore @SerializeToIgnore disable serialization in the from step or the to step
- @SerializeIgnore is the same as combining @SerializeToIgnore @SerializeToIgnore and disables serialization/deserialization for the variable
- @SerializedName('Name') Use specified name when serializing/deserializing
- @SerializedName('To', 'From') Use a different name when serializing/deserializing
- @SerializedToName('To') @SerializedFromName('From') Alternative way of defining names.

## Installation

Installation is mostly managed through http://code.dlang.org, so you can add it to your dependencies in your dub.json file.

You can also generate the library by hand with:

```
git clone http://github.com/BlackEdder/painlessjson.git
cd painlessjson 
dub build -b release
```

## Examples

```D
import std.json;
import painlessjson;

struct Point
{
    double x = 0;
    double y = 1;
}

Point point;
auto json = point.toJSON; // => q{{"x":0,"y":1}}
auto newPoint = fromJSON!Point(parseJSON(q{{"x":-1,"y":2}}));

class IdAndName
{
    immutable string name;
    immutable int id;
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

auto person = fromJSON!IdAndName(parseJSON(q{{"id":34, "name": "Jason Pain"}}));
assertEqual(person.id, 34);
assertEqual(person.name, "Jason Pain");
```

More detailed examples can be found in the [master branch documentation on Github](http://blackedder.github.io/painlessjson/painlessjson.html), the [master branch documentation on ddocs.org](http://ddocs.org/painlessjson/~master/painlessjson/painlessjson.html), or the [latest release documentation on ddocs.org](http://ddocs.org/painlessjson/~master/painlessjson/painlessjson.html). The classes/structs used in the examples are defined [here](https://github.com/BlackEdder/painlessjson/blob/master/source/painlessjson/unittesttypes.d).

## Performance

The library uses compile time reflection to find the fields in your classes. This generates the same code as a handwritten implementation would. It uses std.json on the backend and performance is mainly determined by the std.json implementation. At the moment of writing (2014) std.json is known to be slow compared to other languages. Hopefully, this will be improved over time.

## Tested compilers
![DMD-2.067.0](https://img.shields.io/badge/DMD-2.067.0-green.svg) ![dmd-2.066.1](https://img.shields.io/badge/DMD-2.066.1-brightgreen.svg) ![DMD-2.065.0](https://img.shields.io/badge/DMD-2.065.0-red.svg)  ![LDC-0.15.1](https://img.shields.io/badge/LDC-0.15.1-brightgreen.svg) ![GDC-4.9.0](https://img.shields.io/badge/GDC-4.9.0-red.svg)
