@isTest
private class UNITY_AutopopulateChildControllerTest {
	
	@testSetup 
	static void test_method_one() {
		
		// Create Autopopulate Mapping Custom Setting Records
		insertAutopopulateMapping();

		// Create Releationship lookups Custom Setting Records
		insertRelationshipLookups();

		Map<String,Object> caseFields                  = UNITY_TestDataFactory.MOCKUP_CASE_FIELDS;
        Map<String,Object> skillFields                 = UNITY_TestDataFactory.MOCKUP_FSO_SKILL_FIELDS;
        Map<String,Object> contactFields               = UNITY_TestDataFactory.MOCKUP_CONTACT_FIELDS;
        Map<String,Object> accountFields               = UNITY_TestDataFactory.MOCKUP_ACCOUNT_FIELDS;    
        Map<String,Object> workOrderFields             = UNITY_TestDataFactory.MOCKUP_WORK_ORDER_FIELDS;
        Map<String,Object> serviceContractFields       = UNITY_TestDataFactory.MOCKUP_SERVICE_CONTRACT_FIELDS;
        
        //STEP 1
        accountFields.put('recordTypeId', UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE);
        accountFields.put('Type', 'Site/Location');
        accountFields.put('Name', 'C-'+UNITY_Utils.generateRandomPin());
        accountFields.put('UNITY_Business_Unit__c', 'MNS');
        List<Account> customers  = (List<Account>)UNITY_TestDataFactory.createObject(10, Account.getSObjectType() , accountFields);
        insert customers;
        Map<id,Account> customerMap  = new Map<id,Account>(customers);


        serviceContractFields.put('UNITY_Business_Unit__c', 'MNS');
        serviceContractFields.put('UNITY_Required_Documentation__c', 'Customer-Specific Service Report Sign');

        
        List<Contact>                     contacts         = new List<Contact>();
        List<UNITY_Service_Contract__c>   serviceContracts = new List<UNITY_Service_Contract__c>();
        
        for(Account acc :customers){
        	contactFields.put('AccountId', acc.id);
        	contacts.addAll((List<Contact>)UNITY_TestDataFactory.createObject(1, Contact.getSObjectType() , contactFields));

        	serviceContractFields.put('UNITY_Account__c', acc.id);
        	UNITY_Service_Contract__c sc= (UNITY_Service_Contract__c)UNITY_TestDataFactory.createObject(1, UNITY_Service_Contract__c.getSObjectType(), serviceContractFields).get(0);
        	serviceContracts.add(sc);
        }
        insert contacts;
        insert serviceContracts;

        Map<id,UNITY_Service_Contract__c> serviceContractsMap  = new Map<id,UNITY_Service_Contract__c>(serviceContracts);

        
        FSO__Skill__c onSkill = (FSO__Skill__c)UNITY_TestDataFactory.createObject(1, FSO__Skill__c.getSObjectType() , skillFields).get(0);
        insert onSkill;

        
        for(UNITY_Service_Contract__c sc :serviceContractsMap.values()){
        	 customerMap.get(sc.UNITY_Account__c).UNITY_Service_Contract__c = sc.id;
        }
       
        update customerMap.values();
		
	}

	@isTest 
	static void autopopulateMappingpPage() {
			
			Account customer = [SELECT  id,
										Name, 
										UNITY_Service_Contract__r.Name, 
										UNITY_Service_Contract__c, 
										UNITY_Business_Unit__c 
							    FROM    Account
								LIMIT 1];

			PageReference pageRef = Page.UNITY_AutopopulateChild;
       	    pageRef.getParameters().put('parentId'      , customer.id);
            pageRef.getParameters().put('sourceSObject' , 'Account');
            pageRef.getParameters().put('targetSObject' , 'Case');
            pageRef.getParameters().put('urlEncodedParameters' , EncodingUtil.urlEncode('SOMEPARAMETERS','UTF-8'));
            pageRef.getParameters().put('baseUrl' , 'some.domain.com' );
        
            Test.setCurrentPage(pageRef); 


			UNITY_AutopopulateChildController ctrl = new UNITY_AutopopulateChildController();

			ctrl.getTargetSObject();

			String  url  = ctrl.getMapFieldsAndRedirect();					
			system.debug('>>> url '+url);

	}

