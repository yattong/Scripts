/* This creates a Logout object class that can be used to standardise the log output in workflows.
* @Author Yattong Wu
* @Date 18 April 2019 
* @param {string} objType - The component type i.e. Action or Workflow.
* @param {string} objName - The Action or Workflow name.
* @return {Any} The Logout object.
*/

function Logout() {
	this.type = objType; 
	this.name = objName;
	this.log = function (lMessage){		
		System.log("[" + this.type + " : " + this.name + "] " + lMessage);
	}
	this.error = function (eMessage, exception){		
		System.error("[" + this.type + " : " + this.name + "] " + eMessage);
		if (exception) {
			throw "[" + this.type + " : " + this.name + "] " + eMessage + " " + exception;
		} else {
			throw eMessage;
		}
	}
	this.debug = function (dMessage){		
		System.debug("[" + this.type + " : " + this.name +"] " + dMessage);
	}
	this.warn = function (wMessage){		
		System.warn("[" + this.type + " : " + this.name + "] " + wMessage);
	}
}

return Logout