/**
 * 
 * /Users/gedaiu/workspace/crate.d/source/crated/controller/admin.d
 * 
 * Author:
 * Szabo Bogdan <szabobogdan@yahoo.com>
 * 
 * Copyright (c) 2014 ${CopyrightHolder}
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
module crated.controller.admin;

import crated.view.web.admin;

import crated.controller.vibed;
import vibe.d;

/**
 * The project controller
 */
template AdminController(string baseUrl, Model, Prototype) {

	class CAdminController {
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
		mixin MixVibedController!(CAdminController);
	}

	alias AdminController = CAdminController;
}



