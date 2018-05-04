@isTest(SeeAllData=true)
private class UpdateDetailRollUpFieldsOnWorkOrder_UT {

	static testMethod void myUnitTest() {
		//Create Account
		Account ac = TestDataProvider.getAccounts(1,'Customer','Customer')[0]; 
		insert ac;
		
        Contact contact = TestDataProvider.getContacts(1,ac.Id)[0];
        insert contact;   
        
        SVMXC__Site__c loc = TestDataProvider.getLocations(1,'Location Site','SPSC',ac.Id)[0];
        insert loc;
        // create IP
        SVMXC__Installed_Product__c IP1 = TestDataProvider.getInstalledProducts(1,'Installed Product',loc.Id,ac.Id)[0];
		insert IP1;	  
		
		//Create Case	
		Case cs = new Case(
            Status ='New', 
            Priority = 'Medium',
            Origin = 'Email',
            ContactId = contact.Id,
            AccountId = ac.Id,
            UNITY_Customer__c = ac.Id
        ); 
		insert cs;	  
		//Create Product
		Map<String,String> prodMap = TestDataProvider.getProductAndPriceBookEntry(1);
        String prId = '';
        for(String key :prodMap.keySet()){
            prId = key;
			break;
        }
		
		//Create Work Order
		SVMXC__Service_Order__c svo = new SVMXC__Service_Order__c (
										SVMXC__Case__c = cs.Id ,
										SVMXC__Company__c = ac.Id , 
										Estimated_Work_Total__c=0,
										Work_Order_Total__c=0,
										Sales_Tax_Total__c=0,
										SVMXC__Order_Status__c = 'Open',
										SVMXC__Priority__c ='Medium',
										SVMXC__Order_Type__c='Field Service',
            							SVMXC__Component__C = IP1.id
										);
		insert svo;
		//create SVO Lines - Estimate
		RecordType rtSvoLine = [SELECT Id FROM RecordType WHERE SobjectType = 'SVMXC__Service_Order_Line__c' AND Name = 'Estimate' Limit 1];
		RecordType rtSvoLine1 = [SELECT Id FROM RecordType WHERE SobjectType = 'SVMXC__Service_Order_Line__c' AND DeveloperName = 'UsageConsumption' Limit 1];
        SVMXC__Service_Order_Line__c svol = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = svo.id,
            SVMXC__Product__c = prid,
            SVMXC__Line_Type__c = 'Parts',
            SVMXC__Activity_Type__c = 'Parts - New Construction',
            SVMXC__Estimated_Quantity2__c = 2,
            SVMXC__Estimated_Price2__c = 2,
            SVMXC__Actual_Quantity2__c = 2,
            SVMXC__Actual_Price2__c = 2,
            RecordTypeId = rtSvoLine.id
        );
        
        
        SVMXC__Service_Order_Line__c svol1 = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = svo.id,
            SVMXC__Product__c = prid,
            SVMXC__Line_Type__c = 'Parts',
            SVMXC__Activity_Type__c = 'Parts - New Construction',
            Sales_Tax__c=3,
            SVMXC__Estimated_Quantity2__c = 2,
            SVMXC__Estimated_Price2__c = 2,
            SVMXC__Actual_Quantity2__c = 2,
            SVMXC__Actual_Price2__c = 2,
            RecordTypeId = rtSvoLine1.id
        );
		Test.startTest();
		insert new List<SVMXC__Service_Order_Line__c>{svol,svol1};
		svol1.Sales_Tax__c=4;
		update svol1;
		svol.SVMXC__Actual_Price2__c=3;
		svol.SVMXC__Actual_Quantity2__c=2;
		update svol;
		//delete svol1;
		//delete svol;
		Test.stopTest();
	   
		SVMXC__Service_Order__c newwo = [select  Estimated_Work_Total__c,
										Work_Order_Total__c,
										Sales_Tax_Total__c from SVMXC__Service_Order__c where id=:svo.id];
	    //System.assertEquals(4, newwo.Estimated_Work_Total__c);
	    //System.assertEquals(4, newwo.Sales_Tax_Total__c);
	    //System.assertEquals(4, newwo.Work_Order_Total__c);
		
	}
}

/*
The Estimated_Work_Total__c field should be the sum of the "Total_Line_PriceMH__c" field on all 
Estimate record type work details on the work order. 

The Work_Order_Total__c field should be the sum of the "Total_Line_PriceMH__c" 
field on all "Usage/Consumption" record type work details on the work order.

The Sales_Tax_Total__c field should be the sum of the Sales_Tax__c field on all "Usage/Consupmtion" 
record type work details on the work order. */