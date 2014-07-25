import std.json;
import std.range;
import std.traits;

version( unittest ) {
	import std.stdio;
}

/// Template function that converts any object to JSON
JSONValue toJSON( T )( T object ) if (__traits(compiles, (T t) {JSONValue(t);})) {
	return JSONValue( object );
}

/*JSONValue toJSON( T )( T[] object ) {
	JSONValue[] jsonRange;
	foreach ( el ; object ) {
		jsonRange ~= el.toJSON;
	}
	return JSONValue(jsonRange);
}*/

/// Converting common types
unittest {
	assert( 5.toJSON!int == JSONValue( 5 ) );
	assert( 4.toJSON != JSONValue( 5 ) );
	assert( 5.4.toJSON == JSONValue( 5.4 ) );
	assert( toJSON( "test" ) == JSONValue( "test" ) );
}

/// Converting InputRanges
unittest {
	assert( [1,2].toJSON.toString == "[1,2]" );
}

/// User structs

/// Array of structs

/// User class

/// Array of classes

/// Associative array
