# Painles JSON

Library to painlessly convert your custom types (structs and classes) to and from JSON. This library provides the function toJSON and fromJSON to automatically convert any type to and from JSON. It is possible to override the implementation by defining your own toJSON and fromJSON member functions for a type. The default conversion works by converting all member variables of a type to and from JSON.

## Performance

On the backend this library uses std.json and performance is mainly determined by the std.json implementation. At the moment of writing (2014) std.json is known to be slow compared to other languages. Hopefully, this will be improved over time.
