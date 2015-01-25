/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 1 18, 2015
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module fillFields;

import vibe.d;
import crated.model.calendar;
import crated.model.base;
import std.stdio;

class A {
	@("field", "primary") string id;
	@("field") string name = "unknown";
	
	this() {}
}

class ADescriptor : ModelDescriptor!A {
	static A CreateItem(string type, string[string] data) {
		auto a = new A;
		
		return a;
	}
}

unittest {
	auto item = new A;
	
	Bson bItem = ADescriptor.Convert!Bson(item);
	
	assert(bItem["name"].get!string == "unknown");
}



class B {
	@("field", "primary") string id;
	@("field") string names[];
	
	this() {}
}

class BDescriptor : ModelDescriptor!B {
	static B CreateItem(string type, string[string] data) {
		auto b = new B;
		
		return b;
	}
}

unittest {
	auto item = new B;
	item.names ~= [ "name1", "name2" ];

	Bson bItem = BDescriptor.Convert!Bson(item);

	assert( bItem["names"].type == Bson.Type.array );
	assert( bItem["names"].length == 2 );
	assert( bItem["names"][0].get!string == "name1" );
	assert( bItem["names"][1].get!string == "name2" );
}



class C {
	@("field", "primary") string id;
	@("field") string names[string];
	
	this() {}
}

class CDescriptor : ModelDescriptor!C {
	static C CreateItem(string type, string[string] data) {
		auto c = new C;
		
		return c;
	}
}

unittest {
	auto item = new C;
	
	item.names["first"] = "name1";
	item.names["other"] = "name2" ;
	
	Bson bItem = CDescriptor.Convert!Bson(item);
	
	assert( bItem["names"].type == Bson.Type.object );
	assert( bItem["names"].length == 2 );
	assert( bItem["names"]["first"].get!string == "name1" );
	assert( bItem["names"]["other"].get!string == "name2" );
}

class D {
	@("field", "primary") string id;
	@("field") string names[string][][string];
	
	this() {}
}

class DDescriptor : ModelDescriptor!D {
	static D CreateItem(string type, string[string] data) {
		auto d = new D;
		
		return d;
	}
}

unittest {
	auto item = new D;
	
	item.names = [ "first": [ ["other":"value"] ] ];
	
	Bson bItem = DDescriptor.Convert!Bson(item);

	assert( bItem["names"].type == Bson.Type.object );
	assert( bItem["names"]["first"].length == 1 );
	assert( bItem["names"]["first"][0]["other"].get!string == "value" );
}



class SomeItem {
	
	@("field", "primary")
	int id;
	
	@("field")
	string[] names;
	
	@("field")
	string[string] otherData;
}

alias Descriptor = ModelDescriptor!SomeItem;

unittest {
	
	string[string] data;
	
	data["id"] = "0";
	
	data["names[0]"] = "name1";
	data["names[1]"] = "name2";
	
	data["otherData[key1]"] = "val1";
	data["otherData[key2]"] = "val2";
	
	auto item = Descriptor.CreateItem("", data);
	
	assert(item.id == 0);
	
	assert(item.names.length == 2);
	assert(item.names[0] == "name1");
	assert(item.names[1] == "name2");
	
	
	assert(item.otherData["key1"] == "val1");
	assert(item.otherData["key2"] == "val2");
}

	