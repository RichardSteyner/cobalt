trigger Create_Price_Book on Product2 (after insert) {
    List<String> bookNames = new String[] {'Tier 1: Retail','Tier 2: Contractor','Tier 3: Dealer'}; 
    Map<String,Pricebook2> Books = new Map<String,Pricebook2>();
    List<PricebookEntry> bookEntry = new List<PricebookEntry>();
    List<PricebookEntry> EntryForStandard = new List<PricebookEntry>();
    Map<Id,Account> Suppliers;
    Set<Id> SupplierIds = new Set<Id>();
    Pricebook2 temp;
    PricebookEntry newEntry;
    Boolean flag = false;

    Pricebook2 stdPriceBook = [select id, name from Pricebook2 where isStandard = true limit 1];
    for(Pricebook2 pb : [SELECT id,IsActive,Name,IsStandard FROM Pricebook2 WHERE Name IN :bookNames AND IsActive = true]){
        Books.put(pb.Name, pb);
    }
    
    for (Product2 item : Trigger.new) {
        SupplierIds.add(item.Supplier__c);
    }

    Suppliers = new Map<Id,Account>([SELECT Id,Tier_1_Retail__c,Tier_2_Contractor__c,Tier_3_Dealer__c FROM Account WHERE Id IN :SupplierIds]);

    for (Product2 item : Trigger.new) {
       
        if(item.List_price__c != null){
            temp = Books.get(bookNames[0]);
            if(temp != null){
                flag = temp.IsStandard ? true : false;
                PricebookEntry newEntry = new PricebookEntry();
                newEntry.Product2Id = item.Id;
                newEntry.Pricebook2Id = temp.Id;
                Double Percent = Suppliers.get(item.Supplier__c).Tier_1_Retail__c;
                Percent = Percent == null ? 0 : Percent/100;
                newEntry.UnitPrice = item.List_price__c - ( item.List_price__c * Percent);
                newEntry.IsActive = true;
                bookEntry.add(newEntry);
            }
            temp = Books.get(bookNames[1]);
            if(temp != null){
                flag = temp.IsStandard ? true : false;
                PricebookEntry newEntry = new PricebookEntry();
                newEntry.Product2Id = item.Id;
                newEntry.Pricebook2Id = temp.Id;
                Double Percent = Suppliers.get(item.Supplier__c).Tier_2_Contractor__c;
                Percent = Percent == null ? 0 : Percent/100;
                newEntry.UnitPrice = item.List_price__c - ( item.List_price__c * Percent);
                newEntry.IsActive = true;
                bookEntry.add(newEntry);
            }
            temp = Books.get(bookNames[2]);
            if(temp != null){
                PricebookEntry newEntry = new PricebookEntry();
                flag = temp.IsStandard ? true : false;
                newEntry.Product2Id = item.Id;
                newEntry.Pricebook2Id = temp.Id;
                Double Percent = Suppliers.get(item.Supplier__c).Tier_3_Dealer__c;
                Percent = Percent == null ? 0 : Percent/100;
                newEntry.UnitPrice = item.List_price__c - ( item.List_price__c * Percent);
                newEntry.IsActive = true;
                bookEntry.add(newEntry);
            }

            if(!flag){
                PricebookEntry newEntry = new PricebookEntry();
                newEntry.Product2Id = item.Id;
                newEntry.Pricebook2Id = stdPriceBook.Id;
                newEntry.UnitPrice = item.List_price__c ;
                newEntry.IsActive = true;
                EntryForStandard.add(newEntry);
            }
        }
        
    }
    
    System.debug(bookEntry);
    if(EntryForStandard.size() > 0) insert EntryForStandard;
    if(bookEntry.size() > 0) insert bookEntry;
}