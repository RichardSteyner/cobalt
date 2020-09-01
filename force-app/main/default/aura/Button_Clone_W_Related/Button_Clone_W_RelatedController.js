({
    doInit: function(component,event,helper){
        var action = component.get("c.Clone_Estimate");
        var Id = component.get("v.recordId");
        
        action.setParams({
            "Id": Id 
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();
            var response = response.getReturnValue();
            if(response != "Error"){
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": response,
                    "slideDevName": "Detail"
                });
                navEvt.fire();
            }else{
                component.set("v.loaded",true);
                component.set("v.message",'Try in a few moments');
            }
        });

        $A.enqueueAction(action);
    }
})