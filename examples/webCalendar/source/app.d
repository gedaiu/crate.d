import vibe.d;

import crated.model.calendar;
import crated.model.mongo;
import crated.controller.base;
import crated.controller.admin;

import std.stdio;

abstract class Event : CalendarEvent {
	@("field", "primary")
	string _id;

	@("field", "required") 
	string name;

	this() {}
}

alias BaseEventDescriptor = ModelDescriptor!(Event, EventType.Basic, EventType.AutoPostpone, EventType.Repetable, 
													CalendarEventPrototype!Event, CalendarAutoPostponeEventPrototype!Event, CalendarRepetableEventPrototype!Event);

class EventDescriptor : BaseEventDescriptor {

	static TimeOfDay getTimeOfDay(string data) {
		int h = 0;
		int m = 0;
		int s = 0;

		auto splitedData = data.split(":");

		if(splitedData.length > 1) h = splitedData[0].to!int;
		if(splitedData.length > 2) m = splitedData[1].to!int;
		if(splitedData.length > 3) s = splitedData[2].to!int;

		return TimeOfDay(h, m, s);
	}

	static CalendarRule CreateRule(string[string] data) {
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

	static Event CreateItem(string type, string[string] data) {
		auto item = BaseEventDescriptor.CreateItem(type, data);

		if("_id" in data) item._id = data["_id"];
		if("name" in data) item.name = data["name"];
		if("startDate" in data) item.startDate = SysTime.fromISOExtString(data["startDate"]);

		if(type == "Basic" || type == "Repetable") {
			if("endDate" in data) item.endDate = SysTime.fromISOExtString(data["endDate"]);
		}

		if(type == "AutoPostpone") {
			if("duration" in data) item.duration = dur!"hnsecs"(data["duration"].to!long);
			if("postpone" in data) item.postpone = dur!"hnsecs"(data["postpone"].to!long);
			if("boundary" in data) item.boundary = dur!"hnsecs"(data["boundary"].to!long);
		}

		if(type == "Repetable") {
			auto stringRules = data.extractArray!("rules", string[string][]);

			CalendarRule[] rules;
			foreach(i; 0..stringRules.length)
				rules ~= CreateRule(stringRules[i]);

			item.rules = rules;
		}

		return item;
	}
}

alias CalendarModel = MongoModel!(EventDescriptor, "test.calendar", "Calendar");
alias DataManagerController = DataManager!("/admin", CalendarModel);

/**
 *  Vibe.d init
 */
shared static this()
{	
	//setup the database connection string
	crated.model.mongo.dbAddress = "127.0.0.1";

	auto dataManager = new Controller!DataManagerController;

	//set the web server
	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];

	auto router = new URLRouter;

	auto fsettings = new HTTPFileServerSettings;
	fsettings.serverPathPrefix = "/assets/";
	router.get("*", serveStaticFiles("../../assets/", fsettings));

	dataManager.addRoutes(router);

	listenHTTP(settings, router);
	logInfo("Please open http://127.0.0.1:8080/admin/Calendar in your browser.");
}
