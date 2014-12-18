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
import std.typecons;
import std.datetime;
import core.time;

import vibe.d;

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



template AbstractModel(Prototype) {

	/**
	 * Abstract model definition
	 */
	abstract class Model {
					
		static {

			///Private:
			mixin PrototypeReflection!Prototype;

			///Get field attribute value 
			string valueOf(string field, string attr) {
				
				return "";
			}

			///Check if field has an attribute
			bool fieldHas(string field, string attr) {
				
				return false;
			}

			//TODO: remove the string mixin
			///All the enum fields with their keys
			enum string[][string] enumValues = mixin("[ ``: [] " ~ getEnumValues ~ "]");

			/**
			 * Generate the values for the enums from the current item
			 */
			private string getEnumValues(ulong i = 0)() {
				
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
			 * Add or update an element
			 */
			void save(Prototype item);

			/**
			 * Add or update a list of elements
			 */
			void save(Prototype[] items);

			/**
			 * Remove an existing item
			 */
			void remove(T)(T item);

			/**
			 * Remove one item
			 */
			void remove(Prototype item);

			/**
			 * Remove a list of items
			 */
			void remove(Prototype[] items);

			/**
			 * Remove an item by field name
			 */
			void remove(string field, T)(T value);

			/**
			 * Remove all items
			 */
			void truncate();

			/**
			 * Retrieve all items
			 */
			Prototype[] all();

			/**
			 * Count all items
			 */
			ulong length();

			/**
			 * Create a new item. The returned item will not be 
			 * automatically added to the model. If you want to add it to a model
			 * call Item.save()
			 */
			static Prototype CreateItem(string type = "")();			

			/**
			 * Create an item from some dictionary
			 */
			static Prototype CreateItem(T)(T data) if(!is(T == string));


			/**
			 * Find all items that match the search criteria 
			 */
			Prototype[] getBy(string fieldName, T)(T value);

			/**
			 * Retrieve the first item that match the search
			 * criteria
			 */
			Prototype getOneBy(string fieldName, T)(T value);

			/**
			 * Query the model. This is unsupported for the base model, but if you want to use a database as storage,
			 * you should implement this method in your model.
			 */
			Prototype[] query(T)(T query);
		}
	}

	alias AbstractModel = Model;
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
template Model(alias CreatePrototype, string modelName = "Unknown") {

	alias Prototype = ReturnType!CreatePrototype;


	mixin ModelHelper!ModelTemplate;

	/**
	 * A basic model implementation without any persistence
	 */
		class ModelTemplate : AbstractModel!(Prototype) {

		///An alias to the item class type.
		alias ItemCls = Prototype;

		static {
			///Private:
			mixin PrototypeReflection!Prototype;

			///The model name.
			enum string name = modelName;

			///Protected: item container
			protected Prototype[] items;

			/**
			 * Add or update an element
			 */
			void save(Prototype item) {
				auto itemId = primaryField(item);
				bool added = false;

				foreach(i; 0..items.length) {
					auto currentId = primaryField(items[i]);

					if(itemId == currentId) {
						items[i] = item;
						return;
					}
				}

				items ~= [item];
			}

			/**
			 * Add or update a list of elements
			 */
			void save(Prototype[] items) {
				foreach(item; items) {
					save(item);
				}
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

			static Prototype CreateItem(string type = "")() {
				string[string] data;
				
				Prototype item = CreatePrototype(type, data);
				
				return item;
			}
			
			
			/**
			 * Create an item from some dictionary
			 */
			static Prototype CreateItem(T)(T data) if(!is(T == string)) {
				string type = "";
				if("type" in data) type = data["type"].to!string;
				
				string[string] dataAsString = toDict(data);
				auto itm = CreatePrototype(type, dataAsString);
				
				return itm;
			}

			/**
			 * Retrieve all items
			 */
			Prototype[] all() {
				return items;
			}

			/**
			 * Query the model. This is unsupported for the base model, but if you want to use a database as storage,
			 * you should implement this method in your model.
			 */
			Prototype[] query() {
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
			Prototype[] getBy(string fieldName, T)(T value) {
				Prototype[] r;

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
			Prototype getOneBy(string fieldName, T)(T value) {
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
			string toString() {
				return items.to!string;
			}

		}
	}

	alias Model = ModelTemplate;
}

mixin template ModelHelper(Model) {

	void save(Model.ItemCls item) {
		Model.save(item);
	}
	
	void save(Model.ItemCls[] itemList) {
		Model.save(itemList);
	}

	void remove(Model.ItemCls item) {
		Model.remove(item);
	}
	
	void remove(Model.ItemCls[] itemList) {
		Model.remove(itemList);
	}

	//private
	private void fillFields(T, FIELDS...)(ref T data, Model.ItemCls item) {

		static if(FIELDS[0].length == 1) {

			//if is a bson id
			static if(Model.primaryFieldName == FIELDS[0][0][0] && FIELDS[0][0][1] == "string" && is(T == Bson)) {
				BsonObjectID id;
				string val = __traits(getMember, item, FIELDS[0][0][0]);

				if(val == "") {
					id = BsonObjectID.generate;
					__traits(getMember, item, FIELDS[0][0][0]) = id.to!string;
				} else {
					id = BsonObjectID.fromString(__traits(getMember, item, FIELDS[0][0][0]));
				}

				data[FIELDS[0][0][0]] = id;

			} else {
				data[FIELDS[0][0][0]] = __traits(getMember, item, FIELDS[0][0][0]);
			}

		} else static if(FIELDS[0].length > 1) {
			fillFields!(T, FIELDS[0][0..$/2])(data, item);
			fillFields!(T, FIELDS[0][$/2..$])(data, item);
		}
	}

	T convert(T)(Model.ItemCls item) if(is(T==Json) || is(T==Bson)) {
		T data = T.emptyObject;

		fillFields!(T, Model.fields)(data, item);
		
		return data;
	}

}

/*
///Private: copy field values from query to item
private void setFieldsInto(string[][] fields)(ref Bson query, const Prototype item) {
	
	static if(fields.length == 1) {
		if(query[fields[0][0]].type == Bson.Type.null_) {
			//date time 
			static if(fields[0][1] == "SysTime" || fields[0][1] == "DateTime" || fields[0][1] == "Date") {
				BsonDate date = BsonDate( __traits(getMember, item, fields[0][0]) );
				query[fields[0][0]] = date;
			} else static if(fields[0][1] == "Duration") {
				Bson date = Bson( __traits(getMember, item, fields[0][0]).total!"hnsecs" );
				query[fields[0][0]] = date;
			} else {
				query[fields[0][0]] = __traits(getMember, item, fields[0][0]);
			}
		}
		
	} else if(fields.length > 0) {
		setFieldsInto!(fields[0..$/2])(query, item);
		setFieldsInto!(fields[$/2..$])(query, item);
	}
}
*/
