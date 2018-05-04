@isTest
private class TEST_MSPFS_NewQuoteItemContExt {
	
	private static Account accountCustomer;
	private static Account accountVendor;
	private static List<UNITY_Service_Contract__c> serviceContractsVendor;
	private static List<UNITY_Service_Contract__c> serviceContractsCustomer;
	private static List<Contact> contacts;
	private static List<Case> cases;
	private static List<UNITY_Service_Contract__c> serviceContracts;
	private static List<WorkOrder> workOrders;
	private static List<User> technicians;
	private static UNITY_Proposal__c quote;
	private static Asset testAsset;
	private static Product2 testLaborProduct;
	private static Product2 testTravelProduct;
	private static Product2 testPartProduct;
	private static Product2 testFreightProduct;
	private static PricebookEntry testLaborPBE;
	private static PricebookEntry testTravelPBE;
	private static PricebookEntry testPartPBE;
	private static PricebookEntry testFreightPBE;
	private static FSO__Location__c location;

	static void setup() {
		
		accountCustomer = UNITY_TestDataFactory.createAccounts( 1, 'Site/Location', UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE ).get(0);
        accountVendor = UNITY_TestDataFactory.createAccounts( 1, 'Customer', UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE ).get(0);

        system.debug('##### accountVendor.Id: '+accountVendor.Id);

        serviceContractsVendor = UNITY_TestDataFactory.createServiceContracts( 2, accountVendor.id );
        serviceContractsCustomer = UNITY_TestDataFactory.createServiceContracts( 2, accountCustomer.Id );
        contacts = UNITY_TestDataFactory.createContacts( 2, accountCustomer.Id );
        cases = UNITY_TestDataFactory.createCases( 2, accountCustomer.Id, accountVendor.Id, contacts.get(0).Id, UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE );
        serviceContracts = UNITY_TestDataFactory.createServiceContracts( 1, accountCustomer.Id );
        workOrders = UNITY_TestDataFactory.createWorkOrders( 2, cases.get(0).Id,accountCustomer.Id, serviceContracts.get(0).Id, UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE );
        
        technicians = UNITY_TestDataFactory.createUsersTechnician( 1, contacts.get(0).Id );

        testAsset = new Asset( Name = 'Test', AccountId = accountVendor.Id );
        insert testAsset;
        
        List<Product2> products = new List<Product2>();
        testLaborProduct = new Product2( Name = 'TestLaborProduct_IP', ProductCode = 'Miner-Labor', Make1__c = 'TestMake', Model__c = 'TestModel', Broad__c = 'Door',
			Group__c = 'High Speed', Type__c = 'Electrical', Family = 'Equipment', SVMXC__Product_Line__c = 'Equipment', IsActive = true, Description = 'Installed Product Test Product',
			SVMXC__Product_Cost__c = 0.00, SVMXC__Inherit_Parent_Warranty__c = true, UNITY_Status__c = 'Active', UNITY_Product_Cost__c = 0, UNITY_Unit_Of_Measure__c = 'Each',
			UNITY_Product_Type__c = 'Labor'
		);
		testTravelProduct = new Product2( Name = 'TestTravelProduct_IP', ProductCode = 'Miner-Travel', Make1__c = 'TestMake1', Model__c = 'TestModel1', Broad__c = 'Door',
			Group__c = 'High Speed', Type__c = 'Electrical', Family = 'Equipment', SVMXC__Product_Line__c = 'Equipment', IsActive = true, Description = 'Travel to job site.',
			SVMXC__Product_Cost__c = 0.00, SVMXC__Inherit_Parent_Warranty__c = true, UNITY_Status__c = 'Active', UNITY_Product_Cost__c = 0, UNITY_Unit_Of_Measure__c = 'Each',
			UNITY_Product_Type__c = 'Travel'
		);
		testPartProduct = new Product2( Name = 'TestPartProduct_IP', ProductCode = 'Miner-Part', Make1__c = 'TestMake', Model__c = 'TestModel', Broad__c = 'Door',
			Group__c = 'High Speed', Type__c = 'Electrical', Family = 'Equipment', SVMXC__Product_Line__c = 'Equipment', IsActive = true, Description = 'Door',
			SVMXC__Product_Cost__c = 0.00, SVMXC__Inherit_Parent_Warranty__c = true, UNITY_Status__c = 'Active', UNITY_Product_Cost__c = 0, UNITY_Unit_Of_Measure__c = 'Each',
			UNITY_Product_Type__c = 'Part'
		);
		testFreightProduct = new Product2( Name = 'TestFreightProduct_IP', ProductCode = 'Miner-Freight', Make1__c = 'TestMake1', Model__c = 'TestModel1', Broad__c = 'Door',
			Group__c = 'High Speed', Type__c = 'Electrical', Family = 'Equipment', SVMXC__Product_Line__c = 'Equipment', IsActive = true, Description = 'Freight',
			SVMXC__Product_Cost__c = 0.00, SVMXC__Inherit_Parent_Warranty__c = true, UNITY_Status__c = 'Active', UNITY_Product_Cost__c = 0, UNITY_Unit_Of_Measure__c = 'Each',
			UNITY_Product_Type__c = 'Freight'
		);
		products.add( testLaborProduct );
		products.add( testTravelProduct );
		products.add( testPartProduct );
		products.add( testFreightProduct );
		insert products;

		List<PricebookEntry> pBEs = new List<PricebookEntry>();
		testLaborPBE = new PricebookEntry( Product2Id = testLaborProduct.Id, Pricebook2Id = Test.getStandardPricebookId() , UnitPrice = 2, Cost__c = 1 );
		testTravelPBE = new PricebookEntry( Product2Id = testTravelProduct.Id, Pricebook2Id = Test.getStandardPricebookId() , UnitPrice = 2, Cost__c = 1 );
		testPartPBE = new PricebookEntry( Product2Id = testPartProduct.Id, Pricebook2Id = Test.getStandardPricebookId() , UnitPrice = 2, Cost__c = 1 );
		testFreightPBE = new PricebookEntry( Product2Id = testFreightProduct.Id, Pricebook2Id = Test.getStandardPricebookId() , UnitPrice = 2, Cost__c = 1 );
		pBEs.add( testLaborPBE );
		pBEs.add( testTravelPBE );
		pBEs.add( testPartPBE );
		pBEs.add( testFreightPBE );
		insert pBEs;

        location = new FSO__Location__c( FSO__Geolocation__Latitude__s = 10, FSO__Geolocation__Longitude__s = 10 );
		insert location; 

		TestDataProvider.setKeyValueStore();
	}

