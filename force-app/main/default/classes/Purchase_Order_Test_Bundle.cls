@isTest
public class Purchase_Order_Test_Bundle {
    public static Purchase_Order__c po;
    @TestSetup
    static void init(){
        Account a = new Account(Name = 'Test Account');
        insert a;
        Contact c = new Contact(LastName = 'Test Contact',email='test@test.com');
        insert c;
        Asset asset = new Asset(Name = 'Test',AccountId = a.Id);
        insert asset; 
        Purchase_Order__c po = new Purchase_Order__c(Supplier__c = a.Id,Supplier_contact__c=c.Id);
        insert po;
        Purchase_order_Line_Item__c poi = new Purchase_order_Line_Item__c (Purchase_Order__c = po.Id);
        insert poi;
    }

    /* Test for Purchase Order Send Email */
    @isTest 
    static void TestSendEmailSuccess(){
        Test.startTest();        
            po = [SELECT Id FROM Purchase_Order__c limit 1 ];
            String result = Purchase_Order_Email_Template.send_email_template_PO(po.Id);
        Test.stopTest();
    }
    @isTest 
    static void TestSendEmailErrorSupplier(){
        po = [SELECT Id FROM Purchase_Order__c limit 1 ];
        po.Supplier__c = null;
        update po;
        Test.startTest();
            po = [SELECT Id FROM Purchase_Order__c limit 1];
            String result = Purchase_Order_Email_Template.send_email_template_PO(po.Id);
        Test.stopTest();
    }
    @isTest 
    static void TestSendEmailError(){
        Test.startTest();        
            po = new Purchase_Order__c ();
            String result = Purchase_Order_Email_Template.send_email_template_PO(po.Id);
        Test.stopTest();
    }

    /* Test for Purchase Visualforce */
    @isTest
    static void TestVisualforceSuccess(){
        po = [SELECT Id FROM Purchase_Order__c limit 1 ];
        Purchase_Order_Generate_PDF_Controller pdf = new Purchase_Order_Generate_PDF_Controller();
        ApexPages.StandardController sc = new ApexPages.StandardController(po);
        pdf = new Purchase_Order_Generate_PDF_Controller(sc);
        String owner = pdf.OwnerName;
        Decimal Order_Total  = pdf.Order_Total;
    }
    @isTest
    static void TestVisualforceError(){
        po =  new Purchase_Order__c ();
        ApexPages.StandardController sc = new ApexPages.StandardController(po);
        Purchase_Order_Generate_PDF_Controller pdf = new Purchase_Order_Generate_PDF_Controller(sc);
    }
    @isTest
    static void TestVisualforceErrorSupplier(){
        po = [SELECT Id FROM Purchase_Order__c limit 1 ];
        po.Supplier__c = null;
        update po;
        Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(po);
            Purchase_Order_Generate_PDF_Controller pdf = new Purchase_Order_Generate_PDF_Controller(sc);
        Test.stopTest();
    }
}