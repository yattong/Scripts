/* This action returns the Configuration Element Attribute
* @Author Yattong Wu
* @version 1.0.0
* @date 16/04/19
* @param {string} categoryPath - The Cateogry path for Configuration Element.
* @param {string} configElementName - The Name of Configuration Element.
* @param {string} attributeName - The name of the configuratoin element attribute.
* @return {attribute.value} The configuration Element Attribute Value.
*/

// Set Standard Logging
var objType = "Action";
var objName = "getConfigElementAttribute"; // This must be set to the name of the action
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
var attribute = configElement.getAttributeWithKey(attributeName);

// Error handling
if (!attribute){
	throw "Could not find Configuration Element Attribute with Name : " + attributeName;
} else {
	log.debug("Found Configuration Element Attribute : " + attribute.name);
}

// return output
return attribute.value;

// just to make some damn changes for sync