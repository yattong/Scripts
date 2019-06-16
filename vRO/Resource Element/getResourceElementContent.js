/* This retuns the Resource Element Content
* @Author Yattong Wu
* @version 1.0.0
* @date 16/04/19
* @param {string} categoryPath - The Cateogry path for Resource Element.
* @param {string} resourceElementName - The Name of Resource Element.
* @return {resourceElementContent} The Resource Element Content Object.
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

// execute
try {
	log.debug("Getting content for resource element: " + resourceElementName);
	var resourceElementCategory = Server.getResourceElementCategoryWithPath(categoryPath);
	var resourceElement = System.getModule("com.vodafone.agilecloud.library.vro.resources").getResourceElement(categoryPath, resourceElementName);
    var resourceElementContent = resourceElement.getContentAsMimeAttachment().content;
    log.debug("debug","Found content for resource element: " + resourceElementName);
} catch (e) {
    throw "Failed to get content from resource element. " + e;
}

// return
return resourceElementContent;