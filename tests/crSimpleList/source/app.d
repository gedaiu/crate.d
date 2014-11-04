import std.stdio;
import crated.model.base;

class BookItem {
	@field @primary 
	ulong id = 1;

	@field string name = "unknown";
	@field string author = "unknown";
}

class BookModel {

}

/*
string generateModelCode(string type, string val) {
	
	string a = "
        class c"~ type ~ "Model { 
             mixin MixModel!(c"~ type ~ "Item,c"~ type ~ "Model); 
	         
             Prototype[] query(T)(T data, int length = 0, int skip = 0) { Prototype[] list; return list; }
             void remove(c"~ type ~ "Item itm) {}
        }

        class c"~ type ~ "Item {
			@field " ~ type ~ " val = "~ val ~";
            @field @primary long id;
			//insert model item code
			mixin MixItem!(c"~ type ~ "Item,c"~ type ~ "Model);
		}";
	
	return a;
}

string generateAssertCode(string type, string expected) {
	string a = "
	auto myC"~ type ~ "Item = new c"~ type ~ "Item(new c"~ type ~ "Model);
	assert(myC"~ type ~ "Item.to!string == `{ \"val\": "~ expected ~" }`, `error on ["~type~"] serialization`);";

	return a;
}



mixin(generateModelCode("bool", "true"));
mixin(generateModelCode("byte", "0"));
mixin(generateModelCode("ubyte", "0"));
mixin(generateModelCode("short", "0"));
mixin(generateModelCode("ushort", "0"));

mixin(generateModelCode("int", "0"));
mixin(generateModelCode("uint", "0"));
mixin(generateModelCode("long", "0"));
mixin(generateModelCode("ulong", "0"));
//TODO: mixin(generateModelCode("cent", "0"));
//TODO: mixin(generateModelCode("ucent", "0"));
mixin(generateModelCode("float", "0"));
mixin(generateModelCode("double", "0"));
mixin(generateModelCode("real", "0"));
mixin(generateModelCode("ifloat", "0i"));
mixin(generateModelCode("idouble", "0i"));
mixin(generateModelCode("ireal", "0i"));
//TODO: mixin(generateModelCode("cfloat", "1.0i"));
//TODO: mixin(generateModelCode("cdouble", "1.0i"));
//TODO: mixin(generateModelCode("creal", "1.0i"));
mixin(generateModelCode("string", `"0"`));
mixin(generateModelCode("wstring", "`0`w"));
mixin(generateModelCode("dstring", "`0`d"));


//check if types are correctly paresed
void testFieldParse() {


	mixin(generateAssertCode("bool", "true"));

	mixin(generateAssertCode("byte", "0"));
	mixin(generateAssertCode("ubyte", "0"));
	mixin(generateAssertCode("short", "0"));
	mixin(generateAssertCode("ushort", "0"));

	mixin(generateAssertCode("int", "0"));
	mixin(generateAssertCode("uint", "0"));
	mixin(generateAssertCode("long", "0"));
	mixin(generateAssertCode("ulong", "0"));
	//TODO: mixin(generateAssertCode("cent", "0"));
	//TODO: mixin(generateAssertCode("ucent", "0"));
	mixin(generateAssertCode("float", "0"));
	mixin(generateAssertCode("double", "0"));
	mixin(generateAssertCode("real", "0"));
	mixin(generateAssertCode("ifloat", `"0i"`));
	mixin(generateAssertCode("idouble", `"0i"`));
	mixin(generateAssertCode("ireal", `"0i"`));
	//TODO: mixin(generateAssertCode("cfloat", "1.0i"));
	//TODO: mixin(generateAssertCode("cdouble", "1.0i"));
	//TODO: mixin(generateAssertCode("creal", "1.0i"));
	mixin(generateAssertCode("string", `"0"`));
	mixin(generateAssertCode("wstring", `"0"`));
	mixin(generateAssertCode("dstring", `"0"`));
}
*/

void main()
{
	auto model = new Model!(BookItem);
	auto item =  new Item!(BookItem, model)(model);




	//auto books = new BookModel;

	/*
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
	assert(all.length == 4);*/

	writeln("OK");
}
