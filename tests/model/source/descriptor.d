/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 1 22, 2015
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module descriptor;

import vibe.d;

import crated.model.calendar;
import crated.model.base;
import crated.model.mongo;

import tests.descriptor;
import tests.model;
import tests.events;

import prototypes.book;
import prototypes.events;

alias EventsModel = MongoModel!(EventDescriptor, "test.calendar", "Calendar");
mixin EventsDescriptorTest!EventsModel;

unittest {
	Json data = Json.emptyObject;
	
	data.name = "some name";
	auto item = BookDescriptor.CreateItemFrom(data);
	
	assert(data.name = "some name");
}
