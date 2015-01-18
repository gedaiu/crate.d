/**
 * Basic view tools
 * 
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: November 3, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module crated.view.base;

import crated.settings;
import std.string, std.conv;
import std.stdio; //todo: remove this


/**
 * Aggregates all information about a model error status.
 */
class CratedViewException : Exception {
	/**
	 * Create the exception
	 */
	this(string msg, string file = __FILE__, ulong line = cast(ulong)__LINE__, Throwable next = null) {
		super(msg, file, line, next);
	}
}


/**
 * 
 */
struct TypeView(T) {
	string[string] attributes;
	T value;

	BaseView container;

	/**
	 * Allows to access attributes using dot sintax
	 */
	@property const(string) opDispatch(string prop)() const { 
		if(prop in attributes) return attributes[prop]; 

		return "";
	}

	/// ditto
	@property ref string opDispatch(string prop)() { 
		if(prop !in attributes) attributes[prop] = ""; 

		return attributes[prop]; 
	}

	/**
	 * Create fields for an HTML form
	 */
	string asForm(bool isRequired = false) {

		string id = opDispatch!"id";
		string cls = opDispatch!"cls";
		string name = opDispatch!"name";
		string type = opDispatch!"type";
		string step = opDispatch!"step";

		if(isRequired) {				
			return "<div class='input-group'>
				               <input class='form-control "~cls~"' id='"~id~"' type='"~type~"' step='"~step~"' name='" ~ name ~ "' value='" ~ value.to!string ~ "' required>
				               <span class='input-group-addon'>
                                     <span class='glyphicon glyphicon-fire' aria-hidden='true'></span>
                               </span>
				        </div>";
		} else {
			return "<input class='form-control "~cls~"' id='"~id~"' type='"~type~"' step='"~step~"' name='" ~ name ~ "' value='" ~ value.to!string ~ "' required>";
		}
	}

	/**
	 * Returns a string that is easy to understand for the user
	 */
	string asPreview() {
		return value.to!string;
	}
}

struct BoolView {
	string[string] attributes;
	
	BaseView container;
	
	/**
	 * Allows to access attributes using dot sintax
	 */
	@property const(string) opDispatch(string prop)() const { 
		if(prop in attributes) return attributes[prop]; 
		
		return "";
	}
	
	/// ditto
	@property ref string opDispatch(string prop)() { 
		if(prop !in attributes) attributes[prop] = ""; 
		
		return attributes[prop]; 
	}

	/**
	 * Create a checkbox for an HTML form
	 */
	string asForm(bool isRequired = false) {
		string id = opDispatch!"id";
		string cls = opDispatch!"cls";
		string name = opDispatch!"name";
		string value = opDispatch!"value";
		string type = opDispatch!"type";
		string step = opDispatch!"step";
		
		return " <input type='checkbox' class='"~cls~"' id='"~id~"' value='true' name='" ~ name ~ "' " ~ (value == "true" ? `checked`:``) ~ `>`;
	}

	/**
	 * Returns a string that is easy to understand for the user
	 */
	string asPreview() {
		return opDispatch!"value";
	}
}

/**
 * 
 */
struct ListView {

	string[] values;

	string[string] attributes;
	
	BaseView container;
	
	/**
	 * Allows to access attributes using dot sintax
	 */
	@property const(string) opDispatch(string prop)() const { 
		if(prop in attributes) return attributes[prop]; 
		
		return "";
	}
	
	/// ditto
	@property ref string opDispatch(string prop)() { 
		if(prop !in attributes) attributes[prop] = ""; 
		
		return attributes[prop]; 
	}

	/**
	 * Returns a string that is easy to understand for the user
	 */
	string asPreview() {
		return opDispatch!"value";
	}

	/**
	 * Create fields for an HTML form
	 */
	string asForm(bool isRequired = false) {
		string id = opDispatch!"id";
		string cls = opDispatch!"cls";
		string name = opDispatch!"name";
		string value = opDispatch!"value";
		string type = opDispatch!"type";
		string step = opDispatch!"step";

		string a = "<select id='"~id~"' class='form-control "~cls~"' name='" ~ name ~ "'>";
		
		foreach(v; values) {
			a ~= "<option " ~ ( value == v ? `selected`:``) ~ ">"~v~"</option>";
		}
		
		a ~= "</select>";
		
		return a;
	}

	void addItem(T)(T item) {
		values ~= item.to!string;
	}

}

/**
 * 
 */
struct ArrayView(T) if(is(T == struct)) {
	
	alias ItemType = typeof(T.value);
	
