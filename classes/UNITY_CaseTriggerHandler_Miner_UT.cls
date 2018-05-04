/**This class serves as a unit test for UNITY_CaseTriggerHandler_Miner
 * @programmer: Izay Ramos-Irizarry
 * @date: 4/4/2016
 * @version: 0.1
 */
@isTest
public class UNITY_CaseTriggerHandler_Miner_UT {
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
        //Create BU SPecific Team field Map
        UNITY_BU_Team_Field_Map__c nsbsTeamMap = new UNITY_BU_Team_Field_Map__c(
        	Name = 'MNS',
            UNITY_Field_API_Name__c = 'UNITY_MNS_Customer_Team__c'
        );
        insert nsbsTeamMap;
        //Create CTI Value Map (Abbreviations Map)
        List<UNITY_CTI_Values_Map__c> cvmList = new List<UNITY_CTI_Values_Map__c>();
        UNITY_CTI_Values_Map__c cvm = new UNITY_CTI_Values_Map__c();
        cvm.Name = 'Team 1';
        cvm.InContact_Value__c = 'TM1';
        cvmList.add(cvm);
        UNITY_CTI_Values_Map__c cvm2 = new UNITY_CTI_Values_Map__c();
        cvm2.Name = 'Tier 1';
        cvm2.InContact_Value__c = 'T1';
        cvmList.add(cvm2);
        insert cvmList;
        //Create CTI Skill Ids Map for MNS and NSBS
        List<CTI_Skill_Id_Map__c>  ctiSkillList = new List<CTI_Skill_Id_Map__c>();
        CTI_Skill_Id_Map__c ctiSkill = new CTI_Skill_Id_Map__c();
        ctiSkill.InContact_ID__c = '123456';
        ctiSkill.Name = 'NSBS-T1-TM1-Glass';
        CTI_Skill_Id_Map__c ctiSkill2 = new CTI_Skill_Id_Map__c();
        ctiSkill2.InContact_ID__c = '234567';
        ctiSkill2.Name = 'NSBS-T1-TM1';
        CTI_Skill_Id_Map__c ctiSkill3 = new CTI_Skill_Id_Map__c();
        ctiSkill3.InContact_ID__c = '345678';
        ctiSkill3.Name = 'NSBS-T1';
        CTI_Skill_Id_Map__c ctiSkill4 = new CTI_Skill_Id_Map__c();
        ctiSkill4.InContact_ID__c = '741258';
        ctiSkill4.Name = 'MNS-T1-TM1-Glass';
        CTI_Skill_Id_Map__c ctiSkill5 = new CTI_Skill_Id_Map__c();
        ctiSkill5.InContact_ID__c = '963258';
        ctiSkill5.Name = 'MNS-T1-TM1';
        CTI_Skill_Id_Map__c ctiSkill6 = new CTI_Skill_Id_Map__c();
        ctiSkill6.InContact_ID__c = '852147';
        ctiSkill6.Name = 'MNS-T1';
        CTI_Skill_Id_Map__c ctiSkill7 = new CTI_Skill_Id_Map__c();
        ctiSkill7.InContact_ID__c = '852369';
        ctiSkill7.Name = 'MNS-T1-TM1-VM';
        ctiSkillList.add(ctiSkill);ctiSkillList.add(ctiSkill2);ctiSkillList.add(ctiSkill3);
        ctiSkillList.add(ctiSkill4);ctiSkillList.add(ctiSkill5);ctiSkillList.add(ctiSkill6);ctiSkillList.add(ctiSkill7);
        insert ctiSkillList;
    }
    
    public static TestMethod void test1(){
        
        List<Account> accts = new List<Account>();
        Account cust = TestDataProvider.getAccounts(1,'Customer', 'Customer')[0];
        cust.Account_Status__c = 'Active';
        cust.UNITY_Customer_Team__c = 'Team 1';
        cust.UNITY_MNS_Customer_Team__c = 'Team 1';
        cust.UNITY_Tier_Level__c = 'Tier 1';
        accts.add(cust);
        
        Account buNSBS = TestDataProvider.getAccounts(1,'Miner','Business Unit')[0];buNSBS.UNITY_Business_Unit__c = 'NSBS';accts.add(buNSBS);
        Account buMNS = TestDataProvider.getAccounts(1,'Miner','Business Unit')[0];buMNS.UNITY_Business_Unit__c = 'MNS';accts.add(buMNS);
        insert accts;
        
        List<Case> cases = new List<Case>();
        
        Case c = UNITY_TestDataFactory.createCases(1,cust.Id,cust.Id)[0];
        c.UNITY_Customer__c = cust.Id;
        c.UNITY_Business_Unit__c = 'NSBS';
        c.UNITY_Business_Unit_Account__c = buNSBS.Id;
        c.UNITY_Skill_Broad__c = 'Glass';
        
        Case c2 = UNITY_TestDataFactory.createCases(1,cust.Id,cust.Id)[0];
        c2.UNITY_Customer__c = cust.Id;
        c2.UNITY_Business_Unit__c = 'MNS';
        c2.UNITY_Business_Unit_Account__c = buMNS.Id;
        c2.UNITY_Skill_Broad__c = 'Glass';
        
        Test.startTest();
        
        cases.add(c);
        cases.add(c2);
        //UNITY_CaseTriggerHandler_Miner.isFirstTriggerRun_Before = true;
        update cases;
        cases = [SELECT Id,UNITY_Skill_ID__c,UNITY_Skill_ID_1__c,UNITY_Skill_ID_2__c FROM Case];
        
        //System.assertEquals('123456', c.UNITY_Skill_ID__c);
        //System.assertEquals('234567', c.UNITY_Skill_ID_1__c);
        //System.assertEquals('345678', c.UNITY_Skill_ID_2__c);
        //
        UNITY_CaseTriggerHandler_Miner.runTriggerOnce_Before();
        UNITY_CaseTriggerHandler_Miner.runTriggerOnce_After();
        UNITY_CaseTriggerHandler_Miner.runTriggerOnce_Before();
        UNITY_CaseTriggerHandler_Miner.runTriggerOnce_After();
        Test.stopTest();
    }
    
}