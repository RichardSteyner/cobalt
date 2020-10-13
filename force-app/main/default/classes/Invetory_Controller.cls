public class Invetory_Controller {
    
    public static void VerifyProductPOInsert(List<Purchase_Order_Line_Item__c> POL){
        Set<Id> POIds = new Set<id>();
        for(Purchase_Order_Line_Item__c item: POL){
            POIds.add(item.Purchase_Order__c);
        }

        List<String> ProductsInPO = new List<String>();
        for(Purchase_Order_Line_Item__c p : [SELECT Id,Part_Number__c,Purchase_Order__c  FROM Purchase_Order_Line_Item__c WHERE Purchase_Order__c IN :POIds]){
            ProductsInPO.add(p.Purchase_Order__c + String.valueOf(p.Part_Number__c));
        }

        for(Purchase_Order_Line_Item__c item: POL){            
            if( ProductsInPO.contains(item.Purchase_Order__c + String.valueOf(item.Part_Number__c)) ){
                item.addError('This product bellow to an existent PO');
            }
        }
    }
    
    public static void VerifyProductPOUpdate(List<Purchase_Order_Line_Item__c> POL,Map<Id,Purchase_Order_Line_Item__c> POLOld){
        Purchase_Order_Line_Item__c POLTemp;
        for(Purchase_Order_Line_Item__c item: POL){
            POLTemp = POLOld.get(item.Id);
            if(POLTemp.Part_Number__c != null &&  POLTemp.Warehouse__c != null && (POLTemp.Part_Number__c != item.Part_Number__c || POLTemp.Warehouse__c != item.Warehouse__c)){
                item.addError('The product or warehouse cannot be changed');
            }
        }
    }

    public static void CreateInventory(Map<Id,Purchase_Order_Line_Item__c> MapPOLNew,Map<Id,Purchase_Order_Line_Item__c> MapPOLOld){
        Purchase_Order__c POTemp;
        Purchase_Order_Line_Item__c POLTemp;
        ProductItem PartItemTemp;
        Product2 PartTemp;
        ProductRequired PartRequiredTemp;
        ProductItemTransaction PartTransactTemp,TransacAux;
        List<Purchase_Order_Line_Item__c> LineItemTemp;
        Map<String,String> values = new Map<String,String> {
            'N (normal)' => 'Received' , 
            'D (Direct Ship)' => 'Received' , 
            'R (Return)' => 'Returned' , 
            'Inventory Adjustment' => 'Adjust'
        };

        List<Id> POIds = new List<Id>();
        List<Id> POReturnedIds = new List<Id>();
        List<Id> WarehouseIds = new List<Id>();
        List<Id> PartIds = new List<Id>();
        List<Id> PartRequiredIds = new List<Id>();        
        Map<String,Purchase_Order__c> MapPO = new Map<String,Purchase_Order__c>();
        Map<String,ProductItemTransaction> MapPartTransactionReturned = new Map<String,ProductItemTransaction>();
        Map<Id,ProductItemTransaction> MapPartTransaction = new Map<Id,ProductItemTransaction>();        
        Map<String,ProductItem> MapPartItem = new Map<String,ProductItem>();
        Map<Id,List<Purchase_Order_Line_Item__c>> MapPOLineItem = new Map<Id,List<Purchase_Order_Line_Item__c>> ();
        List<ProductItemTransaction> ListTemp;

        Map<String,ProductItem> MapPartItemInsert = new Map<String,ProductItem>();
        Map<String,List<ProductItemTransaction>> MapTransactGroup = new Map<String,List<ProductItemTransaction>>();
        List<ProductItemTransaction> TransactInsert = new List<ProductItemTransaction>();
        List<ProductRequired> UpdatePartRequired = new List<ProductRequired>();
        List<Purchase_Order__c> UpdatePO = new List<Purchase_Order__c>();
        Decimal BackOrderOld,BackOrderCurrent;
        
        for(Purchase_Order_Line_Item__c item : MapPOLNew.values()){
            POIds.add(item.Purchase_Order__c);
            POReturnedIds.add(item.Returned_Purchase_order_line_item__c);
            WarehouseIds.add(item.Warehouse__c);
            PartIds.add(item.Part_Number__c);
            PartRequiredIds.add(item.part_required__c);
        }
        
        Map<Id,Product2> MapPart = new Map<Id,Product2> ([SELECT Id,Quantity_On_hand__c,QTY_on_Order__c,QTY_Back_Ordered__c FROM Product2 WHERE Id IN :PartIds ]);
        for(Purchase_Order__c p : [SELECT Id,Status__c,Purchase_order_type__c FROM Purchase_Order__c WHERE Id IN :POIds ]){
            MapPO.put(p.Id,p);
        }

        for(ProductItemTransaction PartTransac : [SELECT Purchase_order_line__c,Quantity,Actual_cost_per_item__c,ProductItemId,ProductItem.Product2Id,ProductItem.LocationId FROM ProductItemTransaction WHERE Purchase_order_line__c IN :POReturnedIds ORDER BY CreatedDate ASC]){
            if(!MapPartTransactionReturned.containsKey(PartTransac.Purchase_order_line__c))
                MapPartTransactionReturned.put(PartTransac.Purchase_order_line__c,PartTransac);
        }

        for(ProductItem PartItem : [SELECT Id,LocationId,Product2Id,QuantityOnHand FROM ProductItem WHERE LocationId IN :WarehouseIds AND Product2Id IN :PartIds ]){
            MapPartItem.put(String.valueOf(PartItem.LocationId) + String.valueOf(PartItem.Product2Id),PartItem);
        }

        for(ProductItemTransaction PartTransac : [SELECT Purchase_order_line__c,Quantity,Actual_cost_per_item__c,ProductItemId,ProductItem.Product2Id,ProductItem.LocationId FROM ProductItemTransaction WHERE Purchase_order_line__c IN :MapPOLNew.keySet()  ORDER BY CreatedDate ASC]){
            if(!MapPartTransaction.containsKey(PartTransac.Purchase_order_line__c))
                MapPartTransaction.put(PartTransac.Purchase_order_line__c,PartTransac);
            System.debug('Line Item: ' +PartTransac.Purchase_order_line__c);
        }

        Map<Id,ProductRequired> MapPartRequired = new Map<Id,ProductRequired> ([SELECT Id,Inventory_Status__c FROM ProductRequired WHERE Id IN :PartRequiredIds]);

        for(Purchase_order_Line_Item__c LineItem : [SELECT Id,Status__c,Purchase_Order__c FROM Purchase_order_Line_Item__c WHERE Purchase_Order__c IN :POIds]){
            if(!MapPOLineItem.containsKey(LineItem.Purchase_Order__c)){
                LineItemTemp = new List<Purchase_Order_Line_Item__c>();
            }else{ 
                LineItemTemp = MapPOLineItem.get(LineItem.Purchase_Order__c);
            }            
            LineItemTemp.add(LineItem);
            MapPOLineItem.put(LineItem.Purchase_Order__c,LineItemTemp);
        }
        
        for(Purchase_Order_Line_Item__c item: MapPOLNew.values()){

            if(MapPO.containsKey(item.Purchase_Order__c)){

                if(MapPOLOld != null){
                    if(MapPOLOld.containsKey(item.Id)){
                        BackOrderOld = MapPOLOld.get(item.Id).Order_Qty__c - MapPOLOld.get(item.Id).Quantity_Received__c;
                    }else{
                        BackOrderOld = 0;
                    }
                }else{
                    BackOrderOld = 0;
                }
                BackOrderCurrent = item.Order_Qty__c - item.Quantity_Received__c;

                POTemp = MapPO.get(item.Purchase_Order__c);
                if( item.Returned_Purchase_order_line_item__c != null 
                    && MapPartTransactionReturned.containsKey(item.Returned_Purchase_order_line_item__c) 
                    && item.Quantity_Received__c > 0 && item.Status__c	== 'Returned'){

                        String Key = String.valueOf(PartTransactTemp.ProductItem.LocationId) + String.valueOf(PartTransactTemp.ProductItem.Product2Id);
                        PartTransactTemp = MapPartTransactionReturned.get(item.Returned_Purchase_order_line_item__c);

                        TransacAux = new ProductItemTransaction();
                        TransacAux.Purchase_order_line__c = item.Id;
                        TransacAux.ProductItemId = PartTransactTemp.ProductItemId;
                        TransacAux.Actual_cost_per_item__c = PartTransactTemp.Actual_cost_per_item__c;
                        TransacAux.Quantity = -(item.Quantity_Received__c);
                        TransacAux.TransactionType = 'Adjusted';

                        if(MapTransactGroup.containsKey(Key)){
                            ListTemp = MapTransactGroup.get(Key);
                        }else{
                            ListTemp = new List<ProductItemTransaction>();
                        }

                        ListTemp.add(TransacAux);
                        MapTransactGroup.put(Key,ListTemp);

                }else if(item.Part_Number__c != null && item.Warehouse__c!= null && (item.status__c == 'Partially Received' || item.status__c == 'Received')){

                    String Key = String.valueOf(item.Warehouse__c) + String.valueOf(item.Part_Number__c);
                    if(MapTransactGroup.containsKey(Key)){
                        ListTemp = MapTransactGroup.get(Key);
                    }else{
                        ListTemp = new List<ProductItemTransaction>();
                    }

                    System.debug('MapPartItem:' + MapPartItem.containsKey(Key));
                    if(MapPartItem.containsKey(Key)){
                        PartItemTemp = MapPartItem.get(Key);
                    }else{
                        PartItemTemp = new ProductItem ();
                        PartItemTemp.Product2Id = item.Part_Number__c;
                        PartItemTemp.QuantityOnHand = 0;
                        PartItemTemp.LocationId = item.Warehouse__c;
                        MapPartItemInsert.put(Key,PartItemTemp);
                    }

                    PartTemp = MapPart.get(item.Part_Number__c);
                    System.debug('Line Item Item: ' +item.Id);
                    System.debug('MapPartTransaction: ' + MapPartTransaction.containsKey(item.Id));

                    if(MapPartTransaction.containsKey(item.Id)){
                        POLTemp = MapPOLOld.get(item.id);
                        System.debug('old: ' + POLTemp.Quantity_Received__c + 'new: ' + item.Quantity_Received__c);
                        if( POLTemp.Quantity_Received__c != item.Quantity_Received__c){
                            TransacAux = new ProductItemTransaction();
                            TransacAux.Purchase_order_line__c = item.Id;
                            TransacAux.ProductItemId = MapPartTransaction.get(item.Id).ProductItemId;
                            TransacAux.Actual_cost_per_item__c = item.Actual_Cost__c;
                            TransacAux.Quantity = item.Quantity_Received__c - POLTemp.Quantity_Received__c;
                            TransacAux.TransactionType = 'Adjusted';
                            ListTemp.add(TransacAux);

                            if(PartTemp.Quantity_On_hand__c == null) PartTemp.Quantity_On_hand__c = 0;
                            PartTemp.Quantity_On_hand__c += TransacAux.Quantity;

                            if(PartTemp.QTY_on_Order__c == null) PartTemp.QTY_on_Order__c = 0;
                            PartTemp.QTY_on_Order__c -= TransacAux.Quantity;
                        }
                    }else{
                        TransacAux = new ProductItemTransaction();
                        TransacAux.Purchase_order_line__c = item.Id;
                        if(MapPartItem.containsKey(Key)){
                            TransacAux.ProductItemId = PartItemTemp.Id;
                        }
                        TransacAux.Actual_cost_per_item__c = item.Actual_Cost__c;
                        TransacAux.Quantity = item.Quantity_Received__c;
                        System.debug(values.get(POTemp.Purchase_order_type__c));
                        TransacAux.Cobalt_Status__c = values.get(POTemp.Purchase_order_type__c);
                        System.debug(TransacAux.Cobalt_Status__c);
                        TransacAux.TransactionType = 'Adjusted';

                        ListTemp.add(TransacAux);

                        if(PartTemp.Quantity_On_hand__c == null) PartTemp.Quantity_On_hand__c = 0;
                        PartTemp.Quantity_On_hand__c += TransacAux.Quantity;

                        if(PartTemp.QTY_on_Order__c == null) PartTemp.QTY_on_Order__c = 0;
                        System.debug('Before QTY_on_Order__c:' + PartTemp.QTY_on_Order__c);
                        PartTemp.QTY_on_Order__c += item.Order_Qty__c - TransacAux.Quantity;
                        System.debug('After QTY_on_Order__c:' + PartTemp.QTY_on_Order__c);
                    }
                    if(PartTemp.QTY_Back_Ordered__c == null) PartTemp.QTY_Back_Ordered__c = 0;
                    if(item.status__c == 'Partially Received'){                       
                        PartTemp.QTY_Back_Ordered__c += BackOrderCurrent - BackOrderOld;
                    }

                    if(item.status__c == 'Received'){                        
                        PartTemp.QTY_Back_Ordered__c -= BackOrderOld;
                    }

                    MapPart.put(item.Part_Number__c,PartTemp);
                    MapTransactGroup.put(Key,ListTemp);
                }

                if( item.Part_Number__c != null && item.status__c == 'Back Order'){
                    PartTemp = MapPart.get(item.Part_Number__c);
                    if(PartTemp.QTY_Back_Ordered__c == null) PartTemp.QTY_Back_Ordered__c = 0;
                    PartTemp.QTY_Back_Ordered__c += BackOrderCurrent - BackOrderOld;
                    MapPart.put(item.Part_Number__c,PartTemp);
                }

                if(item.status__c == 'Received' && item.part_required__c != null && item.Quantity_Received__c == item.Order_Qty__c){
                    if(MapPartRequired.containsKey(item.part_required__c)){
                        PartRequiredTemp = MapPartRequired.get(item.part_required__c);
                        if(PartRequiredTemp.Inventory_Status__c != 'Commit'){
                            PartRequiredTemp.Inventory_Status__c = 'Commit';
                            UpdatePartRequired.add(PartRequiredTemp);
                        }
                    }
                }

                if(POTemp.Status__c != 'Received'){
                    LineItemTemp = MapPOLineItem.get(POTemp.Id);
                    Integer count = 0;
                    for(Purchase_order_Line_Item__c it : LineItemTemp){
                        if(it.Status__c == 'Received'){
                            count ++;
                        }
                    }
        
                    if(LineItemTemp.size()>0 && LineItemTemp.size() == count){
                        POTemp.Status__c = 'Received';
                        UpdatePO.add(POTemp);
                    }
                }
            }
        }

        

        System.debug('MapPartItemInsert: ' +MapPartItemInsert.values());
        System.debug('MapTransactGroup: ' +MapTransactGroup.values());
        if(MapPartItemInsert.size() > 0){
            insert MapPartItemInsert.values();        
        }
        if(MapTransactGroup.size() > 0){
            for(String key : MapTransactGroup.keySet()){
                for(ProductItemTransaction ItemTransac : MapTransactGroup.get(key)){
                    if(MapPartItemInsert.containsKey(key)){     
                        if(ItemTransac.ProductItemId == null)                       
                            ItemTransac.ProductItemId = MapPartItemInsert.get(key).Id;
                    }
                    TransactInsert.add(ItemTransac);
                }
            }
        }
        System.debug('TransactInsert: ' + TransactInsert);
        if(TransactInsert.size() > 0) insert TransactInsert;
        if(MapPart.size() > 0) update MapPart.values();
        if(UpdatePartRequired.size() > 0) update UpdatePartRequired;
        if(UpdatePO.size() > 0) update UpdatePO;

    }

}