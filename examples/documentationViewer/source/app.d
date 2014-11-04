import vibe.d;

import crated.model.base;
import crated.view.base;
import crated.controller.vibed;

import std.stdio;
import std.file;

enum docsJsonPath = "../../docs.json";

/**
 * 
 */
class ModuleItem {

	@field @primary
	string id;

	@field
	string description = "no description";

	@field
	DocsMemberModel members;


	this(Json data) {
		id = data.name.to!string;
		description = data.comment.to!string.split("\n")[0];
		members = new DocsMemberModel(data.members);
	}


	mixin MixItem!(ModuleItem, DocsModuleModel);
}


/**
 * 
 */
class DocsMemberModel {
	this(Json data) {

	}
}


/**
 * The module model is a collection with all modules
 */
class DocsModuleModel {

	ModuleItem[] items;

	/**
	 * Read the Json file and parse the documentation
	 */
	this(const string path) {
		auto content = path.readText;

		Json modelData = content.parseJsonString;

		items.reserve(modelData.length);

		foreach(i; 0..modelData.length) {
			items ~= [ new ModuleItem(modelData[i]) ]; 
		}
	}

	/**
	 * 
	 */
	@property
	string[string] categories() {
		string[string] categories;

		foreach(i;0..items.length) {
			string name = items[i].id["crated.".length..$];

			categories[name] = items[i].description;
		}

		return categories;
	}


	mixin MixModel!(ModuleItem, DocsModuleModel);
}

class DocsController {

	/**
	 * The list page
	 */
	@HttpRequest("GET", "/docs")
	static void docPage(HTTPServerRequest req, HTTPServerResponse res) {
		auto docsModule = new DocsModuleModel(docsJsonPath);

		auto categories = docsModule.categories;

		res.writeBody( renderDh!"moduleList.dh"(categories), "text/html; charset=UTF-8");
	}

	/**
	 * The list page
	 */
	@HttpRequest("GET", "/docs/*")
	static void docMemberPage(HTTPServerRequest req, HTTPServerResponse res) {
		
		string path = req.requestURL["/docs/".length .. $];
		auto pathSlices = path.split("/");

		//display a module documentation
		if(pathSlices.length == 1) {
			auto docsModule = new DocsModuleModel(docsJsonPath);

			auto result = docsModule.find!"id"(pathSlices[0]);

			res.writeBody( result.to!string, "text/html; charset=UTF-8");
		}

	}
	
	//insert controller code
	mixin MixVibedController!(DocsController);
}



/**
 *  Vibe.d init
 */
shared static this()
{	
	//init the data
	MongoClient client = connectMongoDB("127.0.0.1");

	//set the web server
	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];
	
	auto router = new URLRouter;

	auto docsController = new DocsController;
	
	docsController.addRoutes(router);
	router.get("*", serveStaticFiles("./public/"));

	listenHTTP(settings, router);
	logInfo("Please open http://127.0.0.1:8080/docs in your browser.");
}
