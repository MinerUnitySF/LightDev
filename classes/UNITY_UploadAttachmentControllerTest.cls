/*------------------------------------------------------------
Name:          UNITYUploadAttachmentControllerTest
Author:        Krishna Kamineni
Company:       Miner
Description:   This class contains unit tests for validating the behavior of Apex classe:UNITYUploadAttachmentController
History:
1/21/2016      Krishna Kamineni

------------------------------------------------------------*/
@isTest
private class UNITY_UploadAttachmentControllerTest {
    
    @testSetup
    static void data(){
         
        //  Create customer           STEP 1
        //  Create Contact            STEP 2
        //  Create Skill              STEP 3
        //  Create Case               STEP 4
        //  Create Service Contract   STEP 5
        //  Create work Order         STEP 6
        
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

        Account customer      = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType() , accountFields).get(0);
        insert customer;

        //STEP 2
        contactFields.put('AccountId', customer.id);

        Contact cont       = (Contact)UNITY_TestDataFactory.createObject(1, Contact.getSObjectType() , contactFields).get(0);
        insert cont;

        //STEP 3
        FSO__Skill__c onSkill = (FSO__Skill__c)UNITY_TestDataFactory.createObject(1, FSO__Skill__c.getSObjectType() , skillFields).get(0);
        insert onSkill;

        //STEP 4
        caseFields.put('AccountId'        , customer.id);
        caseFields.put('Customer__c'      , customer.id);
        caseFields.put('RecordTypeId'     , UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        caseFields.put('UNITY_Trade__c'   , onSkill.id);
            
        Case onCase = (Case) UNITY_TestDataFactory.createObject(1, Case.getSObjectType(), caseFields).get(0);
        insert onCase;       
        
        //STEP 5
        serviceContractFields.put('UNITY_Business_Unit__c', 'MNS');
        serviceContractFields.put('UNITY_Account__c', customer.id);
        serviceContractFields.put('UNITY_Required_Documentation__c', 'Customer-Specific Service Report Sign');
        UNITY_Service_Contract__c sc  = (UNITY_Service_Contract__c)UNITY_TestDataFactory.createObject(1, UNITY_Service_Contract__c.getSObjectType(), serviceContractFields).get(0);
        insert sc;
        
        //STEP 6
        workOrderFields.put('CaseId'            , onCase.id);
        workOrderFields.put('Subject'           , 'WO-Test');
        workOrderFields.put('AccountId'         , customer.id);
        workOrderFields.put('RecordTypeId'      , UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
        workOrderFields.put('UNITY_Trade__c'    , onSkill.id);
        workOrderFields.put('UNITY_Customer__c' , customer.id);
        workOrderFields.put('UNITY_Agent__c'    , UserInfo.getUserId());   
        workOrderFields.put('UNITY_Business_Unit__c' , 'MNS');
        workOrderFields.put('UNITY_Customer_Service_Contract__c' , sc.id);
        WorkOrder wo  = (WorkOrder)UNITY_TestDataFactory.createObject(1, WorkOrder.getSObjectType(), workOrderFields).get(0);
        insert wo;

    }
    
    static testMethod void testProcessUpload() {
        
        // get WO 
        WorkOrder wo  = [SELECT id FROM WorkOrder LIMIT 1];

        // set current page
        PageReference pageRef = Page.UNITY_UploadAttachment;
        pageRef.getParameters().put('id', wo.id);
        Test.setCurrentPage(pageRef);

        // set controller 
        ApexPages.StandardController sc       = new ApexPages.StandardController(wo);
        UNITY_UploadAttachmentController ctrl = new UNITY_UploadAttachmentController(sc);
          
        ctrl.fileName     = 'test file upload';
        ctrl.fileBody     =  Blob.valueOf('Unit Test Attachment Body');
        ctrl.selectedType = 'Customer-Specific Service Report Sign-Off';
        try{
        ctrl.processUpload();
        }catch(Exception e){
          System.debug(LoggingLevel.ERROR,e);
          System.Debug('******************************************'+e);
        }
        ctrl.back();
        
        
    }
    
    static testMethod void failUpload() {
        
        // get WO 
        WorkOrder wo  = [SELECT id FROM WorkOrder LIMIT 1];

        // set current page
        PageReference pageRef = Page.UNITY_UploadAttachment;
        pageRef.getParameters().put('id', wo.id);
        Test.setCurrentPage(pageRef);

        // set controller 
        ApexPages.StandardController sc       = new ApexPages.StandardController(wo);
        UNITY_UploadAttachmentController ctrl = new UNITY_UploadAttachmentController(sc);

        ctrl.fileName     =  'test file upload';
        ctrl.fileBody     =  Blob.valueOf('Unit Test Attachment Body');
        ctrl.selectedType = 'Customer-Specific Service Report Sign-Off';
        ctrl.processUpload();
        
        ctrl.fileName     =  null;
        ctrl.fileBody     =  Blob.valueOf('Unit Test Attachment Body');
        ctrl.selectedType = 'Customer-Specific Service Report Sign-Off';
        ctrl.processUpload();
        ctrl.getTypes();
    }
    
    
}