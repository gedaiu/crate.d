﻿/**
 * Views to manage data
 * 
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: November 3, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module crated.view.web.admin;

import std.conv;
import crated.model.base;
public import crated.view.base;

private string renderTableLine(string[][] fields, const string primaryField) {
	string a;
	
	string glue = "";
	foreach(field; fields) {
		if(field[0] != primaryField){ 
			a ~= glue ~ `"<td>" ~ item.`~field[0]~`.to!string ~ "</td>"`;
			glue = "~";
		}
	}
	
	a ~= ` ~ "<td><a href='" ~ base ~ "/edit/" ~ item.` ~ primaryField ~ `.to!string ~ "'>Edit</a> <a href='" ~ base ~ "/delete/" ~ item.` ~ primaryField ~ `.to!string ~ "'>Delete</a></td>"`;
	
	return a;
}

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
}


string inputFormFields(ITEM)(string[][] fields, const string primaryField) {
	string a="`";
	
	foreach(field; fields) {
		if(field[0] == primaryField) { 
			
			a ~= "<input type='hidden' name='" ~ field[0] ~ "' value='` ~ data."~field[0]~".to!string ~ `' >";
			
		} else {
			a ~= `<div class="line">`;
			a ~= "<label>" ~ field[0] ~ "</label>";
			
			string required = "";
			if(ITEM.has(field[0], "required")) required = "required";
			
			string fieldType = ITEM.valueOf(field[0], "type");
			bool randeredByType = false;
			
			switch(fieldType) {
				case "color":
				case "date":
				case "datetime":
				case "datetime-local":
				case "email":
				case "month":
				case "number":
				case "range":
				case "tel":
				case "time":
				case "url":
				case "week":
					
					a ~= "<input type='" ~ fieldType ~ "' name='" ~ field[0] ~ "' value='` ~ data."~field[0]~" ~ `'>";
					
					randeredByType = true;
					break;
					
				default: 
					
			}
			
			//build the value based on the property type
			if(!randeredByType)
			switch(field[1]) {
				case "bool":
				a ~= "<input type='checkbox' value='true' name='" ~ field[0] ~ "' ` ~ (data."~field[0]~" ? `checked`:``) ~ `>";
				break;
				
				
				case "byte":
				case "short":
				case "int":
				case "long":
				case "cent":
				case "ubyte":
				case "ushort":
				case "uint":
				case "ulong":
				case "ucent":
				a ~= "<input type='number' name='" ~ field[0] ~ "' value='` ~ data."~field[0]~".to!string ~ `' "~field[0]~" "~required~">";
				break;
				
				case "float":
				case "double":

				case "real":
				a ~= "<input step='0.01' type='number' name='" ~ field[0] ~ "' value='` ~ data."~field[0]~".to!string ~ `' "~required~">";
				break;
				
				default:
				
				if(field[2] == "enum") {
					a ~= "<select name='" ~ field[0] ~ "'>";
					import std.traits;
					
					auto values = ITEM.enumValues[field[0]];
					
					foreach(v; values) {
						a ~= "<option ` ~ ( data."~field[0]~".to!string == `"~v~"` ? `selected`:``) ~ `>"~v~"</option>";
					}
					
					a ~= "</select>";
				} else {
					a ~= "<input name='" ~ field[0] ~ "' value='` ~ data."~field[0]~".to!string ~ `' "~required~">";
				}
			}
			
			a ~= `</div>`;
		}
	}
	
	return a ~ "`";
}

string viewAsAdminEditForm(string base, ITEM)(ITEM data){
	
	string a = "";
	
	enum fields = ITEM.fields;
	enum primaryField = ITEM.primaryField;
	
	a ~= `<form action="`~base~`/save/` ~ mixin("data." ~ primaryField ~ ".to!string") ~ `" method="post">`;
	
	a ~= mixin(inputFormFields!ITEM(fields, primaryField));
	
	a ~= `<input type="submit"/>`;
	a ~= `</form>`;
	
	return a;
}
