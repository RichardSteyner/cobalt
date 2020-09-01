@isTest
public class Invoice_Test_Bundle {
    public static Invoice__c Invoice;
    @TestSetup
    static void init(){
        Account a = new Account(Name = 'Test Account');
        insert a;
        Contact c = new Contact(LastName = 'Test Contact',email='test@test.com');
        insert c;
        Asset asset = new Asset(Name = 'Test',AccountId = a.Id);
        insert asset; 
        Invoice__c Invoice = new Invoice__c (Sold_To_Customer__c = a.Id,Invoice_Contact__c=c.Id,Sales_Rep__c = UserInfo.getUserId());
        insert Invoice;
        Invoice_line_item__c ili = new Invoice_line_item__c (Invoice__c = Invoice.Id);
        insert ili;
    }

     /* Test for Invoice Send Email */
     @isTest 
     static void TestSendEmailSuccess(){
         Test.startTest();        
             Invoice = [SELECT Id FROM Invoice__c limit 1 ];
             String result = Invoice_Email_Template.send_email_template_Invoice(Invoice.Id);
         Test.stopTest();
     }
     @isTest 
     static void TestSendEmailErrorInvoice_Contact(){
         Invoice = [SELECT Id FROM Invoice__c limit 1 ];
         Invoice.Invoice_Contact__c = null;
         update Invoice;
         Test.startTest();
             Invoice = [SELECT Id FROM Invoice__c limit 1];
             String result = Invoice_Email_Template.send_email_template_Invoice(Invoice.Id);
         Test.stopTest();
     }
     @isTest 
     static void TestSendEmailError(){
         Test.startTest();        
             Invoice = new Invoice__c ();
             String result = Invoice_Email_Template.send_email_template_Invoice(Invoice.Id);
         Test.stopTest();
     }
 
     /* Test for Invoice Visualforce */
     @isTest
     static void TestVisualforceSuccess(){
         Invoice = [SELECT Id FROM Invoice__c limit 1 ];
         Invoice_Generate_PDF_Controller pdf = new Invoice_Generate_PDF_Controller();
         ApexPages.StandardController sc = new ApexPages.StandardController(Invoice);
         pdf = new Invoice_Generate_PDF_Controller(sc);
     }
     @isTest
     static void TestVisualforceError(){
         Invoice =  new Invoice__c ();
         ApexPages.StandardController sc = new ApexPages.StandardController(Invoice);
         Invoice_Generate_PDF_Controller pdf = new Invoice_Generate_PDF_Controller(sc);
     }
     @isTest
     static void TestVisualforceErrorSold(){
         Invoice = [SELECT Id FROM Invoice__c limit 1 ];
         Invoice.Sold_To_Customer__c = null;
         update Invoice;
         Test.startTest();
             ApexPages.StandardController sc = new ApexPages.StandardController(Invoice);
             Invoice_Generate_PDF_Controller pdf = new Invoice_Generate_PDF_Controller(sc);
         Test.stopTest();
     }  
}