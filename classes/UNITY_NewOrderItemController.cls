/*------------------------------------------------------------
Name:           UNITY_NewOrderItemController 
Author:         Izay
Company:        Miner
Description:    This is the class controller for the Add Product vf page 
=====================================================
Changelog
=====================================================
Developer:      Izay Ramos
Description:    Made changes to support intercompany transfer process
Date:           1/20/2016
=====================================================
------------------------------------------------------------*/
/** This is the class controller for the Add Product vf page
*/
public without sharing class UNITY_NewOrderItemController {
    
    public List<OLineWrapper> oLines {get; set;}
    public Order o {get; private set;}              //The order lines are being added to
    public Boolean finalize {get; set;}             //Denotes if to finalize the order on the next save
    public Boolean saveComplete {get; private set;} //Denotes that the save button was used and should go back to detail page
    public Boolean canEdit {get; private set;}      //Denotes that the PO can be editted
    public Boolean isIntComp {get; private set;}    //Denotes that the WO is intercompany transfer
    public Boolean isMSPUser {get; private set;}    //Denotes that the user on the page is from the MSP assigned as Vendor for intercompany transfer
    public Boolean isUR {get; private set;}         //Denotes that it is an UR
    public Boolean isMSPBU {get; private set;}      //Denotes that the BU on the order is MSP BU
    public Boolean hasError {get; private set;}     //Denotes that the page has errors
    public String saveResult {get; private set;}    //Holds save results to return to page
    public String message {get; private set;}       //Holds any messages to return to the page
    private String bu = '';                         //The BU name on the PO. Ex. 'NSBS','MNS','MSP Nashville',...
    private String oType = '';                      //The order type. 'Service','Project','PM'
    private String vendId = '';                       //The vendor id. Used to query the BU Account on intercompany transfer
    
    public UNITY_NewOrderItemController(ApexPages.StandardController controller){
        //Assign variables
        setOrder();
        this.bu = this.o.UNITY_Business_Unit__c;
        this.vendId = this.o.UNITY_Vendor__c;
        this.oType = this.o.UNITY_Work_Order_Type__c;
        this.isIntComp = this.o.FSO__WorkOrder__r.MSPFS_Intercompany_Transfer__c;
        this.isUR = this.o.RecordTypeId == UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE ? true:false;
        this.isMSPBU = this.o.UNITY_Business_Unit_Account__r.MSPFS_Is_MSP_BU__c;
        this.isMSPUser = false;
        this.finalize = false;
        this.saveComplete = false;
        this.canEdit = true;
        this.hasError = false;
        this.saveResult = '';
        this.message = '';
        //Izay: Added for intercompany transfer
        if(this.isIntComp){
            List<CKSW_BASE__User_Location__c> userLocs = [SELECT Id,MSPFS_BU_Account_Id__c,CKSW_BASE__User__c 
                                                          FROM CKSW_BASE__User_Location__c 
                                                          WHERE MSPFS_BU_Account_Id__c = :this.vendId AND CKSW_BASE__User__c = :UserInfo.getUserId() LIMIT 1];
            if(!userLocs.isEmpty()){
                isMSPUser = true;
            }
        }
        //Determine MSP BU user can edit 'Accepted' POs on intercompany transfer
        if((this.o.Status == 'Accepted' && isIntComp && isMSPUser)){
            this.hasError = false;
            this.canEdit = true;
        }
        //Determine if can edit PO
        else if(this.o.Status == 'PO Created' || this.o.Status == 'In Quote Process' || this.o.Status == 'Accepted' || this.o.Status == 'Final'){
            this.hasError = true;
            this.message = 'This PO cannot be modified.';
            this.canEdit = false;
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + message));
        }
        //Create the line wrapper for existing POLIs
        setPOLines();
    }

    private void setOrder(){
        this.o = [SELECT Id,OrderNumber,AccountId,Status,UNITY_Total_Cost__c,UNITY_Business_Unit__c,UNITY_Final_Price__c,UNITY_NTE__c,UNITY_Work_Order_Type__c,
                  FSO__WorkOrder__c,FSO__WorkOrder__r.RecordTypeId,FSO__WorkOrder__r.MSPFS_Intercompany_Transfer__c,UNITY_Business_Unit_Account__r.MSPFS_Is_MSP_BU__c,UNITY_Vendor__c,
                  UNITY_Estimated_Tax__c,MSPFS_MSP_Total_Cost__c,MSPFS_MSP_Total_Price__c,MSPFS_MSP_Margin__c,MSPFS_MSP_Margin_Per__c,MSPFS_NTE__c, RecordTypeId
                  FROM Order WHERE Id = :ApexHelper.getParam('id') LIMIT 1];
    }
    private void setPOLines(){
        //Create the line wrapper for existing POLIs
        this.oLines = new List<OLineWrapper>();
        List<OrderItem> oldLines = [SELECT Id,OrderId,OrderItemNumber,Quantity,UNITY_Activity_Type__c,UNITY_Cost__c,UNITY_Product_Code__c,UNITY_Part_Source__c,UNITY_Part_Location__c,
                                    UNITY_Location_AvailableQuantity__c,UNITY_Location_QOH_LastChecked__c,UNITY_Location_OOS__c,UNITY_Part_Location__r.Name,UNITY_Part_Source__r.UNITY_Miner_Regional_Office__c,
                                    UNITY_Is_Vendor_Supply__c,UNITY_Type__c,PricebookEntryId,UnitPrice,UNITY_Total_Cost__c,UNITY_Asset__c,UNITY_Vendor_Holiday_Multiplier__c,UNITY_Vendor_OT_Multiplier__c,
                                    MSPFS_Technician__c,MSPFS_Technician2__c,MSPFS_MSP_Cost__c,MSPFS_MSP_Price__c,MSPFS_MSP_Total_Cost__c,MSPFS_MSP_Total_Price__c,UNITY_Price__c,UNITY_Total_Price__c,UNITY_Price_Calculation_Details__c,
                                    UNITY_Vendor_Adjusted_Quantity__c,UNITY_Customer_Adjusted_Quantity__c,UNITY_Number_of_Techs__c,UNITY_Cost_Calculation_Details__c,UNITY_Customer_Holiday_Multiplier__c,UNITY_Customer_OT_Multiplier__c
                                    FROM OrderItem WHERE OrderId = :o.Id ORDER BY OrderItemNumber ASC];
        if(!oldLines.isEmpty()){
            for(OrderItem line :oldLines){
                Integer index = oLines.size();
                OLineWrapper wrapper = new OLineWrapper(line,this.bu,this.oType,index,isIntComp,isMSPUser);
                oLines.add(wrapper);
            }
        }
    }
    
    public void addItem(){
        OrderItem oLine = new OrderItem(
            OrderId = this.o.Id,
            UnitPrice = 0
        );
        Integer index = oLines.size();
        OLineWrapper wrapper = new OLineWrapper(oLine,this.bu,this.oType,index,isIntComp,isMSPUser);
        this.oLines.add(wrapper);
    }
    
    public void deleteSel(){
        this.hasError = false;
        this.message = '';
        SavePoint sp = Database.setSavepoint();
        List<OrderItem> toDelete = new List<OrderItem>();
        List<OLineWrapper> newLines = new List<OLineWrapper>();
        for(OLineWrapper line :oLines){
            if(line.sel){
                if(line.item != null){
                    if(String.isNotBlank(line.item.Id))
                    	toDelete.add(line.item);
                }
            }else{
                newLines.add(line);
            }
        }
        try{
            if(!toDelete.isEmpty()){
                delete toDelete;
                setOrder();
            }
            this.oLines = newLines;
            Integer i = 0;
            for(OLineWrapper line :oLines){
                line.index = i;
                i++;
            }
        }catch(Exception e){
            this.hasError = true;
            this.message = e.getMessage();
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + message));
            Database.rollback(sp);
        }
    }
    
    public PageReference doQuickSave(){
        PageReference pr;
        this.saveResult = '';
        this.saveComplete = false;
        this.hasError = false;
        this.message = '';
        SavePoint sp = Database.setSavepoint();
        if(!this.canEdit){
            pr = new PageReference('/'+this.o.Id);
            pr.setRedirect(true);
            return pr;
        }
        try{
            validateLines();
            if(!this.hasError){
                Set<Id> itemIds = new Set<Id>();
                List<OrderItem> toInsert = new List<OrderItem>();
                List<OrderItem> toUpdate = new List<OrderItem>();
                for(OLineWrapper line :oLines){
                    if(String.isBlank(line.item.Id)){
                        toInsert.add(line.item);
                    }else{
                        toUpdate.add(line.item);
                        itemIds.add(line.item.Id);
                    }
                }
                if(!toInsert.isEmpty()){
                    insert toInsert;
                    for(OrderItem item :toInsert){
                        itemIds.add(item.Id);
                    }
                }
                if(!toUpdate.isEmpty())
                    update toUpdate;
                setOrder();
                setPOLines();
            }else{
                //this.message = 'Missing required fields.';
            	//Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + message));
                return null;
            }
        }catch(Exception e){
            this.hasError = true;
            this.message = e.getMessage();
            if(e.getTypeName() == 'System.DmlException'){
                this.message = e.getDMLMessage(0);
                if(!ApexPages.hasMessages())
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + message));
            }else{
                Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + message));
            }
            Database.rollback(sp);
        }
        return null;
    }
    public PageReference doSave(){
        PageReference pr;
        this.saveResult = '';
        this.saveComplete = false;
        this.hasError = false;
        this.message = '';
        SavePoint sp = Database.setSavepoint();
        if(!this.canEdit){
            pr = new PageReference('/'+this.o.Id);
            pr.setRedirect(true);
            return pr;
        }
        try{
            validateLines();
            if(!this.hasError){
                List<OrderItem> toInsert = new List<OrderItem>();
                List<OrderItem> toUpdate = new List<OrderItem>();
                for(OLineWrapper line :oLines){
                    if(String.isBlank(line.item.Id)){
                        line.item.PricebookEntryId = line.pbe.Id;
                        toInsert.add(line.item);
                    }else{
                        toUpdate.add(line.item);
                    }
                }
                if(!toInsert.isEmpty())
                    insert toInsert;
                if(!toUpdate.isEmpty())
                    update toUpdate;
                if(this.finalize){
                    this.o.Status = 'Final';
                    update this.o;
                    //this.saveResult = UNITY_UsageRequestHandler.createPOFromUsageRequest(o.Id);
                }
                this.saveComplete = true;
            }else{
                //this.message = 'Missing required fields.';
            	//Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + message));
                return null;
            }
        }catch(Exception e){
            this.hasError = true;
            this.message = e.getMessage();
            Database.rollback(sp);
            if(e.getTypeName() == 'System.DmlException'){
                this.message = e.getDMLMessage(0);
                if(!ApexPages.hasMessages())
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + message));
            }else{
                Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + message));
            }
        }
        return null;
    }
    
    public void validateLines(){
        if(!this.oLines.isEmpty()){
            List<OLineWrapper> newLines = new List<OLineWrapper>();
            for(OLineWrapper line :oLines){
                if(String.isNotBlank(line.pbe.Product2Id)){
                    if(String.isBlank(line.item.UNITY_Type__c)){
                        line.item.UNITY_Type__c.addError('This field is required');
                        this.hasError = true;
                    }
                    if(String.isBlank(line.item.UNITY_Activity_Type__c)){
                        line.item.UNITY_Activity_Type__c.addError('This field is required');
                        this.hasError = true;
                    }
                    if(line.item.Quantity == null || line.item.Quantity == 0){
                        line.item.Quantity.addError('This field is required');
                        this.hasError = true;
                    }
                    if(line.item.UNITY_Is_Vendor_Supply__c && 
                      (line.item.UNITY_Activity_Type__c.indexOf('Labor') == -1 && line.item.UNITY_Activity_Type__c.indexOf('Travel') == -1) &&
                      (line.item.UNITY_Cost__c == null) &&
                      (!this.isIntComp) /*|| line.item.UNITY_Cost__c == 0*/){
                          line.item.UNITY_Cost__c.addError('This field is required');
                          this.hasError = true;
                    }
                    if(line.isMinerSource && String.isNotBlank(Line.item.UNITY_Part_Source__c) && line.item.UNITY_Part_Location__c == null){
                        line.item.UNITY_Part_Location__c.addError('This field is required when the Part Source is a Business Unit');
                        this.hasError = true;
                    }
                    if(!this.hasError)
                        newLines.add(line);
                }
            }
            if(!hasError)
                this.oLines = newLines;
        }
    }
    
    public void onProductChange(){
        Integer i = Integer.valueOf(ApexHelper.getParam('index'));
        String value = ApexHelper.getParam('myValue');
        System.debug('#####Izay: i = ' + i);
        System.debug('#####Izay: value = ' + value);
        for(OLineWrapper line :oLines){
            if(line.index == i){
                line.pbe = new PriceBookEntry();
                line.pbe.Product2Id = (value != null && value != '')?value:null;
                line.onProductChange();
                break;
            }
        }
    }
    
    public class OLineWrapper{
        public OrderItem item {get; set;}
        public PriceBookEntry pbe {get; set;}
        public Boolean sel {get; set;}
        public Boolean isMinerSource {get; private set;}
        public Boolean inStock {get; private set;}
        public Decimal inStockQty {get; private set;}
        public DateTime inStockLastMod {get; private set;}
        public Boolean isIntComp {get; private set;}
        public Boolean isMSPUser {get; private set;}
        private Boolean isMSPBU {get; private set;}
        public Boolean hasError {get; set;}
        private String bu {get; set;}
        private String oType {get; set;}
        public Integer index {get; set;}
        
        public oLineWrapper(OrderItem oLine,String bu,String otype,Integer i,Boolean isIC, Boolean isMSPU){
            this.item = oLine;
            this.sel = false;
            this.hasError = false;
            this.bu = bu;
            this.oType = otype;
            this.index = i;
            this.isIntComp = isIC;
            this.isMSPUser = isMSPU;
            this.isMSPBU = (this.bu != 'MNS' && this.bu != 'NSBS');
            if(String.isBlank(this.item.PriceBookEntryId)){
                this.pbe = new PriceBookEntry();
            }else{
                this.pbe = [SELECT Id,Pricebook2Id,Product2Id,Product2.UNITY_Product_Type__c,Product2.ProductCode,Product2.Name FROM PriceBookEntry WHERE Id = :this.item.PricebookEntryId LIMIT 1];
            }
            this.isMinerSource = oLine.UNITY_Part_Source__r.UNITY_Miner_Regional_Office__c;
            if(String.isNotBlank(this.item.UNITY_Part_Location__c))
                onStockLocationChange();
        }
        /**This method associates pricebook entry ans set default on POLI when product change
        */
        public void onProductChange(){
            if(String.isNotBlank(this.pbe.Product2Id)){
                //Associate the pricebookentry to the POLI from the selected Product
                Id standardPBId = UNITY_Constants.getStandardPriceBookId();
                PriceBookEntry[] temp = [SELECT Id,Pricebook2Id,Product2Id,Product2.UNITY_Product_Type__c,Product2.ProductCode,Product2.Name FROM PriceBookEntry WHERE Product2Id = :this.pbe.Product2Id AND Pricebook2Id = :standardPBId LIMIT 1];
                if(!temp.isEmpty()){
                    this.pbe = temp[0];
                }else{
                    PriceBookEntry tempPBE = new PriceBookEntry(
                        Product2Id = this.pbe.Product2Id,
                        Pricebook2Id = standardPBId,
                        IsActive = true,
                        UnitPrice = 0,
                        UseStandardPrice = false
                    );
                    insert tempPBE;
                    temp = [SELECT Id,Pricebook2Id,Product2Id,Product2.UNITY_Product_Type__c,Product2.ProductCode,Product2.Name FROM PriceBookEntry WHERE Product2Id = :this.pbe.Product2Id LIMIT 1];
                    this.pbe = temp[0];
                }
                this.item.PriceBookEntryId = this.pbe.Id;
                //Clear the line inventory values
                this.item.UNITY_Part_Source__c = null;
                this.item.UNITY_Part_Location__c = null;
                this.isMinerSource = false;
                this.inStockQty = null;
                this.inStockLastMod = null;
                this.inStock = false;
                //Default Line Type and Activity Type based on the selected propduct's product type
                if(String.isNotBlank(this.pbe.Product2.UNITY_Product_Type__c)){
                    //Defaults for all others ***LABOR***
                    if(this.pbe.Product2.UNITY_Product_Type__c.contains('Labor') ){
                        if(this.isMSPBU){
                            if(this.oType == 'Project')
                                this.item.UNITY_Type__c = 'Labor - Installation';
                            else 
                                this.item.UNITY_Type__c = 'Labor - Service';
                            if(this.oType == 'PM')
                                this.item.UNITY_Activity_Type__c = 'Preventative Maintenance';
                            else
                                this.item.UNITY_Activity_Type__c = 'Standard Labor';
                        }else{
                            this.item.UNITY_Type__c = 'Vendor Services';
                            this.item.UNITY_Activity_Type__c = 'Vendor Standard Labor';
                        }
                        this.item.UNITY_Is_Vendor_Supply__c = true;
                        this.item.UNITY_Number_of_Techs__c = '1 Technician';
                        getTechnicianAndBurdenRate();
                    //Default for all others ***TRAVEL***
                    }else if(this.pbe.Product2.UNITY_Product_Type__c.contains('Travel')){
                        if(this.isMSPBU){
                            this.item.UNITY_Type__c = 'Travel';
                            this.item.UNITY_Activity_Type__c = 'Standard Travel';
                        }else{
                            this.item.UNITY_Type__c = 'Vendor Services';
                            this.item.UNITY_Activity_Type__c = 'Vendor Standard Travel';
                        }
                        this.item.UNITY_Is_Vendor_Supply__c = true;
                        this.item.UNITY_Number_of_Techs__c = '1 Technician';
                        getTechnicianAndBurdenRate();
                    //Default for ALL ***PARTS***
                    }else if(this.pbe.Product2.UNITY_Product_Type__c.contains('Part')){
                        if(this.isMSPBU)
                            this.item.UNITY_Type__c = 'Vendor Services';
                        else
                            this.item.UNITY_Type__c = 'Parts';
                        if(this.oType == 'Service' || this.oType == 'PM' || this.oType == 'PMO' || this.oType == 'PMA')
                            this.item.UNITY_Activity_Type__c = 'Parts - Service and Remodel';
                        else if(this.oType == 'Project')
                            this.item.UNITY_Activity_Type__c = 'Parts - New Construction';
                        this.item.UNITY_Number_of_Techs__c = null;
                    //Default for ALL ***FREIGHT***
                    }else if(this.pbe.Product2.UNITY_Product_Type__c.contains('Freight')){
                        this.item.UNITY_Type__c = 'Parts';
                        if(this.oType == 'Service' || this.oType == 'PM' || this.oType == 'PMO' || this.oType == 'PMA')
                            this.item.UNITY_Activity_Type__c = 'Freight - Service and Remodel';
                        else if(this.oType == 'Project')
                            this.item.UNITY_Activity_Type__c = 'Freight - New Construction';
                        this.item.UNITY_Number_of_Techs__c = null;
                    }
                }//End if product has a product type
            }else{
                //Clear line if no product is selected
                this.pbe = new PriceBookEntry();
                this.item.UNITY_Type__c = null;
                this.item.UNITY_Activity_Type__c = null;
                this.item.UNITY_Is_Vendor_Supply__c = false;
                this.item.UNITY_Number_of_Techs__c = null;
            }
        }//End onProductChange()
        /**This method runs when the line cost is changed.
        */
        public void onCostQtyChange(){
            //Calculate the total cost
            if(this.item.Quantity != null && this.item.UNITY_Cost__c != null){
            	this.item.UNITY_Total_Cost__c = (this.item.UNITY_Cost__c * this.item.Quantity);
            }else{
                this.item.UNITY_Total_Cost__c = null;
            }
            String isUR = ApexHelper.getParam('isUR');
            if(this.isIntComp && this.item.UNITY_Is_Vendor_Supply__c && (String.isBlank(isUR) || (isUR != 'true')) ){
                //this.item.MSPFS_MSP_Price__c = this.item.UNITY_Cost__c;
                if(this.pbe.Product2.UNITY_Product_Type__c.contains('Part') && this.item.UNITY_Cost__c == null){
                    // #############################
                    // Izay: For the walk/run phase
                    // #############################
                    //Need to get the MSP Price from MSP BU to Asset Light BU Service Contract
                    //To populate on MSP Price and Cost fields
                }
            }
        }//End onCostQtyChange
        /**This methods updates the Cost when MSP Price is populated on intercompany transfer jobs
        */
        public void onMSPPriceChange(){
            String isUR = ApexHelper.getParam('isUR');
            System.debug('Izay: isUR = ' + isUR);
            if(isIntComp && String.isNotBlank(isUR) && isUR == 'true'){
                this.item.UNITY_Cost__c = this.item.MSPFS_MSP_Price__c;
                onCostQtyChange();
            }
        }
        /**This method runs when the Is Vendor Supply flag changes. 
        *Updates the default Line Type and Activity Type
        */
        public void onVendorSupplyChange(){
            if(String.isNotBlank(this.pbe.Product2.UNITY_Product_Type__c)){
                
                if( (!this.isMSPBU && !isIntComp) || (!this.isMSPBU && isIntComp) ){
                    if(this.pbe.Product2.UNITY_Product_Type__c.contains('Part') && this.item.UNITY_Is_Vendor_Supply__c){
                        this.item.UNITY_Type__c = 'Vendor Services';
                    }else if(this.pbe.Product2.UNITY_Product_Type__c.contains('Part')){
                        this.item.UNITY_Type__c = 'Parts';
                    }else if(this.pbe.Product2.UNITY_Product_Type__c.contains('Freight') && this.item.UNITY_Is_Vendor_Supply__c){
                        this.item.UNITY_Type__c = 'Vendor Services';
                    }else if(this.pbe.Product2.UNITY_Product_Type__c.contains('Freight')){
                        this.item.UNITY_Type__c = 'Parts';
                    }else if(this.pbe.Product2.UNITY_Product_Type__c.contains('Labor') && this.item.UNITY_Is_Vendor_Supply__c){
                        this.item.UNITY_Type__c = 'Vendor Services';
                    }else if(this.pbe.Product2.UNITY_Product_Type__c.contains('Labor')){
                        if(this.oType == 'Service'){
                            this.item.UNITY_Type__c = 'Labor - Service';
                        }else{
                            this.item.UNITY_Type__c = 'Labor - Installation';
                        }
                    }else if(this.pbe.Product2.UNITY_Product_Type__c.contains('Travel') && this.item.UNITY_Is_Vendor_Supply__c){
                        this.item.UNITY_Type__c = 'Vendor Services';
                    }else if(this.pbe.Product2.UNITY_Product_Type__c.contains('Travel')){
                        this.item.UNITY_Type__c = 'Travel';
                    }
                }else{
                    if(this.pbe.Product2.UNITY_Product_Type__c.contains('Part') && this.item.UNITY_Is_Vendor_Supply__c){
                        this.item.UNITY_Type__c = 'Parts';
                    }else if(this.pbe.Product2.UNITY_Product_Type__c.contains('Part')){
                        this.item.UNITY_Type__c = 'Vendor Services';
                    }else if(this.pbe.Product2.UNITY_Product_Type__c.contains('Freight') && this.item.UNITY_Is_Vendor_Supply__c){
                        this.item.UNITY_Type__c = 'Parts';
                    }else if(this.pbe.Product2.UNITY_Product_Type__c.contains('Freight')){
                        this.item.UNITY_Type__c = 'Vendor Services';
                    }else if(this.pbe.Product2.UNITY_Product_Type__c.contains('Labor') && this.item.UNITY_Is_Vendor_Supply__c){
                        if(this.oType == 'Service'){
                            this.item.UNITY_Type__c = 'Labor - Service';
                        }else{
                            this.item.UNITY_Type__c = 'Labor - Installation';
                        }
                    }else if(this.pbe.Product2.UNITY_Product_Type__c.contains('Labor')){
                        this.item.UNITY_Type__c = 'Vendor Services';
                    }else if(this.pbe.Product2.UNITY_Product_Type__c.contains('Travel') && this.item.UNITY_Is_Vendor_Supply__c){
                        this.item.UNITY_Type__c = 'Travel';
                    }else if(this.pbe.Product2.UNITY_Product_Type__c.contains('Travel')){
                        this.item.UNITY_Type__c = 'Vendor Services';
                    }
                }
                if(!this.isMSPBU && !this.isIntComp && this.item.UNITY_Is_Vendor_Supply__c){
                    this.item.UNITY_Part_Source__c = null;
                    onPartSourceChange();
                }else if(this.isMSPBU && !this.item.UNITY_Is_Vendor_Supply__c){
                    this.item.UNITY_Part_Source__c = null;
                    onPartSourceChange();
                }
            }
        }//ENd onVenbdorSupplyChange
        /**This methods runs when a Part Source is selected. It defaults the Part Location (Stock Location) if the source is a BU Account.
        *It is also called by other processes in the wrapper class.
        */
        public void onPartSourceChange(){
            System.debug('##### In onPartSourceChange...');
            //If there is a part source on the line
            if(String.isNotBlank(this.item.UNITY_Part_Source__c)){
                //Query the account to see if it is a miner BU
                Account a = [SELECT Id,Name,UNITY_Miner_Regional_Office__c,MSPFS_Is_MSP_BU__c FROM Account WHERE Id = :this.item.UNITY_Part_Source__c LIMIT 1];
                System.debug('##### isMinerSource? ' + a.UNITY_Miner_Regional_Office__c);
                //If it is a Miner BU account
                if(a.UNITY_Miner_Regional_Office__c){
                    this.isMinerSource = true;
                    if(this.isMSPBU && a.MSPFS_Is_MSP_BU__c){
                        this.item.UNITY_Is_Vendor_Supply__c = true;
                        this.item.UNITY_Type__c = 'Parts';
                    }
                    //Query stock locations associated with the account
                    List<FSO__Location__c> stockLocs = [SELECT Id,Name,FSO__Account__c FROM FSO__Location__c WHERE FSO__Account__c = :a.Id];
                    System.debug('##### has stock location? ' + (stockLocs.size() > 0));
                    //If stock locations are found...
                    if(!stockLocs.isEmpty()){
                        System.debug('##### how many stock location? ' + stockLocs.size());
                        //If there is only one(1) stock location...
                        if(stockLocs.size() == 1){
                            //Default the location as the part's location to adjusting inventory
                            this.item.UNITY_Part_Location__c = stockLocs[0].Id;
                            onStockLocationChange();
                        }else{
                            //What to to if there are many stock locations available???
                        }
                    }else{
                        this.item.UNITY_Part_Location__c = null;
                        onStockLocationChange();
                    }
                }else{
                    this.item.UNITY_Part_Location__c = null;
                    this.isMinerSource = false;
                    onStockLocationChange();
                }
            }else{
                this.item.UNITY_Part_Location__c = null;
                this.isMinerSource = false;
                onStockLocationChange();
            }
        }//End onPartSourceChange
        /**This method runs when the Part Location changes.
        *It is also called by other processes in the wrapper class
        */
        public void onStockLocationChange(){
            if(String.isNotBlank(this.item.UNITY_Part_Location__c) && this.pbe != null && String.isNotBlank(this.pbe.Product2Id)){
                String locId = this.item.UNITY_Part_Location__c;
            	String prodId = this.pbe.Product2Id;
                List<FSO__LocationStock__c> lockStock = new List<FSO__LocationStock__c>();
                lockStock = [SELECT Id,Name,FSO__Quantity__c,FSO__Location__c,FSO__Product__c,LastModifiedDate,UNITY_Min__c,UNITY_Landed_Cost__c,UNITY_MAC__c 
                             FROM FSO__LocationStock__c WHERE FSO__Location__c = :locId AND FSO__Product__c = :prodId LIMIT 1];
                if(lockStock.size() > 0){
                    this.inStockQty = lockStock[0].FSO__Quantity__c;
                    this.inStockLastMod = lockStock[0].LastModifiedDate;
                    this.inStock = (lockStock[0].FSO__Quantity__c > 0);
                    if(String.isBlank(this.item.Id)){
                        if(this.isIntComp && this.item.UNITY_Is_Vendor_Supply__c){
                            this.item.MSPFS_MSP_Cost__c = (lockStock[0].UNITY_Landed_Cost__c != null) ? lockStock[0].UNITY_Landed_Cost__c : 
                                                          (lockStock[0].UNITY_MAC__c != null) ? lockStock[0].UNITY_MAC__c : 0; 
                        }else{
                            this.item.UNITY_Cost__c = (lockStock[0].UNITY_Landed_Cost__c != null) ? lockStock[0].UNITY_Landed_Cost__c : 
                                                      (lockStock[0].UNITY_MAC__c != null) ? lockStock[0].UNITY_MAC__c : 0;
                        }
                        onCostQtyChange();
                    }
                        
                }else{
                    this.inStockQty = 0;
                    this.inStockLastMod = null;
                    this.inStock = false;
                    if(String.isBlank(this.item.Id)){
                        if(this.isIntComp && this.item.UNITY_Is_Vendor_Supply__c){
                            this.item.MSPFS_MSP_Cost__c = null; 
                        }else{
                            this.item.UNITY_Cost__c = null;
                        }
                        onCostQtyChange();
                    }
                }
            }else{
                this.inStockQty = null;
                this.inStockLastMod = null;
                this.inStock = false;
            }
        }

        public void getTechnicianAndBurdenRate(){
            List<Order> o = new List<Order>();//To query the PO with Primary and Secondary Tech from PO
            //Get the technician from the WO's primary and secondary tech
            o = [SELECT Id,FSO__WorkOrder__c,FSO__WorkOrder__r.UNITY_Business_Unit_Account__c,FSO__WorkOrder__r.UNITY_Primary_Technician__c,FSO__WorkOrder__r.UNITY_Secondary_Technician__c,
                 FSO__WorkOrder__r.MSPFS_Intercompany_Transfer__c,UNITY_Vendor__c
                 FROM Order WHERE Id = : this.item.OrderId LIMIT 1];
            String buid = '';
            if(!o.isEmpty()){
                if(!o[0].FSO__WorkOrder__r.MSPFS_Intercompany_Transfer__c)
                    buid = o[0].FSO__WorkOrder__r.UNITY_Business_Unit_Account__c;
                else
                    buid = o[0].UNITY_Vendor__c;

            }
            Set<Id> techIds = new Set<Id>();//To hold technician Ids. Either from line (resource id) or work order primary secondary tech (user id)
            //Add the technician from the line if these are populated
            if(String.isNotBlank(this.item.MSPFS_Technician__c))
                techIds.add(this.item.MSPFS_Technician__c);
            if(String.isNotBlank(this.item.MSPFS_Technician2__c))
                techIds.add(this.item.MSPFS_Technician2__c);
            //If there are no technicians populated on the line...
            if(techIds.isEmpty()){
                if(!o.isEmpty()){
                    //Add the techncian from the WO's primary and secondary tech
                    if(String.isNotBlank(o[0].FSO__WorkOrder__r.UNITY_Primary_Technician__c)){
                        techIds.add(o[0].FSO__WorkOrder__r.UNITY_Primary_Technician__c);
                    }
                    if(String.isNotBlank(o[0].FSO__WorkOrder__r.UNITY_Secondary_Technician__c)){
                        techIds.add(o[0].FSO__WorkOrder__r.UNITY_Secondary_Technician__c);
                    }
                }
            }
            //If there is(are) tech associated to the line...
            if(!techIds.isEmpty()){
                //Get the resource record
                List<CKSW_BASE__Resource__c> techs = [SELECT Id,MSPFS_Burden_Rate__c,MSPFS_BU_Account_Id__c,CKSW_BASE__User__c
                                                      FROM CKSW_BASE__Resource__c WHERE (Id IN :techIds OR CKSW_BASE__User__c IN :techIds)
                                                      AND MSPFS_BU_Account_Id__c = :buid LIMIT :techIds.size()];
                //If resource record is found...
                if(!techs.isEmpty()){
                    Decimal allRate = 0;//To hold tech(s) combined rate
                    for(CKSW_BASE__Resource__c t :techs){
                        allRate += t.MSPFS_Burden_Rate__c != null ? t.MSPFS_Burden_Rate__c:0;//Add the burden rate if esisting
                        //If the o list is NOT empty means that the lines don't have the tech(s) populated
                        if(!o.isEmpty()){
                            //Populate the tech on lines
                            if(t.CKSW_BASE__User__c == o[0].FSO__WorkOrder__r.UNITY_Primary_Technician__c)
                                this.item.MSPFS_Technician__c = t.Id;
                            else if(t.CKSW_BASE__User__c == o[0].FSO__WorkOrder__r.UNITY_Secondary_Technician__c)
                                this.item.MSPFS_Technician2__c = t.Id;
                        }
                    }
                    if(this.isIntComp){
                        this.item.MSPFS_MSP_Cost__c = allRate;
                    }else{
                        this.item.UNITY_Cost__c = allRate;
                    }
                    onCostQtyChange();
                }
            }
        }

    }
    
    @RemoteAction
    public static Map<String,String> getStockInfo(String[] args){
        Map<String,String> valsMap = new Map<String,String>();
        if(!args.isEmpty()){
            String locId = args[0];
            String prodId = args[1];
            List<FSO__LocationStock__c> lockStock = new List<FSO__LocationStock__c>();
            lockStock = [SELECT Id,Name,FSO__Quantity__c,FSO__Location__c,FSO__Product__c,LastModifiedDate,UNITY_Min__c FROM FSO__LocationStock__c WHERE FSO__Location__c = :locId AND FSO__Product__c = :prodId LIMIT 1];
            if(lockStock.size() > 0){
                valsMap.put('qty',String.valueOf(lockStock[0].FSO__Quantity__c));
                valsMap.put('lastDate',String.valueOf(lockStock[0].LastModifiedDate));
                valsMap.put('instock',String.valueOf((lockStock[0].FSO__Quantity__c > 0)));
            }else{
                valsMap.put('err','The part was not found in the selected inventory location');
            }
        }
        return valsMap;
    }
    
}