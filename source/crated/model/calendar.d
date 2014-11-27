/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 11 27, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module crated.model.calendar;

import std.exception;
import std.datetime;

/**
 * Basic functionality for a calendar event
 */
class CalendarEventPrototype
{

	///Event start date
	@("field") 
	SysTime startDate;

	///Event end date
	@("field")
	SysTime endDate;

	///Invariant to check the event consistency
	invariant() {
		assert(startDate <= endDate, "`startDate` <= `endDate`");
	}
}

unittest {
	auto testEvent = new CalendarEventPrototype;

	testEvent.startDate = Clock.currTime;
	testEvent.endDate = Clock.currTime - dur!"hours"(1);

	bool failed = false;

	try {
		assert(testEvent);
	} catch (core.exception.AssertError e) {
		failed = true;
	}

	assert(failed);
}

unittest {
	auto testEvent = new CalendarEventPrototype;
	
	testEvent.startDate = Clock.currTime;
	testEvent.endDate = Clock.currTime + dur!"hours"(1);
	
	bool failed = false;
	
	try {
		assert(testEvent);
	} catch (core.exception.AssertError e) {
		failed = true;
	}
	
	assert(!failed);
}