/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 11 27, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module crated.model.calendar;

import crated.model.base;
import crated.view.base;
import crated.view.datetime;

import std.exception;
import std.datetime;
import std.conv;
import std.string;


enum EventType {
	Undefined,
	Basic,
	AutoPostpone,
	Repetable
};

abstract class CalendarEvent {
	@property
	const(EventType) itemType();

	@property 
	void startDate(const SysTime startDate);

	@property
	SysTime startDate() const;

	@property               
	void endDate(const SysTime endDate);

	@property
	SysTime endDate() const;

	@property 
	Duration duration();

	@property 
	void duration(Duration duration);

	@property 
	void boundary(const Duration customBoundary);

	@property 
	Duration boundary() const;
	
	@property 
	void postpone(const Duration customBoundary);

	@property 
	Duration postpone() const;

	@property @CalendarRulePrototype
	CalendarRule[] rules() const;

	@property 
	void rules(CalendarRule[] someRules);
}

struct Reservation {

	@("field")
	string name;

	@("field")
	Interval!SysTime interval;
}

/**
 * Represents a resource as a group of an event and an array of reserverd dates
 */
abstract class Resource {
	@("field")
	CalendarEvent time;

	@("field")
	Reservation[] reserved;
}

/**
 * Implementation for a basic calendar event
 */

template CalendarEventPrototype(T : CalendarEvent) {

	class CalendarEventPrototypeImplementation : T
	{
		///Event start date
		protected SysTime _startDate;

		///Event end date
		protected SysTime _endDate;

		this() {
			_startDate = Clock.currTime;
			_startDate.fracSec = FracSec.zero;
			_endDate = _startDate + dur!"hours"(1);
		}

		@property override {

			@("field") 
			const(EventType) itemType() { return EventType.Basic; }

			void startDate(const SysTime startDate) { _startDate = startDate; }

			@("field") 
			SysTime startDate() const { return _startDate; }

			void endDate(const SysTime endDate) { _endDate = endDate; }
			@("field") SysTime endDate() const { return _endDate; }

			///return event duration
			Duration duration() { return endDate - startDate; }

			///ditto
			void duration(Duration duration) { endDate = startDate + duration; }

			///return event boundary
			Duration boundary() const { return dur!"minutes"(0); }
			
			///ditto
			void boundary(const Duration customBoundary) { throw new CratedModelException("Base Event does not support boundary setter");  }
			
			///return event postpone
			Duration postpone() const { return dur!"minutes"(0); }
			
			///ditto
			void postpone(const Duration customPostpone) {  throw new CratedModelException("Base Event does not support postpone setter");  }

			@property 
			CalendarRule[] rules() const { return null; }
			
			@property 
			void rules(CalendarRule[] someRules) { throw new CratedModelException("Base Event does not support rules setter");  };
		}

		///Invariant to check the event consistency
		invariant() {
			assert(_startDate <= _endDate, "`startDate` > `endDate`");
		}
	}

	alias CalendarEventPrototype = CalendarEventPrototypeImplementation;
}

unittest {
	auto testEvent = new CalendarEventPrototype!CalendarEvent;
	bool failed = false;

	try {
		testEvent.startDate = Clock.currTime;
		testEvent.endDate = Clock.currTime - dur!"hours"(1);
	} catch (core.exception.AssertError e) {
		failed = true;
	}

	assert(failed);
}

