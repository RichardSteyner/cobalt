public with sharing class Estimate_Email_Template {
    @AuraEnabled
    public static String send_email_template_E(String Id){
        String retunrvalues;
        try{
            Estimate__c Estimate = [
                SELECT 
                    Id,Unit__c,Unit__r.Name,Sales_Rep__c,Estimate_Contact__c,Status__c
                FROM Estimate__c WHERE Id = :Id
            ];

            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            Messaging.EmailFileAttachment pdf = new Messaging.EmailFileAttachment();

            PageReference pref = Page.Estimate_Generate_PDF_VFP;
            pref.getParameters().put('id',Estimate.Id);
            Blob b = !test.isRunningTest() ? pref.getContent() : Blob.valueof('test');
            pdf.setFileName('Estimate Unit #' + Estimate.Unit__r.Name +'.pdf');
            pdf.setBody(b);
            message.setFileAttachments(new Messaging.EmailFileAttachment[]{pdf});

            message.setTargetObjectId(Estimate.Estimate_Contact__c); 
            message.setSenderDisplayName('Cobal Truck'); 
            message.setReplyTo('no-reply@cobalttruck.com');
            message.setUseSignature(false); 
            message.setBccSender(false); 
            message.setSaveAsActivity(false); 
            EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where name = 'Estimate_Email_VFP'];
            System.debug('EmailTempalte: '+emailTemplate);
            message.setTemplateID(emailTemplate.Id); 
            message.setWhatId(Estimate.Id);
            
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
            System.debug(results);
            if (results[0].success) 
            {
                Estimate.Status__c = 'Submitted';
                update Estimate;

                Task tsk = new Task();
                tsk.Subject = 'Cobalt Estimate for unit ' + Estimate.Unit__r.Name;
                tsk.WhatId = Estimate.Id;
                tsk.OwnerId = Estimate.Sales_Rep__c;
                tsk.Status = 'Completed';
                tsk.Type = 'Call';
                tsk.ActivityDate = System.today();
                insert tsk;

                Attachment attachment = new Attachment();
                attachment.Body = b;
                attachment.Name = pdf.getFileName();
                attachment.ParentId = tsk.Id; 
                insert attachment;


                retunrvalues =  'Mail successfully sent, ' + 'file: Estimate Unit #' + Estimate.Unit__r.Name +'.pdf';
            } else {
                System.debug('The email failed to send: ' +  results[0].errors[0].message);
                retunrvalues =  'The email failed to send, Verify that the Estimate Contact field is not empty';
            }
            
        }catch (Exception e){
            retunrvalues =  'The email failed to send, Verify that the Estimate Contact field is not empty';
            System.debug('EmailTempalte - Error Line: ' + e.getLineNumber());
            System.debug('EmailTempalte - Error Message: ' + e.getMessage());
        }
            
        return retunrvalues;
    }
}