//Trigger handler class that uses WITHOUT SHARING
public without sharing class UNITY_OrderTriggerHandler_NoSharing {

	public static void shareOrderToVendor(List<Order> orders){

        system.debug('@@@shareOrderToVendor orders:'+orders);
        
		Map<Id, Id> orderAndGroupMap = getOrderIdAndGroupIDMap(orders);
        system.debug('@@@shareOrderToVendor orderAndGroupMap:'+orderAndGroupMap);
		
		if (orderAndGroupMap == null)
			return;
        
        if (orderAndGroupMap.size() > 0){
            List<OrderShare> shareToInsert = new List<OrderShare>();
            for (Id orderId : orderAndGroupMap.keySet()){
                
                OrderShare os = new OrderShare();
                os.OrderId = orderId;
		        os.OrderAccessLevel = 'Read';
		        os.RowCause = Schema.OrderShare.RowCause.Manual;
		        os.UserOrGroupId = orderAndGroupMap.get(orderId);
		        shareToInsert.add(os);
            }
            system.debug('@@@shareOrderToVendor shareToInsert:'+shareToInsert);
            insert shareToInsert;
        }
    }
        
    public static void unShareOrderToVendor(List<Order> orders){
    	
    	system.debug('@@@unShareOrderToVendor orders:'+orders);
    	
		Map<Id, Id> orderAndGroupMap = getOrderIdAndGroupIDMap(orders);

        system.debug('@@@unShareOrderToVendor orderAndGroupMap:'+orderAndGroupMap);
		if (orderAndGroupMap == null)
			return;

		List<OrderShare> orderShareList = [SELECT OrderId, UserOrGroupId FROM OrderShare 
											WHERE UserOrGroupId in :orderAndGroupMap.values() 
											AND RowCause = 'Manual' AND OrderAccessLevel = 'Read'
											AND OrderId in :orderAndGroupMap.keySet()];
											
        system.debug('@@@unShareOrderToVendor orderShareList:'+orderShareList);
        
        if (orderShareList.size() > 0){
            delete orderShareList;
        }
    }
    
    //Returns a map of Order ID and the Group ID of the Vendor Account's Role (Community Role)
    public static Map<Id, Id> getOrderIdAndGroupIDMap (List<Order> orders){
		Map<Id, Id> result = new Map<Id, Id>();
        
        system.debug('@@@getGroupIdAndOrderIdMap orders:'+orders);

    	Map<Id, List<Id>> acctOrderMap = new Map<Id, List<Id>>();
        for(Order o: orders){
            if (!acctOrderMap.containsKey(o.UNITY_Vendor__c))
                acctOrderMap.put(o.UNITY_Vendor__c, new List<Id>());
    		acctOrderMap.get(o.UNITY_Vendor__c).add(o.Id);
        }
        
    	system.debug('@@@getGroupIdAndOrderIdMap acctOrderMap:'+acctOrderMap);
    	
    	// Select Account 
		Map<Id, Account> vendorList = new Map<Id, Account>([SELECT Id, IsCustomerPortal
										FROM Account
	                                 	WHERE Id In :acctOrderMap.keySet()
										AND RecordTypeId = :UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE
	                                 	AND IsCustomerPortal = true]);

		if (vendorList.size() <= 0)
       		return null;

        //Query the UserRoles associated to the accounts
        List<UserRole> userRoleList = [SELECT Id, PortalAccountId FROM UserRole WHERE PortalAccountId in :vendorList.keySet()];
		
		Map<Id, Id> roleAcctMap =  new Map<Id, Id>();
		for (UserRole role: userRoleList){
            roleAcctMap.put(role.Id,role.PortalAccountId);
        }

        system.debug('@@@getGroupIdAndOrderIdMap roleAcctMap:'+roleAcctMap);
        
        if (roleAcctMap.size() <= 0)
       		return null;
        
        //Query Group ID 
        List<Group> groupList = [SELECT Id, RelatedID FROM Group WHERE RelatedID in :roleAcctMap.keySet() AND Type = 'RoleAndSubordinates'];
        
        system.debug('@@@getGroupIdAndOrderIdMap groupList:'+groupList);
        
        if (groupList.size() <= 0)
        	return null;
        
        for (Group g: groupList){
            Id accountId = roleAcctMap.get(g.RelatedID);
            List<Id> orderIDList = acctOrderMap.get(accountId);
            for (Id oId: orderIDList)            
            	result.put(oId, g.Id);
        }    	
    	return result;
    }

}