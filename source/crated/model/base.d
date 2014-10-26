/**
 * 
 * source/crated/model/base.d
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
module crated.model.base;

import std.stdio;
import std.traits;
public import std.conv;
public import std.typetuple;

/// User defined attribute (not intended for direct use)
struct FieldAttribute {
	string name;
}

/**
 *	Attribute marking a property field
 */
@property FieldAttribute field()
{
	return FieldAttribute("field");
}

/**
 *	Attribute marking a property primary field
 */
@property FieldAttribute primary()
{
	return FieldAttribute("primary");
}

/**
 *	Attribute marking a property required field
 */
@property FieldAttribute required()
{
	return FieldAttribute("required");
}

/**
 *	Attribute that sets a property type (used for randering)
 */
@property FieldAttribute type(string name)()
{
	return FieldAttribute(name);
}

//check if the type is an enum
template IsEnum(T) if(is(T == enum)) {
	enum bool check = true;
} 
template IsEnum(T) if(!is(T == enum)) {
	enum bool check = false;
} 

//check if the method has an from string method
template HasFromString(T) if(is(T == class) || is(T == struct)) {
	enum bool check = __traits(hasMember, T, "fromString");
}
template HasFromString(T) if(!is(T == class) && !is(T == struct)) {
	enum bool check = false;
}

/**
 * This template is used to represent one item from a model
 */
