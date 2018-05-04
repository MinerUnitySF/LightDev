global class CustomLookupController {
    
    global CustomLookupController(){
        
    }
    
    @RemoteAction
    global static List<SObject> doSearch(String s,String[] args){
        String query = '';
        String obj = args[0];
        String flds = args[1];
        String whr =  args[2];
        String lk = args[3];
        
        query += 'FIND \'' + String.valueOf(s) + '*\' IN ALL FIELDS RETURNING ' + String.valueOf(obj) + '(' + String.valueOf(flds);
        if(String.isNotBlank(whr))
            query += ' WHERE ' + whr;
        query += ')';
        
        List<SObject> resultSOSL = new List<SObject>();
        List<SObject> resultSOQL = new List<SObject>();
        Set<SObject> removeDupes = new Set<SObject>();
        List<SObject> finalList = new List<SObject>();
        
        System.debug('query: ' + query);
        List<List<SObject>> searchList = search.query(query);
        resultSOSL = searchList[0];
        removeDupes.addAll(resultSOSL);
        
        query = '';
        if(String.isNotBlank(lk)){
            query += 'SELECT ' + flds + ' FROM ' + obj + ' WHERE ';
            if(String.isNotBlank(whr))
            	query += ' ('+whr+') AND ';
            String lkStr = '(';
            String[] lkArr = lk.split(',');
            for(String lks :lkArr){
                lkStr += lks + ' LIKE \'%'+s+'%\' OR ';
            }
            lkStr = lkStr.trim();
            lkStr = lkStr.removeEndIgnoreCase('OR');
            query += lkStr + ')';
            
            System.debug('query: ' + query);
            resultSOQL = Database.query(query);
            
            if(!resultSOQL.isEmpty()){
                removeDupes.addAll(resultSOQL);
            }
        }
        
        finalList.addAll(removeDupes);
        
        return finalList;
    }
    
}