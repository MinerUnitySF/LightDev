@isTest
public class UNITY_AssetChildListControllerTest{

    public static testMethod void runTest(){
        Account acc = new Account(Name = 'Test', Type= 'Site/Location', BillingCity = 'City', BillingStateCode = 'CA', BillingPostalCode = '12345', BillingCountry = 'US', BillingStreet = 'Street', Account_Email__c = 'test2@test.com');
        insert acc;
    
        Asset asset = new Asset(AccountId = acc.Id, Name = 'Parent Asset');
        insert asset;
        
        Asset childAsset = new Asset(AccountId = acc.Id, Name = 'Child Asset', ParentId = asset.Id);
        insert childAsset;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(asset);
        UNITY_AssetChildListController controller = new UNITY_AssetChildListController(sc);
        system.assertEquals(1, controller.assetChildList.size());
    }

}