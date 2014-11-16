/**
 * Provides templates to create data models. There are two components that are used 
 * to represent data. Models and Items.
 * 
 * The model is a collection of items and it usualy represents a table. The <code>ModelTemplate</code>
 * provides a standard interface for one dimension model. It can be used directly, 
 * but it does not save it's content.
 * 
 * An Item is a group of fields that usualy represents a table row. The <code>ItemTemplate</code>
 * provides a standard interface for a group of fields. Usualy you should not need to extend this
 * class, but you can check the Item template for more information.
 * 
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: November 3, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module crated.model.base;

import std.stdio;
import std.traits;
import std.algorithm;
import std.conv;
import std.typetuple;

/**
 * Find if type (T) is an enum
 * Example:
 * --------------------------
 * enum BookCategory : string {
 *		Fiction = "Fiction",
 *		Nonfiction = "Nonfiction"
 *	};
 *  
 *  auto test = IsEnum!BookCategory;
 *  assert(test.check == true);
 * --------------------------
 * 
 * Example:
 * --------------------------
 *  auto test = IsEnum!string;
 *  assert(test.check == false);
 * --------------------------
 */
template IsEnum(T) if(is(T == enum)) {
	enum bool check = true;
} 
template IsEnum(T) if(!is(T == enum)) {
	enum bool check = false;
}


/**
 * Check if the method has a from string method
 */
template HasFromString(T) if(is(T == class) || is(T == struct)) {
	enum bool check = __traits(hasMember, T, "fromString");
}

template HasFromString(T) if(!is(T == class) && !is(T == struct)) {
	enum bool check = false;
}

/**
 * Get a class property
 */
template ItemProperty(item, string method) {
	static if(__traits(hasMember, item, method)) {
		alias ItemProperty = TypeTuple!(__traits(getMember, item, method));
	} else {
		alias ItemProperty = TypeTuple!();
	}
}

template getItemFields(alias ATTR, Prototype) {

	string Type(string name)() {
		static if(__traits(isIntegral, ItemProperty!(Prototype, name))) return "isIntegral";
		else static if(__traits(isFloating, ItemProperty!(Prototype, name))) return "isFloating";
		else return "";
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
				static if(staticIndexOf!(ATTR, __traits(getAttributes, ItemProperty!(Prototype, FIELDS[0]))) >= 0) {
					alias ItemFields = TypeTuple!([FIELDS[0], typeof(FIELDS[0]).stringof, Type!(FIELDS[0]) ]);
				} else {
					alias ItemFields = TypeTuple!();
				}
			} else {
				alias ItemFields = TypeTuple!();
			}
			
		} else alias ItemFields = TypeTuple!();
	}

	enum string[][] fields = [ ItemFields!(__traits(allMembers, Prototype)) ];
	alias getItemFields = fields;
}


/**
 * Generate a crated item. A prototype class will be the base of ItemTemplate class which
 * contains helper methods and properties to make you able to use the prototype class with any other 
 * generated crate.d model.
 * 
 * The Item will be generated based on what attribute has every property declared. If you want to treat
 * a property as a db field you have to add <code>@("field")</code> attribute. Also every prototype must have 
 * a <code>@("primary")</code> attribute to let the models look for the primary fields.
 *
 * The default supported attributes are:
 * 	+ <code>field</code>   - an item field
 * 	+ <code>primary</code> - the primary key
 * 
 * But you are free to create and use any other atributes that can describe your Prototype.
 * 
 * Let's take a valid Prototype:
 * 
 * Example: 
 * --------------------
 * class BookItemPrototype {
 * 	@("field", "primary")
 *	ulong id;
 *
 *	@("field") string name = "unknown";
 * 	@("field") string author = "unknown";
 * }
 * --------------------
 * 
 * The most simple way of crate.d item like this:
 * 
 * Example:
 * ---------------------
 * auto books = new Model!(BookItemPrototype);
 * 
 * auto item = books.createItem;
 * ---------------------
 * 
 * As you can see, you can not have an Item without a model. In fact in order to make <code>item.save</code> 
 * and <code>item.detele</code> methods to work, the item has to know who is it's parent,
 * because those methods are shortcuts for <code>model.save(item)</code> or <code>model.delete(item)</code>.
 * 
 * In fact the code that create an Item looks like this:
 * 
 * Example:
 * ---------------------
 * auto books = new Model!(BookItemPrototype);
 * 
 * auto item = new Item!BookItemPrototype(books);
 * ---------------------
 * 
 * If you want to create an alias for the item type you can do it like this:
 * 
 * Example:
 * ---------------------
 * alias ItemCls = Item!BookItemPrototype;
 * 
 * ... or ...
 * 
 * auto books = new Model!(BookItemPrototype);
 * alias ItemCls = Item!(BookItemPrototype, books);
 * ---------------------
 * 
 * =Extending
 * 
 * ... more to be soon ... 
 */
