/*------------------------------------------------------------
Name:          UNITYCloneWorkOrderController
Author:        Krishna Kamineni
Company:       Minor
Description:   This class clones  WorkOrder
History:
1/21/2016      Krishna Kamineni

------------------------------------------------------------*/
public with sharing class UNITY_CloneWorkOrderController {
    //added an instance varaible for the standard controller
    private ApexPages.StandardController controller {get; set;}
    // add the instance for the variables being passed by id on the url
    @TestVisible private WorkOrder wo {get;set;}
    
    public id newWOId {get;set;}
    
    // initialize the controller
    public UNITY_CloneWorkOrderController(ApexPages.StandardController controller) { 
        //initialize the stanrdard controller
        this.controller = controller;
        // load the current record
        wo = (WorkOrder)controller.getRecord();       
    }
    
    // method called from the VF's action attribute to clone the partners    
    public void cloneWorkOrder() { 
         // setup the save point for rollback
         Savepoint sp = Database.setSavepoint();
         WorkOrder newWO;
              

         try {                      
              //Copy the WorkOrde - ONLY REQUIRED FIELDS INCLUDED              
               

                    wo = [SELECT woobj.CaseId,
                                 woobj.Subject,
                                 woobj.FSO__Type__c,
                                 woobj.Priority,
                                 woobj.UNITY_Trade__c,
                                 woobj.AccountId, 
                                 woobj.ContactId,
                                 woobj.UNITY_Customer__c,
                                 woobj.UNITY_Customer_PO__c,
                                 woobj.UNITY_Customer_Service_Contract__c,
                                 woobj.UNITY_Site_Contact_Phone__c,
                                 woobj.UNITY_Not_To_Exceed_NTE__c,
                                 woobj.UNITY_Signature_Name__c,
                                 woobj.UNITY_RMA_Required__c,   
                                 woobj.UNITY_Agent__c, 
                                 woobj.UNITY_PO_Template__c, 
                                 woobj.UNITY_Work_Description__c,
                          	     woobj.PostalCode,
                                 woobj.FSO__Geolocation__Latitude__s,
                                 woobj.FSO__Geolocation__Longitude__s,
                                 woobj.FSO__Special_Instructions__c,
                                 woobj.Description,
                                 woobj.UNITY_Skill_Type__c, 
                                 woobj.UNITY_Skill_Broad__c, 
                                 woobj.UNITY_Skill_Group__c 
                          FROM WorkOrder woobj
                          WHERE woobj.Id = :wo.id];
      

             newWO = wo.clone(false);
             newWO.UNITY_Related_Work_Order__c    = wo.Id;
             
             //Use Case Work Window Begin by default, even for related WO
             //newWO.UNITY_Work_Window_Begin__c     = DateTime.Now().AddDays(1);
             //newWO.UNITY_Work_Window_End__c       = DateTime.Now().AddDays(2);
             
             Integer indexOfHyphen = wo.Subject.lastindexOfChar(45);
             if(indexOfHyphen==-1){
                 newWO.Subject=wo.Subject+'-1';
             }
             else{
                 try{
                     Integer no = Integer.valueOf(wo.Subject.substring(indexOfHyphen+1));
                     newWO.Subject = wo.Subject.substring(0,indexOfHyphen+1)+(no+1);
                 }catch(Exception e){
                     newWO.Subject=wo.Subject+'-1';

                 }
             }
             insert newWO;
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Related Work Order Created. Redirect in 5 sec.')); 
            newWOId = newWO.id;      
         } catch (Exception e){
             // roll everything back in case of errors
            Database.rollback(sp);
            ApexPages.addMessages(e);
            newWOId = null;
            //return null;
         }
         //return new PageReference('/'+newWO.id);
    }
}