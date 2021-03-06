﻿/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 12 21, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module prototypes.events;

import crated.model.calendar;
import crated.model.base;

abstract class Event : CalendarEvent {
	
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

alias BaseEventDescriptor = ModelDescriptor!(Event, EventType.Basic, EventType.AutoPostpone, CalendarEventPrototype!Event, CalendarAutoPostponeEventPrototype!Event);

class EventDescriptor : BaseEventDescriptor {

	static Event CreateItem(string type, string[string] data) {
		auto item = BaseEventDescriptor.CreateItem(type, data);

		return item;
	}
}
