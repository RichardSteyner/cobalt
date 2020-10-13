trigger Create_Inventory_Trigger on Purchase_Order_Line_Item__c (before insert,before update,after insert,after update) {

    if(Trigger.isBefore){
        if(Trigger.isInsert){
            Invetory_Controller.VerifyProductPOInsert(Trigger.new);
        }

        if(Trigger.isUpdate){
            Invetory_Controller.VerifyProductPOUpdate(Trigger.new,Trigger.oldMap);
        }
    }

    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
        Invetory_Controller.CreateInventory(Trigger.newMap,Trigger.oldMap);
    }

    
}