@isTest
public class UNITY_AccountHandler_UT {
    @testSetup
    public static void testSetup(){
        UNITY_MuleSiteSettingUtilsTest.setUp();
        UNITY_Mule2Salesforce_MappingUtilsTest.setUp();
        UNITY_Mulesoft_Credentials__c mCreds = new UNITY_Mulesoft_Credentials__c(
          Name = 'Basic Authorization',
            Authorization_Header__c = 'Basic dXNlcjE6cGFzc3dvcmQx'
        );
        insert mCreds;
        UNITY_MuleHttpCalloutMockImp calloutMock = new UNITY_MuleHttpCalloutMockImp(false);
        calloutMock.supposedEndPoint = UNITY_MuleSiteSettingUtils.getEndPoint(UNITY_MuleSiteSettingUtils.VENDOR);
        Test.setMock(HttpCalloutMock.class, calloutMock);
    }
    
    public static TestMethod void test1(){
        List<Account> vendors = TestDataProvider.getAccounts(1,'Vendor','Vendor');
        vendors[0].UNITY_Vendor_Status__c = 'Pending';
        vendors[0].Account_Status__c = 'Pending';
        insert vendors;
        UNITY_Vendor_Covered_Location__c cl = new UNITY_Vendor_Covered_Location__c(
        	Vendor__c = vendors[0].Id,
            Location_Key__c = 'US-782'
        );
        insert cl;
        FSO__Skill__c skill = new FSO__Skill__c(
        	Name = 'Test Skill Type',
            UNITY_Skill_Broad__c = 'Test Broad',
            UNITY_Skill_Group__c = 'Test Group'
        );
        insert skill;
        UNITY_Vendor_Trade__c vt = new UNITY_Vendor_Trade__c(
        	Vendor__c = vendors[0].Id,
            Trade__c = skill.Id
        );
        insert vt;
        vendors[0].UNITY_Vendor_Status__c = 'Active';
        vendors[0].Account_Status__c = 'Active';
        UNITY_Constants.isExecutingContext.put('AccountTriggerHandler.setUltimateParent',false);
        update vendors;
    }
    
}