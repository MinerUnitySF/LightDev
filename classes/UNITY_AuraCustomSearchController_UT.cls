@isTest	
public class UNITY_AuraCustomSearchController_UT {
    @testSetup
    public static void init(){
        TestDataProvider.unityTestSetup();
    }
    
    public static testMethod void testSearchForIds(){
        //Setup Product and Pricebook Info
        Id PRICEBOOKENTRYID_T;
        Id PRICEBOOKENTRYID_L;
        Id PRICEBOOKENTRYID_P;
        Id PRODUCTID;
        
        //Create Product & pricebook
        Map<String,String> prodMapP = TestDataProvider.getProductAndPriceBookEntry(1,'Part');
        for(String s :prodMapP.keySet()){
            PRICEBOOKENTRYID_P = (Id)prodMapP.get(s);
            PRODUCTID = (Id)s;
        }
        Map<String,String> prodMapL = TestDataProvider.getProductAndPriceBookEntry(1,'Labor');
        for(String s :prodMapL.keySet()){
            PRICEBOOKENTRYID_L = (Id)prodMapL.get(s);
        }
        Map<String,String> prodMapT = TestDataProvider.getProductAndPriceBookEntry(1,'Travel');
        for(String s :prodMapT.keySet()){
            PRICEBOOKENTRYID_T = (Id)prodMapT.get(s);
        }
           
        
		Account cust;
        Account vend;
        Account bu;
        
        String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
        String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;
        String usageRecRTId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
        String purchaseOrdRTId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;

        Test.startTest();
        //Get the accounts
        List<Account> accounts = [SELECT Id,RecordTypeId,Account_Email__c FROM Account];
        
        for(Account a :accounts){
            if(a.RecordTypeId == custRTId)
                cust = a;
            if(a.RecordTypeId == vendRTId)
                vend = a;
            if(a.RecordTypeId == buRTId)
                bu = a;
        }
		cust.Name = 'Test Account Copy';
        update cust;
        
        Case testCase = [SELECT Id,UNITY_Customer_WO__c FROM Case LIMIT 1];
		testCase.UNITY_Customer_WO__c = 'Copy456';
		update testCase;
        
        //Create an agent
        User agent = TestDataProvider.getUser('Agent', 'One', 'NMS Technician');
        insert agent;
        
        //Create a Work Order
        WorkOrder wo = new WorkOrder();
        wo.AccountId = cust.Id;
        wo.UNITY_Business_Unit_Account__c = bu.Id;
        wo.UNITY_Business_Unit__c = 'NSBS';
        wo.UNITY_Customer__c = cust.Id;
        wo.UNITY_Skill_Broad__c = 'Glass';
        wo.UNITY_Skill_Group__c = 'Glass Installation/Repair';
        wo.UNITY_Skill_Type__c = 'Glass, Board up, Mirrors & Displays';
        wo.Priority = '24 Hour Response';
        wo.Status = 'New';
        wo.RecordTypeId = woRTId;
        wo.CaseId = testCase.Id;
        wo.Description = 'Test Test Test';
        wo.UNITY_Work_Description__c = 'Test Test Test';
        wo.UNITY_Work_Window_Begin__c = DateTime.now();
        wo.UNITY_Work_Window_End__c = DateTime.now().addMinutes(60);
        wo.MSPFS_Intercompany_Transfer__c = true;
        wo.UNITY_Agent__c = agent.Id;
        wo.UNITY_Assigned_Vendor__c = vend.Id;
        wo.UNITY_Accepted_Vendor__c = vend.Id;
        wo.UNITY_Vendor_Status__c = 'Accepted';
        insert wo;    
        
        UNITY_Attachment__c attachment1 = new UNITY_Attachment__c();
        attachment1.Work_Order__c =wo.Id;
        attachment1.UNITY_Type__c ='Copy of Supplier Parts';
        insert attachment1;
 
        Test.stopTest();
        
        //Setup test data for SOSL
        Id [] fixedSearchResults= new Id[3];
        fixedSearchResults[0] = cust.Id;
        fixedSearchResults[1] = testCase.Id;
        fixedSearchResults[2] = attachment1.Id;
        //Required so SOSL will fire in Unit Tests Properly
        Test.setFixedSearchResults(fixedSearchResults);
        
        List<SObject> searchResults = UNITY_AuraCustomSearchController.searchForIds('Copy');
        system.debug('@@@ searchResults'+searchResults);
        System.assert(searchResults.size() == 3);
            
    }
}