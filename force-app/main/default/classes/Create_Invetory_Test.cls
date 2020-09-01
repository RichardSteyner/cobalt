@isTest
public class Create_Invetory_Test {
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

        Schema.Location l = new Schema.Location(Name = 'Test', LocationType = 'Van', IsMobile = true, IsInventoryLocation = true);
        insert l;
        
        Product2 p = new Product2(Name = 'Prod 1',IsActive = true);
        insert p;
        Product2 p2 = new Product2(Name = 'Prod 2',IsActive = true);
        insert p2;

        Purchase_order_Line_Item__c poi = new Purchase_order_Line_Item__c (Purchase_Order__c = po.Id,Warehouse__c = l.Id,Part_Number__c = p.Id,Quantity_Received__c = 20);
        insert poi;
    }
    @isTest
    static void TestErrorDuplicateItem(){
        Test.startTest();
            try{
                po = [SELECT Id FROM Purchase_Order__c limit 1 ];
                Product2 p = [SELECT Id FROM Product2 WHERE Name = 'Prod 1' Limit 1];
                Schema.Location l = [SELECT Id FROM Location WHERE Name = 'Test' Limit 1];
                Purchase_order_Line_Item__c poi = new Purchase_order_Line_Item__c (Purchase_Order__c = po.Id,Warehouse__c = l.Id,Part_Number__c = p.Id);
                insert poi;
            }catch(Exception e){            
                Boolean expectedExceptionThrown =  e.getMessage().contains('This product bellow to an existent PO') ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }
        Test.StopTest();
    }
    @isTest
    static void TestErrorDuplicateItemUpdate(){
        Schema.Location l = new Schema.Location(Name = 'Test2', LocationType = 'Warehouse');
        insert l;
        Product2 p = [SELECT Id FROM Product2 WHERE Name = 'Prod 2' Limit 1];
        Purchase_order_Line_Item__c poi = [SELECT Id FROM Purchase_order_Line_Item__c Limit 1];
        poi.Part_Number__c = p.id;
        
        Test.startTest();
            try{
                update poi;
            }catch(Exception e){            
                Boolean expectedExceptionThrown =  e.getMessage().contains('The product or warehouse cannot be changed') ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }
        Test.StopTest();
    }
    @isTest
    static void TestCreateInventory(){
        Purchase_order_Line_Item__c poi = [SELECT Id FROM Purchase_order_Line_Item__c Limit 1];
        poi.status__c = 'Partially Received';
        
        Test.startTest();
            update poi;
        Test.StopTest();
    }
}