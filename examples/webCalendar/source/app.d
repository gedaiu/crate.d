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

	static Event CreateItem(string type, string[string] data) {
		auto item = BaseEventDescriptor.CreateItem(type, data);

		if("_id" in data) item._id = data["_id"];
		if("name" in data) item.name = data["name"];

		setDefaultEventFields(item, type, data);

		return item;
	}
}

class LocalResource : Resource {
	@("field", "primary")
	string _id;
	
	@("field", "required") 
	string name;

}

alias BaseResourceDescriptor = ModelDescriptor!LocalResource;

class ResourceDescriptor : BaseResourceDescriptor {

}

alias CalendarModel = MongoModel!(EventDescriptor, "test.calendar", "Calendar");
alias ResourceModel = MongoModel!(ResourceDescriptor, "test.resources", "Resources");

alias DataManagerController = DataManager!("/admin", CalendarModel, ResourceModel);

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
