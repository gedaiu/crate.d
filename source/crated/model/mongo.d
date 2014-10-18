/**
 * 
 * source/crated/model/mongo.d
 * 
 * Author:
 * Szabo Bogdan <szabobogdan@yahoo.com>
 * 
 * Copyright (c) 2014 Szabo Bogdan
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 * documentation files (the "Software"), to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions
 * of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 * TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 * CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 * 
 */module crated.model.mongo;

version(UseVibe) { }

public import crated.model.base;
public import vibe.d;
public import std.conv;


public mixin template MixMongoModel(Prototype, Model) {
	private MongoClient client;
	private MongoCollection collection;

	//check if the collection name is declared
	static if(!__traits(hasMember, Model, "collectionName")) {
		pragma(msg, "Have you forgot to declare the property [collectionName]?\n`private enum string collectionName=\"[your collection]\";`\n");
	}

	static if(!__traits(hasMember, Prototype, "_id")) {
		pragma(msg, "Have you forgot to declare the property [_id] for your items?\n`BsonObjectID _id;`\n");
	}

	this(MongoClient client) {
		this.client = client;
		collection = client.getCollection(collectionName);
	}

	/**
	 * 
	 */
	void save(Prototype item) {
		if(item._id.to!string == "000000000000000000000000") {
			item._id = BsonObjectID.generate;

			collection.insert(item);
		} else {
			collection.update(["_id": item._id], item);
		}
	}

	/**
	 * Remove all items from the model
	 */
	void remove() {
		collection.remove();
	}

	/**
	 * Return all the items that match the query
	 */
	Prototype[] findBy(string field, U)(U value) {
		Prototype[] list;

		Bson q = Bson.emptyObject;
		q[field] = value;

		return query(q);
	}

	/**
	 * Query the model
	 */
	Prototype[] query(T)(T data, int length = 0, int skip = 0) {
		Prototype[] list;

		auto result = collection.find(data, Bson(), QueryFlags.None, skip, length);

		while (!result.empty) {
			Prototype item = Prototype.FromJson(this, result.front.toJson);

			result.popFront();
			list ~= item;
		}

		return list;
	}
	
	/**
	 * Returns first item that match the query
	 */
	Prototype findOneBy(string field, U)(U value) {
		Prototype item;
		Bson q = Bson.emptyObject;
		q[field] = value;
		
		auto res = query(q, 1);

		if(res.length > 0) 
			return res[0];

		return null;
	}

	/**
	 * Returns all item models
	 */
	Prototype[] allItems() {
		Bson q = Bson.emptyObject;
		
		auto res = query(q);

		return res;
	}

	/**
	 * Create one item
	 */
	Prototype createItem() {
		auto item = new Prototype(this);
		return item;
	}


	mixin MixCheckFieldsModel!(Model);
}

//}