public mixin template MixItem(Prototype, Model) {

	//the item model
	private Model myModel;

	//default item constructor
	this(Model parent) {
		myModel = parent;
	}

	/**
	 * Get a class property
	 */
	private template ItemProperty(item, string method) {
		
		static if(__traits(hasMember, item, method)) {
			alias ItemProperty = TypeTuple!(__traits(getMember, item, method));
		} else {
			alias ItemProperty = TypeTuple!();
		}
	}

	/** 
	 * Get all the metods that have @field attribute
	 */
	template ItemFields(FIELDS...) {
		static if (FIELDS.length > 1) {
			alias ItemFields = TypeTuple!(
				ItemFields!(FIELDS[0 .. $/2]),
				ItemFields!(FIELDS[$/2 .. $])
				); 
		} else static if (FIELDS.length == 1 && FIELDS[0] != "modelFields") {
			
			static if(__traits(hasMember, Prototype, FIELDS[0])) {
				static if(staticIndexOf!(field, __traits(getAttributes, ItemProperty!(Prototype, FIELDS[0]))) >= 0) {
					alias ItemFields = TypeTuple!(FIELDS[0]);
				} else {
					alias ItemFields = TypeTuple!();
				}
			} else {
				alias ItemFields = TypeTuple!();
			}
			
		} else alias ItemFields = TypeTuple!();
	}

	/** 
	 * Get all the metods that have @field attribute
	 */
	template PrimaryFields(FIELDS...) {
		static if (FIELDS.length > 1) {
			alias PrimaryFields = TypeTuple!(
				PrimaryFields!(FIELDS[0 .. $/2]),
				PrimaryFields!(FIELDS[$/2 .. $])
				); 
		} else static if (FIELDS.length == 1 && FIELDS[0] != "modelFields") {
			
			static if(__traits(hasMember, Prototype, FIELDS[0])) {
				static if(staticIndexOf!(primary, __traits(getAttributes, ItemProperty!(Prototype, FIELDS[0]))) >= 0) {
					alias PrimaryFields = TypeTuple!(FIELDS[0]);
				} else {
					alias PrimaryFields = TypeTuple!();
				}
			} else {
				alias PrimaryFields = TypeTuple!();
			}
			
		} else alias PrimaryFields = TypeTuple!();
	}


	//a pair of a field name and type to be accessed at runtime
	enum string[][] fields = mixin(getFields);

	//the field attributes.
	enum string[string][string] attributes = mixin(getUDA);

	//all the enum fields with their keys
	enum string[][string] enumValues = mixin("[ ``: [] " ~ getEnumValues ~ "]");

	/**
	 * Generate the values for the enums from the current item
	 */
	private static string getEnumValues(ulong i = 0)() {
		enum fields = Prototype.fields;
		
		//exit condition
		static if(i >= fields.length) {
			return "";
		} else {
			enum auto field = fields[i];
			
			//check for D types
			static if(field[2] == "enum") {
				import std.traits;

				string vals = "";

				string glue = "";
				foreach(v; EnumMembers!(typeof(__traits(getMember, Prototype, field[0])))) {
					vals ~= glue ~ `"` ~ v.stringof[1..$-1] ~ `"`; 
					glue ~= ", ";
				}

				return `, "` ~ field[0] ~ `": [` ~ vals ~ `]` ~ getEnumValues!(i + 1);
			} else {
				return getEnumValues!(i + 1);
			}
		}

	}

	/**
	 * Generate the UDA list for fields
	 */
	private static string getUDA() {
		string glue;
		string a;

		foreach (method; __traits(allMembers, Prototype)) {
			static if (method != "fields" && method != "attributes") {
				string glue2;
				string b;
				foreach (i, T; __traits(getAttributes, ItemProperty!(Prototype, method))) {
					if(T.stringof == "type()") {
						b ~= glue2 ~ `"type":"`~T.name~`"`;
					} else {
						b ~= glue2 ~ `"` ~ T.name ~ `":""`;
					}
					
					glue2 = ", ";
				}
				
				if(b != "") {
					a ~= glue ~ `"`~method~`": [` ~ b ~ `]`;
					glue = ", ";
				}
			}
		}

		if(a != "") return "[" ~ a ~ "]";

		return "null";
	}

	/**
	 * Generate the field list
	 */
	private static string getFields() {
		string a = "[";

		import std.traits;

		string glue;
		foreach (method; __traits(allMembers, Prototype)) {
			static if (method != "fields") {
				string b;
				foreach (i, T; __traits(getAttributes, __traits(getMember, Prototype, method))) {
					if(T.stringof == "field()") {

						string type = "unknown";
						alias isEnum = IsEnum!(typeof(__traits(getMember, Prototype, method)));
						alias hasFromString = HasFromString!(typeof(__traits(getMember, Prototype, method)));

						if(isEnum.check) {
							type = "enum";
						} else if(isBasicType!(typeof(__traits(getMember, Prototype, method))) || 
						   isSomeString!(typeof(__traits(getMember, Prototype, method)))) {
							type = "basic";

						} else if(hasFromString.check) {
							type = "hasFromString";
						}

						b = `"`~method~`", "` ~ 
									typeof(__traits(getMember, Prototype, method)).stringof ~ `", "` ~ type
								~`"`;
						break;
					}
				}

				if(b != "") {
					a ~= glue ~ `[` ~ b ~ `]`;
					glue = ", ";
				}
			}
		}
		
		return a ~ "]";
	}

	/**
	 * Get the if field for the current item
	 */
	@property
	static string primaryField() {
		enum primaryFields = [ PrimaryFields!(__traits(allMembers, Prototype)) ];

		static assert(primaryFields.length > 0, "there are no fields marked with @primary attribute.");

		return primaryFields[0];
	}

	/**
	 * Check if a field has a certain attribute
	 */
	static bool has(string property, string attr) {
		if( property in attributes && attr in attributes[property]) {
			return true;
		} else {
			return false;
		}
	}

	/**
	 * Get the value of a certain attribute
	 */
	static string valueOf(string property, string attr) {
		if( property in attributes && attr in attributes[property]) {
			return attributes[property][attr];
		} else {
			return "";
		}
	}

	/**
	 * Get Json body for all the item fields
	 */
	private static string propertyJson() {
		string a;

		string glue = "";
		foreach (mname; ItemFields!(__traits(allMembers, Prototype))) {
			a ~= glue ~ "\"" ~ mname ~ "\": ";

			static if(__traits(isIntegral, ItemProperty!(Prototype, mname))) {
				//is int
				a ~= "` ~ this." ~ mname ~ ".to!string" ~ " ~ `";
			} else static if(__traits(isFloating, ItemProperty!(Prototype, mname))) {
				//is float
				a ~= "` ~ ( this." ~ mname ~ ".to!string[$-1..$] == \"i\" ? 
				                         `\"` ~  this." ~ mname ~ ".to!string ~ `\"` : 
				                                 this." ~ mname ~ ".to!string ) ~ `";
			} else {
				//is something else
				a ~= "\"` ~ this." ~ mname ~ ".to!string" ~ " ~ `\"";
			}

			glue = ",\n";
		}

		return a;
	}

	/**
	 * Save the item into the model
	 */
	void save() {
		myModel.save(this);
	}

	/**
	 * Convert item to string
	 */
	override string toString() {

		string a = "{ ";

		mixin("a ~= `" ~ propertyJson() ~ "`;");

		a ~= " }";

		return a;
	}

	/**
	 * Create an item based on T type
	 */
	static BookItem From(T)( T elm, BookModel parent ) {
		BookItem itm = new BookItem(parent);

		mixin(FromCode!Prototype);
		
		return itm;
	}
}

/**
 * create the code for the item From method
 */
string FromCode(Prototype, int i = 0)() {
	enum fields = Prototype.fields;

	//exit condition
	static if(i >= fields.length) {
		return "";
	} else {
		enum auto field = fields[i];

		//check for D types
		static if(field[2] == "basic") {
			return `itm.`~field[0]~` = elm["`~field[0]~`"].to!`~field[1]~`;` ~ FromCode!(Prototype, i + 1);
		} else static if(field[2] == "enum") {
			return `itm.`~field[0]~` = elm["`~field[0]~`"].to!string.to!`~field[1]~`;` ~ FromCode!(Prototype, i + 1);
		} else static if(field[2] == "hasFromString") {
			return `itm.`~field[0]~` = `~field[1]~`.fromString(elm["`~field[0]~`"].to!string);` ~ FromCode!(Prototype, i + 1);
		} else {
			pragma(msg, `Field '`,Prototype,`.`,field[0],`' can not be converted. You need a basic type, enum or class or struct with static fromString(string) method.`);

			return FromCode!(Prototype, i + 1);
		}
	}
}


/**
 * This template is used to represent one item from a model
 */
public mixin template MixModel(Prototype, Model) {
	Prototype[] items;

	/**
	 * Create one item
	 */
	Prototype createItem() {
		auto item = new Prototype(this);
		mixin("item." ~ Prototype.primaryField) = items.length + 1;
		items ~= [ item ];

		return item;
	}

	/**
	 * Save the item
	 */
	void save(Prototype item) {
		items[mixin("item." ~ Prototype.primaryField) - 1] = item;
	}	
	
	/**
	 * Get all model items
	 */
	auto allItems() {
		return items;
	}
	
	/**
	 * Return all the items that match the query
	 */
	Prototype[] findBy(string field, U)(U value) {
		Prototype[] list;

		foreach(j; 0..items.length) {
			if(mixin("items[j]." ~ field ~ " == value")) {
				list ~= items[j];
			}
		}

		return list;
	}
	
	/**
	 * Returns first item that match the query
	 */
	Prototype findOneBy(string field, U)(U value) {
		Prototype item;

		foreach(j; 0..items.length) {
			if(mixin("items[j]." ~ field ~ " == value")) {
				return items[j];
			}
		}

		return null;
	}


	mixin MixCheckFieldsModel!(Model);
}

/**
 * Generate code that checks if a certain method is declared 
 */
string _genChkMember(Model, string name)() {
	static if(!__traits(hasMember, Model, name)) {

		pragma(msg, "Have you forgot to declare method ["~name~"] for [", Model ,"]?");
	}

	return "";
}

/**
 * This template is used to check if a model has declared all the methods
 */
public mixin template MixCheckFieldsModel(Model) {

	mixin(_genChkMember!(Model, "createItem"));

	mixin(_genChkMember!(Model, "save"));
	mixin(_genChkMember!(Model, "remove"));

	mixin(_genChkMember!(Model, "allItems"));

	mixin(_genChkMember!(Model, "query"));
	mixin(_genChkMember!(Model, "findBy"));
	mixin(_genChkMember!(Model, "findOneBy"));

}
