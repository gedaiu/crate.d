/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 12 21, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module source.prototypes.book;

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