	@isTest 
	static void testInitializationNoLinesNoStatus() {
		setup();

		test.startTest();
		quote = UNITY_TestDataFactory.createQuote( 1, cases[0].Id, workOrders[0].Id, accountCustomer.Id, UserInfo.getUserId() )[0];
		ApexPages.StandardController stdQuote = new ApexPages.StandardController( quote );
		MSPFS_NewQuoteItemContExt quoteContExt = new MSPFS_NewQuoteItemContExt( stdQuote );
		test.stopTest();

		System.assertEquals( 0, ApexPages.getMessages().size() );
		System.assertEquals( false, quoteContExt.hasError );
		System.assertEquals( true, quoteContExt.canEdit );
	}

	@isTest 
	static void testInitializationWithLinesNoStatus() {
		setup();

		test.startTest();
		quote = UNITY_TestDataFactory.createQuote( 1, cases[0].Id, workOrders[0].Id, accountCustomer.Id, UserInfo.getUserId() )[0];
		UNITY_Proposal_Line_Item__c newQuoteLine = new UNITY_Proposal_Line_Item__c(
			UNITY_Proposal__c = quote.Id, UNITY_Quantity__c = 1, UNITY_Activity_Type__c = 'Standard Labor', UNITY_Cost__c = 1, UNITY_Type__c = 'Labor - Service',
			UNITY_Asset__c = testAsset.Id, UNITY_Unit_Price__c = 1, UNITY_Product__c = testLaborProduct.Id, UNITY_Part_Location__c = location.Id, UNITY_Part_Source__c = accountVendor.Id
		);
		insert newQuoteLine;

		ApexPages.StandardController stdQuote = new ApexPages.StandardController( quote );
		MSPFS_NewQuoteItemContExt quoteContExt = new MSPFS_NewQuoteItemContExt( stdQuote );
		test.stopTest();

		System.assertEquals( 0, ApexPages.getMessages().size() );
		System.assertEquals( false, quoteContExt.hasError );
		System.assertEquals( true, quoteContExt.canEdit );
	}

