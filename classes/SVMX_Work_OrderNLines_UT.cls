public class SVMX_Work_OrderNLines_UT {
    static testMethod void SVMX_Work_OrderNLines_Test()
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
        //Create Product
        Map<String,String> prodMap = TestDataProvider.getProductAndPriceBookEntry(1);
        String prid = '';
        for(String key :prodMap.keySet()){
            prid = key;
			break;
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
        
        
        List<SVMXC__Service_Order_Line__c>  WOL = new List<SVMXC__Service_Order_Line__c>();
        WOL.add(svol);
        
        //Calling Class methods
        SVMX_Work_OrderNLines classInst = new SVMX_Work_OrderNLines();
        classInst.Assign(SVO, WOL);
        //SVMX_Work_OrderNLines classInst2 = new SVMX_Work_OrderNLines(SVO, WOL);
        
        WOL = classInst.getLines();
        
        SVMX_Work_Order classInst4 = new SVMX_Work_Order();
        classInst4 = classInst.getSVOHeader();
        
    }
}