template Item(Prototype, M) {

	class ItemTemplate : Prototype {
		//the item model
		private M myModel;


		//default item constructor
		this(M parent) {
			myModel = parent;
		}

		//a copy constructor
		this(T)(T someItem, M parent) {
			copy!(fields)(someItem);
			this(parent);
		}

		void copy(string[][] fields, T)(T someItem) {
			static if(fields.length == 1) {
				__traits(getMember, this, fields[0][0]) = __traits(getMember, someItem, fields[0][0]);
			} else if(fields.length > 0) {
				copy!(fields[0..$/2])(someItem);
				copy!(fields[$/2..$])(someItem);
			}
		}

		//a pair of a field name and type to be accessed at runtime
		enum string[][] fields = getItemFields!("field", Prototype);


		//a pair of a field name and type to be accessed at runtime
		enum string[] primaryField = getItemFields!("primary", Prototype)[0];
		
		//the field attributes.
		//enum string[string][string] attributes = mixin(getUDA);
		
		//all the enum fields with their keys
		//enum string[][string] enumValues = mixin("[ ``: [] " ~ getEnumValues ~ "]");

		@property
		M parent() {
			return myModel;
		}

		/**
		 * Save the item into model
		 */
		void save() {
			myModel.save(this);
		}

		/**
		 * Delete the item from model
		 */
		void remove() {
			myModel.remove(this);
		}

		/**
		 * Convert the items to a string
		 */
		override string toString() {
			string jsonString = "{ ";
			
			mixin("jsonString ~= `" ~ PropertyJson() ~ "`;");
			
			jsonString ~= " }";

			return jsonString;
		}

		/**
		 * Get Json body for all the item fields
		 */
		private static string PropertyJson() {
			string jsonCode;
			
			string glue = "";
			foreach (field; fields) {
				jsonCode ~= glue ~ "\"" ~ field[0] ~ "\": ";


				if(field[2] == "isIntegral") {
					//is int
					jsonCode ~= "` ~ this." ~ field[0] ~ ".to!string" ~ " ~ `";
				} else if(field[2] == "isFloating") {
					//is float
					jsonCode ~= "` ~ ( this." ~ field[0] ~ ".to!string[$-1..$] == \"i\" ? 
				                         `\"` ~  this." ~ field[0] ~ ".to!string ~ `\"` : 
				                                 this." ~ field[0] ~ ".to!string ) ~ `";
				} else {
					//is something else
					jsonCode ~= "\"` ~ this." ~ field[0] ~ ".to!string" ~ " ~ `\"";
				}
								
				glue = ",\n";
			}
			
			return jsonCode;
		}
	}


	alias Item = ItemTemplate;
}

template Item(Prototype, alias M) {
	alias Item = Item!(Prototype, typeof(M));
}

/*
template Item(alias item, alias M) {
	alias T = Item!(typeof(item), typeof(M));
	alias Item = cast(T) item;
}*/

/**
 * create the code for the item From method
 */
string FromCode(Prototype, T, int i = 0)() {
	enum fields = Prototype.fields;

	//exit condition
	static if(i >= fields.length) {
		return "";
	} else {
		enum auto field = fields[i];

		//check for D types
		static if(field[2] == "basic") {

			static if(field[1] == "bool") {
				return `try { itm.`~field[0]~` = elm["`~field[0]~`"].to!`~field[1]~`; } catch(Exception e) {itm.`~field[0]~` = false; }` ~ FromCode!(Prototype, T, i + 1);
			} else {
				return `itm.`~field[0]~` = elm["`~field[0]~`"].to!`~field[1]~`;` ~ FromCode!(Prototype, T, i + 1);
			}
		} else static if(field[2] == "enum") {
			return `itm.`~field[0]~` = elm["`~field[0]~`"].to!string.to!`~field[1]~`;` ~ FromCode!(Prototype, T, i + 1);
		} else static if(field[2] == "hasFromString") {
			return `itm.`~field[0]~` = `~field[1]~`.fromString(elm["`~field[0]~`"].to!string);` ~ FromCode!(Prototype, T, i + 1);
		} else {

			return FromCode!(Prototype, T, i + 1);
		}
	}
}

template Model(Prototype) {



	//the model template
	class ModelTemplate {
		//the item type
		alias ItemCls = Item!(Prototype, ModelTemplate);

		ItemCls[] items;

		/**
		 * Add ot update an element
		 */
		void save(ItemCls item) {
			auto itemId = __traits(getMember, item, (ItemCls.primaryField[0]));
			bool added = false;

			foreach(i; 0..items.length) {
				auto currentId = __traits(getMember, items[i], (ItemCls.primaryField[0]));

				if(itemId == currentId) {
					items[i] = item;
					return;
				}
			}

			items ~= [item];
		}

		/**
		 * Remove an existing item
		 */
		void remove(T)(T item) {

		}

		/**
		 * Remove all items
		 */
		void clean() {
			items = [];
		}

		/**
		 * Create a new item. The returned item will not be 
		 * automatically added to the model. If you want to add it to a model
		 * call Item.save()
		 */
		ItemCls createItem() {
			ItemCls item = new ItemCls(this);

			return item;
		}

		/**
		 * Retrieve all items
		 */
		ItemCls[] all() {
			return items;
		}

		/**
		 * Query the model
		 */
		ItemCls[] query() {
			return items;
		}

		/**
		 * Count an item set 
		 */
		ulong length(string fieldName, T)(T value) {
			ulong sum = 0;

			foreach(i; 0..items.length) {
				sum += __traits(getMember, items[i], fieldName) == value ? 1 : 0;
			}

			return sum;
		}

		/**
		 * Count all items
		 */
		ulong length() {
			return items.length;
		}

		/**
		 * Find all items that match the search criteria 
		 */
		ItemCls[] getBy(string fieldName, T)(T value) {
			ItemCls[] r;

			foreach(i; 0..items.length) {
				if(__traits(getMember, items[i], fieldName) == value) {
					r ~= [ items[i] ];
				}
			}

			return r;
		}

		/**
		 * retrieve the first item that match the search
		 * criteria
		 */
		ItemCls getOneBy(string fieldName, T)(T value) {
			foreach(i; 0..items.length) {
				if(__traits(getMember, items[i], fieldName) == value) {
					return items[i];
				}
			}

			return null;
		}

		/**
		 * Convert the items to a string
		 */
		override string toString() {
			return items.to!string;
		}

	}

	mixin MixCheckFieldsModel!ModelTemplate;
	alias Model = ModelTemplate;
}

/**
 * Generate code that checks if a certain method is declared 
 */
string _genChkMember(M, string name)() {
	static if(!__traits(hasMember, M, name)) {

		pragma(msg, "Have you forgot to declare method ["~name~"] for [", M ,"]?");
	}

	return "";
}

/**
 * This template is used to check if a model has declared all the methods
 */
mixin template MixCheckFieldsModel(M) {
	mixin(_genChkMember!(M, "createItem"));

	mixin(_genChkMember!(M, "save"));
	mixin(_genChkMember!(M, "remove"));
	mixin(_genChkMember!(M, "clean"));

	mixin(_genChkMember!(M, "all"));

	mixin(_genChkMember!(M, "query"));
	mixin(_genChkMember!(M, "getBy"));
	mixin(_genChkMember!(M, "getOneBy"));
}
