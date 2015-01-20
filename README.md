# Painless JSON [![Build Status](https://travis-ci.org/BlackEdder/painlessjson.svg?branch=master)](https://travis-ci.org/BlackEdder/painlessjson)

Library to painlessly convert your custom types (structs and classes) to and from JSON. This library provides the function toJSON and fromJSON to automatically convert any type to and from JSON. It is possible to override the implementation by defining your own \_toJSON and \_fromJSON member functions for a type. The default conversion works by converting all member variables of a type to and from JSON.

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
struct Point
{
    double x = 0;
    double y = 0;
}

Point point;
auto json = point.toJSON; // => q{{"x":-1,"y":2}})
auto newPoint = fromJSON!Point(parseJSON(q{{"x":-1,"y":2}}));
```

More detailed can be found by generating the documentation

```
dub -b docs
```

## Performance

On the backend this library uses std.json and performance is mainly determined by the std.json implementation. At the moment of writing (2014) std.json is known to be slow compared to other languages. Hopefully, this will be improved over time.

## Tested compilers
![dmd-2.066.1](https://img.shields.io/badge/DMD-2.066.1-brightgreen.svg) ![DMD-2.065.0](https://img.shields.io/badge/DMD-2.065.0-brightgreen.svg) ![DMD-2.064.2](https://img.shields.io/badge/DMD-2.064.2-red.svg) ![LDC-0.14.0](https://img.shields.io/badge/LDC-0.14.0-brightgreen.svg) ![LDC-0.15.1](https://img.shields.io/badge/LDC-0.15.1-brightgreen.svg) ![GDC-4.9.0](https://img.shields.io/badge/GDC-4.9.0-brightgreen.svg)
