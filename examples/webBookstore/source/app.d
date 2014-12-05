import vibe.d;

import crated.model.mongo;
import crated.controller.base;
import crated.controller.admin;

import std.stdio;

/**
 * A book item prototype
 */
class BookPrototype {
	
	enum BookCategory : string {
		Fiction = "Fiction",
		Nonfiction = "Nonfiction"
	};
	
	@("field", "primary")
	string _id;
	
	@("field", "required") 
	string name = "unknown";
	
	@("field", "required") 
	string author = "unknown";
	
	@("field") 
	BookCategory category;
	
	@("field", "required") 
	double price = 100;
	
	@("field", "required", "type:color") 
	string color = "#fff";
	
	@("field") 
	bool inStock = true;

	this() {};
}

/**
 * Other products prototype
 */
class OtherProductsPrototype {
	
	enum OtherProductsCategory : string {
		Tea = "Tea",
		Games = "Games",
		Other = "Other"
	};
	
	@("field", "primary")
	string _id;
	
	@("field", "required") 
	string name = "unknown";

	@("field") 
	OtherProductsCategory category;
	
	@("field", "required") 
	double price = 100;

	@("field") 
	bool inStock = true;

	this() {}
}

/**
 *  Vibe.d init
 */
shared static this()
{	
	//setup the database connection string
	crated.model.mongo.dbAddress = "127.0.0.1";

	//init the data	
	alias BookModel = MongoModel!(BookPrototype, "test.books", "Books");
	alias OtherProductsModel = MongoModel!(OtherProductsPrototype, "test.otherProducts", "Other products");

	alias DataManagerController = DataManager!("/admin", BookModel, OtherProductsModel);

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
	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}
