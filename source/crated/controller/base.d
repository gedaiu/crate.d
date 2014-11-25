/**
 * Controller basic functionality
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


template Controller(ControllerCls) {

	class ControllerTemplate : ControllerCls {

		//TODO: make attributes of type string[string][string] to avoid runtime string parsing
		///The request attributes.
		enum string[][] requests = getItemFields!("HttpRequest", ControllerCls, true);

		/**
		 * Init the router
		 */
		void addRoutes(ref URLRouter router, bool callSuper = true) {

			static if(__traits(hasMember, super, "addOtherRoutes")) {
				if(callSuper) super.addOtherRoutes(router);
			}

			addRoutes!requests(router);
		}

		/**
		 * 
		 */
		private void addRoutes(string[][] requests)(ref URLRouter router) {
			static if(requests.length == 1) {
				route( &__traits(getMember, this, requests[0][0]), 
				       valueOf(requests[0][0], "method"), 
				       valueOf(requests[0][0], "node"), 
				       router);

			} else static if(requests.length > 1) {
				addRoutes!(requests[0..$/2])(router);
				addRoutes!(requests[$/2..$])(router);
			}
		}

		/**
		 * 
		 */
		void route(void function(HTTPServerRequest, HTTPServerResponse) cb, string method, string path, ref URLRouter router) {
			if(method == "ANY") router.any(path, cb);
			if(method == "GET") router.get(path, cb);
			if(method == "DELETE") router.delete_(path, cb);
			if(method == "PATCH") router.patch(path, cb);
			if(method == "POST") router.post(path, cb);
			if(method == "PUT") router.put(path, cb);
		}


		/**
		 * Get the value of an attribute. An atribute value is set like this:
		 * 
		 * Example: 
		 * -------------
		 * @("field", "custom attribute:custom value")
		 * string name;
		 * -------------
		 */
		static string valueOf(string fieldName, string attribute) {
			foreach(list; requests) {
				if(list[0] == fieldName) {
					
					foreach(i; 1..list.length) {
						auto index = list[i].indexOf(":");
						
						if(index > 0 && list[i][0..index] == attribute) {
							return list[i][index+1..$];
						}
					}
				}
			}
			
			return "";
		}
	}

	alias Controller = ControllerTemplate;
}


/**
 * 
 */
struct HttpRequest {
	string method;
	string path;
	void* cb;

	this(string method, string path) 
		in {
			assert(
					method == "ANY" ||
					method == "GET" ||
					method == "DELETE" ||
					method == "MATCH" ||
					method == "PATCH" ||
					method == "POST" ||
					method == "PUT", 
				"Allowed methods are: `ANY`, `GET`, `DELETE`, `MATCH`, `PATCH`, `POST`, `PUT`");
		}

		body {
			this.method = method;
			this.path = path;
		}

	//TODO: this is a strange warkaround
	this(string method, string path, void* cb) {
		this(method, path);
	}
}