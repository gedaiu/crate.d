/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 12 18, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module tests.descriptor;

import std.stdio;
import std.conv;
import std.string;

import crated.tools;
import crated.model.base;
import crated.model.calendar;


///Descriptor tests
mixin template ModelDescriptorTest(Model) {

	alias Descriptor = Model.Descriptor;

	unittest {
		auto item1 = Model.CreateItem!"Basic";
		auto item2 = Model.CreateItem!"Unknown";
		
		assert(!Descriptor.HasField(item1, "duration"));
		assert(Descriptor.HasField(item2, "duration"));
	}

	unittest {
		auto item1 = Model.CreateItem!"Basic";
		auto item2 = Model.CreateItem!"Unknown";
		
		assert(Descriptor.HasAttribute(item1, "name", "required"));
		assert(Descriptor.HasAttribute(item1, "name", "test"));
		assert(!Descriptor.HasAttribute(item1, "name", "___"));
	}

	unittest {
		auto item = Model.CreateItem!"Basic";

		assert(Descriptor.AttributeValue(item, "name", "required") == "");
		assert(Descriptor.AttributeValue(item, "name", "test") == "value");
		assert(Descriptor.AttributeValue(item, "name", "___") == "");
	}

	unittest {
		auto item = Model.CreateItem!"Basic";
		
		item._id = "ID1";
		assert(Descriptor.PrimaryField(item) == "ID1");
		
		Descriptor.PrimaryField(item) = "ID2";
		assert(item._id == "ID2");
	}

	unittest {
		auto item = Model.CreateItem!"Basic";
		
		assert(Descriptor.GetType(item, "_id") == "string");
		assert(Descriptor.GetType(item, "startDate") == "SysTime");
	}

	unittest {
		auto item = Model.CreateItem!"Basic";

		assert(Descriptor.GetDescription(item, "_id") == "");

		assert(Descriptor.GetDescription(item, "index") == "isIntegral");
		assert(Descriptor.GetDescription(item, "otherIndex") == "isFloating");

		assert(Descriptor.GetDescription(item, "itemType") == "isConst");
		assert(Descriptor.GetDescription(item, "category") == "isEnum");
	}

}

