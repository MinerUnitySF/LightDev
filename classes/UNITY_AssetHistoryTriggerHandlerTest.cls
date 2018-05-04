@isTest
public class UNITY_AssetHistoryTriggerHandlerTest {

    public UNITY_AssetHistoryTriggerHandlerTest() {}

    @TestSetup
    static void init(){

        // CREATE SKILL
        // CREATE ACCOUNT 
        // CREATE SERVICE CONTRACT 
        // CREATE CASE
        // CREATE WORKORDER
        // CREATE ASSET 
        Integer MAX_ACCOUNT = 10;
        Map<String,Object> caseFields                  = UNITY_TestDataFactory.MOCKUP_CASE_FIELDS;
        Map<String,Object> orderFields                 = UNITY_TestDataFactory.MOCKUP_ORDER_FIELDS;
        Map<String,Object> assetFields                 = new Map<String,Object>();
        Map<String,Object> skillFields                 = UNITY_TestDataFactory.MOCKUP_FSO_SKILL_FIELDS;
        Map<String,Object> contactFields               = UNITY_TestDataFactory.MOCKUP_CONTACT_FIELDS;
        Map<String,Object> accountFields               = UNITY_TestDataFactory.MOCKUP_ACCOUNT_FIELDS;  
        Map<String,Object> locationFields              = UNITY_TestDataFactory.MOCKUP_LOCATION_FIELDS;  
        Map<String,Object> workOrderFields             = UNITY_TestDataFactory.MOCKUP_WORK_ORDER_FIELDS;
        Map<String,Object> assetHistoryFields          = new Map<String,Object>();
        Map<String,Object> serviceContractFields       = UNITY_TestDataFactory.MOCKUP_SERVICE_CONTRACT_FIELDS;
        
        accountFields.put('recordTypeId', UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE);
        accountFields.put('Type', 'Customer');

        List<Account> accounts = (List<Account>)UNITY_TestDataFactory.createObject(MAX_ACCOUNT, Account.getSObjectType() , accountFields);
        insert accounts;

        List<Asset> assets = new List<Asset>();
        for(Integer i = 0 ; i < accounts.size(); i++){
            assetFields.put('Name'   , 'test-'+i);
            assetFields.put('AccountId', accounts.get(i).Id);
            assets.add((Asset)UNITY_TestDataFactory.createObject(1, Asset.getSObjectType() , assetFields).get(0));
        }

        insert assets;

    }

    static testMethod void test(){

        List<Asset> assets = [SELECT Id, AccountId FROM Asset];
        List<UNITY_Asset_History__c> assetHistories = new List<UNITY_Asset_History__c>();

        Test.startTest();

            for(Asset onAsset :assets){
                assetHistories.add(new UNITY_Asset_History__c(  UNITY_Asset__c        = onAsset.Id,
                                                                UNITY_Account__c      = onAsset.AccountId,
                                                                UNITY_End_Date__c     = Date.today().addMonths(12),
                                                                UNITY_Down_Time__c    = 1440,
                                                                UNITY_Start_Date__c   = Date.today(),
                                                                UNITY_Service_Time__c = 1440));


            }
            insert assetHistories;


            for(UNITY_Asset_History__c ah :assetHistories){
                ah.UNITY_Down_Time__c    = 2880;
                ah.UNITY_Service_Time__c = 2880;
            }
            update assetHistories;

        Test.stopTest();
    }
}