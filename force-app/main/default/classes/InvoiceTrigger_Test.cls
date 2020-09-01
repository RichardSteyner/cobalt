@isTest
public class InvoiceTrigger_Test {
    
    public static testmethod void test01(){
    	State_Code__c sc = new State_Code__c(Name='Test State Code', Total_Tax_Rate__c=10.0, Labor_Taxable__c=false, Freight_Taxable__c=false);
        insert sc;
        Account acc = new Account(Name='Test Account', State_Tax_Code__c=sc.Id, Type='Competitor', Fleet_Size__c='100 - 199', Industry='Municipal');
        insert acc;
        Invoice__c inv = new Invoice__c(Sold_To_Customer__c=acc.Id);
        insert inv;
    }

}