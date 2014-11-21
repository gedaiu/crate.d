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
import std.string;
import std.traits;
import std.algorithm;
import std.conv;
import std.typetuple;


/**
 * 
 */
class CratedModelException : Exception {
	this(string msg, string file = __FILE__, ulong line = cast(ulong)__LINE__, Throwable next = null) {
		super(msg, file, line, next);
	}
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
 * 
 * =Creating new Item templates
 */
template Item(Prototype, M) {

	/**
	 * The Prototype wrapper. Every Item is created by wrapping a Prototype class with this class. <code>ItemTemplate</code>
	 * contains methods to manipulate the Prototype like save and delete. 
	 * 
	 * 
	 */
	class ItemTemplate : Prototype {
		/**
		 * Private: The parent model
		 */
		private M myModel;


		/**
		 * Default constructor
		 */
		this(M parent) {
			myModel = parent;
		}

		/**
		 * Copy constructor
		 */
		this(T)(T someItem, M parent) {
			copy!fields(someItem);
			this(parent);
		}

		/**
		 * Copy data from an object that have the same fields
		 */
		void copy(string[][] fields, T)(T someItem) {
			static if(fields.length == 1) {
				static if( is( typeof(__traits(getMember, this, fields[0][0]) ) == typeof(__traits(getMember, someItem, fields[0][0]) ) ) ) {

					__traits(getMember, this, fields[0][0]) = __traits(getMember, someItem, fields[0][0]);
				} else {
					static if(fields[0][2] == "isEnum") {
						__traits(getMember, this, fields[0][0]) = __traits(getMember, someItem, fields[0][0]).to!string.to!(typeof(__traits(getMember, this, fields[0][0])));
					} else {
						__traits(getMember, this, fields[0][0]) = __traits(getMember, someItem, fields[0][0]).to!(typeof(__traits(getMember, this, fields[0][0])));
					}
				}

			} else if(fields.length > 0) {
				copy!(fields[0..$/2])(someItem);
				copy!(fields[$/2..$])(someItem);
			}
		}

		/**
		 * A pair of a field name and type to be accessed at runtime
		 */
		static enum string[][] fields = getItemFields!("field", Prototype, false);


		/**
		 * a pair of a field name and type to be accessed at runtime
		 */
		static enum string[] primaryField = getItemFields!("primary", Prototype, false)[0];

		//the field attributes.
		enum string[][] attributes = getItemFields!("field", Prototype, true);
		
		//all the enum fields with their keys
		enum string[][string] enumValues = mixin("[ ``: [] " ~ getEnumValues ~ "]");

		/**
		 * Generate the values for the enums from the current item
		 */
		private static string getEnumValues(ulong i = 0)() {

			//exit condition
			static if(i >= fields.length) {
				return "";
			} else {
				enum auto field = fields[i];
				
				//check for D types
				static if(field[2] == "isEnum") {
					import std.traits;
					
					string vals = "";
					
					string glue = "";
					foreach(v; EnumMembers!(typeof(__traits(getMember, Prototype, field[0])))) {
						vals ~= glue ~ `"` ~ v.stringof[1..$-1] ~ `"`; 
						glue ~= ", ";
					}
					
					return `, "` ~ field[0] ~ `": [` ~ vals ~ `]` ~ getEnumValues!(i + 1);
				} else {
					return getEnumValues!(i + 1);
				}
			}
			
		}

		/**
		 * Parent model
		 */
		@property
		M parent() {
			return myModel;
		}

		/**
		 * Save item
		 */
		void save() {
			myModel.save(this);
		}

		/**
		 * Delete item from the parent model
		 */
		void remove() {
			myModel.remove(this);
		}

		/**
		 * Convert item to string
		 */
		override string toString() {
			string jsonString = "{ ";
			
			mixin("jsonString ~= `" ~ PropertyJson() ~ "`;");
			
			jsonString ~= " }";

			return jsonString;
		}

		@property
		typeof(__traits(getMember, this, primaryField[0])) primaryKeyValue() {
			return __traits(getMember, this, primaryField[0]);
		}
		
		/**
		 * 
		 */
		static bool fieldHas(T)(T fieldName, string attribute) {
			return false;
		}

		/**
		 * 
		 */
		static string valueOf(string fieldName, string attribute) {
			foreach(list; attributes) {
				if(list[0] == fieldName) {

					foreach(i; 1..list.length) {
						auto index = list[i].indexOf(":");

						if(index > 0 && list[i][0..index] == attribute) {
							return list[i][index+1..$];
						}
					}
				}
			}

			return "";
		}

		/**
		 * == operator overload. It will check if the fields of the current Item are equals to the other one.
		 */
		override bool opEquals(Object o) {
			return isFieldEqual!(fields)(cast(typeof(this)) o);
		}

		string fieldAsString(string fieldName)() {
			return __traits(getMember, this, fieldName).to!string;
		}

		/**
		 * Check if the fields are equal
		 */
		private bool isFieldEqual(string[][] fields, T)(T o) {
			static if(fields.length == 1) {
				static if( is( typeof(__traits(getMember, this, fields[0][0]) ) == typeof(__traits(getMember, o, fields[0][0]) ) ) ) {
					return __traits(getMember, this, fields[0][0]) == __traits(getMember, o, fields[0][0]);
				} else {
					return __traits(getMember, this, fields[0][0]) == __traits(getMember, o, fields[0][0]).to!(typeof(__traits(getMember, this, fields[0][0])));
				}
				
			} else if(fields.length > 0) {
				return isFieldEqual!(fields[0..$/2])(o) && isFieldEqual!(fields[$/2..$])(o);
			}
		}

		/**
		 * Private: Get code that generate the Json
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


	
	/**
	 * Find if type (T) is an enum.
	 * Example:
	 * --------------------------
	 * enum BookCategory : string {
	 *		Fiction = "Fiction",
	 *		Nonfiction = "Nonfiction"
	 * };
	 *  
	 * auto test = IsEnum!BookCategory;
	 * assert(test.check == true);
	 * --------------------------
	 * 
	 * Example:
	 * --------------------------
	 *  auto test = IsEnum!string;
	 *  assert(test.check == false);
	 * --------------------------
	 */
	template IsEnum(T) if(is(T == enum)) {
		/**
		 * is true if T is enum
		 */
		enum bool check = true;
	} 
	
	template IsEnum(T) if(!is(T == enum)) {
		/**
		 * is true if T is enum
		 */
		enum bool check = false;
	}
	
	
	/**
	 * Check if the method has a from string method.
	 * 
	 * Example: 
	 * --------------------
	 * class BookItemPrototype {
	 * 	private string name;
	 * 
	 * 	this(string name) {
	 *  	this.name = name;
	 * 	}
	 * 
	 * 	static BookItemPrototype FromString(string name) {
	 * 		return new BookItemPrototype(name);
	 *  }
	 * }
	 * 
	 * assert(HasFromString!BookItemPrototype == true);
	 * assert(HasFromString!Object == false);
	 * --------------------
	 * 
	 */
	template HasFromString(T) if(is(T == class) || is(T == struct)) {
		/**
		 * is true if T has `from string` method
		 */
		enum bool check = __traits(hasMember, T, "fromString");
	}
	
	template HasFromString(T) if(!is(T == class) && !is(T == struct)) {
		/**
		 * is true if T has `from string` method
		 */
		enum bool check = false;
	}
	
	/**
	 * Get a class property.
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
	 * 
	 * assert(__traits(isIntegral, ItemProperty!(BookItemPrototype, "id")) == true);
	 * --------------------
	 */
	template ItemProperty(item, string method) {
		static if(__traits(hasMember, item, method)) {
			alias ItemProperty = TypeTuple!(__traits(getMember, item, method));
		} else {
			alias ItemProperty = TypeTuple!();
		}
	}


	/** 
	 * Get all members that have ATTR attribute.
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
	 * 
	 * 
	 * enum string[][] fields = getItemFields!("field", BookItemPrototype);
	 * 
	 * assert(fields[0][0] == "id");
	 * assert(fields[0][1] == "ulong");
	 * assert(fields[0][2] == "isIntegral");
	 * 
	 * --------------------
	 */
	template getItemFields(alias ATTR, Prototype, bool addFields) {

		/**
		 *  Get a general type
		 */
		string Type(string name)() {

			alias isEnum = IsEnum!(typeof(ItemProperty!(Prototype, name)));

			static if(isEnum.check) return "isEnum";
				else static if(__traits(isIntegral, ItemProperty!(Prototype, name))) return "isIntegral";
				else static if(__traits(isFloating, ItemProperty!(Prototype, name))) return "isFloating";
				else static if( is(ItemProperty!(Prototype, name) == enum) )  return "isEnum";
				else return "";
		}
		
		/** 
		 * Get all the metods that have ATTR attribute
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

						static if(addFields) {
							alias ItemFields = TypeTuple!([FIELDS[0], __traits(getAttributes, ItemProperty!(Prototype, FIELDS[0])) ]);

						} else {
							alias ItemFields = TypeTuple!([FIELDS[0], typeof(ItemProperty!(Prototype, FIELDS[0])).stringof[1..$-1], Type!(FIELDS[0]) ]);
						}
					} else {
						alias ItemFields = TypeTuple!();
					}
				} else {
					alias ItemFields = TypeTuple!();
				}
				
			} else alias ItemFields = TypeTuple!();
		}
		
		/**
		 * All the members that have ATTR attribute
		 */
		enum string[][] fields = [ ItemFields!(__traits(allMembers, Prototype)) ];

		alias getItemFields = fields;
	}
	

	alias Item = ItemTemplate;
}

template Item(Prototype, alias M) {
	alias Item = Item!(Prototype, typeof(M));
}

/**
 * 
 * =Extending
 * .. more to come ..
 * 
 * =Creating new Item templates
 * 
 * ==Step 1
 * 
 * Create a new template that take a Type as parameter;
 * 
 * Example: 
 * ----------
 * template CustomModel(Prototype) {
 * 
 * }
 * ----------
 * 
 * ==Step 2
 * 
 * Add a new class in the template and set the template alias to this class;
 * 
 * Example: 
 * ----------
 * template CustomModel(Prototype) {
 * 	
 *	class CustomModelTemplate {
 *	
 *	}
 * 
 *	alias CustomModel = CustomModelTemplate;
 * }
 * ----------
 * 
 * ==Step 3
 * 
 * Mix in the template that checks if your class implements all the required methods and add their implementation. 
 * You can find more information about those metods in <code>ModelTemplate</code> class;
 * 
 * Example: 
 * ----------
 * template CustomModel(Prototype) {
 * 	
 *	class CustomModelTemplate {
 *		
 *	}
 * 	
 * 	mixin MixCheckModelFields!CustomModelTemplate;
 *	alias CustomModel = CustomModelTemplate;
 * }
 * 
 * ==Step 4
 * 
 * If you don't want to create a new template from scratch, you can extend the base Model template you can do it like this:
 * 
 * Example: 
 * ----------
 * template CustomModel(Prototype) {
 * 	
 *	class CustomModelTemplate : Model!Prototype {
 *		
 *	}
 * 	
 * 	mixin MixCheckModelFields!CustomModelTemplate;
 *	alias CustomModel = CustomModelTemplate;
 * }
 * ----------
 */
template Model(Prototype) {

	/**
	 * 
	 * 
	 */
	class ModelTemplate {

		/**
		 * 
		 */
		alias ItemCls = Item!(Prototype, ModelTemplate);

		ItemCls[] items;

		/**
		 * Add or update an element
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
			throw new CratedModelException("unimplemented base method");
		}
	
		/**
		 * Remove all items
		 */
		void truncate() {
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
		 * Query the model. This is unsupported for the base model, but if you want to use a database as storage,
		 * you should implement this method in your model.
		 */
		ItemCls[] query() {
			throw new CratedModelException("unsupported method");
		}

		/**
		 * Count an item set 
		 */
		ulong length(string fieldName, T)(T value) {
			ulong sum = 0;

			auto list = all;

			foreach(i; 0..list.length) {
				sum += __traits(getMember, list[i], fieldName) == value ? 1 : 0;
			}

			return sum;
		}

		/**
		 * Count all items
		 */
		ulong length() {
			return all.length;
		}

		/**
		 * Find all items that match the search criteria 
		 */
		ItemCls[] getBy(string fieldName, T)(T value) {
			ItemCls[] r;

			auto list = all;

			foreach(i; 0..list.length) {
				if(__traits(getMember, list[i], fieldName) == value) {
					r ~= [ list[i] ];
				}
			}

			return r;
		}

		/**
		 * retrieve the first item that match the search
		 * criteria
		 */
		ItemCls getOneBy(string fieldName, T)(T value) {
			auto list = all;

			foreach(i; 0..list.length) {
				if(__traits(getMember, list[i], fieldName) == value) {
					return list[i];
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

	mixin MixCheckModelFields!ModelTemplate;
	alias Model = ModelTemplate;
}



/**
 * This template is used to check if a model has declared all the methods.
 * 
 * Example:
 * ----------------------
 * class MyModel {
 * 	mixin MixCheckFieldsModel!MyModel;
 * }
 * ----------------------
 * 
 * Will show messages on compile for every missing member.
 * 
 */
mixin template MixCheckModelFields(M) {

	/**
	 * Generate code that checks if a certain method is declared 
	 */
	private string _genChkMember(M, string name)() {
		static if(!__traits(hasMember, M, name)) {
			pragma(msg, "Have you forgot to declare method ["~name~"] for [", M ,"]?");
		}
		
		return "";
	}


	mixin(_genChkMember!(M, "createItem"));

	mixin(_genChkMember!(M, "save"));
	mixin(_genChkMember!(M, "remove"));
	mixin(_genChkMember!(M, "truncate"));

	mixin(_genChkMember!(M, "all"));

	mixin(_genChkMember!(M, "query"));
	mixin(_genChkMember!(M, "getBy"));
	mixin(_genChkMember!(M, "getOneBy"));
}
