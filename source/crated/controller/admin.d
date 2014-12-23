/**
 * Tools for managing Model data. 
 * 
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: November 3, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module crated.controller.admin;

import crated.view.admin;
import crated.view.adminmenu;

import crated.tools;

import crated.controller.base;

import vibe.d;

/**
 * AdminController create <b>/edit/:id</b>, <b>/add</b>, <b>/edit</b>, <b>/delete</b> 
 * nodes relative to the <code>baseUrl</code> parameter. At the <b>baseUrl</b> node will be displayed
 * a list wil the model elements.
 * 
 * The <code>AdminController</code> is just a controller prototype and must be wraped with the crate.d
 * Controller to be used properly. It's so, because you might want to add more nodes to the AdminController.
 * Here is an example of creating an AdminController:
 * 
 * Example:
 * -----------------
 * auto myController = new Controller!(AdminController!("/admin", BookModel));
 * -----------------
 * 
 * If you want to use a custom container view for the admin controler you can pass it as the third parameter:
 * 
 * Example:
 * -----------------
 * auto myController = new Controller!(AdminController!("/admin", BookModel, MyCustomContainerView));
 * -----------------
 * 
 */
template AdminController(string baseUrl, Model, ContainerCls = BaseView) {

	///Private:
	alias ItemCls = Model.Prototype;

	///Admin controller template class
	class AdminControllerTemplate  {

		/**
		 * The list page
		 */
		@("HttpRequest", "method:GET", "node:" ~ baseUrl)
		static void index(HTTPServerRequest req, HTTPServerResponse res) {

			auto container = new ContainerCls;
			auto view = new AdminView!Model(baseUrl, container);

			container.content = view.asAdminTable(Model.all);

			res.writeBody( container.to!string , "text/html; charset=UTF-8");
		}
		
		/**
		 * The edit page
		 */
		@("HttpRequest", "method:GET", "node:" ~ baseUrl ~ "/edit/:id")
		static void edit(HTTPServerRequest req, HTTPServerResponse res) {

			auto container = new ContainerCls;
			auto view = new AdminView!Model(baseUrl, container);
		
			auto item = Model.getOneBy!"_id"(BsonObjectID.fromString(req.params["id"]));
			container.content = view.asForm!"edit"(item);

			res.writeBody( container.to!string , "text/html; charset=UTF-8");
		}
		
		/**
		 * The add item page
		 */
		@("HttpRequest", "method:GET", "node:" ~ baseUrl ~ "/add/:type")
		static void add(HTTPServerRequest req, HTTPServerResponse res) {
			
			auto container = new ContainerCls;
			auto view = new AdminView!Model(baseUrl, container);
			
			string[string] data;
			data["itemType"] = req.params["type"];
			
			auto item = Model.CreateItem(data);
			container.content = view.asForm!"add"(item);
			
			res.writeBody( container.to!string, "text/html; charset=UTF-8");
		}

		/**
		 * The add item page
		 */
		@("HttpRequest", "method:GET", "node:" ~ baseUrl ~ "/add")
		static void addDefault(HTTPServerRequest req, HTTPServerResponse res) {
			
			auto container = new ContainerCls;
			auto view = new AdminView!Model(baseUrl, container);

			auto item = Model.CreateItem;
			container.content = view.asForm!"add"(item);
			
			res.writeBody( container.to!string, "text/html; charset=UTF-8");
		}

		/**
		 * The save item action
		 */
		@("HttpRequest", "method:POST", "node:" ~ baseUrl ~ "/save/:id")
		static void save(HTTPServerRequest req, HTTPServerResponse res) {
			auto container = new ContainerCls;

			if(req.params["id"] == "new") {
				add(req);
			} else {
				update(req);
			}

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
			Model.remove!(PrimaryFieldName!(Model.Descriptor.Prototype))(req.params["id"]);

			res.headers["Location"] = baseUrl;
			res.statusCode = 302;
			res.statusPhrase = "Deleted! Redirecting...";
			
			res.writeBody( "Deleted! Redirecting..." , "text/html; charset=UTF-8");
		}

		/**
		 * 
		 */
		private static void add(HTTPServerRequest req) {
			if(Model.Descriptor.primaryFieldName in req.form && req.form[Model.Descriptor.primaryFieldName] != "") {
				throw new CratedControllerException("Can not add items with default primary key");
			}
			
			auto item = Model.CreateItem(req.form);
			Model.save(item);
		}

		/**
		 * 
		 */
		private static void update(HTTPServerRequest req) {
			if(Model.Descriptor.primaryFieldName !in req.form) {
				throw new CratedControllerException("You must set `"~Model.Descriptor.primaryFieldName~"` primary field to update an item");
			}
			
			if(Model.Descriptor.primaryFieldName in req.form && req.form[Model.Descriptor.primaryFieldName] != req.params["id"]) {
				throw new CratedControllerException("POST[`"~Model.Descriptor.primaryFieldName~"`] does not match with save/:id");
			}
			
			auto item = Model.CreateItem(req.form);

			if("__save" in req.form) {
				if(req.form["__save"] == "new") Model.Descriptor.RemovePrimaryField(item);
				else  {
					string[string] data = Model.Descriptor.ToDic(item);
					data["itemType"] = req.form["__save"];
					item = Model.CreateItem(data);
				}
			}

			Model.save(item);
		}
	}

	alias AdminController = AdminControllerTemplate;
}

/**
 * You also can create an AdminController like this:
 * 
 * Example:
 * -----------------
 * auto myModel = new BookModel;
 * 
 * auto myController = new Controller!(AdminController!("/admin", myModel));
 * -----------------
 */
template AdminController(string baseUrl, alias model, ContainerCls = BaseView) {
	alias AdminController = AdminController!(baseUrl, typeof(model), ContainerCls);
}


/**
 * DataManager create an AdminController for every Model passed as parameter. The DataManagerController use
 * the AdminMenuview and because this view has external css and js files, you must serve the assets as static 
 * files.
 * 
 * Example:
 * -----------------
 * alias DataManagerController = DataManager!("/admin", BookModel, OtherProductsModel);
 * 
 * auto dataManager = new Controller!DataManagerController;
 * 
 * //serve the crated library files
 * auto fsettings = new HTTPFileServerSettings;
 * fsettings.serverPathPrefix = "/assets/";
 * router.get("*", serveStaticFiles("../../assets/", fsettings));
 * 
 * //add routes to manage the BookModel and OtherProductsModel
 * dataManager.addRoutes(router);
 * -----------------
 */
template DataManager(string baseUrl, EL...)
{
	
	class DataManagerTemplate  {

		@("HttpRequest", "method:GET", "node:" ~ baseUrl)
		static void index(HTTPServerRequest req, HTTPServerResponse res) {

			res.writeBody( "nothing here" , "text/html; charset=UTF-8");
		}

		/**
		 * Init the router
		 */
		void addOtherRoutes(ref URLRouter router) {
			
			void addModelRoutes(Models...)() {
				
				static if(Models.length == 1) {
					
					AdminMenuView.dataUrls["Models"][Models[0].name] = baseUrl ~ "/" ~ Models[0].name;
					
					alias T = Controller!(AdminController!(baseUrl ~ "/" ~ Models[0].name, Models[0], AdminMenuView));
					
					auto admin = new T;
					
					admin.addRoutes(router);
					
				} else if(Models.length > 1) {
					addModelRoutes!(EL[0..$/2]);
					addModelRoutes!(EL[$/2..$]);
				}
			}
			
			addModelRoutes!EL;
		}
	}
	
	alias DataManager = DataManagerTemplate;
}
