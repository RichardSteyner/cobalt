@isTest
public class InvoiceLineTrigger_Test {
    
    public static testmethod void test01(){
    	State_Code__c sc = new State_Code__c(Name='Test State Code', Total_Tax_Rate__c=5.0, Labor_Taxable__c=true, Freight_Taxable__c=false);
        insert sc;
        Account acc = new Account(Name='Test Account', State_Tax_Code__c=sc.Id, Type='Competitor', Fleet_Size__c='100 - 199', Industry='Municipal');
        insert acc;
        Invoice__c inv = new Invoice__c(Sold_To_Customer__c=acc.Id);
        insert inv;
        Product2 part = new Product2(Name='Test Part', Family='Parts & Material');
        insert part;
        Invoice_line_item__c item = new Invoice_line_item__c(Invoice__c=inv.Id, Selling_Price__c=100, Quantity__c=10, Part_Number__c=part.Id);
        insert item;
    }
    
    public static testmethod void test02(){
    	State_Code__c sc = new State_Code__c(Name='Test State Code', Total_Tax_Rate__c=5.0, Labor_Taxable__c=true, Freight_Taxable__c=false);
        insert sc;
        Account acc = new Account(Name='Test Account', State_Tax_Code__c=sc.Id, Type='Competitor', Fleet_Size__c='100 - 199', Industry='Municipal');
        insert acc;
        Invoice__c inv = new Invoice__c(Sold_To_Customer__c=acc.Id);
        insert inv;
        Product2 part = new Product2(Name='Test Part', Family='Labor');
        insert part;
        Invoice_line_item__c item = new Invoice_line_item__c(Invoice__c=inv.Id, Selling_Price__c=100, Quantity__c=10, Part_Number__c=part.Id);
        insert item;
    }
    
    public static testmethod void test03(){
    	State_Code__c sc = new State_Code__c(Name='Test State Code', Total_Tax_Rate__c=5.0, Labor_Taxable__c=false, Freight_Taxable__c=true);
        insert sc;
        Account acc = new Account(Name='Test Account', State_Tax_Code__c=sc.Id, Type='Competitor', Fleet_Size__c='100 - 199', Industry='Municipal');
        insert acc;
        Invoice__c inv = new Invoice__c(Sold_To_Customer__c=acc.Id);
        insert inv;
        Product2 part = new Product2(Name='Test Part', Family='Freight');
        insert part;
        Invoice_line_item__c item = new Invoice_line_item__c(Invoice__c=inv.Id, Selling_Price__c=100, Quantity__c=10, Part_Number__c=part.Id);
        insert item;
    }

}