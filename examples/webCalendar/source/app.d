import vibe.d;

import crated.model.calendar;
import crated.model.mongo;
import crated.controller.base;
import crated.controller.admin;

import std.stdio;

abstract class MyEvent : CalendarEvent {
	@("field", "primary")
	string _id;

	@("field", "required") 
	string name = "unknown";

	this() {}
}

MyEvent createEvent(string type, string[string] data) {

	if(type == EventType.Basic.to!string || type == "") {
		return new CalendarEventPrototype!MyEvent;
	}

	if(type == EventType.Unknown.to!string) {
		return new CalendarUnknownEventPrototype!MyEvent;
	}

	throw new Exception("Unknown type " ~ type);
}

alias CalendarModel = MongoModel!(createEvent, "test.calendar", "Calendar");

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
