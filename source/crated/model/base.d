/**
 * Model basic functionality
 * 
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: November 3, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
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
 * Get a class property
 */
template ItemProperty(item, string method) {
	static if(__traits(hasMember, item, method)) {
		alias ItemProperty = TypeTuple!(__traits(getMember, item, method));
	} else {
		alias ItemProperty = TypeTuple!();
	}
}



template getItemFields(alias ATTR, Prototype) {

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
				static if(staticIndexOf!(ATTR, __traits(getAttributes, ItemProperty!(Prototype, FIELDS[0]))) >= 0) {
					alias ItemFields = TypeTuple!([FIELDS[0], typeof(FIELDS[0]).stringof ]);
				} else {
					alias ItemFields = TypeTuple!();
				}
			} else {
				alias ItemFields = TypeTuple!();
			}
			
		} else alias ItemFields = TypeTuple!();
	}

	enum string[][] fields = [ ItemFields!(__traits(allMembers, Prototype)) ];
	alias getItemFields = fields;
} 


/**
 * This template is used to represent one item from a model
 */
template Item(Prototype, alias M) {
	alias Item = Item!(Prototype, typeof(M));
}

template Item(Prototype, M) {

	class ItemTemplate : Prototype {
		//the item model
		private M myModel;


		//default item constructor
		this(M parent) {
			myModel = parent;
		}
		
		//a pair of a field name and type to be accessed at runtime
		enum string[][] fields = getItemFields!(field, Prototype);
		
		//the field attributes.
		//enum string[string][string] attributes = mixin(getUDA);
		
		//all the enum fields with their keys
		//enum string[][string] enumValues = mixin("[ ``: [] " ~ getEnumValues ~ "]");
		
		
		/**
		 * Save the item into model
		 */
		void save() {
			myModel.save(this);
		}

		/**
		 * Delete the item from model
		 */
		void remove() {
			myModel.remove(this);
		}

	}


	alias Item = ItemTemplate;
}

/**
 * create the code for the item From method
 */
string FromCode(Prototype, T, int i = 0)() {
	enum fields = Prototype.fields;

	//exit condition
	static if(i >= fields.length) {
		return "";
	} else {
		enum auto field = fields[i];

		//check for D types
		static if(field[2] == "basic") {

			static if(field[1] == "bool") {
				return `try { itm.`~field[0]~` = elm["`~field[0]~`"].to!`~field[1]~`; } catch(Exception e) {itm.`~field[0]~` = false; }` ~ FromCode!(Prototype, T, i + 1);
			} else {
				return `itm.`~field[0]~` = elm["`~field[0]~`"].to!`~field[1]~`;` ~ FromCode!(Prototype, T, i + 1);
			}
		} else static if(field[2] == "enum") {
			return `itm.`~field[0]~` = elm["`~field[0]~`"].to!string.to!`~field[1]~`;` ~ FromCode!(Prototype, T, i + 1);
		} else static if(field[2] == "hasFromString") {
			return `itm.`~field[0]~` = `~field[1]~`.fromString(elm["`~field[0]~`"].to!string);` ~ FromCode!(Prototype, T, i + 1);
		} else {
			pragma(msg, `Field '`,Prototype,`.`,field[0],`' can not be converted. You need a basic type, enum or class or struct with static fromString(string) method.`);

			return FromCode!(Prototype, T, i + 1);
		}
	}
}


template Model(Prototype) {

	class ModelTemplate {
		Prototype[] items;

		bool save(Prototype item) {
			return false;
		}

		bool remove(Prototype item) {
			return false;
		}


	}


	mixin MixCheckFieldsModel!ModelTemplate;
	alias Model = ModelTemplate;

}

/**
 * Generate code that checks if a certain method is declared 
 */
string _genChkMember(M, string name)() {
	static if(!__traits(hasMember, M, name)) {

		pragma(msg, "Have you forgot to declare method ["~name~"] for [", M ,"]?");
	}

	return "";
}

/**
 * This template is used to check if a model has declared all the methods
 */
mixin template MixCheckFieldsModel(M) {
	mixin(_genChkMember!(M, "createItem"));

	mixin(_genChkMember!(M, "save"));
	mixin(_genChkMember!(M, "remove"));
	mixin(_genChkMember!(M, "clean"));

	mixin(_genChkMember!(M, "all"));

	mixin(_genChkMember!(M, "query"));
	mixin(_genChkMember!(M, "findBy"));
	mixin(_genChkMember!(M, "findOneBy"));
}
