/**This class provides a seried of methods that generate data to use on unit test classes
** @programer: Izay Ramos-Irizarry
** @version: 1.0
** @date: 6/11/2015
*/
@isTest
public class TestDataProvider {
    /** This method returns a list of accounts.
     * @param count - Integer: The number of accounts to return.
     * @param recType - String: The record type for the accounts to be returned. [Customer Account,FLEXX Accounts,FLEXX Customer,In Progress Account, M&A Accounts, Parent Account, Prospect Accounts,Standard,Vendor Account]
     * @param type - String: The account type. [Customer,FFM (Full Facility Maintenance),Competitor,Partner,Supplier,Vendor,Field Office,Other,Lender Account,Prospect Affiliate,Parent Account]
     * @return - List<Account>
     */
    public static List<Account> getAccounts(Integer count, String recType, String type){
        List<Account> accounts = new List<Account>();
        String rtid = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = :recType LIMIT 1].Id;
        for(Integer i = 0; i < count; i++){
            Account a = new Account(
                Name = 'TestAccount_' + String.valueOf(getRandomInt(100,999)),
                BillingStreet = String.valueOf(getRandomInt(100,999)) + ' ' + String.valueOf(getRandomInt(10,99)) + ' Street',
                BillingCity = 'San Antonio',
                //BillingState = 'TX',
                BillingStateCode = 'TX',
                BillingCountry = 'US',
                BillingPostalCode = String.valueOf(getRandomInt(10000,99999)),
                ShippingStreet = String.valueOf(getRandomInt(100,999)) + ' ' + String.valueOf(getRandomInt(10,99)) + ' Street',
                ShippingCity = 'San Antonio',
                //BillingState = 'TX',
                ShippingStateCode = 'TX',
                ShippingCountry = 'US',
                ShippingPostalCode = String.valueOf(getRandomInt(10000,99999)),
                RecordTypeId = rtid,
                Type = type
            );
            accounts.add(a);
        }
        return accounts;
    }
    public static List<Account> getAccounts(Integer count, String type){
        List<Account> accounts = new List<Account>();
        for(Integer i = 0; i < count; i++){
            Account a = new Account(
                Name = 'TestAccount_' + String.valueOf(getRandomInt(100,999)),
                BillingStreet = String.valueOf(getRandomInt(100,999)) + ' ' + String.valueOf(getRandomInt(10,99)) + ' Street',
                BillingCity = 'San Antonio',
                //BillingState = 'TX',
                BillingStateCode = 'TX',
                BillingCountry = 'US',
                BillingPostalCode = String.valueOf(getRandomInt(10000,99999)),
                ShippingStreet = String.valueOf(getRandomInt(100,999)) + ' ' + String.valueOf(getRandomInt(10,99)) + ' Street',
                ShippingCity = 'San Antonio',
                //BillingState = 'TX',
                ShippingStateCode = 'TX',
                ShippingCountry = 'US',
                ShippingPostalCode = String.valueOf(getRandomInt(10000,99999)),
                Type = type
            );
            accounts.add(a);
        }
        return accounts;
    }
    /** This method returns a list of locations for a specified account.
     * @param count - Integer: The number of locations to return.
     * @param recType - String: The record type for the location(s) to be returned. [Depot,Depot Child,Depot Parent,Inventory Location,Location Site,Standard Location]
     * @param callType - String: The call type of the locations. [TFS,AMS,NMS,EXT.GMC,SPSC]
     * @param acctId - String: The account the location(s) is associated to.
     * @return - List<SVMXC__Site__c>
     */
    public static List<SVMXC__Site__c> getLocations(Integer count, String recType, String callType, String acctId){
        List<SVMXC__Site__c> locations = new List<SVMXC__Site__c>();
        String rtid = [SELECT Id FROM recordType WHERE SObjectType = 'SVMXC__Site__c' AND Name = :recType LIMIT 1].Id;
        for(Integer i = 0; i < count; i++){
            SVMXC__Site__c l = new SVMXC__Site__c(
                Name = 'TestLocation_' + i,
                SVMXC__Street__c = i + '00 Main Street',
                SVMXC__City__c = 'San Antonio',
                SVMXC__State__c = 'TX',
                SVMXC__Zip__c = '78232',
                Call_Type__c = callType,
                SVMXC__Account__c = acctId,
                RecordTypeId = rtid
            );
            locations.add(l);
        }
        return locations;
    }
    /**
     * getUser creates a single user with defaults for required fields. 
     * @param  firstName   First Name of user - i.e John
     * @param  lastName    Last name of user - i.e. 'Smith'
     * @param  profileName Target profile for this user, IF NOT FOUND will default to Standard User - i.e. 'System Administrator'
     * @return             User. A single user for manipulation and insertion
     */
    public static User getUser(String firstName, String lastName, String profileName){
        //try to find the profile they requested
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        //if it isnt found, select a standard user profile
        if(p == null)
            p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        //Now create the User to return
        User user = new User(
            Alias = firstName.left(1) + lastName.left(4), 
            Email = firstName.left(1) + lastName + '@testsfdc.net',
            EmailEncodingKey = 'ISO-8859-1',
            UserName = firstName.left(2) + lastName + '@testsfdc.net',
            FirstName = firstname,
            LastName = lastName,
            CommunityNickname = firstName.left(1) + lastName,
            TimeZoneSidKey = 'America/Chicago',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id );
        return user;
    }
    /** This method returns a list of installed products for a specified location.
     * @param count - Integer: The number of installed product to return.
     * @param recType - String: The record type for the installed product(s) to be returned. [Installed Product]
     * @param locationId - String: The location the installed product(s) is associated to.
     * @param acctId - String: The account the installed product(s) is associated to.
     * @return - List<SVMXC__Installed_Product__c>
     */
    public static List<SVMXC__Installed_Product__c> getInstalledProducts(Integer count, String recType, String locationId, String acctId){
        String rtid = [SELECT Id FROM recordType WHERE SObjectType = 'SVMXC__Installed_Product__c' AND Name = :recType LIMIT 1].Id;
        List<SVMXC__Installed_Product__c> installedProds = new List<SVMXC__Installed_Product__c>();
        Product2 prod = new Product2(
            Name = 'TestProduct_IP',
            ProductCode = 'Test-123456',
            Make1__c = 'TestMake',
            Model__c = 'TestModel',
            Broad__c = 'Door',
            Group__c = 'High Speed',
            Type__c = 'Electrical',
            Family = 'Equipment',
            SVMXC__Product_Line__c = 'Equipment',
            IsActive = true,
            Description = 'Installed Product Test Product',
            SVMXC__Product_Cost__c = 0.00,
            SVMXC__Inherit_Parent_Warranty__c = true,
            UNITY_Status__c = 'Active',
            UNITY_Product_Cost__c = 0,
            UNITY_Unit_Of_Measure__c = 'Each'
        );
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, 
            Product2Id = prod.Id,
            UnitPrice = 100, 
            IsActive = true
        );
        insert standardPrice;
        for(Integer i = 0; i < count; i++){
            SVMXC__Installed_Product__c ip = new SVMXC__Installed_Product__c(
                Name = 'TestLocation_IP_' + i,
                Serial_Number__c = '123456_' + i,
                SVMXC__Asset_Tag__c = 'ABC' + i,
                SVMXC__Status__c = 'Active',
                Broad_IP__c = 'Door',
                Group_IP__c = 'High Speed',
                Ownership_Type__c = 'Owned',
                SVMXC__Product__c = prod.Id,
                SVMXC__Site__c = locationId,
                SVMXC__Company__c = acctId,
                RecordTypeId = rtid
            );
            installedProds.add(ip);
        }
        return installedProds;
    }
    /** This method returns a list of Service Teams
     * @param count - Integer: The number of service teams to be returned.
     * @param superCenter - String: The supercenter the service team(s) will be assigned to.
     * @param segment - The segment within the supercenter.
     * @return - List<SVMXC__Service_Group__c>
     */
    public static List<SVMXC__Service_Group__c> getServiceTeams(Integer count, String superCenter, String segment){
        List<SVMXC__Service_Group__c> serviceTeams = new List<SVMXC__Service_Group__c>();
        for(Integer i = 0; i < count; i++){
            SVMXC__Service_Group__c st = new SVMXC__Service_Group__c(
                Name = 'TestServiceTeam_' + i,
                Super_Center__c = superCenter,
                Segment__c = segment,
                SVMXC__Active__c = true,
                SVMXC__Group_Type__c = 'Internal',
                SVMXC__Description__c = 'Test Service Team for ' + superCenter
            );
            serviceTeams.add(st);
        }
        return serviceTeams;
    }
    /** This method sets the key value store custom setting
     */
    public static void setKeyValueStore(){
        List<Key_Value_Store__c> values = new List<Key_Value_Store__c>();
        Key_Value_Store__c kv1 = new Key_Value_Store__c(Name = 'Avatax Account ID', Value__c = '1100001003');
        Key_Value_Store__c kv2 = new Key_Value_Store__c(Name = 'Avatax License Key', Value__c = 'D479CEA824039A0B');
        Key_Value_Store__c kv3 = new Key_Value_Store__c(Name = 'Avatax URL', Value__c = 'https://avatax.avalara.net');
        Product2 prod = new Product2(
            Name = 'TestShopFee',
            ProductCode = 'TestShopFee',
            Make1__c = 'TestMake',
            Model__c = 'TestModel',
            Broad__c = 'Door',
            Group__c = 'High Speed',
            Type__c = 'Electrical',
            Family = 'Equipment',
            SVMXC__Product_Line__c = 'Parts',
            IsActive = true,
            Description = 'Installed Product Test Product',
            SVMXC__Product_Cost__c = 0.00,
            SVMXC__Inherit_Parent_Warranty__c = true,
            UNITY_Status__c = 'Active',
            UNITY_Product_Cost__c = 0,
            UNITY_Unit_Of_Measure__c = 'Each'
        );
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, 
            Product2Id = prod.Id,
            UnitPrice = 7.95, 
            IsActive = true
        );
        insert standardPrice;
        Key_Value_Store__c kv4 = new Key_Value_Store__c(Name = 'NMS Service Fees', Value__c = prod.Id);
        values.add(kv1);
        values.add(kv2);
        values.add(kv3);
        values.add(kv4);
        insert values;
    }
    /**This method returns a list of users.
     * @param count - Integer: The number of users to return.
     * @return - List<User>
     */
    public static List<User> getUsers(Integer count){
        List<User> users = new List<User>();
        for(Integer i = 0; i < count; i++){
            Integer rand = getRandomInt((i + 9000), 10000);
            User u = new User(
                FirstName = 'Test',
                LastName = 'User_' + rand,
                Email='test.user_' + rand + '@domain.com',
                Alias = 'tusr'+ rand, 
                username = 'test.user_' + rand + '@domain.com',
                CommunityNickname = 'tusr'+ rand,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                ProfileId = UserInfo.getProfileId(),
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                EmployeeNumber = String.valueOf(rand)
            );
            users.add(u);
        }
        return users;
    }
    /**Gets a random integer number between lower two numbers.
    * @param lower - Integer: The lower number (inclusive).
    * @param upper - Integer: The upper number (exclusive).
    * @return - Integer
    */
    public static Integer getRandomInt(Integer lower, Integer upper){
        return Math.round(Math.random() * (upper - lower)) + lower;
    }
    /**This method return a list of contacts.
    * @param count - Integer: The number of contacts to return.
    * @param aid - String: The account id for the contact.
    * @return - List<Contact>
    */
    public static List<Contact> getContacts(Integer count, String aid){
        List<Contact> contacts = new List<Contact>();
        for(Integer i = 0; i < count; i++){
            Contact contact = new Contact(
                FirstName = 'Test', 
                LastName = 'Contact_' + i, 
                Email = 'test.contact_' + i + '@domain.com',
                AccountId = aid
            );
            contacts.add(contact);
        }
        return contacts;
    }
    /**This method return list of leads.
    * @param count - Integer: The number of contacts to return.
    * @param recordType - String: The developer name for the record type to use. [FLEXX Leads,M&A Leads Record Type,Miner Corp Lead - Assigned,Miner Corp Leads,Miner National Leads,NMS Leads,Standard Leads]
    * @return - List<Lead>
    */
    public static List<Lead> getLeads(Integer count, String recordType){
        List<Lead> leads = new List<Lead>();
        String rtid = [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName = :recordType LIMIT 1].Id;
        for(Integer i = 0; i < count; i++){
            Lead l = new Lead(
            	FirstName = 'Test_' + String.valueOf(getRandomInt(222,555)),
                LastName = 'Lead_' + String.valueOf(getRandomInt(222,555)),
                Email = 'test.lead_' + String.valueOf(getRandomInt(222,555)) + '@domain.com',
                Phone = '210' + String.valueOf(getRandomInt(222,555)) + String.valueOf(getRandomInt(2222,5555)),
                Company = 'Test Lead #' + String.valueOf(getRandomInt(222222,555555)),
                Street = String.valueOf(getRandomInt(100,999)) + ' ' + String.valueOf(getRandomInt(10,99)) + ' Street',
                City = 'San Antonio',
                StateCode = 'TX',
                //State = 'TX',
                Country = 'US',
                PostalCode = String.valueOf(getRandomInt(10000,99999)),
                RecordTypeId = rtid
            );
            leads.add(l);
        }
        return leads;
    }
    
    public static Map<String,String> getProductAndPriceBookEntry(Integer count){
        Map<String,String> prodPBEMap = new Map<String,String>();
        List<Product2> prods = new List<Product2>();
        List<PricebookEntry> pbes = new List<PricebookEntry>();
        Id pricebookId = Test.getStandardPricebookId();
        for(Integer i = 0; i < count; i++){
            Integer rand = getRandomInt((i + 9000), 10000);
            Product2 prod = new Product2(
                Name = 'TestProduct_'+rand,
                ProductCode = 'Test-123456'+rand,
                Make1__c = 'TestMake',
                Model__c = 'TestModel',
                Broad__c = 'Door',
                Group__c = 'High Speed',
                Type__c = 'Electrical',
                Family = 'Equipment',
                SVMXC__Product_Line__c = 'Equipment',
                IsActive = true,
                Description = 'Installed Product Test Product',
                SVMXC__Product_Cost__c = 0.00,
                SVMXC__Inherit_Parent_Warranty__c = true,
                UNITY_Status__c = 'Active',
                UNITY_Product_Cost__c = 0,
                UNITY_Unit_Of_Measure__c = 'Each',
                UNITY_Is_Stockable__c = true
            );
            prods.add(prod);
        }
        insert prods;
        for(Product2 p :prods){
            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = pricebookId, 
                Product2Id = p.Id,
                UnitPrice = 100, 
                IsActive = true
            );
            pbes.add(pbe);
        }
        insert pbes;
        for(PricebookEntry pbe :pbes){
            prodPBEMap.put(pbe.Product2Id,pbe.Id);
        }
        return prodPBEMap;
    }
    public static Map<String,String> getProductAndPriceBookEntry(Integer count,String type){
        Map<String,String> prodPBEMap = new Map<String,String>();
        List<Product2> prods = new List<Product2>();
        List<PricebookEntry> pbes = new List<PricebookEntry>();
        Id pricebookId = Test.getStandardPricebookId();
        for(Integer i = 0; i < count; i++){
            Integer rand = getRandomInt((i + 9000), 10000);
            Product2 prod = new Product2(
                Name = 'TestProduct_'+rand,
                ProductCode = ((type =='Labor')?'Miner-Labor':'Test-123456'+rand),
                Make1__c = 'TestMake',
                Model__c = 'TestModel',
                Broad__c = 'Door',
                Group__c = 'High Speed',
                Type__c = 'Electrical',
                Family = 'Equipment',
                SVMXC__Product_Line__c = 'Equipment',
                IsActive = true,
                Description = 'Installed Product Test Product',
                SVMXC__Product_Cost__c = 0.00,
                SVMXC__Inherit_Parent_Warranty__c = true,
                UNITY_Status__c = 'Active',
                UNITY_Product_Cost__c = 0,
                UNITY_Unit_Of_Measure__c = 'Each',
                UNITY_Product_Type__c = type,
                UNITY_Is_Stockable__c = (type == 'Part')
            );
            prods.add(prod);
        }
        insert prods;
        for(Product2 p :prods){
            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = pricebookId, 
                Product2Id = p.Id,
                UnitPrice = 100, 
                IsActive = true
            );
            pbes.add(pbe);
        }
        insert pbes;
        for(PricebookEntry pbe :pbes){
            prodPBEMap.put(pbe.Product2Id,pbe.Id);
        }
        return prodPBEMap;
    }
    public static Map<String,Map<Id,Id>> getProductAndPriceBookEntry(Integer count,String[] types){
        Map<String,Map<Id,Id>> prodPBEMap = new Map<String,Map<Id,Id>>();
        List<Product2> prods = new List<Product2>();
        List<PricebookEntry> pbes = new List<PricebookEntry>();
        Id pricebookId = Test.getStandardPricebookId();
        for(Integer i = 0; i < count; i++){
            for(Integer j = 0; j < types.size(); j++){
                Integer rand = getRandomInt((i + 9000), 10000);
                Product2 prod = new Product2(
                    Name = 'TestProduct_'+rand,
                    ProductCode = ((types[j]=='Labor')?'Miner-Labor':'Test-123456'+rand),
                    Make1__c = 'TestMake',
                    Model__c = 'TestModel',
                    Broad__c = 'Door',
                    Group__c = 'High Speed',
                    Type__c = 'Electrical',
                    Family = 'Equipment',
                    SVMXC__Product_Line__c = 'Equipment',
                    IsActive = true,
                    Description = 'Installed Product Test Product',
                    SVMXC__Product_Cost__c = 0.00,
                    SVMXC__Inherit_Parent_Warranty__c = true,
                    UNITY_Status__c = 'Active',
                    UNITY_Product_Cost__c = 0,
                    UNITY_Unit_Of_Measure__c = 'Each',
                    UNITY_Product_Type__c = types[j],
                    UNITY_Is_Stockable__c = (types[j] == 'Part')
                );
                prods.add(prod);
            }
        }
        insert prods;
        Set<Id> pids = new Set<Id>();
        for(Product2 p :prods){
            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = pricebookId, 
                Product2Id = p.Id,
                UnitPrice = 100, 
                IsActive = true
            );
            pbes.add(pbe);
            pids.add(p.Id);
        }
        insert pbes;
        pbes = [SELECT Id,Pricebook2Id,Product2Id,Product2.UNITY_Product_Type__c FROM PricebookEntry WHERE Product2Id IN :pids];
        for(PricebookEntry pbe :pbes){
            if(!prodPBEMap.containsKey(pbe.Product2.UNITY_Product_Type__c))
                prodPBEMap.put(pbe.Product2.UNITY_Product_Type__c,new Map<Id,Id>());
            prodPBEMap.get(pbe.Product2.UNITY_Product_Type__c).put(pbe.Product2Id,pbe.Id);
        }
        
        return prodPBEMap;
    }
    public static void setEmailTemplate(String devName){
        EmailTemplate et = new EmailTemplate();
        et.isActive = true;
        et.Name = devName;
        et.DeveloperName = devName;
        et.TemplateType = 'text';
        et.FolderId = UserInfo.getUserId();
        insert et;
    }
    public static void setGLMatrix(){
        List<UNITY_GL_Matrix__c> glms = new List<UNITY_GL_Matrix__c>();
        UNITY_GL_Matrix__c glm1 = new UNITY_GL_Matrix__c(
        	UNITY_Activity_Type__c = 'Parts - Service and Remodel',
            UNITY_Line_Type__c = 'Parts',
            UNITY_Order_Type__c = 'Service',
            UNITY_Revenue_Account__c = '123456',
            UNITY_Cost_Account__c = '789456',
            UNITY_Tax_Account__c = '852963'
        );
        glms.add(glm1);
        UNITY_GL_Matrix__c glm2 = new UNITY_GL_Matrix__c(
        	UNITY_Activity_Type__c = 'Standard Labor',
            UNITY_Line_Type__c = 'Labor - Service',
            UNITY_Order_Type__c = 'Service',
            UNITY_Revenue_Account__c = '123456',
            UNITY_Cost_Account__c = '789456',
            UNITY_Tax_Account__c = '852963'
        );
        glms.add(glm2);
        UNITY_GL_Matrix__c glm3 = new UNITY_GL_Matrix__c(
        	UNITY_Activity_Type__c = 'Standard Travel',
            UNITY_Line_Type__c = 'Travel',
            UNITY_Order_Type__c = 'Service',
            UNITY_Revenue_Account__c = '123456',
            UNITY_Cost_Account__c = '789456',
            UNITY_Tax_Account__c = '852963'
        );
        glms.add(glm3);
        insert glms;
        List<UNITY_GL_Segment_Account__c> segs = new List<UNITY_GL_Segment_Account__c>();
        UNITY_GL_Segment_Account__c seg1 = new UNITY_GL_Segment_Account__c(
        	UNITY_Seg_Account_Number__c = '1234',
            UNITY_Segment__c = 'NSBS'
        );
        segs.add(seg1);
        UNITY_GL_Segment_Account__c seg2 = new UNITY_GL_Segment_Account__c(
        	UNITY_Seg_Account_Number__c = '3456',
            UNITY_Segment__c = 'MNS'
        );
        segs.add(seg2);
        insert segs;
        List<UNITY_GL_Sub_Account__c> glSubs = new List<UNITY_GL_Sub_Account__c>();
        UNITY_GL_Sub_Account__c sub1 = new UNITY_GL_Sub_Account__c(
        	UNITY_GL_Sub_Account_Number__c = '33',
            UNITY_Sub_Account__c = 'Service'
        );
        glSubs.add(sub1);
        UNITY_GL_Sub_Account__c sub2 = new UNITY_GL_Sub_Account__c(
        	UNITY_GL_Sub_Account_Number__c = '30',
            UNITY_Sub_Account__c = 'Project'
        );
        glSubs.add(sub2);
        UNITY_GL_Sub_Account__c sub3 = new UNITY_GL_Sub_Account__c(
        	UNITY_GL_Sub_Account_Number__c = '31',
            UNITY_Sub_Account__c = 'PM'
        );
        glSubs.add(sub3);
        insert glSubs;
    }
    //This methos creates Test Data for UNITY Test Code
    public static void unityTestSetup(){
        //Setup mulesoft connection
        UNITY_MuleSiteSettingUtilsTest.setUp();
        UNITY_Mule2Salesforce_MappingUtilsTest.setUp();
        UNITY_Mulesoft_Credentials__c mCreds = new UNITY_Mulesoft_Credentials__c(
            Name = 'Basic Authorization',
            Authorization_Header__c = 'Basic dXNlcjE6cGFzc3dvcmQx'
        );
        insert mCreds;
        UNITY_MuleHttpCalloutMockImp calloutMock = new UNITY_MuleHttpCalloutMockImp(false);
        calloutMock.supposedEndPoint = UNITY_MuleSiteSettingUtils.getEndPoint(UNITY_MuleSiteSettingUtils.VENDOR);
        Test.setMock(HttpCalloutMock.class, calloutMock);
        //Create BU Specific Team field Map
        UNITY_BU_Team_Field_Map__c nsbsTeamMap = new UNITY_BU_Team_Field_Map__c(
            Name = 'NSBS',
            UNITY_Field_API_Name__c = 'UNITY_Customer_Team__c'
        );
        Map<String,UNITY_General_Settings__c> generalSettings = UNITY_General_Settings__c.getAll();
        List<UNITY_General_Settings__c> gSettings =  new List<UNITY_General_Settings__c>();
        if(!generalSettings.KeySet().contains(UNITY_Constants.SERVICE_FEE_PRODUCT_TYPE_CS_KEY))
            gSettings.add(new UNITY_General_Settings__c(
                Name = UNITY_Constants.SERVICE_FEE_PRODUCT_TYPE_CS_KEY, 
                UNITY_Value__c = 'Vendor Service Fee', 
                UNITY_Description__c='Vendor Service Fee'
            ));
        if(!generalSettings.KeySet().contains(UNITY_Constants.PO_INVOICEABLE_STATUSES))
            gSettings.add(new UNITY_General_Settings__c(
                Name = UNITY_Constants.PO_INVOICEABLE_STATUSES, 
                UNITY_Value__c = 'Final', 
                UNITY_Description__c='PO INVOICEABLE STATUS'
            ));
        if(!gSettings.isEmpty()) 
            insert gSettings;
        insert nsbsTeamMap;
        //Create CTI value Maps
        //Create CTI Value Map (Abbreviations Map)
        List<UNITY_CTI_Values_Map__c> cvmList = new List<UNITY_CTI_Values_Map__c>();
        UNITY_CTI_Values_Map__c cvm = new UNITY_CTI_Values_Map__c();
        cvm.Name = 'Team 1';
        cvm.InContact_Value__c = 'TM1';
        cvmList.add(cvm);
        UNITY_CTI_Values_Map__c cvm2 = new UNITY_CTI_Values_Map__c();
        cvm2.Name = 'Tier 1';
        cvm2.InContact_Value__c = 'T1';
        cvmList.add(cvm2);
        insert cvmList;
        //Create CTI Skill Ids Map for MNS and NSBS
        List<CTI_Skill_Id_Map__c>  ctiSkillList = new List<CTI_Skill_Id_Map__c>();
        CTI_Skill_Id_Map__c ctiSkill = new CTI_Skill_Id_Map__c();
        ctiSkill.InContact_ID__c = '123456';
        ctiSkill.Name = 'NSBS-T1-TM1-Glass';
        CTI_Skill_Id_Map__c ctiSkill2 = new CTI_Skill_Id_Map__c();
        ctiSkill2.InContact_ID__c = '234567';
        ctiSkill2.Name = 'NSBS-T1-TM1';
        CTI_Skill_Id_Map__c ctiSkill3 = new CTI_Skill_Id_Map__c();
        ctiSkill3.InContact_ID__c = '345678';
        ctiSkill3.Name = 'NSBS-T1';
        CTI_Skill_Id_Map__c ctiSkill4 = new CTI_Skill_Id_Map__c();
        ctiSkill4.InContact_ID__c = '741258';
        ctiSkill4.Name = 'MNS-T1-TM1-Glass';
        CTI_Skill_Id_Map__c ctiSkill5 = new CTI_Skill_Id_Map__c();
        ctiSkill5.InContact_ID__c = '963258';
        ctiSkill5.Name = 'MNS-T1-TM1';
        CTI_Skill_Id_Map__c ctiSkill6 = new CTI_Skill_Id_Map__c();
        ctiSkill6.InContact_ID__c = '852147';
        ctiSkill6.Name = 'MNS-T1';
        CTI_Skill_Id_Map__c ctiSkill7 = new CTI_Skill_Id_Map__c();
        ctiSkill7.InContact_ID__c = '852369';
        ctiSkill7.Name = 'MNS-T1-TM1-VM';
        ctiSkillList.add(ctiSkill);ctiSkillList.add(ctiSkill2);ctiSkillList.add(ctiSkill3);
        ctiSkillList.add(ctiSkill4);ctiSkillList.add(ctiSkill5);ctiSkillList.add(ctiSkill6);ctiSkillList.add(ctiSkill7);
        insert ctiSkillList;
        FSO__Skill__c skill = new FSO__Skill__c(
            Name = 'Glass, Board up, Mirrors & Displays',
            FSO__Skill_Description__c = 'Glass, Glass Installation/Repair, Glass, Board up, Mirrors & Displays',
            UNITY_Skill_Broad__c = 'Glass',
            UNITY_Skill_Group__c =  'Glass Installation/Repair'
        );
        insert skill;
        //Setup custom setting with status map
        List<UNITY_Status_Fields_Update_Map__c> statMapList = new List<UNITY_Status_Fields_Update_Map__c>();
        statMapList.add(new UNITY_Status_Fields_Update_Map__c());
        statMapList[0].Name = 'TestPOSubmittedtoWO';
        statMapList[0].UNITY_Origin_Object__c = 'Order';
        statMapList[0].UNITY_Origin_Value__c = 'Submitted to Miner';
        statMapList[0].UNITY_Origin_Record_Type__c = 'UNITY_Usage_Request';
        statMapList[0].UNITY_Order__c = 1;
        statMapList[0].UNITY_Target_Object__c = 'WorkOrder';
        statMapList[0].UNITY_Target_Value__c = 'Parts Needed';
        statMapList[0].UNITY_Target_Record_Type__c = 'Service_Request';
        statMapList.add(new UNITY_Status_Fields_Update_Map__c());
        statMapList[1].Name = 'TestPOFinaltoWO';
        statMapList[1].UNITY_Origin_Object__c = 'Order';
        statMapList[1].UNITY_Origin_Value__c = 'Final';
        statMapList[1].UNITY_Origin_Record_Type__c = 'UNITY_Usage_Request';
        statMapList[1].UNITY_Order__c = 2;
        statMapList[1].UNITY_Target_Object__c = 'WorkOrder';
        statMapList[1].UNITY_Target_Value__c = 'Parts Order Complete';
        statMapList[1].UNITY_Target_Record_Type__c = 'Service_Request';
        insert statMapList;
        //Create Tax Code Associations
        ////Fetch the record types for tax code associations
        String exRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'Tax_Code_Associations__c' AND Name = 'Exception' LIMIT 1].Id;
        String sRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'Tax_Code_Associations__c' AND Name = 'Standard' LIMIT 1].Id;
        List<Tax_Code_Associations__c> tca = new List<Tax_Code_Associations__c>();
        //Tax rule based on segment (State)
        Tax_Code_Associations__c tc0 = new Tax_Code_Associations__c(
            Segment__c = 'TX',
            Order_Type__c = 'Service',
            Included_Line_Types__c = 'Parts;Vendor Services',
            Excluded_Line_Types__c = 'Labor',
            Included_Activity_Types__c = 'Parts - New Construction; Parts - Service and Remodel',
            Excluded_Activity_Types__c = 'Standard Labor; Overtime Labor',
            RecordTypeId = exRTId
        );
        tca.add(tc0);
        //Tax rule based on segment (State)
        Tax_Code_Associations__c tc1 = new Tax_Code_Associations__c(
            Segment__c = 'TX',
            Order_Type__c = 'Service',
            Line_Type__c = 'Parts',
            Activity_Type__c = 'Parts - Service and Remodel',
            Tax_Code__c = 'seg-rule1',
            RecordTypeId = sRTId
        );
        tca.add(tc1);
        Tax_Code_Associations__c tc2 = new Tax_Code_Associations__c(
            Segment__c = 'TX',
            Order_Type__c = 'Service',
            Activity_Type__c = 'Parts - Construction',
            Tax_Code__c = 'seg-rule2'
        );
        tca.add(tc2);
        //Rules based on order type
        Tax_Code_Associations__c tc3 = new Tax_Code_Associations__c(
            Order_Type__c = 'Service',
            Line_Type__c = 'Labor',
            Activity_Type__c = 'Standard Labor',
            Tax_Code__c = 'ot-rule1'
        );
        tca.add(tc3);
        Tax_Code_Associations__c tc4 = new Tax_Code_Associations__c(
            Order_Type__c = 'Service',
            Activity_Type__c = 'Overtime Labor',
            Tax_Code__c = 'ot-rule2'
        );
        tca.add(tc4);
        //Rules based on line type
        Tax_Code_Associations__c tc5 = new Tax_Code_Associations__c(
            Line_Type__c = 'Expenses',
            Activity_Type__c = 'Use Tax',
            Tax_Code__c = 'lt-rule1'
        );
        tca.add(tc5);
        Tax_Code_Associations__c tc6 = new Tax_Code_Associations__c(
            Line_Type__c = 'Expenses',
            Activity_Type__c = 'Warranty',
            Tax_Code__c = 'lt-rule2'
        );
        tca.add(tc6);
        //Rules based on activity type
        Tax_Code_Associations__c tc7 = new Tax_Code_Associations__c(
            Activity_Type__c = 'Travel - Standard Labor',
            Tax_Code__c = 'at-rule1'
        );
        tca.add(tc7);
        Tax_Code_Associations__c tc8 = new Tax_Code_Associations__c(
            Activity_Type__c = 'Travel - Over Time Labor',
            Tax_Code__c = 'at-rule2'
        );
        tca.add(tc8);
        //Insert the tax code rules
        insert tca;
        Tax_Code_Exception__c ex1 = new Tax_Code_Exception__c(
            Tax_Code_Association__c = tc0.Id,
            Activity_Type__c = 'Parts - New Construction',
            Tax_Code__c = 'exempt'
        );
        insert ex1;
        //Setup Accounts
        List<Account> accts = new List<Account>();
        Account cust = TestDataProvider.getAccounts(1,'Customer', 'Customer')[0];cust.Account_Status__c = 'Active';
        cust.Account_Status__c = 'Active';
        cust.UNITY_Customer_Team__c = 'Team 1';
        cust.UNITY_MNS_Customer_Team__c = 'Team 1';
        cust.UNITY_Tier_Level__c = 'Tier 1';
        cust.UNITY_Customer_Size__c = 'Huge';
        Account vend = TestDataProvider.getAccounts(1,'Vendor','Vendor')[0];vend.UNITY_Vendor_Status__c = 'Active';
        Account bu = TestDataProvider.getAccounts(1,'Miner','Business Unit')[0];bu.UNITY_Business_Unit__c = 'NSBS';bu.UNITY_Company_Code__c = 'NSBS';bu.UNITY_Vendor_Status__c = 'Active';
        accts.add(cust);accts.add(vend);accts.add(bu);insert accts;
        //Setup Customer Contract
        List<UNITY_Service_Contract__c> contracts = new List<UNITY_Service_Contract__c>();
        UNITY_Service_Contract__c custContract = new UNITY_Service_Contract__c();
        custContract.UNITY_Account__c = cust.Id;
        custContract.UNITY_Trip_Charge__c = 10;
        custContract.UNITY_Trip_Charge_Type__c = 'Hourly Rate';
        custContract.UNITY_Default_Labor_Rate__c = 75;
        custContract.UNITY_Invoicing_Increments__c = 'Next ¼ hr';
        custContract.UNITY_Business_Unit__c = 'MNS;NSBS';
        custContract.UNITY_IS_Active__c = true;
        custContract.RecordTypeId = UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE;
        custContract.UNITY_2_Technicians__c = 1.25;
        custContract.UNITY_Multi_Technician__c = 1.25;
        custContract.UNITY_Apprentice__c = 1.25;
        custContract.UNITY_Holiday_Multiplier__c = 1.25;
        custContract.UNITY_OT_Multiplier__c = 1.25;
        custContract.UNITY_Holiday_Travel_Multiplier__c = 1.25;
        custContract.UNITY_OT_Travel_Multiplier__c = 1.25;
        //Setup Vendor Contract
        UNITY_Service_Contract__c vendorContract = new UNITY_Service_Contract__c();
        vendorContract.UNITY_Account__c = vend.Id;
        vendorContract.UNITY_Trip_Charge__c = 10;
        vendorContract.UNITY_Trip_Charge_Type__c = 'Hourly Rate';
        vendorContract.UNITY_Default_Labor_Rate__c = 75;
        vendorContract.UNITY_Invoicing_Increments__c = 'Next ¼ hr';
        vendorContract.UNITY_Business_Unit__c = 'MNS;NSBS';
        vendorContract.UNITY_IS_Active__c = true;
        vendorContract.RecordTypeId = UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE;
        vendorContract.UNITY_2_Technicians__c = 1.25;
        vendorContract.UNITY_Multi_Technician__c = 1.25;
        vendorContract.UNITY_Apprentice__c = 1.25;
        vendorContract.UNITY_Holiday_Multiplier__c = 1.25;
        vendorContract.UNITY_OT_Multiplier__c = 1.25;
        vendorContract.UNITY_Holiday_Travel_Multiplier__c = 1.25;
        vendorContract.UNITY_OT_Travel_Multiplier__c = 1.25;
        contracts.add(custContract);contracts.add(vendorContract);insert contracts;
        //Add SCLIs to the customer service contract
        List<UNITY_Service_Contract_Line_Item__c> sclis = new List<UNITY_Service_Contract_Line_Item__c>();
        UNITY_Service_Contract_Line_Item__c serviceCharge = new UNITY_Service_Contract_Line_Item__c(
            UNITY_Threshold_Start__c = .01,
            UNITY_Threshold_End__c = 500,
            UNITY_Service_Charge__c = 16,
            UNITY_Service_Charge_Amount__c = 60,
            UNITY_Service_Contract__c = custContract.Id,
            RecordTypeId = UNITY_Constants.SCLI_SERVICE_CHARGE_RECORDTYPE
        );
        sclis.add(serviceCharge);insert sclis;
        //Setup Avatax Credentials
        TestDataProvider.setKeyValueStore();
        //Setup GL Matrix Data
        TestDataProvider.setGLMatrix();
        User u = TestDataProvider.getUsers(1)[0];
        //Create Contact
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(1,cust.Id);
        List<Case> cases = UNITY_TestDataFactory.createCases(1,cust.Id,cust.Id,contacts.get(0).Id,UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        cases[0].UNITY_Business_Unit_Account__c = bu.Id;
        cases[0].UNITY_Business_Unit__c = 'NSBS';
        cases[0].UNITY_Customer_Service_Contract__c = custContract.Id;
        update cases;
    }
}