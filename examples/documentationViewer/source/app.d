import vibe.d;

import crated.model.base;
import crated.view.base;
import crated.controller.vibed;

import std.stdio;
import std.file;

import docsModule;

enum docsJsonPath = "../../docs.json";



/**
 * 
 */
class DocsController {

	/**
	 * The index page page
	 */
	@HttpRequest("GET", "/docs")
	static void docPage(HTTPServerRequest req, HTTPServerResponse res) {
		auto docsModel = new DocsModuleModel(docsJsonPath);
		
		string[string] data;
		
		data["tableOfContents"] = renderDh!"tableOfContents.dh"(docsModel);
		data["breadcrumbs"] = renderDh!"breadcrumbs.dh"("");
		data["content"] = "content";
		
		res.writeBody( renderDh!"docs.dh"(data), "text/html; charset=UTF-8");
	}

	/**
	 * ditto
	 */
	@HttpRequest("GET", "/docs/")
	static void docPage2(HTTPServerRequest req, HTTPServerResponse res) {
		docPage(req, res);
	}

	/**
	 * The list page
	 */
	@HttpRequest("GET", "/docs/*")
	static void docMemberPage(HTTPServerRequest req, HTTPServerResponse res) {
		auto docsModel = new DocsModuleModel(docsJsonPath);
		
		string[string] data;

		if(req.requestURL[$-1..$] == "/") {
			req.requestURL = req.requestURL[0..$-1];
		}

		auto content = docsModel.getBy!"path"(req.requestURL);

		if(content.length > 0) { 
			data["tableOfContents"] = renderDh!"tableOfContents.dh"(docsModel);
			data["breadcrumbs"] = renderDh!"breadcrumbs.dh"(req.requestURL);
			data["content"] = renderDh!"docsContent.dh"(content);

			res.writeBody( renderDh!"docs.dh"(data), "text/html; charset=UTF-8");
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
