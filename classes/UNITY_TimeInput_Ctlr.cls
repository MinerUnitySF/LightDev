/**UNITY_WOTimeInput_Ctlr
 * @description: This class serves as controller for custom date/time input vfPage
 * @programer:   Izay Ramos-Irizarry
 * @date:        3/23/2016
 * @version:     1.0
 */
public with sharing class UNITY_TimeInput_Ctlr{
    
    public ApexPages.StandardController controller;//The standard controller for the page
    public string acctTimeZone {get; private set;}//The account time zone name
    public string localTimeZone {get; private set;}//The local time zone name
    public String recId {get; private set;}
    //Field name in the object that holds the account TimeZoneSidKey value. This field is required.
    public static final String TIMEZONE_FIELD_NAME = 'unity_account_time_zone__c';
    public boolean hasError {get; private set;}
    public boolean showBtns {get; private set;}
    
    /**This is the constructor for the extension 
     *@param c :ApexPages.StandardController
     */
    public UNITY_TimeInput_Ctlr(ApexPages.StandardController c){
        this.controller = c;
        SObject s = c.getRecord();
        this.recId = (String)s.get('Id');
        this.hasError = false;
        this.showBtns = false;
        if(s.get(TIMEZONE_FIELD_NAME) != null){
            String atz = String.valueOf(s.get(TIMEZONE_FIELD_NAME));
            TimeZone acctTZ = TimeZone.getTimeZone(atz);
            this.acctTimeZone = acctTZ.getDisplayName();
        }else{
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Account Time Zone not set. Please set the Account Time Zone and refresh this page.'));
            this.hasError = true;
        }
        TimeZone localtz = UserInfo.getTimeZone();
        this.localTimeZone = localTZ.getDisplayName();
        String errorMessage = Apexpages.currentpage().getparameters().get('errMessage');
        if(String.isNotBlank(errorMessage)){
            this.showBtns = true;
            errorMessage = System.EncodingUtil.urlDecode(errorMessage, 'UTF-8');
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
        }
    }
    /**This method saves the record when the Save button is clicked.
     *@return null
     */
    public PageReference saveRecord(){
        try{
            PageReference pr = this.controller.save();
            
        }
        catch(Exception e){
            String pageMessage = e.getMessage();
            pageMessage = System.EncodingUtil.urlDecode(pageMessage, 'UTF-8');
            String url = ApexPages.currentPage().getUrl();
            url = url.substring(0, url.indexOf('?'));
            PageReference pr = new PageReference(url);
            pr.setredirect(true);
            pr.getParameters().put('errMessage',pageMessage);
            pr.getParameters().put('id',this.recId);
            return pr;
        }
        if(ApexPages.hasMessages()){
            String pageMessage = ApexPages.getMessages()[0].getSummary();
            pageMessage = System.EncodingUtil.urlDecode(pageMessage, 'UTF-8');
            String url = ApexPages.currentPage().getUrl();
            url = url.substring(0, (url.indexOf('?') + 1));
            System.debug('##### url: ' + url);
            PageReference pr = new PageReference(url);
            pr.setredirect(true);
            pr.getParameters().put('errMessage',pageMessage);
            pr.getParameters().put('id',this.recId);
            return pr;
        }
        return null;
    }
    /**This method saves the record when the Cancel button is clicked.
     *@return null
     */
    public PageReference cancelChange(){
        return null;
    }
    
    /**This method verifies changes to mapped fields in given records and updates as needed
     *@return List<SObject>
     */
    public static List<SObject> verifyDateTimeChanged(List<SObject> records, Map<Id,SObject> oldMap, String obj, Boolean isTrigger){
        //Get the custom setting mapping values
        Map<String,UNITY_Date_Time_Field_to_Local__c> fieldsMap = UNITY_Date_Time_Field_to_Local__c.getAll();
        //Order the mapped field by Object type
        Map<String,List<UNITY_Date_Time_Field_to_Local__c>> objFieldsMap = new Map<String,List<UNITY_Date_Time_Field_to_Local__c>>();
        for(UNITY_Date_Time_Field_to_Local__c f :fieldsMap.values()){
            if(!objFieldsMap.containsKey(f.UNITY_Object__c)){
                List<UNITY_Date_Time_Field_to_Local__c> temp = new List<UNITY_Date_Time_Field_to_Local__c>();
                temp.add(f);
                objFieldsMap.put(f.UNITY_Object__c,temp);
            }else{
                objFieldsMap.get(f.UNITY_Object__c).add(f);
            }
        }//End of for date time fields to local mapping
        //Now check if there is any mapping for the obj
        if(objFieldsMap.containsKey(obj)){
            //Need to get the object describe to make sure that the given fields are available in the object
            List<String> objType = new List<String>();
            objType.add(obj);
            Set<String> objectFields = Schema.describeSObjects(objType)[0].fields.getMap().keySet();
            //System.debug('###### objFields: ' + objectFields);
            Integer fCount = 0;
            for(SObject o :records){
                //Set to collect updated target fields, that way if the field was updated in the code, it will not catch it as an update by the trigger
                Set<String> updatedTargets = new Set<String>();//Hold the name of updated fields
                String custTZSidKey = '';//The time zone sid key to convert to
                //Check if the object has an account time zone field
                System.debug('###### contains unity_account_time_zone__c: ' + objectFields.contains(TIMEZONE_FIELD_NAME));
                if(objectFields.contains(TIMEZONE_FIELD_NAME)){
                    custTZSidKey = String.valueOf(o.get(TIMEZONE_FIELD_NAME));
                }
                //Clay - Added a check for whether or not it's daylight savings time. Doesn't check for null tho! 
                //This lives in a hierarchy setting that should only have a setting for default
                Boolean dst = UNITY_daylight_savings__c.getInstance().NA_Daylight_Savings__c;
                System.debug('//Clay - Is it daylight savings? ' + dst);

                //If an account timezone is found...
                if(String.isNotBlank(custTZSidKey)){
                    for(UNITY_Date_Time_Field_to_Local__c f :objFieldsMap.get(obj)){
                        if(objectFields.contains(f.UNITY_Origin_Field__c.toLowerCase()) && 
                           objectFields.contains(f.UNITY_Target_Field__c.toLowerCase()) &&
                           !updatedTargets.contains(f.UNITY_Origin_Field__c) //is this wrong?
                          ){
                            //Need to verify if the field was updated
                            String myVal = String.valueOf(o.get(f.UNITY_Origin_Field__c.toLowerCase()));//Get the current record value
                            String myOldVal = '';

                            
                            //If in a trigger
                            if(isTrigger){
                                //If the trigger is update... need to check for changes
                                if(Trigger.isUpdate){
                                    myOldVal = String.valueOf(oldMap.get((Id)o.get('Id')).get(f.UNITY_Origin_Field__c.toLowerCase()));
                                    System.debug('###### origin field: ' + f.UNITY_Origin_Field__c.toLowerCase());
                                    System.debug('###### myVal: ' + myVal);
                                    System.debug('###### myOldVal: ' + myOldVal);                                    
                                    //If the values changed
                                    if((myVal != myOldVal)){
                                        if(String.isNotBlank(myVal)){
                                            //START inContact workorder check in/out assist
                                            //Clay: Needed a way to convert incontact time stamp (gmt) to actual customer timezone BEFORE converting from customer time zone to local user
                                            //This should always occur during an update context on a work order, and only in two origin fields. We will have to take into account daylight savings
                                            if(obj == 'WorkOrder' && o.get('UNITY_Check_In_Source__c')== 'inContact' || obj == 'WorkOrder' && o.get('UNITY_Check_Out_Source__c')== 'inContact'){
                                                //CLAY:
                                                //if we are a work order object AND the source is incontact
                                                if(((f.UNITY_Origin_Field__c.toLowerCase() == 'unity_check_in_date_cust__c') 
                                                || (f.UNITY_Origin_Field__c.toLowerCase() == 'unity_check_out_date_cust__c')) && o.get(f.UNITY_Target_Field__c) == null ){
                                                    //System.debug('//Clay - This is where we will override the origin field?');
                                                    DateTime ivrCheck = DateTime.parse(myVal);
                                                    System.Debug('//Clay: ivrCheck RAW = ' + ivrCheck);
                                                    //Clay - if daylight savings is true, remove one hour to the origin field assuming all of the account time zone are STANDARD time
                                                    if(dst){
                                                        ivrCheck = ivrCheck.addHours(-1);
                                                        System.Debug('//Clay: ivrCheck after DST = ' + ivrCheck);
                                                    }
                                                    myVal = ivrCheck.format('M/d/yyyy h:mm aaa',custTZSidKey);

                                                    //myVal = ivrCheck.format('M/d/yyyy h:mm aaa');
                                                    System.debug('//Clay - override of origin field has occurred for inContact. ivrCheck = ' + ivrCheck + ' | myval = '+ myVal);
                                                    o.put(f.UNITY_Origin_Field__c, myVal);
                                                    o.put(f.UNITY_Target_Field__c, ivrCheck);
                                                    //updatedTargets.add(f.UNITY_Origin_Field__c);
                                                }
                                                    
                                            }else if (f.UNITY_To_Date_Time__c == false){ //if not convert date time is TRUE
                                                //get the origin as datetime
                                                DateTime myDate = (DateTime)o.get(f.UNITY_Origin_Field__c);
                                                //Call the convertDateTime method passing the DateTime and Customer timeZone
                                                String convString = convertDateTime(myDate,custTZSidKey);
                                                o.put(f.UNITY_Target_Field__c, convString);
                                            }else{
                                                DateTime convDate = convertDateTime(myVal,custTZSidKey);                                                
                                                o.put(f.UNITY_Target_Field__c, convDate);
                                                System.debug('//Clay - put the date into our target field :' + f.UNITY_Target_Field__c);
                                                System.debug('//Clay - value put into o :' + o.get(f.UNITY_Target_Field__c));
                                            }

                                            updatedTargets.add(f.UNITY_Target_Field__c);
                                            fCount ++;
                                        }else{ //if myVal is BLANK
                                            //this allows for clearing the target field - deleting the value
                                            o.put(f.UNITY_Target_Field__c, null);
                                        }
                                    }//End of myVal not myOldVal
                                }else if(Trigger.isInsert){
                                    if(String.isNotBlank(myVal)){
                                        //If not converting to Date
                                        if(f.UNITY_To_Date_Time__c == false){
                                            //get the origin as datetime
                                            DateTime myDate = (DateTime)o.get(f.UNITY_Origin_Field__c);
                                            //Call the convertDateTime method passing the DateTime and Customer timeZone
                                            if(myDate != null){
                                                String convString = convertDateTime(myDate,custTZSidKey);
                                                o.put(f.UNITY_Target_Field__c, convString);
                                            }
                                        }else{
                                            DateTime convDate = convertDateTime(myVal,custTZSidKey);
                                            o.put(f.UNITY_Target_Field__c, convDate);
                                        }
                                        updatedTargets.add(f.UNITY_Target_Field__c);
                                    }
                                }
                                if(fCount > 1){
                                    //Trigger.new[0].addError('Update one date/time field at a time.');
                                }
                            /*********************************
                            ** If NOT called from a trigger **
                            ******************************** */
                            }else{
                                //If the oldMap is NOT null...
                                if(oldMap != null){
                                    //If the oldMap contains the current record id...
                                    if(oldMap.containsKey((Id)o.get('Id'))){
                                        //Treat the call as an update above
                                        myOldVal = String.valueOf(oldMap.get((Id)o.get('Id')).get(f.UNITY_Origin_Field__c.toLowerCase()));
                                        System.debug('###### myVal: ' + myVal);
                                        System.debug('###### myOldVal: ' + myOldVal);
                                        //If the values changed
                                        if((myVal != myOldVal)){
                                            if(String.isNotBlank(myVal)){
                                                //If not converting to Date
                                                if(f.UNITY_To_Date_Time__c == false){
                                                    //get the origin as datetime
                                                    DateTime myDate = (DateTime)o.get(f.UNITY_Origin_Field__c);
                                                    //Call the convertDateTime method passing the DateTime and Customer timeZone
                                                    String convString = convertDateTime(myDate,custTZSidKey);
                                                    o.put(f.UNITY_Target_Field__c, convString);
                                                }else{
                                                    DateTime convDate = convertDateTime(myVal,custTZSidKey);
                                                    o.put(f.UNITY_Target_Field__c, convDate);
                                                }
                                                updatedTargets.add(f.UNITY_Target_Field__c);
                                            }else{
                                                o.put(f.UNITY_Target_Field__c, null);
                                            }
                                        }//End of myVal not myOldVal
                                    }//End of if in oldMap
                                }//End of oldMap != null
                            }//End if in trigger
                        }//End if object contains origin target
                    }//end for map
                }//End of if custTZSidKey
            }//For each record
        }//If the object has a mapping
        return records;
    }
    /**This method converts a given DateTime from local time zone 
     * to the given time zone and returns the String value
     *@param dt - DateTime: The DateTime to convert
     *@param tz - String: The TimeZoneSidKey to convert to
     *@return String - The converted time formatted in '12/31/2016 3:15 PM'
     */
    public static String convertDateTime(DateTime dt, String tz){
        System.debug('###### Converting Date to String: ...');
        System.debug('###### Date: ' + dt);
        System.debug('###### to Time Zone: ' + tz);
        String converted = '';
        if(dt != null && String.isNotBlank(tz)){
            converted = dt.format('M/d/yyyy h:mm aaa',tz);
            System.debug('###### converted: ' + converted);
        }
        return converted;
    }
    /**This method converts a given String from given time zone 
     * to the local DateTime
     *@param dt - String: The DateTime to convert to local time
     *@param tz - String: The TimeZoneSidKey to convert from
     *@return DateTime - The converted DateTime in the user locat time zone
     */
    public static DateTime convertDateTime(String dt, String tz){
        System.debug('###### Converting String to Date: ...');
        System.debug('###### Date: ' + dt);
        System.debug('###### from Time Zone: ' + tz);
        //CLAY: Need to revist matcher - as of right now it is not matching anything.
        //Need to make sure that the date formatting is correct here...
        //String regEx = '/^(0[1-9]|1[012])[- /.](0[1-9]|[12][0-9]|3[01])[- /.]((?:19|20)\\d\\d)$/' + '((([1])([0-2])|(([0])([1-9])))(\\u003A)(([0-5])([0-9]))(\\s)(([AP])([M])))';
        ////String scRegEx = '([0-9]{4})[/]([0-9]{2})[/]([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})';
        //Pattern myPttrn = Pattern.compile(regEx);
        //Matcher m = myPttrn.matcher(dt);
        //System.debug('CLAY: did we match regEx? ' + m.matches());
        //if(!m.matches()){
        //    //Do something here!!!
        //    //CLAY: Matching for service channel
        //    //We have to change the string that gets converted in the parser
        //    //myPttrn = Pattern.compile(scRegEx);
        //    //m = myPttrn.matcher(dt);
        //    //System.debug('CLAY: did we match ScRegEx? ' + m.matches());
        //    //Integer ihr = integer.valueOf(m.group(4));
        //    //String hr = (ihr > 12) ? (ihr - 12) + '' : ihr + '';
        //    //String hrAP = (ihr > 12) ? ' PM' : ' AM'; 
        //    //String dt2 = m.group(2) + '/' + m.group(3) + '/' + m.group(1) + ' ' + hr +':'+m.group(5)+hrAP; 
        //    //dt = dt2;
        //    //System.debug(dt2);
        //    //if(!m.matches()){//if we didnt find another match
        //    //}
        //}
        DateTime converted;
        if(String.isNotBlank(dt) && String.isNotBlank(tz)){
            DateTime localDate = DateTime.parse(dt);
            dateTime gmtdate = DateTime.newInstanceGmt(localDate.date(),localDate.time());
            System.debug('###### converted before: ' + gmtdate);
            TimeZone tzone = TimeZone.getTimeZone(tz);
            TimeZone usrTZone = UserInfo.getTimeZone();
            Integer tzOffset = tzone.getOffset(gmtdate);
            Integer usrOffset = usrTZone.getOffset(gmtdate);
            System.debug('###### tzOffset: ' + tzOffset);
            System.debug('###### usrOffset: ' + usrOffset);
            
            if(tzOffset <> usrOffset){
                converted = gmtdate.addSeconds((tzOffset/1000)*-1);
                System.debug('###### Added seconds: ' + (tzOffset/1000)*-1);
            }else{
                converted = localDate;
            }
            System.debug('###### converted after: ' + converted);
        }
            
        return converted;
    }


    /**This method converts a given String from given time zone specifically for SERVICE CHANNEL
     * 
     */
    public static DateTime convertDateTime(String dt, String tz, String type){
        DateTime converted;
        if (type == 'Service Channel'){

            System.debug('###### Converting String to Date: ...');
            System.debug('###### Date: ' + dt);
            System.debug('###### from Time Zone: ' + tz);
            //Need to make sure that the date formatting is correct here...
            //String regEx = '/^(0[1-9]|1[012])[- /.](0[1-9]|[12][0-9]|3[01])[- /.]((?:19|20)\\d\\d)$/' + '((([1])([0-2])|(([0])([1-9])))(\\u003A)(([0-5])([0-9]))(\\s)(([AP])([M])))';
            String scRegEx = '([0-9]{4})[/]([0-9]{2})[/]([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})';
            Pattern myPttrn = Pattern.compile(scRegEx);
            Matcher m = myPttrn.matcher(dt);
            //System.debug('CLAY: did we match regEx? ' + m.matches());            
            //CLAY: Matching for service channel
            //We have to change the string that gets converted in the parser
            System.debug('CLAY: did we match ScRegEx? ' + m.matches());
            if(m.matches()){
                Integer ihr = integer.valueOf(m.group(4));
                String hr = (ihr > 12) ? (ihr - 12) + '' : ihr + '';
                //CLAY: added to cover for midnight check ins. Wasnt working!
                hr = (hr == '0') ? '12' : hr;
                String hrAP = (ihr >= 12) ? ' PM' : ' AM'; 
                String dt2 = m.group(2) + '/' + m.group(3) + '/' + m.group(1) + ' ' + hr +':'+m.group(5)+hrAP; 
                dt = dt2;
                System.debug(dt2);
                DateTime localDate = DateTime.parse(dt);
                dateTime gmtdate = DateTime.newInstanceGmt(localDate.date(),localDate.time());
                System.debug('###### converted before: ' + gmtdate);
                TimeZone tzone = TimeZone.getTimeZone(tz);
                TimeZone usrTZone = UserInfo.getTimeZone();
                Integer tzOffset = tzone.getOffset(gmtdate);
                Integer usrOffset = usrTZone.getOffset(gmtdate);
                System.debug('###### tzOffset: ' + tzOffset);
                System.debug('###### usrOffset: ' + usrOffset);            
                if(tzOffset <> usrOffset){
                    converted = gmtdate.addSeconds((tzOffset/1000)*-1);
                    System.debug('###### Added seconds: ' + (tzOffset/1000)*-1);
                }else{
                    converted = localDate;
                }    
            }
        }
        
        
        System.debug('###### converted after: ' + converted);
        return converted;
    }

}