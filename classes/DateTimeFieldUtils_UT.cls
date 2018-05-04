@isTest
private class DateTimeFieldUtils_UT {

    static testMethod void DateTimeFieldUtilsUnitTest(){
        Account account = TestDataProvider.getAccounts(1,'Customer', 'Customer')[0];
        insert account;
 
 
        Contact contact = TestDataProvider.getContacts(1,account.Id)[0];
        insert contact;
 
       
        Case case1 = new Case(Status ='New', Priority = 'Medium',Origin = 'Email',ContactId =contact.Id,AccountId=account.Id,UNITY_Customer__c=account.Id);
        insert case1; 
       
        test.startTest();
       
        ApexPages.currentPage().getParameters().put('ObjId', case1.id);
        ApexPages.currentPage().getParameters().put('FieldAPIName', 'SVMXC__Actual_Initial_Response__c');
        ApexPages.currentPage().getParameters().put('ObjAPIName', 'Case');
        DateTimeFieldUtils dtf=new DateTimeFieldUtils();
        dtf.updateObject();
        ApexPages.currentPage().getParameters().put('ObjId', contact.id);
        ApexPages.currentPage().getParameters().put('FieldAPIName', 'SVMXC__Actual_Initial_Response__c');
        ApexPages.currentPage().getParameters().put('ObjAPIName', 'Case');
        DateTimeFieldUtils dtf2=new DateTimeFieldUtils();
        dtf2.updateObject();
        
        test.stopTest();
    }

}