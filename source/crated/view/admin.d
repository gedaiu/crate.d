
/**
 * Views to manage data
 * 
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: November 3, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module crated.view.admin;

import std.conv;
import crated.model.base;
public import crated.view.base;


template AdminView(Model) {
	class AdminViewTpl : BaseView {

		immutable string baseUrl;

		this(const string baseUrl, BaseView parent) {
			super(parent);
			this.baseUrl = baseUrl;
		}

		/**
		 * 
		 */
		private ViewType getViewByAttribute(string field, PrototypedItem)(PrototypedItem item, ulong index) {
		
			ViewType view;

			string fieldType = Model.valueOf(field, "type");
			string cls;
			
			if(index == 1) cls ~= "input-lg";

			switch(fieldType) {
				case "color": case "date": case "datetime": case "datetime-local": case "email": case "month":
				case "number": case "range": case "tel": case "time": case "url": case "week":
					view = new ViewType;
					view.container = parent;
					view.type = fieldType;
					view.cls = cls;
					view.id = "formElement" ~ index.to!string;
					view.name = field;
					view.value = __traits(getMember, item, field).to!string;

					break;
				default:
					break;
			}

			return view;
		}

		/**
		 * 
		 */
		ViewType editFormFieldByType(string[] field, PrototypedItem)(PrototypedItem item, ulong index) {
			bool required;
			string requiredIcon;

			if(Model.fieldHas(field[0], "required")) required = true;
		
			string value = __traits(getMember, item, field[0]).to!string;
			string cls;

			if(index == 1) cls ~= "input-lg";

			import crated.view.base;

			ViewType view;


			switch(field[1]) {
				case "bool":
					view = new ViewBool;
					view.container = parent;

					break;

				case "byte": case "short": case "int": case "long": case "cent": case "ubyte": case "ushort":
				case "uint": case "ulong": case "ucent":
					view = new ViewType;
					view.container = parent;
					view.type = "number";

					break;

				case "float": case "double": case "real":
					view = new ViewType;
					view.container = parent;
					view.type = "number";
					view.step = "0.01";

					break;

				case "SysTime":
					view = new crated.view.datetime.ViewSysTime;
					view.container = parent;

					break;

				case "Duration":
					view = new crated.view.datetime.ViewDuration;
					view.container = parent;

					break;

				default:
					
					if(field[2] == "isEnum") {
						view = new ViewList;
						view.container = parent;

						foreach(v; Model.enumValues[field[0]]) {
							(cast(ViewList) view).addItem(v);
						}
					} else {
						view = new ViewType;
						view.container = parent;

						view.type = "text";
					}
			}

			view.cls = cls;
			view.id = "formElement" ~ index.to!string;
			view.name = field[0];
			view.value = value;
					
			return view;
		}

		/// Private: 
		private ViewType getTypeFor(string[] field, PrototypedItem)(PrototypedItem item, ulong index = 0) {
			ViewType inputField = getViewByAttribute!(field[0])(item, index);
			
			//build the value based on the property type
			if(inputField is null) inputField = editFormFieldByType!(field)(item, index);

			return inputField;
		}

		/// Private:
		private string editFormFields(string[][] fields, PrototypedItem)(PrototypedItem item, ulong index = 0) {
			
			static if(fields.length > 1) {
				return editFormFields!(fields[0..$/2])(item, index) ~ editFormFields!(fields[$/2..$])(item, index+fields.length/2);
			} else {
				return editFormField!(fields[0])(item, index);
			}
		}

		
		/// Private:
		private string adminTableHeader(string[][] fields, string primaryField) {
			string a = "<thead><tr>";
			
			foreach(field; fields) {
				if(field[0] != primaryField) { 
					a ~= "<th>" ~ field[0] ~ "</th>";
				}
			}
			
			return a ~ "<th></th></tr></thead>";
		}
		
		/// Private: 
		private string preview(string[] field, T)(T item) {
			ViewType inputField = getTypeFor!(field)(item);
			
			return inputField.asPreview;
		}
		
		/// Private:
		private string adminTableLine(string[][] fields, PrototypedItem)(PrototypedItem item) {
			static if(fields.length > 1) {
				return adminTableLine!(fields[0..$/2])(item) ~ adminTableLine!(fields[$/2..$])(item);
			} else static if(fields[0][0] != Model.primaryFieldName) {
				return "<td>" ~ preview!(fields[0])(item) ~ "</td>";
			} else {
				return "";
			}
		}

		/**
		 * 
		 */
		string editFormField(string[] field, PrototypedItem)(PrototypedItem item, ulong index) {
			string a;

			static if(field[0] == Model.primaryFieldName) { 
				a ~= "<input type='hidden' name='" ~ field[0] ~ "' value='" ~ __traits(getMember, item, field[0]).to!string ~ "' />";
				
			} else static if(field[2] != "isConst") {
				ViewType inputField = getTypeFor!(field)(item, index);

				if(inputField !is null) {
					string cls;

					if(index == 1) cls = "class='text-primary'";

					a ~= `<div class="form-group">`;
					a ~= "<label "~cls~" for='formElement"~index.to!string~"'>" ~ field[0] ~ "</label>";

					bool required;
					if(Model.fieldHas(field[0], "required")) required = true;

					a ~= inputField.asForm(required) ~ `</div>`;
				}
			}
					
			return a;
		}

		/**
		 * 
		 */
		string asEditForm(PrototypedItem)(PrototypedItem item) {
			string a;

			if(parent) {
				parent.title = "Edit " ~ Model.name;
			}


			a = `<form action="`~baseUrl~`/save/` ~ Model.primaryField(item) ~ `" method="post">`;

			a ~= editFormFields!(Model.fields)(item);

			a ~= `<input class='btn btn-default' type="submit"/>`;
			a ~= `</form>`;

			a = `<div class="container"><div class="row"><div class="col-xs-12">` ~ a ~ `</div></div>`;

			return a;
		}

		/**
		 * 
		 */
		string asAddForm(PrototypedItem)(PrototypedItem item) {
			string a;

			if(parent) {
				parent.title = "Add " ~ Model.name;
			}

			a = `<form action="`~baseUrl~`/save/new" method="post">`;
			
			a ~= editFormFields!(Model.fields)(item);
			
			a ~= `<input class='btn btn-default' type="submit"/>`;
			a ~= `</form>`;
			
			a = `<div class="container"><div class="row"><div class="col-xs-12">` ~ a ~ `</div></div>`;
			
			return a;
		}

		/**
		 * 
		 */
		string asAdminTable(PrototypedItem)(PrototypedItem[] items) {
			string a;

			if(parent) {
				parent.title = Model.name;
			}

			a  = "<table class='table table-striped'>" ~ adminTableHeader(Model.fields, Model.primaryFieldName) ~ "<tbody>";
			
			foreach(item; items) {
				a ~= "<tr>";
						
				a ~= adminTableLine!(Model.fields)(item);

				a ~= "<td><a class='btn btn-default' href='" ~ baseUrl ~ "/edit/" ~ Model.primaryField(item) ~ "'>Edit</a> "~
					 "<a class='btn btn-danger' href='" ~ baseUrl ~ "/delete/" ~ Model.primaryField(item) ~ "'>Delete</a></td></tr>";
			}
			
			a ~= "</tbody></table>";
			a ~= `<a class='btn btn-default' href='` ~ baseUrl ~ `/add'>Add</a>`;

			a = `<div class="container"><div class="row"><div class="col-xs-12">` ~ a ~ `</div></div>`;

			return a;
		}
	}

	alias AdminView = AdminViewTpl;
}