	@isTest 
	static void testInitializationWithLinesCustomerApprovedStatus() {
		setup();

		test.startTest();
		quote = UNITY_TestDataFactory.createQuote( 1, cases[0].Id, workOrders[0].Id, accountCustomer.Id, UserInfo.getUserId() )[0];
		quote.UNITY_Proposal_Status__c = UNITY_Constants.QT_STATUS_CUSTOMER_APPROVED;
		update quote;

		UNITY_Proposal_Line_Item__c newQuoteLine = new UNITY_Proposal_Line_Item__c(
			UNITY_Proposal__c = quote.Id, UNITY_Quantity__c = 1, UNITY_Activity_Type__c = 'Standard Labor', UNITY_Cost__c = 1, UNITY_Type__c = 'Labor - Service',
			UNITY_Asset__c = testAsset.Id, UNITY_Unit_Price__c = 1, UNITY_Product__c = testLaborProduct.Id, UNITY_Part_Location__c = location.Id, UNITY_Part_Source__c = accountVendor.Id
		);
		insert newQuoteLine;

		ApexPages.StandardController stdQuote = new ApexPages.StandardController( quote );
		MSPFS_NewQuoteItemContExt quoteContExt = new MSPFS_NewQuoteItemContExt( stdQuote );
		test.stopTest();

		System.assertEquals( 1, ApexPages.getMessages().size() );
		System.assert( ApexPages.getMessages()[0].getDetail().contains('This Quote cannot be modified.') );
		System.assertEquals( true, quoteContExt.hasError );
		System.assertEquals( false, quoteContExt.canEdit );
	}

	@isTest 
	static void testWithoutLinesAddUncompletedLineQuickSave() {
		setup();

		test.startTest();
		quote = UNITY_TestDataFactory.createQuote( 1, cases[0].Id, workOrders[0].Id, accountCustomer.Id, UserInfo.getUserId() )[0];
		update quote;

		ApexPages.StandardController stdQuote = new ApexPages.StandardController( quote );
		MSPFS_NewQuoteItemContExt quoteContExt = new MSPFS_NewQuoteItemContExt( stdQuote );

		System.assertEquals( 0, quoteContExt.quoteLines.size() );

		quoteContExt.addItem();

		quoteContExt.quoteLines[0].item.UNITY_Product__c = testLaborProduct.Id;
		quoteContExt.quoteLines[0].item.UNITY_Is_Vendor_Supply__c = true;

		quoteContExt.doQuickSave();

		test.stopTest();

		System.assertEquals( 1, quoteContExt.quoteLines.size() );
		System.assertEquals( 2, ApexPages.getMessages().size() );
		System.assertEquals( true, quoteContExt.hasError );
		System.assertEquals( true, quoteContExt.canEdit );
	}

	@isTest 
	static void testWithoutLinesAddCompletedLineQuickSave() {
		setup();

		test.startTest();
		quote = UNITY_TestDataFactory.createQuote( 1, cases[0].Id, workOrders[0].Id, accountCustomer.Id, UserInfo.getUserId() )[0];
		update quote;

		ApexPages.StandardController stdQuote = new ApexPages.StandardController( quote );
		MSPFS_NewQuoteItemContExt quoteContExt = new MSPFS_NewQuoteItemContExt( stdQuote );

		System.assertEquals( 0, quoteContExt.quoteLines.size() );

		quoteContExt.addItem();

		quoteContExt.quoteLines[0].item.UNITY_Product__c = testLaborProduct.Id;
		quoteContExt.quoteLines[0].item.UNITY_Type__c = 'Labor - Installation';
		quoteContExt.quoteLines[0].item.UNITY_Activity_Type__c = 'Standard Labor';
		quoteContExt.quoteLines[0].item.UNITY_Quantity__c = 1;
		quoteContExt.quoteLines[0].item.UNITY_Cost__c = 5;
		quoteContExt.quoteLines[0].item.UNITY_Is_Vendor_Supply__c = true;

		quoteContExt.doQuickSave();

		test.stopTest();

		System.assertEquals( 1, quoteContExt.quoteLines.size() );
		System.assertEquals( 0, ApexPages.getMessages().size() );
		System.assertEquals( false, quoteContExt.hasError );
	}

