/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 11 24, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module crated.tools;


import std.conv;
import std.typetuple;


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
template IsEnum(T) if(is(T == enum)) {
	/**
		 * is true if T is enum
		 */
	enum bool check = true;
} 

template IsEnum(T) if(!is(T == enum)) {
	/**
		 * is true if T is enum
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
		alias ItemProperty = TypeTuple!(__traits(getMember, item, method));
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
	
	/**
		 *  Get a general type
		 */
	string Type(string name)() {
		
		alias isEnum = IsEnum!(typeof(ItemProperty!(Prototype, name)));
		
		static if(isEnum.check) return "isEnum";
		else static if(__traits(isIntegral, ItemProperty!(Prototype, name))) return "isIntegral";
		else static if(__traits(isFloating, ItemProperty!(Prototype, name))) return "isFloating";
		else static if( is(ItemProperty!(Prototype, name) == enum) )  return "isEnum";
		else return "";
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
		} else static if (FIELDS.length == 1 && FIELDS[0] != "modelFields") {
			static if(__traits(hasMember, Prototype, FIELDS[0])) {

				static if(staticIndexOf!(ATTR, __traits(getAttributes, ItemProperty!(Prototype, FIELDS[0]))) >= 0) {
					
					static if(addFields) {
						alias ItemFields = TypeTuple!([FIELDS[0], __traits(getAttributes, ItemProperty!(Prototype, FIELDS[0])) ]);
						
					} else {
						alias ItemFields = TypeTuple!([FIELDS[0], typeof(ItemProperty!(Prototype, FIELDS[0])).stringof[1..$-1], Type!(FIELDS[0]) ]);
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
		pragma(msg, Prototype, " has no ", ATTR , " attribute.");		
		enum string[][] fields=[];
		alias getItemFields = fields;
	}
}
