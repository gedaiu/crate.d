/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 11 24, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module crated.tools;


import std.conv;
import std.typetuple;
import std.traits;

import vibe.d;

/**
 * Find if type (T) is an enum.
 * Example:
 * --------------------------
 * enum BookCategory : string {
 *		Fiction = "Fiction",
 *		Nonfiction = "Nonfiction"
 * };
 *  
 * auto test = IsEnum!BookCategory;
 * assert(test.check == true);
 * --------------------------
 * 
 * Example:
 * --------------------------
 *  auto test = IsEnum!string;
 *  assert(test.check == false);
 * --------------------------
 */
template IsEnum(T) if(is(T == enum )) {
	/**
	 * is true if T is enum
	 */
	enum bool check = true;
} 

template IsEnum(T) if(!is(T == enum )) {
	/**
	 * is false if T is const
	 */
	enum bool check = false;
}

/**
 * Find if type (T) is const.
 */
template IsConst(T) if(is(T == const )) {
	/**
	 * is true if T is const
	 */
	enum bool check = true;
} 

template IsConst(T) if(!is(T == const )) {
	/**
	 * is false if T is not const
	 */
	enum bool check = false;
}

/**
 * Check if the method has a from string method.
 * 
 * Example: 
 * --------------------
 * class BookItemPrototype {
 * 	private string name;
 * 
 * 	this(string name) {
 *  	this.name = name;
 * 	}
 * 
 * 	static BookItemPrototype FromString(string name) {
 * 		return new BookItemPrototype(name);
 *  }
 * }
 * 
 * assert(HasFromString!BookItemPrototype == true);
 * assert(HasFromString!Object == false);
 * --------------------
 * 
 */
template HasFromString(T) if(is(T == class) || is(T == struct)) {
	/**
	 * is true if T has `from string` method
	 */
	enum bool check = __traits(hasMember, T, "fromString");
}

template HasFromString(T) if(!is(T == class) && !is(T == struct)) {
	/**
	 * is true if T has `from string` method
	 */
	enum bool check = false;
}

/**
 * Get a class property.
 *
 * Example: 
 * --------------------
 * class BookItemPrototype {
 * 	@("field", "primary")
 *	ulong id;
 *
 *	@("field") string name = "unknown";
 * 	@("field") string author = "unknown";
 * }
 * 
 * assert(__traits(isIntegral, ItemProperty!(BookItemPrototype, "id")) == true);
 * --------------------
 */
template ItemProperty(item, string method) {
	static if(__traits(hasMember, item, method)) {
		static if(__traits(getProtection, mixin("item." ~ method)).stringof[1..$-1] == "public") {
			alias ItemProperty = TypeTuple!(__traits(getMember, item, method));
		} else {
			alias ItemProperty = TypeTuple!();
		}

	} else {
		alias ItemProperty = TypeTuple!();
	}
}

/** 
 * Get all members that have ATTR attribute.
 * 
 * Example: 
 * --------------------
 * class BookItemPrototype {
 * 	@("field", "primary")
 *	ulong id;
 *
 *	@("field") string name = "unknown";
 * 	@("field") string author = "unknown";
 * }
 * 
 * 
 * enum string[][] fields = getItemFields!("field", BookItemPrototype);
 * 
 * assert(fields[0][0] == "id");
 * assert(fields[0][1] == "ulong");
 * assert(fields[0][2] == "isIntegral");
 * 
 * --------------------
 */
