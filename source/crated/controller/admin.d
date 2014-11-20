/**
 * Manage models easily
 * 
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: November 3, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module crated.controller.admin;

import crated.view.admin;

import crated.controller.vibed;
import vibe.d;

/**
 * The project controller
 */

template AdminController(string baseUrl, alias model) {
	alias AdminController = AdminController!(baseUrl, typeof(model));
}

template AdminController(string baseUrl, Model) {

	alias Prototype = Model.ItemCls;

	class AdminControllerTemplate {
		/**
		 * The list page
		 */
		@HttpRequest("GET", baseUrl ~ "")
		static void index(HTTPServerRequest req, HTTPServerResponse res) {

			auto model = new Model;
			auto view = new AdminView(baseUrl);

			res.writeBody( view.asAdminTable(model.all), "text/html; charset=UTF-8");
		}
		
		/**
		 * The edit page
		 */
		@HttpRequest("GET", baseUrl ~ "/edit/:id")
		static void edit(HTTPServerRequest req, HTTPServerResponse res) {
			auto model = new Model;
			auto view = new AdminView(baseUrl);
			auto item = model.getOneBy!"_id"(BsonObjectID.fromString(req.params["id"]));

			res.writeBody( view.asEditForm(item) , "text/html; charset=UTF-8");
		}
		
		/**
		 * The add item page
		 */
		@HttpRequest("GET", baseUrl ~ "/add")
		static void add(HTTPServerRequest req, HTTPServerResponse res) {
			/*auto myModel = new Model;
			
			auto item = myModel.createItem;
			
			res.writeBody( item.viewAsAdminEditForm!(baseUrl) , "text/html; charset=UTF-8");*/
		}
		
		
		/**
		 * The save item action
		 */
		@HttpRequest("POST", baseUrl ~ "/save/:id")
		static void save(HTTPServerRequest req, HTTPServerResponse res) {
			/*auto myModel = new Model;
			
			auto item = new Prototype(req.form, myModel);
			item.save;
			
			res.headers["Location"] = baseUrl;
			res.statusCode = 302;
			res.statusPhrase = "Saved! Redirecting...";
			
			res.writeBody( "Saved! Redirecting..." , "text/html; charset=UTF-8");*/
		}
		
		/**
		 * The delete item action
		 */
		@HttpRequest("ANY", baseUrl ~ "/delete/:id")
		static void delete_(HTTPServerRequest req, HTTPServerResponse res) {
			/*auto myModel = new Model;
			
			auto item = myModel.getOneBy!"_id"(BsonObjectID.fromString(req.params["id"]));
			
			item.remove;
			
			res.headers["Location"] = baseUrl;
			res.statusCode = 302;
			res.statusPhrase = "Deleted! Redirecting...";
			
			res.writeBody( "Deleted! Redirecting..." , "text/html; charset=UTF-8");*/
		}
		
		
		
		//insert controller code
		mixin MixVibedController!(AdminControllerTemplate);
	}

	alias AdminController = AdminControllerTemplate;
}



