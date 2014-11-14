/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 11 5, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module docsModule;

import std.stdio;
import std.file;
import vibe.d;
import crated.model.base;


/**
 * Item for representing a module
 */
class ModuleItem {
	
	@("field", "primary")
	string name;

	@("field")
	string description = "no description";

	@("field")
	string kind = "unknown";

	@("field")
	string path;

	@("field")
	string parameters[][string];

	@("field")
	string data;

	@("field")
	bool isTemplate;

	@("field")
	string returnType;

	@("field")
	string[] members;

	@("field")
	string type;

	@("field")
	string aliasName;

	@("field")
	string aliasPath;

	this() {}

	this(const Json data, const string path, DocsModuleModel parent) {
		this.data = data.toPrettyString;

		this.name = data.name.to!string;
		this.description = data.comment.to!string;
		this.path = path ~ "/" ~ name;

		if("kind" in data) this.kind = data.kind.to!string;
		if("type" in data) this.type = data["type"].to!string;

		if(this.kind == "template") {
			isTemplate = true;
		}

		if(this.kind == "function") {
			if("type" in data) {
				auto crumbs = data.type.to!string.split("(");
				this.returnType = crumbs[0];
			}
		}

		if("parameters" in data) {
			foreach(i; 0..data.parameters.length) {
				parameters ~= [ "name": data.parameters[i]["name"].to!string,
								"type": data.parameters[i]["type"].to!string,
								"kind": data.parameters[i]["kind"].to!string];
			}
		}

		//add the child members
		if("members" in data) {
			foreach(i; 0..data.members.length) {
				members ~= [ this.path ~ "/" ~ data.members[i].name.to!string ];
				auto item = parent.addItem(data.members[i], this.path);

				if(item.name == this.name && item.kind == "alias") {
					this.aliasName = item.type;
					this.aliasPath = item.path ~ "#member" ~ members.length.to!string;
				}
			}
		}
	}
}

/**
 * The module model is a collection with all modules
 */
class DocsModuleModel : Model!ModuleItem {

	/**
	 * Read the Json file and parse the documentation
	 */
	this(const string path) {
		auto content = path.readText;
		
		Json modelData = content.parseJsonString;

		foreach(i; 0..modelData.length) {
			addItem(modelData[i], "/docs"); 
		}
	}

	ItemCls[] getByPath(string path) {
		ItemCls[] list;

		foreach(i; 0..items.length) {
			if(items[i].path.indexOf(path) != -1) {
				auto crumbs = items[i].path[path.length..$].split("/");

				if(crumbs.length == 1) list ~= items[i];
			}
		}

		return list;
	}

	/**
	 * Add an item to the model
	 */
	ItemCls addItem(const Json data, string path) {
		auto item = new ModuleItem(data, path, this);
		items ~= [ new ItemCls(item, this) ]; 

		return items[items.length-1];
	}
}