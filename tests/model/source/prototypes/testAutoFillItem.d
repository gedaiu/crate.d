/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 1 21, 2015
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module prototypes.testautofillitems;

import std.conv;
import crated.model.base;


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

