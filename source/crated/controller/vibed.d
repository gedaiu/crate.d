/**
 * 
 * source/crated/controller/base.d
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
 */
module crated.controller.vibed;

import std.stdio;

public import crated.controller.base;
public import std.typetuple;

version(UseVibe) {}

/**
 * Get a class property
 */
private template ItemProperty(item, string method) {
	
	static if(__traits(hasMember, item, method)) {
		alias ItemProperty = TypeTuple!(__traits(getMember, item, method));
	} else {
		alias ItemProperty = TypeTuple!();
	}
}

/**
 * Create the code that links all the controller methods with the vibe.d router
 */
string generateEntryPoints(Controller)() {
	string a = "HttpRequest tmp;";

	pragma(msg, __traits(allMembers, Controller));
	foreach (method; __traits(allMembers, Controller)) {
		enum attrList = __traits(getAttributes, ItemProperty!(Controller, method));

		foreach (i, T; attrList) {
			string code = attrList[i].stringof;

			if(code.length > 12 && code[0..12] == "HttpRequest(") {
				a ~= "tmp = " ~ code ~ "; route(&this."~ method ~", tmp.method, tmp.path, router);";
			}
		}
	}


	return a;
}

public mixin template MixVibedController(Controller) {

	/**
	 * Init the router
	 */
	static void addRoutes(ref URLRouter router) {
		mixin(generateEntryPoints!Controller);
	}

	static void route(void function(HTTPServerRequest, HTTPServerResponse) cb, string method, string path, ref URLRouter router) {
		writeln(method, " ", path);

		if(method == "ANY") router.any(path, cb);
		if(method == "GET") router.get(path, cb);
		if(method == "DELETE") router.delete_(path, cb);
		if(method == "PATCH") router.patch(path, cb);
		if(method == "POST") router.post(path, cb);
		if(method == "PUT") router.put(path, cb);
	}
}

