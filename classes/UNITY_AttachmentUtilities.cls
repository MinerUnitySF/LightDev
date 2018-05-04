/*------------------------------------------------------------
Name:          AttachmentUtilities
Author:        Krishna Kameneni
Company:       Miner
Description:   This is Main utility class for Attachment object.
History:
12/16/2015     Krishna Kameneni(Perficient)    Added/Modified comments
                                               Created event handling methods 
================================
Changelog
================================
Developer: Izay Ramos
Description: Updated logic to fix attachment count bug
Date: 1/10/2017
------------------------------------------------------------*/
public without sharing class UNITY_AttachmentUtilities{
    public static void onAfterInsert(List<UNITY_Attachment__c> attachmentsNew) {
        UNITY_AttachmentUtilities.updateAttachmentCompliant(attachmentsNew,null);
        UNITY_AttachmentUtilities.shareAttachmentToVendor(attachmentsNew);
    }
    public static void onAfterUpdate(List<UNITY_Attachment__c> attachmentsNew,Map<id,UNITY_Attachment__c>oldMap) {
        UNITY_AttachmentUtilities.updateAttachmentCompliant(attachmentsNew,oldMap);
        
        List<UNITY_Attachment__c> shareList = new List<UNITY_Attachment__c>();
        List<UNITY_Attachment__c> unshareList = new List<UNITY_Attachment__c>();
        
        for (UNITY_Attachment__c newAttachment: attachmentsNew){
            UNITY_Attachment__c oldAttachment = oldMap.get(newAttachment.Id);
            if (oldAttachment.UNITY_Type__c != newAttachment.UNITY_Type__c){
                
                //old type is vendor visible, new type should not be vendor visible
				if (UNITY_AttachmentHelper_Miner.isAttachmentVendorVisible(oldAttachment)
                   && !UNITY_AttachmentHelper_Miner.isAttachmentVendorVisible(newAttachment)) //Old attachment is visible 
                    unshareList.add(oldAttachment);
                
                //old type is not vendor visible, new type is vendor visible
                if (!UNITY_AttachmentHelper_Miner.isAttachmentVendorVisible(oldAttachment)
                   && UNITY_AttachmentHelper_Miner.isAttachmentVendorVisible(newAttachment))
                    shareList.add(newAttachment);
            }                
        }
        
        if (unshareList.size() > 0)
            unShareAttachmentToVendor(unshareList);
        
        if (shareList.size() > 0)
            shareAttachmentToVendor(shareList);
    }
    public static void onAfterDelete(List<UNITY_Attachment__c> attachmentsNew) {
        UNITY_AttachmentUtilities.updateAttachmentCompliant(attachmentsNew,null);
    }    
    public static void onBeforeInsert(List<UNITY_Attachment__c> attachmentsNew) {
        //Get all WorkOrderIds
        Set<Id> workOrderIds = new Set<Id>();
        for (UNITY_Attachment__c a: attachmentsNew){
            workOrderIds.add(a.Work_Order__c);
        }
        //Get the ultimate company name
        Map<Id,WorkOrder> woList = new  Map<Id,WorkOrder>([SELECT Id, UNITY_Customer__r.UNITY_Company__c FROM WorkOrder WHERE Id in :workOrderIds]);
        
        for (UNITY_Attachment__c a: attachmentsNew){
            WorkOrder wo = woList.get(a.Work_Order__c);
            if (wo != null && wo.UNITY_Customer__c != null)
                a.Customer_Ultimate_Parent_Text__c = wo.UNITY_Customer__r.UNITY_Company__c;
        }
    }
    
    public static void updateAttachmentCompliant(List<UNITY_Attachment__c> attachmentsNew,Map<id,UNITY_Attachment__c>oldMap){
        Set<Id> workOrderIds = new Set<Id>();
        //Izay: Not a clue why want to return if the attachment type changed
        // get the WorkOrder Ids updated / inserted to be used in the following query
        /*
        Boolean isTypeChanged=false;
        if(oldMap!=null){
            for(UNITY_Attachment__c attachment : attachmentsNew){
                if(attachment.UNITY_Type__c!=oldMap.get(attachment.id).UNITY_Type__c)isTypeChanged=true;
            }
            if(!isTypeChanged)return;
        }
        */
        //Add the WO id if it is a new attachment or if the attachment type changed
        for (UNITY_Attachment__c attachment : attachmentsNew){
            if(oldMap == null){
                workOrderIds.add(attachment.Work_Order__c);
            }else if(attachment.UNITY_Type__c != oldMap.get(attachment.id).UNITY_Type__c){
                workOrderIds.add(attachment.Work_Order__c);
            }
        }
        //Query the WOs to get the required documents from the SC
        List <WorkOrder>workOrders=[SELECT id ,UNITY_Attachment_Compliant__c,UNITY_Customer_Service_Contract__r.UNITY_Required_Documentation__c,
                                    (Select id, UNITY_Type__c from Attachments__r)  
                                    FROM WorkOrder
                                    WHERE Id In :workOrderIds];
        
        for(WorkOrder wo : workOrders){
            //Map to hold attachment count by attachment type
            //Key: Attachment Type (String)
            //Value: Count (Integer)
            Map<String,Integer> docsMap = new Map<String,Integer>();
            Boolean compliant = true; //To denote if the WO is attachment compliant
            Integer tripCount = 1; //Assign the trip count from a real trip count for multi trip support. Default to 1.
            if(String.isNotEmpty(wo.UNITY_Customer_Service_Contract__r.UNITY_Required_Documentation__c)) { 
              //Split the required docs from the SC into a list
                List<String> requiredDocs = wo.UNITY_Customer_Service_Contract__r.UNITY_Required_Documentation__c.split(';');
                //Add the required doc types to the map with a count of zero(0)
                for(String recDoc :requiredDocs){
                    docsMap.put(recDoc,0);
                }
                System.Debug('Izay: docsMap = ' + docsMap);
                //For each attachment on the WO...
                for(UNITY_Attachment__c attachment : wo.Attachments__r){
                    //Look for the attachment type in the map...
                    if(docsMap.containsKey(attachment.UNITY_Type__c)){
                        //Add one(1) to the count of this attachment type
                        Integer i = docsMap.get(attachment.UNITY_Type__c);
                        i++;
                        docsMap.put(attachment.UNITY_Type__c,i);
                    }
                }
                //For each required document...
                for(Integer i :docsMap.values()){
                    //Compare the required document count with the trip count
                    //If the document count is less than the trip count... 
                    //Set compliant to false
                    if(i < tripCount){
                        compliant = false;
                    }
                }
            }
            wo.UNITY_Attachment_Compliant__c = compliant;//Update Attachment compliant checkbox on the WO
        }
        //Exception handling
        try{
            update workOrders;//Update the WOs 
        }catch(Exception e){
            Trigger.new[0].addError(e.getMessage());
        }
    }
    //Share the attachment to the vendor community users
    public static void shareAttachmentToVendor(List<UNITY_Attachment__c> attachmentsNew){
        
		Map<Id, Id> attachAndGroupMap = getAttachmentAndGroupIdMap(attachmentsNew);

        if (attachAndGroupMap == null)
			return;
			
        system.debug('@@@shareAttachmentToVendor attachAndGroupMap:'+attachAndGroupMap);
        
        if (attachAndGroupMap.size() > 0){
            List<UNITY_Attachment__Share> attShares = new List<UNITY_Attachment__Share>();
            for (Id attachId : attachAndGroupMap.keySet()){
                
                UNITY_Attachment__Share s = new UNITY_Attachment__Share();
                s.ParentID = attachId;
                s.UserOrGroupID = attachAndGroupMap.get(attachId);
                s.AccessLevel = 'Read';
                s.RowCause = Schema.UNITY_Attachment__Share.RowCause.Vendor_Community__c;
                
                attShares.add(s); 
            }
            system.debug('@@@shareAttachmentToVendor attShares:'+attShares);
            insert attShares;
        }
    }
	
	public static void unShareAttachmentToVendor(List<UNITY_Attachment__c> attachmentsNew){
    	
		Map<Id, Id> attachAndGroupMap = getAttachmentAndGroupIdMap(attachmentsNew);

        if (attachAndGroupMap == null)
			return;
        
    	system.debug('@@@unShareAttachmentToVendor attachAndGroupMap:'+attachAndGroupMap);
        
		List<UNITY_Attachment__Share> attachShareList = [SELECT ParentId, UserOrGroupId FROM UNITY_Attachment__Share 
											WHERE UserOrGroupId in :attachAndGroupMap.values() 
											AND RowCause = :Schema.UNITY_Attachment__Share.RowCause.Vendor_Community__c
											AND ParentId in :attachAndGroupMap.keySet()];
											
        system.debug('@@@unShareAttachmentToVendor attachShareList:'+attachShareList);
        
        if (attachShareList.size() > 0){
            delete attachShareList;
        }
    }
    
    //Returns a map of Attachment ID and the Group ID of the Vendor Account's Role (Community Role)
    public static Map<Id, Id> getAttachmentAndGroupIdMap (List<UNITY_Attachment__c> attachments){
        system.debug('@@@getAttachmentAndGroupIdMap attachments:'+attachments);

        //Filter attachment by type
        List<UNITY_Attachment__c> filteredAttachments = new List<UNITY_Attachment__c>();
        for (UNITY_Attachment__c a: attachments){
            if (UNITY_AttachmentHelper_Miner.isAttachmentVendorVisible(a))
                filteredAttachments.add(a);
        }
        
        system.debug('@@@getAttachmentAndGroupIdMap filteredAttachments:'+filteredAttachments);
        
        if (filteredAttachments.size() <= 0)
            return null;
        
        //Get WO ids
        Map<Id, List<Id>> woAndAttchMap = new Map<Id, List<Id>>();
        for (UNITY_Attachment__c attachment : filteredAttachments){
            if (!woAndAttchMap.containsKey(attachment.Work_Order__c))
                woAndAttchMap.put(attachment.Work_Order__c, new List<Id>());
    		woAndAttchMap.get(attachment.Work_Order__c).add(attachment.Id);
        }
        
        system.debug('@@@getAttachmentAndGroupIdMap woAndAttchMap:'+woAndAttchMap);
        
        if (woAndAttchMap.size() <= 0)
       		return null;
        
        //Query the WOs to get the accepted Vendors who has community enabled
        List<WorkOrder> woList = [SELECT id, UNITY_Accepted_Vendor__c
                                  FROM WorkOrder
                                  WHERE Id In :woAndAttchMap.keySet()
                                  AND UNITY_Accepted_Vendor__c != null
                                  AND UNITY_Accepted_Vendor__r.RecordTypeId = :UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE
                                  AND UNITY_Accepted_Vendor__r.IsCustomerPortal = true];
        
		Map<Id, List<Id>> acctAndAttchMap = new Map<Id, List<Id>>();
        for (WorkOrder wo: woList){
            Id accountId = wo.UNITY_Accepted_Vendor__c;
            List<Id> attachIdList = woAndAttchMap.get(wo.Id);
            if (!acctAndAttchMap.containsKey(accountId))
                acctAndAttchMap.put(accountId, new List<Id>());
            acctAndAttchMap.get(accountId).addAll(attachIdList);
        }
        system.debug('@@@getAttachmentAndGroupIdMap acctAndAttchMap:'+acctAndAttchMap);
        
        if (acctAndAttchMap.size() <= 0)
       		return null;
        
        Map<Id, Id> roleAcctMap =  new Map<Id, Id>();
        //Query the UserRoles associated to the accounts
        List<UserRole> userRoleList = [SELECT Id, PortalAccountId FROM UserRole WHERE PortalAccountId in :acctAndAttchMap.keySet()];
        for (UserRole role: userRoleList){
            roleAcctMap.put(role.Id, role.PortalAccountId);
        }

        system.debug('@@@getAttachmentAndGroupIdMap roleAcctMap:'+roleAcctMap);
        
        if (roleAcctMap.size() <= 0)
       		return null;
        
        //Query Group ID 
        Map<Id, Id> result = new Map<Id, Id>();
        List<Group> groupList = [SELECT Id, RelatedID FROM Group WHERE RelatedID in :roleAcctMap.keySet() AND Type = 'RoleAndSubordinates'];
        
        if (groupList.size() <= 0)
        	return null;
        
        for (Group g: groupList){
            Id accountID = roleAcctMap.get(g.RelatedId);
            List<Id> attachIdList = acctAndAttchMap.get(accountId);
            for (Id aId: attachIdList)
            	result.put(aId, g.Id);
        }

        system.debug('@@@getAttachmentAndGroupIdMap result:'+result);
        
    	return result;
    }
}