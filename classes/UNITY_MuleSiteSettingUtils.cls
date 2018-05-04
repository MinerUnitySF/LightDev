/**
 *   @programer:    Rodrigo Birriel 
 *   @description: Wrapper class to access the mule site setting.
 *   @date:         02/16/2015
 */
public class UNITY_MuleSiteSettingUtils {  
    
    public static String CUSTOMER       = 'Customer';
    public static String VENDOR         = 'Vendor';
    public static String INVOICE        = 'Invoice';
    public static String PURCHASE_ORDER = 'PurchaseOrder';
    public static String CASE1          = 'Case';
    public static String CASE_COMMENT   = 'CaseComment';
    
    public static String getEndPoint(String name) {
        String endPoint = 'temp';
        if(UNITY_MuleSiteSetting__c.getInstance(name) != null) {
            UNITY_MuleSiteSetting__c  siteSetting = UNITY_MuleSiteSetting__c.getInstance(name);
            endPoint = siteSetting.Protocol__c  + '://' + siteSetting.Host__c + siteSetting.Domain__c;
            System.debug('endPoint ---> '+endPoint);
        }
        return endPoint;
    }
    
    public static String getHost(String name) {
        System.debug('getHost ---> '+name);
        String host = 'temp';
        if(UNITY_MuleSiteSetting__c.getInstance(name) != null) {
            host = UNITY_MuleSiteSetting__c.getInstance(name).Host__c;  
        }
        return host;
    }
    
    public static String getContentType(String name) {
        String contentType = 'application/json';
        if(UNITY_MuleSiteSetting__c.getInstance(name) != null && UNITY_MuleSiteSetting__c.getInstance(name).Content_Type__c != null) {
            contentType = UNITY_MuleSiteSetting__c.getInstance(name).Content_Type__c;
        }
        return contentType;
    }
    
    public static Boolean isContentTypeJSON(String name) {
        return getContentType(name) == 'application/json';
    }
    
    public static Boolean isActive(String name) {
        return UNITY_MuleSiteSetting__c.getInstance(name) != null && UNITY_MuleSiteSetting__c.getInstance(name).IsActive__c;
    }      
        
}