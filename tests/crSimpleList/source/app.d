import std.stdio;
import std.conv;
import crated.model.base;

class BookItemPrototype {
	@("field", "primary")
	ulong id;

	@("field") string name = "unknown";
	@("field") string author = "unknown";
}

/**
 * Test the basic model functionality
 */
unittest {
	auto books = new Model!(BookItemPrototype);

	auto item1 = books.createItem;
	item1.id = 1;
	item1.name = "Prelude to Foundation";
	item1.author = "Isaac Asimov";
	item1.save;
	
	auto item2 = books.createItem;
	item2.id = 2;
	item2.name = "The Hunger Games";
	item2.author = "Suzanne Collins";
	item2.save;
	
	auto item3 = books.createItem;
	item3.id = 3;
	item3.name = "The Adventures of Huckleberry Finn";
	item3.author = "Mark Twain";
	item3.save;
	
	auto item4 = books.createItem;
	item4.id = 4;
	item4.name = "The Adventures of Tom Sawyer";
	item4.author = "Mark Twain";
	item4.save;

	auto marksBooks = books.getBy!"author"("Mark Twain");
	assert(marksBooks.length == 2, "getBy length expected to be 2 instead of " ~ marksBooks.length.to!string);
	assert(marksBooks[0].author == "Mark Twain", "getBy[0] author expected to be `Mark Twain`");
	assert(marksBooks[1].author == "Mark Twain", "getBy[0] author expected to be `Mark Twain`");
	
	auto oneItem    = books.getOneBy!"author"("Mark Twain");
	assert(oneItem.name == "The Adventures of Huckleberry Finn", "getOneBy name expected to be `The Adventures of Huckleberry Finn`" );
	assert(oneItem.author == "Mark Twain", "getOneBy author expected to be `Mark Twain`");
	
	auto all          = books.all;
	assert(all.length == 4, "all length expected to be 4");
}

/**
 * Item creation
 */
unittest {
	alias BookModel = Model!BookItemPrototype;
	BookModel model = new BookModel;

	alias BookItem = Item!(BookItemPrototype, model);

	//test the type
	static if (!is(BookModel.ItemCls == BookItem)) {
		assert(false, "ModelTemplate.Itemcls is not the same as " ~ BookItem.stringof);
	}

	static if (!is(typeof(model.createItem()) == BookItem)) {
		assert(false, "`" ~ typeof(model.createItem()).stringof ~ "` ModelTemplate.createItem is not the same as " ~ BookItem.stringof);
	}
}

//check the copy constructor
unittest{
	alias BookModel = Model!BookItemPrototype;
	alias BookItem = Item!(BookItemPrototype, BookModel);

	BookModel model = new BookModel;

	auto dItem = new BookItemPrototype;
	dItem.id = 99;
	dItem.name = "some name";
	dItem.author = "some author";

	auto item = new BookItem(dItem, model);

	assert(dItem.id == item.id, "id was not copied");
	assert(dItem.name == item.name, "name was not copied");
	assert(dItem.author == item.author, "author was not copied");
	assert(model == item.parent, "wrong parent");

	//you should be able to create items from any object 
	//that has the same fields as the item that you want to create
	class FakeItemPrototype {
		ulong id;
		string name;
		string author;
	}

	auto fItem = new FakeItemPrototype;
	fItem.id = 88;
	fItem.name = "fake name";
	fItem.author = "fake author";

	item = new BookItem(fItem, model);
	assert(fItem.id == item.id, "id was not copied");
	assert(fItem.name == item.name, "name was not copied");
	assert(fItem.author == item.author, "author was not copied");
	assert(model == item.parent, "wrong parent");
}



void main()
{
	writeln("OK");
}
