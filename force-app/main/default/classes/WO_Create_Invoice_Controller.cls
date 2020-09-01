public with sharing class WO_Create_Invoice_Controller {
    @AuraEnabled
    public static List<String> CreateInvoice(String Id){
        List<String> retunrvalues = new List<String>();
        WorkOrder WO;
        Map<Id,WorkOrderLineItem> ListItems;
        List<ProductConsumed> ListProCons;
        List<ProductRequired> ListProReq;
        List<Invoice_line_item__c> ListInvLine = new List<Invoice_line_item__c>();

        Invoice_line_item__c InvLine;
        WorkOrderLineItem WOL;
        Invoice__c Inv;

        Map<String,ProductRequired> MapProdReq = new Map<String,ProductRequired> ();
        Map<String,ProductConsumed> MapProdCons = new Map<String,ProductConsumed> ();

        try{
            WO = [
                SELECT 
                    Estimate__c,Warehouse__c,AssetId,Notes_to_client__c, Internal_Notes__c,Bill_as__c,Estimate__r.Invoice_Contact__c,Estimate__r.Sales_Rep__c,AccountId,CreatedDate,
                    Ship_to_Company_name__c,Ship_to_Street_Address__c,Ship_to_City__c,Ship_to_State__c,Ship_to_Zip_code__c,
                    Bill_to_Company_Name__c,Bill_to_street_address__c,Bill_to_City__c,Bill_to_State__c,Bill_to_Zip_code__c                    
                FROM WorkOrder WHERE Id  = :Id
            ];

            ListItems = new Map<Id,WorkOrderLineItem>([
                SELECT 
                    Seq__c, Subject, Description,Estimated_Labor__c,Estimated_Travel__c,Actual_Labor__c,Actual_Travel__c
                FROM WorkOrderLineItem WHERE WorkOrderId = :Id
            ]);
        
            ListProReq = [
                SELECT 
                    ParentRecordId,Product2Id, Product2.Name,Estimate_Line_Item__r.Selling_Price__c,Estimate_Line_Item__r.Total_Price__c,Estimate_Line_Item__r.Standard_Cost__c
                FROM ProductRequired WHERE ParentRecordId in :ListItems.keySet() AND Estimate_Line_Item__c != null
            ];
            System.debug(ListProReq);

            MapProdCons = new Map<String,ProductConsumed> ([
                SELECT 
                    WorkOrderLineItemId,Product2Id,QuantityConsumed,UnitPrice,Product2.Family,ProductItemId
                FROM ProductConsumed WHERE WorkOrderLineItemId = :ListItems.keySet()
            ]);

            for(ProductRequired pritem : ListProReq){
                String keypr = '' + pritem.Product2Id + pritem.ParentRecordId;
                MapProdReq.put(keypr,pritem);
            }

            System.debug('MapProdReq' + MapProdReq);

            if( (WO.Bill_as__c == 'Estimate' || WO.Bill_as__c == 'Actual') && WO.Estimate__c != null  && MapProdCons.size() > 0){
                Inv = new Invoice__c();
                Inv.Estimate__c = WO.Estimate__c;
                Inv.Ship_to_Company_name__c = WO.Ship_to_Company_name__c;
                Inv.Ship_to_Street_Address__c = WO.Ship_to_Street_Address__c;
                Inv.Ship_to_City__c = WO.Ship_to_City__c;
                Inv.Ship_to_State__c = WO.Ship_to_State__c;
                Inv.Ship_to_Zip_code__c = WO.Ship_to_Zip_code__c;
                Inv.Bill_to_Company_Name__c = WO.Bill_to_Company_Name__c;
                Inv.Bill_to_street_address__c = WO.Bill_to_street_address__c;
                Inv.Bill_to_City__c = WO.Bill_to_City__c;
                Inv.Bill_to_State__c = WO.Bill_to_State__c;
                Inv.Bill_to_Zip_code__c = WO.Bill_to_Zip_code__c;
                Inv.unit__c = WO.AssetId;
                Inv.Client_Comments__c = WO.Notes_to_client__c;
                Inv.Internal_Comments__c = WO.Internal_Notes__c;
                Inv.Status__c = 'Open';
                Inv.Sold_To_Customer__c	= WO.AccountId;
                Inv.Invoice_Contact__c = WO.Estimate__r.Invoice_Contact__c;
                Inv.Sales_Rep__c = WO.Estimate__r.Sales_Rep__c;
                Date d = Date.newinstance(WO.CreatedDate.year(), WO.CreatedDate.month(), WO.CreatedDate.day());
                Inv.Order_Date__c =  d;
                Inv.Work_Order__c = WO.Id;
                
                insert Inv;
                
                Inv = [SELECT Id,Name FROM Invoice__c WHERE Id = :Inv.Id ];
                retunrvalues.add('New Invoice: <a target="_blank" href="' + System.URL.getSalesforceBaseURL().toExternalForm() + '/' + Inv.Id + '" > N° ' + Inv.Name + '</a>');
                
                for(ProductConsumed pc : MapProdCons.values()){
                    WOL = ListItems.get(pc.WorkOrderLineItemId);
                    System.debug('Wol: ' + WOL);
                    String key = ''+ pc.Product2Id + pc.WorkOrderLineItemId;
                    System.debug('Key' + key);
                    ProductRequired Temp = MapProdReq.get(key);
                    System.debug('Part Required: ' + Temp);
                    if(WOL != null){
                        InvLine = new Invoice_line_item__c();
                        InvLine.Invoice__c = Inv.Id;
                        InvLine.Seq__c = WOL.Seq__c;
                        InvLine.Seq_Title__c = WOL.Subject;
                        InvLine.Seq_Notes__c = WOL.Description;
                        InvLine.Part_number__c = pc.Product2Id;
                        
                        Decimal Quantity = 0.00;
                        Decimal Standar_Cost = 0.00;
                        Decimal Selling_Price = 0.00;
                        Decimal Total = 0.00;

                        List<ProductItemTransaction> lpit = [SELECT Actual_cost_per_item__c FROM ProductItemTransaction WHERE ProductItemId = :pc.ProductItemId AND Actual_cost_per_item__c != null order by CreatedDate desc limit 1];
                        ProductItemTransaction pit;
                        if(lpit.size() > 0){
                            pit = lpit[0];
                        }
                        System.debug(pit);
                        System.debug(pc);
                        

                        if(pc.Product2.Family == 'Labor'){      
                            if(WO.Bill_as__c == 'Estimate'){

                                Quantity = WOL.Estimated_Labor__c;
                                Standar_Cost  = Temp.Estimate_Line_Item__r.Standard_Cost__c;
                                Selling_Price  = Temp.Estimate_Line_Item__r.Selling_Price__c;
                                Total = Temp.Estimate_Line_Item__r.Total_Price__c;
                                
                            }else if(WO.Bill_as__c == 'Actual'){

                                Quantity = WOL.Actual_Labor__c;
                                if(pc.UnitPrice > 0 ){
                                    Standar_Cost  = pc.UnitPrice;
                                } else {
                                    Standar_Cost = pit.Actual_cost_per_item__c;
                                }
                                Selling_Price  = Temp.Estimate_Line_Item__r.Selling_Price__c;
                                System.debug('Quantity: ' + Quantity);
                                System.debug('Standar_Cost: ' + Standar_Cost);
                                Total = Quantity * Standar_Cost ;

                            }
                        }else if(pc.Product2.Family == 'Travel'){
                            if(WO.Bill_as__c == 'Estimate'){

                                Quantity = WOL.Estimated_Travel__c;
                                Standar_Cost  = Temp.Estimate_Line_Item__r.Standard_Cost__c;
                                Selling_Price  = Temp.Estimate_Line_Item__r.Selling_Price__c;
                                Total = Temp.Estimate_Line_Item__r.Total_Price__c; 

                            }else if(WO.Bill_as__c == 'Actual'){

                                Quantity = WOL.Actual_Travel__c;
                                if(pc.UnitPrice > 0 ){
                                    Standar_Cost  = pc.UnitPrice;
                                } else {
                                    Standar_Cost = pit.Actual_cost_per_item__c;
                                }
                                Selling_Price  = Temp.Estimate_Line_Item__r.Selling_Price__c;
                                Total = Quantity * Standar_Cost ;

                            }
                        }else{

                            Quantity = pc.QuantityConsumed;
                            if(pc.UnitPrice > 0 )
                                Standar_Cost  = pc.UnitPrice;
                            else {
                                Standar_Cost = pit.Actual_cost_per_item__c;
                            }
                            Selling_Price  = Temp.Estimate_Line_Item__r.Selling_Price__c;
                            System.debug('Quantity: ' + Quantity);
                            System.debug('Standar_Cost: ' + Standar_Cost);
                            Total = Quantity * Standar_Cost ;

                        }

                        InvLine.Quantity__c = Quantity;
                        InvLine.Standard_Cost__c  = Standar_Cost;
                        InvLine.Selling_Price__c  = Selling_Price;
                        InvLine.Total_Price__c = Total ;
                        
                        ListInvLine.add(InvLine);
                    }
                }
                     
            }else{
                retunrvalues.add('The fields "Bill as" and "Estimate" should have a value');
            }

            if (ListInvLine.size() > 0){insert ListInvLine;}

            return retunrvalues;
        }catch(Exception ex){
            System.debug('Line: ' + ex.getLineNumber() + ' - Message: '+ ex.getMessage());
            retunrvalues.add(ex.getMessage());
            return retunrvalues;
        }
    }
    @AuraEnabled
    public static List<String> Verify(String Id){

        List<String> retunrvalues = new List<String>();
        WorkOrder WO;
        Map<Id,WorkOrderLineItem> ListItems;
        List<ProductConsumed> ListProCons;
        List<ProductRequired> ListProReq;

        Invoice_line_item__c InvLine;
        WorkOrderLineItem WOL;
        Invoice__c Inv;

        Map<String,ProductRequired> MapProdReq = new Map<String,ProductRequired> ();
        Map<String,ProductConsumed> MapProdCons = new Map<String,ProductConsumed> ();

        try{
            WO = [
                SELECT 
                    Bill_as__c ,Estimate__c               
                FROM WorkOrder WHERE Id  = :Id
            ];

            ListItems = new Map<Id,WorkOrderLineItem>([
                SELECT 
                    Seq__c, Subject, Description,Estimated_Labor__c,Estimated_Travel__c,LineItemNumber,Actual_Labor__c,Actual_Travel__c
                FROM WorkOrderLineItem WHERE WorkOrderId = :Id
            ]);
        
            ListProReq = [
                SELECT 
                    ParentRecordId,Product2Id, Product2.Name,Estimate_Line_Item__r.Selling_Price__c,Estimate_Line_Item__r.Total_Price__c,Estimate_Line_Item__r.Standard_Cost__c
                FROM ProductRequired WHERE ParentRecordId in :ListItems.keySet() AND Estimate_Line_Item__c != null
            ];
            System.debug(ListProReq);

            MapProdCons = new Map<String,ProductConsumed> ([
                SELECT 
                    WorkOrderLineItemId,Product2Id,QuantityConsumed,UnitPrice,Product2.Family,Product2.Name,ProductItemId
                FROM ProductConsumed WHERE WorkOrderLineItemId = :ListItems.keySet()
            ]);

            for(ProductRequired pritem : ListProReq){
                String keypr = '' + pritem.Product2Id + pritem.ParentRecordId;
                MapProdReq.put(keypr,pritem);
            }

            System.debug('MapProdReq' + MapProdReq);

            if( (WO.Bill_as__c == 'Estimate' || WO.Bill_as__c == 'Actual') && WO.Estimate__c != null  && MapProdCons.size() > 0){
                
                for(ProductConsumed pc : MapProdCons.values()){
                    WOL = ListItems.get(pc.WorkOrderLineItemId);
                    System.debug('Wol: ' + WOL);
                    String key = ''+ pc.Product2Id + pc.WorkOrderLineItemId;
                    System.debug('Key' + key);
                    ProductRequired Temp = MapProdReq.get(key);
                    System.debug('Part Required: ' + Temp);
                    if(WOL != null){

                        List<ProductItemTransaction> lpit = [SELECT Actual_cost_per_item__c FROM ProductItemTransaction WHERE ProductItemId = :pc.ProductItemId AND Actual_cost_per_item__c != null order by CreatedDate desc limit 1];
                        ProductItemTransaction pit;
                        if(lpit.size() > 0){
                            pit = lpit[0];
                        }
                        String name = [SELECT Id,ProductConsumedNumber FROM ProductConsumed WHERE ID = :pc.Id].get(0).ProductConsumedNumber;
                        if(pc.Product2.Family == 'Labor'){      
                            if(WO.Bill_as__c == 'Estimate'){

                                if(Temp == null){
                                    retunrvalues.add('The Part Consumed '+ name+': <a target="_blank" href="' + System.URL.getSalesforceBaseURL().toExternalForm() + '/' + pc.Id + '" >' + pc.Product2.Name + '</a> don\'t have a Part Required with the same Part');
                                }
                                
                            }else if(WO.Bill_as__c == 'Actual'){
                                if(pit ==  null && pc.UnitPrice == null){
                                    retunrvalues.add('The Part Consumed '+ name+': <a target="_blank" href="' + System.URL.getSalesforceBaseURL().toExternalForm() + '/' + pc.Id + '" >' + pc.Product2.Name + '</a> don\'t have a unit price');
                                }
                                if(WOL.Actual_Labor__c == null){
                                    retunrvalues.add('The Work Order Line <a target="_blank" href="' + System.URL.getSalesforceBaseURL().toExternalForm() + '/' + WOL.Id + '" >' + WOL.LineItemNumber + '</a> don\'t have a Actual Labor');
                                }
                                

                            }
                        }else if(pc.Product2.Family == 'Travel'){
                            if(WO.Bill_as__c == 'Estimate'){

                                if(Temp == null){
                                    retunrvalues.add('The Part Consumed '+ name+': <a target="_blank" href="' + System.URL.getSalesforceBaseURL().toExternalForm() + '/' + pc.Id + '" >' + pc.Product2.Name + '</a> don\'t have a Part Required with the same Part');
                                }

                            }else if(WO.Bill_as__c == 'Actual'){
                                if(pit ==  null && pc.UnitPrice == null){
                                    retunrvalues.add('The Part Consumed '+ name+': <a target="_blank" href="' + System.URL.getSalesforceBaseURL().toExternalForm() + '/' + pc.Id + '" >' + pc.Product2.Name + '</a> don\'t have a unit price');
                                }
                                
                                if(WOL.Actual_Travel__c == null){
                                    retunrvalues.add('The Work Order Line <a target="_blank" href="' + System.URL.getSalesforceBaseURL().toExternalForm() + '/' + WOL.Id + '" >' + WOL.LineItemNumber + '</a> don\'t have a Actual Travel');
                                }
                            }
                        }else{

                            if(pit ==  null && pc.UnitPrice == null){
                                retunrvalues.add('The Part Consumed '+ name+': <a target="_blank" href="' + System.URL.getSalesforceBaseURL().toExternalForm() + '/' + pc.Id + '" >' + pc.Product2.Name + '</a> don\'t have a unit price');
                            }

                        }

                        
                    }
                }
                     
            }else{
                retunrvalues.add('The fields "Bill as" and "Estimate" should have a value and at least one part consumed related to a line item');
            }

            //if (ListInvLine.size() > 0){insert ListInvLine;}

            return retunrvalues;
        }catch(Exception ex){
            System.debug('Line: ' + ex.getLineNumber() + ' - Message: '+ ex.getMessage());
            retunrvalues.add(ex.getMessage());
            return retunrvalues;
        }
    }
}