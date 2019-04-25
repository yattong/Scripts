/* This action creates a Configuration Element Attribute
* @Author Yattong Wu
* @version 1.0.0
* @date 25/04/19
* @param {string} categoryPath - The Cateogry path for Configuration Element.
* @param {string} configElementName - The Name of Configuration Element.
* @param {string} attributeName - The name of the configuratoin element attribute.
* @param {any} objectType - The Type of object to create the configuration element attri
*/

// Set Standard Logging
var objType = "Action";
var objName = "createConfigElementAttribute"; // This must be set to the name of the action
var Logger = System.getModule("com.vodafone.agilecloud.library.util").logout(objType, objName);  //change Path
var log = new Logger(objType, objName);
// Start logging
log.debug("------ Starting " + objName + " ------");

// check input params
if (!categoryPath) {
	throw "The configuration element category path must be provided.";
}
if (!configElementName) {
	throw "The configuration element name must be provided.";
}
if (!attributeName) {
	throw "The configuration element attribute name must be provided.";
}

// get configElement
var configElement = System.getModule("com.vodafone.agilecloud.library.util").getConfigElement(categoryPath, configElementName);  //change Path

// Get Config Element Attribute
configElement.setAttributeWithKey(attributeName, objectType);

// validate config Element attribute created / updated
var attribute = System.getModule("com.vodafone.agilecloud.library.util").getConfigElementAttribute(categoryPath, configElementName, attributeName)

if (attribute.value == objectType){
	log.log("Configuration Element Attribute : " + attribute.name + " was created/updated successfully.");
} else {
	throw "Configuration Element Attribute : " + attribute.name + " creation/update failed."
}
