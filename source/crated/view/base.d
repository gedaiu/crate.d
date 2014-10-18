/**
 * 
 * source/crated/view/base.d
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
module crated.view.base;

/**
 * Parse a dh file
 */
string parseDhContent(string content) {
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
string renderDh(string file, T)(T data) {
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