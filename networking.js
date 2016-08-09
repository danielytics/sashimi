.pragma library

function request (verb, url, headers, body, callback) {
    var xhr = new XMLHttpRequest();
    if (callback) {
        xhr.onreadystatechange = function() {
            if(xhr.readyState === XMLHttpRequest.DONE) {
                var body = xhr.responseText.toString();
                var type = 'text';
                try {
                    body = JSON.parse(body);
                    type = 'json';
                } catch (e) {}
                var headerString = xhr.getAllResponseHeaders();
                var headers = {};
                if (headerString) {
                    headerString = headerString.split("\n");
                    for (var index in headerString) {
                        var line = headerString[index];
                        var idx = line.indexOf(':');
                        var key = line.substring(0, idx).trim();
                        var value = line.substring(idx + 1).trim();
                        headers[key] = value;
                    }
                }
                callback(xhr.status, headers, type, body);
            }
        }
    }
    xhr.open(verb, url);
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.setRequestHeader('Accept', 'application/json');
    for (var header in headers) {
        xhr.setRequestHeader(header, headers[header]);
    }

    xhr.send(body)
}

function workflow (base_url) {
    var object = {
        // Private data
        '_context_': [],
        // Private API
        '_last': function () {
            var stack = this._context_;
            return stack[stack.length - 1];
        },
        '_set': function (key, value) {
            this._last()[key] = value;
            return this;
        },
        '_next': function () {
            return this._context_.shift();
        },
        // Public API
        'params': function (params) {
            return this._set("params", params);
        },
        'body': function (body) {
            return this._set('body', JSON.stringify(body));
        },
        'header': function (key, value) {
            var headers = this._last()['headers'];
            if (headers === undefined) {
                headers = {}
                this._set('headers', headers);
            }
            headers[key] = value;
            return this;
        },
        'headers': function (headers) {
            var old_headers = this._last()['headers'];
            if (old_headers) {
                for (var key in headers) {
                    old_headers[key] = headers[key];
                }
                headers = old_headers;
            }
            return this._set('headers', headers);
        },
        'when': function (status, callback) {
            this._last().when[status] = callback;
            return this;
        },
        'get': function (endpoint) {
            this._set('endpoint', endpoint);
            this._set('method', 'GET');
            return this;
        },
        'post': function (endpoint) {
            this._set('endpoint', endpoint);
            this._set('method', 'POST');
            return this;
        },
        'next': function () {
            this._context_.push({when: {}});
            return this;
        },
        'run': function () {
            // Run the workflow
            var parent = this;
            var task = this._next();
            if (task !== undefined && task['method'] !== undefined) {
                // Query Params
                var params = task['params'] || {};
                var query_params = [];
                for (var key in params) {
                    var value = params[key]
                    if (typeof(value) == "function") {
                        value = value();
                    }
                    query_params.push(key + "=" + value);
                }
                var query_string = query_params.join('&');
                if (query_string) {
                    query_string = "?" + query_string;
                }

                // URL
                var endpoint = task['endpoint'] || '';
                var url = base_url + endpoint + query_string;
                // Headers
                var headers = task['headers'] || {};
                // Body
                var body = task['body'] || '';
                // Callback
                function callback (status, headers, type, body) {
                    var when = task['when'][status];
                    if (when !== undefined) {
                        when(headers, body);
                        parent.run();
                    } else {
                        console.error("Unhandled status (" + status + "), aborting workflow.");
                    }
                }
                // Make request
                request(task['method'], url, headers, body, callback);
            }
        }
    };
    return object.next();
}
