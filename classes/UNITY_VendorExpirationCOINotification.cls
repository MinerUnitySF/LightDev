global class UNITY_VendorExpirationCOINotification implements Database.Batchable<sObject>{
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
         Date dateForData = System.today().addDays(61);
         //String accID = '001q000000j4iLg';
         
       String query = 'SELECT Id, UNITY_Account__c, UNITY_Account__r.ID,';
          query+=' UNITY_Account__r.Account_Email__c, UNITY_Expiration_Date__c,'; 
          query+=' UNITY_Insurance_Type__c'; 
          query+=' FROM UNITY_Insurance__c';
         // query+=' WHERE UNITY_Expiration_Date__c <= : dateForData';
          query+=' WHERE UNITY_Account__c IN (SELECT ID FROM Account WHERE UNITY_Vendor_Status__c = ' + '\'Active\'' + ' AND RecordType.Name = ' + '\'Vendor\'' + ')';
          //query+=' WHERE UNITY_Account__c =:accID'; 
          query+=' ORDER BY UNITY_Expiration_Date__c DESC ' ;
          
         return Database.getQueryLocator(query);
    }
     
    global void execute (Database.BatchableContext BC, List<UNITY_Insurance__c> insurances)
    { 
        Contact cnt = new Contact();
        if ( insurances.size() > 0){                        
            cnt = [select id from contact where accountID =: insurances[0].UNITY_Account__r.ID  limit 1]; 
        }
                                      
        List<String> tempNames = new List<String>{'UNITY_COI_Due_to_Expired', 'UNITY_COI_Due_to_Expire_7_days','UNITY_COI_Due_to_Expire_15_days',
                                                        'UNITY_COI_Due_to_Expire_30_days', 'UNITY_COI_Due_to_Expire_60_days'};
       
        String expiredtemp , expire7temp, expire15temp, expire30temp, expire60temp;
            
                for (EmailTemplate emailTemplates : [SELECT Id,  DeveloperName FROM EmailTemplate WHERE DeveloperName IN : + tempNames])
                {
                    if (emailTemplates.DeveloperName == 'UNITY_COI_Due_to_Expired'){
                        expiredtemp = emailTemplates.ID;
                    }
                    else if (emailTemplates.DeveloperName == 'UNITY_COI_Due_to_Expire_7_days'){
                        expire7temp = emailTemplates.ID;
                    }
                    else if (emailTemplates.DeveloperName == 'UNITY_COI_Due_to_Expire_15_days'){
                         expire15temp = emailTemplates.ID;
                    }
                    else if (emailTemplates.DeveloperName == 'UNITY_COI_Due_to_Expire_30_days'){
                        expire30temp = emailTemplates.ID;
                    }
                    else if (emailTemplates.DeveloperName == 'UNITY_COI_Due_to_Expire_60_days'){
                        expire60temp = emailTemplates.ID;
                    }
                }
                
            //=====================================================================================
             insurances = removeDuplicateCIO (insurances);
            //======================================================================================
        
                 for( UNITY_Insurance__c insurance : insurances )
                  {
                        Date expirationDate = insurance.UNITY_Expiration_Date__c;
                        String insuranceType = insurance.UNITY_Insurance_Type__c;
                        Date todayDate = System.today(); 
                        
                        Integer daysBetween = todayDate.daysBetween(expirationDate);  
                        
                        Boolean expired60day =  (daysBetween <= 60 && daysBetween > 30 ? true: false);
                        Boolean expired30day =  (daysBetween <= 30 && daysBetween > 15 ? true: false);
                        Boolean expired15day =  (daysBetween <= 15 && daysBetween > 7 ? true: false);
                        Boolean expired7day =  (daysBetween <= 7 ? true: false);
                        Boolean expired =  (daysBetween < 0 ? true: false);
                        
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        
                            if (expired){
                                  email.setTemplateId(expiredtemp);
                            }
                            else if (expired7day){
                                 email.setTemplateId(expire7temp);
                               
                            }
                            else if (expired15day){
                                 email.setTemplateId(expire15temp);
                               
                            }
                            else if (expired30day){
                                email.setTemplateId(expire30temp); 
                                
                            }
                            else if(expired60day){
                                 email.setTemplateId(expire60temp);
                            }                            
                          
                             email.setWhatId(insurance.ID);
                             email.setSaveAsActivity(false); 
                             email.setToAddresses(new List<String> { insurance.UNITY_Account__r.Account_Email__c });                           
                             email.setTargetObjectId(cnt.ID);
                             
                           if(!Test.isRunningTest())  
                               Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
                    }
    }
    
    global void finish(Database.BatchableContext info){     
    
       
    } 
    
    private static List<UNITY_Insurance__c> removeDuplicateCIO (List<UNITY_Insurance__c> duplicateInsurance ){
        
        List<UNITY_Insurance__c> distinctInsurance= new List<UNITY_Insurance__c>();
        
        for (UNITY_Insurance__c cio: duplicateInsurance){
            Boolean found = false;   
            for(Integer i=0; i< distinctInsurance.size(); i++){
                if (cio.UNITY_Insurance_Type__c.equalsIgnoreCase(distinctInsurance[i].UNITY_Insurance_Type__c)
                            && cio.UNITY_Account__c.equals(distinctInsurance[i].UNITY_Account__c)){
                    found=true;
                    break;
                }
             }
         if(!found)
               distinctInsurance.add(cio);
        }
        
         system.debug('>>> neli >> distinctInsurance >> ' + distinctInsurance);   
         
         Date dateForData = System.today().addDays(61);
         List <UNITY_Insurance__c>  insuratceToExpired  = new List<UNITY_Insurance__c>();
         
         for (UNITY_Insurance__c cio: distinctInsurance){
           if (cio.UNITY_Expiration_Date__c <= dateForData) {
               insuratceToExpired.add(cio);
           } 
         }
        system.debug('>>> neli >> insuratceToExpired >> ' + insuratceToExpired);      
        return insuratceToExpired;
    }
}