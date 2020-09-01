trigger Estimate_Line_Update_Price on Estimate_Line_Item__c (before insert,before update) {

   
    if(Trigger.isBefore){
        set<Id> partIds = new set<Id>();
        Product2 temp;
    
        for(Estimate_Line_Item__c item : Trigger.new){
            if(item.Part_number__c != null){
                partIds.add(item.Part_number__c);
            }
        }

        Map<Id,Product2> MapPart = new Map<Id,Product2>([
            SELECT 
                Id,Landed_Cost__c,Standard_Cost__c,Family,Supplier__r.Labor_Travel_Pricebook__c,Supplier__r.Parts_Material_Pricebook__c
            FROM Product2 WHERE Id IN :partIds  
        ]);

        Map<String,Decimal> MapEntryPrice = new Map<String,Decimal>();
        List<PricebookEntry> EntryTemp;

        if(Trigger.isInsert){  
            for(Product2 p : MapPart.values()){
                if(p.Supplier__c != null){
                    if(p.Supplier__r.Labor_Travel_Pricebook__c != null){
                        EntryTemp = [SELECT Id,UnitPrice,Product2Id FROM PricebookEntry WHERE Product2Id = :p.Id AND Pricebook2Id = :p.Supplier__r.Labor_Travel_Pricebook__c];
                        if(EntryTemp.size() > 0){
                            MapEntryPrice.put(p.id + '-Labor_Travel_Pricebook',EntryTemp.get(0).UnitPrice);
                        }
                    }
                    if(p.Supplier__r.Parts_Material_Pricebook__c != null){
                        EntryTemp = [SELECT Id,UnitPrice,Product2Id FROM PricebookEntry WHERE Product2Id = :p.Id AND Pricebook2Id = :p.Supplier__r.Parts_Material_Pricebook__c];
                        if(EntryTemp.size() > 0){
                            MapEntryPrice.put(p.id + '-Parts_Material_Pricebook',EntryTemp.get(0).UnitPrice);
                        }
                    }
                }
            }
        }
    
        Decimal price;
        for(Estimate_Line_Item__c item : Trigger.new){
            try{
                if(item.Part_number__c != null){
                    temp = MapPart.get(item.Part_number__c);
                    if(temp != null){
                        if(Trigger.isInsert){                            
                            item.Standard_Cost__c = temp.Standard_Cost__c;
                            if(temp.Family == 'Travel' || temp.Family == 'Labor'){
                                price = MapEntryPrice.get(temp.id + '-Labor_Travel_Pricebook');
                                if(price != null)
                                    item.Selling_Price__c = price;
                                else {
                                    item.addError('Part Price book entry not found please create the price book entry or use another part');
                                }
                            }else{
                                price = MapEntryPrice.get(temp.id + '-Parts_Material_Pricebook');
                                if(price != null)
                                    item.Selling_Price__c = price;
                                else {
                                    item.addError('Part Price book entry not found please create the price book entry or use another part');
                                }
                            }
                        }
                        //item.Selling_Price__c = (temp.Landed_Cost__c * item.Adjusted_Margin__c ) + temp.Landed_Cost__c;
                        item.Total_Price__c = item.Selling_Price__c * item.Quantity__c;                   
                    }
                }
            }catch (Exception ex){
                System.debug('Line: ' + ex.getLineNumber() + ' - Message: '+ ex.getMessage());
            } 
        }
    }
    
}