/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 12 21, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module tests.model;


mixin template BasicModelTest(Model) {

	import std.conv;
	import vibe.d;

	mixin ModelHelper!Model;

	//test save
	unittest {
		Book item = Model.CreateItem;
		item.name = "some name";
		item.author = "some author";
		item.save;
		
		assert(Model.length == 1);
		auto savedItem = Model.all[0];
		
		savedItem.convert!Json;
		
		assert(item.convert!Json == savedItem.convert!Json);
	}
	
	//test truncate
	unittest {
		auto item = Model.CreateItem;
		item.save;
		
		Model.truncate;
		
		assert(Model.length == 0);
	}
	
	//test remove
	unittest {
		
		auto item = Model.CreateItem;
		item.save;
		
		assert(Model.length == 1);
		
		item.remove;
		
		assert(Model.length == 0);
	}
	
	unittest {
		auto item = Model.CreateItem;
		item.save;
		
		assert(Model.length == 1);
		
		Model.remove!"_id"(item._id);
		
		assert(Model.length == 0);
	}
	
	//save and delete multiple values
	unittest {
		auto item1 = Model.CreateItem;
		auto item2 = Model.CreateItem;
		
		auto list = [item1, item2];
		
		Model.save(list);
		
		assert(Model.length == 2);
		
		Model.remove([item1, item2]);
		
		assert(Model.length == 0);
	}

	/**
	 * Test the basic model functionality
	 */
	unittest {
		Model.truncate;

		auto item1 = Model.CreateItem;
		item1.name = "Prelude to Foundation";
		item1.author = "Isaac Asimov";
		item1.save;

		auto item2 = Model.CreateItem;
		item2.name = "The Hunger Games";
		item2.author = "Suzanne Collins";
		item2.save;

		auto item3 = Model.CreateItem;
		item3.name = "The Adventures of Huckleberry Finn";
		item3.author = "Mark Twain";
		item3.save;

		auto item4 = Model.CreateItem;
		item4.name = "The Adventures of Tom Sawyer";
		item4.author = "Mark Twain";
		item4.save;

		auto marksModel = Model.getBy!"author"("Mark Twain");
		assert(marksModel.length == 2, "getBy length expected to be 2 instead of " ~ marksModel.length.to!string);
		assert(marksModel[0].author == "Mark Twain", "getBy[0] author expected to be `Mark Twain` not " ~ marksModel[0].author);
		assert(marksModel[1].author == "Mark Twain", "getBy[1] author expected to be `Mark Twain` not " ~ marksModel[1].author);
		
		auto oneItem    = Model.getOneBy!"author"("Mark Twain");
		assert(oneItem.name == "The Adventures of Huckleberry Finn", "getOneBy name expected to be `The Adventures of Huckleberry Finn`" );
		assert(oneItem.author == "Mark Twain", "getOneBy author expected to be `Mark Twain`");
		
		auto all          = Model.all;
		assert(all.length == 4, "all length expected to be 4");
	}
}