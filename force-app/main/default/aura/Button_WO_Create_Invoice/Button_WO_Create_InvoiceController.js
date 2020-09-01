({
    doInit: function(component,event,helper){
        var action = component.get("c.Verify");
        var Id = component.get("v.recordId");
        
        action.setParams({
            "Id": Id 
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();
            var response = response.getReturnValue();
            if(response != "Error"){

                if(response.length > 0){
                    component.set("v.message",response);
                    component.set("v.loaded",true);
                    console.log('Error'+response);
                    component.set("v.flag",false);
                }else{
                    component.set("v.loaded",true);
                    component.set("v.flag",true);
                    console.log('No error'+response);
                }

            }else{
                component.set("v.loaded",true);
                component.set("v.message",'Try in a few moments');
            }
        });

        $A.enqueueAction(action);
    },
    ClickSave: function(component,event,helper){
        var action = component.get("c.CreateInvoice");
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
                component.set("v.flag",false);
                console.log(response);                

            }else{
                component.set("v.loaded",true);
                component.set("v.flag",false);
                component.set("v.message",'Try in a few moments');
            }
        });

        $A.enqueueAction(action);
    }
})