@isTest
public class UNITY_InvoiceTriggerHandlerUnitTest {

	@testSetup
	public static void data() {
		TestDataProvider.setKeyValueStore();
		Integer MAX_CUSTOMERS = 1;
		        Map<String,Object> caseFields                  = UNITY_TestDataFactory.MOCKUP_CASE_FIELDS;
                Map<String,Object> skillFields                 = UNITY_TestDataFactory.MOCKUP_FSO_SKILL_FIELDS;
                Map<String,Object> contactFields               = UNITY_TestDataFactory.MOCKUP_CONTACT_FIELDS;
                Map<String,Object> accountFields               = UNITY_TestDataFactory.MOCKUP_ACCOUNT_FIELDS;    
                Map<String,Object> productFields               = UNITY_TestDataFactory.MOCKUP_PRODUCT_FIELDS;
                Map<String,Object> workOrderFields             = UNITY_TestDataFactory.MOCKUP_WORK_ORDER_FIELDS;
                Map<String,Object> priceBookEntryFields        = UNITY_TestDataFactory.MOCKUP_PRICE_BOOK_ENTRY_FIELDS;
                Map<String,Object> serviceContractFields       = UNITY_TestDataFactory.MOCKUP_SERVICE_CONTRACT_FIELDS;
                Map<String,Object> serviceContractLineItemFields       = UNITY_TestDataFactory.MOCKUP_SERVICE_CONTRACT_LI_FIELDS;

                serviceContractFields.put('RecordTypeId'          , UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE);
                serviceContractFields.put('UNITY_IS_Active__c'    , true);
                serviceContractFields.put('UNITY_Business_Unit__c', 'MNS');
                serviceContractFields.put('UNITY_Is_Pass_Through__c', true);
                serviceContractFields.put('UNITY_Required_Documentation__c', 'Customer-Specific Service Report Sign');

                caseFields.put('Type'                   , 'Customer');
                caseFields.put('RecordTypeId'           , UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
                caseFields.put('UNITY_Business_Unit__c' , 'MNS');

                accountFields.put('recordTypeId', UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE);
                accountFields.put('Type', 'Customer');
                accountFields.put('Name', 'C-'+UNITY_Utils.generateRandomPin());

                List<Account> customers = (List<Account>)UNITY_TestDataFactory.createObject(MAX_CUSTOMERS, Account.getSObjectType() , accountFields);
                insert customers;

                FSO__Skill__c onSkill = (FSO__Skill__c)UNITY_TestDataFactory.createObject(1, FSO__Skill__c.getSObjectType() , skillFields).get(0);
                insert onSkill;

        	List<Case>    					  cases    			= new List<Case>();
                List<Contact> 					  contacts 			= new List<Contact>();
                List<UNITY_Service_Contract__c>   serviceContracts    = new List<UNITY_Service_Contract__c>();
                Map<id,Map<String,SObject>> accountId_children  = new Map<id,Map<String,SObject>>();

                Case aux_case;
                Contact aux_contact;
                UNITY_Service_Contract__c aux_sc;
                for(Account customer :customers){

                	contactFields.put('AccountId', customer.id);
                	aux_contact =(Contact)UNITY_TestDataFactory.createObject(1, Contact.getSObjectType() , contactFields).get(0);
                	contacts.add(aux_contact);

                	caseFields.put('AccountId'        , customer.id);
        	        caseFields.put('UNITY_Customer__c', customer.id);
        	        caseFields.put('UNITY_Trade__c'   , onSkill.id);
        	        
        	        aux_case = (Case)UNITY_TestDataFactory.createObject(1, Case.getSObjectType() , caseFields).get(0);
        	        cases.add(aux_case);

        	        serviceContractFields.put('UNITY_Account__c', customer.id);
        	        aux_sc = (UNITY_Service_Contract__c)UNITY_TestDataFactory.createObject(1, UNITY_Service_Contract__c.getSObjectType() , serviceContractFields).get(0);
        	        serviceContracts.add(aux_sc);

        	        if(accountId_children.get(customer.id) == null) accountId_children.put(customer.id, new Map<String,SObject>());
        	        if(accountId_children.get(customer.id).get('cases') == null)            accountId_children.get(customer.id).put('cases', null);
        	        if(accountId_children.get(customer.id).get('contacts') == null)         accountId_children.get(customer.id).put('contacts', null);
        	        if(accountId_children.get(customer.id).get('serviceContract') == null) accountId_children.get(customer.id).put('serviceContract', null);
        	        
        	        accountId_children.get(customer.id).put('cases',aux_case);
        	        accountId_children.get(customer.id).put('contacts',aux_contact);
        	        accountId_children.get(customer.id).put('serviceContract',aux_sc);

                }
                insert contacts;
                insert serviceContracts;

                serviceContractLineItemFields.put('RecordTypeId', UNITY_Constants.SCLI_SERVICE_CHARGE_RECORDTYPE);
                serviceContractLineItemFields.put('UNITY_Trade__c', onSkill.id);
                List<UNITY_Service_Contract_Line_Item__c> scLineItems = new List<UNITY_Service_Contract_Line_Item__c>();

                for(Contact onContact :contacts){

                        accountId_children.get(onContact.AccountId).get('cases').put('ContactId',onContact.id);
                        //accountId_children.get(onContact.AccountId).get('cases').put('UNITY_Customer_Service_Contract__c',accountId_children.get(onContact.AccountId).get('serviceContract').get('Id'));
                	serviceContractLineItemFields.put('UNITY_Service_Contract__c', accountId_children.get(onContact.AccountId).get('serviceContract').get('Id'));
                        scLineItems.addAll((List<UNITY_Service_Contract_Line_Item__c>)UNITY_TestDataFactory.createObject(1, UNITY_Service_Contract_Line_Item__c.getSObjectType() , serviceContractLineItemFields));
                }
        
                insert cases;
                insert scLineItems;
        
        		// update the case with customer service contract
        		for(Case aCase : cases) {
                    aCase.UNITY_Customer_Service_Contract__c = serviceContracts.get(0).Id;
        		}

                productFields.put('UNITY_Product_Type__c', 'Customer Service Charge');
                productFields.put('UNITY_Status__c', 'Inactive');
                List<Product2> products = (List<Product2>)UNITY_TestDataFactory.createObject(1, Product2.getSObjectType() , productFields);
                insert products;
                
                priceBookEntryFields.put('IsActive', true);
                List<PricebookEntry> priceBookE = new List<PricebookEntry>();
                for(Product2 product :products){
                	priceBookEntryFields.put('Product2Id', product.id);
                	priceBookE.addAll((List<PricebookEntry>)UNITY_TestDataFactory.createObject(1, PricebookEntry.getSObjectType() , priceBookEntryFields));
                }
                insert priceBookE;

	}

	public static testMethod void codeCoverage() {
		
                
                Map<String,Object> invoiceFields   = UNITY_TestDataFactory.MOCKUP_INVOICE_FIELDS;
                Map<String,Object> invoiceLIFields = UNITY_TestDataFactory.MOCKUP_SERVICE_CONTRACT_LI_FIELDS;


                invoiceLIFields.put('UNITY_Is_Vendor_Supply__c',true); 
                invoiceLIFields.put('UNITY_Excluded_from_Total__c',false);

                invoiceFields.put('RecordTypeId',UNITY_Constants.INVOICE_VENDOR_RECORDTYPE);
                invoiceFields.put('UNITY_Service_Charge__c', 10);

                List<UNITY_Invoice__c>           invoices   = new List<UNITY_Invoice__c>();
                List<UNITY_Invoice__c>           aux_use_for_update_without_scli = new List<UNITY_Invoice__c>();
                List<UNITY_Invoice_Line_Item__c> invoicesLI = new List<UNITY_Invoice_Line_Item__c>();

                List<Case> cases = [SELECT id, UNITY_Customer__c,  UNITY_Customer_Service_Contract__c FROM Case];

                for(Case onCase :cases){
                        invoiceFields.put('UNITY_Case__c',onCase.id);
                        invoiceFields.put('UNITY_Customer__c',onCase.UNITY_Customer__c);
                        invoiceFields.put('UNITY_Customer_Service_Contract__c',onCase.UNITY_Customer_Service_Contract__c);
                        invoices.addall((List<UNITY_Invoice__c>)UNITY_TestDataFactory.createObject(1, UNITY_Invoice__c.getSObjectType() , invoiceFields));
                        aux_use_for_update_without_scli.addAll((List<UNITY_Invoice__c>)UNITY_TestDataFactory.createObject(1, UNITY_Invoice__c.getSObjectType() , invoiceFields));
                }

                Test.startTest();
                		Test.setMock(WebServiceMock.class, new AvataxCalloutMock());
                        insert invoices;

                        for(UNITY_Invoice__c invoice :invoices){
                                invoiceLIFields.put('UNITY_Invoice__c',invoice.id);
                                invoicesLI.addAll((List<UNITY_Invoice_Line_Item__c>)UNITY_TestDataFactory.createObject(1, UNITY_Invoice_Line_Item__c.getSObjectType() , invoiceLIFields));
                        }
                        insert invoicesLI;

                        // Force Invoice trigger to create SCLI, updating SC without SCLI
                        insert aux_use_for_update_without_scli;

                        for(UNITY_Invoice__c invoice :aux_use_for_update_without_scli){
                                invoice.UNITY_Invoice_Comments__c ='T';
                        }
                        
                        update aux_use_for_update_without_scli;

                Test.stopTest();
	}
}