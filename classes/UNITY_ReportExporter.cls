global class UNITY_ReportExporter implements System.Schedulable {
    public String reportName {get; set;}
    
    public UNITY_ReportExporter(String reportName){
        this.reportName = reportName;
    }
    global void execute(SchedulableContext sc) {
        DoExport(reportName);        
    }
    @future(callout=true)
    public static void DoExport(String reportName){
        //Retrieve report details
        List<Report> reportList = [SELECT Id, Name FROM Report WHERE Name = :reportName];
        system.debug('@@@DoExport reportList'+reportList);
        if (reportList.size() <= 0)
            return;
        //Retrieve custom report setting
        Report_Export_Settings__c reportSetting = Report_Export_Settings__c.getValues(reportName);
        system.debug('@@@DoExport reportSetting'+reportSetting);
        if (reportList.size() > 0 && reportSetting != null){
            ApexPages.PageReference report = new ApexPages.PageReference('/' + reportList[0].Id + '?export=1&enc=UTF-8&xf=csv');
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName(reportSetting.Attachment_File_Name__c);
            attachment.setBody(report.getContent());
            attachment.setContentType(reportSetting.Content_Type__c);
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment } );
            message.setSubject(reportSetting.Email_Subject__c);
            String body = reportSetting.Email_Body__c == null ? String.valueof(Date.today()) : reportSetting.Email_Body__c + DateTime.now();
            message.setPlainTextBody(body);
            message.setToAddresses( new String[] { reportSetting.Email_Recipient__c } );
            Messaging.SendEmailResult[] sendEmailResult = Messaging.sendEmail( new Messaging.SingleEmailMessage[] { message } );            
            system.debug('@@@DoExport sendEmailResult'+sendEmailResult);
        }
    }
}