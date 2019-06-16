/* This action creates or updates the Resource Element
* @Author Yattong Wu
* @version 1.0.0
* @date 24/04/19
* @param {Resource Element Category} resourceElementCategory - The Resource Element Category where the Resource Element should be created or updated.
* @param {string} resourceElementName - The Name of Resource Element.
* @param {string} content - Content of resource element.
* @param {string} mimeType - The MIME type that should be set on the created or updated Resource Element
* @return null;
*/

// Set Standard Logging
var objType = "Action";
var objName = "restCall"; // This must be set to the name of the action
var Logger = System.getModule("london.clouding.logging").standardisedLogger(objType,objName);
var log = new Logger(objType, objName);

// Start logging
log.debug("------ Starting " + objType + " : " + objName + " ------");

// check input params
if (!resourceElementCategory) {
    throw "The resource element category must be provided.";
}
if (!resourceElementName) {
    throw "The resource element name must be provided.";
}
if (!content) {
    throw "The resource element content must be provided.";
}

// Declare variables
var resourceElement = null;

// Create new MIME object
var mime = new MimeAttachment(elementName);
mime.content = content;
mime.mimeType = mimeType;

// Look for existing Resource Element
for each (element in resourceElementCategory.allResourceElements) {
	if (element.name == elementName) {
		resourceElement = element;
		break;
	}
}

// Create or update Resource Element
if (!resourceElement) {
	log.debug("Creating new Resource Element '" + elementName + "' in category '" + resourceElementCategory.path + "'");
	Server.createResourceElement(resourceElementCategory, elementName, mime, mimeType);
} else {
	log.debug("Updating existing Resource Element '" + elementName + "' in category '" + resourceElementCategory.path + "'");
	resourceElement.setContentFromMimeAttachment(mime);
}
