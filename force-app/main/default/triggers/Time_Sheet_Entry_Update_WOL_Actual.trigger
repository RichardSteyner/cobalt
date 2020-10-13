trigger Time_Sheet_Entry_Update_WOL_Actual on TimeSheetEntry (after insert,after update) {

    Set<Id> WOIds = new Set<Id>();

    for( TimeSheetEntry TSE : Trigger.new ){
        if(TSE.WorkOrderLineItemId != null && TSE.Status == 'Approved' ) {
            if( (Trigger.oldMap.get(TSE.Id).Status != null  || Trigger.oldMap.get(TSE.Id).Status == 'Submitted' ) && TSE.Status == 'Approved')
            {
                WOIds.add(TSE.WorkOrderLineItemId);
            }

        }
    }

    Map<Id,WorkOrderLineItem> MapWO = new Map<Id,WorkOrderLineItem> ([SELECT Id,Actual_Labor__c,Actual_Travel__c FROM WorkOrderLineItem  WHERE id IN :WOIds]);
    Map<Id,TimeSheetEntry> MapTimeSheetEntry = new Map<Id,TimeSheetEntry>([SELECT Duration__C FROM  TimeSheetEntry WHERE Id IN :Trigger.newMap.keySet()]);

    TimeSheetEntry TSEtemp ;
    WorkOrderLineItem WOItemTemp;

    List<WorkOrderLineItem> UpdateWOL = new List<WorkOrderLineItem>();

    for( TimeSheetEntry TSE : Trigger.new ){
        if( (Trigger.oldMap.get(TSE.Id).Status != null  || Trigger.oldMap.get(TSE.Id).Status == 'Submitted' ) && TSE.Status == 'Approved')
        {
            TSEtemp = MapTimeSheetEntry.get(TSE.id);
            WOItemTemp = MapWO.get(TSE.WorkOrderLineItemId);

            if(TSE.Type == 'Travel'){
                WOItemTemp.Actual_Travel__c = WOItemTemp.Actual_Travel__c != null ? WOItemTemp.Actual_Travel__c + TSEtemp.Duration__c : TSEtemp.Duration__c;
                System.debug('Added Actual_Travel__c: ' + WOItemTemp.Actual_Travel__c);
            }

            if(TSE.Type == 'Labor'){
                WOItemTemp.Actual_Labor__c = WOItemTemp.Actual_Labor__c != null ? WOItemTemp.Actual_Labor__c + TSEtemp.Duration__c : TSEtemp.Duration__c;
                System.debug('Added Actual_Labor__c: ' + WOItemTemp.Actual_Labor__c);
            }
            
            UpdateWOL.add(WOItemTemp);
        }
    }

    if(UpdateWOL.size() > 0) update UpdateWOL;
    /*for( TimeSheetEntry TSE : Trigger.new ){

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
        
    }*/

}