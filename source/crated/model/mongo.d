/**
 * A model that use mongo db database to save the data.
 * 
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: November 3, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module crated.model.mongo;

public import crated.model.base;
public import std.conv;
import vibe.d;

/**
 * Mongo connection String URI.
 * Find more here: http://docs.mongodb.org/manual/reference/connection-string/
 * 
 * Example:
 * ---------------
 * //setup the database connection string
 * crated.model.mongo.dbAddress = "127.0.0.1";
 * 
 * //init the data	
 * alias BookModel = MongoModel!(BookPrototype, "test.books", "Books");
 * ---------------
 */
shared static string dbAddress;

/**
 * Create a mongo model. More general informations about the Models and Items can be found in crates.model.base.
 * 
 * The MongoModel template takes three parameters:
 *  - Prototype - is the item prototype that will be stored in the database
 *  - string CollectionName - the collection where the items will be stored
 *  - string modelName - the model name used in various situations to identify the model type
 * 
 * Here is an example of how you can use a Mongo model:
 * 
 * Example:
 * ---------------
 * class BookPrototype {
 * 
 * 	@("field", "primary")
 * 	string _id;
 * 	
 * 	@("field", "required") 
 * 	string name = "unknown";
 * 	
 * 	@("field", "required") 
 * 	string author = "unknown";
 * }
 * 
 * //create the mongo model
 * alias BookModel = MongoModel!(BookPrototype, "test.books", "Books");
 * ---------------
 */
template MongoModel(Prototype, string collectionName, string modelName = "Unknown") {

	///Private:
	private MongoClient client;
	///Private:
	private MongoCollection collection;

	/**
	 * Mongo model implementation
	 */
	class MongoModelTemplate {

		///An alias to the item class type.
		alias ItemCls = Item!(Prototype, MongoModelTemplate);

		///Model name
		enum string name = modelName;

		///Create the object an init the connection
		this() {
			client = connectMongoDB(dbAddress);
			collection = client.getCollection(collectionName);
		}

		/**
		 * Add or update an element
		 */
		void save(ItemCls item) {
			auto itemId = __traits(getMember, item, (ItemCls.primaryField[0]));

			Bson query = Bson.emptyObject;

			bool isNew = true;

			//if we have the default _id key
			static if(typeof(itemId).stringof == "string" && ItemCls.primaryField[0] == "_id") {
				if(itemId == "") {
					auto id = BsonObjectID.generate;
					
					query["_id"] = id;
					item._id = id.toString;
				} else {
					query["_id"] = BsonObjectID.fromString(item._id);
					isNew = false;
				}
			}

			setFieldsInto!(item.fields)(query, item);

			//perform the query
			if(isNew) {
				collection.insert(query);
			} else {
				Bson sel = Bson.emptyObject;
				sel[ItemCls.primaryField[0]] = query[ItemCls.primaryField[0]];

				collection.update(sel, query);
			}
		}

		/**
		 * Add or update a list of elements
		 */
		void save(ItemCls[] items) {
			foreach(item; items) {
				save(item);
			}
		}

		///Private: copy field values from query to item
		private void setFieldsInto(string[][] fields)(ref Bson query, const ItemCls item) {

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

		/**
		 * Remove all items
		 */
		void truncate() {
			Bson query = Bson.emptyObject;
			remove(query);
		}

		/**
		 * Remove an existing item
		 */
		 void remove(T)(T item) {
			static if(T.stringof == "Bson" || T.stringof == "Json") {
				collection.remove(item);
			}
		}

		/**
		 * Remove one item
		 */
		void remove(ItemCls item) {
			remove!(item.primaryField[0])( __traits(getMember, item, item.primaryField[0]) );
		}

		/**
		 * Remove a list of items
		 */
		void remove(ItemCls[] items) {
			Bson list[];

			foreach(item; items) {
				Bson tmp = Bson.emptyObject;

				static if(item.primaryField[0] == "_id" && item.primaryField[1] == "string") {
					tmp = BsonObjectID.fromString(item.primaryKeyValue);
				} else {
					tmp = item.primaryKeyValue;
				}

				list ~= tmp;
			}


			Bson idList = Bson.emptyObject;
			idList["$in"] = Bson(list);

			Bson query = Bson.emptyObject;
			query[items[0].primaryField[0]] = idList;

			collection.remove(query, DeleteFlags.None);
		}

		/**
		 * Remove an item by field name
		 */
		void remove(string field, T)(T value) {
			Bson query = Bson.emptyObject;

			static if(field == "_id" && is(T == string)) {
				query[field] = BsonObjectID.fromString(value);
			} else {
				query[field] = value;
			}

			remove(query);
		}

		/**
		 * Retrieve all items
		 */
		ItemCls[] all() {
			ItemCls[] items;

			auto cursor = collection.find(Bson.emptyObject);

			while (!cursor.empty) {
				items ~= new ItemCls(cursor.front.toJson, this);
				cursor.popFront();
			}

			return items;
		}

		/**
		 * Count all items
		 */
		ulong length() {
			return collection.count(Bson.emptyObject);
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
		 * Find all items that match the search criteria 
		 */
		ItemCls[] getBy(string fieldName, T)(T value) {
			ItemCls[] filteredList;
			
			Bson query = Bson.emptyObject;
			
			static if(fieldName == "_id" && is(T == string)) {
				query[fieldName] = BsonObjectID.fromString(value);
			} else {
				query[fieldName] = value;
			}

			auto cursor = collection.find(query);
			
			while (!cursor.empty) {
				filteredList ~= new ItemCls(cursor.front.toJson, this);
				cursor.popFront();
			}

			return filteredList;
		}
		
		/**
		 * Retrieve the first item that match the search
		 * criteria
		 */
		ItemCls getOneBy(string fieldName, T)(T value) {
			ItemCls[] filteredList;
			
			Bson query = Bson.emptyObject;
			
			static if(fieldName == "_id" && is(T == string)) {
				query[fieldName] = BsonObjectID.fromString(value);
			} else {
				query[fieldName] = value;
			}
			
			auto cursor = collection.find(query).limit(1);
			
			while (!cursor.empty) {
				return new ItemCls(cursor.front.toJson, this);
			}

			throw new CratedModelException("No item found");
		}

		/**
		 * Query the model. This is unsupported for the base model, but if you want to use a database as storage,
		 * you should implement this method in your model.
		 */
		ItemCls[] query(T)(T query) {
			ItemCls[] queryList;
			
			Bson q = Bson.emptyObject;

			foreach(string fieldName, value; query) {
				if(fieldName == "_id") {
					q[fieldName] = BsonObjectID.fromString(value.to!string);
				} else {
					q[fieldName] = value;
				}
			}

			auto cursor = collection.find(q);
			
			while (!cursor.empty) {
				queryList ~= new ItemCls(cursor.front.toJson, this);
				cursor.popFront();
			}
			
			return queryList;
		}
	}

	///Private: check if we implemented all required fields
	mixin MixCheckModelFields!MongoModelTemplate;
	alias MongoModel = MongoModelTemplate;
}

