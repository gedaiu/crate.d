module crated.model.base;

import std.stdio;
public  import std.conv;
public  import std.typetuple;


/// User defined attribute (not intended for direct use)
struct FieldAttribute {}

/**
 *	Attribute marking an item field
 */
@property FieldAttribute field()
{
	return FieldAttribute();
}


/**
 * This template is used to represent one item from a model
 */
public mixin template MixItem(Prototype, Model) {

	private Model myModel;

	this(Model parent) {
		myModel = parent;
	}

	/**
	 * Get a class property
	 */
	private template ItemProperty(item, string method) {

		static if(__traits(hasMember, item, method)) {
			alias ItemProperty = TypeTuple!(__traits(getMember, item, method));
		} else {
			alias ItemProperty = TypeTuple!();
		}
	}

	/** 
	 * Get all the metods that have @field attribute
	 */
	template ItemFields(FIELDS...) {
		static if (FIELDS.length > 1) {
			alias ItemFields = TypeTuple!(
									ItemFields!(FIELDS[0 .. $/2]),
									ItemFields!(FIELDS[$/2 .. $])
								); 
		} else static if (FIELDS.length == 1 && FIELDS[0] != "modelFields") {

			static if(__traits(hasMember, Prototype, FIELDS[0])) {
				static if(staticIndexOf!(field, __traits(getAttributes, ItemProperty!(Prototype, FIELDS[0]))) >= 0) {
					alias ItemFields = TypeTuple!(FIELDS[0]);
				} else {
					alias ItemFields = TypeTuple!();
				}
			} else {
				alias ItemFields = TypeTuple!();
			}

		} else alias ItemFields = TypeTuple!();
	}

	/**
	 * Return all the model fields
	 */
	enum modelFields = [ ItemFields!(__traits(allMembers, Prototype)) ];


	/**
	 * Get Json body for all the item fields
	 */
	private static string propertyJson() {
		string a;

		string glue = "";
		foreach (mname; ItemFields!(__traits(allMembers, Prototype))) {
			a ~= glue ~ "\"" ~ mname ~ "\": ";

			static if(__traits(isIntegral, ItemProperty!(Prototype, mname))) {
				//is int
				a ~= "` ~ this." ~ mname ~ ".to!string" ~ " ~ `";
			} else static if(__traits(isFloating, ItemProperty!(Prototype, mname))) {
				//is float
				a ~= "` ~ ( this." ~ mname ~ ".to!string[$-1..$] == \"i\" ? 
				                         `\"` ~  this." ~ mname ~ ".to!string ~ `\"` : 
				                                 this." ~ mname ~ ".to!string ) ~ `";
			} else {
				//is something else
				a ~= "\"` ~ this." ~ mname ~ ".to!string" ~ " ~ `\"";
			}

			glue = ",\n";
		}

		return a;
	}

	/**
	 * Save the item into the model
	 */
	void save() {
		myModel.save(this);
	}

	/**
	 * Convert item to string
	 */
	override string toString() {

		string a = "{ ";

		mixin("a ~= `" ~ propertyJson() ~ "`;");

		a ~= " }";

		return a;
	}
}

//TODO: unittest : check field parse


//check if types are correctly paresed
/*unittest {

	string generateValCode(string type, string val, string expected) {

		string a = "
        class c"~ type ~ "Model { mixin MixModel!(c"~ type ~ "Item,c"~ type ~ "Model); }
        class c"~ type ~ "Item {
			@field " ~ type ~ " val = "~ val ~";

			//insert model item code
			mixin MixItem!(c"~ type ~ "Item,c"~ type ~ "Model);
		}

		auto myC"~ type ~ "Item = new c"~ type ~ "Item;
		assert(myC"~ type ~ "Item.to!string == `{ \"val\": "~ expected ~" }`, `error on ["~type~"] serialization`);";

		return a;
	}

	mixin(generateValCode("bool", "true", "true"));
	mixin(generateValCode("byte", "0", "0"));
	mixin(generateValCode("ubyte", "0", "0"));
	mixin(generateValCode("short", "0", "0"));
	mixin(generateValCode("ushort", "0", "0"));

	mixin(generateValCode("int", "0", "0"));
	mixin(generateValCode("uint", "0", "0"));
	mixin(generateValCode("long", "0", "0"));
	mixin(generateValCode("ulong", "0", "0"));
	//TODO: mixin(generateValCode("cent", "0"));
	//TODO: mixin(generateValCode("ucent", "0"));
	mixin(generateValCode("float", "0", "0"));
	mixin(generateValCode("double", "0", "0"));
	mixin(generateValCode("real", "0", "0"));
	mixin(generateValCode("ifloat", "0i", `"0i"`));
	mixin(generateValCode("idouble", "0i", `"0i"`));
	mixin(generateValCode("ireal", "0i", `"0i"`));
	//TODO: mixin(generateValCode("cfloat", "1.0i"));
	//TODO: mixin(generateValCode("cdouble", "1.0i"));
	//TODO: mixin(generateValCode("creal", "1.0i"));
	mixin(generateValCode("string", `"0"`, `"0"`));
	mixin(generateValCode("wstring", "`0`w", `"0"`));
	mixin(generateValCode("dstring", "`0`d", `"0"`));
}
*/

/**
 * This template is used to represent one item from a model
 */
public mixin template MixModel(Prototype, Model) {
	Prototype[] items;

	/**
	 * Create one item
	 */
	Prototype createItem() {
		auto item = new Prototype(this);
		item.id = items.length + 1;
		items ~= [ item ];

		return item;
	}

	/**
	 * Save the item
	 */
	void save(Prototype item) {
		items[item.id-1] = item;
	}	
	
	/**
	 * Get all model items
	 */
	auto allItems() {
		return items;
	}
	
	/**
	 * Return all the items that match the query
	 */
	Prototype[] findBy(string field, U)(U value) {
		Prototype[] list;

		foreach(j; 0..items.length) {
			if(mixin("items[j]." ~ field ~ " == value")) {
				list ~= items[j];
			}
		}

		return list;
	}
	
	/**
	 * Returns first item that match the query
	 */
	Prototype findOneBy(string field, U)(U value) {
		Prototype item;

		foreach(j; 0..items.length) {
			if(mixin("items[j]." ~ field ~ " == value")) {
				return items[j];
			}
		}

		return null;
	}


	mixin MixCheckFieldsModel!(Model);
}

/**
 * Generate code that checks if a certain method is declared 
 */
string _genChkMember(Model, string name)() {
	static if(!__traits(hasMember, Model, name)) {

		pragma(msg, "Have you forgot to declare method ["~name~"] for [", Model ,"]?");
	}

	return "";
}

/**
 * This template is used to check if a model has declared all the methods
 */
public mixin template MixCheckFieldsModel(Model) {

	mixin(_genChkMember!(Model, "createItem"));

	mixin(_genChkMember!(Model, "save"));
	mixin(_genChkMember!(Model, "remove"));

	mixin(_genChkMember!(Model, "allItems"));

	mixin(_genChkMember!(Model, "query"));
	mixin(_genChkMember!(Model, "findBy"));
	mixin(_genChkMember!(Model, "findOneBy"));

}

//TODO: unittest check model name
/*unittest {
	Model books = new Model("books");

	assert(books.modelName == "books");
}*/
