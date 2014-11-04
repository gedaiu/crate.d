/**
 * Manage models easily
 * 
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: November 3, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module crated.controller.admin;

import crated.view.web.admin;

import crated.controller.vibed;
import vibe.d;

/**
 * The project controller
 */
template AdminController(string baseUrl, Model, Prototype) {

	class AdminControllerTemplate {
		/**
		 * The list page
		 */
		@HttpRequest("GET", baseUrl ~ "")
		static void index(HTTPServerRequest req, HTTPServerResponse res) {
			MongoClient client = connectMongoDB("127.0.0.1");
			auto itemList = new Model(client);
			
			auto items = itemList.allItems;
			
			
			res.writeBody( items.viewAsAdminTable!(Prototype, baseUrl), "text/html; charset=UTF-8");
		}
		
		/**
		 * The edit page
		 */
		@HttpRequest("GET", baseUrl ~ "/edit/:id")
		static void edit(HTTPServerRequest req, HTTPServerResponse res) {
			MongoClient client = connectMongoDB("127.0.0.1");
			auto myModel = new Model(client);
			
			auto itemList = myModel.findBy!"_id"(BsonObjectID.fromString(req.params["id"]));
			auto item = itemList[0];
			
			res.writeBody( item.viewAsAdminEditForm!(baseUrl) , "text/html; charset=UTF-8");
		}
		
		/**
		 * The add item page
		 */
		@HttpRequest("GET", baseUrl ~ "/add")
		static void add(HTTPServerRequest req, HTTPServerResponse res) {
			MongoClient client = connectMongoDB("127.0.0.1");
			auto myModel = new Model(client);
			
			auto item = myModel.createItem;
			
			res.writeBody( item.viewAsAdminEditForm!(baseUrl) , "text/html; charset=UTF-8");
		}
		
		
		/**
		 * The save item action
		 */
		@HttpRequest("POST", baseUrl ~ "/save/:id")
		static void save(HTTPServerRequest req, HTTPServerResponse res) {
			MongoClient client = connectMongoDB("127.0.0.1");
			auto myModel = new Model(client);
			
			auto item = Prototype.From(req.form, myModel);
			item.save;
			
			res.headers["Location"] = baseUrl;
			res.statusCode = 302;
			res.statusPhrase = "Saved! Redirecting...";
			
			res.writeBody( "Saved! Redirecting..." , "text/html; charset=UTF-8");
		}
		
		/**
		 * The delete item action
		 */
		@HttpRequest("ANY", baseUrl ~ "/delete/:id")
		static void delete_(HTTPServerRequest req, HTTPServerResponse res) {
			MongoClient client = connectMongoDB("127.0.0.1");
			auto myModel = new Model(client);
			
			auto item = myModel.findBy!"_id"(BsonObjectID.fromString(req.params["id"]));
			
			item[0].remove;
			
			res.headers["Location"] = baseUrl;
			res.statusCode = 302;
			res.statusPhrase = "Deleted! Redirecting...";
			
			res.writeBody( "Deleted! Redirecting..." , "text/html; charset=UTF-8");
		}
		
		
		
		//insert controller code
		mixin MixVibedController!(AdminControllerTemplate);
	}

	alias AdminController = AdminControllerTemplate;
}



