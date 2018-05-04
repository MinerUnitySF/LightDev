/**
 *   @programer:    Rodrigo Birriel 
 *   @description:  Wrapper class to handle callout operation to mulesoft.
 *   @date:         02/15/2015
 */
public class UNITY_MuleCalloutOperation {
    
    private static Boolean insertOnceAvoidLoopWithFutures = false;
    public static String calledBy = '';
    
    private HttpRequest req;
    
    private UNITY_MuleCalloutOperation() {
        req = new HttpRequest();
        req.setMethod('POST');        
        
        // Specify the required user name and password to access the endpoint
        // As well as the header and header information
        String authorizationHeader = UNITY_Mulesoft_Credentials__c.getOrgDefaults().Authorization_Header__c;
        req.setHeader('Authorization', authorizationHeader == null?'asdf':authorizationHeader);
    }
    
    public static void invokeCallOut(List<Id> idList,String muleTypeName) {
        if(!idList.isEmpty() && 
           (!insertOnceAvoidLoopWithFutures && !(muleTypeName == UNITY_MuleCalloutOperation.calledBy))) {
               UNITY_MuleCalloutOperation.calledBy = muleTypeName;
               if(System.isBatch())
                   prepareCallOutAlt(idList,muleTypeName);
               else
               if(!System.isFuture() && !System.isBatch())
                   prepareCallOut(idList,muleTypeName);
           }
    }
    
    @Future(callout=true)
    private static void prepareCallOut(List<Id> idList,String muleTypeName) {
        UNITY_MuleCalloutOperation calloutOperation = new UNITY_MuleCalloutOperation();
      	calloutOperation.req.setEndpoint(UNITY_MuleSiteSettingUtils.getEndPoint(muleTypeName));
       	calloutOperation.req.setHeader('Host',UNITY_MuleSiteSettingUtils.getHost(muleTypeName));
        calloutOperation.req.setHeader('content-type', UNITY_MuleSiteSettingUtils.getContentType(muleTypeName));
       	calloutOperation.doUpdate(idList,muleTypeName);
    }

    public static void prepareCallOutAlt(List<Id> idList,String muleTypeName) {
        System.debug('###Izay: In Mulesoft callout: prepateCalloutAlt...');
        System.debug('###Izay: In Batch? ' + System.isBatch());
        System.debug('###Izay: idList = ' + JSON.serializePretty(idList));
        UNITY_MuleCalloutOperation calloutOperation = new UNITY_MuleCalloutOperation();
        calloutOperation.req.setEndpoint(UNITY_MuleSiteSettingUtils.getEndPoint(muleTypeName));
        calloutOperation.req.setHeader('Host',UNITY_MuleSiteSettingUtils.getHost(muleTypeName));
        calloutOperation.req.setHeader('content-type', UNITY_MuleSiteSettingUtils.getContentType(muleTypeName));
        calloutOperation.doUpdate(idList,muleTypeName);
    }

    private String serializeTo(Map<String,Object> muleObject, String typeName) {
        String muleObjectSerialized;
        if(UNITY_MuleSiteSettingUtils.isContentTypeJSON(typeName)) {
            muleObjectSerialized = serializeToJSON(muleObject);
        } else {
            muleObjectSerialized = serializeToXML(muleObject,typeName);
        }
        return muleObjectSerialized;
    }
    
    private String serializeToJSON(Map<String,Object> muleObject) {
        return JSON.serialize(muleObject);
    }
    /* NEW CASE COMMENT
     * <postXML>
      <StoreID>Minercorp</StoreID>
      <CustomerID>MCxml</CustomerID>
      <XMLMsg>&lt;DATA2SC PIN="65650" ID="12341234" >&lt;CALL TR_NUM="67365048" WO_NUM="WO-67365048">&lt;ATTR NAME="NOTE" LINE="3" DATETIME="02/03/2016 5:15:00 PM" CREATED_BY="BBEASLEY" NEW_SCHED_DATETIME="03/05/2016 7:00:00 AM" >Service rescheduled for next day due to transportation problems with vendor&lt;/ATTR> &lt;/CALL>&lt;/DATA2SC></XMLMsg>
	  </postXML>
     */ 
    /* CASE STATUS
     <postXML>
      <StoreID>Minercorp</StoreID>
      <CustomerID>MCxml</CustomerID>
      <XMLMsg>&lt;DATA2SC PIN="65650" ID="12341234" >&lt;CALL TR_NUM="67365048" WO_NUM="WO-67365048" COMPL_DATETIME="2016/02/04 19:04:23" STATUS="COMPLETED">&lt;RESOL>The vendor has fixed the problem&lt;/RESOL>&lt;/CALL>&lt;/DATA2SC></XMLMsg>
	</postXML>
	*/
    private String serializeToXML(Map<String,Object> muleObject,String typeName) {
        String StringReturn;
        // try to improve this
        System.debug('muleObject getting passed into serializeToXML: ');
        System.debug(muleObject);
        System.debug(typeName);
        System.debug('========');
        String storeID = '';
        String customerId ='';
        Map<String,Object> fieldMap;
        if(!muleObject.values().isEmpty()){
            fieldMap =  ( Map<String,Object>)muleObject.values().get(0); 
        }
        if(fieldMap != null && UNITY_Mule_Template__c.getAll().get(typeName) != null) {
        String muleTemplate = UNITY_Mule_Template__c.getAll().get(typeName).Template__c;
            if(muleTemplate != null) {
                System.debug('>>> fieldMap.keySet: '+fieldMap.keySet());

            	for(String key : fieldMap.keySet()) {
                    system.debug('This is a key we are on:');
                    //CLAY: Added this so that we can dynamically assign the StoreID and CustomerID.
                    //These are values pulled from the case that was originally created
                    //
                    if(key == 'StoreID'){
                        storeID = (String)fieldMap.get(key);
                    }else if (key == 'CustomerID'){
                        customerId = (String)fieldMap.get(key);
                    }else{
                       muleTemplate = muleTemplate.replaceAll('\\('+key+'\\)', (String)fieldMap.get(key));        
                    }
                    
                    System.debug(key);
                    System.debug((String)fieldMap.get(key));
        		}
                System.debug('===== CLAY: muleTemplate? ' + muleTemplate );
                DOM.Document body = new DOM.Document();
                String prefix = '';
                String nameSpace = '';
                
                DOM.XmlNode root = body.createRootElement('postXML', nameSpace, prefix);
                root.addChildElement('StoreID',nameSpace,prefix).addTextNode(storeID);
                root.addChildElement('CustomerID',nameSpace,prefix).addTextNode(customerId);
                root.addChildElement('XMLMsg',nameSpace,prefix).addTextNode(muleTemplate);
                
                StringReturn = body.toXmlString();
            } 
        }
        System.debug('========Clay: Finally we have our XML:' );
        System.debug(StringReturn);
        return  StringReturn;
    }
    
