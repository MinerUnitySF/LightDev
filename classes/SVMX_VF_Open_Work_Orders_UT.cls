public class SVMX_VF_Open_Work_Orders_UT {

    static testMethod void SVMX_VF_Open_Work_Orders_Test(){
        //Create Account
        Account ac = TestDataProvider.getAccounts(1,'Customer','Customer')[0];
        insert ac;
        //Create location
        SVMXC__Site__c location = TestDataProvider.getLocations(1,'Location Site','SPSC',ac.Id)[0];
        insert location;
        //Create Contact
        Contact  contact = TestDataProvider.getContacts(1,ac.Id)[0]; 
        insert contact; 
        //create IP
        SVMXC__Installed_Product__c ip1 = TestDataProvider.getInstalledProducts(1,'Installed Product',location.Id,ac.Id)[0];
        insert ip1;
        ip1 = [SELECT Id,Name,Serial_Number__c,SVMXC__Site__c,SVMXC__Company__c,SVMXC__Product__c FROM SVMXC__Installed_Product__c WHERE Id = :ip1.Id LIMIT 1];    
        //Create Case    
        Case cs = new Case(Status ='New', Priority = 'Medium',Origin = 'Email',ContactId =contact.Id,AccountId=ac.Id,UNITY_Customer__c=ac.Id); 
        insert cs;      

        //Create Work Order
        SVMXC__Service_Order__c svo = new SVMXC__Service_Order__c (
                                        SVMXC__Case__c = cs.Id ,
                                        SVMXC__Company__c = ac.Id , 
                                        SVMXC__Order_Status__c = 'Open',
                                        SVMXC__Priority__c ='Medium',
                                        SVMXC__Order_Type__c='Field Service',
                                        SVMXC__Component__c = ip1.id
                                        );
         insert svo;
         //create SVO Lines - Estimate
        RecordType rtSvoLine = [SELECT Id FROM RecordType WHERE SobjectType = 'SVMXC__Service_Order_Line__c' AND Name = 'Estimate' Limit 1];
        SVMXC__Service_Order_Line__c svol = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = svo.id,
            SVMXC__Product__c = ip1.SVMXC__Product__c,
            SVMXC__Line_Type__c = 'Parts',
            SVMXC__Activity_Type__c = 'Parts - Service and Remodel',
            SVMXC__Estimated_Quantity2__c = 2,
            SVMXC__Estimated_Price2__c = 2,
            SVMXC__Actual_Quantity2__c  = 2,
            RecordTypeId = rtSvoLine.id
        );
        insert svol; 
        
        
       ApexPages.StandardController stdcontroller = new ApexPages.standardController(svo);
       //ApexPages.StandardController stdcontroller1 = new ApexPages.standardController(svol);

        
        //Test converage for the SVMX_VF_ServiceReport visualforce page
        PageReference pageRef = Page.SVMX_VF_Open_Work_Orders;
        pageRef.getParameters().put('id',svo.Id);
        Test.setCurrentPageReference(pageRef);
        
        // create an instance of the controller
        SVMX_VF_Open_Work_Orders myPageCon = new SVMX_VF_Open_Work_Orders(stdcontroller);
       // SVMX_VF_Open_Work_Orders myPageCon1 = new SVMX_VF_Open_Work_Orders(stdcontroller1);
        //try calling methods/properties of the controller in all possible scenarios
        // to get the best coverage.
        List<SVMX_Work_OrderNLines> lWO = new List<SVMX_Work_OrderNLines>();
        lWO = myPageCon.getWorkOrders();
        
        List<SVMXC__Service_Order_Line__c> lWOLines = new List<SVMXC__Service_Order_Line__c>();
        lWOLines =  myPageCon.getWorkOrderDetail(svo);

        ////SVMXC__Service_Order__c soCreatDt = myPageCon.getWOCreatedDate();
        //String strWOdt =  myPageCon.getWODate();
        String strCurrDt =  myPageCon.getCurrentDate();
        
        Date dat = System.today();
        String strDt =  myPageCon.getFormattedDate(dat); //Sending Date Val
        dat = null;
        String strDt3 =  myPageCon.getFormattedDate(dat); //Sending Null Value
        DateTime datTime =  System.now(); 
        String strDt4 =  myPageCon.getFormattedDate(datTime); //Sending DateTime Value
        datTime = null;
        String strDt5 =  myPageCon.getFormattedDate(datTime); //Sending null Value
        string strDt6 = myPageCon.getcontype();
        string strDt7 = myPageCon.getrender();
        
           myPageCon.getREPTAG001();
           myPageCon.getREPTAG001();

           myPageCon.svmxTagList.clear();
           
           myPageCon.getREPTAG001();
           myPageCon.getREPTAG001();


   
    }
}