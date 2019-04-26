/* This action returns the Configuration Element Attribute
* @Author Yattong Wu
* @version 1.0.0
* @date 16/04/19
* @param {string} categoryPath - The Cateogry path for Configuration Element.
* @param {string} configElementName - The Name of Configuration Element.
* @return {configElement} The configuration Element Object.
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

// get configElements
var configElementCategory = Server.getConfigurationElementCategoryWithPath(categoryPath);
var configElements = configElementCategory.allConfigurationElements;

// Find configElement
for each (i in configElements){
	if (i.name == configElementName){
		configElement = i;
		break;
	}
}

// Error handling
if (!configElement){
	throw "Could not find Configuration Element with Name : " + configElementName;
} else {
	log.debug("Found Configuration Element : " + configElement.name);
}

// return output

return configElement;

// just to make some damn changes for sync