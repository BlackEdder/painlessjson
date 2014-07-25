import std.json;

JSONValue toJSON( T )( T object ) {
	return JSONValue( object );
}

unittest {
	assert( true );
}
