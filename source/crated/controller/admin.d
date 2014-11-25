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
import vibe.d;

/**
 * The project controller
 */

template AdminController(string baseUrl, alias model) {
	alias AdminController = AdminController!(baseUrl, typeof(model));
}

template AdminController(string baseUrl, Model, ContainerCls = BaseView) {

	alias Prototype = Model.ItemCls;

	class AdminControllerTemplate  {

		/**
		 * The list page
		 */
		@("HttpRequest", "method:GET", "node:" ~ baseUrl)
		static void index(HTTPServerRequest req, HTTPServerResponse res) {

			auto container = new ContainerCls;

			auto model = new Model;
			auto view = new AdminView(baseUrl, container);

			container.useBootstrapCssCDN;
			container.content = view.asAdminTable(model.all);

			res.writeBody( container.to!string , "text/html; charset=UTF-8");
		}
		
		/**
		 * The edit page
		 */
		@("HttpRequest", "method:GET", "node:" ~ baseUrl ~ "/edit/:id")
		static void edit(HTTPServerRequest req, HTTPServerResponse res) {

			auto container = new ContainerCls;

			auto model = new Model;
			auto view = new AdminView(baseUrl, container);

			auto item = model.getOneBy!"_id"(BsonObjectID.fromString(req.params["id"]));

			container.useBootstrapCssCDN;
			container.content = view.asEditForm(item);

			res.writeBody( container.to!string , "text/html; charset=UTF-8");
		}
		
		/**
		 * The add item page
		 */
		@("HttpRequest", "method:GET", "node:" ~ baseUrl ~ "/add")
		static void add(HTTPServerRequest req, HTTPServerResponse res) {
			auto container = new ContainerCls;

			auto model = new Model;
			auto view = new AdminView(baseUrl, container);

			auto item = model.createItem;

			container.useBootstrapCssCDN;
			container.content = view.asAddForm(item);

			res.writeBody( container.to!string, "text/html; charset=UTF-8");
		}
		
		
		/**
		 * The save item action
		 */
		@("HttpRequest", "method:POST", "node:" ~ baseUrl ~ "/save/:id")
		static void save(HTTPServerRequest req, HTTPServerResponse res) {

			auto container = new ContainerCls;

			auto model = new Model;
			auto item = new Prototype(req.form, model);
			item.save;
			
			res.headers["Location"] = baseUrl;
			res.statusCode = 302;
			res.statusPhrase = "Saved! Redirecting...";
			
			res.writeBody( "Saved! Redirecting..." , "text/html; charset=UTF-8");
		}
		
		/**
		 * The delete item action
		 */
		@("HttpRequest", "method:ANY", "node:" ~ baseUrl ~ "/delete/:id")
		static void delete_(HTTPServerRequest req, HTTPServerResponse res) {
			auto model = new Model;

			model.remove!(Model.ItemCls.primaryField[0])(req.params["id"]);

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



