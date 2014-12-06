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

import crated.tools;

/**
 * Aggregates all information about a model error status.
 */
class CratedModelException : Exception {
	/**
	 * Create the exception
	 */
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
	 */
	class ItemTemplate : Prototype {
		/**
		 * Private: The parent model
		 */
		private M myModel;

		/**
		 * An alias to the model type
		 */
		alias modelCls = M;

		/**
		 * Default constructor
		 */
		this(M parent) {
			super();
			myModel = parent;
		}

		/**
		 * Copy constructor
		 */
		this(T)(T someItem, M parent) {
			this(parent);
			copy!fields(someItem);

		}

		/**
		 * Copy data from an object that have the same fields
		 */
		void copy(string[][] fields, T)(T someItem) {

			static if(fields.length == 1) {
				bool found = true;

				//get the desired field value from someItem
				static if(__traits(hasMember, someItem, fields[0][0])) {
					auto someField = __traits(getMember, someItem, fields[0][0]);
				} else {

					string someField;

					try {
						someField = someItem[fields[0][0]].to!string;
					} catch (Exception e) {
						someField = "";
						found = false;
					}
				}

				if(found) { 
					static if( is( typeof(__traits(getMember, this, fields[0][0]) ) == typeof(someField) ) ) {
						__traits(getMember, this, fields[0][0]) = someField;
					} else {
						static if(fields[0][2] == "isEnum") {
							try {
								static if(__traits(compiles, 
								                   __traits(getMember, this, fields[0][0]) = someField.to!string.to!(typeof(__traits(getMember, this, fields[0][0]))))) {

									__traits(getMember, this, fields[0][0]) = someField.to!string.to!(typeof(__traits(getMember, this, fields[0][0])));
								} else {
									pragma(msg, "`", Prototype, "`.`", fields[0][0], "` can not be set at runtime.");
								} 
							} catch(ConvException e) {
								std.stdio.writeln(e);
							}

						} else static if(fields[0][1] == "SysTime") {
							import std.datetime;

							SysTime d;
							if(fields[0][0] ~ "[tzOffset]" in someItem) {

								auto mm = someItem[fields[0][0] ~ "[tzOffset]"].to!long;

								auto h = std.math.abs(mm) / 60;
								auto m = std.math.abs(mm) - h * 60;
								string sh = (h < 10 ? "0":"") ~ h.to!string;
								string sm = (m < 10 ? "0":"") ~ m.to!string;
							
								if( mm <= 0 ) {
									d = SysTime.fromISOExtString(someField.to!string ~ "+" ~ sh ~ ":" ~ sm);
								} else {
									d = SysTime.fromISOExtString(someField.to!string ~ "-" ~ sh ~ ":" ~ sm);
								}

							} else {
								d = SysTime.fromISOExtString(someField.to!string);
							}

							__traits(getMember, this, fields[0][0]) = d;

							__traits(getMember, this, fields[0][0]).fracSec = FracSec.zero;
						} else static if(fields[0][1] == "Duration") {
							import std.datetime;

							try {
								__traits(getMember, this, fields[0][0]) = dur!"hnsecs"(someField.to!string.to!long);
							} catch(Exception e) {
								std.stdio.writeln(fields[0][0], " can not be set as Duration.");
							}
						} else static if(fields[0][2] != "isConst") {
							__traits(getMember, this, fields[0][0]) = someField.to!(typeof(__traits(getMember, this, fields[0][0])));
						}
					}
				} else {
					static if( is( typeof(__traits(getMember, this, fields[0][0]) ) == bool ) ) {
						__traits(getMember, this, fields[0][0]) = false;
					}

					static if( is( typeof(__traits(getMember, this, fields[0][0]) ) == core.time.Duration ) ) {
						import core.time;

						Duration d = dur!"seconds"(0);

						if(fields[0][0] ~ "[seconds]" in someItem) d += dur!"seconds"(someItem[fields[0][0] ~ "[seconds]"].to!string.to!long);
						if(fields[0][0] ~ "[minutes]" in someItem) d += dur!"minutes"(someItem[fields[0][0] ~ "[minutes]"].to!string.to!long);
						if(fields[0][0] ~ "[hours]" in someItem) d += dur!"hours"(someItem[fields[0][0] ~ "[hours]"].to!string.to!long);
						if(fields[0][0] ~ "[days]" in someItem) d += dur!"days"(someItem[fields[0][0] ~ "[days]"].to!string.to!long);
						if(fields[0][0] ~ "[weeks]" in someItem) d += dur!"weeks"(someItem[fields[0][0] ~ "[weeks]"].to!string.to!long);

						__traits(getMember, this, fields[0][0]) = d;
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
		 * A pair of a field name and type to be accessed at runtime
		 */
		static enum string[] primaryField = getItemFields!("primary", Prototype, false)[0];

		//TODO: make attributes of type string[string][string] to avoid runtime string parsing in valueOf method
		///The field attributes.
		enum string[][] attributes = getItemFields!("field", Prototype, true);

		//TODO: remove the string mixin
		///All the enum fields with their keys
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
						if(v.stringof[1..$-1] != "") {
							vals ~= glue ~ `"` ~ v.stringof[1..$-1] ~ `"`; 
							glue = ", ";
						}
					}
					
					return `, "` ~ field[0] ~ `": [` ~ vals ~ `]` ~ getEnumValues!(i + 1);
				} else {
					return getEnumValues!(i + 1);
				}
			}
		}