    // mulesoft api not support more than one record per call
    // workaround is as many post as records are.
    private void doUpdate(List<Id> idList, String typeName) {
        try {
            List<String> payloads = new List<String>();
            System.debug('(idList,typeName) ---> ('+idList+','+typeName+')');
            
            List<Map<String,Object>> muleObjects = UNITY_Mule2SalesforceMappingUtils.createMuleObjects(idList,typeName);
            
            System.debug('muleObjects --->'+muleObjects);
            
            Http http = new Http();
            
            List<SObject> objectsToUpdate = new List<SObject>();
            // Set the HTTPRequest body 
            // serialize the muleobject to json string
            for(Integer i=0; i<idList.size(); i++) {
                Map<String,Object> muleObject = muleObjects.get(i);
                String serializedMuleObject = '';
                HTTPResponse res;
                try{
                    try{
                        serializedMuleObject = serializeTo(muleObject,typeName);
                    }catch(Exception ex){
                        System.debug('Exception: --->'+ex.getMessage());
                        payloads.add('Error serializing payload: ' + muleObject + ' \n\n[Type] ' + typeName + '\n\n[Exception] ' + ex.getMessage());
                        continue;
                    }
                    System.debug('serializedMuleObject --->'+serializedMuleObject);
                    req.setBody(serializedMuleObject);
                    res = http.send(req);
                    //Helpful debug messages
                    System.debug('res.toString() --->'+res.toString());
                    System.debug('STATUS: -- >'+res.getStatus());
                    System.debug('STATUS_CODE: --->'+res.getStatusCode());
                    Map<String,Map<String,String>> response = new Map<String,Map<String,String>>();
                    
                    response = (Map<String,Map<String,String>>)JSON.deserialize( res.getBody() , Map<String,Map<String,String>>.class);
                    
                    // everything works fine
                    if(res.getStatusCode() == 200 && response.get('response') != null && response.get('response').get('error') == '') {
                        //in the response for vendor should come VendId but it comes VendorId
                        if(typeName == UNITY_Mule2SalesforceMappingUtils.MU_VENDOR) {
                            response.get('response').put('VendId',response.get('response').get('VendID'));
                        }
                        
                        Id currentId = idList.get(i);
                        if(currentId.getSobjectType() != null) {
                            system.debug(' >>> currentId :'+currentId);
                            // create a new instance from Id to update the fields on the response
                            SObject sobj = idList.get(i).getSObjectType().newSObject(currentId);
                            system.debug(' >>> response :'+response);
                            if(UNITY_Mule2SalesforceMappingUtils.populateSObject(typeName,response.get('response'),sobj)){
                                objectsToUpdate.add(sobj);
                            }
                        }
                    }
                }catch(Exception e){
                    System.debug('Exception: --->'+e.getMessage());
                    payloads.add('Payload: ' + serializedMuleObject + ' \n\n[Response] ' + res.getBody() + ' \n\n[Exception] ' + e.getMessage());
                    continue;
                }
            }
            if(payloads.size() > 0){
                List<Messaging.SingleEmailMessage> messagesList = new List<Messaging.SingleEmailMessage>();
                String htmlBody = '<p><strong>Mulesoft Callout Response Failure</strong></p>';
                for(String s :payloads){
                    htmlBody += '<span>======================================</span>';
                    htmlBody += '<p>' + s + '</p>';
                }
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setSubject('Mulesoft Callout (QA)');
                message.setHtmlBody(htmlBody);
                message.setToAddresses(new String[] {'izramos@minercorp.com','ctomerlin@minercorp.com','bbeasley@minercorp.com'});
                messagesList.add(message);
                //Messaging.sendEmail(messagesList);
            }
            if(!objectsToUpdate.isEmpty()){
                insertOnceAvoidLoopWithFutures = true;
                update objectsToUpdate;
            }
        } catch(System.CalloutException e) {
            System.debug('An callout exception has ocurred on'+e.getStackTraceString());
        } catch(System.Exception e) {
            System.debug('An internal error has occured on '+e.getStackTraceString());
        }
    }
    
    private class MuleResponse {
        
    }
    
}