	@isTest 
	static void testWithoutLinesAddCompletedLineSaveDelLine() {
		setup();

		test.startTest();
		quote = UNITY_TestDataFactory.createQuote( 1, cases[0].Id, workOrders[0].Id, accountCustomer.Id, UserInfo.getUserId() )[0];
		update quote;

		ApexPages.StandardController stdQuote = new ApexPages.StandardController( quote );
		MSPFS_NewQuoteItemContExt quoteContExt = new MSPFS_NewQuoteItemContExt( stdQuote );

		System.assertEquals( 0, quoteContExt.quoteLines.size() );

		quoteContExt.addItem();

		quoteContExt.quoteLines[0].item.UNITY_Product__c = testLaborProduct.Id;
		quoteContExt.quoteLines[0].item.UNITY_Type__c = 'Labor - Installation';
		quoteContExt.quoteLines[0].item.UNITY_Activity_Type__c = 'Standard Labor';
		quoteContExt.quoteLines[0].item.UNITY_Quantity__c = 1;
		quoteContExt.quoteLines[0].item.UNITY_Cost__c = 5;
		quoteContExt.quoteLines[0].item.UNITY_Is_Vendor_Supply__c = true;

		quoteContExt.doSave();

		quoteContExt.deleteSel();

		test.stopTest();

		System.assertEquals( 1, quoteContExt.quoteLines.size() );
		System.assertEquals( 0, ApexPages.getMessages().size() );
		System.assertEquals( false, quoteContExt.hasError );
	}

	@isTest 
	static void testWithoutLinesAddCompletedLineSave() {
		setup();

		test.startTest();
		quote = UNITY_TestDataFactory.createQuote( 1, cases[0].Id, workOrders[0].Id, accountCustomer.Id, UserInfo.getUserId() )[0];
		update quote;

		ApexPages.StandardController stdQuote = new ApexPages.StandardController( quote );
		MSPFS_NewQuoteItemContExt quoteContExt = new MSPFS_NewQuoteItemContExt( stdQuote );

		System.assertEquals( 0, quoteContExt.quoteLines.size() );

		quoteContExt.addItem();

		quoteContExt.quoteLines[0].item.UNITY_Product__c = testLaborProduct.Id;
		quoteContExt.quoteLines[0].item.UNITY_Type__c = 'Labor - Installation';
		quoteContExt.quoteLines[0].item.UNITY_Activity_Type__c = 'Standard Labor';
		quoteContExt.quoteLines[0].item.UNITY_Quantity__c = 1;
		quoteContExt.quoteLines[0].item.UNITY_Cost__c = 5;
		quoteContExt.quoteLines[0].item.UNITY_Is_Vendor_Supply__c = true;

		quoteContExt.doSave();

		test.stopTest();

		System.assertEquals( 1, quoteContExt.quoteLines.size() );
		System.assertEquals( 0, ApexPages.getMessages().size() );
		System.assertEquals( false, quoteContExt.hasError );
	}

	@isTest 
	static void testWithoutLinesAddCompletedLaborLineThenProductChangeMNS() {
		setup();

		test.startTest();
		quote = UNITY_TestDataFactory.createQuote( 1, cases[0].Id, workOrders[0].Id, accountCustomer.Id, UserInfo.getUserId() )[0];
		quote.UNITY_Business_Unit__c = 'MNS';
		update quote;

		ApexPages.StandardController stdQuote = new ApexPages.StandardController( quote );
		MSPFS_NewQuoteItemContExt quoteContExt = new MSPFS_NewQuoteItemContExt( stdQuote );

		PageReference quotePage = Page.MSPFS_NewQuoteItem;
		Test.setCurrentPage( quotePage );

		System.assertEquals( 0, quoteContExt.quoteLines.size() );

		quoteContExt.addItem();

		quoteContExt.quoteLines[0].item.UNITY_Product__c = testLaborProduct.Id;
		quoteContExt.quoteLines[0].item.UNITY_Product__r = testLaborProduct;
		quoteContExt.quoteLines[0].item.UNITY_Part_Location__c = location.Id;
		quoteContExt.quoteLines[0].item.UNITY_Part_Source__c = accountVendor.Id;
		quoteContExt.quoteLines[0].item.UNITY_Type__c = 'Labor - Installation';
		quoteContExt.quoteLines[0].item.UNITY_Activity_Type__c = 'Standard Labor';
		quoteContExt.quoteLines[0].item.UNITY_Quantity__c = 1;
		quoteContExt.quoteLines[0].item.UNITY_Cost__c = 5;
		quoteContExt.quoteLines[0].item.UNITY_Is_Vendor_Supply__c = true;

		quotePage.getParameters().put( 'index', string.valueOf(quoteContExt.quoteLines[0].index) );
		quotePage.getParameters().put( 'myValue', testLaborProduct.Id );

		quoteContExt.onProductChange();
		quoteContExt.quoteLines[0].onProductChange();
		quoteContExt.quoteLines[0].onVendorSupplyChange();

		test.stopTest();

		System.assertEquals( 1, quoteContExt.quoteLines.size() );
		System.assertEquals( 0, ApexPages.getMessages().size() );
		System.assertEquals( false, quoteContExt.hasError );
	}