	ItemType[] _value;
	
	string[string] attributes;
	
	BaseView container;
	
	
	@property ItemType[] value() {
		return _value;
	}
	
	@property void value(T)(T[] items) {
		static if( is(T == ItemType) ) {
			//just set the values
			_value = items;
		} else {
			//check the array length
			if(items.length < _value.length) {
				_value = _value[0..items.length];
			}
			
			foreach(i;0..items.length) {
				if(i < value.length) {
					_value[i] = items[i];
				} else {
					_value ~= [ items[i] ];
				}
			}
		}
	}
	
	/**
	 * Allows to access attributes using dot sintax
	 */
	@property const(string) opDispatch(string prop)() const { 
		if(prop in attributes) return attributes[prop]; 
		
		return "";
	}
	
	/// ditto
	@property ref string opDispatch(string prop)() { 
		if(prop !in attributes) attributes[prop] = ""; 
		
		return attributes[prop]; 
	}
	
	/**
	 * Create fields for an HTML form
	 */
	string asForm(bool isRequired = false) {
		string id = opDispatch!"id";
		string cls = opDispatch!"cls";
		string name = opDispatch!"name";
		
		T sample;

		container.useJqueryCDN;
		container.uses("arrayForm.js");
		container.uses("arrayViewAsForm.js");
		container.uses("arrayViewForm.css");

		string a = "<div class='arrayViewForm arrayViewAsForm'><div class='message well well-sm' role='alert'>This is an empty list. By pressing the button below, you will start adding items.</div><ol id='"~id~"' data-name='"~name~"'>";

		int i = 0;

		string header = `<div class="head"><button class="btn btn-add btn-success"><span class="glyphicon glyphicon-plus" aria-hidden="true"></span></button><button class="btn btn-remove btn-danger"><span class="glyphicon glyphicon-remove" aria-hidden="true"></span></button></div>`;

		sample.name = name ~ "[_index_]";
		sample.cls = cls;

		foreach(v; value) {
			sample.value = v;
			
			a ~= `<li>` ~ header ~ sample.asForm(isRequired) ~ "</li>";
			i++;
		}

		a ~= `</ol>`;

		sample.name = name ~ "[_index_]";
		a ~= `<template class="sample">
				` ~ header ~ sample.asForm(isRequired) ~ `
			  </template>`;

		a ~= `<div class="footer"><button class="btn btn-add btn-success"><span class="glyphicon glyphicon-plus" aria-hidden="true"></span><span class="text">Add item</span></button></div></div>`;
		
		return a;
	}
	
	/**
	 * Returns a string that is easy to understand for the user
	 */
	string asPreview() {
		if(value.length == 0) return "-";
		if(value.length == 1) return "1 item";
		
		return value.length.to!string ~ " items";
	}
}


/**
 * 
 */
struct AssociativeArrayView(T, K) if(is(T == struct) && is(K == struct)) {
	
	alias ItemType = typeof(T.value);

	ItemType[string] value;
	
	string[string] attributes;
	
	BaseView container;

	/**
	 * Allows to access attributes using dot sintax
	 */
	@property const(string) opDispatch(string prop)() const { 
		if(prop in attributes) return attributes[prop]; 
		
		return "";
	}
	
	/// ditto
	@property ref string opDispatch(string prop)() { 
		if(prop !in attributes) attributes[prop] = ""; 
		
		return attributes[prop]; 
	}
	
	/**
	 * Create fields for an HTML form
	 */
	string asForm(bool isRequired = false) {
		string id = opDispatch!"id";
		string cls = opDispatch!"cls";
		string name = opDispatch!"name";

		T sample;
		K keySample;
		
		container.useJqueryCDN;
		container.uses("arrayForm.js");
		container.uses("associativeArrayViewAsForm.js");
		container.uses("arrayViewForm.css");
		
		string a = "<div class='arrayViewForm associativeArrayViewAsForm'><div class='message well well-sm' role='alert'>This is an empty list. By pressing the button below, you will start adding items.</div><ol id='"~id~"' data-name='"~name~"'>";
		
		int i = 0;
		
		string header = `<div class="head"><button class="btn btn-add btn-success"><span class="glyphicon glyphicon-plus" aria-hidden="true"></span></button><button class="btn btn-remove btn-danger"><span class="glyphicon glyphicon-remove" aria-hidden="true"></span></button></div>`;
		
		sample.name = name ~ "[_index_]";
		sample.cls = cls;
		keySample.cls = cls ~ " arrayKeyField";

		sample.container = container;
		keySample.container = container;
		
		foreach(k, v; value) {
			sample.value = v;
			keySample.value = k;
			
			a ~= `<li>` ~ header ~ `<div class="key">`~keySample.asForm(false)~`</div>:<div class="value">` ~ sample.asForm(isRequired) ~ "</div></li>";
			i++;
		}
		
		a ~= `</ol>`;

		sample.name = name ~ "[_index_]";
		a ~= `<template class="sample"> 
				`~ header ~ `<div class="key">`~keySample.asForm(false)~`</div>:<div class="value">` ~ sample.asForm(isRequired) ~ `
			  </template>`;
		
		a ~= `<div class="footer"><button class="btn btn-add btn-success"><span class="glyphicon glyphicon-plus" aria-hidden="true"></span><span class="text">Add item</span></button></div></div>`;

		return a;
	}
	
