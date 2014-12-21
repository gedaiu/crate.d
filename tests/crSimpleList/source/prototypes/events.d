/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 12 21, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module source.prototypes.events;

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

alias EventDescriptor = ModelDescriptor!(Event, EventType.Basic, EventType.Unknown, CalendarEventPrototype!Event, CalendarUnknownEventPrototype!Event);
