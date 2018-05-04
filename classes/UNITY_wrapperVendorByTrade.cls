/*
*   @programer:    Samuel Astol
*   @description:  wrapper class for vendor by trade
*   @date:         12/09/2015             
*/
public class UNITY_wrapperVendorByTrade implements Comparable {
    
    public String name      {get;set;}
    public String id        {get;set;}
    public String phone     {get;set;}
    public String email     {get;set;}
    public id     dispatcherId {get;set;}
    public String tradeId   {get;set;}
    public String tradeName {get;set;}
    public String status {get;set;}
    public String tradePreference {get;set;}
    public String timeZoneName {get;set;}
    public String timeZoneId {get;set;}
    
    public list<integer> todayStart {get;set;}
    public list<integer> todayEnd   {get;set;}
    
    // this variable should depend of the record type selected 
    public Double score      {get;set;}
    public Double price      {get;set;}
    public String selectedRT {get;set;}
    public String contextAbbr {get;set;}
    public String contextName {get;set;}
    
    public Double ranking    {get;set;}
    
    public Boolean isMiner {get;set;}
    
    public Boolean isCustomerPreferred {get;set;}
    public Boolean isMinerPreferred    {get;set;}
    public Boolean isAssigned          {get;set;}
    public Boolean isCandidate         {get;set;}
    public Boolean isAccepted          {get;set;}
    public Boolean isRejected          {get;set;}
    public Boolean isRejectedNoResponse{get;set;}
    public Boolean isCandidateOffHours {get;set;}
    public Boolean isRejectedOther     {get;set;}
    public Boolean isCandidateBelowMargin {get;set;}
    public Boolean isOON {get;set;}
    public Boolean isAtCustomerLocation {get;set;}
    
    public Boolean willBeCandidateOffHours {get;set;}
    public Boolean willBeCandidateBelowMargin {get;set;}
    public Boolean canBeAssigned {get;set;}
    
    public DateTime lastModifiedDate   {get;set;} 
    public DateTime lastAssignedDate   {get;set;} 
    public String   userFormat_lastAssignedDate {get;set;} 
    public String   userFormat_lastModifiedDate {get;set;} 
    public String   summaryHours {get;set;} 

    public Map< String, double  > pricesByRecordType = new Map< String, double  >();
    public Map< String, double  > scoreByRecordType  = new Map< String, double  >();
    public Map< String, boolean > isRecordType       = new Map< String, boolean >();
    
    public String assignedStatus {get;set;}
    public String assignmentId   {get;set;}
    
    public UNITY_Vendor_Assignment__c assignment {get;set;}
    private Map< String, String > recordType_abbr = new Map<String,String>{'Preventative Maintenance'=>'PM','Project Management'=>'Project','Service Request'=>'SR','Site Survey'=>'SS'};
    private Map< String, String > abbr_RecordType = new Map<String,String>{'PM'=>'Preventative Maintenance','Project'=>'Project Management','SR'=>'Service Request','SS'=>'Site Survey'};
        
    // ** constructor ** //
    public UNITY_wrapperVendorByTrade(){
        
        ranking = 0;
        userFormat_lastAssignedDate = '';
        tradePreference = '';
        contextAbbr  = '';
        contextName  = '';
        
        isCandidate    = false;
        isAssigned     = false;
        isAccepted     = false;
        isRejected     = false;
        isRejectedNoResponse   = false;
        isRejectedOther        = false;
        isCandidateOffHours    = false;
        isCandidateBelowMargin = false;
        isCustomerPreferred    = false;
        isMinerPreferred       = false;
        canBeAssigned          = false;
        isAtCustomerLocation   = false;
        isOON   = false;
        
        willBeCandidateOffHours    = false;
        willBeCandidateBelowMargin  = false;
        
        for(String var :UNITY_Constants.WO_ABBR_RECORDTYPE.keySet()){
            pricesByRecordType.put(var, 0);
            scoreByRecordType.put(var, 0);
            isRecordType.put(var, false);
        }
        
        setStatus('');
    }
    
