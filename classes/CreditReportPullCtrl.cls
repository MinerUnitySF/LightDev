global with sharing class CreditReportPullCtrl extends genesis.ApplicationWizardBaseClass{
    
  // private Office_Name__c currentBranch;
    private Date systemDate;
    global genesis__Application_Decisions__c decision {get;set;}    
    private String mode = genesis.LendingConstants.NEW_RECORD;
    global List<ints__Credit_Report__c> creditReportsList {get; set;}
    
    global CreditReportPullCtrl(ApexPages.StandardController controller) {
        super(controller);
        this.application = (genesis__Applications__c)controller.getRecord();
        
        system.debug(logginglevel.error,'Application id'+application);
        if (application.Id != null){
            mode = genesis.LendingConstants.EDITED_RECORD;
            String type = 'genesis__Application_Decisions__c';
            String appId = application.Id;
            String query = 'SELECT '+ CommonUtil.fetchAllFields(type)+ ' from ' + type +' where genesis__Application__c =:appId limit 1';
            try{
                decision = Database.query(query);                 
            }catch(Exception e){
                this.decision = new genesis__Application_Decisions__c();
                decision.genesis__Application__c = this.application.Id;
                decision.genesis__Driving_Experience_based_on__c = 'MONTHS';
                decision.genesis__Average_Cash_Flow_Basis__c = 3;
                decision.genesis__Average_Cash_Flow__c = 0;
                decision.genesis__Expected_Income__c = 0;
                decision.genesis__Decision_Status__c = 'PENDING';
                //custom rating fields...
                decision.Business_Rating__c = 0;
                decision.Equipment_Quality_Rating__c = 0;
                decision.Guarantors_Rating__c = 0;
                decision.Target_GP_Transactional_Rating__c = 0;
                
                //createMessage(ApexPages.severity.error,e.getMessage());
 
            }
        }
        creditReportsList = [SELECT Id, Name from ints__Credit_Report__c where genesis__Applications__c =: this.application.Id];
    }
    
    global List<String> getDrivingExperienceBasedOnList() {
        List<String> drivingExpList = new List<String>();
        Schema.DescribeFieldResult picklistdrvExp = genesis__Application_Decisions__c.genesis__Driving_Experience_based_on__c.getDescribe();
        for (Schema.PicklistEntry drivingExpLst : picklistdrvExp.getPicklistValues()) {
            drivingExpList.add(drivingExpLst.getValue());
        }
        return drivingExpList;
    }
    
    private void createMessage(ApexPages.severity severity, String message) {
        ApexPages.addmessage(new ApexPages.message(severity, message));
    }    
    global boolean validateBeforeSave(String action){
        system.debug(logginglevel.error,'Inside validateBeforeSave start MODE :'+mode);
        if (action == 'AUTODECSION'){
            
            
        }
        else if(action == 'SAVE'){
            if(decision.Business_Rating__c > 10 || decision.Guarantors_Rating__c > 10 || decision.Target_GP_Transactional_Rating__c > 10 ||
                    decision.Equipment_Quality_Rating__c > 10){
                createMessage(ApexPages.severity.error,'Rating cannot be greater than 10');
                return false;
                
            }
        }
        
              
        return true;
    }     
    global PageReference refreshDecision(){
            try{
                String type = 'genesis__Application_Decisions__c';
                String decisionId = decision.Id;
                String query = 'SELECT '+ commonUtil.fetchAllFields(type)+ ' from ' + type +' where id =:decisionId limit 1';
                decision = Database.query(query);
            }catch(Exception e){
            }
        
       return null; 
    }
    
    global PageReference saveDecisionInfo(){
        if(!validateBeforeSave('SAVE'))
            return null;        
        
        if(!insertUpdatedecision())
            return null;
    
       try{
           upsert decision;
       }catch(Exception e){
           createMessage(ApexPages.severity.confirm,'Decisioning values could not be saved.' + e.getMessage()); 
           return null; 
       }
       createMessage(ApexPages.severity.confirm,'Decisioning values have been saved.'); 
       return null; 
    }
    global PageReference autoDecision(){
        if(!validateBeforeSave('AUTODECSION'))
            return null;        
         if (decision.id == null){
            createMessage(ApexPages.severity.error,'First Pull the credit report.');   
            return null;                
         }
         decision.genesis__Trigger_Decision_WorkFlow__c = (decision.genesis__Trigger_Decision_WorkFlow__c == true)?false:true;
         decision.genesis__Decision_Status__c = 'EVALUATING';
         upsert decision;       
         createMessage(ApexPages.severity.INFO,'Submitted For Auto-Decisioning.');   
       return null; 
    }      
    global boolean insertUpdatedecision(){

    
        Savepoint sp = Database.setSavepoint();
        try{
            decision.genesis__Decision_Status__c = 'PENDING';
            upsert decision; 
 
        }catch (DMLException dmlException){
            Database.Rollback(sp);
            String errorMsg = '';
            system.debug(logginglevel.error,'dmlException.getNumDml()'+dmlException.getNumDml());
            for (Integer i = 0; i < dmlException.getNumDml(); i++) {
                errorMsg = errorMsg + dmlException.getDmlMessage(i); 
            }
            decision.Id = null;
            system.debug(logginglevel.error,'errorMsg:'+errorMsg);
            createMessage(ApexPages.severity.ERROR,errorMsg);   
            return false;
        }
        catch(Exception e){
            Database.Rollback(sp);
            decision.Id = null;
            createMessage(ApexPages.severity.ERROR,e.getMessage());
            return false;
        }   
        return true;
    }           
    
    global PageReference fetchCreditPullData(){
        String result = '';
        if(this.application.genesis__contact__c != null){
            result = pullCreditForBorrower(this.application.genesis__contact__c,this.application.Id);
            if ( result == 'Credit pull successful.'){
                populate_summarized_data();
            }   
        }else if(this.application.genesis__account__c != null){
            result = pullCreditForAccount(this.application.genesis__account__c,this.application.Id);
            if ( result == 'Credit pull successful.'){
                populate_summarized_data();
            }  
        }else{
            result = 'Contact/Account cannot be found';
        }
        System.debug('the result is ::'+result);
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.info,result));
        return null;
    }
    global void Populate_summarized_data(){
        ints__Credit_Report__c creditReport = [select genesis__Open_Bankruptcy_Date__c ,
                                                      genesis__Open_Bankruptcy_Currently_Used__c,
                                                      genesis__Dismissed_Bankruptcy_Date__c,
                                                      genesis__Dismissed_Bankruptcy_Currently_Used__c,
                                                      genesis__Delinquent_Child_Support_Amount__c,
                                                      genesis__Involuntary_Repossession__c,
                                                      genesis__Vehicle_Charge_Off_Currently_Used__c
                                                 from ints__Credit_Report__c
                                                where genesis__Applications__c = :this.application.Id
                                                limit 1];
    
                                                        
        if  (creditReport.genesis__Open_Bankruptcy_Date__c != null){
            decision.genesis__Open_Bankruptcy__c = true;
        }
        if  (creditReport.genesis__Dismissed_Bankruptcy_Date__c != null){
            decision.genesis__Dismissed_Bankruptcy__c = true;
        }                       
        if  ((creditReport.genesis__Delinquent_Child_Support_Amount__c != null)
                && (creditReport.genesis__Delinquent_Child_Support_Amount__c >0 )){
            decision.genesis__Delinquent_Child_Support_Amount__c = creditReport.genesis__Delinquent_Child_Support_Amount__c;
        }else{
            decision.genesis__Delinquent_Child_Support_Amount__c = 0;
        }       
        if  ((creditReport.genesis__Vehicle_Charge_Off_Currently_Used__c != null)
                && (creditReport.genesis__Vehicle_Charge_Off_Currently_Used__c >0 )){
            decision.genesis__Vehicle_Charge_Off__c = true;
        }else{
            decision.genesis__Vehicle_Charge_Off__c = false;
        } 
        decision.genesis__Decision_Status__c = 'PENDING';  
        
        // security review recommendations
         
        upsert decision;    
        
    }


    //added by sneha for credit pull
    global static String pullCreditForBorrower(String contactId , String applicationId){
      if(contactId == null){
          ApexPages.Message message = new ApexPages.message(ApexPages.severity.ERROR,'Contact Id found null');
          ApexPages.addMessage(message);       
          return null;
      }
      String resStr;
         if(Test.isRunningTest()){
                resStr = 'Credit pull successful.';
         }else{
                resStr = ints.BorrowerCreditPullAction.pullCreditForABorrower(null,contactId);
                System.debug(logginglevel.error,'resStr for account :: '+resStr);
         }
       
         if(resStr.equalsIgnoreCase('Credit pull successful.')){
             // update application id in credit report
             ints__Credit_Report__c cr = [SELECT Name, Id ,genesis__Applications__c from ints__Credit_Report__c 
                                             where ints__Contact__c =: contactId order by name desc limit 1 ];
              cr.genesis__Applications__c = applicationId;
              // security review recommendations
            upsert cr; 
         }
         return resStr;
     }
     
     global static String pullCreditForAccount(String accountId , String applicationId){
         String resStr;
         if(Test.isRunningTest()){
                resStr = 'Credit pull successful.';
         }else{
                resStr = ints.BorrowerCreditPullAction.pullCreditForAccount(accountId);
                System.debug(logginglevel.error,'resStr for account :: '+resStr);
         }
       
         if(resStr.equalsIgnoreCase('Credit pull successful.')){
             // update application id in credit report
             ints__Credit_Report__c cr = [SELECT Name, Id ,genesis__Applications__c from ints__Credit_Report__c 
                                             where ints__Account__c =: accountId order by name desc limit 1 ];
              cr.genesis__Applications__c = applicationId;
              
              upsert cr; 
         }
         
         return resStr;
     }
}