	@isTest 
	static void autopopulateMapping() {
			
			Account customer = [SELECT  id,
										Name, 
										UNITY_Service_Contract__r.Name, 
										UNITY_Service_Contract__c, 
										UNITY_Business_Unit__c 
							    FROM    Account
								LIMIT 1];

			UNITY_AutopopulateChildController ctrl = new UNITY_AutopopulateChildController('Account','Case',customer.id);
			String  url  = ctrl.getMapFieldsAndRedirect();

			ctrl = new UNITY_AutopopulateChildController('Case');


	}

	@isTest 
	static void autopopulateMappingBulk() {
			
			List<Account> customers = new List<Account>([SELECT  id,
																 Name, 
																 UNITY_Service_Contract__r.Name, 
																 UNITY_Service_Contract__c, 
																 UNITY_Business_Unit__c 
													     FROM    Account ]);
			List<Case> cases =  new List<Case>();

			for(Account acc :customers){
				cases.add(new Case(UNITY_Customer__c = acc.id));
			}

			UNITY_AutopopulateChildController.autopopulateFieldsIfApplicableBulkified(cases, 'Case');

	}


	
	/*
	 * Name : insertAutopopulateMapping
	 * Note : Source                    /  Target
	 *        Case                      /  WorkOrder
	 *        Account                   /  Case
	 *        WorkOrder                 /  Order
	 *        WorkOrder                 /  UNITY_Proposal__c
	 *        UNITY_Service_Contract__c /  Case
	 */
	static void insertAutopopulateMapping(){
		
		List<UNITY_Autopopulate_Mapping__c> autopopulateMapping = new List<UNITY_Autopopulate_Mapping__c>();

		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Customer_Email__c', Source_Field__c = 'Contact.Email' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'UNITY_Proposal__c', Target_Field_Layout_Id__c = 'null'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Trade__c', Source_Field__c = 'UNITY_Trade__c' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = 'CF00N18000000bBzJ_lkid'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = true,  Target_Field__c = 'UNITY_Trade__c Lookup', Source_Field__c = 'UNITY_Trade__r.Name' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = 'CF00N18000000bBzJ'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = true,  Target_Field__c = 'UNITY_Case__c Lookup', Source_Field__c = 'Case.CaseNumber' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'UNITY_Proposal__c', Target_Field_Layout_Id__c = 'CF00N18000000Zz02'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = true,  Target_Field__c = 'Case Lookup', Source_Field__c = 'CaseNumber' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = 'CF00N18000000Za0A'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'AccountId', Source_Field__c = 'AccountId' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'Order', Target_Field_Layout_Id__c = 'accid_lkid'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = true,  Target_Field__c = 'UNITY_Work_Order__c Lookup', Source_Field__c = 'WorkOrderNumber' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'UNITY_Proposal__c', Target_Field_Layout_Id__c = 'CF00N18000000ZhB7'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'CaseId', Source_Field__c = 'Id' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = 'CF00N18000000Za0A_lkid'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Work_Order__c', Source_Field__c = 'Id' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'UNITY_Proposal__c', Target_Field_Layout_Id__c = 'CF00N18000000ZhB7_lkid'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = true,  Target_Field__c = 'Account Lookup', Source_Field__c = 'Account.Name' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'Order', Target_Field_Layout_Id__c = 'accid'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Case__c', Source_Field__c = 'CaseId' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'UNITY_Proposal__c', Target_Field_Layout_Id__c = 'CF00N18000000Zz02_lkid'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = true,  Target_Field__c = 'UNITY_Customer__c Lookup', Source_Field__c = 'UNITY_Customer__r.Name' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = 'CF00N18000000ZcK9'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = true,  Target_Field__c = 'Contact Lookup', Source_Field__c = 'Contact.Name' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = 'CF00N18000000Za0F'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = true,  Target_Field__c = 'UNITY_Customer_Service_Contract__c Lookup', Source_Field__c = 'UNITY_Customer_Service_Contract__r.Name' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = 'CF00N18000000ZfNQ'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = true,  Target_Field__c = 'Account Lookup', Source_Field__c = 'Account.Name' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = 'CF00N18000000Za05'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Customer_Service_Contract__c', Source_Field__c = 'UNITY_Customer_Service_Contract__c' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = 'CF00N18000000ZfNQ_lkid'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'Latitude', Source_Field__c = 'Account.UNITY_Shipping_Location__Latitude__s' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = '0BC180000008OWL'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = true,  Target_Field__c = 'Account Lookup', Source_Field__c = 'Name' ,Source_Object__c = 'Account', Target_Object__c = 'Case', Target_Field_Layout_Id__c = 'cas4'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Site_Contact_Phone__c', Source_Field__c = 'Contact.Phone' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = '00N18000000aJXp'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'Subject', Source_Field__c = 'Subject' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = '00N18000000Za0g'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Business_Unit__c', Source_Field__c = 'UNITY_Business_Unit__c' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = '00N18000000a2S4'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Customer__c', Source_Field__c = 'Id' ,Source_Object__c = 'Account', Target_Object__c = 'Case', Target_Field_Layout_Id__c = 'CF00N18000000ZcJu_lkid'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'AccountId', Source_Field__c = 'Account.Id' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = 'CF00N18000000Za05_lkid'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'ShippingPostalCode', Source_Field__c = 'PostalCode' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'Order', Target_Field_Layout_Id__c = 'ShippingAddresszip'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Not_To_Exceed_NTE__c', Source_Field__c = 'UNITY_NTE_Threshold__c' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = '00N18000000ZfLy'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'ContactId', Source_Field__c = 'Contact.Id' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = 'CF00N18000000Za0F_lkid'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'Longitude', Source_Field__c = 'Account.UNITY_Shipping_Location__Longitude__s' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = '0BC180000008OWM'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'Description', Source_Field__c = 'Description' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = '00N18000000Za0H'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'ShippingState', Source_Field__c = 'State' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'Order', Target_Field_Layout_Id__c = 'ShippingAddressstate'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'FSO__Special_Instructions__c', Source_Field__c = 'UNITY_Special_Instructions__c' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = '00N18000000Za0Z'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Ship_To_Account__c', Source_Field__c = 'AccountId' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'Order', Target_Field_Layout_Id__c = 'CF00N18000000der8_lkid'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'Priority', Source_Field__c = 'Priority' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = '00N18000000Za0W'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_NTE__c', Source_Field__c = 'UNITY_Not_To_Exceed_NTE__c' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'Order', Target_Field_Layout_Id__c = '00N18000000der2'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = true,  Target_Field__c = 'UNITY_Customer_Service_Contract__c Lookup', Source_Field__c = 'UNITY_Service_Contract__r.Name' ,Source_Object__c = 'Account', Target_Object__c = 'Case', Target_Field_Layout_Id__c = 'CF00N18000000aGn6'));
		autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Customer_PO__c', Source_Field__c = 'UNITY_Customer_PO__c' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = '00N18000000aJY4'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Customer__c', Source_Field__c = 'UNITY_Customer__r.Id' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = 'CF00N18000000ZcK9_lkid'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Customer_Service_Contract__c', Source_Field__c = 'UNITY_Service_Contract__c' ,Source_Object__c = 'Account', Target_Object__c = 'Case', Target_Field_Layout_Id__c = 'CF00N18000000aGn6_lkid'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'ShippingStreet', Source_Field__c = 'Street' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'Order', Target_Field_Layout_Id__c = 'ShippingAddressstreet'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = true,  Target_Field__c = 'UNITY_Customer__c Lookup', Source_Field__c = 'Name' ,Source_Object__c = 'Account', Target_Object__c = 'Case', Target_Field_Layout_Id__c = 'CF00N18000000ZcJu'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'ShippingCity', Source_Field__c = 'City' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'Order', Target_Field_Layout_Id__c = 'ShippingAddresscity'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Signature_Required__c', Source_Field__c = 'UNITY_Signature_Required__c' ,Source_Object__c = 'UNITY_Service_Contract__c', Target_Object__c = 'Case', Target_Field_Layout_Id__c = '00N18000000ahe1'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Business_Unit_Account__c', Source_Field__c = 'UNITY_Business_Unit_Account__c' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = 'CF00N18000000bWx4_lkid'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Business_Unit_Account__c', Source_Field__c = 'UNITY_Business_Unit_Account__c' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'Order', Target_Field_Layout_Id__c = 'CF00N18000000deqp_lkid'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = true,  Target_Field__c = 'UNITY_Business_Unit_Account__c Lookup', Source_Field__c = 'UNITY_Business_Unit_Account__r.Name' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'Order', Target_Field_Layout_Id__c = 'CF00N18000000deqp'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = true,  Target_Field__c = 'UNITY_Business_Unit_Account__c Lookup', Source_Field__c = 'UNITY_Business_Unit_Account__r.Name' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = 'CF00N18000000bWx4'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = true,  Target_Field__c = 'UNITY_Business_Unit_Account__c Lookup', Source_Field__c = 'UNITY_Business_Unit_Account__r.Name' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'UNITY_Proposal__c', Target_Field_Layout_Id__c = 'CF00N18000000bWxE'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Customer__c', Source_Field__c = 'UNITY_Customer__c' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'Order', Target_Field_Layout_Id__c = 'CF00N18000000deqt_lkid'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = true,  Target_Field__c = 'UNITY_Customer__c Lookup', Source_Field__c = 'UNITY_Customer__r.Name' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'Order', Target_Field_Layout_Id__c = 'CF00N18000000deqt'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Business_Unit_Account__c', Source_Field__c = 'UNITY_Business_Unit_Account__c' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'UNITY_Proposal__c', Target_Field_Layout_Id__c = 'CF00N18000000bWxE_lkid'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Vendor_Email__c', Source_Field__c = 'UNITY_Vendor_Email__c' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'Order', Target_Field_Layout_Id__c = '00N18000000derA'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'FSO__Work_Order__c', Source_Field__c = 'Id' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'Order', Target_Field_Layout_Id__c = 'CF00N18000000dgLO_lkid'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = true,  Target_Field__c = 'FSO__WorkOrder__c Lookup', Source_Field__c = 'WorkOrderNumber' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'Order', Target_Field_Layout_Id__c = 'CF00N18000000dgLO'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = true,  Target_Field__c = 'UNITY_Assigned_Vendor__c Lookup', Source_Field__c = 'UNITY_Assigned_Vendor__r.Name' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'Order', Target_Field_Layout_Id__c = 'CF00N18000000derB'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Vendor__c', Source_Field__c = 'UNITY_Assigned_Vendor__c' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'Order', Target_Field_Layout_Id__c = 'CF00N18000000derB_lkid'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = true,  Target_Field__c = 'UNITY_Account__c Lookup', Source_Field__c = 'Account.Name' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'UNITY_Proposal__c', Target_Field_Layout_Id__c = 'CF00N18000000Zyzx'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Account__c', Source_Field__c = 'AccountId' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'UNITY_Proposal__c', Target_Field_Layout_Id__c = 'CF00N18000000Zyzx_lkid'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Account__c', Source_Field__c = 'Account.Id' ,Source_Object__c = 'Case', Target_Object__c = 'UNITY_Proposal__c', Target_Field_Layout_Id__c = 'CF00N18000000Zyzx_lkid'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = true,  Target_Field__c = 'UNITY_Account__c Lookup', Source_Field__c = 'Account.Name' ,Source_Object__c = 'Case', Target_Object__c = 'UNITY_Proposal__c', Target_Field_Layout_Id__c = 'CF00N18000000Zyzx'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Skill_Type__c', Source_Field__c = 'UNITY_Skill_Type__c' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = 'null'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Skill_Group__c', Source_Field__c = 'UNITY_Skill_Group__c' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = 'null'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Skill_Broad__c', Source_Field__c = 'UNITY_Skill_Broad__c' ,Source_Object__c = 'Case', Target_Object__c = 'WorkOrder', Target_Field_Layout_Id__c = 'null'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = true,  Target_Field__c = 'UNITY_Ship_To_Account__c Lookup', Source_Field__c = 'Account.Name' ,Source_Object__c = 'WorkOrder', Target_Object__c = 'Order', Target_Field_Layout_Id__c = 'CF00N18000000der8'));
        autopopulateMapping.add(new UNITY_Autopopulate_Mapping__c(UI_Only__c = false, Target_Field__c = 'UNITY_Business_Unit__c', Source_Field__c = 'UNITY_Business_Unit__c' ,Source_Object__c = 'Account', Target_Object__c = 'Case', Target_Field_Layout_Id__c = 'null'));

        for(Integer index = 0; index < autopopulateMapping.size(); index++){
        	autopopulateMapping.get(index).Name = 'AM-'+index;
        }
        insert autopopulateMapping;

	}

	
	/*
	 * Name : insertRelationshipLookups
	 */
	static void insertRelationshipLookups(){

		List<UNITY_TemplateConfigRelationshipLookups__c> relationshipLookups = new List<UNITY_TemplateConfigRelationshipLookups__c>();

		relationshipLookups.add(new UNITY_TemplateConfigRelationshipLookups__c(UNITY_Child_Object__c = 'Case', UNITY_Parent_Object__c = 'Case', UNITY_Parent_Lookup_Field__c = 'Parent'));
		relationshipLookups.add(new UNITY_TemplateConfigRelationshipLookups__c(UNITY_Child_Object__c = 'OrderItem', UNITY_Parent_Object__c = 'Order', UNITY_Parent_Lookup_Field__c = 'OrderId'));
		relationshipLookups.add(new UNITY_TemplateConfigRelationshipLookups__c(UNITY_Child_Object__c = 'Task', UNITY_Parent_Object__c = 'Case', UNITY_Parent_Lookup_Field__c = 'WhatId'));
		relationshipLookups.add(new UNITY_TemplateConfigRelationshipLookups__c(UNITY_Child_Object__c = 'UNITY_Proposal_Line_Item__c', UNITY_Parent_Object__c = 'UNITY_Proposal__c', UNITY_Parent_Lookup_Field__c = 'UNITY_Proposal__c'));
		relationshipLookups.add(new UNITY_TemplateConfigRelationshipLookups__c(UNITY_Child_Object__c = 'UNITY_Proposal__c', UNITY_Parent_Object__c = 'WorkOrder', UNITY_Parent_Lookup_Field__c = 'UNITY_Work_Order__c'));
		relationshipLookups.add(new UNITY_TemplateConfigRelationshipLookups__c(UNITY_Child_Object__c = 'WorkOrder', UNITY_Parent_Object__c = 'Case', UNITY_Parent_Lookup_Field__c = 'CaseId'));
		relationshipLookups.add(new UNITY_TemplateConfigRelationshipLookups__c(UNITY_Child_Object__c = 'Order', UNITY_Parent_Object__c = 'WorkOrder', UNITY_Parent_Lookup_Field__c = 'FSO__Work_Order__c'));
		relationshipLookups.add(new UNITY_TemplateConfigRelationshipLookups__c(UNITY_Child_Object__c = 'Case', UNITY_Parent_Object__c = 'Account', UNITY_Parent_Lookup_Field__c = 'UNITY_Customer__c'));
		relationshipLookups.add(new UNITY_TemplateConfigRelationshipLookups__c(UNITY_Child_Object__c = 'Case', UNITY_Parent_Object__c = 'UNITY_Service_Contract__c', UNITY_Parent_Lookup_Field__c = 'UNITY_Customer_Service_Contract__c'));
		relationshipLookups.add(new UNITY_TemplateConfigRelationshipLookups__c(UNITY_Child_Object__c = 'UNITY_Proposal__c', UNITY_Parent_Object__c = 'Case', UNITY_Parent_Lookup_Field__c = 'UNITY_Case__c'));

		for(Integer index = 0; index < relationshipLookups.size(); index++){
        	relationshipLookups.get(index).Name = 'RL-'+index;
        }
        insert relationshipLookups;

	}
	
}