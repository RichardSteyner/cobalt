trigger InvoiceTrigger on Invoice__c (after insert, after update) {
    
    Set<Id> invIds = new Set<Id>();
    
    if(Trigger.IsInsert) {
    	for(Invoice__c invoice : Trigger.New){
    		if(invoice.Sold_To_Customer__c!=null){
                invIds.add(invoice.Id);
				System.debug('InvoiceTrigger->' + invoice.Id);
            }
        }
    
        Map<Id, Invoice__c> mapInvoices = new Map<Id, Invoice__c>();
        
        for(Invoice__c inv : [select Id, Sold_To_Customer__c, Sold_To_Customer__r.State_Tax_Code__c from Invoice__c where Sold_To_Customer__c!=null and Id in: invIds]){
            mapInvoices.put(inv.Id, inv);
        }
        
        for(Invoice__c inv : mapInvoices.values()){
            inv.State_Tax_Code__c = inv.Sold_To_Customer__r.State_Tax_Code__c;
        }
        
        if(mapInvoices.values().size()>0){
            //Since this trigger will only be executed when creating, there is no need for a variable to control when this trigger is called.
            update mapInvoices.values();
        }
    }else{
        
    }

}