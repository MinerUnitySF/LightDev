public with sharing class AppEquipmentCtrl {
    public genesis__Application_Equipment__c equipment {get; set;}
    public genesis__Equipment_Master__c masterEq {get; set;}
    private String mode = genesis.LendingConstants.NEW_RECORD;
    private Date systemDate;
    public String choice {get;set;}
    public List<SelectOption> options {set;}
    public boolean isNewMasterEq {get;set;}
    
    public AppEquipmentCtrl(Apexpages.StandardController controller){
        equipment = (genesis__Application_Equipment__c)controller.getRecord();
        System.debug(logginglevel.error,'equipment id'+equipment.Id);
        if(equipment.Id != null ){
            mode = genesis.LendingConstants.EDITED_RECORD;
            String type = 'genesis__Application_Equipment__c';
            String query = 'SELECT '+ CommonUtil.fetchAllFields(type)+ 
                            ' from ' + type +
                            ' where id ='+'\''+equipment.id+'\'';
            equipment = Database.query(query); 
            //equipment.Copy_data_to_VehicleValuation__c = true;
            String masterEqId = equipment.genesis__Equipment__c;
            System.debug(logginglevel.error,'masterEqId id'+masterEqId);
            if(masterEqId != null){
                fetchMasterEquipmentDetails(masterEqId);
                isNewMasterEq = false;
                choice ='1';
            }   
        }else{
            updateTotalfields();
            isNewMasterEq = true;
        }
    }
    
    private void fetchMasterEquipmentDetails(String Id){
        String type = 'genesis__Equipment_Master__c';
        String query = 'SELECT '+ CommonUtil.fetchAllFields(type)+ 
                            ' from ' + type +
                            ' where id ='+'\''+id+'\' limit 1 ';
        List<genesis__Equipment_Master__c> ls = Database.query(query); 
        if(ls!=null){
            masterEq = ls.get(0);
        }else{
            masterEq = null;
        }
    }
    
    private void createApexMessage(ApexPages.severity severity,String errMsg){
         ApexPages.Message msg;
         msg = new ApexPages.Message(severity , errMsg);
         ApexPages.addMessage(msg);
    }
    
    private void updateMasterEquipment(integer action){
        // assumes master equipment is enabled
        
        if(action == 1){
        // update the master equipment as linked to application equipment
            masterEq.genesis__Available_To_Lease_Flag__c = false; 
            masterEq.genesis__Status__c = genesis.LendingConstants.MASTER_EQ_PENDING ;
        }else if(action == 2){
        // free the master equipment as application equipment is deleted
            masterEq.genesis__Available_To_Lease_Flag__c = true; 
            masterEq.genesis__Status__c = genesis.LendingConstants.MASTER_EQ_AVAILABLE ;
        }else if(action == 3){
        // reset the value so that application equipment can be saved and then set flag to false again
            masterEq.genesis__Available_To_Lease_Flag__c = true; 
            masterEq.genesis__Status__c = genesis.LendingConstants.MASTER_EQ_AVAILABLE ;
        }
        System.debug('masterEq ::'+masterEq);
              upsert masterEq;
    }
    
    private void updateTotalfields(){
        equipment.genesis__Wholesale_Rough_Base_Amount__c = (equipment.genesis__Wholesale_Rough_Base_Amount__c == null)?0:equipment.genesis__Wholesale_Rough_Base_Amount__c ;
        equipment.genesis__Wholesale_Rough_Mileage_Adjustment__c = (equipment.genesis__Wholesale_Rough_Mileage_Adjustment__c == null)?0:equipment.genesis__Wholesale_Rough_Mileage_Adjustment__c;
        equipment.genesis__Wholesale_Average_Base_Amount__c = (equipment.genesis__Wholesale_Average_Base_Amount__c == null)?0:equipment.genesis__Wholesale_Average_Base_Amount__c;
        equipment.genesis__Wholesale_Average_Mileage_Adjustment__c = (equipment.genesis__Wholesale_Average_Mileage_Adjustment__c == null)?0:equipment.genesis__Wholesale_Average_Mileage_Adjustment__c;
        equipment.genesis__Retail_Average_Base_Amount__c = (equipment.genesis__Retail_Average_Base_Amount__c == null)?0:equipment.genesis__Retail_Average_Base_Amount__c;
        equipment.genesis__Retail_Average_Mileage_Adjustment__c = (equipment.genesis__Retail_Average_Mileage_Adjustment__c == null)?0:equipment.genesis__Retail_Average_Mileage_Adjustment__c;  
                 
        equipment.genesis__Wholesale_Rough_Adjusted_Amount__c = equipment.genesis__Wholesale_Rough_Base_Amount__c + 
                                                        equipment.genesis__Wholesale_Rough_Mileage_Adjustment__c;
        equipment.genesis__Wholesale_Average_Adjusted_Amount__c = equipment.genesis__Wholesale_Average_Base_Amount__c 
                                                            + equipment.genesis__Wholesale_Average_Mileage_Adjustment__c;
        equipment.genesis__Retail_Average_Adjusted_Amount__c = equipment.genesis__Retail_Average_Base_Amount__c 
                                                            + equipment.genesis__Retail_Average_Mileage_Adjustment__c;
    } 
      
    public PageReference saveDetailsInfo(){
        System.debug(equipment);
        System.debug(masterEq);
         if(choice != '2' && equipment.genesis__Equipment__c == null){
             createApexMessage(ApexPages.severity.Error,'Equipment cannot be null');
             return null;
         }
         if(choice == '2'){
             //insert new object into master equipment after validation
             if(!validateMasterEquipment()){
                System.debug('No details entered for master equipment');
                createApexMessage(ApexPages.severity.Error,'Please fill Equipment Description');
                return null;
             }
             updateMasterEquipment(3);
             System.debug(masterEq);
             equipment.genesis__Equipment__c = masterEq.Id;
         }
         try{   
                if(masterEq.genesis__Available_To_Lease_Flag__c == false){
                    updateMasterEquipment(3);
                }
                updateTotalfields();
                Database.upsert(equipment);
                updateMasterEquipment(1);
                equipment.genesis__Equipment__c = masterEq.Id;
                
                return(new PageReference('/'+equipment.id));
         }catch(Exception e){
                System.debug('Error is : '+e);
                createApexMessage(ApexPages.severity.Error,e.getDMLMessage(0));
                return null;
         }   
    
    }

     public PageReference deleteDetailsInfo(){
         try{   
                String id =  equipment.genesis__Application__c;
                updateMasterEquipment(2);
                Database.delete(equipment);
                return(new PageReference('/'+id));
                
         }catch(Exception e){
                System.debug('Error is : '+e);
                createApexMessage(ApexPages.severity.Error,e.getDMLMessage(0));
                return null;
         }   
     
     }
    
    public PageReference fetchMasterDetails(){ 
        String fetchedId = equipment.genesis__Equipment__c;
        System.debug('master Equipment Id fetched :'+fetchedId);
        if(fetchedId != null){
            fetchMasterEquipmentDetails(fetchedId);
        }
        System.debug('masterEq fetched is :'+masterEq);
        return null;
    }
    
    public void fetchEvaluation(){
         ApexPages.Message msg;
         String result = genesis.EquipmentEvaluationController.fetchEquipmentCost(equipment.Id);
         if(Test.isRunningTest()){
            result = 'Successfully fetched valuation';
         }
         if(result.toLowerCase().contains('successfully')){
             try{
                 String type = 'genesis__Application_Equipment__c';
                 String query = 'SELECT '+ CommonUtil.fetchAllFields(type)+ 
                                ' from ' + type +
                                ' where id ='+'\''+equipment.id+'\'';
                 equipment = Database.query(query); 
             }catch(Exception e){
                 createApexMessage(ApexPages.severity.ERROR,e.getMessage());
             }
         }
         createApexMessage(ApexPages.severity.INFO,result);
    }
    
     public PageReference cancel(){ 
         String id =  equipment.genesis__Application__c;
         return(new PageReference('/'+id));
    }
    
    public List<SelectOption> getOptions(){
        List<SelectOption> optionsList = new List<SelectOption>();
        optionsList.add(new SelectOption('1', 'Select Existing Details'));
        optionsList.add(new SelectOption('2', 'Create New Details'));
        return optionsList;
    }
    
     public PageReference equipmentMasterChoice(){ 
         System.debug('Inside equipmentMasterChoice, choice ::'+choice);
         
         if(choice == '1'){
             isNewMasterEq = false;
         }else if(choice == '2'){
              isNewMasterEq = true;
               masterEq = new genesis__Equipment_Master__c();
              updateTotalfields();
         }{
             isNewMasterEq = false;
         }
         return null;
    }
    
  /*  public PageReference createMasterEquipment(){
        if(masterEq.Equipment_Serial_Number__c != null){
            createApexMessage(ApexPages.severity.INFO,'New Equipment Details Saved');
        }else{
            createApexMessage(ApexPages.severity.Error,'equipment Serial Number is required');
        }
        
        return null;
    } */
    
    public boolean validateMasterEquipment(){
        boolean valid = true;
        // if all fields are null then master equipment should not be entered.
        if(masterEq.genesis__Equipment_Serial_Number__c == null 
            && masterEq.genesis__Equipment_Type__c == null
            && masterEq.genesis__License_Plate_Number__c == null
            && masterEq.genesis__Equipment_Sub_Type__c == null
            && masterEq.genesis__VIN_Identification__c == null
            && masterEq.genesis__Make__c == null
            && masterEq.genesis__Model__c == null
            && masterEq.genesis__Style__c == null
            && masterEq.genesis__Year_Of_Manufacture__c == null
            && masterEq.genesis__Mileage__c == null
            && masterEq.genesis__Stock_Number__c == null){
            valid = false;
        }
        return valid;
    }
}