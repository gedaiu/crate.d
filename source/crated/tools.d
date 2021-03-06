﻿/**
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
 * Get all field attributes 
 */
template GetAttributes(string name, Prototype) {
	
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

template OriginalFieldType(alias F) {
	static if(is( FunctionTypeOf!F == function )) 
	{ 
		
		static if( is( ReturnType!(F) == void ) && arity!(F) == 1 ) 
		{
			alias OriginalFieldType = Unqual!(ParameterTypeTuple!F);
		} 
		else 
		{
			alias OriginalFieldType = Unqual!(ReturnType!F);
		}
		
	} else {
		alias OriginalFieldType = typeof(F);
	}
}

template ArrayType(T : T[]) {
	alias ArrayType = T;
}

template FieldType(alias F) {

	alias FT = OriginalFieldType!F;

	static if(!isSomeString!(FT) && isArray!(FT)) 
	{

		alias FieldType = ArrayType!(FT);
	} 
	else static if(isAssociativeArray!(FT)) 
	{
		alias FieldType = ValueType!(FT);
	} 
	else 
	{
		alias FieldType = Unqual!(FT);
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
template getItemFields(alias ATTR, Prototype) {

	template isConstField(alias name) {

		template CheckOverloads(TL...) {
			static if(TL.length == 1) {
				alias localIsConst = IsConst!(ReturnType!(TL[0]));
				enum bool check = localIsConst.check;

			} else static if(TL.length > 1) {
				alias localIsConst = IsConst!(ReturnType!(TL[0]));
				enum bool check = localIsConst.check || CheckOverloads!(TL[1..$]).check;

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
	string Description(string name)() {

		alias isEnum = IsEnum!(typeof(ItemProperty!(Prototype, name)));
		alias isConst = isConstField!name;

		static if(isConst.check)        return "isConst";
		else static if(isEnum.check && isTypeTuple!(__traits(getMember, Prototype, name))) return "isEnumListDeclaration"; 
		else static if(isEnum.check)	return "isEnum"; 
		else static if(!isSomeString!(typeof(ItemProperty!(Prototype, name))) && isArray!(typeof(ItemProperty!(Prototype, name)))) return "isArray";
		else static if(isAssociativeArray!(typeof(ItemProperty!(Prototype, name)))) return "isAssociativeArray";
		else static if(__traits(isIntegral, ItemProperty!(Prototype, name))) return "isIntegral";
		else static if(__traits(isFloating, ItemProperty!(Prototype, name))) return "isFloating";
		else static if( is(ItemProperty!(Prototype, name) == enum) )  return "isEnum";
		else return "";
	}

	template strOf(T) {
		enum str = "object:" ~ T.stringof;

		alias strOf = str;
	}

	template strOf(alias T) {
		enum str = T;
		
		alias strOf = T;
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
		} else static if (FIELDS.length == 1) {

			static if(ItemProperty!(Prototype, FIELDS[0]).length == 1) {
				static if(staticIndexOf!(ATTR, GetAttributes!(FIELDS[0], Prototype)) >= 0) {
					alias Type = FieldType!(ItemProperty!(Prototype, FIELDS[0]));

					static if(isBasicType!Type)
						enum isBasicType = true.stringof;
					else 
						enum isBasicType = false.stringof;

					alias ItemFields = TypeTuple!([FIELDS[0]: [ "attributes": [ staticMap!(strOf, GetAttributes!(FIELDS[0], Prototype)) ], "type": [ Type.stringof, isBasicType ], "description": [ Description!(FIELDS[0]) ] ] ]);	
				} else {
					alias ItemFields = TypeTuple!();
				}
			} else {
				alias ItemFields = TypeTuple!();
			}
			
		} else alias ItemFields = TypeTuple!();
	}

	mixin("enum list = [ " ~ Join!(ItemFields!(__traits(allMembers, Prototype))) ~ " ];");

	/**
	 * All the members that have ATTR attribute
	 */
	static if(list.length > 0) {
		alias getItemFields = list;
	} else {
		static assert(false, Prototype.stringof ~ " has no "~ ATTR ~" attribute.");
	}
}

template EnumerateFieldList(Prototype) {
	/** 
	 * Get all the metods that have ATTR attribute
	 */
	template ItemFields(FIELDS...) {
		
		static if (FIELDS.length > 1) {
			alias ItemFields = TypeTuple!(
				ItemFields!(FIELDS[0 .. $/2]),
				ItemFields!(FIELDS[$/2 .. $])
				); 
		} else static if (FIELDS.length == 1) {
			
			static if(ItemProperty!(Prototype, FIELDS[0]).length == 1 && !isTypeTuple!(__traits(getMember, Prototype, FIELDS[0])) && !__traits(hasMember, Object, FIELDS[0]) && FIELDS[0] != "__ctor") {
				alias ItemFields = TypeTuple!(FIELDS[0]);		
			} else {
				alias ItemFields = TypeTuple!();
			}
			
		} else alias ItemFields = TypeTuple!();
	}

	enum list = [ ItemFields!(__traits(allMembers, Prototype)) ];

	alias EnumerateFieldList = list;
}



template Join(List...) {
	
	static if(List.length == 1) {
		enum l = List[0].stringof[1..$-1];
	} else static if(List.length > 1) {
		enum l = List[0].stringof[1..$-1] ~ ", " ~ Join!(List[1..$]);
	} else {
		enum l = "";
	}
	
	alias Join = l;
}

template FieldList(Prototype) {
	enum string[][string][string] fields = getItemFields!("field", Prototype);

	alias FieldList = fields;
}


template FindPrimary(Prototype, Fields...) {
	
	static if(Fields.length == 1) {
		static if(ItemProperty!(Prototype, Fields[0]).length == 1) {
			static if(staticIndexOf!("primary", GetAttributes!(Fields[0], Prototype)) >= 0) {
				alias FindPrimary = TypeTuple!(__traits(getMember, Prototype, Fields[0]));
			} else {
				alias FindPrimary = TypeTuple!();
			}
		}
	} else static if(Fields.length > 1) {
		alias FindPrimary = TypeTuple!(FindPrimary!(Prototype, Fields[0..$/2]), FindPrimary!(Prototype, Fields[$/2..$]));
	}
}


template PrimaryFieldType(Prototype) {
	alias PrimaryFieldType = Unqual!(typeof(FindPrimary!(Prototype, __traits(allMembers, Prototype))));
}


template PrimaryFieldName(Prototype) {
	enum string name = FindPrimary!(Prototype, __traits(allMembers, Prototype))[0].stringof;

	alias PrimaryFieldName = name;
}


string[string] toStringDictionary(T)(T data, bool isFirst = true) {
	string[string] dict;

	import std.stdio;

	static if(is(T == Json) || is(T == Bson)) {

		if(data.type == T.Type.array) { 

			foreach(i; 0..data.length) {
				string[string] item = toStringDictionary(data[i], false);

				string itemKey = i.to!string;
				if(!isFirst) itemKey = "["~itemKey~"]";

				foreach(itemSubkey, value; item) {

					dict[ itemKey ~ itemSubkey ] = value;
				}
			}

		} else if(data.type == T.Type.object) {

			foreach(string key, val; data) {
				string[string] item = toStringDictionary(val, false);

				string itemKey = key;
				if(!isFirst) itemKey = "["~itemKey~"]";

				foreach(itemSubkey, value; item) {
					dict[ itemKey ~ itemSubkey ] = value;
				}
			}

		} else {
			dict[""] = data.to!string;
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

unittest {
	Json data = Json.emptyObject;
	data["otherdata"] = Json.emptyObject;
	data["otherdata"]["a"] = Json.emptyArray;
	data["otherdata"]["a"] ~= Json("test");

	auto ret = toStringDictionary(data);

	assert("otherdata[a][0]" in ret);
	assert(ret["otherdata[a][0]"] == "test");
}

///Tells if a value of a Class or Struct member can be get without passing any parameter.
template CanGetValue(string fieldName, Type) {
	static if(fieldName != "__ctor" &&
				__traits(getProtection, __traits(getMember, Type, fieldName)) == "public" &&
				!__traits(hasMember, Object, fieldName) && 
				!isTypeTuple!(__traits(getMember, Type, fieldName) )) {

		enum result = IsTypeMember!(fieldName, Type) || CanGetMethodValue!(fieldName, Type);

	} else {
		enum result = false;
	}

	alias CanGetValue = result;
}

///Tells if a member is Type not a function
template IsTypeMember(string fieldName, Type) {
	static if ( is(FunctionTypeOf!(__traits(getMember, Type, fieldName)) == function) ) {
		enum result = false;
	} else {
		enum result = true;
	}

	alias IsTypeMember = result;
}

///Tells if a member is a function that return value is not void and it takes no parameters
template CanGetMethodValue(string fieldName, Type) {

	template OverloadCanGetMethodValue(alias i, L...) {

		static if(L.length <= i) {
			enum result = false;
		} else static if ( is(FunctionTypeOf!(L[i]) == function) ) {
			
			static if( is(ReturnType!(L[i]) == void) ) {
				enum result = OverloadCanGetMethodValue!(i+1, L);
			} else static if( (ParameterTypeTuple!(L[i])).length > 0 ) {
				enum result = OverloadCanGetMethodValue!(i+1, L);
			} else static if ( __traits(getProtection, L[i]) == "public" ) {
				enum result = true;
			}
			
		} else {
			enum result = OverloadCanGetMethodValue!(i+1, L);
		}

		alias OverloadCanGetMethodValue = result;
	}


	alias CanGetMethodValue = OverloadCanGetMethodValue!(0, __traits(getOverloads, Type, fieldName));
}