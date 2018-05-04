public with sharing class UNITY_WOHighlightPanelController {

    private Id onWorkOrderId {get;set;}
    private WorkOrder onWorkOrder {get;set;}
    
    public  UNITY_Utils.DateTimeZone dtzLocalTime {get;set;}
    public  UNITY_Utils.DateTimeZone dtzWOWorkWindowBegin {get;set;}
    public  UNITY_Utils.DateTimeZone dtzWOWorkWindowEnd {get;set;}
    public  UNITY_Utils.DateTimeZone dtzWOStartDate {get;set;}

    public  UNITY_Utils.DateTimeZone dtzWOCreated {get;set;}
    public  UNITY_Utils.DateTimeZone dtzWOAssigned {get;set;}
    public  UNITY_Utils.DateTimeZone dtzWOAccepted {get;set;}
    public  UNITY_Utils.DateTimeZone dtzWOScheduled {get;set;}
    public  UNITY_Utils.DateTimeZone dtzWOTravelStarted {get;set;}
    public  UNITY_Utils.DateTimeZone dtzWOCheckedIn {get;set;}
    public  UNITY_Utils.DateTimeZone dtzWOCompleted {get;set;}

    public  String sTimeZoneSidKey {get;set;}
    public  String sTimeZoneDisplayName {get;set;}

    public  boolean bWOCreated {get;set;}
    public  boolean bWOAssigned {get;set;}
    public  boolean bWOAccepted {get;set;}
    public  boolean bWOScheduled {get;set;}
    public  boolean bWOCheckedIn {get;set;}
    public  boolean bWOTravelStarted {get;set;}
    public  boolean bWOCompleted {get;set;}

    public  boolean bWarning {get;set;}
    public  String sWarningMsg {get;set;}
    
    public UNITY_WOHighlightPanelController(ApexPages.StandardController stdController) {
        this.onWorkOrder = null;
        this.onWorkOrderId = stdController.getId();        

        if (this.onWorkOrderId != null)
        {
            list<WorkOrder> woList =  [SELECT UNITY_Trade__c,
                                  UNITY_Vendor_Status__c,
                                  UNITY_Trade__r.Name, 
                                  RecordType.Name,
                                  Account.Name,
                                  AccountId,                              
                                  Account.UNITY_TimeZoneSidKey__c,
                                  UNITY_Business_Unit__c,
                                  Status,
                                  CreatedDate,
                                  UNITY_Work_Window_Begin__c,
                                  UNITY_Work_Window_End__c,
                                  UNITY_Dispatch_Attempts__c,
                                  UNITY_Assigned_Vendor__c,
                                  UNITY_Accepted_Vendor__c,
                                  UNITY_Vendor_Last_Assigned__c,
                                  UNITY_Vendor_Accept_Date__c,
                                  UNITY_Scheduled_Date_Time__c,
                                  StartDate,
                                  FSO__Start_Travel_Date__c,
                                  FSO__Check_In_Date__c,
                                  FSO__Completed_Date__c,
                                  SFPS_FS_FirstCheckIn__c,
                                  SFPS_FS_FirstTravel__c,
                                  SFPS_FS_LastCheckOut__c,
                                  SFPS_FS_Overall_Start__c,
                                  SFPS_FS_OverallStatus__c,
                                  UNITY_Smart_Assistant_Warning__c
                           FROM  WorkOrder
                           WHERE id = :this.onWorkOrderId ];

            if (woList != null && woList.size() >= 1) 
            {
                this.onWorkOrder = woList[0];

                sTimeZoneSidKey = onWorkOrder.Account.UNITY_TimeZoneSidKey__c;

                dtzLocalTime = new UNITY_Utils.DateTimeZone();

                DateTime tTime = UNITY_Utils.getDateTime();
                dtzLocalTime = UNITY_Utils.getDateTime(tTime, null, sTimeZoneSidKey);
                sTimeZoneDisplayName = dtzLocalTime.displayname;

                DateTime tWOCreated = onWorkOrder.CreatedDate;
                dtzWOCreated = UNITY_Utils.getDateTime(tWOCreated, null, sTimeZoneSidKey);
                bWOCreated = true;

                DateTime tWOWorkWindowBegin = onWorkOrder.UNITY_Work_Window_Begin__c;
                if (tWOWorkWindowBegin != Null)
                {
                    dtzWOWorkWindowBegin = UNITY_Utils.getDateTime(tWOWorkWindowBegin, null, sTimeZoneSidKey);
                }
                else
                {
                    dtzWOWorkWindowBegin = null;
                }

                DateTime tWOWorkWindowEnd = onWorkOrder.UNITY_Work_Window_End__c;
                if (tWOWorkWindowEnd != Null)
                {
                    dtzWOWorkWindowEnd = UNITY_Utils.getDateTime(tWOWorkWindowEnd, null, sTimeZoneSidKey);
                }
                else
                {
                    dtzWOWorkWindowEnd = null;
                }

                DateTime tWOAssigned = onWorkOrder.UNITY_Vendor_Last_Assigned__c;
                if (tWOAssigned != Null && (onWorkOrder.UNITY_Vendor_Status__c == 'Assigned' || onWorkOrder.UNITY_Vendor_Status__c == 'Accepted'))
                {
                    dtzWOAssigned = UNITY_Utils.getDateTime(tWOAssigned, null, sTimeZoneSidKey);
                    bWOAssigned = true;
                }
                else
                {
                    dtzWOAssigned = null;
                    bWOAssigned = false;
                }

                DateTime tWOAccepted = onWorkOrder.UNITY_Vendor_Accept_Date__c;
                if (tWOAccepted != Null && (onWorkOrder.UNITY_Vendor_Status__c == 'Accepted'))
                {
                    dtzWOAccepted = UNITY_Utils.getDateTime(tWOAccepted, null, sTimeZoneSidKey);
                    bWOAccepted = true;
                }
                else
                {
                    dtzWOAccepted = null;
                    bWOAccepted = false;
                }

                DateTime tWOScheduled = onWorkOrder.UNITY_Scheduled_Date_Time__c;
                DateTime tWOStartDate = onWorkOrder.StartDate;
                //DateTime tWOStartDate = onWorkOrder.SFPS_FS_Overall_Start__c;
                if (tWOScheduled != Null && tWOStartDate != Null)
                {
                    dtzWOScheduled = UNITY_Utils.getDateTime(tWOScheduled, null, sTimeZoneSidKey);
                    dtzWOStartDate = UNITY_Utils.getDateTime(tWOStartDate, null, sTimeZoneSidKey);
                    bWOScheduled = true;
                }
                else
                {
                    dtzWOScheduled = null;
                    dtzWOStartDate = null;          
                    bWOScheduled = false;
                }

                DateTime tWOTravelStarted = onWorkOrder.FSO__Start_Travel_Date__c;
                //DateTime tWOTravelStarted = onWorkOrder.SFPS_FS_FirstTravel__c;
                if (tWOTravelStarted != Null)
                {
                    dtzWOTravelStarted = UNITY_Utils.getDateTime(tWOTravelStarted, null, sTimeZoneSidKey);
                    bWOTravelStarted = true;
                }
                else
                {
                    dtzWOTravelStarted = null;
                    bWOTravelStarted = false;
                }

                DateTime tWOCheckedIn = onWorkOrder.FSO__Check_In_Date__c;
                //DateTime tWOCheckedIn = onWorkOrder.SFPS_FS_FirstCheckIn__c;
                if (tWOCheckedIn != Null)
                {
                    dtzWOCheckedIn = UNITY_Utils.getDateTime(tWOCheckedIn, null, sTimeZoneSidKey);
                    bWOCheckedIn = true;
                }
                else
                {
                    dtzWOCheckedIn = null;
                    bWOCheckedIn = false;
                }

                //DateTime tWOCompleted = onWorkOrder.FSO__Completed_Date__c;
                DateTime tWOCompleted = onWorkOrder.SFPS_FS_LastCheckOut__c;
                if (tWOCompleted != Null)
                {
                    dtzWOCompleted = UNITY_Utils.getDateTime(tWOCompleted, null, sTimeZoneSidKey);
                    bWOCompleted = true;
                }
                else
                {
                    dtzWOCompleted = null;
                    bWOCompleted = false;
                }

                // In case technician skipped all the steps and agent set status directly to closed
                //if (onWorkOrder.Status == 'Completed' || onWorkOrder.Status == 'Closed')
                if (onWorkOrder.SFPS_FS_OverallStatus__c == 'Completed' || onWorkOrder.SFPS_FS_OverallStatus__c == 'Closed')
                    bWOCompleted = true;

                //Prepare Smart Assistance
                sWarningMsg = onWorkOrder.UNITY_Smart_Assistant_Warning__c;
            }
        }

        if (this.onWorkOrder == null) sWarningMsg = 'Work Order Not Found';

        if (sWarningMsg != Null && sWarningMsg != '')
            bWarning = true;
        else
            bWarning = false;
    }
}