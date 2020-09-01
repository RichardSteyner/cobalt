trigger Time_Sheet_Entry_Update_WOL_Actual on TimeSheetEntry (after insert,after update) {

    for( TimeSheetEntry TSE : Trigger.new ){

        if(TSE.WorkOrderLineItemId != null && TSE.Status == 'Approved' ) {
            if( (Trigger.oldMap.get(TSE.Id).Status != null  || Trigger.oldMap.get(TSE.Id).Status == 'Submitted' ) && TSE.Status == 'Approved')
            {
                TimeSheetEntry temp = [
                    SELECT Duration__C FROM  TimeSheetEntry WHERE Id = :TSE.id
                ];

                System.debug('Duration: '+temp.Duration__C);
                WorkOrderLineItem WOItem = [
                    SELECT Id,Actual_Labor__c,Actual_Travel__c	 FROM WorkOrderLineItem  WHERE id = :TSE.WorkOrderLineItemId
                ];

                if(TSE.Type == 'Travel'){
                    WOItem.Actual_Travel__c = WOItem.Actual_Travel__c != null ? WOItem.Actual_Travel__c + temp.Duration__c : temp.Duration__c;
                    System.debug('Added Actual_Travel__c: ' + WOItem.Actual_Travel__c);
                }

                if(TSE.Type == 'Labor'){
                    WOItem.Actual_Labor__c = WOItem.Actual_Labor__c != null ? WOItem.Actual_Labor__c + temp.Duration__c : temp.Duration__c;
                    System.debug('Added Actual_Labor__c: ' + WOItem.Actual_Labor__c);
                }
            
                update WOItem;  
            }
        }
        
    }

}