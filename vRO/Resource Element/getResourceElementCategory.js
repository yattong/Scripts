/* This retuns the Resource Element Category
* @Author Yattong Wu
* @version 1.0.0
* @date 16/04/19
* @param {string} categoryPath - The Cateogry path for Resource Element.
* @return {resourceElementCategory} The Resource Element Category Object.
*/

// Set Standard Logging
var objType = "Action";
var objName = "getResourceElementCategory"; // This must be set to the name of the action
var Logger = System.getModule("com.vodafone.agilecloud.library.util").logout(objType, objName);
var log = new Logger(objType, objName);
// Start logging
log.debug("------ Starting " + objName + " ------");

// check input params
if (!categorypath) {
    throw "The resource element category path must be provided.";
}

// execute
try {
	log.debug("Getting resource element category from path: " + categoryPath);
	var resourceElementCategory = Server.getResourceElementCategoryWithPath(categoryPath);
	if (resourceElementCategory) {
	    categoryName = resourceElementCategory.name;
	    log.debug("Found resource element category: " + categoryName);
	} else {
	    throw "Resource element category was not found.";
	}
} catch (e) {
    log.debug("Failed to get resource element category from provided path.", e);
}

// return
return resourceElementCategory;