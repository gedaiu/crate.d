import vibe.d;

import crated.model.mongo;
import crated.controller.base;
import crated.controller.admin;

import std.stdio;

/**
 * A book item prototype
 */
class Book {
	
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
	bool inStock;

	this() {};
}


class BookDescriptor : ModelDescriptor!Book {
	static Book CreateItem(string type, string[string] data) {
		auto myBook = new Book;

		if("_id" in data) myBook._id = data["_id"];
		if("name" in data) myBook.name = data["name"];
		if("author" in data) myBook.author = data["author"];
		if("category" in data) myBook.category = data["category"].to!(Book.BookCategory);
		if("price" in data) myBook.price = data["price"].to!double;
		if("color" in data) myBook.color = data["color"];
		if("inStock" in data) myBook.inStock = data["inStock"].to!bool;

		return myBook;
	}
}

/**
 * Other products prototype
 */
class OtherProducts {
	
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
	bool inStock;

	this() {}
}
/*
class OtherProductsDescriptor : ModelDescriptor!Book {
	static OtherProducts CreateItem(string type, string[string] data) {
		auto myOther = new OtherProducts;
		
		if("_id" in data) myOther._id = data["_id"];
		if("name" in data) myOther.name = data["name"];
		if("category" in data) myOther.category = data["category"].to!(OtherProducts.OtherProductsCategory);
		if("price" in data) myOther.price = data["price"].to!double;
		if("inStock" in data) myOther.inStock = data["inStock"].to!bool;
		
		return myOther;
	}
}*/

alias BookModel = MongoModel!(BookDescriptor, "test.books", "Books");
//alias OtherProductsModel = MongoModel!(OtherProductsDescriptor, "test.otherProducts", "Other products");

///Create the controller
alias DataManagerController = DataManager!("/admin", BookModel/*, OtherProductsModel*/);

/**
 *  Vibe.d init
 */
shared static this()
{	
	//setup the database connection string
	crated.model.mongo.dbAddress = "127.0.0.1";

	//init the data	


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
