trigger Create_Inventory_Trigger on Purchase_Order_Line_Item__c (before insert,before update,after insert,after update) {

    if(Trigger.isBefore){
        if(Trigger.isInsert){

            for(Purchase_Order_Line_Item__c item: Trigger.new){
                List<Purchase_Order_Line_Item__c> p = [SELECT Part_Number__c FROM Purchase_Order_Line_Item__c WHERE Part_Number__c = :item.Part_Number__c AND Purchase_Order__c = :item.Purchase_Order__c and Part_Number__r.non_inventory__c = False] ;
                System.debug(p);
                if( p.size() > 0 ){
                    item.addError('This product bellow to an existent PO');
                }
            }

        }

        if(Trigger.isUpdate){
            Map<Id,Purchase_Order_Line_Item__c> ListAfter = (Map<Id,Purchase_Order_Line_Item__c>)Trigger.oldMap;
            Purchase_Order_Line_Item__c POL;
            for(Purchase_Order_Line_Item__c item: Trigger.new){
                POL = ListAfter.get(item.Id);
                if(POL.Part_Number__c != null &&  POL.Warehouse__c != null && (POL.Part_Number__c != item.Part_Number__c || POL.Warehouse__c != item.Warehouse__c)){
                    item.addError('The product or warehouse cannot be changed');
                }
            }
        }
    }

    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
        Purchase_Order__c p;
        Purchase_Order_Line_Item__c pol;
        Map<String,String> values = new Map<String,String> {
            'N (normal)' => 'Received' , 
            'D (Direct Ship)' => 'Received' , 
            'R (Return)' => 'Returned' , 
            'Inventory Adjustment' => 'Adjust'
        };

        Set<Id> ids = Trigger.newMap.keySet();

        Map<Id,Purchase_Order_Line_Item__c> VerifyInvetory = new Map<Id,Purchase_Order_Line_Item__c> ([SELECT Id,Part_Number__r.non_inventory__c FROM Purchase_Order_Line_Item__c WHERE Id = :ids AND Part_Number__r.non_inventory__c = False]) ;

        for(Purchase_Order_Line_Item__c item: Trigger.new){
            pol = VerifyInvetory.get(item.id);
            if(pol != null){
                p = [Select Id,Status__c,Purchase_order_type__c FROM Purchase_Order__c WHERE Id = :item.Purchase_Order__c ];
                system.debug('Purchase Order:'+ p );
                if(item.Returned_Purchase_order_line_item__c != null){
                    ProductItem prodItem;
                    List<ProductItemTransaction> LID = [SELECT Purchase_order_line__c,Quantity,Actual_cost_per_item__c,ProductItemId FROM ProductItemTransaction WHERE Purchase_order_line__c = :item.Returned_Purchase_order_line_item__c  ORDER BY CreatedDate ASC];
                    Id POId ;

                    if(LID.size() > 0){POId = LID[0].id;}

                    if(POId != null && item.Quantity_Received__c > 0 && item.Status__c	== 'Returned'){
                        ProductItemTransaction Transac = new ProductItemTransaction();
                        Transac.Purchase_order_line__c = item.Id;
                        Transac.ProductItemId = LID[0].ProductItemId;
                        Transac.Actual_cost_per_item__c = LID[0].Actual_cost_per_item__c;
                        Transac.Quantity = -(item.Quantity_Received__c);
                        Transac.TransactionType = 'Adjusted';
                        insert Transac;  
                    }
            
                }else if(item.Part_Number__c != null && item.Warehouse__c!= null && (item.status__c == 'Partially Received' || item.status__c == 'Received')){
                    
                    ProductItemTransaction Transac;
                    ProductItem prodItem;
                    List<ProductItem> LPro = [SELECT Id,LocationId,Product2Id,QuantityOnHand FROM ProductItem WHERE LocationId = :item.Warehouse__c  AND Product2Id = :item.Part_Number__c ];

                    if(LPro.size() > 0){prodItem = LPro[0];}

                    if(prodItem == null){
                        
                        prodItem = new ProductItem ();
                        prodItem.Product2Id = item.Part_Number__c;
                        prodItem.QuantityOnHand = 0;//item.Quantity_Received__c;
                        prodItem.LocationId = item.Warehouse__c;
                        insert prodItem;

                        

                    }
                    List<ProductItemTransaction> LID = [SELECT Purchase_order_line__c,Quantity,Actual_cost_per_item__c FROM ProductItemTransaction WHERE Purchase_order_line__c = :item.Id  ORDER BY CreatedDate ASC];
                    Id POId ;
                    Product2 partUpdate = [SELECT Id,Quantity_On_hand__c FROM Product2 WHERE Id = :item.Part_Number__c];

                    if(LID.size() > 0){POId = LID[0].id;}

                    if(POId == null){
                        Transac = new ProductItemTransaction();
                        Transac.Purchase_order_line__c = item.Id;
                        Transac.ProductItemId = prodItem.Id;
                        Transac.Actual_cost_per_item__c = item.Actual_Cost__c;
                        Transac.Quantity = item.Quantity_Received__c;
                        System.debug(values.get(p.Purchase_order_type__c));
                        Transac.Cobalt_Status__c = values.get(p.Purchase_order_type__c);
                        System.debug(Transac.Cobalt_Status__c);
                        Transac.TransactionType = 'Adjusted';

                        partUpdate.Quantity_On_hand__c = partUpdate.Quantity_On_hand__c == null ? Transac.Quantity : partUpdate.Quantity_On_hand__c + Transac.Quantity;
                    }else{
                        if(LID[0].Quantity != item.Quantity_Received__c){
                            Transac = new ProductItemTransaction();
                            Transac.Purchase_order_line__c = item.Id;
                            Transac.ProductItemId = prodItem.Id;
                            Transac.Actual_cost_per_item__c = item.Actual_Cost__c;
                            Transac.Quantity = item.Quantity_Received__c - LID[0].Quantity;
                            Transac.TransactionType = 'Adjusted';

                            partUpdate.Quantity_On_hand__c = partUpdate.Quantity_On_hand__c == null ? Transac.Quantity : partUpdate.Quantity_On_hand__c + Transac.Quantity;

                        }
                    }

                    if(Transac != null)
                        insert Transac;
                    if(partUpdate != null)
                        update partUpdate;
                }

                if(item.status__c == 'Received' && item.part_required__c != null && item.Quantity_Received__c == item.Order_Qty__c){
                    ProductRequired partReq = [SELECT Id,Inventory_Status__c FROM ProductRequired WHERE Id = :item.part_required__c];
                    if(partReq.Inventory_Status__c != 'Commit'){
                        partReq.Inventory_Status__c= 'Commit';
                        update partReq;
                    }
                }

                if(p.Status__c != 'Received'){
                    List<Purchase_order_Line_Item__c> PurchaseLI = [Select Id,Status__c FROM Purchase_order_Line_Item__c WHERE Purchase_Order__c = :p.Id AND Status__c = 'Received'];
                    Integer count = 0;
                    for(Purchase_order_Line_Item__c it : PurchaseLI){
                        if(it.Status__c == 'Received'){
                            count ++;
                        }
                    }
        
                    if(PurchaseLI.size()>0 && PurchaseLI.size() == count){
                        p.Status__c = 'Received';
                        update p;
                    }
                }
            }
            

        }     

    }

    
}