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
public import crated.tools;
public import std.conv;

import std.traits;
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
template MongoModel(alias CreatePrototype, string collectionName, string modelName = "Unknown") {

	alias Prototype = ReturnType!CreatePrototype;

	///Private:
	private MongoClient client;
	///Private:
	private MongoCollection collection;

	mixin ModelHelper!MongoModelTemplate;

	/**
	 * Mongo model implementation
	 */
	class MongoModelTemplate {
	
		alias ItemCls = Prototype;

		///Model name
		enum string name = modelName;

		static {

			///Private:
			mixin PrototypeReflection!Prototype;

			///init the connection
			void connect() {
				client = connectMongoDB(dbAddress);
				collection = client.getCollection(collectionName);
			}

			/**
			 * Add or update an element
			 */
			void save(Prototype item) {
				if(collection.name != collectionName) connect;

				bool isNew = (primaryField(item).to!string == "");

				Bson query = item.convert!Bson;

				//perform the query
				if(isNew) {
					collection.insert(query);
				} else {
					Bson sel = Bson.emptyObject;
					sel[primaryFieldName] = query[primaryFieldName];

					collection.update(sel, query);
				}
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
				if(collection.name != collectionName) connect;

				static if(T.stringof == "Bson" || T.stringof == "Json") {
					collection.remove(item);
				}
			}

			/**
			 * Remove one item
			 */
			void remove(Prototype item) {
				remove!(primaryFieldName)( primaryField(item) );
			}

			/**
			 * Remove a list of items
			 */
			void remove(Prototype[] items) {
				if(collection.name != collectionName) connect;

				Bson list[];

				foreach(item; items) {
					Bson tmp = Bson.emptyObject;

					tmp = BsonObjectID.fromString( primaryField(item) );
					list ~= tmp;
				}

				Bson idList = Bson.emptyObject;
				idList["$in"] = Bson(list);

				Bson query = Bson.emptyObject;
				query[primaryFieldName] = idList;

				collection.remove(query, DeleteFlags.None);
			}

			/**
			 * Remove an item by field name
			 */
			void remove(string field, T)(T value) {
				if(collection.name != collectionName) connect;

				Bson query = Bson.emptyObject;

				static if(field == "_id" && is(T == string)) {
					query[field] = BsonObjectID.fromString(value);
				} else {
					query[field] = value;
				}

				remove(query);
			}

			/**
			 * Remove all items
			 */
			void truncate() {
				Bson query = Bson.emptyObject;
				remove(query);
			}

			/**
			 * Retrieve all items
			 */
			Prototype[] all() {
				if(collection.name != collectionName) connect;

				Prototype[] items;

				auto cursor = collection.find(Bson.emptyObject);

				while (!cursor.empty) {
					items ~= CreateItem(cursor.front.toJson);
					cursor.popFront();
				}

				return items;
			}

			/**
			 * Count all items
			 */
			ulong length() {
				if(collection.name != collectionName) connect;

				return collection.count(Bson.emptyObject);
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
				if(collection.name != collectionName) connect;

				string type = "";
				if("type" in data) type = data["type"].to!string;
				
				string[string] dataAsString = toDict(data);
				auto itm = CreatePrototype(type, dataAsString);
				
				return itm;
			}


			/**
			 * Find all items that match the search criteria 
			 */
			Prototype[] getBy(string fieldName, T)(T value) {
				if(collection.name != collectionName) connect;

				Prototype[] filteredList;
				
				Bson query = Bson.emptyObject;
				
				static if(fieldName == "_id" && is(T == string)) {
					query[fieldName] = BsonObjectID.fromString(value);
				} else {
					query[fieldName] = value;
				}

				auto cursor = collection.find(query);
				
				while (!cursor.empty) {
					filteredList ~= CreateItem(cursor.front.toJson);
					cursor.popFront();
				}

				return filteredList;
			}

			/**
			 * Retrieve the first item that match the search
			 * criteria
			 */
			Prototype getOneBy(string fieldName, T)(T value) {
				if(collection.name != collectionName) connect;

				Prototype[] filteredList;
				
				Bson query = Bson.emptyObject;
				
				static if(fieldName == "_id" && is(T == string)) {
					query[fieldName] = BsonObjectID.fromString(value);
				} else {
					query[fieldName] = value;
				}
				
				auto cursor = collection.find(query).limit(1);
				
				while (!cursor.empty) {
					return CreateItem(cursor.front.toJson);
				}

				throw new CratedModelException("No item found");
			}

			/**
			 * Query the model. This is unsupported for the base model, but if you want to use a database as storage,
			 * you should implement this method in your model.
			 */
			Prototype[] query(T)(T query) {
				if(collection.name != collectionName) connect;

				Prototype[] queryList;
				
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
					queryList ~= CreateItem(cursor.front.toJson);
					cursor.popFront();
				}
				
				return queryList;
			}
		}
	}

	///Private: check if we implemented all required fields
	mixin MixCheckModelFields!MongoModelTemplate;
	alias MongoModel = MongoModelTemplate;
}
