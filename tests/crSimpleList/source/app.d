/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 11 18, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module source.app;

import std.stdio;
import std.conv;
import crated.model.base;

class Book {
	@("field", "primary")
	ulong id;

	@("field") string name = "unknown";
	@("field") string author = "unknown";

	this() {}
}


class BookDescriptor : ModelDescriptor!Book {
	Book createBook(string type, string[string] data) {
		auto myBook = new Book;
		
		if("_id" in data) myBook.id = data["id"].to!ulong;
		if("name" in data) myBook.name = data["name"];
		if("author" in data) myBook.author = data["author"];
		 
		return myBook;
	}
}



alias BookModel = Model!(createBook);
mixin ModelHelper!BookModel;


/**
 * Test the basic model functionality
 */
unittest {
	auto item1 = BookModel.CreateItem;
	item1.id = 1;
	item1.name = "Prelude to Foundation";
	item1.author = "Isaac Asimov";
	item1.save;
	
	auto item2 = BookModel.CreateItem;
	item2.id = 2;
	item2.name = "The Hunger Games";
	item2.author = "Suzanne Collins";
	item2.save;
	
	auto item3 = BookModel.CreateItem;
	item3.id = 3;
	item3.name = "The Adventures of Huckleberry Finn";
	item3.author = "Mark Twain";
	item3.save;
	
	auto item4 = BookModel.CreateItem;
	item4.id = 4;
	item4.name = "The Adventures of Tom Sawyer";
	item4.author = "Mark Twain";
	item4.save;

	auto marksBookModel = BookModel.getBy!"author"("Mark Twain");
	assert(marksBookModel.length == 2, "getBy length expected to be 2 instead of " ~ marksBookModel.length.to!string);
	assert(marksBookModel[0].author == "Mark Twain", "getBy[0] author expected to be `Mark Twain`");
	assert(marksBookModel[1].author == "Mark Twain", "getBy[0] author expected to be `Mark Twain`");
	
	auto oneItem    = BookModel.getOneBy!"author"("Mark Twain");
	assert(oneItem.name == "The Adventures of Huckleberry Finn", "getOneBy name expected to be `The Adventures of Huckleberry Finn`" );
	assert(oneItem.author == "Mark Twain", "getOneBy author expected to be `Mark Twain`");
	
	auto all          = BookModel.all;
	assert(all.length == 4, "all length expected to be 4");
}

void main()
{
	writeln("OK");
}
