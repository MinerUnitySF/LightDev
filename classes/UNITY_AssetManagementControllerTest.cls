@isTest
public with sharing class UNITY_AssetManagementControllerTest {
    public UNITY_AssetManagementControllerTest() {}

    @TestSetup
    static void init(){

        Integer MAX_ACCOUNT = 10;
        
        Map<String,Object> assetFields                 = new Map<String,Object>();
        Map<String,Object> accountFields               = UNITY_TestDataFactory.MOCKUP_ACCOUNT_FIELDS; 
        Map<String,Object> assetHistoryFields          = new Map<String,Object>();
        
        accountFields.put('recordTypeId', UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE);
        accountFields.put('Type', 'Customer');

        List<Account> accounts = (List<Account>)UNITY_TestDataFactory.createObject(MAX_ACCOUNT, Account.getSObjectType() , accountFields);
        insert accounts;

        List<Asset> assets = new List<Asset>();
        assetFields.put('ParentId'  , null);
        for(Integer i = 0 ;  i <accounts.size(); i++){
            assetFields.put('Name'       , 'test-'+i);
            assetFields.put('AccountId'  , accounts.get(i).Id);
            assets.add((Asset)UNITY_TestDataFactory.createObject(1, Asset.getSObjectType() , assetFields).get(0));
        }
        insert assets;

        List<UNITY_Asset_History__c> assetHistories = new List<UNITY_Asset_History__c>();
        for(Asset onAsset :assets){
            assetHistories.add(new UNITY_Asset_History__c(  UNITY_Asset__c        = onAsset.Id,
                                                            UNITY_Account__c      = onAsset.AccountId,
                                                            UNITY_End_Date__c     = Date.today().addMonths(6),
                                                            UNITY_Down_Time__c    = 1440,
                                                            UNITY_Start_Date__c   = Date.today().addMonths(-6),
                                                            UNITY_Service_Time__c = 1440));


        }
        insert assetHistories;

    }

    static testMethod void test(){
        List<Asset> assets = [SELECT Id, AccountId, ParentId, RootAsset.Name   FROM Asset];
        for(Asset a :assets){
            a.ParentId = null;
        }
        update assets;
        system.debug('>>> assets '+assets);
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 2];
        system.debug('>>> acc 0 '+accounts.get(0));
        system.debug('>>> acc 1 '+accounts.get(1));
        Test.startTest();
            PageReference pageRef = Page.UNITY_Asset_Management;
            pageRef.getParameters().put('id', accounts.get(0).id);
        
            Test.setCurrentPage(pageRef); 
        
            UNITY_AssetManagementController ctrl = new UNITY_AssetManagementController();
            ctrl = new UNITY_AssetManagementController(new ApexPages.StandardController(accounts.get(0)));
            system.debug('>>> fromAccountId '+ctrl.fromAccountId);
            ctrl.search_name = accounts.get(1).Name;
            ctrl.search();
            ctrl.transferTo = accounts.get(1).Id;
            for(UNITY_AssetManagementController.wrapperAsset  w :ctrl.assets){
                w.tranfer = true;
            }
            ctrl.transfer();


        Test.stopTest();

    }
}