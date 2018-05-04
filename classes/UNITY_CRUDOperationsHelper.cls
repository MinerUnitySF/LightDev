/**
 *   @programer:    Rodrigo Birriel 
 *   @description: Wrapper class to handle update operation.
 *   @date:         02/15/2015
 */
global class UNITY_CRUDOperationsHelper {
    
    public static String STATUS_OK      = 'OK';
    public static String STATUS_FAIL    = 'FAIL';
    
    public static String MESSAGE_OK                 = '';
    public static String MESSAGE_REQUIRING_FIELDS   = 'Some fields are missing.';
    public static String MESSAGE_PANIC              = 'An unexpected error has ocurred';
    public static String MESSAGE_BODY_EMPTY         = 'The request body is empty';
    
    private static List<Map<String,String>> checkSanity(Blob requestBody, ResponseResult response) {
        
        List<Map<String,String>> result = NULL;
        if(requestBody != null) {
            System.debug('requestBody.toString()'+requestBody.toString());
            try {
                result = (List<Map<String,String>>)JSON.deserialize(requestBody.toString(), List<Map<String,String>>.class);
                System.debug('result --->'+result);
                response.isOk = true;
                response.status = STATUS_OK;
                response.message = MESSAGE_OK;
            } catch(Exception ex) {
                response.isOk = false;
                response.status = STATUS_FAIL;
                response.message = MESSAGE_PANIC;
            } 
        } else {
            response.isOk = false;
            response.status = STATUS_FAIL;
            response.message = MESSAGE_BODY_EMPTY;
        }
        
        return result;
    }
    
    public static ResponseResult upsertSOOperation(String sotypeName, String sourceType, Blob blobParams, String recordTypeId) {
        ResponseResult response = new ResponseResult();
        List<Map<String,String>> blobParamList = checkSanity(blobParams,response);
        Savepoint savepoint = Database.setSavepoint();
        if(response.isOk) {
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sotypeName);
            
            // keep two list for update and insert because generic list object only is supported for insert, update and delete.
            List<SObject> newSobjects = new List<SObject>();
            List<SObject> updateSobjects = new List<SObject>();
            try {
                System.debug('blobParamList --->'+blobParamList);
                for(Map <String, String> paramMap : blobParamList) {
                    SObject obj = targetType.newSObject();
                    obj.put('RecordTypeId', recordTypeId);
                    UNITY_Mule2SalesforceMappingUtils.populateSObject(sourceType, paramMap, obj);
                    if(obj.get('Id') != NULL) {
                        updateSobjects.add(obj);
                    } else {
                        newSobjects.add(obj);
                    }
                }
                System.debug('newSobjects --->'+newSobjects);
                System.debug('updateSobjects --->'+updateSobjects);                           
                
                if(!newSobjects.isEmpty()) {
                   List<Database.SaveResult> insertSaveResults = Database.insert(newSobjects, true);
                   System.debug('insertSaveResults --->'+insertSaveResults);
                }                           
                if(!updateSobjects.isEmpty()) {
                   List<Database.SaveResult> updateSaveResults = Database.update(updateSobjects, true);
                   System.debug('updateSaveResults --->'+updateSaveResults);
                }
                
                //String aId = obj.Id;
                // to avoid create dummy data on the org
                //Database.rollback(savepoint);
                
                response.isOk = true;
                response.status = STATUS_OK;
                response.message = MESSAGE_OK;
            } catch (Exception ex) {
                response.isOk = false;
                response.status = STATUS_FAIL;
                response.message = ex.getMessage();
                Database.rollback(savepoint);
            
            }
        }
        
       
        return response;
    }
    
    global class ResponseResult {
        public transient Boolean isOk;
        public String status;
        public String message;
        
        public ResponseResult() {
            
        }
    } 
    
}