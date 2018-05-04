public class SVMX_Work_Order_UT {
    static testMethod void SVMX_Work_Order_Test()
    {
        //Create Account
        Account  account = TestDataProvider.getAccounts(1,'Customer','Customer')[0]; 
        insert account;
        
        Contact contact = TestDataProvider.getContacts(1,account.Id)[0];
        insert contact;   
        
        SVMXC__Site__c loc = TestDataProvider.getLocations(1,'Location Site','SPSC',account.Id)[0];
        insert loc;
        // create IP
        SVMXC__Installed_Product__c IP1 = TestDataProvider.getInstalledProducts(1,'Installed Product',loc.Id,account.Id)[0];
		insert IP1;     
        //Create Case    
        Case cs = new Case(Status ='New', Priority = 'Medium',Origin = 'Email',ContactId =contact.Id,AccountId=account.Id,UNITY_Customer__c=account.Id); 
        insert cs;      
        
        //Create Work Order
        SVMXC__Service_Order__c svo = new SVMXC__Service_Order__c (
                                        SVMXC__Case__c = cs.Id ,
                                        SVMXC__Company__c = account.Id , 
                                        SVMXC__Order_Status__c = 'Open',
                                        SVMXC__Priority__c ='Medium',
                                        SVMXC__Order_Type__c='Field Service'
                                    );
        insert svo;
        
        SVMX_Work_Order classInst = new SVMX_Work_Order(svo);
        SVMX_Work_Order classInst2 = new SVMX_Work_Order();
        classInst2.setSVMX_WorkOrder(svo);
        
        SVMXC__Service_Order__c svo2 = classInst2.getSVMX_WorkOrder();
        String strDt2 =  classInst2.getWOCreatedDate(); 
        
        Date dat = System.today();
        String strDt =  classInst2.getFormattedDate(dat); //Sending Date Val
        dat =null;
        String strDt3 =  classInst2.getFormattedDate(dat); //Sending Null Value
        DateTime datTime =  System.now(); 
        String strDt4 =  classInst2.getFormattedDate(datTime); //Sending DateTime Value
        datTime = null;
        String strDt5 =  classInst2.getFormattedDate(datTime); //Sending null Value
        
    }
}