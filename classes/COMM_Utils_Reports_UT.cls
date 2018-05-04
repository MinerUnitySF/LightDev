public class COMM_Utils_Reports_UT {
	
	public static testmethod void test(){
		try{
			test.startTest();
            
			string strUserID = UserInfo.getUserId();
			string strSessionID = UserInfo.getSessionId();
			list<SVMXC__RMA_Shipment_Order__c> lstRMA = new list<SVMXC__RMA_Shipment_Order__c>();
			
			RecordType rtRMA = [SELECT Id , Name,SobjectType  FROM RecordType WHERE SObjectType = 'SVMXC__RMA_Shipment_Order__c' AND Name = 'RMA' LIMIT 1];
			
			Account account = TestDataProvider.getAccounts(1, 'Customer Account', 'Customer')[0]; 
			insert account;
			        
			Contact contact = TestDataProvider.getContacts(1, account.Id)[0];
			insert contact;
			
			Case case1 = new Case(Status ='New', Priority = 'Medium',Origin = 'Email',ContactId =contact.Id,AccountId=account.Id); 
			insert case1;
			
			SVMXC__Site__c sourceLocation = new SVMXC__Site__c(SVMXC__Zip__c ='90909090',SVMXC__Street__c ='ABC',SVMXC__State__c ='ABC',SVMXC__Country__c ='ABC',SVMXC__City__c ='ABC',SVMXC__Account__c=account.Id);
			insert sourceLocation;    
			
			SVMXC__Site__c destLocation = new SVMXC__Site__c(SVMXC__Zip__c ='90909090',SVMXC__Street__c ='ABC',SVMXC__State__c ='ABC',SVMXC__Country__c ='ABC',SVMXC__City__c ='ABC',SVMXC__Account__c=account.Id);
			insert destLocation;
			
			SVMXC__RMA_Shipment_Order__c o1 = new SVMXC__RMA_Shipment_Order__c(SVMXC__Source_Location__c =sourceLocation.Id,SVMXC__Expected_Delivery_Date__c =System.today(),SVMXC__Destination_Location__c=destLocation.Id,SVMXC__Contact__c =contact.Id,SVMXC__Company__c=account.Id,SVMXC__Case__c =case1.Id,RecordTypeId = rtRMA.Id,SVMXC__Order_Status__c='Open');                  
			lstRMA.add(o1);
			insert lstRMA;
	        
	        list<SVMXC__ServiceMax_List__c> lstSL = new list<SVMXC__ServiceMax_List__c>();
	        SVMXC__ServiceMax_List__c oSL1 = new SVMXC__ServiceMax_List__c ( SVMXC__Object_Id__c =o1.Id, SVMXC__Salesforce_Session_ID__c ='ServiceMax', SVMXC__User__c = strUserID);
	        SVMXC__ServiceMax_List__c oSL2 = new SVMXC__ServiceMax_List__c ( SVMXC__Object_Id__c =o1.Id, SVMXC__Salesforce_Session_ID__c = strSessionID, SVMXC__User__c = strUserID);
	        lstSL.add(oSL1);
	        lstSL.add(oSL2);
	        insert lstSL;
	                
	        ApexPages.StandardSetController setController = new ApexPages.StandardSetController(lstRMA);
	        setController.setselected(lstRMA);
	        
	        COMM_Utils_Reports controller = new COMM_Utils_Reports();
	        controller.getServiceMaxList(setController, 'SVMXC.RMA_Shipment_Order.Shipment', strUserID, strSessionID);
	
			//controller.getSelectTempPage(lstSL, 'SVMXC.RMA_Shipment_Order.Shipment',true, '' );
			//controller.getSelectTempPage(lstSL, 'SVMXC.RMA_Shipment_Order.Shipment',false, oSL1.Id );
	     
	        COMM_Utils_Reports.SVMX_ListCleanUp(strUserID, strSessionID);
	        COMM_Utils_Reports.getcontype('pdf');
	        COMM_Utils_Reports.getcontype('xls');
	        COMM_Utils_Reports.getcontype('doc');
	        
	        Date d;
	        DateTime dt;
	        COMM_Utils_Reports.getFormattedDate(Date.today());
	        COMM_Utils_Reports.getFormattedDate(DateTime.now());
	        COMM_Utils_Reports.getFormattedDate(d);
	        COMM_Utils_Reports.getFormattedDate(dt);
	    	test.stopTest();
    	}
		catch(exception ex){
            System.debug('====== Error: ' + ex.getMessage());
            Apexpages.addMessage(new ApexPages.Message ( ApexPages.Severity.ERROR,ex.getmessage()));
        }
        
    }
}