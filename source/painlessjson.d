import std.json;
import std.range;
import std.traits;

version( unittest ) {
	import std.stdio;

	struct Point {
		double x = 0;
		double y = 1;
		this( double x_, double y_ ) { x = x_; y = y_; }
		string foo() { writeln( "I should not be called" ); return "Noooooo!"; }
	}

	class PointC {
		double x = 0;
		double y = 1;
		this( double x_, double y_ ) { x = x_; y = y_; }
		string foo() { writeln( "I should not be called" ); return "Noooooo!"; }
	}
}

/// Template function that converts any object to JSON
JSONValue toJSON( T )( T object ) {
	static if (__traits(compiles, (T t) {JSONValue(t);})) {
		return JSONValue( object );
	} else static if ( isArray!T ) { // Range
		JSONValue[] jsonRange;
		foreach ( el ; object ) {
			jsonRange ~= el.toJSON;
		}
		return JSONValue(jsonRange);
	} else {
		JSONValue[string] json;	

		// Getting all member variables (there is probably an easier way)
		foreach (name; __traits(allMembers, T))
		{
			static if(
					__traits(compiles, __traits(getMember, object, name).toJSON)
					//&& __traits(compiles, __traits(getMember, object, name)) 
					//  Skip Functions 
					&& !__traits(compiles, FunctionTypeOf!(__traits(getMember, object, name) ))
					) 
			{ // Can we get a value? (filters out void * this)
				json[name] = __traits(getMember, object, name).toJSON;
			}
		}	

		return JSONValue( json );
	}
}

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
unittest {
 	Point p;
	assert( toJSON( p ).toString == q{{"x":0,"y":1}} );
}

/// Array of structs
unittest {
 	Point[] ps = [ Point(-1,1), Point(2,3) ];
	assert( toJSON( ps ).toString == q{[{"x":-1,"y":1},{"x":2,"y":3}]} );
}


/// User class
unittest {
 	PointC p = new PointC( 0, 1 );
	assert( toJSON( p ).toString == q{{"x":0,"y":1}} );
}
/// Array of classes

/// Associative array

/// Overloaded toJSON
