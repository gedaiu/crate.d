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

alias BaseEventDescriptor = ModelDescriptor!(Event, EventType.Basic, EventType.AutoPostpone, CalendarEventPrototype!Event, CalendarAutoPostponeEventPrototype!Event);

class EventDescriptor : BaseEventDescriptor {
	
	static Event CreateItem(string type, string[string] data) {
		auto item = BaseEventDescriptor.CreateItem(type, data);

		if("_id" in data) item._id = data["_id"];
		if("name" in data) item.name = data["name"];
		if("startDate" in data) item.startDate = SysTime.fromISOExtString(data["startDate"]);

		if(type == "Basic") {
			if("endDate" in data) item.endDate = SysTime.fromISOExtString(data["endDate"]);
		}

		if(type == "AutoPostpone") {
			if("duration" in data) item.duration = dur!"hnsecs"(data["duration"].to!long);
			if("postpone" in data) item.postpone = dur!"hnsecs"(data["postpone"].to!long);
			if("boundary" in data) item.boundary = dur!"hnsecs"(data["boundary"].to!long);
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
