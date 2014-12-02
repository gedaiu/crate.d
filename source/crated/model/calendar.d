/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 11 27, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module crated.model.calendar;

import std.exception;
import std.datetime;


enum EventType {
	Basic,
	Unknown
};

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

	@("field")
	static const EventType type = EventType.Basic;

	this() {
		startDate = Clock.currTime;
		startDate.fracSec = FracSec.zero;
		endDate = startDate + dur!"hours"(1);
	}

	/**
	 * return event duration
	 */
	Duration duration() {
		return endDate - startDate;
	}

	///Invariant to check the event consistency
	invariant() {
		assert(startDate <= endDate, "`startDate` > `endDate`");
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

/**
 * An event with an unknown start date. The <code>startDate</code> field represents an aproximate start date for
 * the event. If the current time is <code>startDate - boundary</code> the startDate will be automaticaly postponed
 * with <code>postpone</code> duration.
 */
class CalendarUnknownEventPrototype : CalendarEventPrototype
{
	private alias _startDate = super.startDate;
	private alias _endDate = super.endDate;

	///Event start date
	@property @("field")
	SysTime startDate() {
		auto now = Clock.currTime;

		if(now + boundary >= _startDate) {
			_startDate = now + postpone;
			_endDate = _startDate + duration;
		}

		return _startDate;
	}

	@property @("field")
	void startDate(SysTime start) {
		auto now = Clock.currTime;
		
		if(now + boundary >= start) start = now + postpone;

		_startDate = start;
		_endDate = _startDate + duration;
	}

	@property @("field")
	SysTime endDate() {
		return startDate + duration;
	}

	@property
	void endDate(SysTime end)
	in {
		assert(end >= startDate);
	}
	body
	{
		duration = end - startDate;
		_endDate = _startDate + duration;
	}
	
	@("field")
	Duration duration = dur!"hours"(1);

	@("field")
	Duration postpone = dur!"minutes"(15);

	@("field")
	Duration boundary = dur!"minutes"(15);

	@("field")
	static const EventType type = EventType.Unknown;


	///Invariant to check the event consistency
	invariant() {
		assert(boundary >= postpone, "`boundary` < `postpone`");
	}
}

unittest {
	//test boundary consistence
	auto event = new CalendarUnknownEventPrototype;
	
	event.boundary = dur!"minutes"(1);

	bool failed = false;

	try {
		assert(event);
	} catch (core.exception.AssertError e) {
		failed = true;
	}
	
	assert(failed);
}

unittest {
	//end date estimation test
	auto event = new CalendarUnknownEventPrototype;
	
	event.startDate = SysTime(DateTime(2100,1,1));
	event.duration = dur!"hours"(10);
	
	assert(event.endDate == event.startDate + dur!"hours"(10));
}

unittest {
	//duration from end date
	auto event = new CalendarUnknownEventPrototype;
	
	event.startDate = SysTime(DateTime(2100,1,1));
	event.endDate = event.startDate + dur!"hours"(10);
	
	assert(event.duration == dur!"hours"(10));
}

unittest {
	//start date postpone
	auto event = new CalendarUnknownEventPrototype;
	
	auto start = Clock.currTime + dur!"minutes"(16);
	event.startDate = start;
	
	assert(event.startDate == start);
}

unittest {
	//start date postpone
	auto event = new CalendarUnknownEventPrototype;
	
	auto start = Clock.currTime;
	
	event.startDate = start;
	
	assert(event.startDate >= start + dur!"minutes"(15) && event.startDate <= start + dur!"minutes"(15) + dur!"seconds"(1));
}

/**
 * Rule that helps to define repetable events.
 */
class CalendarRulePrototype {
	bool weekStartOnMonday;

	@("field")
	bool monday;

	@("field")
	bool tuesday;

	@("field")
	bool wednesday;

	@("field")
	bool thursday;

	@("field")
	bool friday;

	@("field")
	bool saturday;

	@("field")
	bool sunday;

	@("field")
	TimeOfDay startTime = TimeOfDay(0,0,0);

	@("field")
	TimeOfDay endTime = TimeOfDay(1,0,0);

	@("field")
	int repeatAfterWeeks;



	/**
	 * Check if a date satisfy a rule
	 */
	@safe bool isInside(SysTime start, SysTime end, SysTime date) {
		if(!isInsideDateInterval(start, end, date)) return false;
		if(!isInsideTimeInterval(date)) return false;
		if(!isValidWeek(start, date)) return false;
		if(!isValidDay(date)) return false;
		
		return true;
	}

	/**
	 * Check if date is in a date range
	 */
	@safe nothrow pure static bool isInsideDateInterval(SysTime start, SysTime end, SysTime date) {
		if(date < start || date >= end) return false;
		return true;
	}

	/**
	 * Check if date is in the same time interva as the rule
	 */
	@safe nothrow bool isInsideTimeInterval(SysTime date) {
		auto tod = (cast(DateTime) date).timeOfDay;
		
		if(tod < startTime || tod >= endTime) return false;

		
		return true;
	}

	/**
	 * Check if date is in a valid rule week
	 */
	@safe bool isValidWeek(SysTime start, SysTime date) {
		SysTime firstDay = start - dur!"days"(start.dayOfWeek);
		firstDay.hour = 0;
		firstDay.minute = 0;
		firstDay.second = 0;
		firstDay.fracSec = FracSec.zero;
		
		if(weekStartOnMonday) firstDay +=  dur!"days"(1);
		
		auto weeks = (date - firstDay).total!"weeks";
		
		return weeks % (repeatAfterWeeks+1) == 0;
	}

	/**
	 * Check if date is in a valid rule week
	 */
	@safe nothrow bool isValidDay(SysTime date) {
		auto day = date.dayOfWeek;
		
		if(day == 0 && sunday)    return true;
		if(day == 1 && monday)    return true;
		if(day == 2 && tuesday)   return true;
		if(day == 3 && wednesday) return true;
		if(day == 4 && thursday)  return true;
		if(day == 5 && friday)    return true;
		if(day == 6 && saturday)  return true;
		
		return false;
	}

	/**
	 * Generate intervals for the current rule.
	 */
	 Interval!SysTime[] generateIntervalsBetween(SysTime start, SysTime startInterval, SysTime endInterval) {
		SysTime firstDay = start - dur!"days"(start.dayOfWeek);
		firstDay.hour = 0;
		firstDay.minute = 0;
		firstDay.second = 0;
		firstDay.fracSec = FracSec.zero;
		
		if(weekStartOnMonday) firstDay +=  dur!"days"(1);

		auto currentDay = start;
		currentDay.hour = 0;
		currentDay.minute = 0;
		currentDay.second = 0;
		currentDay.fracSec = FracSec.zero;

		Interval!SysTime[] intervals;

		while(currentDay < endInterval) {

			if(isValidWeek(start, currentDay) && isValidDay(currentDay)) {
				auto tmpStart = SysTime( DateTime(cast(Date) currentDay, startTime) );
				auto tmpEnd = SysTime( DateTime(cast(Date) currentDay, endTime) );

				if(isInsideDateInterval(startInterval, endInterval, tmpStart) && isInsideDateInterval(startInterval, endInterval, tmpEnd)) {
					auto tmpInterval = Interval!SysTime(tmpStart, tmpEnd);

					intervals ~= tmpInterval;
				}
			}

			currentDay += dur!"days"(1);
		}

		return intervals;
	}

	invariant() {
		assert(startTime <= endTime, "`boundary` < `postpone`");
	}
}

unittest {
	auto testProgram = new CalendarRulePrototype;
		
	bool failed = false;
	
	try {
		assert(testProgram);
	} catch (core.exception.AssertError e) {
		failed = true;
	}
	
	assert(!failed);
}

unittest {
	auto testProgram = new CalendarRulePrototype;
	
	testProgram.startTime = TimeOfDay(1,0,0);
	testProgram.endTime = TimeOfDay(0,0,0);
	
	bool failed = false;
	
	try {
		assert(testProgram);
	} catch (core.exception.AssertError e) {
		failed = true;
	}
	
	assert(failed);
}

unittest {
	SysTime start = SysTime(DateTime(2014,1,1,0,0,0));
	SysTime end = SysTime(DateTime(2014,1,2,0,0,0));
	
	//range check
	assert(!CalendarRulePrototype.isInsideDateInterval(start, end, start - dur!"seconds"(1)));
	assert( CalendarRulePrototype.isInsideDateInterval(start, end, start) );
	assert( CalendarRulePrototype.isInsideDateInterval(start, end, end - dur!"seconds"(1)));
	assert(!CalendarRulePrototype.isInsideDateInterval(start, end, end));
}

unittest {
	//check rule colisons
	auto testProgram = new CalendarRulePrototype;
	
	testProgram.startTime = TimeOfDay(10,0,0);
	testProgram.endTime = TimeOfDay(11,0,0);
	
	//interval check
	assert(!testProgram.isInsideTimeInterval(SysTime(DateTime(2014,1,1,10,0,0)) - dur!"seconds"(1)));
	assert( testProgram.isInsideTimeInterval(SysTime(DateTime(2014,1,1,10,0,0))) );
	assert( testProgram.isInsideTimeInterval(SysTime(DateTime(2014,1,1,11,0,0)) - dur!"seconds"(1)));
	assert(!testProgram.isInsideTimeInterval(SysTime(DateTime(2014,1,1,11,0,0))));
}

unittest {
	//check rule colisons
	auto testProgram = new CalendarRulePrototype;
	
	testProgram.startTime = TimeOfDay(10,0,0);
	testProgram.endTime = TimeOfDay(11,0,0);
	testProgram.repeatAfterWeeks = 2;

	SysTime start = SysTime(DateTime(2014,1,1));

	//interval check
	assert( testProgram.isValidWeek(start, start));
	assert(!testProgram.isValidWeek(start, start + dur!"weeks"(1)));
	assert(!testProgram.isValidWeek(start, start + dur!"weeks"(2)));
	assert( testProgram.isValidWeek(start, start + dur!"weeks"(3)));
}

unittest {
	//check interval generation
	auto testProgram = new CalendarRulePrototype;
	testProgram.startTime = TimeOfDay(10,0,0);
	testProgram.endTime = TimeOfDay(11,0,0);
	testProgram.repeatAfterWeeks = 2;

	testProgram.monday = true;

	SysTime start = SysTime(DateTime(2014,1,1));

	auto res = testProgram.generateIntervalsBetween(start, start, SysTime(DateTime(2014,3,1)));

	assert(res.length == 2);
	assert(res[0] == Interval!SysTime(SysTime(DateTime(2014,1,20,10,0,0)), SysTime(DateTime(2014,1,20,11,0,0))));
	assert(res[1] == Interval!SysTime(SysTime(DateTime(2014,2,10,10,0,0)), SysTime(DateTime(2014,2,10,11,0,0))));
}


/**
 * This represents a repetable event.
 */
class CalendarRepetableEventPrototype : CalendarEventPrototype {

	@("field") CalendarRulePrototype[] rules;

	/**
	 * Check if there is an event on a particular date and time
	 */
	bool isEventOn(SysTime date) {
		if(date < startDate || date >= endDate) return false;

		bool result = false;

		foreach(rule; rules) {
			result = result || rule.isInside(startDate, endDate, date);
		}

		return result;
	}

	/**
	 * Generate intervals for the current event.
	 * 
	 * TODO: write a test
	 */
	Interval!SysTime[] generateIntervalsBetween(SysTime startInterval, SysTime endInterval) {
		if(startInterval < startDate) startInterval = startDate;
		if(endInterval > endDate) endInterval = endDate;

		Interval!SysTime[] intervals;

		foreach(rule; rules) {
			intervals ~= rule.generateIntervalsBetween(startDate, startInterval, endInterval);
		}

		return intervals;
	}
}

unittest {
	//test outside events
	auto testEvent = new CalendarRepetableEventPrototype;
	testEvent.startDate = SysTime(DateTime(2014,1,1));
	testEvent.endDate = SysTime(DateTime(2015,1,1));
	
	assert(!testEvent.isEventOn( SysTime(DateTime(2014,1,1)) - dur!"seconds"(1) ));
	assert(!testEvent.isEventOn( SysTime(DateTime(2015,1,1)) ));
}


unittest {
	//test outside events
	auto testEvent = new CalendarRepetableEventPrototype;
	testEvent.startDate = SysTime(DateTime(2014,1,1));
	testEvent.endDate = SysTime(DateTime(2015,1,1));

	CalendarRulePrototype rule1 = new CalendarRulePrototype;
	rule1.monday = true;
	rule1.startTime = TimeOfDay(10,0,0);
	rule1.endTime = TimeOfDay(11,0,0);
	rule1.repeatAfterWeeks = 2;

	CalendarRulePrototype rule2 = new CalendarRulePrototype;
	rule2.tuesday = true;
	rule2.startTime = TimeOfDay(12,0,0);
	rule2.endTime = TimeOfDay(14,0,0);
	rule2.repeatAfterWeeks = 2;

	testEvent.rules ~= [rule1, rule2];

	//test the first rule
	assert(!testEvent.isEventOn( SysTime(DateTime(2014,1,20, 10,0,0)) - dur!"seconds"(1)));
	assert( testEvent.isEventOn( SysTime(DateTime(2014,1,20, 10,0,0))));
	assert( testEvent.isEventOn( SysTime(DateTime(2014,1,20, 11,0,0)) - dur!"seconds"(1)));
	assert(!testEvent.isEventOn( SysTime(DateTime(2014,1,20, 11,0,0))));
	
	assert(!testEvent.isEventOn( SysTime(DateTime(2014,1,13, 10,0,0))));
	assert(!testEvent.isEventOn( SysTime(DateTime(2014,1,13, 11,0,0)) - dur!"seconds"(1)));

	//test the second rule
	assert(!testEvent.isEventOn( SysTime(DateTime(2014,1,21, 12,0,0)) - dur!"seconds"(1)));
	assert( testEvent.isEventOn( SysTime(DateTime(2014,1,21, 12,0,0))));
	assert( testEvent.isEventOn( SysTime(DateTime(2014,1,21, 14,0,0)) - dur!"seconds"(1)));
	assert(!testEvent.isEventOn( SysTime(DateTime(2014,1,21, 14,0,0))));
	
	assert(!testEvent.isEventOn( SysTime(DateTime(2014,1,14, 12,0,0))));
	assert(!testEvent.isEventOn( SysTime(DateTime(2014,1,14, 14,0,0)) - dur!"seconds"(1)));
}

/**
 * This represent a chain of events where each event does not overlap with his successor.
 */
class CalendarEventChainPrototype {
	CalendarEventPrototype[] events;

	/**
	 * Check events for collisions and solve them.
	 */
	void update() {

		if(events.length == 0) return;

		auto prevEvent = events[0];
		
		foreach(i; 1..events.length) {
			if(events[i].startDate < prevEvent.endDate) {
				auto tmpDuration = events[i].duration;

				events[i].startDate = prevEvent.endDate;
				events[i].endDate = prevEvent.endDate + tmpDuration;
			}

			prevEvent = events[i];
		}

	}
}

unittest {
	//test a valid chain
	auto chain = new CalendarEventChainPrototype;
	
	auto event1 = new CalendarEventPrototype;
	event1.startDate = SysTime(DateTime(2014,1,1,10,0,0));
	event1.endDate = SysTime(DateTime(2014,1,1,11,0,0));
	
	auto event2 = new CalendarEventPrototype;
	event2.startDate = SysTime(DateTime(2014,1,1,11,0,0));
	event2.endDate = SysTime(DateTime(2014,1,1,12,0,0));
	
	chain.events = [event1, event2];
	chain.update;
	
	assert(chain.events[0].startDate == SysTime(DateTime(2014,1,1,10,0,0)));
	assert(chain.events[0].endDate == SysTime(DateTime(2014,1,1,11,0,0)));
	assert(chain.events[1].startDate == SysTime(DateTime(2014,1,1,11,0,0)));
	assert(chain.events[1].endDate == SysTime(DateTime(2014,1,1,12,0,0)));
}

unittest {
	//test another valid chain
	auto chain = new CalendarEventChainPrototype;
	
	auto event1 = new CalendarEventPrototype;
	event1.startDate = SysTime(DateTime(2014,1,1,10,0,0));
	event1.endDate = SysTime(DateTime(2014,1,1,11,0,0));
	
	auto event2 = new CalendarEventPrototype;
	event2.startDate = SysTime(DateTime(2014,1,2,10,0,0));
	event2.endDate = SysTime(DateTime(2014,1,2,11,0,0));
	
	chain.events = [event1, event2];
	chain.update;
	
	assert(chain.events[0].startDate == SysTime(DateTime(2014,1,1,10,0,0)));
	assert(chain.events[0].endDate == SysTime(DateTime(2014,1,1,11,0,0)));
	assert(chain.events[1].startDate == SysTime(DateTime(2014,1,2,10,0,0)));
	assert(chain.events[1].endDate == SysTime(DateTime(2014,1,2,11,0,0)));
}

unittest {
	//test two overlaping events
	auto chain = new CalendarEventChainPrototype;
	
	auto event1 = new CalendarEventPrototype;
	event1.startDate = SysTime(DateTime(2014,1,1,10,0,0));
	event1.endDate = SysTime(DateTime(2014,1,1,11,0,0));
	
	auto event2 = new CalendarEventPrototype;
	event2.startDate = SysTime(DateTime(2014,1,1,10,0,0));
	event2.endDate = SysTime(DateTime(2014,1,1,11,0,0));
	
	chain.events = [event1, event2];
	chain.update;
	
	assert(chain.events[0].startDate == SysTime(DateTime(2014,1,1,10,0,0)));
	assert(chain.events[0].endDate == SysTime(DateTime(2014,1,1,11,0,0)));
	assert(chain.events[1].startDate == SysTime(DateTime(2014,1,1,11,0,0)));
	assert(chain.events[1].endDate == SysTime(DateTime(2014,1,1,12,0,0)));
}

unittest {
	//test two overlaping events with an unknown event
	auto chain = new CalendarEventChainPrototype;
	
	auto event1 = new CalendarUnknownEventPrototype;
	event1.startDate = SysTime(DateTime(2014,1,1,10,0,0));
	event1.duration = dur!"hours"(1);
	
	auto event2 = new CalendarEventPrototype;
	event2.startDate = SysTime(DateTime(2014,1,1,10,0,0));
	event2.endDate = SysTime(DateTime(2014,1,1,11,0,0));
	
	chain.events = [event1, event2];

	auto now = Clock.currTime + event1.postpone - dur!"seconds"(1);
	auto now2 = now + dur!"seconds"(1);

	chain.update;

	auto a = chain.events[0].startDate;         

	assert(chain.events[0].startDate >= now                  && chain.events[0].startDate <= now2);
	assert(chain.events[0].endDate >= now + dur!"hours"(1)   && chain.events[0].endDate <= now2 + dur!"hours"(1));
	assert(chain.events[1].startDate >= now + dur!"hours"(1) && chain.events[1].startDate <= now2 + dur!"hours"(1));
	assert(chain.events[1].endDate >= now + dur!"hours"(2)   && chain.events[1].endDate <= now2 + dur!"hours"(2));
}