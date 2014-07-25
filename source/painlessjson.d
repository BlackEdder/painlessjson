import std.json;
import std.range;
import std.traits;

version( unittest ) {
	import std.stdio;

	struct Point {
		double x = 0;
		double y = 1;
		this( double x_, double y_ ) { x = x_; y = y_; }
		string foo() { 
			writeln( "Functions should not be called" );
			return "Noooooo!";
		}
		static string bar() { 
			writeln( "Static functions should not be called" ); 
			return "Noooooo!"; 
		}
	}

	class PointC {
		double x = 0;
		double y = 1;
		this( double x_, double y_ ) { x = x_; y = y_; }
		string foo() { 
			writeln( "Class functions should not be called" ); 
			return "Noooooo!"; 
		}
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
	} else static if ( isAssociativeArray!T ) { // Range
		JSONValue[string] jsonAA; 
		foreach ( key, value ; object ) {
			jsonAA[ key.toJSON.toString ] = value.toJSON;
		}
		return JSONValue(jsonAA);
	} else {
		JSONValue[string] json;	

		// Getting all member variables (there is probably an easier way)
		foreach (name; __traits(allMembers, T))
		{
			static if(
					__traits(compiles, __traits(getMember, object, name).toJSON)
					//&& __traits(compiles, __traits(getMember, object, name)) 
					//  Skip Functions 
					&& !isSomeFunction!(__traits(getMember, object, name) )
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
unittest {
 	PointC[] ps = [ new PointC(-1,1), new PointC(2,3) ];
	assert( toJSON( ps ).toString == q{[{"x":-1,"y":1},{"x":2,"y":3}]} );
}

/// Associative array
unittest {
	string[int] aa = [ 0 : "a", 1 : "b" ];
	// In JSON (D) only string based associative arrays are supported, so:
	assert( aa.toJSON.toString == q{{"0":"a","1":"b"}} );

	Point[int] aaStruct = [ 0 : Point( -1,1 ), 1 : Point( 2,0 ) ];
	assert( aaStruct.toJSON.toString == q{{"0":{"x":-1,"y":1},"1":{"x":2,"y":0}}} );
}

/// Overloaded toJSON
