public with sharing class ApexCreationPO {
    
    @AuraEnabled
    public static List<String> createPOandPOItems(String id){
        List<String> messages = new List<String>();
        
        List<WorkOrder> workOrderList = [select Id, AccountId, Warehouse__c, Ship_to_Company_name__c, Ship_to_Street_Address__c, Ship_to_City__c, Ship_to_State__c, Ship_to_Zip_code__c 
                                         	from WorkOrder 
                                         	where Id=:id];
        if(workOrderList==null || workOrderList.size()==0){
            System.debug('Work Order not exists!');
            messages.add('Work Order not exists!');
            return messages;
        }
        
        List<ProductRequired> partRequiredList = [select Id, ProductRequiredNumber, Product2Id, Supplier_Formula__c, QuantityRequired, /*Unknown_Part_Name__c,*/PO__c,Product2.Standard_Cost__c 
                                                  	from ProductRequired 
                                                  	where Work_Order__c=:id and Inventory_Status__c='Back Order' and Supplier_Formula__c!=null];
        if(partRequiredList==null || partRequiredList.size()==0){
            System.debug('There are no part required with status equal to Back Order related to this record!');
            messages.add('There are no part required with status equal to Back Order related to this record!');
            return messages;
        }

		Map<String, List<ProductRequired>> mapPOInsert = new Map<String, List<ProductRequired>>(); 
        List<ProductRequired> auxList = new List<ProductRequired>();
        for(ProductRequired pr : partRequiredList){
            auxList = mapPOInsert.get(pr.Supplier_Formula__c);
            if(auxList==null) auxList = new List<ProductRequired>();
            auxList.add(pr);
            mapPOInsert.put(pr.Supplier_Formula__c, auxList);
        }
        
        Purchase_Order__c auxPOInsert;
        Purchase_order_Line_Item__c auxPOLI;
        Map<String, Purchase_order__c> poInsertMap = new Map<String, Purchase_order__c>();
        List<Purchase_order_Line_Item__c> poliInsertList = new List<Purchase_order_Line_Item__c>();
        try{
            for(String key : mapPOInsert.keySet()){
            	auxPOInsert = new Purchase_Order__c();
                auxPOInsert.Supplier__c = key;
                auxPOInsert.Order_Description__c = 'PO Created to fulfil backorder';
                auxPOInsert.Status__c = 'Open';
                auxPOInsert.Purchase_order_type__c = 'N (normal)';
                auxPOInsert.Order_date__c = Date.today();
                auxPOInsert.Accounting_status__c = 'Open';
                auxPOInsert.Ship_to_Option__c = 'Customer';
                auxPOInsert.Work_Order__c = workOrderList[0].Id;
                auxPOInsert.Customer__c = workOrderList[0].AccountId;
                auxPOInsert.Warehouse__c = workOrderList[0].Warehouse__c;
                auxPOInsert.Ship_to_name__c = workOrderList[0].Ship_to_Company_name__c;
                auxPOInsert.Ship_to_address__c = workOrderList[0].Ship_to_Street_Address__c;
                auxPOInsert.Ship_to_City__c = workOrderList[0].Ship_to_City__c;
                auxPOInsert.Ship_to_State__c = workOrderList[0].Ship_to_State__c;
                auxPOInsert.Ship_to_Postal_code__c = workOrderList[0].Ship_to_Zip_code__c;
                poInsertMap.put(key, auxPOInsert);
                for(ProductRequired pr : mapPOInsert.get(key)){
                    auxPOLI = new Purchase_order_Line_Item__c();
                    auxPOLI.Work_Order__c = workOrderList[0].Id;
                    auxPOLI.Part_Number__c = pr.Product2Id;
                    auxPOLI.Order_Qty__c = pr.QuantityRequired;
                    auxPOLI.Status__c = 'Open';
                    //auxPOLI.Unknown_Supplier_Part_Number__c = pr.Unknown_Part_Name__c;
                    auxPOLI.Part_Required__c = pr.Id;
                    auxPOLI.Supplier_Key__c = key;
                    auxPOLI.Actual_Cost__c = pr.Product2.Standard_Cost__c;
                    auxPOLI.Warehouse__c = workOrderList[0].Warehouse__c;
                    poliInsertList.add(auxPOLI);
                }
            }
            
            insert poInsertMap.values();
            
            for(Purchase_Order__c po : poInsertMap.values()){
                messages.add('<a target="_blank" href="' + System.URL.getSalesforceBaseURL().toExternalForm() + '/' + po.Id + '" > New Purchase Order</a>');
            }
            
            Map<Id,ProductRequired> MapPartRequired = new Map<Id,ProductRequired>(partRequiredList);
            ProductRequired temp;

            for(Purchase_order_Line_Item__c poli : poliInsertList){
                poli.Purchase_Order__c = poInsertMap.get(poli.Supplier_Key__c).Id;
                temp = MapPartRequired.get(poli.Part_Required__c);
                if(temp != null) temp.PO__c = poli.Purchase_Order__c;
            }
            
            update MapPartRequired.values();

            insert poliInsertList;
        }catch(Exception e){
            System.debug(e.getLineNumber() + '->' + e.getMessage());
            messages.add('Error: ' + e.getLineNumber() + '->' + e.getMessage());
        }
        
        return messages;//new String[]{'Hiiiiii', 'Chauuuuu'};
    }

}