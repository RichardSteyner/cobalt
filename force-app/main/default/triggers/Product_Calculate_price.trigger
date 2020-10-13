trigger Product_Calculate_price on Product2 (before insert,before update) {
    Map<String,Decimal> MapPickListValues = new Map<String,Decimal>();
    for(Part_Price_Type__c p : Part_Price_Type__c.getall().values()){
        MapPickListValues.put(p.Type__c,p.Value__c);
    }

    Part_Price_Type__c temp;
     
    for (Product2 item : Trigger.new) {
        if(item.Standard_Cost__c != null){
            item.Landed_Cost__c = (item.Standard_Cost__c * 0.055) + item.Standard_Cost__c;

            if(item.Price_type__c == 'LC+2000 (LC+2000)'){
                item.List_price__c = item.Landed_Cost__c + 2000 + item.Landed_Cost__c;
            }else{
                if(MapPickListValues.containsKey(item.Price_type__c)){
                    item.List_price__c = MapPickListValues.get(item.Price_type__c) + item.Landed_Cost_Formula__c;
                }else{
                    item.List_price__c = 0 + item.Landed_Cost__c;
                }
            }
        }else{
            item.addError('Standard Cost is required');
        }
    }


}