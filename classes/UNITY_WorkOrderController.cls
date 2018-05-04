/**
 * @programer: Rodrigo Birriel
 * @date:      02/04/2016
 */
public class UNITY_WorkOrderController {
    
    public WorkOrder relatedTo { get;
                                         set {
                                             relatedTo = value;
                                             try{
                                                 WorkOrder wo=[SELECT Case.CreatedDate, UNITY_Vendor_Last_Assigned__c, UNITY_Work_Window_Begin__c,UNITY_Work_Window_End__c, UNITY_Assigned_Vendor__r.UNITY_TimeZoneSidKey__c, Account.UNITY_TimeZoneSidKey__c, AccountId

                                                               FROM WorkOrder
                                                               WHERE id =:relatedTo.Id];

                                                  UNITY_Utils.DateTimeZone dtzCreatedDate = UNITY_Utils.getDateTime(wo.Case.CreatedDate, null, WO.Account.UNITY_TimeZoneSidKey__c);
                                                  UNITY_Utils.DateTimeZone dtzAssignedDate;

                                                  if (wo.UNITY_Vendor_Last_Assigned__c != null)
                                                      dtzAssignedDate = UNITY_Utils.getDateTime(wo.UNITY_Vendor_Last_Assigned__c, null, WO.Account.UNITY_TimeZoneSidKey__c);
                                                  else
                                                      dtzAssignedDate = dtzCreatedDate;

                                                  UNITY_Utils.DateTimeZone dtzWindow_Begin = UNITY_Utils.getDateTime(wo.UNITY_Work_Window_Begin__c, null, WO.Account.UNITY_TimeZoneSidKey__c);
                                                  UNITY_Utils.DateTimeZone dtzWindow_End = UNITY_Utils.getDateTime(wo.UNITY_Work_Window_End__c, null, WO.Account.UNITY_TimeZoneSidKey__c);

                                                  CreatedDate = dtzCreatedDate.format; // + ' ' + dtzCreatedDate.displayname;
                                                  AssignedDate = dtzAssignedDate.format; // + ' ' + dtzCreatedDate.displayname;
                                                  Window_Begin = dtzWindow_Begin.format + ' ' + dtzWindow_Begin.displayname;
                                                  Window_End = dtzWindow_End.format + ' ' + dtzWindow_End.displayname;
                                                 //CreatedDate = UNITY_Utils.getDateTime(wo.UNITY_Work_Window_Begin__c,'MM/dd/yyyy HH:mm:ss',WO.Account.UNITY_TimeZoneSidKey__c).localdatetime+'';
                                                 //Window_End = UNITY_Utils.getDateTime(wo.UNITY_Work_Window_End__c,'MM/dd/yyyy HH:mm:ss',WO.Account.UNITY_TimeZoneSidKey__c).localdatetime+'';
                                             
                                             }catch(Exception e){}
                                             List<User> users = [SELECT Name,City,CompanyName,Country,Address,Email,
                                                                 MobilePhone,Phone,State,PostalCode,Street 
                                                                 FROM User
                                                                 WHERE ContactId IN (SELECT Id FROM Contact 
                                                                                WHERE Id =:relatedTo.ContactId)];
                                             
                                             if(!users.isEmpty()){
                                                contactUser = [SELECT Name,City,CompanyName,Country,Address,Email,
                                                            MobilePhone,Phone,State,PostalCode,Street 
                                                            FROM User
                                                            WHERE ContactId IN (SELECT Id FROM Contact 
                                                                                WHERE Id =:relatedTo.ContactId)];   
                                             }
                                         }
                                       }
    
    public User contactUser { set; get;}
    public String CreatedDate{get;set;}
    public String AssignedDate{get;set;}
    public String Window_Begin{get;set;}
    public String Window_End {get;set;}
        
        
}