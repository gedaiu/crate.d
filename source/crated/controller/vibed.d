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


	foreach (method; __traits(allMembers, Controller)) {
		pragma(msg, method);
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

	shared static void route(void function(HTTPServerRequest, HTTPServerResponse) cb, string method, string path, ref URLRouter router) {
		if(method == "ANY") router.any(path, cb);
		if(method == "GET") router.get(path, cb);
		if(method == "DELETE") router.delete_(path, cb);
		if(method == "PATCH") router.patch(path, cb);
		if(method == "POST") router.post(path, cb);
		if(method == "PUT") router.put(path, cb);
	}
}

