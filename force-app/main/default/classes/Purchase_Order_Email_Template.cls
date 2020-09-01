public class Purchase_Order_Email_Template {
    @AuraEnabled
    public static String send_email_template_PO(String Id){
        String retunrvalues;
        try{
            Purchase_Order__c Order = [
                SELECT 
                    Id,
                    Name,
                    Supplier_Contact__c,
                    Supplier__c,
                    Status__c
                FROM Purchase_Order__c WHERE Id = :Id
            ];
            System.debug(Order);
            if( (String)Order.Supplier__c != null && (String)Order.Supplier__c != '' ){
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                Messaging.EmailFileAttachment pdf = new Messaging.EmailFileAttachment();

                PageReference pref = Page.Purchase_Order_Generate_PDF_VFP;
                pref.getParameters().put('id',Order.Id);
                Blob b = !test.isRunningTest() ? pref.getContent() : Blob.valueof('test');
                pdf.setFileName('Purchase Order ' + Order.Name +'.pdf');
                pdf.setBody(b);
                message.setFileAttachments(new Messaging.EmailFileAttachment[]{pdf});

                message.setTargetObjectId(Order.Supplier_Contact__c); 
                message.setSenderDisplayName('Cobal Truck'); 
                message.setReplyTo('no-reply@cobalttruck.com');
                message.setUseSignature(false); 
                message.setBccSender(false); 
                message.setSaveAsActivity(false); 
                EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where name = 'Purchase_Order_Email_VFP'];
                message.setTemplateID(emailTemplate.Id); 
                message.setWhatId(Order.Id);
                
                Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                System.debug(results);
                if (results[0].success) 
                {
                    Order.Status__c = 'Submitted';
                    update Order;

                    retunrvalues =  'Mail successfully sent, ' + 'file: Purchase Order ' + Order.Name +'.pdf';

                } else {
                    System.debug('The email failed to send: ' +  results[0].errors[0].message);
                    retunrvalues =  'The email failed to send, Verify that the Supplier Contact field is not empty';
                }
            }else{
                retunrvalues =  'Supplier and Supplier Contact must be populated';
            }
            
        }catch (Exception e){
            retunrvalues =  'The email failed to send, Verify that the Supplier Contact field is not empty';
            System.debug('Error Line: ' + e.getLineNumber());
            System.debug('Error Message: ' + e.getMessage());
        }
            
        return retunrvalues;
    }
}