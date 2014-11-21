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

class AdminView : BaseView {

	immutable string baseUrl;


	bool useDefaultContainer = true;

	this(const string baseUrl) {
		this.baseUrl = baseUrl;
	}

	/**
	 * 
	 */
	string editFormFieldByAttribute(string field, PrototypedItem)(PrototypedItem item, ulong index) {
		string required = "";
		if(PrototypedItem.fieldHas(field[0], "required")) required = "required";

		string fieldType = PrototypedItem.valueOf(field, "type");
		string cls;
		
		if(index == 1) cls ~= "input-lg";

		switch(fieldType) {
			case "color": case "date": case "datetime": case "datetime-local": case "email": case "month":
			case "number": case "range": case "tel": case "time": case "url": case "week":

				return "<input class='"~cls~" form-control' id='formElement"~index.to!string~"' type='" ~ fieldType ~ "' name='" ~ field ~ "' value='" ~ item.fieldAsString!field ~ "' " ~ required ~ ">";
	
			default:

				return "";
		}
	}

	/**
	 * 
	 */
	string editFormFieldByType(string[] field, PrototypedItem)(PrototypedItem item, ulong index) {
		string required = "";
		if(PrototypedItem.fieldHas(field[0], "required")) required = "required";

		string value = item.fieldAsString!(field[0]);
		string cls;

		if(index == 1) cls ~= "input-lg";

		switch(field[1]) {
			case "bool":
				return " <input type='checkbox' class='"~cls~"' id='formElement"~index.to!string~"' value='true' name='" ~ field[0] ~ "' " ~ (value == "true" ? `checked`:``) ~ `>`;

			case "byte": case "short": case "int": case "long": case "cent": case "ubyte": case "ushort":
			case "uint": case "ulong": case "ucent":
				return "<input class='"~cls~" form-control "~cls~"' id='formElement"~index.to!string~"' type='number' name='" ~ field[0] ~ "' value='" ~ value ~ "' "~field[0]~" "~required~">";

			case "float": case "double": case "real":
				return "<input class='"~cls~" form-control "~cls~"' id='formElement"~index.to!string~"' step='0.01' type='number' name='" ~ field[0] ~ "' value='" ~ value ~ "' "~required~">";

			default:
				
				if(field[2] == "isEnum") {
					string a = "<select id='formElement"~index.to!string~"' class='form-control "~cls~"' name='" ~ field[0] ~ "'>";

					import std.traits;

					auto values = PrototypedItem.enumValues[field[0]];

					foreach(v; values) {
						a ~= "<option " ~ ( value == v ? `selected`:``) ~ ">"~v~"</option>";
					}

					a ~= "</select>";

					return a;
				} else {
					return "<input id='formElement"~index.to!string~"' class='form-control "~cls~"' name='" ~ field[0] ~ "' value='" ~ value ~ "' "~required~">";
				}
		}
	}

	/**
	 * 
	 */
	string editFormField(string[] field, const string primaryField, PrototypedItem)(PrototypedItem item, ulong index) {
		string a;

		if(field[0] == primaryField) { 
			a ~= "<input type='hidden' name='" ~ field[0] ~ "' value='" ~ item.fieldAsString!(field[0]) ~ "' />";
			
		} else {
			string cls;

			if(index == 1) cls = "class='text-primary'";

			a ~= `<div class="form-group">`;
			a ~= "<label "~cls~" for='formElement"~index.to!string~"'>" ~ field[0] ~ "</label>";

			string inputField = editFormFieldByAttribute!(field[0])(item, index);


			//build the value based on the property type
			if(inputField == "") {
				inputField = editFormFieldByType!(field)(item, index);
			}

			a ~= inputField ~ `</div>`;
		}

		
		return a;
	}


	/// Private:
	private string editFormFields(string[][] fields, string primaryField, PrototypedItem)(PrototypedItem item, ulong index = 0) {

		static if(fields.length > 1) {
			return editFormFields!(fields[0..$/2], primaryField)(item, index) ~ editFormFields!(fields[$/2..$], primaryField)(item, index+fields.length/2);
		} else {
			return editFormField!(fields[0], primaryField)(item, index);
		}

	}

	/**
	 * 
	 */
	string asEditForm(PrototypedItem)(PrototypedItem item) {
		string a;

		enum fields = PrototypedItem.fields;
		enum primaryField = PrototypedItem.primaryField;

		a  = "<h1>Edit " ~ PrototypedItem.modelCls.name ~ "</h1>";


		a ~= `<form action="`~baseUrl~`/save/` ~ item.fieldAsString!(primaryField[0]) ~ `" method="post">`;

		a ~= editFormFields!(fields, primaryField[0])(item);

		a ~= `<input class='btn btn-default' type="submit"/>`;
		a ~= `</form>`;

		if(useDefaultContainer) a = html5Container(`<div class="container"><div class="row"><div class="col-xs-12">` ~ a ~ `</div></div>`);

		return a;
	}

	/**
	 * 
	 */
	string asAddForm(PrototypedItem)(PrototypedItem item) {
		string a;
		
		enum fields = PrototypedItem.fields;
		enum primaryField = PrototypedItem.primaryField;
		
		a  = "<h1>Add " ~ PrototypedItem.modelCls.name ~ "</h1>";

		a ~= `<form action="`~baseUrl~`/save/new" method="post">`;
		
		a ~= editFormFields!(fields, primaryField[0])(item);
		
		a ~= `<input class='btn btn-default' type="submit"/>`;
		a ~= `</form>`;
		
		if(useDefaultContainer) a = html5Container(`<div class="container"><div class="row"><div class="col-xs-12">` ~ a ~ `</div></div>`);
		
		return a;
	}

	/**
	 * 
	 */
	string asAdminTable(PrototypedItem)(PrototypedItem[] items) {
		enum fields = PrototypedItem.fields;
		enum primaryField = PrototypedItem.primaryField;
		
		string a;
		
		a  = "<h1>" ~ PrototypedItem.modelCls.name ~ "</h1><table class='table table-striped'>" ~ adminTableHeader(fields, primaryField[0]) ~ "<tbody>";
		
		foreach(item; items) {
			a ~= "<tr>";
					
			a ~= adminTableLine!(fields, primaryField[0])(item);

			a ~= "<td><a class='btn btn-default' href='" ~ baseUrl ~ "/edit/" ~ item.fieldAsString!(primaryField[0]) ~ "'>Edit</a> "~
				     "<a class='btn btn-danger' href='" ~ baseUrl ~ "/delete/" ~ item.fieldAsString!(primaryField[0]) ~ "'>Delete</a></td></tr>";
		}
		
		a ~= "</tbody></table>";
		a ~= `<a class='btn btn-default' href='` ~ baseUrl ~ `/add'>Add</a>`;

		if(useDefaultContainer) a = html5Container(`<div class="container"><div class="row"><div class="col-xs-12">` ~ a ~ `</div></div>`);

		return a;
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
	private string adminTableLine(string[][] fields, string primaryField, PrototypedItem)(PrototypedItem item) {
		static if(fields.length > 1) {
			return adminTableLine!(fields[0..$/2], primaryField)(item) ~ adminTableLine!(fields[$/2..$], primaryField)(item);
		} else static if(fields[0][0] != primaryField) {
			return "<td>" ~ item.fieldAsString!(fields[0][0]) ~ "</td>";
		} else {
			return "";
		}
	}
}

