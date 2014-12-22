/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 12 22, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module mongo;

import std.stdio : writeln;
import crated.model.mongo;
import std.traits;
import vibe.d;
import prototypes.book;

unittest {
	crated.model.mongo.dbAddress = "127.0.0.1";
}

alias BookModel = MongoModel!(BookDescriptor, "test.BookModel", "Books");
mixin ModelHelper!BookModel;

unittest {
	BookModel.truncate;
}
