public class UNITYPM_AssignVendorCtrlExtension_v1 {
 public ID id {get;  set;}
    public WorkOrder workorder {get; set;}
    public WorkOrder wo {get; set;}
    public id accountID {get;set;}
    public String assignedVendor {get; set;}
    public List<Account> vendorAccountList {get;set;}
      
     public UNITYPM_AssignVendorCtrlExtension_v1 (ApexPages.StandardController controller){
         workorder = (Workorder)controller.getRecord();
         id = (ID) controller.getRecord().get('id'); 
         //id = '0WO3B000000DeAPWA0';
       
         wo = [SELECT Id, AccountID, UNITY_Assigned_Vendor__c, UNITY_Current_PO__c,Status
                                  FROM WorkOrder WHERE ID =:id];
                                  
         accountID = wo.AccountID;
         assignedVendor ='';
         
          if (wo.UNITY_Assigned_Vendor__c != null){
             assignedVendor = wo.UNITY_Assigned_Vendor__c;
         }
      }
     
      public List<SelectOption> getVendorAccounts () {
         List<SelectOption> vendorsList = new List<Selectoption>();
          vendorAccountList = [SELECT ID, Name, UNITY_Vendor_Status__c, RecordType.Name  
                                    FROM Account  
                                    WHERE UNITY_Vendor_Status__c = 'Active' 
                                    AND RecordType.Name ='Vendor'];
              
          for (Account a :vendorAccountList){
              vendorsList.add(new SelectOption(a.Id, a.Name));
         }
                             
         return vendorsList;
     } 
     
      public PageReference assignVendor(){
       wo = [SELECT Id, AccountID, UNITY_Assigned_Vendor__c, UNITY_Current_PO__c,Status
                            FROM WorkOrder WHERE ID =:id  FOR UPDATE];
          if ( wo != null)   {
             wo.UNITY_Assigned_Vendor__c = assignedVendor;
             wo.Status = 'Pending Tech Dispatch';
             wo.UNITY_Current_PO__c= null;
             
             try{ 
                update wo;
                system.debug('@@@@    assignedVendor @@@' + wo.ID);
             }
             catch (Exception ex){
                 Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + ex)); 
             }
          }
          return null;
      }

}