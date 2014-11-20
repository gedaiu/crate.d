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

/*


string viewAsAdminTable(ITEM, string base, T)(T data) {
	
	enum fields = ITEM.fields;
	enum primaryField = ITEM.primaryField;
	
	string a;
	
	a  = "<table><thead><tr>";
	
	foreach(field; fields) {
		if(field[0] != primaryField) { 
			a ~= "<th>" ~ field[0] ~ "</th>";
		}
	}
	
	a ~= "<th></th></tr></thead><tbody>";
	
	foreach(item; data) {
		a ~= "<tr>" ~ mixin( renderTableLine(fields, primaryField) ) ~ "</tr>";
	}
	
	a ~= "</tbody></table>";
	a ~= `<a href='` ~ base ~ `/add'>Add</a>`;
	
	return a;
}*/

class AdminView : BaseView {

	immutable string baseUrl;

	this(const string baseUrl) {
		this.baseUrl = baseUrl;
	}

	/**
	 * 
	 */
	string editFormFieldByAttribute(string field, PrototypedItem)(PrototypedItem item) {
		string required = "";
		if(PrototypedItem.fieldHas(field[0], "required")) required = "required";

		string fieldType = PrototypedItem.valueOf(field, "type");

		switch(fieldType) {
			case "color": case "date": case "datetime": case "datetime-local": case "email": case "month":
			case "number": case "range": case "tel": case "time": case "url": case "week":
				
				return "<input type='" ~ fieldType ~ "' name='" ~ field ~ "' value='" ~ item.fieldAsString!field ~ "' " ~ required ~ ">";
	
			default:

				return "";
		}
	}

	/**
	 * 
	 */
	string editFormFieldByType(string[] field, PrototypedItem)(PrototypedItem item) {
		string required = "";
		if(PrototypedItem.fieldHas(field[0], "required")) required = "required";

		string value = item.fieldAsString!(field[0]);

		switch(field[1]) {
			case "bool":
				return "<input type='checkbox' value='true' name='" ~ field[0] ~ "' ` ~ (data."~field[0]~" ? `checked`:``) ~ `>";

			case "byte": case "short": case "int": case "long": case "cent": case "ubyte": case "ushort":
			case "uint": case "ulong": case "ucent":
				return "<input type='number' name='" ~ field[0] ~ "' value='" ~ value ~ "' "~field[0]~" "~required~">";

			case "float": case "double": case "real":
				return "<input step='0.01' type='number' name='" ~ field[0] ~ "' value='" ~ value ~ "' "~required~">";

			default:
				
				if(field[2] == "isEnum") {
					/*a ~= "<select name='" ~ field[0] ~ "'>";
					import std.traits;
					
					auto values = PrototypedItem.enumValues[field[0]];
					
					foreach(v; values) {
						a ~= "<option ` ~ ( data."~field[0]~".to!string == `"~v~"` ? `selected`:``) ~ `>"~v~"</option>";
					}

					a ~= "</select>";*/

					return "enum";
				} else {
					return "<input name='" ~ field[0] ~ "' value='" ~ value ~ "' "~required~">";
				}
		}

	}

	/**
	 * 
	 */
	string editFormField(string[] field, const string primaryField, PrototypedItem)(PrototypedItem item) {
		string a;

		if(field[0] == primaryField) { 
			a ~= "<input type='hidden' name='" ~ field[0] ~ "' value='" ~ item.fieldAsString!(field[0]) ~ "' />";
			
		} else {
			a ~= `<div class="line">`;
			a ~= "<label>" ~ field[0] ~ "</label>";

			string inputField = editFormFieldByAttribute!(field[0])(item);


			//build the value based on the property type
			if(inputField == "") {
				inputField = editFormFieldByType!(field)(item);
			}

			a ~= inputField ~ `</div>`;
		}

		
		return a;
	}


	/// Private:
	private string editFormFields(string[][] fields, string primaryField, PrototypedItem)(PrototypedItem item) {

		static if(fields.length > 1) {
			return editFormFields!(fields[0..$/2], primaryField)(item) ~ editFormFields!(fields[$/2..$], primaryField)(item);
		} else {
			return editFormField!(fields[0], primaryField)(item);
		}

	}

	/**
	 * 
	 */
	string asEditForm(PrototypedItem)(PrototypedItem item) {
		string a;

		enum fields = PrototypedItem.fields;
		enum primaryField = PrototypedItem.primaryField;

		a ~= `<form action="`~baseUrl~`/save/` ~ item.fieldAsString!(primaryField[0]) ~ `" method="post">`;

		a ~= editFormFields!(fields, primaryField[0])(item);

		a ~= `<input type="submit"/>`;
		a ~= `</form>`;

		return a;
	}

	/**
	 * 
	 */
	string asAdminTable(PrototypedItem)(PrototypedItem[] items) {
		enum fields = PrototypedItem.fields;
		enum primaryField = PrototypedItem.primaryField;
		
		string a;
		
		a  = "<table>" ~ adminTableHeader(fields, primaryField[0]) ~ "<tbody>";
		
		foreach(item; items) {
			a ~= "<tr>";
					
			a ~= adminTableLine!(fields, primaryField[0])(item);

			a ~= "<td><a href='" ~ baseUrl ~ "/edit/" ~ item.fieldAsString!(primaryField[0]) ~ "'>Edit</a> "~
				 "<a href='" ~ baseUrl ~ "/delete/" ~ item.fieldAsString!(primaryField[0]) ~ "'>Delete</a></td></tr>";
		}
		
		a ~= "</tbody></table>";
		a ~= `<a href='` ~ baseUrl ~ `/add'>Add</a>`;
		
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

