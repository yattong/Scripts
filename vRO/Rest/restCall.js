/* This creates a Logger object that can be used to standardise the log output in workflows.
* @Author Yattong Wu
* @Date 18 April 2019 
* @param {REST:RESTHOST} restHost - The Host for REST connections
* @param {string} restMethod - The REST Method: GET/PUT/PATCH/DELETE
* @param {string} restUri - Url for rest command
* @param {string} acceptType - Accept Type response
* @param {string} contentType - Format of content type being sent
* @param {string} content - Content being sent
* @param {Properties} headers - Rest Call Headers
* @param {boolean} throwOnError - Throw error on incorrect response code?
* @return {Any} - The Rest Call Response.
*/

// Set Variables
var objType = "Action";
var objName = "restCall"; // This must be set to the name of the action
var Logger = System.getModule("com.vodafone.agilecloud.library.util").standardisedLogger(objType,objName);
var log = new Logger(objType, objName);
// Start logging
log.debug("------ Starting " + objName + " ------");

// Create Object
function restCall(restHost, acceptType, contentType, headers){
	// Set Rest Host
	this.restHost = restHost;
		
	// Set default accept type
	if (acceptType){
		this.acceptType = acceptType;
	} else {
		this.acceptType = "application/json";
	}
	log.debug("REST Accept-Type: " + this.acceptType)

	// Set default content type
	if (contentType){
		this.contentType = contentType;
	} else {
		this.contentType = "application/json";
	}
	log.debug("REST Content-Type: " + this.contentType)

	// function
	this.GET = function (restUri, throwOnError){
		// Set up request
		var request = this.restHost.createRequest("GET", restUri);
		log.debug("REST URL: " + request.fullUrl);

		// Set up request details
		request.setHeader("Accept", this.acceptType);
		request.contentType = this.contentType;
		
		// Set headers
		if (headers && headers.length > 0){
			for each (headerKey in headers.keys){
				var headerValue = headers.get(headerKey);
				log.debug("REST Header: " + headerKey + ":" + headerValue);
				request.setHeader(headerKey, headerValue);
			}
		}
		
		// execute request
		var response = request.execute();
		log.debug("REST Response Code: " + response.statusCode);

		// Throw error
		if (response.statusCode >= 400 && throwOnError == true){
			errorMessage = "Error response code received from restCall : " + response.statusCode + "\n . \n" + response.ContentAsString;
			throw errorMessage;
		}
		
		// return response
		log.debug("REST Response Content: " + response.ContentAsString);
		return response;
	}
	this.POST = function (restUri, content, throwOnError){
		// Set up request
		var request = this.restHost.createRequest("POST", restUri, content);
		log.debug("REST URL: " + request.fullUrl);
		log.debug("REST Content: " + content);
		
		// Set up request details
		request.setHeader("Accept", this.acceptType);
		request.contentType = this.contentType;
		
		// Set headers
		if (headers && headers.length > 0){
			for each (headerKey in headers.keys){
				var headerValue = headers.get(headerKey);
				log.debug("REST Header: " + headerKey + ":" + headerValue);
				request.setHeader(headerKey, headerValue);
			}
		}

		// execute request
		var response = request.execute();
		log.debug("REST Response Code: " + response.statusCode);

		// Throw error
		if (response.statusCode >= 400 && throwOnError == true){
			errorMessage = "Error response code received from restCall : " + response.statusCode + "\n . \n" + response.ContentAsString;
			throw errorMessage;
		}
		
		// return response
		log.debug("REST Response Content: " + response.ContentAsString);
		return response;
	}
	this.PUT = function (restUri, content, throwOnError){
		// Set up request
		var request = this.restHost.createRequest("PUT", restUri, content);
		log.debug("REST URL: " + request.fullUrl);
		log.debug("REST Content: " + content);
		
		// Set up request details
		request.setHeader("Accept", this.acceptType);
		request.contentType = this.contentType;
		
		// Set headers
		if (headers && headers.length > 0){
			for each (headerKey in headers.keys){
				var headerValue = headers.get(headerKey);
				log.debug("REST Header: " + headerKey + ":" + headerValue);
				request.setHeader(headerKey, headerValue);
			}
		}
		
		// execute request
		var response = request.execute();
		log.debug("REST Response Code: " + response.statusCode);

		// Throw error
		if (response.statusCode >= 400 && throwOnError == true){
			errorMessage = "Error response code received from restCall : " + response.statusCode + "\n . \n" + response.ContentAsString;
			throw errorMessage;
		}
		
		// return response
		log.debug("REST Response Content: " + response.ContentAsString);
		return response;
	}
	this.DELETE = function (restUri, throwOnError){
		var request = this.restHost.createRequest("DELETE", restUri);
		log.debug("REST URL: " + request.fullUrl);
		
		// Set default accept type
		// Set up request details
		request.setHeader("Accept", this.acceptType);
		request.contentType = this.contentType;
		
		// Set headers
		if (headers && headers.length > 0){
			for each (headerKey in headers.keys){
				var headerValue = headers.get(headerKey);
				log.debug("REST Header: " + headerKey + ":" + headerValue);
				request.setHeader(headerKey, headerValue);
			}
		}
		
		// execute request
		var response = request.execute();
		log.debug("REST Response Code: " + response.statusCode);

		// Throw error
		if (response.statusCode >= 400 && throwOnError == true){
			errorMessage = "Error response code received from restCall : " + response.statusCode + "\n . \n" + response.ContentAsString;
			throw errorMessage;
		}
		
		// return response
		log.debug("REST Response Content: " + response.ContentAsString);
		return response;
	}
	this.PATCH = function (restUri, content, throwOnError){
		var request = this.restHost.createRequest("PATCH", restUri, content);
		log.debug("REST URL: " + request.fullUrl);
		log.debug("REST Content: " + content);
		
		// Set up request details
		request.setHeader("Accept", this.acceptType);
		request.contentType = this.contentType;
		
		// Set headers
		if (headers && headers.length > 0){
			for each (headerKey in headers.keys){
				var headerValue = headers.get(headerKey);
				log.debug("REST Header: " + headerKey + " : " + headerValue);
				request.setHeader(headerKey, headerValue);
			}
		}

		// execute request
		var response = request.execute();
		log.debug("REST Response Code: " + response.statusCode);

		// Throw error
		if (response.statusCode >= 400 && throwOnError == true){
			errorMessage = "Error response code received from restCall : " + response.statusCode + "\n . \n" + response.ContentAsString;
			throw errorMessage;
		}
		
		// return response
		log.debug("REST Response Content: " + response.ContentAsString);
		return response;
	}
}

return restCall;