	@isTest 
	static void testWithoutLinesAddCompletedTravelLineThenProductChangeMNS() {
		setup();

		test.startTest();
		quote = UNITY_TestDataFactory.createQuote( 1, cases[0].Id, workOrders[0].Id, accountCustomer.Id, UserInfo.getUserId() )[0];
		quote.UNITY_Business_Unit__c = 'MNS';
		update quote;

		ApexPages.StandardController stdQuote = new ApexPages.StandardController( quote );
		MSPFS_NewQuoteItemContExt quoteContExt = new MSPFS_NewQuoteItemContExt( stdQuote );

		PageReference quotePage = Page.MSPFS_NewQuoteItem;
		Test.setCurrentPage( quotePage );

		System.assertEquals( 0, quoteContExt.quoteLines.size() );

		quoteContExt.addItem();

		quoteContExt.quoteLines[0].item.UNITY_Product__c = testTravelProduct.Id;
		quoteContExt.quoteLines[0].item.UNITY_Product__r = testTravelProduct;
		quoteContExt.quoteLines[0].item.UNITY_Part_Location__c = location.Id;
		quoteContExt.quoteLines[0].item.UNITY_Part_Source__c = accountVendor.Id;
		quoteContExt.quoteLines[0].item.UNITY_Type__c = 'Travel';
		quoteContExt.quoteLines[0].item.UNITY_Activity_Type__c = 'Standard Travel';
		quoteContExt.quoteLines[0].item.UNITY_Quantity__c = 1;
		quoteContExt.quoteLines[0].item.UNITY_Cost__c = 5;
		quoteContExt.quoteLines[0].item.UNITY_Is_Vendor_Supply__c = true;

		quotePage.getParameters().put( 'index', string.valueOf(quoteContExt.quoteLines[0].index) );

		quoteContExt.quoteLines[0].onProductChange();
		quoteContExt.quoteLines[0].onVendorSupplyChange();

		test.stopTest();

		System.assertEquals( 1, quoteContExt.quoteLines.size() );
		System.assertEquals( 0, ApexPages.getMessages().size() );
		System.assertEquals( false, quoteContExt.hasError );
	}

	@isTest 
	static void testWithoutLinesAddCompletedPartLineThenProductChangeMNS() {
		setup();

		test.startTest();
		quote = UNITY_TestDataFactory.createQuote( 1, cases[0].Id, workOrders[0].Id, accountCustomer.Id, UserInfo.getUserId() )[0];
		quote.UNITY_Business_Unit__c = 'MNS';
		update quote;

		ApexPages.StandardController stdQuote = new ApexPages.StandardController( quote );
		MSPFS_NewQuoteItemContExt quoteContExt = new MSPFS_NewQuoteItemContExt( stdQuote );

		PageReference quotePage = Page.MSPFS_NewQuoteItem;
		Test.setCurrentPage( quotePage );

		System.assertEquals( 0, quoteContExt.quoteLines.size() );

		quoteContExt.addItem();

		quoteContExt.quoteLines[0].item.UNITY_Product__c = testPartProduct.Id;
		quoteContExt.quoteLines[0].item.UNITY_Product__r = testPartProduct;
		quoteContExt.quoteLines[0].item.UNITY_Part_Location__c = location.Id;
		quoteContExt.quoteLines[0].item.UNITY_Part_Source__c = accountVendor.Id;
		quoteContExt.quoteLines[0].item.UNITY_Type__c = 'Parts';
		quoteContExt.quoteLines[0].item.UNITY_Activity_Type__c = 'Parts - New Construction';
		quoteContExt.quoteLines[0].item.UNITY_Quantity__c = 1;
		quoteContExt.quoteLines[0].item.UNITY_Cost__c = 5;
		quoteContExt.quoteLines[0].item.UNITY_Is_Vendor_Supply__c = true;

		quotePage.getParameters().put( 'index', string.valueOf(quoteContExt.quoteLines[0].index) );

		quoteContExt.quoteLines[0].onProductChange();
		quoteContExt.quoteLines[0].onVendorSupplyChange();

		test.stopTest();

		System.assertEquals( 1, quoteContExt.quoteLines.size() );
		System.assertEquals( 0, ApexPages.getMessages().size() );
		System.assertEquals( false, quoteContExt.hasError );
	}