unittest {
	auto testEvent = new CalendarEventPrototype!CalendarEvent;
	
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
 * An event with an auto postpone start date. The <code>startDate</code> field represents an aproximate start date for
 * the event. If the current time is <code>startDate - boundary</code> the startDate will be automaticaly postponed
 * with <code>postpone</code> duration.
 */
template CalendarAutoPostponeEventPrototype(T : CalendarEvent) {

	class CalendarAutoPostponeEventPrototypeImplementation : T
	{
		this() {
			_startDate = Clock.currTime;
			_startDate.fracSec = FracSec.zero;
			_duration = dur!"hours"(1);
			_boundary = dur!"minutes"(15);
			_postpone = dur!"minutes"(15);
		}

		protected SysTime _startDate;
		protected SysTime _endDate;

		///Event start date
		@property override { 
			@("field")
			const(EventType) itemType() { return EventType.AutoPostpone; };

			@("field") 
			SysTime startDate() const {
				auto now = Clock.currTime;
				now.fracSec = FracSec.zero;

				if(now + boundary >= _startDate) {
					const auto sDate = now + postpone;
					return sDate;
				} else {
					return _startDate;
				}
			}

			void startDate(const SysTime start) {
				auto now = Clock.currTime;
				now.fracSec = FracSec.zero;

				if(now + boundary >= start) {
					_startDate = now + postpone;
				} else {
					_startDate = start;
				}

				_endDate = _startDate + _duration;
			}

			SysTime endDate() const {
				return startDate + _duration;
			}

			void endDate(const SysTime end)	{
				_duration = end - startDate;

				if(_duration.total!"seconds" <= 0) _duration = dur!"seconds"(0); 

				_endDate = _startDate + _duration;
			}

			///return event duration
			@("field") 
			Duration duration() const { return _duration; }
			
			///ditto
			void duration(Duration customDuration) { _duration = customDuration; }

			///return event postpone
			@("field") 
			Duration postpone() const { return _postpone; }
			
			///ditto
			void postpone(const Duration customPostpone) { _postpone = customPostpone; }

			///return event boundary
			@("field") 
			Duration boundary() const { return _boundary; }
			
			///ditto
			void boundary(const Duration customBoundary) { _boundary = customBoundary; }

			@property 
			CalendarRule[] rules() const { return null; }
			
			@property 
			void rules(CalendarRule[] someRules) { throw new CratedModelException("Base Event does not support rules setter");  };
		}
		
		protected {
			Duration _duration;
			Duration _boundary;
			Duration _postpone;
		}
	}

	alias CalendarAutoPostponeEventPrototype = CalendarAutoPostponeEventPrototypeImplementation;
}

unittest {
	//end date estimation test
	auto event = new CalendarAutoPostponeEventPrototype!CalendarEvent;
	
	event.startDate = SysTime(DateTime(2100,1,1));
	event.duration = dur!"hours"(10);
	
	assert(event.endDate == event.startDate + dur!"hours"(10));
}

unittest {
	//duration from end date
	auto event = new CalendarAutoPostponeEventPrototype!CalendarEvent;
	
	event.startDate = SysTime(DateTime(2100,1,1));
	event.endDate = event.startDate + dur!"hours"(10);
	
	assert(event.duration == dur!"hours"(10));
}

unittest {
	//duration from end date
	auto event = new CalendarAutoPostponeEventPrototype!CalendarEvent;
	
	event.startDate = SysTime(DateTime(2100,1,1));
	event.endDate = event.startDate - dur!"hours"(10);
	
	assert(event.duration.total!"seconds" == 0);
}

unittest {
	//start date postpone
	auto event = new CalendarAutoPostponeEventPrototype!CalendarEvent;
	
	auto start = Clock.currTime + dur!"minutes"(16);
	event.startDate = start;
	
	assert(event.startDate == start);
}

unittest {
	//start date postpone
	auto event = new CalendarAutoPostponeEventPrototype!CalendarEvent;
	
	auto start = Clock.currTime;
	
	event.startDate = start;

	assert(event.startDate >= start + dur!"minutes"(14) && event.startDate <= start + dur!"minutes"(15) + dur!"seconds"(1));
}

/**
 * Rule that helps to define repetable events.
 */
class CalendarRulePrototype {
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
}

class CalendarRule : CalendarRulePrototype {
	bool weekStartOnMonday;

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
	auto testProgram = new CalendarRule;
		
	bool failed = false;
	
	try {
		assert(testProgram);
	} catch (core.exception.AssertError e) {
		failed = true;
	}
	
	assert(!failed);
}

unittest {
	auto testProgram = new CalendarRule;
	
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
	assert(!CalendarRule.isInsideDateInterval(start, end, start - dur!"seconds"(1)));
	assert( CalendarRule.isInsideDateInterval(start, end, start) );
	assert( CalendarRule.isInsideDateInterval(start, end, end - dur!"seconds"(1)));
	assert(!CalendarRule.isInsideDateInterval(start, end, end));
}

unittest {
	//check rule colisons
	auto testProgram = new CalendarRule;
	
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
	auto testProgram = new CalendarRule;
	
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
	auto testProgram = new CalendarRule;
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
/**
 * An event with an auto postpone start date. The <code>startDate</code> field represents an aproximate start date for
 * the event. If the current time is <code>startDate - boundary</code> the startDate will be automaticaly postponed
 * with <code>postpone</code> duration.
 */
template CalendarRepetableEventPrototype(T : CalendarEvent) {


	class CalendarRepetableEventPrototypeImplementation : CalendarEventPrototype!(T) {

		CalendarRule[] _rules;

		@("field")
		override const(EventType) itemType() { return EventType.Repetable; };

		@property @("field") @CalendarRuleView
		override CalendarRule[] rules() const { 
			CalendarRule[] r;

			foreach(rule; _rules) {
				r ~= cast(CalendarRule) rule;
			}

			return r; 
		}
		
		@property 
		override void rules(CalendarRule[] someRules) { _rules = someRules;  };

		/**
		 * Check if there is an event on a particular date and time
		 */
		bool isEventOn(SysTime date) {
			if(date < _startDate || date >= _endDate) return false;

			bool result = false;
			
			foreach(rule; rules) {
				result = result || rule.isInside(_startDate, _endDate, date);
			}
			
			return result;
		}
		
		/**
		 * Generate intervals for the current event.
		 * 
		 * TODO: write a test
		 */
		Interval!SysTime[] generateIntervalsBetween(SysTime startInterval, SysTime endInterval) {
			if(startInterval < _startDate) startInterval = startDate;
			if(endInterval > _endDate) endInterval = endDate;

			Interval!SysTime[] intervals;
			
			foreach(rule; rules) {
				intervals ~= rule.generateIntervalsBetween(_startDate, startInterval, endInterval);
			}
			
			return intervals;
		}
	}
	
	alias CalendarRepetableEventPrototype = CalendarRepetableEventPrototypeImplementation;
}

unittest {
	//test outside events
	auto testEvent = new CalendarRepetableEventPrototype!CalendarEvent;

	assert(testEvent.itemType == EventType.Repetable);
	assert((cast(CalendarEvent) testEvent).itemType == EventType.Repetable);
}

unittest {
	//test outside events
	auto testEvent = new CalendarRepetableEventPrototype!CalendarEvent;
	testEvent.startDate = SysTime(DateTime(2014,1,1));
	testEvent.endDate = SysTime(DateTime(2015,1,1));
	
	assert(!testEvent.isEventOn( SysTime(DateTime(2014,1,1)) - dur!"seconds"(1) ));
	assert(!testEvent.isEventOn( SysTime(DateTime(2015,1,1)) ));
}

unittest {
	//test outside events
	auto testEvent = new CalendarRepetableEventPrototype!CalendarEvent;
	testEvent.startDate = SysTime(DateTime(2014,1,1));
	testEvent.endDate = SysTime(DateTime(2015,1,1));

	CalendarRule rule1 = new CalendarRule;
	rule1.monday = true;
	rule1.startTime = TimeOfDay(10,0,0);
	rule1.endTime = TimeOfDay(11,0,0);
	rule1.repeatAfterWeeks = 2;

	CalendarRule rule2 = new CalendarRule;
	rule2.tuesday = true;
	rule2.startTime = TimeOfDay(12,0,0);
	rule2.endTime = TimeOfDay(14,0,0);
	rule2.repeatAfterWeeks = 2;

	auto rules = [rule1, rule2];
	testEvent.rules = rules;

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
	CalendarEvent[] events;

	/**
	 * Check events for collisions and solve them.
	 */
	void update() {

		if(events.length == 0) return;

		auto prevEvent = events[0];
		
		foreach(i; 1..events.length) {
			if(events[i].startDate < prevEvent.endDate) {

				if(events[i].itemType != EventType.AutoPostpone) {
					auto tmpDuration = events[i].duration;
					events[i].endDate = prevEvent.endDate + tmpDuration;
				}

				events[i].startDate = prevEvent.endDate;
			}

			prevEvent = events[i];
		}

	}
}

unittest {
	//test a valid chain
	auto chain = new CalendarEventChainPrototype;
	
	auto event1 = new CalendarEventPrototype!CalendarEvent;
	event1.startDate = SysTime(DateTime(2014,1,1,10,0,0));
	event1.endDate = SysTime(DateTime(2014,1,1,11,0,0));
	
	auto event2 = new CalendarEventPrototype!CalendarEvent;
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
	
	auto event1 = new CalendarEventPrototype!CalendarEvent;
	event1.startDate = SysTime(DateTime(2014,1,1,10,0,0));
	event1.endDate = SysTime(DateTime(2014,1,1,11,0,0));
	
	auto event2 = new CalendarEventPrototype!CalendarEvent;
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
	
	auto event1 = new CalendarEventPrototype!CalendarEvent;
	event1.startDate = SysTime(DateTime(2014,1,1,10,0,0));
	event1.endDate = SysTime(DateTime(2014,1,1,11,0,0));
	
	auto event2 = new CalendarEventPrototype!CalendarEvent;
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
	//test two overlaping events with an AutoPostpone event
	auto chain = new CalendarEventChainPrototype;
	
	auto event1 = new CalendarAutoPostponeEventPrototype!CalendarEvent;
	event1.startDate = SysTime(DateTime(2014,1,1,10,0,0));
	event1.duration = dur!"hours"(1);
	
	auto event2 = new CalendarEventPrototype!CalendarEvent;
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


/// Transforms time string to TimeOfDay struct
TimeOfDay getTimeOfDay(string data) {
	int h = 0;
	int m = 0;
	int s = 0;
	
	auto splitedData = data.split(":");

	if(splitedData.length > 0) h = splitedData[0].to!int;
	if(splitedData.length > 1) m = splitedData[1].to!int;
	if(splitedData.length > 2) s = splitedData[2].to!int;
	
	return TimeOfDay(h, m, s);
}

unittest {
	string val = "1:2:3";
	
	auto t = getTimeOfDay(val);

	assert(t.hour == 1);
	assert(t.minute == 2);
	assert(t.second == 3);
}

unittest {
	string val = "1:2";
	
	auto t = getTimeOfDay(val);
	
	assert(t.hour == 1);
	assert(t.minute == 2);
	assert(t.second == 0);
}


/// Get values from a dictionary and converts them to a Duration
static Duration durationFromDictionary(string key)(string[string] data) {
	
	auto components = data.extractArray!(key, string[string]);
	auto d = dur!"seconds"(0);
	
	if("hours" in components) d += dur!"hours"(components["hours"].to!int);
	if("minutes" in components) d += dur!"minutes"(components["minutes"].to!int);
	if("seconds" in components) d += dur!"seconds"(components["seconds"].to!int);
	if("days" in components) d += dur!"days"(components["days"].to!int);
	if("weeks" in components) d += dur!"weeks"(components["weeks"].to!int);
	
	return d;
}

unittest {
	string[string] data;

	data["data[hours]"] = "1";
	data["data[minutes]"] = "2";
	data["data[seconds]"] = "3";
	data["data[days]"] = "4";
	data["data[weeks]"] = "5";

	auto d = durationFromDictionary!"data"(data);

	auto fullSplitStruct = d.split();
	assert(fullSplitStruct.hours == 1);
	assert(fullSplitStruct.minutes == 2);
	assert(fullSplitStruct.seconds == 3);
	assert(fullSplitStruct.days == 4);
	assert(fullSplitStruct.weeks == 5);
	assert(fullSplitStruct.msecs == 0);
	assert(fullSplitStruct.usecs == 0);
	assert(fullSplitStruct.hnsecs == 0);
}


/// Fill the Event Prototype fields
void setDefaultEventFields(T)(ref T item, string type, string[string] data) {
	//todo: test this function
	if("startDate" in data) item.startDate = SysTime.fromISOExtString(data["startDate"]);
	
	if(type == "Basic" || type == "Repetable") {
		if("endDate" in data) item.endDate = SysTime.fromISOExtString(data["endDate"]);
	}
	
	if(type == "AutoPostpone") {
		
		if("duration" in data) item.duration = dur!"hnsecs"(data["duration"].to!long);
		else item.duration = durationFromDictionary!"duration"(data);
		
		if("postpone" in data) item.postpone = dur!"hnsecs"(data["postpone"].to!long);
		else item.postpone = durationFromDictionary!"postpone"(data);
		
		if("boundary" in data) item.boundary = dur!"hnsecs"(data["boundary"].to!long);
		else item.boundary = durationFromDictionary!"boundary"(data);
	}

	
	if(type == "Repetable") {
		auto stringRules = data.extractArray!("rules", string[string][]);
		
		CalendarRule[] rules;
		foreach(i; 0..stringRules.length)
			rules ~= createRule(stringRules[i]);
		
		item.rules = rules;
	}
}

/// Create rule from dictionary
CalendarRule createRule(string[string] data) {
	//todo: test this function

	CalendarRule rule =  new CalendarRule;
	
	if("monday" in data && ( data["monday"] == "true" ) ) 
		rule.monday = true;
	
	if("tuesday" in data && ( data["tuesday"] == "true" ) ) 
		rule.tuesday = true;
	
	if("wednesday" in data && ( data["wednesday"] == "true" ) ) 
		rule.wednesday = true;
	
	if("thursday" in data && ( data["thursday"] == "true" ) ) 
		rule.thursday = true;
	
	if("friday" in data && ( data["friday"] == "true" ) ) 
		rule.friday = true;
	
	if("saturday" in data && ( data["saturday"] == "true" ) ) 
		rule.saturday = true;
	
	if("sunday" in data && ( data["sunday"] == "true" ) ) 
		rule.sunday = true;
	
	if("repeatAfterWeeks" in data && data["repeatAfterWeeks"] != "") {
		rule.repeatAfterWeeks = data["repeatAfterWeeks"].to!int;
	}
	
	if("startTime" in data) rule.startTime = getTimeOfDay(data["startTime"]); 
	if("endTime" in data) rule.endTime = getTimeOfDay(data["endTime"]);
	
	return rule;
}