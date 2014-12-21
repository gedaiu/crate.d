import std.stdio : writeln;
import crated.model.mongo;
import std.traits;
import vibe.d;

unittest {
	crated.model.mongo.dbAddress = "127.0.0.1";
}

class Book {

	this() {}

	@("field", "primary") string _id;
	@("field") string name;
	@("field") string author;
}


class BookDescriptor : ModelDescriptor!Book {

	static Prototype CreateItem(string type, string[string] data) {
		auto myBook = ( ModelDescriptor!Book ).CreateItem(type, data);

		if("_id" in data) myBook._id = data["_id"];
		if("name" in data) myBook.name = data["name"];
		if("author" in data) myBook.author = data["author"];
		
		return myBook;
	}
}

alias BookModel = MongoModel!(BookDescriptor, "test.BookModel", "Books");
mixin ModelHelper!BookModel;

unittest {
	BookModel.truncate;
}

//test save
unittest {
	Book item = BookModel.CreateItem;
	item.name = "some name";
	item.author = "some author";
	item.save;
		
	assert(BookModel.length == 1);
	auto savedItem = BookModel.all[0];

	savedItem.convert!Json;

	assert(item.convert!Json == savedItem.convert!Json);
}

//test truncate
unittest {
	auto item = BookModel.CreateItem;
	item.save;
	
	BookModel.truncate;
	
	assert(BookModel.length == 0);
}

//test remove
unittest {

	auto item = BookModel.CreateItem;
	item.save;
	
	assert(BookModel.length == 1);
	
	item.remove;
	
	assert(BookModel.length == 0);
}

unittest {
	auto item = BookModel.CreateItem;
	item.save;
	
	assert(BookModel.length == 1);
	
	BookModel.remove!"_id"(item._id);
	
	assert(BookModel.length == 0);
}

//save and delete multiple values
unittest {
	auto item1 = BookModel.CreateItem;
	auto item2 = BookModel.CreateItem;

	auto list = [item1, item2];

	BookModel.save(list);
	
	assert(BookModel.length == 2);
	
	BookModel.remove([item1, item2]);
	
	assert(BookModel.length == 0);
}

//a complex test
unittest {	
	//create the connection
	BookModel.truncate;

	//the setup
	auto item1 = BookModel.CreateItem;
	item1.name = "Prelude to Foundation";
	item1.author = "Isaac Asimov";
	item1.save;
	
	auto item2 = BookModel.CreateItem;
	item2.name = "The Hunger Games";
	item2.author = "Suzanne Collins";
	item2.save;
	
	auto item3 = BookModel.CreateItem;
	item3.name = "The Adventures of Huckleberry Finn";
	item3.author = "Mark Twain";
	item3.save;
	
	auto item4 = BookModel.CreateItem;
	item4.name = "The Adventures of Tom Sawyer";
	item4.author = "Mark Twain";
	item4.save;

	//checks
	auto marksBookModel = BookModel.getBy!"author"("Mark Twain");
	assert(marksBookModel.length == 2);
	assert(marksBookModel[0].author == "Mark Twain", "invalid author name");
	assert(marksBookModel[1].author == "Mark Twain", "invalid author name");
	
	auto oneItem    = BookModel.getOneBy!"author"("Mark Twain");
	assert(oneItem.author == "Mark Twain", "ca not get by author");
	
	auto all        = BookModel.all;
	assert(all.length == 4, "can't get all elements");

	//do a query
	import vibe.d;

	Json q = Json.emptyObject;
	q["author"] = "Mark Twain";
	auto queryResult = BookModel.query(q);

	assert(queryResult.length == 2);
	assert(queryResult[0].author == "Mark Twain", "invalid author name");
	assert(queryResult[1].author == "Mark Twain", "invalid author name");
}

void main()
{	
	writeln("OK");
}