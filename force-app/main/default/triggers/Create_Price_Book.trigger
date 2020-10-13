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

    Suppliers = new Map<Id,Account>([SELECT Id,Name,Tier_1_Retail__c,Tier_2_Contractor__c,Tier_3_Dealer__c FROM Account WHERE Id IN :SupplierIds]);

    Double Margin_Tier_1;
    Double Margin_Tier_2;
    Double Margin_Tier_3;
    String Tier_Message;
    for (Product2 item : Trigger.new) {
        Tier_Message = '';
        
        Margin_Tier_1 = Suppliers.get(item.Supplier__c).Tier_1_Retail__c;
        Margin_Tier_2 = Suppliers.get(item.Supplier__c).Tier_2_Contractor__c;
        Margin_Tier_3 = Suppliers.get(item.Supplier__c).Tier_3_Dealer__c;

        if(Margin_Tier_1 == 0  || Margin_Tier_1 == null) Tier_Message += ' Tier 1: Retail,';
        if(Margin_Tier_2 == 0  || Margin_Tier_2 == null) Tier_Message += ' Tier 2: Retail,';
        if(Margin_Tier_3 == 0  || Margin_Tier_3 == null) Tier_Message += ' Tier 3: Retail,';

        if(Tier_Message == ''){
            temp = Books.get(bookNames[0]);
            if(temp != null){
                flag = temp.IsStandard ? true : false;
                newEntry = new PricebookEntry();
                newEntry.Product2Id = item.Id;
                newEntry.Pricebook2Id = temp.Id;
                
                Margin_Tier_1 = Margin_Tier_1 == null ? 0 : (100 - Margin_Tier_1)/100;
                newEntry.UnitPrice = item.Landed_Cost__c/Margin_Tier_1;
                newEntry.IsActive = true;
                bookEntry.add(newEntry);
            }
            temp = Books.get(bookNames[1]);
            if(temp != null){
                flag = temp.IsStandard ? true : false;
                newEntry = new PricebookEntry();
                newEntry.Product2Id = item.Id;
                newEntry.Pricebook2Id = temp.Id;
                
                Margin_Tier_2 = Margin_Tier_2 == null ? 0 : (100 - Margin_Tier_2)/100;
                newEntry.UnitPrice = item.Landed_Cost__c/Margin_Tier_2;
                newEntry.IsActive = true;
                bookEntry.add(newEntry);
            }
            temp = Books.get(bookNames[2]);
            if(temp != null){
                newEntry = new PricebookEntry();
                flag = temp.IsStandard ? true : false;
                newEntry.Product2Id = item.Id;
                newEntry.Pricebook2Id = temp.Id;
                
                Margin_Tier_3 = Margin_Tier_3 == null ? 0 : (100 - Margin_Tier_3)/100;
                newEntry.UnitPrice = item.Landed_Cost__c/Margin_Tier_3;
                newEntry.IsActive = true;
                bookEntry.add(newEntry);
            }

            if(!flag){
                newEntry = new PricebookEntry();
                newEntry.Product2Id = item.Id;
                newEntry.Pricebook2Id = stdPriceBook.Id;
                newEntry.UnitPrice = item.List_price__c ;
                newEntry.IsActive = true;
                EntryForStandard.add(newEntry);
            }
        }else{
            item.addError('The supplier selected doesn\'t have the following fields:' + Tier_Message.removeEnd(','));
        }
        
    }
    
    System.debug(bookEntry);
    if(EntryForStandard.size() > 0) insert EntryForStandard;
    if(bookEntry.size() > 0) insert bookEntry;
}