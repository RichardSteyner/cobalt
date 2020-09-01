public with sharing class Invoice_Generate_PDF_Controller {
    public Invoice__c I {get;set;}
    Public Organization Company {get;set;}
    public Boolean Errors {get;set;}
    public list<Invoice_line_item__c> items {get;set;}
    public list<Invoice_line_item__c> items_suggested {get;set;}

    public Invoice_Generate_PDF_Controller() {}
    public Invoice_Generate_PDF_Controller(ApexPages.StandardController sc) {
        Errors = false;
        I = (Invoice__c) sc.getRecord();
        System.debug('Invoice: '  + I);

        try{ 
            I = [
                SELECT 
                    Id,
                    Name,
                    Ship_to_Company_name__c,
                    Ship_to_Street_Address__c,
                    Ship_to_City__c,
                    Ship_to_State__c,
                    Ship_to_Zip_code__c,
                    Bill_to_Company_Name__c,
                    Bill_to_street_address__c,
                    Bill_to_City__c,
                    Bill_to_State__c,
                    Bill_to_Zip_code__c,
                    Sales_Rep__c,
                    Sold_to_Customer__r.Terms__c,
                    Sold_to_Customer__r.Name,
                    Sales_Rep__r.Name,
                    Unit__c,
                    Unit__r.Name,
                    Unit__r.Make__c,
                    Unit__r.Model__c,
                    Unit__r.Year__c,
                    Unit__r.VIN__c	,
                    Client_Comments__c,
                    Order_date__c,
                    Invoice_date__c,
                    Customer_PO__c,
                    Subtotal__c,
                    Sales_Tax__c,
                    Order_Total__c,
                    Hide_Line_items__c,
                    Invoice_Selling_Price__c,
                    Invoice_Suggested_Price__c
                FROM  Invoice__c WHERE Id = :I.Id
            ];
            Apexpages.currentPage().getHeaders().put('content-disposition', 'inline; filename=Invoice ' + I.Name +'.pdf');
            
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
            if(!I.Hide_Line_items__c){
                items = [
                    SELECT 
                        Id,
                        Name,
                        Invoice__c,
                        Part_number__c,
                        Part_number__r.Description,
                        Part_number__r.Name,
                        Seq__c,
                        Quantity__c,
                        Description__c,
                        Suggested__c,
                        UOM__c,
                        Price__c,
                        Selling_Price__c,
                        Price_Type__c,
                        Regular_Cost__c,
                        Freight_in__c,
                        Bid_Cost__c,
                        Total_Price__c,
                        Regular_Price__c,
                        Landed_cost__c,
                        Standard_Cost__c,
                        Unknown_Part_Name__c,
                        Part_Number_Family__c,
                        Part_Number_Description__c,
                        Total_Price_Formula__c,
                        Standard_Cost_Formula__c
                    FROM Invoice_line_item__c WHERE Invoice__c = :I.Id AND Suggested__c=FALSE ORDER BY Seq__c Desc
                ];
                System.debug(items);

                items_suggested = [
                    SELECT 
                        Id,
                        Name,
                        Invoice__c,
                        Part_number__c,
                        Part_number__r.Description,
                        Part_number__r.Name,
                        Seq__c,
                        Quantity__c,
                        Description__c,
                        Suggested__c,
                        UOM__c,
                        Price__c,
                        Selling_Price__c,
                        Price_Type__c,
                        Regular_Cost__c,
                        Freight_in__c,
                        Bid_Cost__c,
                        Total_Price__c,
                        Regular_Price__c,
                        Landed_cost__c,
                        Standard_Cost__c,
                        Unknown_Part_Name__c,
                        Part_Number_Family__c,
                        Part_Number_Description__c,
                        Total_Price_Formula__c,
                        Standard_Cost_Formula__c
                    FROM Invoice_line_item__c WHERE Invoice__c = :I.Id AND Suggested__c=TRUE ORDER BY Seq__c Desc
                ];
                System.debug(items_suggested);
            }
            

        }catch(Exception ex){
            Errors = True;
            ApexPages.addMessage(new 
                ApexPages.Message(ApexPages.Severity.ERROR, 
               'Ah an error occurred'));
            System.debug(ex);
        }
    }
}