	@isTest 
	static void testWithoutLinesAddCompletedFreightLineThenProductChangeMNS() {
		setup();

		test.startTest();
		quote = UNITY_TestDataFactory.createQuote( 1, cases[0].Id, workOrders[0].Id, accountCustomer.Id, UserInfo.getUserId() )[0];
		quote.UNITY_Business_Unit__c = 'MNS';
		update quote;

		ApexPages.StandardController stdQuote = new ApexPages.StandardController( quote );
		MSPFS_NewQuoteItemContExt quoteContExt = new MSPFS_NewQuoteItemContExt( stdQuote );

		PageReference quotePage = Page.MSPFS_NewQuoteItem;
		Test.setCurrentPage( quotePage );

		System.assertEquals( 0, quoteContExt.quoteLines.size() );

		quoteContExt.addItem();

		quoteContExt.quoteLines[0].item.UNITY_Product__c = testFreightProduct.Id;
		quoteContExt.quoteLines[0].item.UNITY_Product__r = testFreightProduct;
		quoteContExt.quoteLines[0].item.UNITY_Part_Location__c = location.Id;
		quoteContExt.quoteLines[0].item.UNITY_Part_Source__c = accountVendor.Id;
		quoteContExt.quoteLines[0].item.UNITY_Type__c = 'Vendor Services';
		quoteContExt.quoteLines[0].item.UNITY_Activity_Type__c = 'Pass Through Freight';
		quoteContExt.quoteLines[0].item.UNITY_Quantity__c = 1;
		quoteContExt.quoteLines[0].item.UNITY_Cost__c = 5;
		quoteContExt.quoteLines[0].item.UNITY_Is_Vendor_Supply__c = true;

		quotePage.getParameters().put( 'index', string.valueOf(quoteContExt.quoteLines[0].index) );

		quoteContExt.quoteLines[0].onProductChange();
		quoteContExt.quoteLines[0].onVendorSupplyChange();

		test.stopTest();

		System.assertEquals( 1, quoteContExt.quoteLines.size() );
		System.assertEquals( 0, ApexPages.getMessages().size() );
		System.assertEquals( false, quoteContExt.hasError );
	}

	@isTest 
	static void testWithoutLinesAddCompletedLaborLineThenProductChange() {
		setup();

		test.startTest();
		quote = UNITY_TestDataFactory.createQuote( 1, cases[0].Id, workOrders[0].Id, accountCustomer.Id, UserInfo.getUserId() )[0];
		update quote;

		ApexPages.StandardController stdQuote = new ApexPages.StandardController( quote );
		MSPFS_NewQuoteItemContExt quoteContExt = new MSPFS_NewQuoteItemContExt( stdQuote );

		PageReference quotePage = Page.MSPFS_NewQuoteItem;
		Test.setCurrentPage( quotePage );

		System.assertEquals( 0, quoteContExt.quoteLines.size() );

		quoteContExt.addItem();

		quoteContExt.quoteLines[0].item.UNITY_Product__c = testLaborProduct.Id;
		quoteContExt.quoteLines[0].item.UNITY_Product__r = testLaborProduct;
		quoteContExt.quoteLines[0].item.UNITY_Part_Location__c = location.Id;
		quoteContExt.quoteLines[0].item.UNITY_Type__c = 'Labor - Installation';
		quoteContExt.quoteLines[0].item.UNITY_Activity_Type__c = 'Standard Labor';
		quoteContExt.quoteLines[0].item.UNITY_Quantity__c = 1;
		quoteContExt.quoteLines[0].item.UNITY_Cost__c = 5;
		quoteContExt.quoteLines[0].item.UNITY_Is_Vendor_Supply__c = true;

		quotePage.getParameters().put( 'index', string.valueOf(quoteContExt.quoteLines[0].index) );

		quoteContExt.quoteLines[0].onProductChange();
		quoteContExt.quoteLines[0].onVendorSupplyChange();

		test.stopTest();

		System.assertEquals( 1, quoteContExt.quoteLines.size() );
		System.assertEquals( 0, ApexPages.getMessages().size() );
		System.assertEquals( false, quoteContExt.hasError );
	}

