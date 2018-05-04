global class UNITY_CommunityVendorReportExport implements Schedulable {
    public String templateName {get; set;}
    public String reportName {get; set;}
    
    public UNITY_CommunityVendorReportExport(String templateName, String reportName){
        this.templateName = templateName;
        this.reportName = reportName;
    }
    
    global void execute(SchedulableContext sc) {
        DoExport(templateName, reportName);        
    }
    
    @future(callout=true)
    public static void DoExport(String templateName, String reportName){
		//Get orgwide email
        List<OrgWideEmailAddress> owe = [SELECT ID, Address FROM OrgWideEmailAddress WHERE DisplayName = 'MNS Vendor Support' AND (NOT Address like '%uat%')];
                             
		//Retrieve email template
        EmailTemplate template = [SELECT Id, Name, Subject FROM EmailTemplate WHERE DeveloperName = : templateName];
        System.debug('@@@DoExport template: ' + template);

        //Retrieve report
        List<Report> reportList = [SELECT Id, Name FROM Report WHERE Name = :reportName];
        system.debug('@@@DoExport reportList'+reportList);
        if (reportList.size() <= 0)
            return;
        Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(reportList[0].Id);
        Reports.ReportMetadata reportMd = describe.getReportMetadata();
        Reports.ReportFilter filter = reportMd.getReportFilters()[0];
        
        //Get Report settings
        Report_Export_Settings__c reportSetting = Report_Export_Settings__c.getValues(reportName);
        
        //Retrieve all vendor accounts enabled for community, use Account email
        List<Account> accountList = [SELECT Id, Account_Email__c, Name, (SELECT AccountId, Email FROM Contacts) FROM Account WHERE isCustomerPortal = true 
                                     AND RecordTypeId in (SELECT Id FROM RecordType WHERE sObjectType='Account' AND Name in ('Vendor'))
                                     AND UNITY_Vendor_Status__c = 'Active'];
        System.debug('@@@DoExport accountList: ' + accountList);
        
        
        //Compose email
      	List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Account acct: accountList){
            if (acct.Contacts.size() <= 0)
                continue; 
            
            String stringId = String.valueOf(acct.Id).substring(0, 15);
            if (reportSetting == null || reportSetting.Results_Required__c == null || (reportSetting.Results_Required__c != null && reportSetting.Results_Required__c)){
                //Run Report and create an attachment
                filter.setValue(stringId);
                Reports.ReportResults results = Reports.ReportManager.runReport(reportList[0].Id, reportMd, true);
               
                //Run Report and get the results, if there are no rows, continue and don't send an email
                Map<String,Reports.ReportFact> factMapResult = results.getFactMap();
                system.debug('@@@DoExport factDetails:'+acct.Name +'-' + factMapResult);
                if (!factMapResult.containsKey('T!T') || factMapResult.get('T!T') == null || factMapResult.get('T!T').getAggregates().size() <= 0 
                    || factMapResult.get('T!T').getAggregates()[0].getValue() ==0){
                    system.debug('@@@DoExport continue for:'+acct.Name);
                    continue;
                }
            }
            
            String contentType = reportSetting == null || reportSetting.Content_Type__c == null? 'application/xls' : reportSetting.Content_Type__c;
            String urlParams = '?excel=1';
            if (contentType.contains('csv'))
                urlParams = '?export=1&enc=UTF-8&xf=csv';
            
            ApexPages.PageReference report = new ApexPages.PageReference('/' + reportList[0].Id + urlParams + '&pv0='+ stringId);
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName(reportSetting == null || reportSetting.Attachment_File_Name__c == null? 'report.xls' : reportSetting.Attachment_File_Name__c); 
            attachment.setContentType(contentType); 
            attachment.setBody(report.getContent()); 

            //Compose email
    	    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
			email.setToAddresses(getContactEmails(acct)); 
	        email.setTargetObjectId(acct.Contacts[0].Id);
            email.setWhatId(acct.Id); 
            email.setTemplateId(template.Id);
            email.setSaveAsActivity(false); 
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment } );
            if (owe.size() > 0)
            	email.setOrgWideEmailAddressId(owe[0].Id);
            emails.add(email);      
		} 
        System.debug('@@@DoExport emails: ' + emails); 
        
        //Send email 
        Messaging.SendEmailResult[] sendEmailResult = Messaging.sendEmail(emails);            
        system.debug('@@@DoExport sendEmailResult'+sendEmailResult);
    }
	
	public static List<String> getContactEmails(Account acct){
        List<String> contactEmails = new List<String>();
        for (Contact c: acct.Contacts){
        	contactEmails.add(c.Email);
        }
        system.debug('@@@DoExport getContactEmails contactEmails:'+contactEmails);
        return contactEmails;
    }
                             
                            
}