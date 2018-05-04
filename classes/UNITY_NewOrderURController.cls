/*------------------------------------------------------------
Name:          UNITY_NewOrderURController
Author:        Hao Dong
Company:       Salesforce
Description:   This class creates new usage request (Order) from WorkOrder
History:
3/22/2016      Hao Dong
------------------------------------------------------------*/
public with sharing class UNITY_NewOrderURController {
    //added an instance varaible for the standard controller
    private ApexPages.StandardController controller {get; set;}
    // add the instance for the variables being passed by id on the url

    @TestVisible private WorkOrder wo {get;set;}
    
    public id newURId {get;set;}
    public String baseURL {get;set;}
    
    // initialize the controller
    public UNITY_NewOrderURController(ApexPages.StandardController controller) { 
		//add more fields to retrieve
		if (!Test.isRunningTest())
    		controller.addFields(new List<String>{'MSPFS_Service_Order_Type__c','MSPFS_Intercompany_Transfer__c','UNITY_Primary_Technician__c','UNITY_Business_Unit_Account__c','UNITY_Assigned_Vendor__c'});
        //initialize the stanrdard controller
        this.controller = controller;
        // load the current record
        wo = (WorkOrder)controller.getRecord();       
        baseURL = URL.getSalesforceBaseUrl().toExternalForm() + '/';
    }
    
    // method called from the VF's action attribute to clone the partners    
    public PageReference newOrderUR() { 

        Id urRTId = UNITY_Utils.getRecordType(Schema.getGlobalDescribe().get('Order'), 'Usage Request');
        //Izay: Added for new PO button for MSP
        Id poRTId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;
        Id userId = UserInfo.getUserId();

        String orderType = ApexHelper.getParam('type');

        //verify the user can create new Order


        //add logic to prevent button double click
        Integer nExistingDraftUR = [SELECT Count() FROM Order WHERE (RecordTypeId = :urRTId OR RecordTypeId = :poRTId) AND Status = 'Draft' AND FSO__WorkOrder__c = :wo.id AND CreatedById = :userId];
        
        //Do not allow user to create a new UR if service has not been scheduled for Organic Work Orders
        Boolean isPrimaryTechNotScheduled = false;
        if (wo.MSPFS_Service_Order_Type__c == 'Time and Materials' && wo.MSPFS_Intercompany_Transfer__c == false 
        		&& wo.UNITY_Primary_Technician__c == null && wo.UNITY_Business_Unit_Account__c == wo.UNITY_Assigned_Vendor__c ) 
        	isPrimaryTechNotScheduled = true;
        	
        if (!Schema.SObjectType.Order.isCreateable())
        {
            ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You do not have permission to create a new Usage Request.');
            ApexPages.addMessage(errorMsg);
            return null;
        } 
        else if (nExistingDraftUR > 0)
        {
            ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You have created at least one Usage Request that is currently in draft status under the same Work Order, please delete before creating another one.');
            ApexPages.addMessage(errorMsg);
            return null;
        }
        else if (isPrimaryTechNotScheduled)
    	{
    		ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Please schedule the Technician before creating a usage request');
            ApexPages.addMessage(errorMsg);
            return null;
    	}
        else
        {
            UNITY_CreateUR createUR = new UNITY_CreateUR();
            Id recordId;
            if(orderType == 'ur')
                recordId = createUR.CreateUR(wo.Id, urRTId);
            else if(orderType == 'po')
                recordId = createUR.CreateUR(wo.Id, poRTId);

            if (recordId != null)
                return new PageReference('/'+recordId); 
            else
                return null; 
        }
    }

    private without sharing class UNITY_CreateUR {
        private ID CreateUR (ID woId, ID urRTId)
        {
            // setup the save point for rollback
            //Savepoint sp = Database.setSavepoint();
            WorkOrder currentWO;
            Order newUR;

            try {                      
                currentWO = [SELECT Id, AccountId,UNITY_Customer__c FROM WorkOrder WHERE Id = :woId];

                newUR = new Order();
                //newUR.OwnerId = userID; 
                newUR.RecordTypeId = urRTId;
                newUR.FSO__WorkOrder__c = currentWO.Id; 
                newUR.AccountId = currentWO.AccountId; 
                newUR.UNITY_Customer__c = currentWO.UNITY_Customer__c; 
                newUR.Status = 'Draft'; 
                newUR.EffectiveDate = System.today();

                insert newUR;

                return newUR.id;

            } catch (Exception e){
                // roll everything back in case of errors
                //Database.rollback(sp);
                ApexPages.addMessages(e);
                return null;
            }

        }
    }
}