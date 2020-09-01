trigger Reduce_Inventory_ProductRequired_Trigger on ProductRequired (after insert) {

    WorkOrder wo; 
    Product2 Pro;
    ProductItem ProItem;
    List<ProductItem> ListProItem;

    for(ProductRequired pr : Trigger.new){
        Id verifyObject = pr.ParentRecordId;
        if(verifyObject.getsobjecttype() == WorkOrderLineItem.sObjectType && pr.QuantityRequired > 0){
            Pro = [SELECT Id,Quantity_Committed__c,non_inventory__c FROM Product2 WHERE Id = :pr.Product2Id];
            if(Pro.non_inventory__c == False){
                wo = [SELECT Warehouse__c  FROM WorkOrder WHERE Id = : pr.Work_Order__c];
                Pro.Quantity_Committed__c = Pro.Quantity_Committed__c != null? Pro.Quantity_Committed__c + pr.QuantityRequired : pr.QuantityRequired;
            
                System.debug('Ware: ' + wo.Warehouse__c);
                System.debug('p2: ' + pr.Product2Id);
                if(wo.Warehouse__c != null){
                    
                    ListProItem = [SELECT Id,Quantity_Committed__c FROM ProductItem WHERE LocationId = :wo.Warehouse__c  AND Product2Id = :pr.Product2Id];
                    ProItem = ListProItem.size()>0 ? ListProItem[0] : null;

                    if(ProItem != null){
                        ProItem.Quantity_Committed__c = ProItem.Quantity_Committed__c != null? ProItem.Quantity_Committed__c + pr.QuantityRequired : pr.QuantityRequired;
                        update Pro;
                        update ProItem;
                    }else{
                        pr.adderror('There is no product item at WO location');
                    }
                }else{
                    pr.adderror('Warehouse field must not be empty');
                }
            }          
           
        }
    }


}