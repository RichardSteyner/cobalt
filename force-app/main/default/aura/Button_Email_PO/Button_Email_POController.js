({
    doInit: function(component,event,helper){
        var action = component.get("c.send_email_template_PO");
        var Id = component.get("v.recordId");
        
        action.setParams({
            "Id": Id 
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();
            component.set("v.loaded",true);
            component.set("v.message",response.getReturnValue());
            
            $A.get('e.force:refreshView').fire();
        });

        $A.enqueueAction(action);
    }
})