    public void setTimeZone(String timeZoneId){
        if(timeZoneId!=null){
            TimeZone tz = TimeZone.getTimeZone(timeZoneId);
            this.timeZoneName = tz.getDisplayName();
            this.timeZoneId   = timeZoneId;
        }
    }
    
     public void setTimeZone(String timeZoneId, String startS, String endS){
        this.setTimeZone(timeZoneId);
        this.setOperationalHours(startS, endS);
    }
    
    /*
    *   @programer:    Samuel Astol
    *   @description:  set vendor status status, and some context variables  
    *   @param :       <String> status ('Candidate', 'Assigned')
    */
    public void setStatus(String value){
        
        this.assignedStatus = value;
        
        if(value == UNITY_Constants.VENDOR_ASSIGNMENT_STATUS_CANDIDATE){
            this.isCandidate    = true;
        }else if(value == UNITY_Constants.VENDOR_ASSIGNMENT_STATUS_ASSIGNED){
            this.isAssigned  = true;
        }else if(value == UNITY_Constants.VENDOR_ASSIGNMENT_STATUS_ACCEPTED){
            this.isAccepted     = true;
        }else if(value == UNITY_Constants.VENDOR_ASSIGNMENT_STATUS_REJECTED){
            this.isRejected     = true;
        }else if(value == UNITY_Constants.VENDOR_ASSIGNMENT_STATUS_REJECTED_NO_RESPONSE){
            this.isRejectedNoResponse  = true;this.isRejected     = true;
        }else if(value == UNITY_Constants.VENDOR_ASSIGNMENT_STATUS_REJECTED_OTHER){
            this.isRejectedOther = true;this.isRejected     = true;
        }else if(value == UNITY_Constants.VENDOR_ASSIGNMENT_STATUS_CANDIDATE_OFF_HOURS){
            this.isCandidateOffHours = true;
        }else if(value == UNITY_Constants.VENDOR_ASSIGNMENT_STATUS_CANDIDATE_BELOW_MARGIN){
            this.isCandidateBelowMargin = true;
        }else {
            this.assignedStatus = '';
        }
        
    }
    
    /*
    *   @programer:    Samuel Astol
    *   @description:  set vendor context for record type
    *                  the method will set the score and price specific for that record type 
    *   @param :       <String> record type ('PM','Project','SR','SS')
    */
    public void setRTValues(String rt){
        
        this.price  = pricesByRecordType.get(rt);
        this.score  = scoreByRecordType.get(rt);
        this.selectedRT = rt;
        
    }
    
    public void context(String rt){
        if( UNITY_Constants.WO_ABBR_RECORDTYPE.get(rt) != null){
            this.price  = pricesByRecordType.get(rt);
            this.score  = scoreByRecordType.get(rt);
            this.contextName = abbr_recordType.get(rt);
            this.contextAbbr = rt;
        }        
    }
    
    public void context(String rt , double customerPrice , double marginPricePercent ){
        
        
        if( UNITY_Constants.WO_ABBR_RECORDTYPE.get(rt) != null){
            this.context(rt);
            if((customerPrice!=null) &&(marginPricePercent!=null)){
                double marginPrice = ((customerPrice*marginPricePercent)/100);
                this.willBeCandidateBelowMargin = !((customerPrice-marginPrice)>this.price);
            } 
        }        
    }
    
    public String getContext(){
        return this.contextName;
    }
    
    /*
    *   @programer:    Samuel Astol
    *   @description:  set the Assignment record related to the WO, vendor and customer
    *   @param :       <String> record type ('PM','Project','SR','SS')
    */
    public void setAssignment(UNITY_Vendor_Assignment__c assignment){
       this.assignment = assignment ;
       if(this.assignment != null){
            this.setStatus(this.assignment.Status__c);
            this.assignmentId = assignment.Id;
            this.setLastModifiedDate( assignment.LastModifiedDate );
            this.setLastAssignedDate( assignment.Last_Assigned__c  );
            this.isOON = assignment.OON__c;
            this.isAtCustomerLocation = !assignment.OON__c;
       }
    }
    
