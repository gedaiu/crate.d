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