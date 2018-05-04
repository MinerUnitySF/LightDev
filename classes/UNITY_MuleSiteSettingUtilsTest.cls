@isTest
public class UNITY_MuleSiteSettingUtilsTest {

    static String Name1     = 'Customer';
    static String Host1     = 'sl-customer-in.cloudhub.io';
    static String Domain1   = '/api/SlCustomer';
    static String Name2     = 'Invoice';
    static String Host2     = 'sl-invoiceandmemo-in.cloudhub.io';
    static String Domain2   = '/api/SlInvoiceAndMemo';
    static String Name3     = 'PurchaseOrder';
    static String Host3     = 'sl-purchaseorder-in.cloudhub.io';
    static String Domain3   = '/api/InPurchaseOrder';
    static String Name4     = 'Vendor';
    static String Host4     = 'sl-vendor-in.cloudhub.io';
    static String Domain4   = '/api/SlVendor';
    static String CTypeXML  = 'text/xml';
    static String CTypeJSON = 'application/json';
    
    static String ProtocolDefault = 'http';
    
    @testSetup public static void setUp() {
        
        if(UNITY_MuleSiteSetting__c.getAll().values().isEmpty()) {
            List<UNITY_MuleSiteSetting__c> muleSiteSettingList = new List<UNITY_MuleSiteSetting__c>();
        
            UNITY_MuleSiteSetting__c muleSiteSetting1 = new UNITY_MuleSiteSetting__c();
            muleSiteSetting1.Name = Name1;
            muleSiteSetting1.Host__c  = Host1;
            muleSiteSetting1.Domain__c  = Domain1;
            muleSiteSetting1.IsActive__c = true;
            muleSiteSetting1.Content_Type__c = CTypeXML;
            muleSiteSettingList.add(muleSiteSetting1);
            
            UNITY_MuleSiteSetting__c muleSiteSetting2 = new UNITY_MuleSiteSetting__c();
            muleSiteSetting2.Name = Name2;
            muleSiteSetting2.Host__c = Host2;
            muleSiteSetting2.Domain__c = Domain2;
            muleSiteSetting2.IsActive__c = false;
            muleSiteSetting2.Content_Type__c = CTypeXML;
            muleSiteSettingList.add(muleSiteSetting2);
            
            UNITY_MuleSiteSetting__c muleSiteSetting3 = new UNITY_MuleSiteSetting__c();
            muleSiteSetting3.Name = Name3;
            muleSiteSetting3.Host__c  = Host3;
            muleSiteSetting3.Domain__c  = Domain3;
            muleSiteSetting3.IsActive__c = true;
            muleSiteSetting3.Content_Type__c = CTypeJSON;
            muleSiteSettingList.add(muleSiteSetting3);
            
            UNITY_MuleSiteSetting__c muleSiteSetting4 = new UNITY_MuleSiteSetting__c();
            muleSiteSetting4.Name = Name4;
            muleSiteSetting4.Host__c = Host4;
            muleSiteSetting4.Domain__c = Domain4;
            muleSiteSetting4.IsActive__c = true;
            muleSiteSettingList.add(muleSiteSetting4);
            
            insert muleSiteSettingList;    
            
                   
            System.debug(' ---> SetUp : '+muleSiteSettingList);
        }
        
        if(UNITY_Mulesoft_Credentials__c.getAll().values() == null ) {
            UNITY_Mulesoft_Credentials__c credentials = new UNITY_Mulesoft_Credentials__c();
            credentials.Name = 'Basic';
            credentials.Authorization_Header__c = 'Basic 12345';
        
            insert credentials;   
        }

    }
    
    static testMethod void testFineValuesSuccess() {
        System.debug(' ---> allValues : '+UNITY_MuleSiteSetting__c.getAll().values());
        System.assertEquals(UNITY_MuleSiteSettingUtils.getHost(Name1), Host1);
        System.assert(UNITY_MuleSiteSettingUtils.isActive(Name1));
        System.assert(!UNITY_MuleSiteSettingUtils.isContentTypeJSON(Name1));
        System.assertEquals(UNITY_MuleSiteSettingUtils.getEndPoint(Name1), ProtocolDefault+'://'+Host1+Domain1);
        System.assertEquals(UNITY_MuleSiteSettingUtils.getHost(Name2), Host2);
        System.assert(!UNITY_MuleSiteSettingUtils.isActive(Name2));
        System.assert(UNITY_MuleSiteSettingUtils.getContentType(Name1) !=null);
        System.assert(UNITY_MuleSiteSettingUtils.getContentType(Name4) != null);
        System.assertEquals(UNITY_MuleSiteSettingUtils.getEndPoint(Name2), ProtocolDefault+'://'+Host2+Domain2);
        
    }
}