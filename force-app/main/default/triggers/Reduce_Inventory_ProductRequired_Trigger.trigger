trigger Reduce_Inventory_ProductRequired_Trigger on ProductRequired (before insert,after insert,after update) {
    if(Trigger.isBefore && Trigger.isInsert){
        Set<Id> PartIds = new Set<Id>();
        Set<Id> WOLIds = new Set<Id>();
        for(ProductRequired pr : Trigger.new){
            PartIds.add(pr.Product2Id);
            WOLIds.add(pr.ParentRecordId);
        }
        Map<Id,Product2> MapPro = new Map<Id,Product2>([SELECT Id,Unknown_Part__c FROM Product2 WHERE Id IN : PartIds]);
        Map<Id,Id> MapWOId = new Map<Id,Id> ();
        for(WorkOrderLineItem item : [SELECT Id,WorkOrderId FROM WorkOrderLineItem WHERE Id IN :WOLIds]){
            MapWOId.put(item.Id, item.WorkOrderId);
        }

        for(ProductRequired pr : Trigger.new){
            Id verifyObject = pr.ParentRecordId;
            if(verifyObject.getsobjecttype() == WorkOrderLineItem.sObjectType){
                pr.Work_Order__c = MapWOId.get(pr.ParentRecordId);
            }
            pr.Fake_Part__c = pr.Product2Id;
            if(MapPro.containsKey(pr.Product2Id)){
                if( MapPro.get(pr.Product2Id).Unknown_Part__c )
                    pr.Inventory_Status__c = 'Back Order';
            }
        }

    }

    if(Trigger.isAfter && Trigger.isInsert){
        Set<Id> PartIds = new Set<Id>();
        Set<Id> WOIds = new Set<Id>();
        Set<Id> WarehoseIds = new Set<Id>();
        
        Map<Id,WorkOrder> MapWorkOrderWithWarehouse = new Map<Id,WorkOrder>();
        Map<String,ProductItem> MapPartItem = new Map<String,ProductItem>();

        Product2 PartTemp;
        WorkOrder WorkOrderTemp;
        ProductItem PartItemTemp;
        String Key;

        List<Product2> UpdatePart = new List<Product2>();
        List<ProductItem> UpdatePartItem = new List<ProductItem>();
        
        for(ProductRequired pr : Trigger.new){
            Id verifyObject = pr.ParentRecordId;
            if(verifyObject.getsobjecttype() == WorkOrderLineItem.sObjectType && pr.QuantityRequired > 0){
                PartIds.add(pr.Product2Id);
                WOIds.add(pr.Work_Order__c);
            }
        }

        Map<Id,Product2> MapPart = new Map<Id,Product2>([SELECT Id,Quantity_Committed__c,QTY_Required__c FROM Product2 WHERE Id IN :PartIds]);

        for(WorkOrder WO : [SELECT Id,Warehouse__c  FROM WorkOrder WHERE Id IN : WOIds AND Warehouse__c != null]){
            MapWorkOrderWithWarehouse.put(WO.Id,WO);
            WarehoseIds.add(WO.Warehouse__c);
        }

        for(ProductItem PartItem : [SELECT Id,Quantity_Committed__c,LocationId,Product2Id FROM ProductItem WHERE LocationId IN :WarehoseIds  AND Product2Id IN :PartIds]){
            MapPartItem.put(String.valueOf(PartItem.LocationId) + String.valueOf(PartItem.Product2Id),PartItem);
        }

        for(ProductRequired pr : Trigger.new){
            Id verifyObject = pr.ParentRecordId;
            if(verifyObject.getsobjecttype() == WorkOrderLineItem.sObjectType && pr.QuantityRequired > 0){
                if(MapWorkOrderWithWarehouse.containsKey(pr.Work_Order__c)){
                    WorkOrderTemp = MapWorkOrderWithWarehouse.get(pr.Work_Order__c);
                    PartTemp = MapPart.get(pr.Product2Id);

                    Key = String.valueOf(WorkOrderTemp.Warehouse__c) + String.valueOf(PartTemp.Id);
                    if(MapPartItem.containsKey(Key)){
                        PartItemTemp = MapPartItem.get(Key);
                        
                        if( PartTemp.QTY_Required__c == null ) PartTemp.QTY_Required__c = 0;
                        PartTemp.QTY_Required__c += pr.QuantityRequired;

                        if(PartTemp.Quantity_Committed__c == null) PartTemp.Quantity_Committed__c = 0;

                        if(pr.Inventory_Status__c == 'Commit'){
                            PartTemp.Quantity_Committed__c += pr.QuantityRequired;
                        }

                        UpdatePart.add(PartTemp);
                        UpdatePartItem.add(PartItemTemp);

                    }else{
                        pr.adderror('There is no product item at WO location');
                    }
                   }else{
                    pr.adderror('Warehouse field must not be empty');
                }
            }
        }

        if(UpdatePart.size() > 0 ) update UpdatePart;
        if(UpdatePartItem.size() > 0 ) update UpdatePartItem;

    }

    if(Trigger.isAfter && Trigger.isUpdate){
        Set<Id> PartIds = new Set<Id>();
        Product2 PartTemp;
        
        for(ProductRequired pr : Trigger.new){
            Id verifyObject = pr.ParentRecordId;
            if(verifyObject.getsobjecttype() == WorkOrderLineItem.sObjectType && pr.QuantityRequired > 0){
                PartIds.add(pr.Product2Id);
            }
        }

        Map<Id,Product2> MapPart = new Map<Id,Product2>([SELECT Id,Quantity_Committed__c,QTY_Required__c FROM Product2 WHERE Id IN :PartIds]);

        for(ProductRequired pr : Trigger.new){
            Id verifyObject = pr.ParentRecordId;
            if(verifyObject.getsobjecttype() == WorkOrderLineItem.sObjectType && pr.QuantityRequired > 0){
                if(pr.Inventory_Status__c == 'Not Needed'){
                    if(MapPart.containsKey(pr.Product2Id)){
                        PartTemp = MapPart.get(pr.Product2Id);
                        if(PartTemp.QTY_Required__c == null) PartTemp.QTY_Required__c = 0;
                        PartTemp.QTY_Required__c -= pr.QuantityRequired;
                        MapPart.put(pr.Product2Id,PartTemp);
                    }
                }
            }
        }

        if(MapPart.size() > 0 ) update MapPart.values();
    }
    
    

}