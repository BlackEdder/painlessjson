# Painles JSON

Library to painless convert your custom types (structs and classes) to and from JSON. This library provides a toJSON function that will automatically convert any type to JSON, with all the member variables of the type saved in JSON. It is possible to override the implementation by defining a your own toJSON member function for a type.

## Performance

On the backend this library uses std.json and performance is mainly determined by the std.json implementation, which is at the moment of writing (2014) known to be slow compared to other languages. Hopefully, this will be improved over time though.