template getItemFields(alias ATTR, Prototype, bool addFields) {

	template isConstField(alias name) {

		template CheckOverloads(TL...) {
			static if(TL.length == 1) {
				alias localIsConst = IsConst!(ReturnType!(TL[0]));
				enum bool check = localIsConst.check;
			} else static if(TL.length >1) {
				alias localIsConst = IsConst!(ReturnType!(TL[0]));
				enum bool check = localIsConst.check && CheckOverloads!(TL[1..$]).check;

			} else {
				enum bool check = false;
			}
		}

		static if(is( FunctionTypeOf!(ItemProperty!(Prototype, name)) == function )) {
			enum bool check = CheckOverloads!(__traits(getOverloads, Prototype, name)).check;
		} else { 
			alias localIsConst = IsConst!(typeof(__traits(getMember, Prototype, name)));
			enum bool check = localIsConst.check;
		}
	}

	/**
	 *  Get a general type
	 */
	string Type(string name)() {

		alias isEnum = IsEnum!(typeof(ItemProperty!(Prototype, name)));
		alias isConst = isConstField!name;

		static if(isConst.check)        return "isConst"; 
		else static if(isEnum.check)	return "isEnum"; 
		else static if(__traits(isIntegral, ItemProperty!(Prototype, name))) return "isIntegral";
		else static if(__traits(isFloating, ItemProperty!(Prototype, name))) return "isFloating";
		else static if( is(ItemProperty!(Prototype, name) == enum) )  return "isEnum";
		else return "";
	}


	//TODO: use Unqual! to get the type
	/**
	 * Get the type of a Prototype fieald
	 */
	string FieldType(string name)() {

		static if(is( FunctionTypeOf!(ItemProperty!(Prototype, name)) == function )) { 

			static if( is( ReturnType!(ItemProperty!(Prototype, name)) == void ) && arity!(ItemProperty!(Prototype, name)) == 1 ) {

				auto t = ParameterTypeTuple!(ItemProperty!(Prototype, name))[0].stringof;

				if(t[0..6] == "const(") {
					t = t[6..$-1];
				}

				return t;

			} else {
				return ReturnType!(ItemProperty!(Prototype, name)).stringof;
			}

		} else {
			return typeof(ItemProperty!(Prototype, name)).stringof[1..$-1];
		}
	}

	/**
	 * Get all field attributes 
	 */
	template GetAttributes(string name) {

		template GetFuncAttributes(TL...) {

			static if(TL.length == 1) {
				alias GetFuncAttributes = TypeTuple!(__traits(getAttributes, TL[0]));
			} else static if(TL.length > 1) {
				alias GetFuncAttributes = TypeTuple!(GetFuncAttributes!(TL[0..$/2]), GetFuncAttributes!(TL[$/2..$]));
			} else {
				alias GetFuncAttributes = TypeTuple!();
			}
		}

		static if(is( FunctionTypeOf!(ItemProperty!(Prototype, name)) == function )) { 

			static if(__traits(getOverloads, Prototype, name).length == 1) {
				alias GetAttributes = TypeTuple!(__traits(getAttributes, ItemProperty!(Prototype, name)));
			} else {
				alias GetAttributes = TypeTuple!(GetFuncAttributes!(TypeTuple!(__traits(getOverloads, Prototype, name))));
			}

		} else {
			alias GetAttributes = TypeTuple!(__traits(getAttributes, ItemProperty!(Prototype, name)));
		}
	}



	/** 
	 * Get all the metods that have ATTR attribute
	 */
	template ItemFields(FIELDS...) {

		static if (FIELDS.length > 1) {
			alias ItemFields = TypeTuple!(
					ItemFields!(FIELDS[0 .. $/2]),
					ItemFields!(FIELDS[$/2 .. $])
				); 
		} else static if (FIELDS.length == 1 && FIELDS[0] != "modelFields" ) {

			static if(ItemProperty!(Prototype, FIELDS[0]).length == 1) {
				static if(staticIndexOf!(ATTR, GetAttributes!(FIELDS[0])) >= 0) {
					static if(addFields) {
						alias ItemFields = TypeTuple!([FIELDS[0], __traits(getAttributes, ItemProperty!(Prototype, FIELDS[0])) ]);	
					} else {
						alias ItemFields = TypeTuple!([FIELDS[0], FieldType!(FIELDS[0]), Type!(FIELDS[0]) ]);
					}

				} else {
					alias ItemFields = TypeTuple!();
				}
			} else {
				alias ItemFields = TypeTuple!();
			}
			
		} else alias ItemFields = TypeTuple!();
	}

	alias list = ItemFields!(__traits(allMembers, Prototype));

	/**
	 * All the members that have ATTR attribute
	 */
	static if(list.length > 0) {
		enum string[][] fields = [ list ];
		alias getItemFields = fields;
	} else {
		static assert(false, Prototype.stringof ~ " has no "~ ATTR ~" attribute.");
	}
}



template PrimaryFieldType(Prototype) {
	enum fields = getItemFields!("primary", Prototype, false);
	
	alias PrimaryFieldType = typeof(ItemProperty!(Prototype, fields[0][0]));
}

mixin template PrototypeReflection(Prototype) {

	OriginalType!(PrimaryFieldType!Prototype) primaryField(const Prototype item) {
		enum fields = getItemFields!("primary", Prototype, false);

		return __traits(getMember, item, fields[0][0]);
	}

	enum string primaryFieldName = getItemFields!("primary", Prototype, false)[0][0];

	/**
	 * A pair of a field name and type to be accessed at runtime
	 */
	enum string[][] fields = getItemFields!("field", Prototype, false);

	/**
	 * A pair of a field name and type to be accessed at runtime
	 */
	//static enum string[] primaryField = getItemFields!("primary", Prototype, false)[0];
	
	//TODO: make attributes of type string[string][string] to avoid runtime string parsing in valueOf method
	///The field attributes.
	enum string[][] attributes = getItemFields!("field", Prototype, true);
}

string[string] toDict(T)(T data) {
	string[string] dict;

	static if(is(T == Json) || is(T == Bson)) {

		foreach(string key, T val; data) {
			dict[key] = val.to!string;
		}

		return dict;
	} else static if (__traits(isSame, TemplateOf!(T), vibe.utils.dictionarylist.DictionaryList)) {

		foreach(string key, val; data) {
			dict[key] = val;
		}

		return dict;
	} else {
		throw new Exception("Can not convert to dictionary type of " ~ T.stringof);
	}
}
