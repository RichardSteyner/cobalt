({
    doInit: function(component,event,helper){
        var action = component.get("c.CreateWO");
        var Id = component.get("v.recordId");
        
        action.setParams({
            "Id": Id 
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();
            var response = response.getReturnValue();
            if(response != "Error"){
                component.set("v.message",response);
                component.set("v.loaded",true);
                console.log(response);
            }else{
                component.set("v.loaded",true);
                component.set("v.message",'Try in a few moments');
            }
        });

        $A.enqueueAction(action);
    }
})