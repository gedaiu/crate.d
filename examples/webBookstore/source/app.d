import vibe.d;
import crate.d.mongoModel;
import crate.d.vibedController;
import crate.d.view;
import std.stdio;

/**
 * The project modelZ
 */
class BookItem {
	@field BsonObjectID _id;
	@field string name = "unknown";
	@field string author = "unknown";
	
	//
	static BookItem FromJson(BookModel parent, Json elm) {
		BookItem itm = new BookItem(parent);
		
		itm._id = BsonObjectID.fromString(elm._id.to!string);
		itm.name = elm.name.to!string;
		itm.author = elm.author.to!string;
		
		return itm;
	}
	
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
 * The project controller
 */
class BookController {
	/**
	 * The list page
	 */
	@HttpRequest("GET", "/")
	static void index(HTTPServerRequest req, HTTPServerResponse res) {
		res.writeBody( renderDh!"list.dh" , "text/html; charset=UTF-8");
	}

	/**
	 * The edit page
	 */
	@HttpRequest("GET", "/edit/:id")
	static void edit(HTTPServerRequest req, HTTPServerResponse res) {
		res.headers.remove("Content-Type");
		res.writeBody( "edit" );
	}

	//insert controller code
	mixin MixVibedController!(BookController);
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
	
	auto item1 = books.createItem;
	item1.name = "Prelude to Foundation";
	item1.author = "Isaac Asimov";
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

	BookController.addRoutes(router);

	listenHTTP(settings, router);
	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}
