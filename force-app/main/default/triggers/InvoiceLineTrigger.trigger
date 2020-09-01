trigger InvoiceLineTrigger on Invoice_line_item__c (after insert, after update) {
    
    if(ApexTriggerUtility.isInvoiceLineTriggerInvoked == true){
        Set<Id> lineIds = new Set<Id>();
        Set<Id> calculateIds = new Set<Id>();
        
        if(Trigger.IsInsert) {
            for(Invoice_line_item__c line : Trigger.New){
                lineIds.add(line.Id);
                System.debug('InvoiceLineTrigger Populate->' + line.Id);
                calculateIds.add(line.Id);
                System.debug('InvoiceLineTrigger Calculate->' + line.Id);
            }
        
            Map<Id, Invoice_line_item__c> mapLines = new Map<Id, Invoice_line_item__c>();
            
            for(Invoice_line_item__c line : [select Id, Invoice__c, Invoice__r.State_Tax_Code__c from Invoice_line_item__c where Id in: lineIds]){
                mapLines.put(line.Id, line);
            }
            
            for(Invoice_line_item__c line : mapLines.values()){
                line.State_Tax_Code__c = line.Invoice__r.State_Tax_Code__c;
            }
            
            ApexTriggerUtility.isInvoiceLineTriggerInvoked = false;
            if(mapLines.values().size()>0){
                update mapLines.values();
            }
        }else{
            for(Invoice_line_item__c line : Trigger.New){
                calculateIds.add(line.Id);
                System.debug('InvoiceLineTrigger Calculate->' + line.Id);
            }
        }
        
        Map<Id, Invoice_line_item__c> mapCalculateLines = new Map<Id, Invoice_line_item__c>();
        
        for(Invoice_line_item__c line : [select Id, Part_number__r.Family, Selling_Price__c, Quantity__c, 
                                            State_Tax_Code__c, State_Tax_Code__r.Total_Tax_Rate__c, State_Tax_Code__r.Labor_Taxable__c, State_Tax_Code__r.Freight_Taxable__c 
                                            from Invoice_line_item__c where Id in: calculateIds]){
            mapCalculateLines.put(line.Id, line);
        }
        
        Boolean auxLaborTaxable = false;
        Boolean auxFreighTaxable = false;
        Decimal auxSellingPrice = 0.0;
        Decimal auxQty = 0.0;
        Decimal auxTotalTaxRate = 0.0;
        
        for(Invoice_line_item__c line : mapCalculateLines.values()){
            if(line.Part_number__r.Family!=null){
                auxLaborTaxable = line.State_Tax_Code__c!=null && line.State_Tax_Code__r.Labor_Taxable__c;
                auxFreighTaxable = line.State_Tax_Code__c!=null && line.State_Tax_Code__r.Freight_Taxable__c;
                auxSellingPrice = line.Selling_Price__c!=null ? line.Selling_Price__c : 0.0;
                auxQty = line.Quantity__c!=null ? line.Quantity__c : 0.0;
                auxTotalTaxRate = line.State_Tax_Code__c!=null && line.State_Tax_Code__r.Total_Tax_Rate__c!=null ? line.State_Tax_Code__r.Total_Tax_Rate__c/100 : 0.0;
                if(line.Part_number__r.Family.equalsIgnoreCase('Parts & Material')){
                    line.Tax__c = (auxSellingPrice * auxQty) * auxTotalTaxRate;
                    line.Total_Price__c = line.Tax__c + (auxSellingPrice * auxQty);
                }else if(line.Part_number__r.Family.equalsIgnoreCase('Labor') && auxLaborTaxable){
                    line.Tax__c = (auxSellingPrice * auxQty) * auxTotalTaxRate;
                    line.Total_Price__c = line.Tax__c + (auxSellingPrice * auxQty);
                }else if(line.Part_number__r.Family.equalsIgnoreCase('Freight') && auxFreighTaxable){
                    line.Tax__c = (auxSellingPrice * auxQty) * auxTotalTaxRate;
                    line.Total_Price__c = line.Tax__c + (auxSellingPrice * auxQty);
                }else{
                    System.debug('Invoice Line Item without parameters required: ' + line.Id);
                }
            }else{
                System.debug('Invoice Line Item without Part_number__r.Family: ' + line.Id);
            }
        }
        
        ApexTriggerUtility.isInvoiceLineTriggerInvoked = false;
        if(mapCalculateLines.values().size()>0){
        	update mapCalculateLines.values();
        }
    }

}