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

// Set Standard Logging
var objType = "Action";
var objName = "RestCall"; // This must be set to the name of the action
var Logger = System.getModule("london.clouding.logging").standardisedLogger();
var log = new Logger(objType, objName);

// Start logging
log.debug("------ Starting " + objType + " : " + objName + " ------");

// Create Object
function RestCall(restHost, acceptType, contentType, headers){
	// Set Rest Host
	this.restHost = restHost;
  
  // Set headers
  function setHeaders(request,headers,debugMode){
    for each (headerKey in headers.keys){
      var headerValue = headers.get(headerKey);
      if(debugMode == true) log.debug("REST Header: " + headerKey + ":" + headerValue);
      request.setHeader(headerKey, headerValue);
    }
  }

  function logOut(fullUrl,method,content,contentType,acceptType){
    log.debug("URL : "+fullUrl);
    log.debug("REST Method : "+method);
    log.debug("Accept Type : "+acceptType);
    log.debug("Content Type : "+contentType);
    content = (content.match(/password/i) ? JSON.stringify(JSON.parse(content)["password"] = "************") : content;
    log.debug("Content : "+content);
  }

  function execute(request,throwOnError,debugMode){
    var i=0;
    var max=5;
    var interval=(10*1000) // 10 seconds
    var response;

    do{
      log.debug("Attempt "+(i+1)+" of "+max+" REST request execution...");
      response = request.execute();
      i++;
      if(response == null || response >= 400) System.sleep(interval);
    } while ((response == null || response >= 400) && i < max);

    if(response == null || response == >= 400){
      if(throwOnError == true){
        log.error("REST Status Code : "+response.statusCode+"\nREST Response : "+response.ContentAsString);
      } else {
        log.warn("REST Status Code : "+response.statusCode);
        log.warn("REST Response : "+response.ContentAsString);
      }
    }

    if(debugMode == true){
      log.debug("REST Status Code : "+response.statusCode);
      log.debug("REST Response : "+response.ContentAsString);
    }

    return response;
  }

	// function
	this.GET = function (restUri,acceptType,headers,throwOnError,debugMode){
    var request = this.restHost.createRequest("GET", restUri);
    debugMode = (debugMode == null) ? true : false;
    request.setHeader("Accept",acceptType);
    if(headers.keys.length > 0) setHeaders(request,headers,debugMode);
    if(debugMode == true) logOut(request.fullUrl,request.getMethod(),"","",acceptType);
    return execute(request,throwOnError,debugMode);
  }
  
  this.DELETE = function (restUri,acceptType,content,contentType,headers,throwOnError,debugMode){
    var request = this.restHost.createRequest("DELETE", restUri);
    debugMode = (debugMode == null) ? true : false;
    request.setHeader("Accept",acceptType);
    if(headers.keys.length > 0) setHeaders(request,headers,debugMode);
    if(debugMode == true) logOut(request.fullUrl,request.getMethod(),content,contentType,acceptType);
    return execute(request,throwOnError,debugMode);
  }

  this.PATCH = function (restUri,acceptType,content,contentType,headers,throwOnError,debugMode){
    var request = this.restHost.createRequest("PATCH", restUri);
    debugMode = (debugMode == null) ? true : false;
    request.setHeader("Accept",acceptType);
    if(headers.keys.length > 0) setHeaders(request,headers,debugMode);
    if(debugMode == true) logOut(request.fullUrl,request.getMethod(),content,contentType,acceptType);
    return execute(request,throwOnError,debugMode);
  }

  this.PUT = function (restUri,acceptType,content,contentType,headers,throwOnError,debugMode){
    var request = this.restHost.createRequest("PUT", restUri);
    debugMode = (debugMode == null) ? true : false;
    request.setHeader("Accept",acceptType);
    if(headers.keys.length > 0) setHeaders(request,headers,debugMode);
    if(debugMode == true) logOut(request.fullUrl,request.getMethod(),content,contentType,acceptType);
    return execute(request,throwOnError,debugMode);
  }

  this.POST = function (restUri,acceptType,content,contentType,headers,throwOnError,debugMode){
    var request = this.restHost.createRequest("POST", restUri);
    debugMode = (debugMode == null) ? true : false;
    request.setHeader("Accept",acceptType);
    if(headers.keys.length > 0) setHeaders(request,headers,debugMode);
    if(debugMode == true) logOut(request.fullUrl,request.getMethod(),content,contentType,acceptType);
    return execute(request,throwOnError,debugMode);
  }
}

return RestCall;