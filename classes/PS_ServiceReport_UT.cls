public with sharing class PS_ServiceReport_UT {
    
    static Account ac; static Contact ct; static Case cs; static SVMXC__Service_Order__c svo;
    
    public static void setupTest(){
        //Create Account
        ac = TestDataProvider.getAccounts(1,'Customer','Customer')[0]; 
        insert ac;    
        //Create Contact
        ct = TestDataProvider.getContacts(1,ac.Id)[0];
        insert ct;      
        //Create Case    
        cs = new Case(Status ='New', Priority = 'Medium',Origin = 'Email',ContactId =ct.Id,AccountId=ac.Id,UNITY_Customer__c=ac.Id); 
        insert cs;     
        
        //Create Work Order
        svo = new SVMXC__Service_Order__c (
                                        SVMXC__Case__c = cs.Id ,
                                        SVMXC__Company__c = ac.Id , 
                                        SVMXC__Order_Status__c = 'Open',
                                        SVMXC__Priority__c ='Medium',
                                        SVMXC__Order_Type__c='Field Service'
                                        );
         insert svo;        
    }
    
    static testMethod void SVMX_PS_ServiceReport_Test(){        
        ac=null; ct=null; cs=null; svo=null;
        setupTest();
        
        //Test converage for the PS_ServiceReport visualforce page
        PageReference pageRef = Page.PS_ServiceReport;
        pageRef.getParameters().put('RecordId',svo.Id);
        Test.setCurrentPageReference(pageRef);
        
        // create an instance of the controller
        PS_ServiceReport myPageCon = new PS_ServiceReport();
        
        //try calling methods/properties of the controller in all possible scenarios
        // to get the best coverage.
        SVMXC__Service_Order__c pWO = myPageCon.getWorkOrder();
    
        List<SVMXC__Service_Order_Line__c> pWOLines =  myPageCon.getWorkOrderDetail();
        pWOLines =  myPageCon.getWorkOrderEstimate();
     
        //String strWOdt =  myPageCon.getWODate();
        String strCurrDt =  myPageCon.getCurrentDate();
        
        Date dat = System.today();
        String strDt =  myPageCon.getFormattedDate(dat);
        String str1 =  myPageCon.getcontype();
        String str2 =  myPageCon.getrender();  
            
    } 
    static testMethod void SVMX_PS_ServiceReportEST_Test(){ 
        ac=null; ct=null; cs=null; svo=null;
        setupTest();
        
        //Test coverage for the SVMX_VF_ServiceReport visualforce page
        PageReference pageRef = Page.SVMX_PS_ServiceReportEST;
        pageRef.getParameters().put('RecordId',svo.Id);
        Test.setCurrentPageReference(pageRef);
        
        // create an instance of the controller
        SVMX_PS_ServiceReportEST myPageCon = new SVMX_PS_ServiceReportEST();
        
        //try calling methods/properties of the controller in all possible scenarios
        // to get the best coverage.
        SVMXC__Service_Order__c pWO = myPageCon.getWorkOrder();
    
        List<SVMXC__Service_Order_Line__c> pWOLines =  myPageCon.getWorkOrderDetail();
     
        //String strWOdt =  myPageCon.getWODate();
        String strCreateDt = myPageCon.getCreateDate();
        String strCloseDt = myPageCon.getCloseDate();
        String strFormDt = myPageCon.getFormattedDate(svo.CreatedDate);
        String strCurrDt =  myPageCon.getCurrentDate();
        
        Date dat = System.today();
        String strDt =  myPageCon.getFormattedDate(dat);
        String str1 =  myPageCon.getcontype();
        String str2 =  myPageCon.getrender();  
            
    } 
}