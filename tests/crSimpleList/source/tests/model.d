/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 12 21, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module source.tests.model;


mixin template BasicModelTest(Model) {

	import std.conv;

	mixin ModelHelper!Model;

	/**
	 * Test the basic model functionality
	 */
	unittest {
		auto item1 = Model.CreateItem;
		item1.id = 1;
		item1.name = "Prelude to Foundation";
		item1.author = "Isaac Asimov";
		item1.save;
		
		auto item2 = Model.CreateItem;
		item2.id = 2;
		item2.name = "The Hunger Games";
		item2.author = "Suzanne Collins";
		item2.save;
		
		auto item3 = Model.CreateItem;
		item3.id = 3;
		item3.name = "The Adventures of Huckleberry Finn";
		item3.author = "Mark Twain";
		item3.save;
		
		auto item4 = Model.CreateItem;
		item4.id = 4;
		item4.name = "The Adventures of Tom Sawyer";
		item4.author = "Mark Twain";
		item4.save;
		
		auto marksBookModel = Model.getBy!"author"("Mark Twain");
		assert(marksBookModel.length == 2, "getBy length expected to be 2 instead of " ~ marksBookModel.length.to!string);
		assert(marksBookModel[0].author == "Mark Twain", "getBy[0] author expected to be `Mark Twain`");
		assert(marksBookModel[1].author == "Mark Twain", "getBy[0] author expected to be `Mark Twain`");
		
		auto oneItem    = Model.getOneBy!"author"("Mark Twain");
		assert(oneItem.name == "The Adventures of Huckleberry Finn", "getOneBy name expected to be `The Adventures of Huckleberry Finn`" );
		assert(oneItem.author == "Mark Twain", "getOneBy author expected to be `Mark Twain`");
		
		auto all          = Model.all;
		assert(all.length == 4, "all length expected to be 4");
	}
}