    /*
    *   @programer:    Samuel Astol
    *   @description:  set vendor available record types, 'true' = has record type assigned, 'false' has not record tye assigned
    *   @param :       <boolean> Preventative Maintenance
    *   @param :       <boolean> Project Management
    *   @param :       <boolean> Service Request
    *   @param :       <boolean> Site Survey
    */
    public void setIsRT(boolean pm ,boolean proj , boolean sr, boolean ss){
        isRecordType.put('PM', pm);
        isRecordType.put('Project', proj);
        isRecordType.put('SR', sr);
        isRecordType.put('SS', ss);
    }
    
    /*
    *   @programer:    Samuel Astol
    *   @description:  help method to check record type
    *   @param :       <string> record type
    */    
    public boolean isRT(String rt){
        return isRecordType.get(rt);
    }
    
    /*
    *   @programer:    Samuel Astol
    *   @description:  help method to get the price by record type
    *   @param :       <string> record type
    */
    public double getPrice(String rt){
        return pricesByRecordType.get(rt);
    }
    
    /*
    *   @programer:    Samuel Astol
    *   @description:  help method to get the score by record type
    *   @param :       <string> record type
    */    
    public double getScore(String rt){
        return scoreByRecordType.get(rt);
    }
    
    /*
    *   @programer:    Samuel Astol
    *   @description:  help method to know if the vendor is a candidate or it is assigned 
    */
    public boolean hasAssignment(){
        return (this.isAssigned  || 
               this.isCandidate || 
               this.isAccepted  || 
               this.isRejected  || 
               this.isRejectedNoResponse || 
               this.isRejectedOther      || 
               this.isCandidateOffHours  || 
               this.isCandidateBelowMargin);
    }
    
    /*
    *   @programer:    Samuel Astol
    *   @description:  help method to set the last Modified Date
    *   @param :       <DateTime> last Modified Date
    */
    public void setLastModifiedDate(DateTime datetimeString){
        lastModifiedDate = datetimeString;
        userFormat_lastModifiedDate ='' ;
        if(datetimeString!=null){
            lastModifiedDate = datetimeString;
            userFormat_lastModifiedDate = datetimeString.format();
        }
        
    }
    
    public void setLastAssignedDate(DateTime datetimeString){
        
        lastAssignedDate = datetimeString;
        userFormat_lastAssignedDate = '';
        
        if(datetimeString != null){
           lastAssignedDate = datetimeString;
            userFormat_lastAssignedDate = datetimeString.format(); 
        }
            
        
    }       
    
    
    
