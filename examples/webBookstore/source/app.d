import vibe.d;

import crated.model.mongo;
import crated.controller.admin;

import std.stdio;

/**
 * The project modelZ
 */
class BookItem {
	enum BookCategory : string {
		Fiction = "Fiction",
		Nonfiction = "Nonfiction"
	};

	@field @primary
	BsonObjectID _id;

	@field @required 
	string name = "unknown";

	@field @required 
	string author = "unknown";

	@field @type!("select")
	BookCategory category;

	@field 
	double price = 100;

	@field @type!"color"
	string color = "#fff";

	@field @required 
	bool inStock = true;

	//insert model item code
	mixin MixItem!(BookItem, BookModel);
}

class BookModel {
	//set the collection name
	private enum string collectionName = "test.books";
	
	//insert model item code
	mixin MixMongoModel!(BookItem, BookModel);
}




/**
 *  Vibe.d init
 */
shared static this()
{	
	//init the data
	MongoClient client = connectMongoDB("127.0.0.1");
	
	auto books = new BookModel(client);
	books.remove();
	
	BookItem item1 = books.createItem;
	item1.name = "Prelude to Foundation";
	item1.author = "Isaac Asimov";
	item1.price = 120;
	item1.inStock = false;
	item1.category = BookItem.BookCategory.Nonfiction;
	item1.save;
	
	auto item2 = books.createItem;
	item2.name = "The Hunger Games";
	item2.author = "Suzanne Collins";
	item2.save;
	
	auto item3 = books.createItem;
	item3.name = "The Adventures of Huckleberry Finn";
	item3.author = "Mark Twain";
	item3.save;
	
	auto item4 = books.createItem;
	item4.name = "The Adventures of Tom Sawyer";
	item4.author = "Mark Twain";
	item4.save;


	//set the web server
	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];

	auto router = new URLRouter;

	auto adminController = new AdminController!("/admin", BookModel, BookItem);

	adminController.addRoutes(router);

	listenHTTP(settings, router);
	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}
