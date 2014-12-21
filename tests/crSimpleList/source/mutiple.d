/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 12 18, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module source.app;

import std.stdio;
import std.conv;
import std.string;

import crated.tools;
import crated.model.base;
import crated.model.calendar;

abstract class MyEvent : CalendarEvent {

	enum Category {
		category1,
		category2
	}

	@("field", "primary")
	string _id;
	
	@("field", "required", "test: value") 
	string name = "unknown";

	@("field")
	int index;

	@("field")
	float otherIndex;

	@("field")
	Category category;

	this() {}
}

alias CalendarModelDescriptor = ModelDescriptor!(MyEvent, EventType.Basic, EventType.Unknown, CalendarEventPrototype!MyEvent, CalendarUnknownEventPrototype!MyEvent);

alias CalendarModel = Model!CalendarModelDescriptor;

unittest {
	auto item1 = CalendarModel.CreateItem!"Basic";
	auto item2 = CalendarModel.CreateItem!"Unknown";
	
	assert(!CalendarModelDescriptor.HasField(item1, "duration"));
	assert(CalendarModelDescriptor.HasField(item2, "duration"));
}

unittest {
	auto item1 = CalendarModel.CreateItem!"Basic";
	auto item2 = CalendarModel.CreateItem!"Unknown";
	
	assert(CalendarModelDescriptor.HasAttribute(item1, "name", "required"));
	assert(CalendarModelDescriptor.HasAttribute(item1, "name", "test"));
	assert(!CalendarModelDescriptor.HasAttribute(item1, "name", "___"));
}

unittest {
	auto item = CalendarModel.CreateItem!"Basic";

	assert(CalendarModelDescriptor.AttributeValue(item, "name", "required") == "");
	assert(CalendarModelDescriptor.AttributeValue(item, "name", "test") == "value");
	assert(CalendarModelDescriptor.AttributeValue(item, "name", "___") == "");
}

unittest {
	auto item = CalendarModel.CreateItem!"Basic";
	
	item._id = "ID1";
	assert(CalendarModelDescriptor.PrimaryField(item) == "ID1");
	
	CalendarModelDescriptor.PrimaryField(item) = "ID2";
	assert(item._id == "ID2");
}

unittest {
	auto item = CalendarModel.CreateItem!"Basic";
	
	assert(CalendarModelDescriptor.GetType(item, "_id") == "string");
	assert(CalendarModelDescriptor.GetType(item, "startDate") == "SysTime");
}


unittest {
	auto item = CalendarModel.CreateItem!"Basic";

	assert(CalendarModelDescriptor.GetDescription(item, "_id") == "");

	assert(CalendarModelDescriptor.GetDescription(item, "index") == "isIntegral");
	assert(CalendarModelDescriptor.GetDescription(item, "otherIndex") == "isFloating");

	assert(CalendarModelDescriptor.GetDescription(item, "itemType") == "isConst");
	assert(CalendarModelDescriptor.GetDescription(item, "category") == "isEnum");
}