	/**
	 * Returns a string that is easy to understand for the user
	 */
	string asPreview() {
		if(value.length == 0) return "-";
		if(value.length == 1) return "1 item";
		
		return value.length.to!string ~ " items";
	}
}

class BaseView {

	private string[] cssFiles;
	private string[] jsFiles;

	string content;
	string title;
	BaseView parent;

	this(BaseView parent = null) {
		import std.stdio;
		this.parent = parent;
	}

	/**
	 * Parse a dh file
	 */
	static string parseDhContent(string content) {
		string code;
		
		bool parsingCode = false;
		ulong textPos = 0;
		ulong codePos = 0;
		
		foreach(i; 0..content.length) {
			
			//looking for code start
			if(content.length-1 > i && content[i] == '<' && content[i+1] == '?') {
				//append the discovered code
				code ~= "write(`" ~ content[textPos..i] ~ "`);";
				
				parsingCode = true;
				codePos = i+2;
			}
			
			//looking for code end
			if(content.length-1 > i && content[i] == '?' && content[i+1] == '>') {
				code ~= content[codePos..i];
				
				parsingCode = false;
				textPos = i+2;
			}
		}
		
		if(!parsingCode) code ~= "write(`" ~ content[textPos..$] ~ "`);";
		else code ~= content[codePos..$];
		
		return code;
	}
	
	
	/**
	 * Render a dh file 
	 */
	string renderDh(string file, T)(T data, string url = "") {
		import std.stdio;
		
		//store the stdout file
		auto tmpStdout = stdout;
		stdout = File.tmpfile();
		
		//process the template
		mixin(parseDhContent(import(file)));
		
		string result;	
		
		stdout.rewind();
		auto range = stdout.byLine();
		foreach (line; range)
			result ~= line;
		
		//restore the stdout file
		stdout = tmpStdout;
		
		return result;
	}

	void useBootstrapCssCDN() {
		if(parent is null) {
			cssFiles ~= [ BootstrapCssCDN ];
		} else {
			parent.useBootstrapCssCDN;
		}
	}

	void useBootstrapJsCDN() {
		if(parent is null) {
			useJqueryCDN;
			jsFiles ~= [ BootstrapJsCDN ];
		} else {
			parent.useBootstrapJsCDN;
		}
	}

	void useJqueryCDN() {
		if(parent is null) {
			jsFiles ~= [ JQueryCDN ];
		} else {
			parent.useJqueryCDN;
		}
	}

	void uses(string file) {
		if(file.indexOf(".js") != -1) {
			jsFiles ~= [ "/assets/" ~ file ];
		}

		if(file.indexOf(".css") != -1) {
			cssFiles ~= [ "/assets/" ~ file ];
		}
	}

	string wrapWithBaseContainer(const string content) {
		bool used[string];

		string page = `<!DOCTYPE html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
    <title>`~title~`</title>
    <meta name="description" content="">
    <meta name="viewport" content="width=device-width, initial-scale=1">`;
		
		foreach(i;0..cssFiles.length) {

			if(cssFiles[i] !in used) {
				used[cssFiles[i]] = true;
				page ~= "\n\t<link rel='stylesheet' href='" ~ cssFiles[i] ~ "'>";
			}
		}
		
		page~=`
</head>
<body>
	` ~ content;

		foreach(i;0..jsFiles.length) {
			if(jsFiles[i] !in used) {
				used[jsFiles[i]] = true;
				page ~= "\n\t<script src='" ~ jsFiles[i] ~ "'></script>";
			}
		}
		
		page ~= `
</body>
</html>`;

		return page;
	}

	override string toString() {
		return wrapWithBaseContainer(content);
	}

}
