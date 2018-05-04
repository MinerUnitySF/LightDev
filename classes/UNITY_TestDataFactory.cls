@isTest
public class UNITY_TestDataFactory {
    
    static {

        Map<string,UNITY_General_Settings__c> generalSettings = UNITY_General_Settings__c.getAll();

        List<UNITY_General_Settings__c> gSettings = new List<UNITY_General_Settings__c>();
        
        if(!generalSettings.keySet().contains(UNITY_Constants.SERVICE_FEE_PRODUCT_TYPE_CS_KEY))gSettings.add(new UNITY_General_Settings__c(Name= UNITY_Constants.SERVICE_FEE_PRODUCT_TYPE_CS_KEY, UNITY_Value__c = 'Vendor Service Fee', UNITY_Description__c='Vendor Service Fee'));
        

        if(!gSettings.isEmpty()) insert gSettings;


        UNITY_MuleCalloutOperationTest.setup();
    }

    /**
     * TODO: retain all the objects generated in attributes.
     */
    static testMethod void testAllData() {
        Integer size = 10;
        Account account = createAccount('Test');
        createContact('Nick','Fury',account.Id);
        List<Account> accounts = createAccounts(size);
        createAccounts(size,UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE);
        createContacts(size,account.Id);
        List<FSO__Skill__c> skills = createSkills(size);
        createTrades(skills,accounts);
        Account accountCustomer = UNITY_TestDataFactory.createAccounts(1,'Site/Location',UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE).get(0);
        Account accountVendor = UNITY_TestDataFactory.createAccounts(1,'Customer',UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE).get(0);
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(2,accountCustomer.Id);
        List<Case> cases = UNITY_TestDataFactory.createCases(2,accountCustomer.Id,accountVendor.Id,contacts.get(0).Id,UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        List<UNITY_Service_Contract__c> serviceContracts = UNITY_TestDataFactory.createServiceContracts(1, accountCustomer.Id);
        List<WorkOrder> workOrders = UNITY_TestDataFactory.createWorkOrders(2,cases.get(0).Id,accountCustomer.Id,serviceContracts.get(0).Id,UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);

        createVendorAssignments(size,accounts.get(0).Id,workOrders.get(0).Id);
    }

    private class TestException extends Exception  {}

    public static void testLog(String str){
        throw new TestException(str);
    }

    public static  Map<String,Object> MOCKUP_SERVICE_CONTRACT_LI_FIELDS = new   Map<String,Object>{ 'UNITY_Trade__c'  => null,
                                                                                                    'UNITY_Total_Price__c'  => 500,
                                                                                                    'UNITY_Threshold_End__c' => 500,
                                                                                                    'UNITY_Threshold_Start__c' => 100,
                                                                                                    'UNITY_Service_Contract__c' => null,
                                                                                                    'UNITY_Service_Charge_Amount__c' => 50,
                                                                                                    'UNITY_Service_Charge_Percentage__c' => 10};


    public static  Map<String,Object> MOCKUP_INVOICE_FIELDS = new   Map<String,Object>{ 'UNITY_Case__c'   => true,
                                                                                        'UNITY_Customer__c'  => 10,
                                                                                        'UNITY_Service_Charge__c' => null};

    public static  Map<String,Object> MOCKUP_PRICE_BOOK_ENTRY_FIELDS = new   Map<String,Object>{'IsActive'   => true,
                                                                                                'UnitPrice'  => 10,
                                                                                                'Product2Id' => null,
                                                                                                'Pricebook2Id' => Test.getStandardPricebookId()};

    

    public static  Map<String,Object> MOCKUP_FSO_SKILL_FIELDS = new   Map<String,Object>{ 'Name' => 'Skill-A'};


    public static  Map<String,Object> MOCKUP_CONTACT_FIELDS = new   Map<String,Object>{ 'FirstName' => 'Unit',
                                                                                        'LastName'  => 'Test',
                                                                                        'AccountId' => null,
                                                                                        'Email'     => 'UnitTest@emial.com'};


    public static  Map<String,Object> MOCKUP_PRODUCT_FIELDS = new   Map<String,Object>{ 'Name' => 'Product',
                                                                                        'IsActive'    => true,
                                                                                        'Model__c'    => 'Product',
                                                                                        'Description' => 'something',
                                                                                        'UNITY_Status__c' => 'Inactive',
                                                                                        'UNITY_Product_Type__c' => 'Part'};

    public static  Map<String,Object> MOCKUP_PART_PRODUCT_FIELDS = new   Map<String,Object>{'Name' => 'Part',
                                                                                            'IsActive'    => true,
                                                                                            'Model__c'    => 'Part',
                                                                                            'Description' => 'Part product test',
                                                                                            'UNITY_Status__c'       => 'Inactive',
                                                                                            'UNITY_Product_Type__c' => 'Part'};

    public static  Map<String,Object> MOCKUP_TRAVEL_PRODUCT_FIELDS = new   Map<String,Object>{  'Name' => 'Travel',
                                                                                                'IsActive'    => true,
                                                                                                'Model__c'    => 'Travel',
                                                                                                'Description' => 'Travel product test',
                                                                                                'UNITY_Status__c'       => 'Inactive',
                                                                                                'UNITY_Product_Type__c' => 'Travel'};

    public static  Map<String,Object> MOCKUP_LABOR_PRODUCT_FIELDS = new   Map<String,Object>{'Name' => 'Labor',
                                                                                             'IsActive'    => true,
                                                                                             'Model__c'    => 'Labor',
                                                                                             'Description' => 'Labor product test',
                                                                                             'UNITY_Status__c'       => 'Inactive',
                                                                                             'UNITY_Product_Type__c' => 'Labor'};                                                                                    


    public static  Map<String,Object> MOCKUP_SERVICE_CONTRACT_FIELDS = new   Map<String,Object>{ 'RecordTypeId'                 => UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE,
                                                                                                 'UNITY_Account__c'             => null,
                                                                                                 'UNITY_IS_Active__c'           => true,
                                                                                                 'UNITY_Trip_Charge__c'         => 10,
                                                                                                 'UNITY_Business_Unit__c'       => 'MNS',
                                                                                                 'UNITY_Trip_Charge_Type__c'    => 'Hourly Rate',
                                                                                                 'UNITY_Signature_Template__c'  => 'something',
                                                                                                 'UNITY_Default_Labor_Rate__c'  => 100,
                                                                                                 'UNITY_Minimum_Labor_Hours__c' => 2,
                                                                                                 'UNITY_Invoicing_Increments__c'=> 'Next ¼ hr',
                                                                                                 'UNITY_ServiceReport_Template__c' => 'something',
                                                                                                 'UNITY_Required_Documentation__c' => 'something'};


    public static  Map<String,Object> MOCKUP_ORDER_FIELDS = new   Map<String,Object>{ 'Status'             => 'Draft',
                                                                                      'WorkOrder'          => null,
                                                                                      'AccountId'          => null,
                                                                                      'UNITY_Customer__c'  => null,
                                                                                      'EffectiveDate'      => Date.today()};

    public static  Map<String,Object> MOCKUP_TEMPLATE_CONIFG_FIELDS = new   Map<String,Object>{ 'UNITY_Applicable_Template__c' => 'Draft',
                                                                                                'UNITY_Node_Type__c'    => null,
                                                                                                'UNITY_Node_Value__c'   => null,
                                                                                                'UNITY_Part_Lookup__c'  => null,
                                                                                                'UNITY_Product_Activity_Type__c' => null,
                                                                                                'UNITY_Product_Type__c'  => null,
                                                                                                'UNITY_Target_Object__c' => null,
                                                                                                'UNITY_Target_Object_Record_Type__c' => null,
                                                                                                'UNITY_Template_Parent__c' => null };

    public static Map<String,Object> MOCKUP_ACCOUNT_FIELDS = new   Map<String,Object>{          'RecordTypeId'                  => null,
                                                                                                'Name'                          => 'Test Account',
                                                                                                'Account_Status__c'             => 'Active',
                                                                                                'Type'                          => 'Site/Location',
                                                                                                'UNITY_Customer_Team__c'        => 'Apple 1',
                                                                                                'UNITY_SSN__c'                  => '222-22-2222',
                                                                                                'UNITY_LOC__c'                  => 'log',
                                                                                                'UNITY_Vendor_Status__c'        => 'Active',
                                                                                                'UNITY_Miner_Regional_Office__c'=> false,
                                                                                                'UNITY_Subscriber_ID__c'        => 'subscriber',
                                                                                                'UNITY_Vendor_Type_SR__c'       => true,
                                                                                                'UNITY_Vendor_Type_Project__c'  => False,
                                                                                                'UNITY_Vendor_Type_PM__c'       => False,
                                                                                                'UNITY_Vendor_Type_SS__c'       => False,
                                                                                                'UNITY_Business_Unit__c'        => 'MNS',
                                                                                                'UNITY_Sunday_Start_Time__c'    => '00:00',
                                                                                                'UNITY_Sunday_End_Time__c'      => '23:59',
                                                                                                'UNITY_Tuesday_Start_Time__c'   => '00:00',
                                                                                                'UNITY_Tuesday_End_Time__c'     => '23:59',
                                                                                                'UNITY_Wednesday_Start_Time__c' => '00:00',
                                                                                                'UNITY_Wednesday_End_Time__c'   => '23:59',
                                                                                                'UNITY_Thursday_Start_Time__c'  => '00:00',
                                                                                                'UNITY_Thursday_End_Time__c'    => '23:59',
                                                                                                'UNITY_Friday_Start_Time__c'    => '00:00',
                                                                                                'UNITY_Friday_End_Time__c'      => '23:59',
                                                                                                'UNITY_Saturday_Start_Time__c'  => '00:00',
                                                                                                'UNITY_Saturday_End_Time__c'    => '23:59',
                                                                                                'BillingCountryCode'            => 'US',
                                                                                                'BillingCity'                   => 'Buffallo',
                                                                                                'BillingStateCode'              => 'NY',
                                                                                                'BillingStreet'                 => '123 Fake St.',
                                                                                                'BillingPostalCode'             => '92656-3211',
                                                                                                'ShippingCity'                  => 'NY',
                                                                                                'ShippingCountryCode'           => 'US',
                                                                                                'ShippingPostalCode'            => '92656-1321',
                                                                                                'UNITY_Work_Window_End__c'      => (DateTime.now().addDays(5)),
                                                                                                'UNITY_Work_Window_Begin__c'    => DateTime.now(),
                                                                                                'UNITY_Fiscal_Year_Based_On__c' => 'Starting Month',
                                                                                                'UNITY_Fiscal_Year_Start_Month__c' => '1',
                                                                                                'UNITY_Service_Report_Template__c' => 'SRT'}; 

    public static Map<String,Object> MOCKUP_WORK_ORDER_FIELDS = new   Map<String,Object>{       'CaseId'                => null,
                                                                                                'Subject'               => 'subjectWOTest',
                                                                                                'Priority'              => '24 Hour Response',
                                                                                                'AccountId'             => null,
                                                                                                'RecordTypeId'          => UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE,
                                                                                                'UNITY_Agent__c'        => UserInfo.getUserId(),
                                                                                                'UNITY_Trade__c'        => null,
                                                                                                'UNITY_Customer__c'     => null,
                                                                                                'UNITY_Business_Unit__c'=> 'Miner Corp'};

    public static Map<String,Object> MOCKUP_WORK_ORDER_LINE_ITEM_FIELDS = new   Map<String,Object>{ 'RecordTypeId'   => null,
                                                                                                    'WorkOrderId'    => null,
                                                                                                    'Description'    => 'Description'};

    public static Map<String,Object> MOCKUP_USER_FIELDS = new   Map<String,Object>{             'RecordTypeId'          => null,
                                                                                                'ContactId'             => null,
                                                                                                'ProfileId'             => null,
                                                                                                'Username'              => 'Username@name.com',
                                                                                                'LastName'              => 'LastName',
                                                                                                'Alias'                 => 'Alias',
                                                                                                'Email'                 => 'smoe@email.com',
                                                                                                'CommunityNickname'     => 'Username',
                                                                                                'LocaleSidKey'          => 'en_US',
                                                                                                'LanguageLocaleKey'     => 'en_US',
                                                                                                'TimeZoneSidKey'        => 'America/Chicago',
                                                                                                'EmailEncodingKey'      => 'UTF-8',
                                                                                                'UNITY_Tech_Capacity__c'=> 3,
                                                                                                'UNITY_Auto_Dispatch__c'=> false};

    public static Map<String,Object> MOCKUP_VENDOR_LOCATION_FIELDS   = new   Map<String,Object>{ 'Vendor__c'     =>  null,'Location_Key__c' =>  'US-123'};

    public static Map<String,Object> MOCKUP_LOCATION_FIELDS   = new   Map<String,Object>{ 'FSO__Geolocation__Latitude__s'  => 0,
                                                                                          'FSO__Geolocation__Longitude__s' => 0};

    public static Map<String,Object> MOCKUP_VENDOR_PREFERENCE_FIELDS = new   Map<String,Object>{ 'Customer__c'   =>  null,
                                                                                                 'Ranking__c'    =>  null,
                                                                                                 'Type__c'       =>  'PREFERRED',
                                                                                                 'Vendor__c'     =>  null};

    public static Map<String,Object> MOCKUP_VENDOR_PREFERENCE_TRADE_FIELDS = new   Map<String,Object>{   'Customer__c' =>  null,
                                                                                                         'Trade__c'    =>  null,
                                                                                                         'Vendor__c'   =>  null,
                                                                                                         'Vendor_Preference__c' =>  null};

    public static Map<String,Object> MOCKUP_VENDOR_ASSIGNMENT_FIELDS = new   Map<String,Object>{ 'Customer__c'   =>  null,
                                                                                                 'Trade__c'      =>  null,
                                                                                                 'Vendor__c'     =>  null,
                                                                                                 'PIN__c'        =>  null,
                                                                                                 'Status__c'     =>  null,
                                                                                                 'Work_Order__c' =>  null,
                                                                                                 'UNITY_Vendor_Email__c' => 'some@mail.com'};

    public static Map<String,Object> MOCKUP_CASE_FIELDS              = new   Map<String,Object>{ 'Customer__c'   =>  null,
                                                                                                 'RecordTypeId'  =>  null,
                                                                                                 'Status'        =>  'Verified',
                                                                                                 'ContactId'     =>  null,
                                                                                                 'UNITY_Business_Unit__c'=>'Miner Corp'};

    public static Map<String,Object> MOCKUP_VENDOR_TRADE_FIELDS      = new   Map<String,Object>{'RecordTypeId'     => null,
                                                                                                'Vendor__c'   => null,
                                                                                                'Trade__c'    => null,
                                                                                                'Score_PM__c' => null,
                                                                                                'Price_PM__c' => null,
                                                                                                'Score_SR__c' => null,
                                                                                                'Price_SR__c' => null,
                                                                                                'Score_SS__c' => null,
                                                                                                'Price_SS__c' => null,
                                                                                                'Score_Project__c' => null,
                                                                                                'Price_Project__c' => null};
    public static Map<String,Object> getObjectMapFields(SObjectType objectT) {
        Map<String,Object> toReturn = new Map<String,Object>();
        if(objectT != null ){
            for( String fieldName :objectT.getDescribe().fields.getMap().keySet()){
                Schema.DescribeFieldResult field = objectT.getDescribe().fields.getMap().get(fieldName).getDescribe();
                if(field.isAccessible() && !field.isCalculated() && !field.isAutoNumber() && field.isUpdateable() ){
                    toReturn.put(fieldName,null);
                }
            }
        }
        return toReturn;
    }

    public static Account createAccount(String accountName) {
        String aa = Account.UNITY_Customer_Team__c.getDescribe().getPicklistValues().get(0).getValue();
        Account acc = new Account(Name=accountName);
        acc.BillingStateCode = 'NY';
        //account.UNITY_Customer_Team__c = aa;
        acc.UNITY_TimeZoneSidKey__c = 'America/Chicago';
        return acc;
    }

    public static Contact createContact(String firstName, String lastName, Id accountId) {
        Contact contact = new Contact(FirstName=firstName,
                                      LastName=lastName,
                                      AccountId=accountId,
                                      Email='email@home'+Math.ceil(Math.random()*100)+'.com');
        insert contact;
        return contact;
    }

    public static List<Account> createAccounts(Integer size) {
        return createAccounts(size,null);
    }

    public static List<Account> createAccounts(Integer size, String recordType) {
        return createAccounts(size,null,recordType);
    }

    public static List<Account> createAccounts(Integer size,String type, String recordType) {
        List<Account> accounts = new List<Account>();
        for(Integer index=0; index<size; index++) {
            Account account = createAccount('Name'+index+'-'+TestDataProvider.getRandomInt(11111,99999));
            account.BillingCity = 'billingCity'+index;
            account.BillingStateCode = 'NY';
            account.BillingStreet = '123 Fake St.'+'-'+TestDataProvider.getRandomInt(11111,99999);
            account.BillingPostalCode = String.valueOf(TestDataProvider.getRandomInt(11111,99999));
            account.UNITY_SSN__c = '222-22-2222';
            account.Account_Status__c = 'Active';
            if(type != null){
              account.Type = type;
            }
            if(recordType != null) {
                account.RecordTypeId = recordType;
                //System.assert(false,recordtype);
            }
            accounts.add(account);
        }
        insert accounts;
        System.assert(accounts.size() == size,'The '+size+' accounts should be created.');
        accounts = [SELECT Id,Name,Account_Status__c
                      FROM Account
                      WHERE Id IN : UNITY_Utils.joiningByIdList(accounts)];

        return accounts;
    }

    public static List<Account> createAccounts(Integer size, id recordType, Map<String,Boolean> vendorRT, Map<String,String> operationalHours,Boolean minerPreferred ,String prefix) {
        //System.assert(prefix != null,'You should use a prefix.');
        List<Account> accounts = new List<Account>();
        Map<String,Object> mockupFields = MOCKUP_ACCOUNT_FIELDS;

        mockupFields.put('RecordTypeId', recordType);

        accounts = createObject(size, Account.getSObjectType(), mockupFields , true);

        for(Account acc :accounts){
            acc.put('Name', 'A-'+UNITY_Utils.generateRandomPin());
            if(vendorRT != null){
                for(String var :vendorRT.keySet()){
                    acc.put(var.toLowerCase(),vendorRT.get(var));
                }
            }
            if(operationalHours != null){
                for(String var :operationalHours.keySet()){
                    acc.put(var.toLowerCase(),operationalHours.get(var));
                }
            }
        }


        /*
        for(Integer index=0; index<size; index++) {
            Account account = new Account();
            if(recordType != null )account.RecordTypeId  = recordType;
            account.Name = prefix+index;
            account.UNITY_LOC__c = prefix+index;
            account.UNITY_Subscriber_ID__c    = prefix+index;
            account.UNITY_Preferred_Vendor__c = minerPreferred;
            account.UNITY_Vendor_Status__c    = 'Active';
            account.Account_Email__c          = 'account-'+index+'@email.com';
            account.BillingCountryCode        = 'US';
            account.BillingCity               = 'billingCity';
            account.BillingStateCode          = 'NY';
            account.BillingStreet             = '123 Fake St.';
            account.Type                      = 'Site/Location';
            account.BillingPostalCode         = '123-321';
            account.ShippingCity              = 'Fakevile';
            account.UNITY_SSN__c              = '222-22-2222';
            //account.ShippingCountryCode       = 'US';
            account.ShippingPostalCode        = '123-321';
            account.ShippingStreet            = '123 Fake St.';
            account.Account_Status__c    = 'Active';
            if(vendorRT != null){
                for(String var :vendorRT.keySet()){
                    account.put(var.toLowerCase(),vendorRT.get(var));
                }
            }
            if(operationalHours != null){
                for(String var :operationalHours.keySet()){
                    account.put(var.toLowerCase(),operationalHours.get(var));
                }
            }
            accounts.add(account);
        }*/
        System.assert(accounts.size() == size,'The '+size+' accounts should be created.');
        return accounts;
    }

    public static List<UNITY_Service_Contract__c> createServiceContracts(Integer size, Id accountId) {
        List<UNITY_Service_Contract__c> serviceContracts = new List<UNITY_Service_Contract__c>();
        for(Integer index=0; index<size; index++) {
            UNITY_Service_Contract__c serviceContract1 = new UNITY_Service_Contract__c();
            serviceContract1.UNITY_Account__c = accountId;
            serviceContract1.UNITY_Trip_Charge__c = 10;
            serviceContract1.UNITY_Trip_Charge_Type__c = 'Hourly Rate';
            serviceContract1.UNITY_Default_Labor_Rate__c = 75;
            serviceContract1.UNITY_Invoicing_Increments__c = 'Next ¼ hr';
            serviceContract1.UNITY_IS_Active__c = true;
            serviceContract1.UNITY_ServiceReport_Template__c = 'my template';
            serviceContracts.add(serviceContract1);
        }

        insert serviceContracts;
        System.assert(UNITY_Utils.joiningByIdList(serviceContracts).size() == size,'The '+size+' service contracts should be created. ');
        return serviceContracts;
    }

    public static List<Contact> createContacts(Integer size, Id accountId) {
        List<Contact> contacts = new List<Contact>();
        for(Integer index=0; index<size; index++) {
            Contact contact = new Contact(FirstName='FirstName'+index,
                                          LastName='LastName'+index,
                                          AccountId= accountId,
                                          Email='email@home'+index+'.com');
            contacts.add(contact);
        }
        insert contacts;
        System.assert(contacts.size() == size,'The '+size+' contacts should be created.');
        return contacts;
    }

    public static List<User> createUsersTechnician(Integer size, Id contactId) {
        Profile profile = [SELECT Id FROM Profile
                           WHERE Name =:UNITY_Constants.PROFILE_PARTNER_TECHNICIAN_VENDOR_NAME LIMIT 1];
        return createUsers(size,contactId,profile.Id);
    }

    public static List<User> createUsersTechnician(Integer size, Map<String,Object> fields ) {
        Profile profile = [SELECT Id FROM Profile
                           WHERE Name =:UNITY_Constants.PROFILE_PARTNER_TECHNICIAN_VENDOR_NAME LIMIT 1];

        fields.put('ProfileId',profile.Id);
        return createObject(size, User.getSObjectType() ,fields);
    }

    public static List<User> createReadOnlyUsers(Integer size, Id contactId) {
        Profile profile = [SELECT Id FROM Profile
                           WHERE Name =:UNITY_Constants.PROFILE_READ_ONLY_ACCESS_NAME LIMIT 1];

        return createUsers(size,contactId,profile.Id);
    }

    public static List<User> createUsers(Integer size, Id contactId, Id profileId) {
        Profile profile = [SELECT Id FROM Profile
                           WHERE Id =: profileId];
        List<User> users = new List<User>();
        for(Integer index=0; index<size; index++) {
            User user = new User();
            user.ContactId = contactId;
            user.ProfileId = profile.Id;
            user.Username = 'whoknows@home'+index+'.com';
            user.LastName = 'LastName'+index;
            user.Alias = user.Username.substring(0,Math.min(user.Username.length()-1,7));
            user.Email = user.Username;
            user.CommunityNickname = user.LastName;
            user.TimeZoneSidKey = 'America/Chicago';
            user.LocaleSidKey = 'en_US';
            user.EmailEncodingKey = 'UTF-8';
            user.LanguageLocaleKey = 'en_US';
            users.add(user);
        }
        insert users;
        return users;
    }

    public static List<FSO__Skill__c> createSkills(Integer size) {
        List<FSO__Skill__c> skills = new List<FSO__Skill__c>();
        for(Integer index=0; index<size; index++) {
            FSO__Skill__c skill = new FSO__Skill__c(Name='SkillName'+index);
            skills.add(skill);
        }
        insert skills;
        System.assert(skills.size() == size,'The '+size+' skills should be created.');

        return skills;
    }

    public static FSO__Skill__c createSkills(String name) {
        FSO__Skill__c skill = new FSO__Skill__c(Name=name);
        return skill;
    }

    public static list<FSO__Skill__c> createSkills(Integer max , boolean shouldInsert) {

       if(shouldInsert) return createSkills(max);

       list<FSO__Skill__c> toReturn   =  new list<FSO__Skill__c>();
       Map<String,Object> skillFields = MOCKUP_FSO_SKILL_FIELDS;
       for(integer i = 0 ; i < max ; i++){
            skillFields.put('Name', 'skill-'+String.valueOf(i));
            toReturn.add((FSO__Skill__c)UNITY_TestDataFactory.createObject(1, FSO__Skill__c.getSObjectType(),skillFields ).get(0));
        }
        return toReturn;

    }

    public static List<UNITY_Vendor_Trade__c> createTrades(List<FSO__Skill__c> skills, List<Account> accounts) {
        List<UNITY_Vendor_Trade__c> vendorTrades = new List<UNITY_Vendor_Trade__c>();
        Integer min = Math.min(skills.size(), accounts.size());
        for(Integer index=0; index<min ;index++) {
            Account account = accounts.get(Math.mod(index,min));
            FSO__Skill__c skill = skills.get(Math.mod(index,min));
            UNITY_Vendor_Trade__c vendorTrade = new UNITY_Vendor_Trade__c(Vendor__c=account.Id,
                                                                          Trade__c=skill.Id);
            vendorTrades.add(vendorTrade);
        }
        insert vendorTrades;
        System.assert(vendorTrades.size() == min,'The '+min+' vendor trades should be created.');
        return vendorTrades;
    }

    public static List<Case> createCases(Integer size, Id customerId, Id endUserId) {
        return createCases(size, customerId, endUserId, null, null);
    }

    public static List<Case> createCases(Integer size, Id customerId, Id endUserId, Id contactId) {
        return createCases(size, customerId, endUserId, contactId, null);
    }

    public static List<Case> createCases(Integer size, Id customerId, Id endUserId,Id contactId, Id recordType) {
        List<Case> cases = new List<Case>();
        for(Integer index=0; index<size ;index++) {
            Case acase = new Case();
            acase.AccountId = customerId;
            //acase.UNITY_Customer__c = customerId;
            if(recordType != NULL) {
                acase.RecordTypeId = recordType;
            }
            acase.ContactId = contactId;
            acase.Status = 'Verified';
            cases.add(acase);
        }
        insert cases;
        System.debug(' createCases :'+cases);
        System.assert(cases.size() == size,'The '+size+' cases should be created.');
        return cases;
    }

    public static List<WorkOrder> createWorkOrders(Integer size, Id caseId) {
        return createWorkOrders(size, caseId, null, null, null);
    }

    public static List<WorkOrder> createWorkOrders(Integer size, Id caseId, Id recordTypeId) {
        return createWorkOrders(size, caseId, null, null, null);
    }
    
     public static List<WorkOrder> createWorkOrders(Integer size, Id caseId, Id accountId, Id recordTypeId) {
        return createWorkOrders(size, caseId, accountId, null, null);
    }
    
    public static List<WorkOrder> createWorkOrders(Integer size, Id caseId, Id accountId, Id serviceContractId, Id recordTypeId) {
        List<WorkOrder> workOrders = new List<WorkOrder>();
        for(Integer index=0; index<size; index++) {
            WorkOrder workOrder = new WorkOrder();
            workOrder.Subject = 'Subject-'+index;
            workOrder.CaseId = caseId;
            if(accountId != NULL) {
                workOrder.accountId = accountId;
                workOrder.UNITY_Customer__c = accountId;
                
            }
            workOrder.UNITY_Customer_PIN__c = UNITY_Utils.generateRandomPin();
            workOrder.UNITY_Vendor_PIN__c = UNITY_Utils.generateRandomPin();
            workOrder.UNITY_Vendor_Status__c = UNITY_Constants.WO_STATUS_ASSIGNED;
            workOrder.UNITY_Agent__c = UserInfo.getUserId();
            if(serviceContractId != NULL) {
                workOrder.UNITY_Customer_Service_Contract__c = serviceContractId;   
            }
            if(recordTypeId != NULL) {
                workOrder.RecordTypeId = recordTypeId;
            }
            workOrders.add(workOrder);
        }
        insert workOrders;
        workOrders = [SELECT Id,UNITY_Vendor_PIN__c,Subject,CaseId,WorkOrderNumber,
                           UNITY_Vendor_Status__c,ContactId
                      FROM WorkOrder
                      WHERE Id IN : UNITY_Utils.joiningByIdList(workOrders)];
        System.assert(UNITY_Utils.joiningByIdList(workOrders).size() == size,'The '+size+' work orders should be created.');
        return workOrders;
    }

    public static List<WorkOrder> createWorkOrders(Integer size, Map<String,Object> fields ) {
        List<WorkOrder> workOrders = new List<WorkOrder>();
        for(Integer index=0; index<size; index++) {
            WorkOrder workOrder = new WorkOrder();
            if(fields!=null){
               for(String field :fields.keySet()){
                   if((field!=null) &&(workOrder.getsObjectType().getDescribe().fields.getMap().get(field) != null)){
                       workOrder.put(field.toLowerCase(),fields.get(field));
                   }
                }
            }
            workOrders.add(workOrder);
        }
        System.assert(workOrders.size() == size,'The '+size+' work orders should be created.');
        return workOrders;
    }

    public static List<UNITY_Vendor_Assignment__c> createVendorAssignments(Integer size, Id customerId, Id workOrderId) {
        List<UNITY_Vendor_Assignment__c> assigments = new List<UNITY_Vendor_Assignment__c>();
        for(Integer index=0; index<size; index++) {
            UNITY_Vendor_Assignment__c assigment = new UNITY_Vendor_Assignment__c();
            assigment.Customer__c = customerId;
            assigment.Work_Order__c = workOrderId;
            assigments.add(assigment);
        }
        insert assigments;
        System.assert(assigments.size() == size,'The '+size+' assigments should be created.');
        return assigments;

    }

    public static List<UNITY_Invoice__c> createInvoices(Integer size, Id caseId, Id accountId) {
        List<UNITY_Invoice__c> invoices = new List<UNITY_Invoice__c>();
        for(Integer index=0; index<size; index++) {
            UNITY_Invoice__c invoice = new UNITY_Invoice__c();
            invoice.RecordTypeId = UNITY_Constants.INVOICE_VENDOR_RECORDTYPE;
            invoice.UNITY_Case__c = caseId;
            invoice.UNITY_Customer__c = accountId;
            invoices.add(invoice);
        }
        insert invoices;
        System.assert(invoices.size() == size,'The '+size+' invoices should be created.');
        return invoices;
    }

    public static List<UNITY_Proposal__c> createQuote(Integer size, Id caseId, Id workOrderId, Id accoundId, Id userId) {
        List<UNITY_Proposal__c> proposals = new List<UNITY_Proposal__c>();
        for(Integer index=0; index<size; index++) {
            UNITY_Proposal__c proposal = new UNITY_Proposal__c();
            proposal.RecordTypeId = UNITY_Constants.PROPOSAL_CUSTOMER_PROPOSAL_RECORDTYPE;
            proposal.UNITY_Proposal_Status__c = 'Quote Creation';
            proposal.UNITY_Case__c = caseId;
            proposal.UNITY_Work_Order__c = workOrderId;
            proposal.UNITY_Effective_Till_Date__c = Date.today();
            proposal.UNITY_Agent__c = userId;
            proposal.UNITY_Customer__c = accoundId;
            proposals.add(proposal);
        }
        System.debug('>>>> proposals: '+proposals);
        insert proposals;

        proposals = [SELECT Id,Name,UNITY_Status__c,UNITY_Customer_PIN__c,UNITY_Proposal_Status__c,UNITY_Case__c,UNITY_Work_Order__c,UNITY_Master_Quote__c
                    FROM UNITY_Proposal__c
                    WHERE Id IN :UNITY_Utils.joiningByIdList(proposals)];
        System.assert(proposals.size() == size,'The '+size+' proposals should be created.');
        return proposals;
    }

    public static List<SObject> createObject(Integer size, SObjectType objectT , Map<String,Object> fields ) {
        List<SObject> objects = new List<SObject>();
        for(Integer index=0; index<size; index++) {
            SObject obj = objectT.newSObject();
            if(fields!=null){
               for(String field :fields.keySet()){
                   if((field!=null) &&(objectT.getDescribe().fields.getMap().get(field) != null)){
                       obj.put(field.toLowerCase(),fields.get(field));
                   }
                }
            }
            objects.add(obj);
        }
        handleDuplicates( objectT , objects);
        System.assert(objects.size() == size,'The '+size+' work orders should be created.');
        return objects;
    }

    public static List<SObject> createObject(Integer size, SObjectType objectT , Map<String,Object> fields, boolean clearDups ) {
        List<SObject> objects = new List<SObject>();
        for(Integer index=0; index<size; index++) {
            SObject obj = objectT.newSObject();
            if(fields!=null){
               for(String field :fields.keySet()){
                   if((field!=null) &&(objectT.getDescribe().fields.getMap().get(field) != null)){
                       obj.put(field.toLowerCase(),fields.get(field));
                   }
                }
            }
            objects.add(obj);
        }
        if(clearDups) handleDuplicates( objectT , objects);
        System.assert(objects.size() == size,'The '+size+' work orders should be created.');
        return objects;
    }

    private static void handleDuplicates(SObjectType objectT , List<SObject>  objs) {

        for(SObject obj :objs){
            if(objectT == Account.getSobjectType())handleDuplicatesAccount(obj);
            if(objectT == Contact.getSobjectType())handleDuplicatesContact(obj);
            if(objectT == FSO__Skill__c.getSobjectType())handleDuplicatesSkills(obj);
        }
    }

    private static void handleDuplicatesSkills(SObject  obj) {
        String        randomA = UNITY_Utils.generateRandomPin();
        FSO__Skill__c skill   = (FSO__Skill__c) obj;
        skill.Name = 'S-'+randomA;
    }

    private static void handleDuplicatesAccount(SObject  obj) {
        String randomA = UNITY_Utils.generateRandomPin();
        String randomB = UNITY_Utils.generateRandomPin();
        Account acc = (Account) obj;
        if(acc.RecordTypeId == UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE)
            acc.Name = 'C-'+randomA;
        else if(acc.RecordTypeId == UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE)
            acc.Name = 'V-'+randomA;
        acc.BillingPostalCode  = randomA+'-'+randomB;
        acc.BillingStreet      = randomA+ ' STREET.';

    }

    private static void handleDuplicatesContact(SObject  obj) {
        String random = UNITY_Utils.generateRandomPin();
        Contact cont = (Contact) obj;
        cont.firstName  = 'Unit'+random;
        cont.lastName   = 'Test'+random;
        cont.email      = 'UnitTest'+random+'@email.com';

    }

     public static void handleDatabaseResult(list<Database.SaveResult> srs) {
        for(Database.SaveResult sr :srs){
            handleDatabaseResult(sr);
        }
    }

    public static void handleDatabaseResult(Database.SaveResult sr) {
        String message = '';
        if(!sr.isSuccess()){
            for(Database.Error e :sr.getErrors()){
                message += e.getMessage()+' <|> ';
            }
        }
        system.assertEquals(true , sr.isSuccess(), message);

    }

    public static Id getMixRecordType(Schema.SObjectType soTypeTo, Schema.SObjectType soTypeFrom, Id recordTypeIdFrom) {

        String recordTypeNameFrom = getRecordTypeName(soTypeFrom, recordTypeIdFrom);


        return getMixRecordType(soTypeTo, soTypeFrom, recordTypeNameFrom);
    }

    public static String getRecordTypeName(Schema.SObjectType soTypeFrom, Id recordTypeIdFrom) {

        String recordTypeNameFrom = (soTypeFrom.getDescribe() != null
                                    && soTypeFrom.getDescribe().getRecordTypeInfosById() != null
                                    && soTypeFrom.getDescribe().getRecordTypeInfosById().get(recordTypeIdFrom) != null)?
                                    soTypeFrom.getDescribe().getRecordTypeInfosById().get(recordTypeIdFrom).getName():null;


        return recordTypeNameFrom;
    }

    public static Id getMixRecordType(Schema.SObjectType soTypeTo, Schema.SObjectType soTypeFrom, String recordTypeNameFrom) {
        return  (soTypeTo.getDescribe() != null
                && soTypeTo.getDescribe().getRecordTypeInfosByName() != null
                && soTypeTo.getDescribe().getRecordTypeInfosByName().get(recordTypeNameFrom) != null)?
                soTypeTo.getDescribe().getRecordTypeInfosByName().get(recordTypeNameFrom).getRecordTypeId():null;
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
    public static void insertAutopopulateMapping(){
        
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
    public static void insertRelationshipLookups(){

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

    public static List<PricebookEntry> cretePriceBookEntries(List<Product2> products, Integer miltiplier){
        return cretePriceBookEntries(products, miltiplier,true);
    }

    public static List<PricebookEntry> cretePriceBookEntries(List<Product2> products, Integer miltiplier, Boolean shouldInsert){

        Id      spId = Test.getStandardPricebookId();
        Integer unit = 30;

        List<PricebookEntry> pe = new List<PricebookEntry>();

        for(Integer i = 0 ; i < products.size(); i ++ ){
            pe.add(new PricebookEntry(  Pricebook2Id    = spId,
                                        Product2Id      = products.get(i).Id,
                                        UnitPrice       = ((unit*miltiplier)+unit)));
        }

        if(shouldInsert) insert pe;

        return pe;
    }

    public static List<UNITY_Service_Contract__c> creteServiceContracts(List<Account> accountIds, Map<String,Object> fields){
        return creteServiceContracts(accountIds, fields, true);
    }

    public static List<UNITY_Service_Contract__c> creteServiceContracts(List<Account> accountIds, Map<String,Object> fields, boolean shouldInsert){

        List<UNITY_Service_Contract__c> serviceContracts = new List<UNITY_Service_Contract__c>();

        for(Account acc :accountIds){
            fields.put('UNITY_Account__c',acc.Id);
            serviceContracts.addAll((List<UNITY_Service_Contract__c>)UNITY_TestDataFactory.createObject(1, UNITY_Service_Contract__c.getSObjectType() , fields));
        }

        if(shouldInsert) insert  serviceContracts;

        return serviceContracts;

    }

    public static UNITY_Template_Configuration__c creteTemplateConfigPO(Id partlId, Id laborId, Id travelId){

        UNITY_Template_Configuration__c parentTemplate = new UNITY_Template_Configuration__c ();
        
        parentTemplate.RecordTypeId = UNITY_Constants.TEMPLATE_CONFIG_PURCHASE_ORDER_RECORDTYPE;
        parentTemplate.UNITY_Template_Parent__c = null;
        parentTemplate.Name = 'Test PO';
        
        insert parentTemplate;
        
        List<UNITY_Template_Configuration__c> childTemplate = new List<UNITY_Template_Configuration__c>();
        
        UNITY_Template_Configuration__c childTemplate1 = new UNITY_Template_Configuration__c ();
        
        childTemplate1.RecordTypeId             = UNITY_Constants.TEMPLATE_CONFIG_PURCHASE_ORDER_RECORDTYPE;
        childTemplate1.UNITY_Template_Parent__c = parentTemplate.Id;
        childTemplate1.Name                     = 'Test POLI';
        childTemplate1.UNITY_Node_Value__c      = '1';
        childTemplate1.UNITY_Target_Object__c   = 'OrderItem';
        childTemplate1.UNITY_Part_Lookup__c     = partlId;
        
        childTemplate.add(childTemplate1);
        
        UNITY_Template_Configuration__c childTemplate2 = new UNITY_Template_Configuration__c ();
        
        childTemplate2.RecordTypeId             = UNITY_Constants.TEMPLATE_CONFIG_PURCHASE_ORDER_RECORDTYPE;
        childTemplate2.UNITY_Template_Parent__c = parentTemplate.Id;
        childTemplate2.Name                     = 'Test POLI';
        childTemplate2.UNITY_Node_Value__c      = '10';
        childTemplate2.UNITY_Target_Object__c   = 'OrderItem';
        childTemplate2.UNITY_Part_Lookup__c     = laborId;
        
        childTemplate.add(childTemplate2);
        
        UNITY_Template_Configuration__c childTemplate3 = new UNITY_Template_Configuration__c ();
        
        childTemplate3.RecordTypeId             = UNITY_Constants.TEMPLATE_CONFIG_PURCHASE_ORDER_RECORDTYPE;
        childTemplate3.UNITY_Template_Parent__c = parentTemplate.Id;
        childTemplate3.Name                     = 'Test POLI';
        childTemplate3.UNITY_Node_Value__c      = '3';
        childTemplate3.UNITY_Target_Object__c   = 'OrderItem';
        childTemplate3.UNITY_Part_Lookup__c     = travelId;
        
        childTemplate.add(childTemplate3);
        
        insert childTemplate;

        return parentTemplate;

    }

    public static List<FSO__LocationStock__c>  creteLocationStock(List<FSO__Location__c> locations, List<Product2> products, Map<String,Object> fields){
        return creteLocationStock(locations, products, fields, true);
    }

    public static List<FSO__LocationStock__c>  creteLocationStock(List<FSO__Location__c> locations, List<Product2> products, Map<String,Object> fields, Boolean shouldInsert){

        List<FSO__LocationStock__c>  locationStocks =  new List<FSO__LocationStock__c> ();

        for(FSO__Location__c location :locations){
            for(Product2 product :products){
                fields.put('FSO__Product__c'  , product.Id);
                fields.put('FSO__Location__c' , location.Id);
                if(fields.get('UNITY_MAC__c')     ==null)fields.put('UNITY_MAC__c'     , 'AAA');
                if(fields.get('FSO__Quantity__c') ==null)fields.put('FSO__Quantity__c' , 10);
                locationStocks.addAll((List<FSO__LocationStock__c>)UNITY_TestDataFactory.createObject(1, FSO__LocationStock__c.getSObjectType(), fields));
            }
        }

        if(shouldInsert) insert locationStocks;

        return locationStocks;
    }


    public static  OrderItem creteOrderItem( Id orderId, Id pbeId, Id accountBUId, String type, Boolean isVendorSupply, Decimal cost, Decimal unitPrice,String numberOfTechs, Boolean customerOTMultiplier, Boolean  vendorHolidayMultiplier){

        Map<String,Object> orderItemFields = new Map<String,Object>();

        orderItemFields.put('Quantity' , 2);

        if(cost != null)            orderItemFields.put('UNITY_Cost__c',cost);
        if(type != null)            orderItemFields.put('UNITY_Type__c',type);
        if(pbeId != null)           orderItemFields.put('PricebookEntryId',pbeId);
        if(orderId != null)         orderItemFields.put('OrderId',orderId);
        if(unitPrice != null)       orderItemFields.put('UnitPrice',unitPrice);
        if(accountBUId != null)     orderItemFields.put('UNITY_Part_Source__c',accountBUId);
        if(numberOfTechs != null)   orderItemFields.put('UNITY_Number_of_Techs__c',numberOfTechs);
        if(isVendorSupply != null)  orderItemFields.put('UNITY_Is_Vendor_Supply__c',isVendorSupply);
        if(customerOTMultiplier != null)  orderItemFields.put('UNITY_Customer_OT_Multiplier__c',customerOTMultiplier);
        if(vendorHolidayMultiplier != null)  orderItemFields.put('UNITY_Customer_Holiday_Multiplier__c',vendorHolidayMultiplier);

        return  (OrderItem)UNITY_TestDataFactory.createObject(1, OrderItem.getSObjectType(), orderItemFields).get(0);

    }

    public static  OrderItem creteOrderItem( Id orderId, Id pbeId, Id accountBUId, String type, Boolean isVendorSupply, Decimal cost, Decimal unitPrice,String numberOfTechs,Boolean include){

        Map<String,Object> orderItemFields = new Map<String,Object>();

        orderItemFields.put('Quantity' , 2);


        if(cost != null)            orderItemFields.put('UNITY_Cost__c',cost);
        if(type != null)            orderItemFields.put('UNITY_Type__c',type);
        if(pbeId != null)           orderItemFields.put('PricebookEntryId',pbeId);
        if(include != null)         orderItemFields.put('UNITY_Include__c',include);
        if(orderId != null)         orderItemFields.put('OrderId',orderId);
        if(unitPrice != null)       orderItemFields.put('UnitPrice',unitPrice);
        if(accountBUId != null)     orderItemFields.put('UNITY_Part_Source__c',accountBUId);
        if(numberOfTechs != null)   orderItemFields.put('UNITY_Number_of_Techs__c',numberOfTechs);
        if(isVendorSupply != null)  orderItemFields.put('UNITY_Is_Vendor_Supply__c',isVendorSupply);

        return  (OrderItem)UNITY_TestDataFactory.createObject(1, OrderItem.getSObjectType(), orderItemFields).get(0);

    }


    public static void generateEnviroment() {

    }

}