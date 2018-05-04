@isTest(seeAllData=true)
public with sharing class PartsOrderAllTest {

    private static testmethod void test1(){
        
        //Profile p = [Select Id, Name from Profile where Name = 'Standard User'];
        
        User testUser = TestDataProvider.getUsers(1)[0];
        insert testUser;
        
        Account acc = TestDataProvider.getAccounts(1,'Customer Account','Customer')[0];
        insert acc;
        //Create service group
        SVMXC__Service_Group__c sgroup = new SVMXC__Service_Group__c(
            Name = 'Test Service Group',
            SVMXC__Active__c = true,
            Super_Center__c = 'Miner-Houston',
            Segment__c = 'Houston',
            SVMXC__State__c = 'TX'
        );
        insert sgroup;
        //Create locationj
        SVMXC__Site__c  location = TestDataProvider.getLocations(1,'Location Site','SPSC',acc.Id)[0];
        insert location;
        //create Work Order
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.SVMXC__Company__c = acc.Id;
        wo.SVMXC__Order_Status__c = 'Open';
        wo.SVMXC__Order_Type__c = 'Service-DDM';
        wo.SVMXC__Site__c = location.id;
        wo.SVMXC__Problem_Description__c = 'prob desc';
        wo.Location__c = location.Id;
        wo.Business_Unit__c = 'Miner Corp';
        wo.SVMXC__Service_Group__c = sgroup.Id;
        insert wo;
        
        Bill_To_Accounts__c ba = new Bill_To_Accounts__c();
        ba.Service_Team__c = 'name';
        ba.Name = 'ba';
        ba.Account_Id__c = acc.Id;
        insert ba;
        
        System.runAs(testUser){
            SVMXC__RMA_Shipment_Order__c so = new SVMXC__RMA_Shipment_Order__c();
            so.SVMXC__Service_Order__c = wo.Id;
            try{
                insert so;
            }catch(Exception e){
                System.debug('##### Error: ' + e.getStackTraceString());
            }
            
        }
        
        
    }

}