	@isTest 
	static void testWithoutLinesAddCompletedTravelLineThenProductChange() {
		setup();

		test.startTest();
		quote = UNITY_TestDataFactory.createQuote( 1, cases[0].Id, workOrders[0].Id, accountCustomer.Id, UserInfo.getUserId() )[0];
		update quote;

		ApexPages.StandardController stdQuote = new ApexPages.StandardController( quote );
		MSPFS_NewQuoteItemContExt quoteContExt = new MSPFS_NewQuoteItemContExt( stdQuote );

		PageReference quotePage = Page.MSPFS_NewQuoteItem;
		Test.setCurrentPage( quotePage );

		System.assertEquals( 0, quoteContExt.quoteLines.size() );

		quoteContExt.addItem();

		quoteContExt.quoteLines[0].item.UNITY_Product__c = testTravelProduct.Id;
		quoteContExt.quoteLines[0].item.UNITY_Product__r = testTravelProduct;
		quoteContExt.quoteLines[0].item.UNITY_Part_Location__c = location.Id;
		quoteContExt.quoteLines[0].item.UNITY_Type__c = 'Travel';
		quoteContExt.quoteLines[0].item.UNITY_Activity_Type__c = 'Standard Travel';
		quoteContExt.quoteLines[0].item.UNITY_Quantity__c = 1;
		quoteContExt.quoteLines[0].item.UNITY_Cost__c = 5;
		quoteContExt.quoteLines[0].item.UNITY_Is_Vendor_Supply__c = true;

		quotePage.getParameters().put( 'index', string.valueOf(quoteContExt.quoteLines[0].index) );

		quoteContExt.quoteLines[0].onProductChange();
		quoteContExt.quoteLines[0].onVendorSupplyChange();

		test.stopTest();

		System.assertEquals( 1, quoteContExt.quoteLines.size() );
		System.assertEquals( 0, ApexPages.getMessages().size() );
		System.assertEquals( false, quoteContExt.hasError );
	}

	@isTest 
	static void testWithoutLinesAddCompletedPartLineThenProductChange() {
		setup();

		test.startTest();
		quote = UNITY_TestDataFactory.createQuote( 1, cases[0].Id, workOrders[0].Id, accountCustomer.Id, UserInfo.getUserId() )[0];
		update quote;

		ApexPages.StandardController stdQuote = new ApexPages.StandardController( quote );
		MSPFS_NewQuoteItemContExt quoteContExt = new MSPFS_NewQuoteItemContExt( stdQuote );

		PageReference quotePage = Page.MSPFS_NewQuoteItem;
		Test.setCurrentPage( quotePage );

		System.assertEquals( 0, quoteContExt.quoteLines.size() );

		quoteContExt.addItem();

		quoteContExt.quoteLines[0].item.UNITY_Product__c = testPartProduct.Id;
		quoteContExt.quoteLines[0].item.UNITY_Product__r = testPartProduct;
		quoteContExt.quoteLines[0].item.UNITY_Part_Location__c = location.Id;
		quoteContExt.quoteLines[0].item.UNITY_Type__c = 'Parts';
		quoteContExt.quoteLines[0].item.UNITY_Activity_Type__c = 'Standard Part';
		quoteContExt.quoteLines[0].item.UNITY_Quantity__c = 1;
		quoteContExt.quoteLines[0].item.UNITY_Cost__c = 5;
		quoteContExt.quoteLines[0].item.UNITY_Is_Vendor_Supply__c = true;

		quotePage.getParameters().put( 'index', string.valueOf(quoteContExt.quoteLines[0].index) );

		quoteContExt.quoteLines[0].onProductChange();
		quoteContExt.quoteLines[0].onVendorSupplyChange();

		test.stopTest();

		System.assertEquals( 1, quoteContExt.quoteLines.size() );
		System.assertEquals( 0, ApexPages.getMessages().size() );
		System.assertEquals( false, quoteContExt.hasError );
	}

	@isTest 
	static void testWithoutLinesAddCompletedFreightLineThenProductChange() {
		setup();

		test.startTest();
		quote = UNITY_TestDataFactory.createQuote( 1, cases[0].Id, workOrders[0].Id, accountCustomer.Id, UserInfo.getUserId() )[0];
		update quote;

		ApexPages.StandardController stdQuote = new ApexPages.StandardController( quote );
		MSPFS_NewQuoteItemContExt quoteContExt = new MSPFS_NewQuoteItemContExt( stdQuote );

		PageReference quotePage = Page.MSPFS_NewQuoteItem;
		Test.setCurrentPage( quotePage );

		System.assertEquals( 0, quoteContExt.quoteLines.size() );

		quoteContExt.addItem();

		quoteContExt.quoteLines[0].item.UNITY_Product__c = testFreightProduct.Id;
		quoteContExt.quoteLines[0].item.UNITY_Product__r = testFreightProduct;
		quoteContExt.quoteLines[0].item.UNITY_Part_Location__c = location.Id;
		quoteContExt.quoteLines[0].item.UNITY_Type__c = 'Vendor Services';
		quoteContExt.quoteLines[0].item.UNITY_Activity_Type__c = 'Pass Through Freight';
		quoteContExt.quoteLines[0].item.UNITY_Quantity__c = 1;
		quoteContExt.quoteLines[0].item.UNITY_Cost__c = 5;
		quoteContExt.quoteLines[0].item.UNITY_Is_Vendor_Supply__c = true;

		quotePage.getParameters().put( 'index', string.valueOf(quoteContExt.quoteLines[0].index) );

		quoteContExt.quoteLines[0].onProductChange();
		quoteContExt.quoteLines[0].onVendorSupplyChange();

		test.stopTest();

		System.assertEquals( 1, quoteContExt.quoteLines.size() );
		System.assertEquals( 0, ApexPages.getMessages().size() );
		System.assertEquals( false, quoteContExt.hasError );
	}

