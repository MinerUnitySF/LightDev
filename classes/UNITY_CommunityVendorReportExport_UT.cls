@isTest
public class UNITY_CommunityVendorReportExport_UT {
	
    public static testMethod void testDoExport(){
        EmailTemplate validEmailTemplate = new EmailTemplate();
        validEmailTemplate.isActive = true;
        validEmailTemplate.Name = 'name';
        validEmailTemplate.DeveloperName = 'testTemplate';
        validEmailTemplate.TemplateType = 'text';
        validEmailTemplate.FolderId = UserInfo.getUserId();
        insert validEmailTemplate;
        
        UNITY_CommunityVendorReportExport.DoExport('testTemplate', 'noreport');
        
    }      
    
    
    private static void createuser(User runAsUser, Contact c, String username, String email){        
        
        system.runAs(runAsUser){
            Profile p = [select Id,name from Profile where UserType = 'PowerCustomerSuccess' limit 1];
            
            User user = new User();
            user.ProfileID = p.id;
            user.EmailEncodingKey = 'ISO-8859-1';
            user.LanguageLocaleKey = 'en_US';
            user.TimeZoneSidKey = 'America/New_York';
            user.LocaleSidKey = 'en_US';
            user.FirstName = 'first';
            user.LastName = 'last';
            user.Username = username;   
            user.Alias = 't1';
            user.Email = email;
            user.IsActive = true;
            user.ContactId = c.Id;
            insert user;
        }
    }

    public static testMethod void testGetAllContacts(){
        TestDataProvider.unityTestSetup();
        
        Account cust;
        Account vend;
        Account bu;
        
        String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
        String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;
        String usageRecRTId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
        String purchaseOrdRTId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;

        Test.startTest();
		User admin = TestDataProvider.getUser('Tim', 'System_Admin', 'System Administrator');
        
        //Get the accounts
        List<Account> accounts = [SELECT Id,RecordTypeId,Account_Email__c FROM Account];
        
        for(Account a :accounts){
            if(a.RecordTypeId == custRTId)
                cust = a;
            if(a.RecordTypeId == vendRTId)
                vend = a;
            if(a.RecordTypeId == buRTId)
                bu = a;
        }

		Contact c = new Contact();
        c.FirstName = 'Test';
        c.LastName = 'Test';
        c.Email='test@test.com';
        c.AccountId = vend.Id;
        insert c;
        
        createuser(admin, c, 'test1@dkfjlf.com.d1', 'test1@dkfjlf.com');

        Account acct = [SELECT Id, Account_Email__c, Name, (SELECT AccountId, Email FROM Contacts) FROM Account WHERE isCustomerPortal = true 
                        AND Id = :vend.Id];
       	List<String> contactList = UNITY_CommunityVendorReportExport.getContactEmails(acct);
        System.assert(contactList.size() > 0);
        
        Test.stopTest();
    
    }
}