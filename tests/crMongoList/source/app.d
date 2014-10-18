import std.stdio : writeln;
import crated.model.mongo;

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


void test() {
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
	
	auto marksBooks = books.findBy!"author"("Mark Twain");
	assert(marksBooks.length == 2);
	assert(marksBooks[0].author == "Mark Twain");
	assert(marksBooks[1].author == "Mark Twain");
	
	auto oneItem    = books.findOneBy!"author"("Mark Twain");
	assert(oneItem.author == "Mark Twain");
	
	auto all        = books.allItems;
	assert(all.length == 4);
}




void main()
{	
	test();

	writeln("OK");
}