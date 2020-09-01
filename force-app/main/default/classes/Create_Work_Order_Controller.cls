public with sharing class Create_Work_Order_Controller {
    @AuraEnabled
    public static List<String> CreateWO(String Id){
        List<String> retunrvalues = new List<String>();
        Estimate__c estimate;
        List<Estimate_line_Item__c> estimateItems;
        WorkOrderLineItem aux ;
        WorkOrder woInsert;
        List<WorkOrderLineItem> wolInsert = new List<WorkOrderLineItem>();
        ProductRequired pr;
        Map<String,ProductRequired> lpr = new Map<String,ProductRequired>();
        Map<String,Estimate_line_Item__c> mapLI = new Map<String,Estimate_line_Item__c>();
        Map<Decimal,WorkOrderLineItem> mapSeqWOL = new Map<Decimal,WorkOrderLineItem>();

        try{
            estimate = [
                SELECT
                    Id,Sold_to_Customer__c, Warehouse__c, Client_Comments__c,Internal_Comments__c,Unit__c,Customer_PO__c,
                    Ship_to_City__c,Ship_to_Company_name__c,Ship_to_State__c,Ship_to_Street_Address__c,Ship_to_Zip_code__c,
                    Bill_to_City__c,Bill_to_Company_Name__c,Bill_to_State__c,Bill_to_street_address__c,Bill_to_Zip_code__c            
                FROM Estimate__c WHERE Id = :Id
            ];

            if(estimate.Customer_PO__c != null){

                estimateItems = [
                    SELECT 
                        ID,Part_number__c,Quantity__c,Part_number__r.Name,seq__c,Seq_Title__c,Seq_Notes__c,
                        Unknown_Part_Name__c, Unknown_Supplier_Name__c, Part_number__r.Family,Name
                    FROM Estimate_line_Item__c WHERE Estimate__c = :Id AND Suggested__c = false
                ];

                woInsert = new WorkOrder();
                woInsert.Estimate__c = estimate.Id;
                woInsert.AssetId = estimate.Unit__c;
                woInsert.AccountId = estimate.Sold_to_Customer__c;
                woInsert.Warehouse__c = estimate.Warehouse__c;
                woInsert.Status = 'New';
                woInsert.Ship_to_City__c = estimate.Ship_to_City__c;
                woInsert.Ship_to_Company_name__c = estimate.Ship_to_Company_name__c;
                woInsert.Ship_to_State__c	 = estimate.Ship_to_State__c;
                woInsert.Ship_to_Street_Address__c = estimate.Ship_to_Street_Address__c;
                woInsert.Ship_to_Zip_code__c = estimate.Ship_to_Zip_code__c;
                woInsert.Bill_to_City__c = estimate.Bill_to_City__c;
                woInsert.Bill_to_Company_Name__c = estimate.Bill_to_Company_Name__c;
                woInsert.Bill_to_State__c = estimate.Bill_to_State__c;
                woInsert.Bill_to_street_address__c = estimate.Bill_to_street_address__c;
                woInsert.Bill_to_Zip_code__c = estimate.Bill_to_Zip_code__c;
                woInsert.Notes_to_client__c = estimate.Client_Comments__c;
                woInsert.Internal_Notes__c = estimate.Internal_Comments__c;

                insert woInsert;

                woInsert = [SELECT Id, WorkOrderNumber, Warehouse__c FROM WorkOrder WHERE Id = :WOInsert.Id ];
                retunrvalues.add('New Work Order: <a target="_blank" href="' + System.URL.getSalesforceBaseURL().toExternalForm() + '/' + woInsert.Id + '" > N° ' + woInsert.WorkOrderNumber + '</a>');

                for(Estimate_line_Item__c item : estimateItems){
                    aux = mapSeqWOL.get(item.Seq__c);
                    if(aux == null){
                        aux = new WorkOrderLineItem();
                        aux.WorkOrderId = woInsert.Id;
                        aux.AssetId = estimate.Unit__c;
                        aux.Status = 'New';
                        aux.Seq__c = item.Seq__c;
                        aux.Subject = item.Seq_Title__c;
                        aux.Description =  item.Seq_Notes__c;
                        aux.Estimate_Line_Item__c = item.Id;
                        String auxFam = item.Part_number__r.Family != null ? item.Part_number__r.Family : '';
                        if(auxFam.contains('Labor')){
                            aux.Estimated_Labor__c = item.Quantity__c;
                        }

                        if(auxFam.contains('Travel')){
                            aux.Estimated_Travel__c = item.Quantity__c;
                        }
                    }else{
                        String auxFam = item.Part_number__r.Family != null ? item.Part_number__r.Family : '';
                        if(auxFam.contains('Labor')){
                            aux.Estimated_Labor__c = aux.Estimated_Labor__c > 0 ? aux.Estimated_Labor__c + item.Quantity__c : item.Quantity__c;
                        }

                        if(auxFam.contains('Travel')){
                            aux.Estimated_Travel__c = aux.Estimated_Travel__c > 0 ? aux.Estimated_Travel__c + item.Quantity__c : item.Quantity__c;
                        }
                    }
                    mapSeqWOL.put(item.Seq__c,Aux);
                    mapLI.put(item.id,item);
                }
                
                insert mapSeqWOL.values();
                
                
                Map<Id,Decimal> mapProductStock = new Map<Id,Decimal>();
                for(Estimate_line_Item__c item : estimateItems)
                    mapProductStock.put(item.Part_number__c, 0);
                
                for(ProductItem pi : [select Id, QuantityOnHand, Product2Id from ProductItem where LocationId=:woInsert.Warehouse__c and Product2Id in:mapProductStock.keySet()]){
                    mapProductStock.put(pi.Product2Id, mapProductStock.get(pi.Product2Id)!=null ? (mapProductStock.get(pi.Product2Id) + pi.QuantityOnHand) : pi.QuantityOnHand);
                }

                List<ProductItem> ListProItem;
                ProductItem ProItem;


                String identity;
                for(Estimate_line_Item__c item : estimateItems){
                    if(item.Part_number__c != null){
                        identity = mapSeqWOL.get(item.Seq__c).Id;
                    
                        ListProItem = [SELECT Id,Quantity_Committed__c FROM ProductItem WHERE LocationId = :woInsert.Warehouse__c  AND Product2Id = :item.Part_number__c];
                        ProItem = ListProItem.size()>0 ? ListProItem[0] : null;

                        if(ProItem == null){
                            ProItem = new ProductItem ();
                            ProItem.Product2Id = item.Part_Number__c;
                            ProItem.QuantityOnHand = 0;
                            ProItem.LocationId = woInsert.Warehouse__c;
                            System.debug(ProItem);
                            insert ProItem;
                        }

                        pr = new ProductRequired();
                        pr.ParentRecordId = identity;
                        pr.Estimate_Line_Item__c = item.Id;
                        pr.Product2Id = item.Part_number__c;
                        pr.QuantityRequired = item.Quantity__c;
                        pr.Work_Order__c = woInsert.Id;
                        pr.Unknown_Part_Name__c = item.Unknown_Part_Name__c;
                        pr.Unknown_Supplier_Name__c = item.Unknown_Supplier_Name__c;
                        if(item.Part_number__r.Family == 'Travel' || item.Part_number__r.Family == 'Labor'){
                            pr.Inventory_Status__c = 'Commit';
                        }else if(mapProductStock.get(item.Part_number__c)>=item.Quantity__c){
                            pr.Inventory_Status__c = 'Commit';
                        }else {
                            pr.Inventory_Status__c = 'Back Order';
                        }
                        if(item.Part_number__r.Family=='Unknown Part'){
                            if(pr.Unknown_Supplier_Name__c==null)
                                pr.Inventory_Status__c = 'Open';
                            else
                                pr.Inventory_Status__c = 'Back Order';                        
                        }
                        
                        lpr.put(item.Id,pr);
                    }else{
                        retunrvalues.add('<a target="_blank" href="'+System.URL.getSalesforceBaseURL().toExternalForm() + '/'+item.id+'" >' + item.Name+ '</a> - Error: This Estimate Line don\'t have Part related');
                    }
                    
                }

                Database.SaveResult[] results = Database.insert(lpr.values(),false);
                for(Integer i=0; i<results.size(); i++){
                    if (!results.get(i).isSuccess()){
                        pr = lpr.values()[i];
                        Database.Error error = results.get(i).getErrors().get(0);
                        System.debug('<a target="_blank" href="'+System.URL.getSalesforceBaseURL().toExternalForm() + '/'+pr.Estimate_Line_Item__c+'" >' + MapLI.get(pr.Estimate_Line_Item__c).Part_number__r.Name + '</a> - Error: ' + error.getMessage());
                        retunrvalues.add('<a target="_blank" href="'+System.URL.getSalesforceBaseURL().toExternalForm() + '/'+pr.Estimate_Line_Item__c+'" >' + MapLI.get(pr.Estimate_Line_Item__c).Part_number__r.Name + '</a> - Error: ' + error.getMessage());
                    }
                }
            
            }else{
                retunrvalues.add('Customer PO # is required');
            }

            return retunrvalues;
        }catch(Exception ex){
            System.debug('Line: ' + ex.getLineNumber() + ' - Message: '+ ex.getMessage());
            retunrvalues.add(ex.getMessage());
            return retunrvalues;
        }
    }
}