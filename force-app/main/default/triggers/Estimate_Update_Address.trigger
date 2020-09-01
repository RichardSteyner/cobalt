trigger Estimate_Update_Address on Estimate__c (before insert) {
    
    Account acc;

    for(Estimate__C item : Trigger.new){

        if(item.Sold_to_Customer__c != null){
            acc = [
                SELECT 
                    BillingStreet,BillingCity,BillingState,BillingPostalCode,ShippingStreet,ShippingCity,ShippingState,ShippingPostalCode,Bill_to_Company_name__c,Ship_to_Company_name__c 
                FROM  Account WHERE Id = :item.Sold_to_Customer__c
            ];

            item.Ship_to_Company_name__c = acc.Ship_to_Company_name__c;
            item.Ship_to_Street_Address__c = acc.BillingStreet;
            item.Ship_to_City__c = acc.BillingCity;
            item.Ship_to_State__c = acc.BillingState;
            item.Ship_to_Zip_code__c = acc.BillingPostalCode;
            item.Bill_to_Company_Name__c = acc.Bill_to_Company_Name__c;
            item.Bill_to_street_address__c = acc.ShippingStreet;
            item.Bill_to_City__c = acc.ShippingCity;
            item.Bill_to_State__c = acc.ShippingState;
            item.Bill_to_Zip_code__c = acc.ShippingPostalCode;
        }

    }

}