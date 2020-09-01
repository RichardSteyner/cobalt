public with sharing class Purchase_Order_Generate_PDF_Controller {
    public Purchase_Order__c po {get;set;}
    Public Organization Company {get;set;}
    Public Account Supplier {get;set;}
    Public String OwnerName {get;set;}
    public Boolean Errors {get;set;}
    public list<Purchase_order_Line_Item__c> items {get;set;}

    public Decimal Order_Total{
        get{
            Decimal total = 0;
            if(items.size()>0){
                for(Purchase_order_Line_Item__c item: items){
                    total += item.Extended_Cost__c;
                }
            }
            return total.setScale(2);
        }
        set;
    }
    

    public Purchase_Order_Generate_PDF_Controller() {}
    public Purchase_Order_Generate_PDF_Controller(ApexPages.StandardController sc) {
        Errors = false;
        po = (Purchase_Order__c) sc.getRecord();
        System.debug('Purchase_Order: '  + po);
        try{
            po = [
                SELECT
                    Id,
                    Supplier_Notes__c,
                    Name,
                    Need_Date__c,
                    Status__c,
                    Order_date__c,
                    Supplier__c,
                    Purchase_order_type__c,
                    Terms__c,
                    Ordered_For__c,
                    Order_Description__c,
                    Supplier_Reference_Number__c,
                    Tracking_Number__c,
                    Warehouse__c,
                    Customer__c,
                    Ship_to_name__c,
                    Ship_to_address__c,
                    Ship_to_City__c,
                    Ship_to_Postal_code__c,
                    Ship_to_Option__c,
                    Shipping_method__c,
                    Ship_to_State__c,
                    Supplier_Contact__c,
                    OwnerId
                FROM Purchase_Order__c WHERE Id =:po.Id
            ];
            System.debug('Purchase_Order: '  + po);
            Apexpages.currentPage().getHeaders().put('content-disposition', 'inline; filename=Purchase Order '+po.Name+'.pdf');

            if((String)po.Supplier__c != null && (String)po.Supplier__c != ''){
                Supplier = [
                    SELECT
                        Id,
                        Name,
                        BillingStreet,
                        BillingCity,
                        BillingState,
                        BillingPostalCode,
                        BillingCountry,
                        BillingStateCode,                   
                        Supplier_ID__c
                    FROM Account WHERE Id =:po.Supplier__c
                ];
            System.debug(Supplier);
            }else{
                Errors = True;
                ApexPages.addMessage(new 
                    ApexPages.Message(ApexPages.Severity.ERROR, 
                'Verify that the Supplier field is not empty'));
            }

            User U = [SELECT Full_Name__c FROM User WHERE Id =:po.OwnerId ];
            OwnerName = U.Full_Name__c;
            System.debug('Owner Full Name: ' + OwnerName);            

            Company = [
                SELECT    
                    Id,
                    Name,
                    Street,
                    City,
                    State,
                    PostalCode,
                    Country,
                    StateCode,
                    CountryCode,
                    Phone,
                    Fax 
                FROM Organization WHERE Id = :UserInfo.getOrganizationId()
            ];
            System.debug(Company);
    
            items = (List<Purchase_order_Line_Item__c>)[
                SELECT 
                    Id,
                    Name,
                    Purchase_Order__c,
                    Part_Number__c,
                    Part_Number__r.Name,
                    Order_Qty__c,
                    Quantity_Received__c,
                    Unit_of_Measure__c,
                    Actual_Cost__c,
                    Warehouse__c,
                    Warehouse__r.Name,
                    Status__c,
                    Need_date__c,
                    Extended_Cost__c,
                    Supplier_Part_Number__c,
                    Part_Description__c,
                    Unknown_Part_Description__c,
                    Unknown_Supplier_Part_Number__c,
                    Work_Order__c,
                    Work_Order__r.WorkOrderNumber
                FROM Purchase_order_Line_Item__c WHERE Purchase_Order__c =:po.Id
            ];
            System.debug('Purchase_order_Line_Item: ' + items);

        }catch(Exception ex){
            Errors = True;
            ApexPages.addMessage(new 
                ApexPages.Message(ApexPages.Severity.ERROR, 
               'Ah an error occurred'));
            System.debug(ex);
        }
    }
}