	@isTest 
	static void testWithoutLinesAddCompletedLineWithoutProductThenProductChange() {
		setup();

		test.startTest();
		quote = UNITY_TestDataFactory.createQuote( 1, cases[0].Id, workOrders[0].Id, accountCustomer.Id, UserInfo.getUserId() )[0];
		update quote;

		ApexPages.StandardController stdQuote = new ApexPages.StandardController( quote );
		MSPFS_NewQuoteItemContExt quoteContExt = new MSPFS_NewQuoteItemContExt( stdQuote );

		PageReference quotePage = Page.MSPFS_NewQuoteItem;
		Test.setCurrentPage( quotePage );

		System.assertEquals( 0, quoteContExt.quoteLines.size() );

		quoteContExt.addItem();

		quoteContExt.quoteLines[0].item.UNITY_Part_Location__c = location.Id;
		quoteContExt.quoteLines[0].item.UNITY_Type__c = 'Vendor Services';
		quoteContExt.quoteLines[0].item.UNITY_Activity_Type__c = 'Pass Through Freight';
		quoteContExt.quoteLines[0].item.UNITY_Quantity__c = 1;
		quoteContExt.quoteLines[0].item.UNITY_Cost__c = 5;
		quoteContExt.quoteLines[0].item.UNITY_Is_Vendor_Supply__c = true;

		quotePage.getParameters().put( 'index', string.valueOf(quoteContExt.quoteLines[0].index) );

		quoteContExt.quoteLines[0].onProductChange();
		quoteContExt.quoteLines[0].onVendorSupplyChange();

		test.stopTest();

		System.assertEquals( 1, quoteContExt.quoteLines.size() );
		System.assertEquals( 0, ApexPages.getMessages().size() );
		System.assertEquals( false, quoteContExt.hasError );
	}

	@isTest 
	static void testWithoutLinesAddCompletedLineRunWrapperMethods() {
		setup();

		test.startTest();
		quote = UNITY_TestDataFactory.createQuote( 1, cases[0].Id, workOrders[0].Id, accountCustomer.Id, UserInfo.getUserId() )[0];
		update quote;

		ApexPages.StandardController stdQuote = new ApexPages.StandardController( quote );
		MSPFS_NewQuoteItemContExt quoteContExt = new MSPFS_NewQuoteItemContExt( stdQuote );

		PageReference quotePage = Page.MSPFS_NewQuoteItem;
		Test.setCurrentPage( quotePage );


		System.assertEquals( 0, quoteContExt.quoteLines.size() );

		quoteContExt.addItem();

		quoteContExt.quoteLines[0].item.UNITY_Product__c = testLaborProduct.Id;
		quoteContExt.quoteLines[0].item.UNITY_Part_Location__c = location.Id;
		quoteContExt.quoteLines[0].item.UNITY_Type__c = 'Labor - Installation';
		quoteContExt.quoteLines[0].item.UNITY_Activity_Type__c = 'Standard Labor';
		quoteContExt.quoteLines[0].item.UNITY_Quantity__c = 1;
		quoteContExt.quoteLines[0].item.UNITY_Cost__c = 5;
		quoteContExt.quoteLines[0].item.UNITY_Is_Vendor_Supply__c = true;

		quotePage.getParameters().put( 'index', string.valueOf(quoteContExt.quoteLines[0].index) );

		quoteContExt.quoteLines[0].onCostQtyChange();
		quoteContExt.quoteLines[0].onVendorSupplyChange();

		test.stopTest();

		System.assertEquals( 1, quoteContExt.quoteLines.size() );
		System.assertEquals( 0, ApexPages.getMessages().size() );
		System.assertEquals( false, quoteContExt.hasError );
	}
}