/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 12 22, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module tests.events;

import crated.model.calendar;

mixin template EventsTest(Model) {

	import vibe.d;

	mixin ModelHelper!Model;

	unittest {
		Model.truncate;

		auto item1 = Model.CreateItem!"Basic";
		auto item2 = Model.CreateItem!"Unknown";

		item1.save;
		item2.save;

		auto items = Model.all;

		assert(item1.itemType == items[0].itemType);
		assert(item2.itemType == items[1].itemType);
	}
}