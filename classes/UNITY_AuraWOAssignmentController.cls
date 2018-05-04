public class UNITY_AuraWOAssignmentController {

      @AuraEnabled
       public static List<VendorWOWrapper> initMethod() {
           List<VendorWOWrapper> returnVendorWOWrapper = new List<VendorWOWrapper>();           
           ID userid = userinfo.getUserId();  
           
           Contact con = [SELECT AccountID FROM Contact WHERE ID IN (SELECT ContactId
                      FROM User 
                     WHERE Id =: userId) LIMIT 1];                
           return getWorkOrdersList(con.AccountID);        
       }   
    
     public static List<VendorWOWrapper> getWorkOrdersList(String accountID) {
           system.debug('>> neli account id >>> ' + accountID);
           ID userid = userinfo.getUserId();  
           system.debug('>> neli userid >>> ' + userid);
         
           List<VendorWOWrapper> returnVendorWOWrapper = new List<VendorWOWrapper>();  
           List<String> args = new String[]{'0','number','###,##0.00'};
           
           List<WorkOrder> wolist =[SELECT ID, WorkOrderNumber,UNITY_Vendor_PIN__c, Priority, AccountId, Account.Name, ContactId,UNITY_Initial_Vendor_PO_Cost__c,
                             UNITY_Work_Window_Begin__c,UNITY_Work_Window_End__c, UNITY_Trade__r.name,UNITY_Work_Description__c, UNITY_Assigned_Vendor__c,
                             UNITY_Assigned_Vendor__r.UNITY_TimeZoneSidKey__c,  Account.UNITY_TimeZoneSidKey__c, UNITY_WO_Retract_Warning_At__c,
                             CaseId, UNITY_Work_Site_Address__c, UNITY_Work_Site_for_Community__c, UNITY_Case_Thread_Id__c    
                             FROM WorkOrder
                             WHERE  UNITY_Assigned_Vendor__c = : accountID
                                    AND UNITY_Vendor_Status__c =: UNITY_Constants.WO_VENDOR_STATUS_ASSIGNED];
         
           for (WorkOrder wo : wolist)  {
               VendorWOWrapper wor = new VendorWOWrapper();                 
               
               UNITY_Utils.DateTimeZone dtzCreatedDate = UNITY_Utils.getDateTime(wo.UNITY_Work_Window_Begin__c, null, wo.Account.UNITY_TimeZoneSidKey__c);
               UNITY_Utils.DateTimeZone dtzWindow_End = UNITY_Utils.getDateTime(wo.UNITY_Work_Window_End__c, null, wo.Account.UNITY_TimeZoneSidKey__c);               
               wor.createdDate = dtzCreatedDate.format + ' ' + dtzCreatedDate.displayname;
               wor.window_End = dtzWindow_End.format + ' ' + dtzWindow_End.displayname; 
               
                DateTime tempDateTime = wo.UNITY_WO_Retract_Warning_At__c;
                UNITY_Utils.DateTimeZone dtzRetracAtDate = UNITY_Utils.getDateTime(wo.UNITY_WO_Retract_Warning_At__c, null, null);  //wo.UNITY_WO_Retract_Warning_At__c
                wor.deadlinePerformWork = dtzRetracAtDate.format + ' ' + dtzRetracAtDate.displayname;    
               
                if (wo.UNITY_Initial_Vendor_PO_Cost__c != null)
                       wor.doNotExceedAmount = String.format(wo.UNITY_Initial_Vendor_PO_Cost__c.format(), args);                         
            	       
                wor.workOrder = wo;
                wor.workOrderID = String.valueOf(wo.ID);  
                             
                wor.tradeName = wo.UNITY_Trade__r.name;
                wor.acceptChecked = false;
                wor.rejectChecked = false;
                wor.acceptDisabled = false;
                wor.rejectDisabled = false;
                returnVendorWOWrapper.add(wor);
           }          
        
           return returnVendorWOWrapper;         
       }   
  
    @AuraEnabled
    public static  List<String> updateWorkOrdersStatusBySendingEmail(List<String> workOrdersIDs){  
        List <string> workOrdersID = sendReplayEmails(workOrdersIDs);
        return workOrdersID;
    }
     private static List<String> sendReplayEmails(List<String> workOrdersIDs){
        ID userid = userinfo.getUserId();  
      
        List<string> workOrdersID = new List<String>();        
        String emailQueue;         
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();          
       
             for (String emailData: workOrdersIDs){
                 String[] splitcaseIdPinWOs = emailData.split('\\,');
                 String woNum ='', caseID ='', pin ='',  ref ='', status = '', woID ='';
                 
                 if (splitcaseIdPinWOs.size() == 6){
                     woNum = splitcaseIdPinWOs[0];                     
                     caseID = splitcaseIdPinWOs[1];                     
                     pin = splitcaseIdPinWOs[2];                     
                     ref = splitcaseIdPinWOs[3];                     
                     status = splitcaseIdPinWOs[4];   
                     woID = splitcaseIdPinWOs[5];                      
                   
                     Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                     
                     List<String> sendTo = new List<String>();                     
                     emailQueue = Label.EmailAddressQueue;  
                     sendTo.add(emailQueue);
                     mail.setToAddresses(sendTo);
                     
                     String subject ='RE: Work Order Assigned ' + woNum + ' PIN ' + pin + '[' + ref +']';                      
                     mail.setSubject(subject);
                     mail.setBccSender(false);
                     mail.setPlainTextBody(status);
                     mail.setHtmlBody(status);                    
                     mail.setWhatId (caseID);  
                     //mail.saveAsActivity  = false;
                     //mail.setTargetObjectId(userid);
                     
                     emailList.add(mail);
                 
                     system.debug('>> neli >>add email >>>' + mail);     
                     workOrdersID.add(woID);
                 }                  
             }
       
         Boolean errorSenEmails = false;
        
         if (emailList.size() > 0){
             Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);         
             Messaging.SendEmailError[] errors = new List<Messaging.SendEmailError>();
             Set<ID> targetIdsFailed = new Set<ID>();
             
             for( Messaging.SendEmailResult currentResult : results ){
                 if (! currentResult.IsSuccess()){
                   errors = currentResult.getErrors();
                    system.debug('>>>> errors >>>> '+ errors );
                      if( null != errors ) {
                        errorSenEmails = true; 
                        //targetIdsFailed.add(errors[0].getTargetObjectId());
                     }
                   }
               }
         }
        system.debug('>>>>  errorSenEmails >>>> '+ errorSenEmails );
        if (errorSenEmails) 
             return workOrdersID = new List<String>();
         else
            return workOrdersID;        
    }  
    
    public class VendorWOWrapper{             
        @AuraEnabled
        public WorkOrder workOrder {get;set;}
        @AuraEnabled
        public String workOrderID{get;set;}       
        @AuraEnabled
        public String createdDate{get;set;}        
        @AuraEnabled
        public User contactUser { set; get;}         
        @AuraEnabled
        public String window_End {get;set;} 
        @AuraEnabled 
        public string deadlinePerformWork {get;set;}    
		@AuraEnabled
        public String doNotExceedAmount {get;set;}   
        @AuraEnabled
        public String tradeName {get;set;}
        @AuraEnabled
        public boolean acceptChecked {get;set;}
        @AuraEnabled
        public boolean rejectChecked {get;set;}
         @AuraEnabled
        public boolean acceptDisabled {get;set;}
        @AuraEnabled
        public boolean rejectDisabled {get;set;}
      }  
}