    /*
    *   @programer:    Samuel Astol
    *   @param :       <Object> object to compare 
    *   @description:  Implement the compareTo() method.
    *                  We need to be able to sort the vendors by diferent context 
    */
    public Integer compareTo(Object compareTo) {
        
        UNITY_wrapperVendorByTrade compareToW = (UNITY_wrapperVendorByTrade)compareTo;
        
        
        if(this.hasAssignment() && !compareToW.hasAssignment()){ 
            
           return -1;
            
        }else if( this.hasAssignment() && compareToW.hasAssignment() ){
            
            if(this.isAccepted && !compareToW.isAccepted){
                return -1;
            }else if(this.isAccepted && compareToW.isAccepted){
                if (this.lastAssignedDate  == compareToW.lastAssignedDate) return 0;
                if (this.lastAssignedDate  > compareToW.lastAssignedDate ) return -1;
            }
            
            if(this.isAssigned && !(compareToW.isAccepted || compareToW.isAssigned) ){
                return -1;
            }else if(this.isAssigned && compareToW.isAssigned){
                if (this.lastAssignedDate  == compareToW.lastAssignedDate) return 0;
                if (this.lastAssignedDate  > compareToW.lastAssignedDate ) return -1;
            }
            
            if(this.isCandidate && !(compareToW.isCandidate || compareToW.isAccepted || compareToW.isAssigned) ){
                return -1;
            }else if(this.isCandidate && compareToW.isCandidate){
                return UNITY_Vendor_Utils.compareByPreferredOrder(this,compareToW );
            }
            
            if(this.isRejected && !(compareToW.isCandidate || compareToW.isAccepted || compareToW.isAssigned || compareToW.isRejected) ){
                return -1;
            }else if(this.isRejected && compareToW.isRejected){
                return UNITY_Vendor_Utils.compareByPreferredOrder(this,compareToW );
            }
            
            if(this.isRejectedNoResponse && !(compareToW.isCandidate || compareToW.isAccepted || compareToW.isAssigned || compareToW.isRejected || compareToW.isRejectedNoResponse) ){
                return -1;
            }else if(isRejectedNoResponse && compareToW.isRejectedNoResponse){
                return UNITY_Vendor_Utils.compareByPreferredOrder(this,compareToW );
            }
            
            if(this.isRejectedOther && !(compareToW.isCandidate || compareToW.isAccepted || compareToW.isAssigned || compareToW.isRejected || compareToW.isRejectedNoResponse || compareToW.isRejectedOther) ){
                return -1;
            }else if(this.isRejectedOther && compareToW.isRejectedOther){
                return UNITY_Vendor_Utils.compareByPreferredOrder(this,compareToW );
            }
            
            if(this.isCandidateOffHours && !(compareToW.isRejectedOther || compareToW.isCandidate || compareToW.isAccepted || compareToW.isAssigned || compareToW.isRejected || compareToW.isRejectedNoResponse || compareToW.isRejectedOther) ){
                return -1;
            }else if(this.isCandidateOffHours && compareToW.isCandidateOffHours){
                return UNITY_Vendor_Utils.compareByPreferredOrder(this,compareToW );
            }
            
            if(this.isCandidateBelowMargin && !(compareToW.isCandidateOffHours || compareToW.isRejectedOther || compareToW.isCandidate || compareToW.isAccepted || compareToW.isAssigned || compareToW.isRejected || compareToW.isRejectedNoResponse || compareToW.isRejectedOther) ){
                return -1;
            }else if(this.isCandidateBelowMargin && compareToW.isCandidateBelowMargin){
                return UNITY_Vendor_Utils.compareByPreferredOrder(this,compareToW );
            }
             
            
        }else if( !this.hasAssignment() && !compareToW.hasAssignment() ){
            
             return UNITY_Vendor_Utils.compareByPreferredOrder(this,compareToW );
             
        }
        
        return 1;
          
    }
    
    public void setOperationalHours(String startS , String endS) {
        
        if(startS!=null){
             this.todayStart =  new list<integer>{Integer.valueOf(startS.split(':')[0]),Integer.valueOf(startS.split(':')[1])};
        }
            
        if(endS!=null){
             this.todayEnd   =  new list<integer>{Integer.valueOf(endS.split(':')[0]),Integer.valueOf(endS.split(':')[1])};
        }
        this.setWillBeCandidateOffHours();        
    }
    
    public void setWillBeCandidateOffHours() {
        
        dateTime myDateTime = dateTime.now();
        
        UNITY_Utils.DateTimeZone dtz = UNITY_Utils.getDateTime(myDateTime,null, this.timeZoneId);
            
        list<integer> currentTimeZone = new list<integer>{dtz.HH,dtz.MM};
            
        if( (this.todayEnd!=null) && (this.todayStart!=null)){
            this.willBeCandidateOffHours = !UNITY_Vendor_Utils.checkOperationHours(this.todayStart,this.todayEnd,currentTimeZone);
        }else{
            this.willBeCandidateOffHours = true;
        }
    }

}