import std.stdio;
import crated.model.base;

class BookItem {
	@field ulong id = 1;
	@field string name = "unknown";
	@field string author = "unknown";
	
	//insert model item code
	mixin MixItem!(BookItem, BookModel);
}

class BookModel {
	//insert model item code
	mixin MixModel!(BookItem, BookModel);
}



void main()
{
	auto books = new BookModel;

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
	assert(oneItem.name == "The Adventures of Huckleberry Finn");
	assert(oneItem.author == "Mark Twain");


	auto all        = books.allItems;
	assert(all.length == 4);


	writeln("OK");
}
