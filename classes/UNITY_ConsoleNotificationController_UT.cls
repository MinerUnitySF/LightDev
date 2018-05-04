/**This class is the test class for UNITY_ConsoleNotificationController.cls
 * @programmer: Izay Ramos-Irizarry
 * @description: This class is the test class for UNITY_ConsoleNotificationController.cls
 * @date: 3/8/2016
 * @version: 1.0
 */
@isTest
public class UNITY_ConsoleNotificationController_UT {
    /**This method tests the subscribe method in UNITY_ConsoleNotificationController.cls
     */
    public static TestMethod void testSubscribe(){
        //Create a test user
        User u = TestDataProvider.getUsers(1)[0];
        u.Ignore_Validations__c = true;
        insert u;
        //create a queue
        Group q = new Group(Name = 'Test Queue',Type = 'Queue');
        insert q;
        //Create a queue object
        QueueSObject qso = new QueueSObject(QueueID = q.id, SobjectType = 'Case');
        insert qso;
        //create a regular group
        Group g = new Group(
            Name = 'Text Queue',
            Type = 'Regular'
        );
        insert g;
        //Add the curremt user to the regular group
        GroupMember gm = new GroupMember(
            GroupId = g.Id,
            UserOrGroupId = u.Id
        );
        insert gm;
        //Add the regular group to the queue
        GroupMember qm = new GroupMember(
            GroupId = q.Id,
            UserOrGroupId = g.Id
        );
        insert qm;
        //Call the subscribe method as the user u
        System.runAs(u){
            //Create a push notification setting for type Emergency case
            UNITY_Push_Notification_Setting__c pns = new UNITY_Push_Notification_Setting__c(
                Name = 'Emergency Case',
                BG_Color__c = '#ee3333',
                Object__c = 'Case',
                Query__c = 'Id,CaseNumber,Subject,OwnerId,Priority,Status,CreatedDate FROM Case',
                Fields_Order__c = '[{"Subject":"Subject"},{"Priority":"Priority"},{"Created":"CreatedDate"}]'
            );
            insert pns;
            //Create an account and a contact
            Account a = TestDataProvider.getAccounts(1, 'Customer', 'Customer')[0];
            insert a;
            Contact c = TestDataProvider.getContacts(1, a.id)[0];
            insert c;
            //Create a case to relate a notification to
            Case mycase = new Case(
                Subject = 'Test Notification Case',
                Description = 'Test case Description',
                ContactId = c.Id
            );
            insert mycase;
            Test.startTest();
            String result = UNITY_ConsoleNotificationController.subscribe();
            System.debug('result: ' + result);
            System.assert(result.indexOf('"success":true') != -1);
            //Call the subscribe method again to cover the update
            result = UNITY_ConsoleNotificationController.subscribe();
            System.assert(result.indexOf('"success":true') != -1);
            //Create a notification record type Alert
            UNITY_Push_Notification__c upn1 = new UNITY_Push_Notification__c(
                Message__c = 'Test Message',
                Record_Id__c = '',
                Record_Name__c = '',
                Subject__c = 'Test Notification',
                Subscriber__c = u.Id,
                Type__c = 'Alert'
            );
            insert upn1;
            List<UNITY_ConsoleNotificationController.Notif> resultNotif = UNITY_ConsoleNotificationController.getNotification(upn1.Id);
            //Create a notification record type Emergency Case
            UNITY_Push_Notification__c upn2 = new UNITY_Push_Notification__c(
                Message__c = 'Test Message',
                Record_Id__c = mycase.Id,
                Record_Name__c = myCase.CaseNumber,
                Subject__c = 'Test Notification',
                Subscriber__c = u.Id,
                Type__c = 'Emergency Case'
            );
            insert upn2;
            resultNotif = UNITY_ConsoleNotificationController.getNotification(upn2.Id);
            //Create a notification record type Emergency Case
            UNITY_Push_Notification__c upn3 = new UNITY_Push_Notification__c(
                Message__c = 'Test Message. Alert with record id',
                Record_Id__c = mycase.Id,
                Record_Name__c = myCase.CaseNumber,
                Subject__c = 'Test Notification',
                Subscriber__c = u.Id,
                Type__c = 'Alert'
            );
            insert upn3;
            resultNotif = UNITY_ConsoleNotificationController.getNotification(upn3.Id);
            //Create a notification record type Emergency Case
            UNITY_Push_Notification__c upn4 = new UNITY_Push_Notification__c(
                Message__c = 'Test Message. Other than Alert without record id',
                Record_Id__c = null,
                Record_Name__c = null,
                Subject__c = 'Test Notification',
                Subscriber__c = u.Id,
                Type__c = 'Emergency Case'
            );
            insert upn4;
            resultNotif = UNITY_ConsoleNotificationController.getNotification(upn4.Id);
            List<UNITY_ConsoleNotificationController.Notif> resultList = UNITY_ConsoleNotificationController.getMyNotifs();
            Test.stopTest();
        }
    }
}