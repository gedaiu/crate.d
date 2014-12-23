/**
 * Provides a template to create controllers.
 * 
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: November 3, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */

module crated.controller.base;

import vibe.d;

import crated.view.base;
import crated.tools;

/**
 * Aggregates all information about a model error status.
 */
class CratedControllerException : Exception {
	/**
	 * Create the exception
	 */
	this(string msg, string file = __FILE__, ulong line = cast(ulong)__LINE__, Throwable next = null) {
		super(msg, file, line, next);
	}
}

/**
 * Generate a crated controller.
 * 
 * This template extends <code>ControllerCls</code> with methods that helps you to automate the vibe.d routing.
 * More info about vibe.d routing can be found here: http://vibed.org/docs#http-routing.
 * To create a crated Controller, you have to create a class with static methods marked with three attributes:
 * 
 * - HttpRequest - Show that the method is a request callback
 * - method - mark the request method that the callback will react. example: <code>method:GET</code>
 * - node - mark the request URI that the callback will react. example: <code>node:/item/:id</code>
 * 
 * Here is an example of a simple controller:
 * 
 * Example:
 * --------------------
 * class MyControllerPrototype  {
 * 
 * 	@("HttpRequest", "method:GET", "node:/item/:id")
 * 	static void index(HTTPServerRequest req, HTTPServerResponse res) {
 * 		...
 * 	}
 * }
 * 
 * alias MyController = Controller!MyControllerPrototype;
 * 
 * shared static this()
 * {	
 * 	//set the web server
 * 	auto settings = new HTTPServerSettings;
 * 	settings.port = 8080;
 * 	settings.bindAddresses = ["::1", "127.0.0.1"];
 * 
 * 	auto router = new URLRouter;
 * 	auto sampleController = new MyController;
 * 
 * 	sampleController.addRoutes(router);
 * 
 * 	listenHTTP(settings, router);
 * 	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
 * }
 * --------------------
 * 
 */
template Controller(ControllerCls) {

	///
	class ControllerTemplate : ControllerCls {

		//TODO: make attributes of type string[string][string] to avoid runtime string parsing
		///The request attributes.
		enum string[][string][string] requestDetails = getItemFields!("HttpRequest", ControllerCls);
		enum string[] requests = EnumerateFieldList!( ControllerCls );


		/**
		 * Set the Controller callbacks to a vibe.d router. If <code>ControllerCls</code> has 
		 * <code>addOtherRoutes(ref URLRouter router)</code>, it will be called first.
		 */
		void addRoutes(ref URLRouter router, bool callSuper = true) {

			static if(__traits(hasMember, super, "addOtherRoutes")) {
				if(callSuper) super.addOtherRoutes(router);
			}

			addRoutes!requests(router);
		}

		///Private: 
		private void addRoutes(string[] requests)(ref URLRouter router) {
			import std.traits;

			static if( requests.length == 1 && requests[0] in requestDetails ) {

				string method = valueOf(requests[0], "method");
				string node = valueOf(requests[0], "node");

				route( &__traits(getMember, this, requests[0]),  method, node, router);
			} else static if(requests.length > 1) {
				addRoutes!(requests[0..$/2])(router);
				addRoutes!(requests[$/2..$])(router);
			}
		}

		///Private:
		private void route(void function(HTTPServerRequest, HTTPServerResponse) cb, string method, string path, ref URLRouter router) {
			if(method == "ANY") router.any(path, cb);
			if(method == "GET") router.get(path, cb);
			if(method == "DELETE") router.delete_(path, cb);
			if(method == "PATCH") router.patch(path, cb);
			if(method == "POST") router.post(path, cb);
			if(method == "PUT") router.put(path, cb);
		}


		/**
		 * Get an attribute value. An atribute value is set like this:
		 * 
		 * Example: 
		 * -------------
		 * @("field", "custom attribute:custom value")
		 * string name;
		 * -------------
		 */
		static string valueOf(string fieldName, string attribute) {
			foreach(requestName; requests) {
				if(requestName == fieldName) {
					
					foreach(i; 0..requestDetails[requestName]["attributes"].length) {
						string attr = requestDetails[requestName]["attributes"][i];
						auto index = attr.indexOf(":");
						
						if(index > 0 && attr[0..index] == attribute) {
							return attr[index+1..$];
						}
					}
				}
			}
			
			return "";
		}
	}

	///Private:
	alias Controller = ControllerTemplate;
}