trigger Reduce_Inventory_ProductConsumed_Trigger on ProductConsumed (before insert,after insert) {

    if(Trigger.isBefore){
        Set<Id> PartitemIds = new Set<Id>();
        Map<Id,ProductItemTransaction> MapTransact= new Map<Id,ProductItemTransaction>();
        for(ProductConsumed pc : Trigger.new){
            PartitemIds.add(pc.ProductItemId);
        }
        for(ProductItemTransaction item : [SELECT Id,Reduced_count_quantity__c,Actual_cost_per_item__c,ProductItemId FROM ProductItemTransaction WHERE Quantity_and_Reduce_Check__c = true AND ProductItemId IN :PartitemIds AND Actual_cost_per_item__c != null ORDER BY CreatedDate DESC ]){
            if(!MapTransact.containsKey(item.ProductItemId))
                MapTransact.put(item.ProductItemId,item);
        }

        for(ProductConsumed pc : Trigger.new){
            if(MapTransact.containsKey(pc.ProductItemId)){
                pc.UnitPrice = MapTransact.get(pc.ProductItemId).Actual_cost_per_item__c;
            }
        }
    }

    if(Trigger.isAfter){
        /*ProductItemTransaction  ProItemTAux;
        ProductItem  ProItem,ProItemAux;
        Product2 p,paux;
        Map<Id,ProductItemTransaction> MapItransac = new  Map<Id,ProductItemTransaction>();
        Map<Id,ProductItem> MapIt = new  Map<Id,ProductItem>();
        Map<Id,Product2> Mapp = new  Map<Id,Product2>();*/


        Set<Id> PartItemIds = new Set<Id>();
        Set<Id> WOLineIds = new Set<Id>();
        Set<Id> partIds = new Set<Id>();
        Map<Id,ProductItemTransaction> MapPartTransaction = new Map<Id,ProductItemTransaction>();
        Map<Id,ProductItem> MapPartItem = new Map<Id,ProductItem>();
        ProductItem PartItemTemp;
        ProductItemTransaction PartTransactTemp;
        Product2 PartTemp;
        ProductRequired PartRequiredTemp;
        for(ProductConsumed pc : Trigger.new){
            PartItemIds.add(pc.ProductItemId);
            WOLineIds.add(pc.WorkOrderLineItemId);
        }

        for(ProductItemTransaction  ItemTransac : [SELECT Id,Reduced_count_quantity__c,Actual_cost_per_item__c,ProductItemId  FROM ProductItemTransaction WHERE  Quantity_and_Reduce_Check__c = true AND ProductItemId IN :PartItemIds ORDER BY CreatedDate DESC]){
            if(!MapPartTransaction.containsKey(ItemTransac.ProductItemId)){
                MapPartTransaction.put(ItemTransac.ProductItemId,ItemTransac);
            }
        }

        for(ProductItem item : [SELECT Id,Quantity_Committed__c,Product2Id FROM ProductItem WHERE Id IN :PartItemIds]){
            MapPartItem.put(item.Id,item);
            partIds.add(item.Product2Id);
        }
        Map<Id,Product2> MapPart = new Map<Id,Product2>([SELECT Id,Quantity_On_hand__c,Quantity_Committed__c,QTY_Required__c FROM  Product2 WHERE id IN :partIds]);

        Map<Id,ProductRequired> MapPartRequired = new Map<Id,ProductRequired>();

        for(ProductRequired pr : [SELECT Id,Product2Id FROM ProductRequired WHERE ParentRecordId IN :WOLineIds AND Product2Id IN:partIds]){
            MapPartRequired.put(pr.Product2Id,pr);
        }

        for(ProductConsumed pc : Trigger.new){
            if(MapPartTransaction.containsKey(pc.ProductItemId)){
                PartTransactTemp = MapPartTransaction.get(pc.ProductItemId);

                system.debug('Transact before: ' + PartTransactTemp);
                PartTransactTemp.Reduced_count_quantity__c =  PartTransactTemp.Reduced_count_quantity__c != null ? PartTransactTemp.Reduced_count_quantity__c + pc.QuantityConsumed: pc.QuantityConsumed; 
                PartTransactTemp.Actual_cost_per_item__c =  pc.UnitPrice;
                PartTransactTemp.Cobalt_Status__c = 'Reduced';
                system.debug('Transact after: ' + PartTransactTemp);

                MapPartTransaction.put(pc.ProductItemId,PartTransactTemp);
                PartItemTemp = MapPartItem.get(pc.ProductItemId);
                system.debug('Transact before: ' + PartItemTemp);
                PartItemTemp.Quantity_Committed__c = PartItemTemp.Quantity_Committed__c != null ? PartItemTemp.Quantity_Committed__c - pc.QuantityConsumed : pc.QuantityConsumed;
                system.debug('Transact after: ' + PartItemTemp);
                MapPartItem.put(pc.ProductItemId,PartItemTemp);

                PartTemp = MapPart.get(PartItemTemp.Product2Id);

                PartTemp.Quantity_On_hand__c = PartTemp.Quantity_On_hand__c != null ? PartTemp.Quantity_On_hand__c -pc.QuantityConsumed :  - (pc.QuantityConsumed);
                //PartTemp.Quantity_Committed__c = PartTemp.Quantity_Committed__c != null ? PartTemp.Quantity_Committed__c -pc.QuantityConsumed :  - (pc.QuantityConsumed);
                
                if(PartTemp.QTY_Required__c == null ) PartTemp.QTY_Required__c = 0;
                if(PartTemp.Quantity_Committed__c == null ) PartTemp.Quantity_Committed__c = 0;

                if(MapPartRequired.containsKey(PartTemp.Id)){
                    PartTemp.Quantity_Committed__c -= pc.QuantityConsumed;
                    PartTemp.QTY_Required__c -= pc.QuantityConsumed;
                }
                


                MapPart.put(PartItemTemp.Product2Id,PartTemp);
            }
        }


        if(MapPartTransaction.size() > 0) update MapPartTransaction.values();
        if(MapPartItem.size() > 0) update MapPartItem.values();
        if(MapPart.size() > 0) update MapPart.values();

        /*for(ProductConsumed pc : Trigger.new){
            system.debug('Consumed: ' + pc);

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
                
                p = [SELECT Id,Quantity_On_hand__c,Quantity_Committed__c,QTY_Required__c FROM  Product2 WHERE id = :pcon.Product2Id];
                paux = Mapp.get(p.id);
                if(paux == null){
                    paux = p;
                }
                System.debug('before: ' + paux);
                paux.Quantity_On_hand__c = paux.Quantity_On_hand__c != null ? paux.Quantity_On_hand__c -pc.QuantityConsumed :  - (pc.QuantityConsumed);
                paux.Quantity_Committed__c = paux.Quantity_Committed__c != null ? paux.Quantity_Committed__c -pc.QuantityConsumed :  - (pc.QuantityConsumed);
                if(paux.QTY_Required__c == null ) paux.QTY_Required__c = 0;
                paux.QTY_Required__c += pc.QuantityConsumed;
                System.debug('after: ' + paux);
                Mapp.put(paux.id,paux);
            }
        } 

        if(MapItransac.size() > 0) update MapItransac.values();
        if(MapIt.size() > 0) update MapIt.values();
        if(Mapp.size() > 0) update Mapp.values();*/
    }
    

}