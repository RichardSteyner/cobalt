@isTest
public class Reduce_Inventario_Test {

    @TestSetup
    static void init(){
        Account a = new Account(Name = 'Test Account');
        insert a;

        Contact c = new Contact(LastName = 'Test Contact',email='test@test.com');
        insert c;

        Asset asset = new Asset(Name = 'Test',AccountId = a.Id);
        insert asset; 

        Schema.Location l = new Schema.Location(Name = 'Test', LocationType = 'Van', IsMobile = true, IsInventoryLocation = true);
        insert l;
        
        Product2 p = new Product2(Name = 'Prod 1',IsActive = true);
        insert p;
        Product2 p2 = new Product2(Name = 'Prod 2',IsActive = true);
        insert p2;
        
        WorkOrder wo = new WorkOrder(Warehouse__c = l.id);
        insert wo;

        ProductItem ProItem = new ProductItem(LocationId = l.Id ,Product2Id = p.Id,QuantityOnHand = 10);
        insert ProItem;

        ProductItemTransaction ProItemT = new ProductItemTransaction(ProductItemId = ProItem.Id,TransactionType = 'consumed',Quantity = 10);
        insert ProItemT;
    }

    @isTest
    static void TestProductRequired(){
        Product2 p = [SELECT Id FROM Product2 WHERE Name = 'Prod 1' Limit 1];
        WorkOrder wo = [SELECT Id FROM WorkOrder Limit 1];

        ProductRequired pr = new ProductRequired();
        pr.ParentRecordId = wo.Id;
        pr.Product2Id = p.Id;
        pr.QuantityRequired = 3;

        Test.startTest();
            Insert pr;
        Test.stopTest();
    }

    @isTest
    static void TestProductConsumed(){
        ProductItem ProItem = [SELECT Id FROM ProductItem LIMIT 1];
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        ProductConsumed pc = new ProductConsumed(QuantityConsumed = 3,UnitPrice = 5,ProductItemId = ProItem.Id, WorkOrderId = wo.id);
        Test.startTest();
            Insert pc;
        Test.stopTest();
    }
}