		/**
		 * The parent model
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

		/**
		 * Private: The primary key type alias
		 */
		private alias PrimaryKeyType = typeof(__traits(getMember, this, primaryField[0]));

		/**
		 * Get the primary field value
		 */
		@property
		PrimaryKeyType primaryKeyValue() {
			return __traits(getMember, this, primaryField[0]);
		}
		
		/**
		 * Check if a field has a certain attribute
		 */
		static bool fieldHas(T)(T fieldName, string attribute) {
			foreach(list; attributes) {

				if(list[0] == fieldName.to!string) {
					
					foreach(i; 1..list.length) {
						auto index = list[i].indexOf(":");

						if(list[i] == attribute) return true;

						if(index > 0 && list[i][0..index] == attribute) {
							return true;
						}
					}
				}
			}

			return false;
		}

		/**
		 * Get the value of an attribute. An atribute value is set like this:
		 * 
		 * Example: 
		 * -------------
		 * @("field", "custom attribute:custom value")
		 * string name;
		 * -------------
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
		
		/**
		 * Get a field value as string. Very useful in views
		 */
		string fieldAsString(string fieldName)() {
			auto val = __traits(getMember, this, fieldName);

			static if( typeof(val).stringof == "SysTime" ) {
				return val.toISOExtString;
			} else static if( typeof(val).stringof == "Duration" ) {
				return (val.total!"hnsecs").to!string;
			} else {
				return val.to!string;
			}
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
				} else if(field[1] == "SysTime") {
					jsonCode ~= "\"` ~ this." ~ field[0] ~ ".toISOExtString" ~ " ~ `\"";
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

/**
 * Create a crated Model. A model is responsable with manipulating Items. It save, delete and query the 
 * Items into a db or other storage type.
 * 
 * 
 * =Extending
 * 
 * You can extend a model like this:
 * 
 * Example:
 * -----------------
 * class MyModel : Model!Prototype {
 * 
 * 	ItemCls[] customQuery() {
 * 		....
 * 	}
 * 
 * }
 * -----------------
 * 
 * 
 * =Creating new Item templates
 * 
 * ==Step 1
 * 
 * Create a new template that take a Type as parameter;
 * 
 * Example: 
 * ----------
 * template CustomModel(Prototype, string modelName = "Unknown") {
 * 		
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
 * template CustomModel(Prototype, string modelName = "Unknown") {
 * 	
 *	class CustomModelTemplate {
 *		enum string name = modelName;
		alias ItemCls = Item!(Prototype, CustomModelTemplate);
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
 * template CustomModel(Prototype, string modelName = "Unknown") {
 * 	
 *	class CustomModelTemplate {
 *		enum string name = modelName;
		alias ItemCls = Item!(Prototype, CustomModelTemplate);
 *		
 *	}
 * 	
 * 	mixin MixCheckModelFields!CustomModelTemplate;
 *	alias CustomModel = CustomModelTemplate;
 * }
 * ----------
 * 
 * ==Step 4
 * 
 * If you don't want to create a new template from scratch, you can extend the base Model template you can do it like this:
 * 
 * Example: 
 * ----------
 * template CustomModel(Prototype, string modelName = "Unknown") {
 * 	
 *	class CustomModelTemplate : Model!Prototype {
 *		enum string name = modelName;
 *
 *	}
 * 	
 * 	mixin MixCheckModelFields!CustomModelTemplate;
 *	alias CustomModel = CustomModelTemplate;
 * }
 * ----------
 * 
 * 
 */
template Model(Prototype, string modelName = "Unknown") {

	/**
	 * A basic model implementation without any persistence
	 */
	class ModelTemplate {

		///An alias to the item class type.
		alias ItemCls = Item!(Prototype, ModelTemplate);

		///The model name.
		enum string name = modelName;

		///Protected: item container
		protected ItemCls[] items;

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
		 * Retrieve the first item that match the search criteria
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
		 * Convert the items to a Json string
		 */
		override string toString() {
			return items.to!string;
		}
	}

	///Private: 
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
