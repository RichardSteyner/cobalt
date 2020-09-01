({
	init : function(component, event, helper) {
		var action = component.get("c.createPOandPOItems");
        action.setParams({"id": component.get("v.recordId")});
        
        action.setCallback(this, function(response){
            var state = response.getState();
            var responseValue = response.getReturnValue();
            if(component.isValid() && state == "SUCCESS"){
                component.set("v.message",responseValue);
                component.set("v.loaded",true);
                console.log(responseValue);
            }else{
                component.set("v.loaded",true);
                component.set("v.message",'Try in a few moments');
            }
        });
        
        $A.enqueueAction(action);
	}
})