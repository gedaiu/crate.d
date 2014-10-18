﻿/**
 * 
 * source/crated/controller/base.d
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
module crated.controller.base;

/**
 * 
 */
struct HttpRequest {
	string method;
	string path;
	void* cb;

	this(string method, string path) 
		in {
			assert(
					method == "ANY" ||
					method == "GET" ||
					method == "DELETE" ||
					method == "MATCH" ||
					method == "PATCH" ||
					method == "POST" ||
					method == "PUT", 
				"Allowed methods are: `ANY`, `GET`, `DELETE`, `MATCH`, `PATCH`, `POST`, `PUT`");
		}

		body {
			this.method = method;
			this.path = path;
		}

	//TODO: this is a strange warkaround
	this(string method, string path, void* cb) {
		this(method, path);
	}
}