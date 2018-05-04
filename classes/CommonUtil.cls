public class CommonUtil {
    public static String fetchAllFields(String type){
        //String nameSpace;// = 'genesis';//Namespace_Prefix__c;
        //String newType = 'genesis__'+type;
        //if (nameSpace != null){
          //  newType = nameSpace+'__'+type;
        //}
        Schema.sObjectType sObjectType = Schema.getGlobalDescribe().get(type);           
        Map<String,Schema.SObjectField> fieldsMap = sObjectType.getDescribe().fields.getMap();
        String fields = '';
        for(String key : fieldsMap.keySet()) {
            fields = fields + key + ',';
        }
        if(fields.endsWith(',')){
            fields = fields.substring(0, fields.length() -1);
        }    
        return fields;
    }    
}