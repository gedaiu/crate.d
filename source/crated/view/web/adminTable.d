/**
 * 
 * source/crated/view/adminTable.d
 * 
 * Author:
 * Szabo Bogdan <szabobogdan@yahoo.com>
 * 
 * Copyright (c) 2014 Szabo Bogdan
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 * documentation files (the "Software"), to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions
 * of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 * TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 * CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 * 
 */
module crated.view.web.adminTable;

import std.conv;
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

	a ~= ` ~ "<td><a href='" ~ base ~ "edit/" ~ item.` ~ primaryField ~ `.to!string ~ "'>Edit</a> <a href='" ~ base ~ "delete/" ~ item.` ~ primaryField ~ `.to!string ~ "'>Delete</a></td>"`;

	return a;
}

string adminTable(ITEM, string base, T)(T data) {

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
	a ~= `<a href='` ~ base ~ `add'>Add</a>`;

	return a;
}