trigger Reduce_Inventory_ProductConsumed_Trigger on ProductConsumed (before insert,after insert) {

    if(Trigger.isBefore){
        for(ProductConsumed pc : Trigger.new){

            List<ProductItemTransaction> ProItemT = [SELECT Id,Reduced_count_quantity__c,Actual_cost_per_item__c,ProductItem.Product2.non_inventory__c FROM ProductItemTransaction WHERE Quantity_and_Reduce_Check__c = true AND ProductItemId = :pc.ProductItemId AND Actual_cost_per_item__c != null order by CreatedDate desc limit 1];
            if(ProItemT.size() > 0){
                if(ProItemT[0].ProductItem.Product2.non_inventory__c == False){
                    pc.UnitPrice = ProItemT[0].Actual_cost_per_item__c;
                }
            }

        }
    }

    if(Trigger.isAfter){
        ProductItemTransaction  ProItemTAux;
        ProductItem  ProItem,ProItemAux;
        Product2 p,paux;

        Map<Id,ProductItemTransaction> MapItransac = new  Map<Id,ProductItemTransaction>();
        Map<Id,ProductItem> MapIt = new  Map<Id,ProductItem>();
        Map<Id,Product2> Mapp = new  Map<Id,Product2>();

        for(ProductConsumed pc : Trigger.new){
            system.debug('Consumed: ' + pc);
            ProductConsumed pcon = [SELECT Product2Id,Product2.non_inventory__c FROM ProductConsumed WHERE Id = :pc.Id];
            if(pcon.Product2.non_inventory__c == False){

                List<ProductItemTransaction> ProItemT = [SELECT Id,Reduced_count_quantity__c,Actual_cost_per_item__c FROM ProductItemTransaction WHERE  Quantity_and_Reduce_Check__c = true AND ProductItemId = :pc.ProductItemId order by CreatedDate desc limit 1];
                System.debug('Product ID: ' + pcon.Product2Id);
                System.debug('ProductItemTransaction: '+ ProItemT);

                if(ProItemT.size() > 0){
                    ProItemTAux = MapItransac.get(ProItemT[0].Id);
                    if(ProItemTAux == null){
                        ProItemTAux = ProItemT[0];
                    }
                    system.debug('Transact before: ' + ProItemTAux);

                    ProItemTAux.Reduced_count_quantity__c =  ProItemTAux.Reduced_count_quantity__c != null ? ProItemTAux.Reduced_count_quantity__c + pc.QuantityConsumed: pc.QuantityConsumed; 
                    ProItemTAux.Actual_cost_per_item__c =  pc.UnitPrice;
                    ProItemTAux.Cobalt_Status__c = 'Reduced';
                    system.debug('Transact after: ' + ProItemTAux);
                    MapItransac.put(ProItemTAux.Id,ProItemTAux);

                    ProItem = [SELECT Id,Quantity_Committed__c FROM ProductItem WHERE Id = :pc.ProductItemId];
                    ProItemAux = MapIt.get(ProItem.Id);
                    if(ProItemAux == null){
                        ProItemAux = ProItem;
                    }
                    system.debug('Transact before: ' + ProItemAux);
                    ProItemAux.Quantity_Committed__c = ProItemAux.Quantity_Committed__c != null ? ProItemAux.Quantity_Committed__c - pc.QuantityConsumed : pc.QuantityConsumed;
                    system.debug('Transact after: ' + ProItemAux);
                    MapIt.put(ProItemAux.id,ProItemAux);
                    
                    p = [SELECT Id,Quantity_On_hand__c,Quantity_Committed__c FROM  Product2 WHERE id = :pcon.Product2Id];
                    paux = Mapp.get(p.id);
                    if(paux == null){
                        paux = p;
                    }
                    System.debug('before: ' + paux);
                    paux.Quantity_On_hand__c = paux.Quantity_On_hand__c != null ? paux.Quantity_On_hand__c -pc.QuantityConsumed :  - (pc.QuantityConsumed);
                    paux.Quantity_Committed__c = paux.Quantity_Committed__c != null ? paux.Quantity_Committed__c -pc.QuantityConsumed :  - (pc.QuantityConsumed);
                    System.debug('after: ' + paux);
                    Mapp.put(paux.id,paux);
                }
                
            }
        } 

        if(MapItransac.size() > 0) update MapItransac.values();
        if(MapIt.size() > 0) update MapIt.values();
        if(Mapp.size() > 0) update Mapp.values();
    }
    

}