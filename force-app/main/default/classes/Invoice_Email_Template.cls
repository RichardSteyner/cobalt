public with sharing class Invoice_Email_Template {
    @AuraEnabled
    public static String send_email_template_Invoice(String Id){
        String retunrvalues;
        try{
            Invoice__c Invoice = [
                SELECT 
                    Id,
                    Name,
                    Invoice_Contact__c,
                    Status__c,
                    Invoice_Date__c
                FROM Invoice__c WHERE Id = :Id
            ];
            System.debug(Invoice);
            if( (String)Invoice.Invoice_Contact__c != null && (String)Invoice.Invoice_Contact__c != '' ){
                System.debug(Invoice.Invoice_Date__c);
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                Messaging.EmailFileAttachment pdf = new Messaging.EmailFileAttachment();

                PageReference pref = Page.Invoice_Generate_PDF_VFP;
                pref.getParameters().put('id',Invoice.Id);
                pref.getParameters().put('fakedate',String.valueOf(Date.today()));
                Blob b = !test.isRunningTest() ? pref.getContent() : Blob.valueof('test');
                pdf.setFileName('Invoice ' + Invoice.Name +'.pdf');
                pdf.setBody(b);
                message.setFileAttachments(new Messaging.EmailFileAttachment[]{pdf});

                message.setTargetObjectId(Invoice.Invoice_Contact__c); 
                message.setSenderDisplayName('Cobal Truck'); 
                message.setReplyTo('no-reply@cobalttruck.com');
                message.setUseSignature(false); 
                message.setBccSender(false); 
                message.setSaveAsActivity(false); 
                EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where name = 'Invoice_Email_VFP'];
                message.setTemplateID(emailTemplate.Id); 
                message.setWhatId(Invoice.Id);
                
                Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                System.debug(results);
                if (results[0].success) 
                {
                    Invoice.Status__c = 'Emailed';
                    Invoice.Invoice_Date__c = Date.today();
                    update Invoice;
                    retunrvalues =  'Mail successfully sent, ' + 'file: Invoice ' + Invoice.Name +'.pdf';

                } else {
                    System.debug('The email failed to send: ' +  results[0].errors[0].message);
                    retunrvalues =  'The email failed to send, Verify that the Supplier Contact field is not empty';
                }
            }else{
                retunrvalues =  'Invoice Contact must be populated';
            }
            
        }catch (Exception e){
            retunrvalues =  'The email failed to send, Verify that the Supplier Contact field is not empty';
            System.debug('Error Line: ' + e.getLineNumber());
            System.debug('Error Message: ' + e.getMessage());
        }
            
        return retunrvalues;
    }
}