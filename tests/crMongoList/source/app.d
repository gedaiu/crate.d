import std.stdio : writeln;
import crated.model.mongo;

class BookItemPrototype {
	@("field", "primary") string _id;
	@("field") string name;
	@("field") string author;
}


unittest {
	auto books = new MongoModel!BookItemPrototype("127.0.0.1", "test.books");
	books.truncate;
}

//test save
unittest {
	auto books = new MongoModel!BookItemPrototype("127.0.0.1", "test.books");
	auto item = books.createItem;
	item.save;
		
	assert(books.length == 1);

	auto savedItem = books.all[0];
	assert(item == savedItem);
}

//test truncate
unittest {
	auto books = new MongoModel!BookItemPrototype("127.0.0.1", "test.books");
	auto item = books.createItem;
	item.save;
	
	books.truncate;
	
	assert(books.length == 0);
}

//test remove
unittest {
	auto books = new MongoModel!BookItemPrototype("127.0.0.1", "test.books");
	auto item = books.createItem;
	item.save;
	
	assert(books.length == 1);
	
	item.remove;
	
	assert(books.length == 0);
}

unittest {
	auto books = new MongoModel!BookItemPrototype("127.0.0.1", "test.books");
	auto item = books.createItem;
	item.save;
	
	assert(books.length == 1);
	
	books.remove!"_id"(item._id);
	
	assert(books.length == 0);
}

//save and delete multiple values
unittest {
	auto books = new MongoModel!BookItemPrototype("127.0.0.1", "test.books");
	auto item1 = books.createItem;
	auto item2 = books.createItem;

	books.save([item1, item2]);
	
	assert(books.length == 2);
	
	books.remove([item1, item2]);
	
	assert(books.length == 0);
}

//a complex test
unittest {	
	//create the connection
	auto books = new MongoModel!BookItemPrototype("127.0.0.1", "test.books");
	books.truncate;

	//the setup
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

	//checks
	auto marksBooks = books.getBy!"author"("Mark Twain");
	assert(marksBooks.length == 2);
	assert(marksBooks[0].author == "Mark Twain", "invalid author name");
	assert(marksBooks[1].author == "Mark Twain", "invalid author name");
	
	auto oneItem    = books.getOneBy!"author"("Mark Twain");
	assert(oneItem.author == "Mark Twain", "ca not get by author");
	
	auto all        = books.all;
	assert(all.length == 4, "can't get all elements");

	//do a query
	import vibe.d;

	Json q = Json.emptyObject;
	q["author"] = "Mark Twain";
	auto queryResult = books.query(q);

	assert(queryResult.length == 2);
	assert(queryResult[0].author == "Mark Twain", "invalid author name");
	assert(queryResult[1].author == "Mark Twain", "invalid author name");
}

void main()
{	
	writeln("OK");
}