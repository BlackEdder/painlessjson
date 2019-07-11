# Painless JSON [![Build Status](https://travis-ci.org/BlackEdder/painlessjson.svg?branch=master)](https://travis-ci.org/BlackEdder/painlessjson)

Library to painlessly convert your custom types (structs and classes) to and from JSON. This library provides the function toJSON and fromJSON to automatically convert any type to and from JSON. It is possible to override the implementation by defining your own `_toJSON` and `_fromJSON` member functions for a type or with User Defined Attributes. The default conversion works by converting all member variables of a type to and from JSON (including functions with the `@property` attribute). Constructors will be used automatically if no default-constructor is available.

Painlessjson works by serializing a class/struct using compile time reflection and converts the public fields to a JSON object. You can influence the serialisation/seserialization with the following User Defined Attributes:


- `@SerializeToIgnore` & `@SerializeFromIgnore` disable serialization in the to step or the from step
- `@SerializeIgnore` is the same as combining `@SerializeToIgnore` and `@SerializeToIgnore`, and disables serialization/deserialization for the variable
- `@SerializedName('Name')` Use specified name when serializing/deserializing
- `@SerializedName('To', 'From')` Use a different name when serializing/deserializing
- `@SerializedToName('To')` & `@SerializedFromName('From')` Alternative way of defining names.

## Installation

Installation is mostly managed through <http://code.dlang.org>, so you can add it to your dependencies in your dub.json file.

You can also generate the library by hand with:

```sh
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

More detailed examples can be found in the [master branch documentation on Github][master docs github], the [master branch documentation on ddocs.org][master docs ddocs], or the [latest release documentation on ddocs.org][release docs]. The classes/structs used in the examples are defined [here][unittest types].

## Performance

The library uses compile time reflection to find the fields in your classes. This generates the same code as a handwritten implementation would. It uses std.json on the backend and performance is mainly determined by the std.json implementation. At the moment of writing (2014) std.json is known to be slow compared to other languages. Hopefully, this will be improved over time.

## Tested compilers
![DMD-2.087.0](https://img.shields.io/badge/DMD-2.087.0-brightgreen.svg)
![DMD-2.086.1](https://img.shields.io/badge/DMD-2.086.1-brightgreen.svg)
![DMD-2.085.1](https://img.shields.io/badge/DMD-2.085.1-brightgreen.svg)
![DMD-2.084.1](https://img.shields.io/badge/DMD-2.084.1-brightgreen.svg)
![DMD-2.083.1](https://img.shields.io/badge/DMD-2.083.1-brightgreen.svg)
![DMD-2.082.1](https://img.shields.io/badge/DMD-2.082.1-brightgreen.svg)
![DMD-2.081.2](https://img.shields.io/badge/DMD-2.081.2-brightgreen.svg)
![DMD-2.080.1](https://img.shields.io/badge/DMD-2.080.1-brightgreen.svg)
![DMD-2.079.1](https://img.shields.io/badge/DMD-2.079.1-brightgreen.svg)
![DMD-2.078.3](https://img.shields.io/badge/DMD-2.078.3-brightgreen.svg)
![DMD-2.077.1](https://img.shields.io/badge/DMD-2.077.1-brightgreen.svg)
![DMD-2.076.1](https://img.shields.io/badge/DMD-2.076.1-brightgreen.svg)
![DMD-2.075.1](https://img.shields.io/badge/DMD-2.075.1-red.svg)

![LDC-1.16.0](https://img.shields.io/badge/LDC-1.16.0-brightgreen.svg)
![LDC-1.15.0](https://img.shields.io/badge/LDC-1.15.0-brightgreen.svg)
![LDC-1.14.0](https://img.shields.io/badge/LDC-1.14.0-brightgreen.svg)
![LDC-1.13.0](https://img.shields.io/badge/LDC-1.13.0-brightgreen.svg)
![LDC-1.12.0](https://img.shields.io/badge/LDC-1.12.0-brightgreen.svg)
![LDC-1.11.0](https://img.shields.io/badge/LDC-1.11.0-brightgreen.svg)
![LDC-1.10.0](https://img.shields.io/badge/LDC-1.10.0-brightgreen.svg)
![LDC-1.9.0](https://img.shields.io/badge/LDC-1.9.0-brightgreen.svg)
![LDC-1.8.0](https://img.shields.io/badge/LDC-1.8.0-brightgreen.svg)
![LDC-1.7.0](https://img.shields.io/badge/LDC-1.7.0-brightgreen.svg)
![LDC-1.6.0](https://img.shields.io/badge/LDC-1.6.0-brightgreen.svg)
![LDC-1.5.0](https://img.shields.io/badge/LDC-1.5.0-red.svg)

![GDC-8.2.1](https://img.shields.io/badge/GDC-8.2.1-red.svg)

[master docs github]: http://blackedder.github.io/painlessjson/painlessjson.html
[master docs ddocs]: http://ddocs.org/painlessjson/~master/painlessjson/painlessjson.html
[release docs]: http://ddocs.org/painlessjson/~master/painlessjson/painlessjson.html
[unittest types]: https://github.com/BlackEdder/painlessjson/blob/master/source/painlessjson/unittesttypes.d
