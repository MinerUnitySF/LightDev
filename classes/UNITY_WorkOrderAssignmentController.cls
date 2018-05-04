public class UNITY_WorkOrderAssignmentController{
    public WorkOrder relatedTo{
        get;
        set{
            relatedTo = value;
            try{
                WorkOrder wo=[SELECT ContactId,UNITY_Work_Window_Begin__c,UNITY_Work_Window_End__c, UNITY_Assigned_Vendor__r.UNITY_TimeZoneSidKey__c, Accountid, Account.UNITY_TimeZoneSidKey__c
                              FROM WorkOrder
                              WHERE id =:relatedTo.Id];
                //CreatedDate = UNITY_Utils.getDateTime(wo.UNITY_Work_Window_Begin__c,'MM/dd/yyyy HH:mm:ss',WO.UNITY_Assigned_Vendor__r.UNITY_TimeZoneSidKey__c).formatDate;
                //Window_End = UNITY_Utils.getDateTime(wo.UNITY_Work_Window_End__c,'MM/dd/yyyy HH:mm:ss',WO.UNITY_Assigned_Vendor__r.UNITY_TimeZoneSidKey__c).formatDate; 

                UNITY_Utils.DateTimeZone dtzCreatedDate = UNITY_Utils.getDateTime(wo.UNITY_Work_Window_Begin__c, null, WO.Account.UNITY_TimeZoneSidKey__c);
                UNITY_Utils.DateTimeZone dtzWindow_End = UNITY_Utils.getDateTime(wo.UNITY_Work_Window_End__c, null, WO.Account.UNITY_TimeZoneSidKey__c);

                CreatedDate = dtzCreatedDate.format + ' ' + dtzCreatedDate.displayname;
                Window_End = dtzWindow_End.format + ' ' + dtzWindow_End.displayname;
                
                //.format + ' ' ;
             //   + dtzWindow_End.displayname;

                List<User> users = [SELECT Name,City,CompanyName,Country,Address,Email,ContactID,
                                       MobilePhone,Phone,State,PostalCode,Street 
                                FROM User
                                WHERE ContactId IN (SELECT Id FROM Contact 
                                                    WHERE Id =:wo.ContactId)];
                                      
            if(!users.isEmpty()){
                contactUser = [SELECT Name,City,CompanyName,Country,Address,Email,ContactID,
                                      MobilePhone,Phone,State,PostalCode,Street 
                               FROM User
                               WHERE ContactId IN (SELECT Id 
                                                   FROM Contact 
                                                   WHERE Id =:wo.ContactId)];   
            }
            }catch(Exception e){
            System.Debug('**************************************:'+e);
            Window_End = 'test string'+e; 

            }

        }

   }
   
    public User contactUser { set; get;}
    public String CreatedDate{get;set;}
    public String Window_End {get;set;}
}