public with sharing class Estimate_Clone_Controller {
    @AuraEnabled
    public static String Clone_Estimate(String Id){
        String retunrvalues;
        Estimate__c EstimateInsert;
        Estimate_line_Item__c ItemAux;
        List<Estimate_line_Item__c> ListETI = new List<Estimate_Line_Item__c>();
        try{
            
            Estimate__c Estimate = [
                SELECT 
                    Id,Name,Status__c,Revision__c,Sold_to_Customer__c,Case__c,Estimate_Description__c,Estimate_Date__c,Original_Estimate_Date__c,Margin__c,Invoice_Contact__c,Client_Comments__c,Internal_Comments__c,Unit__c,Estimate_Valid_until__c,Warehouse__c,Order_Type__c,Sales_Rep__c,Discount__c,Ship_to_Company_name__c,Ship_to_Street_Address__c,Ship_to_City__c,Ship_to_State__c,Ship_to_Zip_code__c,Bill_to_Company_Name__c,Bill_to_street_address__c,Bill_to_City__c,Bill_to_State__c,Bill_to_Zip_code__c,Estimate_Selling_Price__c,Estimate_Suggested_Price__c,Estimate_Total_w_suggested__c,Estimate_Contact__c,Total_Discount__c 
                FROM  Estimate__c WHERE Id=:Id
            ];

            EstimateInsert = Estimate.clone(false, false, false, false);

            List<Estimate_line_Item__c> ELI = [
                SELECT 
                    Id,Name,Estimate__c,Part_number__c,Seq__c,Quantity__c,Description__c,Suggested__c,UOM__c,Price__c,Est_Price__c,Price_Type__c,Regular_Cost__c,Freight_in__c,Bid_Cost__c,Total_Price__c,Regular_Price__c,Selling_Price__c,Margin__c,Landed_cost__c,Standard_Cost__c,Unknown_Part_Name__c,Part_Number_Family__c,Part_Number_Description__c,Adjusted_Margin__c,Selling_Price_Formula__c,Total_Price_Formula__c,Standard_Cost_Formula__c,Actual_Margin__c
                FROM Estimate_line_Item__c WHERE Estimate__c = :Id
            ];

            Insert EstimateInsert;
            System.debug('new Estimate ' + EstimateInsert.id);
            for(Estimate_line_Item__c item : ELI){
                ItemAux = item.clone(false, false, false, false);
                ItemAux.Estimate__c = EstimateInsert.Id;
                ListETI.add(ItemAux);
            }

            
            if(ListETI.size() > 0){
                Insert ListETI;
            }
            retunrvalues = EstimateInsert.Id;
        }catch(Exception e){
            retunrvalues = 'Error';
            System.debug('Error Line: ' + e.getLineNumber());
            System.debug('Error Message: ' + e.getMessage());
        }
        return retunrvalues;
    }
}