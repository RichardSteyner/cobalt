/*GET EXAMPLE RECORDS*/
List<String> ListObject = new List<String> {
                        'Estimate__c','Estimate_Line_Item__c','Invoice__c','Invoice_line_item__c','Purchase_Order__c','Purchase_order_Line_Item__c',    'Payment__c','State_Code__c','Account','Account','WorkOrder','WorkOrderLineItem','ServiceAppointment','ProductConsumed','ProductRequired','Location','ProductItem','ProductItemTransaction','Product2','Contact'};

Map<String,List<sObject>> ListData = new Map<String,List<sObject>>();

List<sObject> temp;
String allFields;
for(String objectName : ListObject){
    allFields = '';
    Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    Map<String, Schema.SObjectField> fieldMap = schemaMap.get(objectName).getDescribe().fields.getMap();
    Set<string> mapset = fieldMap.keyset();
    for ( String str : mapset ){
        allFields += str +', ';
    }

    String query = 'SELECT '+ allFields.removeEnd(', ') + ' FROM ' + objectName + ' ORDER BY LastModifiedDate DESC LIMIT 30 ';
    temp  = Database.query(query);
    ListData.put(objectName,temp);
}




/*GET LAYOUT INFORMATION*/
List<String> ListLayouts = new List<String> {
                                    'Estimate__c-Estimate Layout','Estimate_Line_Item__c-Estimate Line Items Layout','Invoice__c-Invoice Layout','Invoice_line_item__c-Invoice line item Layout','Purchase_Order__c-Purchase order Layout','Purchase_order_Line_Item__c-Purchase order Line Item Layout','Payment__c-Payment Layout','State_Code__c-State Code Layout','Account-Customer','Account-Supplier','WorkOrder-Work Order Layout','WorkOrderLineItem-Work Order Line Item Layout','ServiceAppointment-Service Appointment Layout','ProductConsumed-Product Consumed Layout','ProductRequired-Product Required Layout','Location-Location Layout','ProductItem-Product Item Layout','ProductItemTransaction-Product Item Transaction Layout','Product2-Product Layout','Contact-Contact Layout'
                                };
String columns= '';
String objname;
String Layout;
List<String> fields; 
Map<String,String> finalValues = new Map<String,String>();
for(String l : ListLayouts){
    columns= '';
    objname = l.split('-')[0];
    List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, new list<String>{l});
    Metadata.Layout layoutMd =  (Metadata.Layout)  layouts.get(0);
    Layout = layoutMd.fullName;
    for (Metadata.LayoutSection section : layoutMd.layoutSections) {
        for (Metadata.LayoutColumn column : section.layoutColumns) {
            if (column.layoutItems != null) {
                for (Metadata.LayoutItem item : column.layoutItems) {
                    if(String.valueOf(item.behavior) != 'Readonly'){
                        if(item.field != null && item.field != 'null')
                            columns += item.field + ',';
                    }
                }
            }
        }
    }
    if(objname == 'Account'){
        columns += 'BillingStreet,BillingCity,BillingState,BillingPostalCode,BillingCountry,ShippingStreet,ShippingCity,ShippingState,ShippingPostalCode,ShippingCountry,';
        columns = columns.replace('ShippingAddress,','');
        columns = columns.replace('BillingAddress,','');
    }

    fields = columns.split(',');
    temp = ListData.get(objname);
    columns = columns.removeEnd(',') + '\n';
    for(sObject o : temp){
        if(o != null){
            for(String f : fields){
                try{
                    columns += String.valueOf(o.get(f)).escapeCsv() + ',';
                }catch(Exception e){
                    columns += ',';
                    System.debug(e.getMessage());
                }
            }
            columns = columns.removeEnd(',') + '\n';
        }
    }
    
    finalValues.put(Layout,columns);
}


/*SEND EMAIL*/
List<Messaging.EmailFileAttachment> Att =  new List<Messaging.EmailFileAttachment>();
Messaging.EmailFileAttachment fileattac;
for(String val : finalValues.keySet()){
    fileattac = new Messaging.EmailFileAttachment();
    Blob file = Blob.valueOf(finalValues.get(val));
    fileattac.setFileName(val + '.csv');
    fileattac.setBody(file);
    Att.add(fileattac);
}

Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
mail.setToAddresses(new String[] {'rurupeque@cloudcreations.com'});
mail.setSubject('Headers Import');
mail.setPlainTextBody('');
mail.setFileAttachments(Att);

Messaging.SendEmailResult[] results =  Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});