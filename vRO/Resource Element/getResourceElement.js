/* This action returns the Resource Element
* @Author Yattong Wu
* @version 1.0.0
* @date 16/04/19
* @param {string} categoryPath - The Cateogry path for Resource Element.
* @param {string} resourceElementName - The Name of Resource Element.
* @return {resourceElement} The Resource Element Object.
*/

// Set Standard Logging
var objType = "Action";
var objName = "restCall"; // This must be set to the name of the action
var Logger = System.getModule("london.clouding.logging").standardisedLogger(objType,objName);
var log = new Logger(objType, objName);

// Start logging
log.debug("------ Starting " + objType + " : " + objName + " ------");

// check input params
if (!categorypath) {
    throw "The resource element category path must be provided.";
}
if (!resourceElementName) {
    throw "The resource element name must be provided.";
}

// Declare Variables
var resourceElement;
var resourceElementCategory;
var resourceElements = [];

// execute
try {
	log.debug("Getting resource element '" + resourceElementName + " from path '" + categoryPath);
	resourceElementCategory = System.getModule("com.vodafone.agilecloud.library.vro.resources").getResourceElementCategory(categoryPath);  //change path
    resourceElements = resourceElementCategory.allResourceElements.filter(function(x){return x.name === resourceElementName;})
    if (resourceElements.length > 0) {
        resourceElement = resourceElements[0];
    } else {
        throw "Could not find a resource element with name '" + resourceElementName + "' " + " in path '" + categoryPath + "'";
    }
    log.debug("Found resource element '" + resourceElementName + "'");
} catch (e) {
    throw "Failed to get resource element from provided path. " + e;
}

return resourceElement;
