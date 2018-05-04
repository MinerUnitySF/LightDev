//Trigger handler class that uses WITHOUT SHARING
public without sharing class UNITY_WorkOrderTriggerHandler_NoSharing {
    
	public static void shareToVendor(List<WorkOrder> workOrders){

        system.debug('@@@shareToVendor workOrders:'+workOrders);
        
		Map<Id, Id> woAndGroupMap = getWOIdAndGroupIdMap(workOrders);

        system.debug('@@@shareToVendor woAndGroupMap:'+woAndGroupMap);

		if (woAndGroupMap == null)
			return;
        
        if (woAndGroupMap.size() > 0){
            List<WorkOrderShare> shareToInsert = new List<WorkOrderShare>();
            for (Id woID : woAndGroupMap.keySet()){
                
                WorkOrderShare woShare = new WorkOrderShare();
                woShare.ParentId = woID;
		        woShare.AccessLevel = 'Read';
		        woShare.RowCause = Schema.OrderShare.RowCause.Manual;
		        woShare.UserOrGroupId = woAndGroupMap.get(woID);
		        shareToInsert.add(woShare);
            }
            system.debug('@@@shareToVendor shareToInsert:'+shareToInsert);
            insert shareToInsert;
        }
    }
        
    public static void unShareToVendor(List<WorkOrder> workOrders){
    	
    	system.debug('@@@unShareToVendor workOrders:'+workOrders);
    	
		Map<Id, Id> woAndGroupMap = getWOIdAndGroupIdMap(workOrders);

        system.debug('@@@unShareToVendor woAndGroupMap:'+woAndGroupMap);
        
		if (woAndGroupMap == null)
			return;

		List<WorkOrderShare> WOShareList = [SELECT ParentId, UserOrGroupId FROM WorkOrderShare 
											WHERE UserOrGroupId in :woAndGroupMap.values() 
											AND RowCause = 'Manual' AND AccessLevel = 'Read'
											AND ParentId in :woAndGroupMap.keySet()];
											
        system.debug('@@@unShareToVendor WOShareList:'+WOShareList);
        
        if (WOShareList.size() > 0){
            delete WOShareList;
        }
    }
    
    //Returns a map of WO ID and the Group ID of the Vendor Account's Role (Community Role)
    public static Map<Id, Id> getWOIdAndGroupIdMap (List<WorkOrder> workOrders){
		Map<Id, Id> result = new Map<Id, Id>();

        system.debug('@@@getWOIdAndGroupIdMap workOrders:'+workOrders);
        
    	Map<Id, List<Id>> acctWOrderMap = new Map<Id,List<Id>>();
        for(WorkOrder wo: workOrders){
            if (!acctWOrderMap.containsKey(wo.UNITY_Assigned_Vendor__c))
                acctWOrderMap.put(wo.UNITY_Assigned_Vendor__c, new List<Id>());
    		acctWOrderMap.get(wo.UNITY_Assigned_Vendor__c).add(wo.Id);
        }
        
    	system.debug('@@@getWOIdAndGroupIdMap acctWOrderMap:'+acctWOrderMap);
    	
    	// Select Account 
		Map<Id, Account> vendorList = new Map<Id, Account>([SELECT Id, IsCustomerPortal
										FROM Account
	                                 	WHERE Id In :acctWOrderMap.keySet()
                                        AND RecordTypeId = :UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE
	                                 	AND IsCustomerPortal = true]);

		if (vendorList.size() <= 0)
       		return null;

        system.debug('@@@getWOIdAndGroupIdMap vendorList:'+vendorList);
        
        //Query the UserRoles associated to the accounts
        List<UserRole> userRoleList = [SELECT Id, PortalAccountId FROM UserRole WHERE PortalAccountId in :vendorList.keySet()];
		
		Map<Id, Id> roleAccountMap =  new Map<Id, Id>();
		for (UserRole role: userRoleList){
            roleAccountMap.put(role.Id, role.PortalAccountId);
        }

        system.debug('@@@getWOIdAndGroupIdMap roleAccountMap:'+roleAccountMap);
        
        if (roleAccountMap.size() <= 0)
       		return null;
        
        //Query Group ID 
        List<Group> groupList = [SELECT Id, RelatedID FROM Group WHERE RelatedID in :roleAccountMap.keySet() AND Type = 'RoleAndSubordinates'];
        
        system.debug('@@@getWOIdAndGroupIdMap groupList:'+groupList);
        
        if (groupList.size() <= 0)
        	return null;
        
        for (Group g: groupList){
            Id acctId = roleAccountMap.get(g.RelatedId);
            List<Id> woIDList = acctWOrderMap.get(acctId);
            for (Id woId: woIDList){
	            result.put(woId, g.Id);
            }
        }    	
    	return result;
    }
}