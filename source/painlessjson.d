import std.json;

/// Template function that converts any object to JSON
JSONValue toJSON( T )( T object ) {
	return JSONValue( object );
}

/// Converting common types
unittest {
	assert( 5.toJSON == JSONValue( 5 ) );
	assert( 4.toJSON != JSONValue( 5 ) );
	assert( 5.4.toJSON == JSONValue( 5.4 ) );
	assert( toJSON( "test" ) == JSONValue( "test" ) );
}

