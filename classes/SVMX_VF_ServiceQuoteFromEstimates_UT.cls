public class SVMX_VF_ServiceQuoteFromEstimates_UT {
static testMethod void SVMX_VF_ServiceQuoteFromEstimates_Test()
    {
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
        //Create Product
        Map<String,String> prodMap = TestDataProvider.getProductAndPriceBookEntry(1);
        String prid = '';
        for(String key :prodMap.keySet()){
            prid = key;
        } 
        
        //Create Work Order
        SVMXC__Service_Order__c svo = new SVMXC__Service_Order__c (
                                        SVMXC__Case__c = cs.Id ,
                                        SVMXC__Company__c = account.Id , 
                                        SVMXC__Order_Status__c = 'Open',
                                        SVMXC__Priority__c ='Medium',
                                        SVMXC__Order_Type__c='Field Service',
            							SVMXC__Component__c = IP1.id
                                        );
         insert svo;
         
         //create SVO Lines - Estimate
        RecordType rtSvoLine = [SELECT Id FROM RecordType WHERE SobjectType = 'SVMXC__Service_Order_Line__c' AND Name = 'Estimate' Limit 1];
        SVMXC__Service_Order_Line__c svol = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = svo.id,
            SVMXC__Product__c = prid,
            SVMXC__Line_Type__c = 'Parts',
            SVMXC__Activity_Type__c = 'Parts - New Construction',
            SVMXC__Estimated_Quantity2__c = 2,
            SVMXC__Estimated_Price2__c =2,
            SVMXC__Actual_Quantity2__c  =2,
            RecordTypeId = rtSvoLine.id
        );
        insert svol; 
        
        
        ApexPages.StandardController stdcontroller = new ApexPages.standardController(svo);

        
        //Test converage for the SVMX_VF_ServiceReport visualforce page
        PageReference pageRef = Page.SVMX_VF_ServiceQuoteFromEstimates;
        pageRef.getParameters().put('id',svo.Id);
        Test.setCurrentPageReference(pageRef);
        
        // create an instance of the controller
        SVMX_VF_ServiceQuoteFromEstimates myPageCon = new SVMX_VF_ServiceQuoteFromEstimates(stdcontroller);
        
        //try calling methods/properties of the controller in all possible scenarios
        // to get the best coverage.
        SVMXC__Service_Order__c pWO = myPageCon.getSVQFMEstimate();
    
        List<SVMXC__Service_Order_Line__c> pWOLines =  myPageCon.getSVQuoteDetails();
     
        String strWOdt =  myPageCon.getSVQEDate();
        String strCurrDt =  myPageCon.getCurrentDate();
        
        Date dat = System.today();
        String strDt =  myPageCon.getFormattedDate(dat);
        String str1 =  myPageCon.getcontype();
        String str2 =  myPageCon.getrender();  
       
         myPageCon.getREPTAG001();
         myPageCon.getREPTAG003();
         myPageCon.getREPTAG004();
         
         myPageCon.svmxTagList.clear();
         
         myPageCon.getREPTAG001();
         myPageCon.getREPTAG003();
         myPageCon.getREPTAG004();
    
      }
}