@isTest
public class Estimate_Test_Bundle {
    public static Estimate__c Estimate;

    @testSetup
    static void init(){
        Account a = new Account(Name = 'Test Account');
        insert a;
        Contact c = new Contact(LastName = 'Test Contact',email='test@test.com');
        insert c;
        Asset asset = new Asset(Name = 'Test',AccountId = a.Id);
        insert asset; 
        Estimate = new Estimate__c (Sold_to_Customer__c = a.Id,Estimate_Contact__c=c.Id,Sales_Rep__c = UserInfo.getUserId(),Unit__c = asset.Id);
        insert Estimate;
        Estimate_line_Item__c ELI = new Estimate_line_Item__c (Estimate__c = Estimate.Id,Selling_Price__c=12,Total_Price__c = 24,Standard_Cost__c = 12,Quantity__c = 2);
        insert ELI;
    }
    /* Test for Estimate Send Email */
    @isTest 
    static void TestSendEmailSuccess(){
        Test.startTest();        
            Estimate = [SELECT Id FROM Estimate__c limit 1 ];
            String result = Estimate_Email_Template.send_email_template_E(Estimate.Id);
        Test.stopTest();
    }
    @isTest 
    static void TestSendEmailErrorEmail(){
        Contact c = [SELECT Id,email FROM Contact limit 1];
        c.email = null;
        update c;
        Test.startTest();
            Estimate = [SELECT Id FROM Estimate__c limit 1];
            String result = Estimate_Email_Template.send_email_template_E(Estimate.Id);
        Test.stopTest();
    }
    @isTest 
    static void TestSendEmailError(){
        Test.startTest();        
            Estimate = new Estimate__c ();
            String result = Estimate_Email_Template.send_email_template_E(Estimate.Id);
        Test.stopTest();
    }

    
    /* Test for Estimate Visualforce */
    @isTest
    static void TestVisualforceSuccess(){
        Estimate = [SELECT Id FROM Estimate__c limit 1 ];
        Estimate_Generate_PDF_Controller pdf = new Estimate_Generate_PDF_Controller();
        ApexPages.StandardController sc = new ApexPages.StandardController(Estimate);
        pdf = new Estimate_Generate_PDF_Controller(sc);
        String owner = pdf.OwnerName;
    }

    @isTest
    static void TestVisualforceError(){
        Estimate =  new Estimate__c ();
        ApexPages.StandardController sc = new ApexPages.StandardController(Estimate);
        Estimate_Generate_PDF_Controller pdf = new Estimate_Generate_PDF_Controller(sc);
    }

    /* Clone Estimate Zone Test */
    @isTest
    static void TestCloneObjectSuccess() {
        Test.startTest();
            Estimate = [SELECT Id FROM Estimate__c limit 1 ];
            Id result = Estimate_Clone_Controller.Clone_Estimate(Estimate.id);
            System.assertEquals(Estimate__c.sObjectType, result.getsobjecttype());
        Test.stopTest();
    }
    @isTest
    static void TestCloneObjectError() {
        Test.startTest();
            String result = Estimate_Clone_Controller.Clone_Estimate('aaabbbccccaasd');
            System.assertEquals('Error', result);
        Test.stopTest();
    }
}