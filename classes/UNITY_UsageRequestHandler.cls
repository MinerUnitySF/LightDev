/*------------------------------------------------------------
/ Name:           UNITY_UsageRequestHandler 
/ Author:         Natalia Chiappara
------------------------------------------------------------*/
global without sharing class UNITY_UsageRequestHandler {
    
    public static id standardPriceBookId{get;set;}
    static {
        if(Test.isRunningTest()){
            standardPriceBookId = Test.getStandardPricebookId();
        }else{
            standardPriceBookId = UNITY_Constants.getStandardPriceBookId();
        }
    }
    public static Order currentOrder {get;set;}
    
    public static List<OrderItem> currentOrderItemList {get;set;}
    
    public static List<OrderItem> laborAndTravelLines {get;set;}
    
    public static List<OrderItem> partLines {get;set;}
    public static List<OrderItem> allOtherLines {get;set;}
    
    public static List<OrderItem> vendorSupplyOrderItemList {get;set;}
    
    public static List<OrderItem> noVendorSupplyOrderItemList {get;set;}
    
    public UNITY_UsageRequestHandler(ApexPages.StandardController c){
        
    }
    
    /* ************************************************* 
     * DEPRECATED BY: IZAY
     * This is the old code to Split Part Sourcing POs
     ***************************************************
    webservice static String createPOFromUsageRequest(Id usageRequestId){
        
        //Izay: Added FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__r.UNITY_Is_Pass_Through__c to query
        currentOrder = [select id,UNITY_Discount__c,UNITY_Discount_Amount__c,UNITY_Business_Unit__c,UNITY_Vendor__c,FSO__WorkOrder__r.CaseId,FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__c,
                        FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__r.UNITY_Is_Pass_Through__c,FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__r.UNITY_Contract_Sub_type__c,FSO__WorkOrder__r.UNITY_Customer__r.Account_Email__c,FSO__WorkOrder__r.UNITY_Agent__c,FSO__WorkOrder__r.UNITY_Customer_Margin__c ,
                        FSO__WorkOrder__r.UNITY_Customer__c,UNITY_NTE_Exceeded__c,UNITY_Total_Amount__c,UNITY_Business_Unit_Account__c,Status, FSO__WorkOrder__c,UNITY_Total_Cost__c,AccountId,EffectiveDate,FSO__WorkOrder__r.RecordTypeId,
                        Description,UNITY_Shipping_Method__c,UNITY_Shipping_Provider__c,UNITY_Ship_To_Account__c,ShipToContactId,UNITY_Parts_Needed_By__c,UNITY_Expected_Arrival_Date__c,FSO__WorkOrder__r.UNITY_Use_Menu_Pricing__c,FSO__WorkOrder__r.UNITY_Include__c,
                        ShippingStreet,ShippingCity,ShippingState,ShippingStateCode,ShippingPostalCode,ShippingCountry, ShippingCountryCode, UNITY_Actual_Arrival_Date__c,UNITY_Tracking_Number__c
                        FROM Order WHERE Id =:usageRequestId];
        
        currentOrderItemList = [SELECT Id,UNITY_Discount__c,UNITY_Discount_Amount__c,UNITY_Discounted_Price__c,UNITY_Vendor_Adjusted_Quantity__c,UNITY_Customer_Adjusted_Quantity__c,UNITY_Cost__c,UNITY_Total_Cost__c,UNITY_Total_Price__c,
                                UNITY_Activity_Type__c,UNITY_Type__c,UNITY_Vendor_Holiday_Multiplier__c,UNITY_Vendor_OT_Multiplier__c,UNITY_Customer_Holiday_Multiplier__c,UNITY_Customer_OT_Multiplier__c,UNITY_Number_of_Techs__c,
                                UNITY_Price__c,PricebookEntryId,Quantity,UnitPrice,PricebookEntry.Id,PricebookEntry.Product2Id,PricebookEntry.Product2.UNITY_Product_Type__c,UNITY_Is_Vendor_Supply__c,UNITY_Part_On_Hand__c,UNITY_Include__c,
                                UNITY_Part_Source__c,UNITY_Make__c,UNITY_Model__c,Description,UNITY_Unit_of_Measure__c,UNITY_Sales_Tax__c FROM OrderItem WHERE OrderId =:currentOrder.Id];
        
        checkNTE();

        String result;
        if (currentOrder.UNITY_NTE_Exceeded__c){
            createQuote();
            currentOrder.Status = 'In Quote Process';
            result = 'NTE Exceeded! A Quote has been generated.';
        }
        else{
            createPurchaseOrders();
            currentOrder.Status = 'PO Created';
            result = 'Purchase Order created.';
        }
        
        
        update currentOrder;
        
        return result;
    }
	*/
    ///////////////////////////////////////////////////////////////////////
    /**Set the currentOrder and currentOrderItemList variables
     * @param urId - String: The Usage Request Id
     * */
    public static void setCurrentOrder(String urId){
        //Izay: Added FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__r.UNITY_Is_Pass_Through__c to query
        //Izay: Added FSO__WorkOrder__r.MSPFS_Service_Order_Type__c to query
        currentOrder = [select Id,UNITY_Discount__c,UNITY_Discount_Amount__c,UNITY_Business_Unit__c,UNITY_Vendor__c,FSO__WorkOrder__r.CaseId,FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__c,UNITY_Customer__r.MH_SL_CustID__c,UNITY_Customer__r.UNITY_Bill_to_Account__r.MH_SL_CustID__c,
                        FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__r.UNITY_Is_Pass_Through__c,FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__r.UNITY_Contract_Sub_type__c,FSO__WorkOrder__r.UNITY_Customer__r.Account_Email__c,FSO__WorkOrder__r.UNITY_Agent__c,FSO__WorkOrder__r.UNITY_Customer_Margin__c,
                        FSO__WorkOrder__r.UNITY_Customer__c,UNITY_NTE_Exceeded__c,UNITY_Total_Amount__c,UNITY_Business_Unit_Account__c,Status,FSO__WorkOrder__c,UNITY_Total_Cost__c,AccountId,EffectiveDate,FSO__WorkOrder__r.RecordTypeId,UNITY_Final_Price__c,UNITY_Line_Item_DIscounted_Price__c,
                        Description,UNITY_Shipping_Method__c,UNITY_Shipping_Provider__c,UNITY_Ship_To_Account__c,ShipToContactId,UNITY_Parts_Needed_By__c,UNITY_Expected_Arrival_Date__c,FSO__WorkOrder__r.UNITY_Use_Menu_Pricing__c,FSO__WorkOrder__r.UNITY_Include__c,
                        ShippingStreet,ShippingCity,ShippingState,ShippingStateCode,ShippingPostalCode,ShippingCountry, ShippingCountryCode, UNITY_Actual_Arrival_Date__c,UNITY_Tracking_Number__c,OwnerId,UNITY_Estimated_Tax__c,FSO__WorkOrder__r.MSPFS_Service_Order_Type__c
                        FROM Order WHERE Id =:urId];
        
        currentOrderItemList = [SELECT Id,UNITY_Discount__c,UNITY_Discount_Amount__c,UNITY_Discounted_Price__c,UNITY_Vendor_Adjusted_Quantity__c,UNITY_Customer_Adjusted_Quantity__c,UNITY_Cost__c,UNITY_Total_Cost__c,UNITY_Total_Price__c,
                                UNITY_Activity_Type__c,UNITY_Type__c,UNITY_Vendor_Holiday_Multiplier__c,UNITY_Vendor_OT_Multiplier__c,UNITY_Customer_Holiday_Multiplier__c,UNITY_Customer_OT_Multiplier__c,UNITY_Number_of_Techs__c,
                                UNITY_Not_Billable__c,UNITY_MP_Labor_Vendor_Adjusted_Qty__c,UNITY_Related_Menu_Price_Line__c,UNITY_MP_Labor_Cost__c,
                                UNITY_Price__c,PricebookEntryId,Quantity,UnitPrice,PricebookEntry.Id,PricebookEntry.Product2Id,PricebookEntry.Product2.UNITY_Product_Type__c,UNITY_Is_Vendor_Supply__c,UNITY_Part_On_Hand__c,UNITY_Include__c,
                                UNITY_Part_Source__c,UNITY_Part_Location__c,UNITY_Make__c,UNITY_Model__c,Description,UNITY_Unit_of_Measure__c,UNITY_Sales_Tax__c,
                                MSPFS_MSP_Cost__c,MSPFS_MSP_Price__c,MSPFS_Technician__c,MSPFS_Technician2__c
                                FROM OrderItem WHERE OrderId =:currentOrder.Id];
    }
    /////////////////////////////////////////////////////////////////////
    /**Remote Action method to initiate the CreatePO Process from vfPage
     * @param urId - String: The Usage Request Id
     * @return Boolean: NTEExceeded [true|false]
     * */
    @RemoteAction
    public static Map<String,String> createPOFromUsageRequest2(String urId){
        Map<String,String> resultMap = new Map<String,String>();
        SavePoint sp = Database.setSavepoint();
        if(String.isNotBlank(urId)){
            try{
                Boolean NTEExceeded = false;
                setCurrentOrder(urId);
                if(String.isNotBlank(currentOrder.FSO__WorkOrder__r.MSPFS_Service_Order_Type__c) && currentOrder.FSO__WorkOrder__r.MSPFS_Service_Order_Type__c == 'Quoted'){
                    NTEExceeded = true;
                    resultMap.put('success','true');
                    resultMap.put('result','true');
                    resultMap.put('message','Quoted Service Order...');
                }else{
                    checkNTE(currentOrder);
                    NTEExceeded = currentOrder.UNITY_NTE_Exceeded__c;
                    update currentOrder;
                    resultMap.put('success','true');
                    if(NTEExceeded){
                        resultMap.put('result','true');
                        resultMap.put('message','NTE Exceeded...');
                    }else{
                        resultMap.put('result','false');
                        resultMap.put('message','Didn\'t Exceed NTE...');
                    }
                }
            }catch(Exception e){
                resultMap.put('success','false');
            	resultMap.put('message','Error: ' + e.getMessage());
                Database.rollback(sp);
            }
        }else{
            resultMap.put('success','false');
            resultMap.put('message','Error: Missing Usage Request Id');
        }
        return resultMap;
    }
    /////////////////////////////////////////////////////////////////////
    /**Remote Action method to initiate the CreatePO Process from vfPage
     * @param urId - String: The Usage Request Id
     * @return Boolean: NTEExceeded [true|false]
     * */
    @RemoteAction
    public static Map<String,String> createQuote2(String urId){
        Map<String,String> resultMap = new Map<String,String>();
        SavePoint sp = Database.setSavepoint();
        System.debug('#####Izay: In createQuote2...');
        if(String.isNotBlank(urId)){
            String result = '';
            setCurrentOrder(urId);
            try{
                UNITY_Proposal__c quote = createQuote();
                if(quote != null){
                    quote = [SELECT Id,Name,UNITY_Master_Quote__c,UNITY_Master_Quote__r.UNITY_Service_Charge__c FROM UNITY_Proposal__c WHERE Id = :quote.Id LIMIT 1];
                    System.debug('#####Izay: Quote Created...');
                    System.debug('#####Izay: Master Quote Id = ' + quote.UNITY_Master_Quote__c);
                    System.debug('#####Izay: Master Service Charge Amount = ' + quote.UNITY_Master_Quote__r.UNITY_Service_Charge__c);
                    List<Id> mqIds = new List<Id>();
                    mqIds.add(quote.UNITY_Master_Quote__c);
                    //UNITY_ProposalTriggerHandler_Miner.setServiceChargeTaxFuture(mqIds);
                }
                resultMap.put('success','true');
                resultMap.put('result','quote created');
            	resultMap.put('message','Success: Quote has been created...');
            }catch(Exception e){
                resultMap.put('success','false');
            	resultMap.put('message','Error: ' + e.getMessage());
                Database.rollback(sp);
            }
        }else{
            resultMap.put('success','false');
            resultMap.put('message','Error: Missing Usage Request Id');
        }
        return resultMap;
    }
    /////////////////////////////////////////////////////////////////////
    /**This method checks if the currentOrder exceeds the Case NTE
     * Sets the UNITY_NTE_Exceeded__c on the currentOrder
     * */
    public static void checkNTE(Order order){
        Map<Id,Case> caseMap = new Map<Id,Case>([SELECT Id,UNITY_NTE_Threshold__c,UNITY_Customer_Service_Contract__c,UNITY_Customer_Service_Contract__r.UNITY_Is_Pass_Through__c FROM Case WHERE Id = :currentOrder.FSO__WorkOrder__r.CaseId]);
        Map<string,UNITY_General_Settings__c> generalSettings = UNITY_General_Settings__c.getAll();
        Set<String> delimitedInvoiceableStatuses = new Set<String>();
        UNITY_General_Settings__c generalSetting = generalSettings.get(UNITY_Constants.PO_INVOICEABLE_STATUSES);
        String POInvoiceableStatuses;
        if (generalSetting!=null){
            POInvoiceableStatuses = generalSetting.UNITY_Value__c;
        }
        if (POInvoiceableStatuses!=null){
            delimitedInvoiceableStatuses = new Set<String>(POInvoiceableStatuses.split(UNITY_Constants.PO_INVOICEABLE_STATUSES_DELIMITER));
        }
        List<Order> orders = [SELECT Id,OrderNumber,AccountId,EffectiveDate,FSO__WorkOrder__c,FSO__WorkOrder__r.CaseId,UNITY_CaseId__c,UNITY_Estimated_Tax__c,
                              UNITY_Line_Item_DIscounted_Price__c,UNITY_Final_Price__c,UNITY_Discount__c,
                              (SELECT Id,OrderId,OrderItemNumber,UNITY_Customer_Adjusted_Quantity__c,UNITY_Is_Vendor_Supply__c,UNITY_Sales_Tax__c,UNITY_Not_Billable__c,
                               UNITY_Price__c,UNITY_Type__c,UNITY_Activity_Type__c,UNITY_Discounted_Price__c,UNITY_Total_Price__c,UNITY_Product_Name__c
                               FROM OrderItems WHERE PriceBookEntry.Product2.Name != 'Vendor Service Fee'
                               AND UNITY_Not_Billable__c = FALSE 
                              ) 
                              FROM Order WHERE FSO__WorkOrder__r.CaseId = :order.FSO__WorkOrder__r.CaseId AND Id != :order.Id
                              AND IsDeleted = FALSE
                              AND(RecordTypeId =: UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE 
                                  OR 
                                  RecordTypeId =: UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE)
                              AND Status IN :delimitedInvoiceableStatuses
                              AND FSO__WorkOrder__r.Status != 'Canceled'];
        
        Map<Id,List<Order>> caseOrdersMap = new Map<Id,List<Order>>();
        
        for(Order o :orders){
            if(!caseOrdersMap.containsKey(o.UNITY_CaseId__c))
                caseOrdersMap.put(o.UNITY_CaseId__c,new List<Order>());
            caseOrdersMap.get(o.UNITY_CaseId__c).add(o);    
        }
        
        System.debug('#####Izay: caseMap.keySet().size(): ' + caseMap.keySet().size());
        System.debug('#####Izay: orders.size(): ' + orders.size()); 
        System.debug('#####Izay: caseOrdersMap.keySet().size(): ' + caseOrdersMap.keySet().size()); 
        
        for(Id cid :caseMap.keySet()){
            Decimal NTEVal = caseMap.containsKey(cid)?caseMap.get(cid).UNITY_NTE_Threshold__c:0;
            Boolean isPassTrough = caseMap.containsKey(cid)?caseMap.get(cid).UNITY_Customer_Service_Contract__r.UNITY_Is_Pass_Through__c:false;
            Decimal totalPrice = 0;
            Decimal totalVendorSupply = 0;
            Decimal totalDiscVendSup = 0;
            Decimal totalTax = 0;
            Decimal sCharge = 0;
            Decimal discSCharge = 0;
            System.debug('#####Izay: NTEVal: ' + NTEVal);
            System.debug('#####Izay: isPassTrough: ' + isPassTrough);
            
            if(caseOrdersMap.containsKey(cid)){
                for(Order o :caseOrdersMap.get(cid)){
                    Decimal temp = (o.UNITY_Final_Price__c != null) ? o.UNITY_Final_Price__c : o.UNITY_Line_Item_DIscounted_Price__c;
                    totalPrice += temp;
                    Decimal tempTax = (o.UNITY_Estimated_Tax__c != null) ? o.UNITY_Estimated_Tax__c : 0;
                    totalTax += tempTax;
                    for(OrderItem ot :o.OrderItems){
                        Decimal tempLine = (ot.UNITY_Discounted_Price__c != null) ? ot.UNITY_Discounted_Price__c: ot.UNITY_Total_Price__c;
                        if(ot.UNITY_Is_Vendor_Supply__c){
                            totalVendorSupply += tempLine;
                            if(o.UNITY_Discount__c != null && o.UNITY_Discount__c > 0){
                                tempLine = (tempLine - (tempLine*(o.UNITY_Discount__c/100))).setScale(2,System.RoundingMode.HALF_DOWN);
                            }
                            totalDiscVendSup += tempLine;
                        }
                    }
                }
            }
            totalPrice += (order.UNITY_Final_Price__c != null) ? order.UNITY_Final_Price__c : order.UNITY_Line_Item_DIscounted_Price__c;
            totalTax += (order.UNITY_Estimated_Tax__c != null) ? order.UNITY_Estimated_Tax__c : 0;
            for(OrderItem ot :currentOrderItemList){
                if(!ot.UNITY_Not_Billable__c){
                    Decimal tempLine = (ot.UNITY_Discounted_Price__c != null) ? ot.UNITY_Discounted_Price__c : ot.UNITY_Total_Price__c;
                    if(ot.UNITY_Is_Vendor_Supply__c){
                        totalVendorSupply += tempLine;
                        if(currentOrder.UNITY_Discount__c != null && currentOrder.UNITY_Discount__c > 0){
                            tempLine = (tempLine - (tempLine*(currentOrder.UNITY_Discount__c/100))).setScale(2,System.RoundingMode.HALF_DOWN);
                        }
                        totalDiscVendSup += tempLine;
                    }
                }
            }
            System.debug('#####Izay: totalVendorSupply: ' + totalVendorSupply);
            if(isPassTrough){
                sCharge = UNITY_UsageRequestHandler.calculateServicveCharge(caseMap.get(cid).UNITY_Customer_Service_Contract__c,totalVendorSupply,0);
                Decimal scDiscPer = 0;
                if(totalDiscVendSup != null && totalDiscVendSup > 0 && totalVendorSupply != null && totalVendorSupply > 0){
                    scDiscPer = (totalDiscVendSup/totalVendorSupply).setScale(2,System.RoundingMode.HALF_DOWN);
                }
                discSCharge = (scDiscPer > 0) ? (sCharge * scDiscPer).setScale(2,System.RoundingMode.HALF_DOWN) : sCharge;
            }
            Decimal sChargeTax = 0;
            if(discSCharge != null && discSCharge > 0){
                sChargeTax = getServiceChargeTax(currentOrder,discSCharge);
            }
            System.debug('#####Izay: totalPrice: ' + totalPrice);
            System.debug('#####Izay: sCharge: ' + sCharge);
            System.debug('#####Izay: sChargeTax: ' + sChargeTax);
            System.debug('#####Izay: totaltax: ' + totalTax);
            if((totalPrice + discSCharge + sChargeTax + totalTax) > NTEVal){
                order.UNITY_NTE_Exceeded__c = true;
            }else{
                order.UNITY_NTE_Exceeded__c = false;
            }
        }
    }
    /////////////////////////////////////////////////////////////////////
    /**This method calculates service charge tax for given service charge amount
     * @param amount - Decimal: The Usage Request Id
     * @return Decimal: The service charge tax amount
     * */
    public static Decimal getServiceChargeTax(Order order, Decimal amount){
        Decimal scTax = 0;
        UNITY_CallAvatax.AvataxResult result = UNITY_CallAvatax.getServiceChargeTax(order.AccountId,order.UNITY_Business_Unit_Account__c,order.UNITY_Customer__c,amount);
        scTax = result.totalTax;
        return scTax;
    }
    /////////////////////////////////////////////////////////////////////////////////////
    /**This method creates Purchase Order(s) from an usage request that didn't exceed NTE
     * RemoteAction method can be called from vfPage
     * */
    @RemoteAction
    public static Map<String,String> createPurchaseOrders2(String urId){
        Map<String,String> result = new Map<String,String>();
        String message = '';
        result.put('success','true');
        result.put('result','');
        result.put('message','');
        SavePoint sp = Database.setSavepoint();
        setCurrentOrder(urId);
        //Get the service contract subtype
        String scSub = currentOrder.FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__r.UNITY_Contract_Sub_type__c;
        //Denotes if the WO is Contract Pricing
        Boolean isContract = (scSub == 'Contract Pricing' && currentOrder.FSO__WorkOrder__r.UNITY_Include__c);
        //Denotes if the WO is Menu Pricing
        Boolean isMenuPrice = (scSub == 'Menu Pricing' && currentOrder.FSO__WorkOrder__r.UNITY_Use_Menu_Pricing__c);
        //Denotes if the WO is Non-Work
        Boolean isNonWork = (currentOrder.FSO__WorkOrder__r.RecordTypeId == UNITY_Constants.WO_NON_WORK_RECORDTYPE);
        //Get the customer service contract to find menu priced lines
        List<UNITY_Service_Contract__c> contractList = [SELECT Id, UNITY_Account__r.RecordTypeId, UNITY_Is_Pass_Through__c, UNITY_Cost_Plus__c, UNITY_Minimum_Labor_Hours__c, UNITY_Max_Allowable_Trip_Charges__c, UNITY_2_Technicians__c,UNITY_Apprentice__c,UNITY_Multi_Technician__c,
                                                        UNITY_Holiday_Multiplier__c,UNITY_OT_Multiplier__c,UNITY_Holiday_Travel_Multiplier__c,UNITY_OT_Travel_Multiplier__c, UNITY_Default_Labor_Rate__c, UNITY_Trip_Charge__c, UNITY_Trip_Charge_Type__c, UNITY_Invoicing_Increments__c, 
                                                        (SELECT Id, UNITY_Labor_Hours__c, UNITY_Trade__c, UNITY_Trip_Charge__c, UNITY_Trip_Charge_Type__c, UNITY_Cost_Plus__c, UNITY_Labor_Cost__c, UNITY_Product__r.Id, UNTIY_Material_Cost__c, UNITY_Self_Perform_Labor_Cost__c,
                                                         UNITY_Self_Perform_Trip_Charge_Cost__c, UNITY_Self_Perform_Trip_Charge_Type__c, UNITY_Holiday_Multiplier__c,UNITY_OT_Multiplier__c,UNITY_Holiday_Travel_Multiplier__c,UNITY_OT_Travel_Multiplier__c, RecordType.DeveloperName 
                                                         FROM UNITY_Service_Contract_Line_Items__r) FROM UNITY_Service_Contract__c WHERE (Id =: currentOrder.FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__c)];
        Map<Id,UNITY_Service_Contract_Line_Item__c> menuPricingMap = new Map<Id,UNITY_Service_Contract_Line_Item__c>();
        for(UNITY_Service_Contract__c serviceContract: contractList){
            for(UNITY_Service_Contract_Line_Item__c scli: serviceContract.UNITY_Service_Contract_Line_Items__r){
                if(scli.RecordType.DeveloperName == UNITY_Constants.SCLI_MENU_PRICING_RT){
                    menuPricingMap.put(scli.UNITY_Product__r.Id,scli);
                }
            }
        }
        //Map to hold new POLIs by Suppliyer
        Map<String,List<OrderItem>> poLinesBySuppliyerMap = new Map<String,List<OrderItem>>();
        //Collenct all POLIs in a list to run an insert
        List<OrderItem> polisToInsert = new List<OrderItem>();
        //List to hold $0 lines for Vendor Supply PO
        List<OrderItem> noCostPOLIList = new List<OrderItem>();
        //Set of Suppliyer Ids
        Set<Id> suppliyerIds = new Set<Id>();
        for(OrderItem iter: currentOrderItemList){
            if(String.isBlank(iter.UNITY_Related_Menu_Price_Line__c)){
                //Check if the line product is in the menu pricing map
                Boolean isMPProd = menuPricingMap.containsKey(iter.PricebookEntry.Product2Id);
                Boolean isCPLine = iter.UNITY_Include__c;
                Boolean isVendorSource = (currentOrder.UNITY_Vendor__c == iter.UNITY_Part_Source__c);
                //Get the line product type 
                String productType = iter.PricebookEntry.Product2.UNITY_Product_Type__c;
                //Create the new OrderItem for the new PO
                OrderItem newOrderItem = iter.clone();
                //If the line is vebdor supply or contract price include or menu price 
                //or is a non-work wo and the source is the same as the vendor on the usage request...
                if(iter.UNITY_Is_Vendor_Supply__c || (isContract && isCPLine) || (isMenuPrice && isMPProd) || (isNonWork && isVendorSource)){
                    //Add to poLinesBySuppliyerMap as VENDORSUPPLY
                    if(!poLinesBySuppliyerMap.containsKey('VENDORSUPPLY'))
                            poLinesBySuppliyerMap.put('VENDORSUPPLY',new List<OrderItem>());
                        poLinesBySuppliyerMap.get('VENDORSUPPLY').add(newOrderItem);
                    suppliyerIds.add(currentOrder.UNITY_Vendor__c);
                }else{
                    //If it is a non-work wo and has a Part Source...
                    //Add to poLinesBySuppliyerMap by UNITY_Part_Source__c
                    if(isNonWork && String.isNotBlank(iter.UNITY_Part_Source__c)){
                        if(!poLinesBySuppliyerMap.containsKey(iter.UNITY_Part_Source__c))
                            poLinesBySuppliyerMap.put(iter.UNITY_Part_Source__c,new List<OrderItem>());
                        poLinesBySuppliyerMap.get(iter.UNITY_Part_Source__c).add(newOrderItem);
                        suppliyerIds.add(iter.UNITY_Part_Source__c);
                    //Otherwise, add to poLinesBySuppliyerMap as NONE (No suppliyer)
                    }else{
                        if(!poLinesBySuppliyerMap.containsKey('NONE'))
                            poLinesBySuppliyerMap.put('NONE',new List<OrderItem>());
                        poLinesBySuppliyerMap.get('NONE').add(newOrderItem);
                        if(!isNonWork){
                            //$0 Line for Vendor Suppy PO
                            OrderItem noCostPOLI = iter.clone();
                            noCostPOLI.UNITY_Cost__c = 0;
                            noCostPOLI.UNITY_Total_Cost__c = 0;
                            noCostPOLI.UNITY_Price__c = 0;
                            noCostPOLI.UNITY_Total_Price__c = 0;  
                            noCostPOLI.UNITY_Discount__c = 0;
                            noCostPOLI.UNITY_Discount_Amount__c = 0;
                            noCostPOLI.UNITY_Type__c = 'Non Billable';
                            noCostPOLI.UNITY_Not_Billable__c = true;
                            //Add to poLinesBySuppliyerMap as NOCOST
                            if(!poLinesBySuppliyerMap.containsKey('NOCOST'))
                                poLinesBySuppliyerMap.put('NOCOST',new List<OrderItem>());
                            poLinesBySuppliyerMap.get('NOCOST').add(noCostPOLI);
                            noCostPOLIList.add(noCostPOLI);
                            polisToInsert.add(noCostPOLI);
                        }
                    }
                }
                polisToInsert.add(newOrderItem);
            }
        }
        //Need to check if there are existing WO for Suppliyer in Parts Order Required status
        Map<Id,WorkOrder> workOrdersMap = 
            new Map<Id,WorkOrder>([SELECT Id,CaseId,UNITY_Assigned_Vendor__c,(SELECT Id,RecordTypeId,Status FROM FSO__Orders__r WHERE RecordTypeId = :UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE 
                                                                              AND Status = :UNITY_Constants.ORDER_STATUS_PART_ORDER_REQUIRED) 
                                   FROM WorkOrder WHERE CaseId = :currentOrder.FSO__WorkOrder__r.CaseId AND UNITY_Assigned_Vendor__c IN :suppliyerIds]);
        System.debug('#####Izay: workOrdersMap = ' + workOrdersMap);
        //Put the work order by Assigned vendor Id
        Map<String,WorkOrder> woVendorMap = new Map<String,WorkOrder>();
        for(WorkOrder wo :workOrdersMap.values()){
            woVendorMap.put(wo.UNITY_Assigned_Vendor__c,wo);
        }
        System.debug('#####Izay: poLinesBySuppliyerMap = ' + poLinesBySuppliyerMap);
        Map<String,Order> newPOs = new Map<String,Order>();//Holds the POs to be created from the usage request by Suppliyer
        Map<String,WorkOrder> newWOs = new Map<String,WorkOrder>();//Holds the WOs to be created from the usage request by Suppliyer
        Map<String,Id> oldPOs = new Map<String,Id>();
        //Iterate through each suppliyer found (VENDORSUPPLY, NONE, NOCOST, or Id)
        for(String s :poLinesBySuppliyerMap.keySet()){
            //If it is a Service WO... Expecting only VENDORSUPPLY or NONE
            if(!isNonWork){
                Order o = currentOrder.clone();//Clone the usage request
                o.pricebook2Id = standardPriceBookId;//Set the pricebookid
                o.UNITY_Originating_Usage_Request__c = currentOrder.Id;//Set the originating from usage request
                //Izay: Make the owner of the order the originating work order agent
                o.OwnerId = UserInfo.getUserId();//currentOrder.FSO__WorkOrder__r.UNITY_Agent__c;
                //If is vendor supply...
                if(s == 'VENDORSUPPLY'){
                    o.RecordTypeId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;//Set as Purchase Order record type
                    o.Status = 'Draft';//Set status to Draft
                //Otherwise, if not vendor supply...
                }else if(s == 'NONE'){
                    o.RecordTypeId = UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE;//Set record type to Part Sourcing Purchase Order
                    o.Status = UNITY_Constants.ORDER_STATUS_PART_SOURCE_NEEDED;//Set status to Part Source Needed
                    o.UNITY_Vendor__c = null;//Set vendor to null
                    o.UNITY_Vendor_Email__c = null;//Set vendor email to null
                //Otherwise, if NOCOST and there are no VENDORSUPPLY.... 
                }else if(s == 'NOCOST' && !newPOs.containsKey('VENDORSUPPLY')){
                    o.RecordTypeId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;//Set as Purchase Order record type
                    o.Status = 'Draft';//Set status to Draft
                    s = 'VENDORSUPPLY';//Set a to VENDORSUPPLY
                }else if(s == 'NOCOST'){
                    continue;
                }
                newPOs.put(s,o);//Add to newPOs map by suppliyer
            //Otherwise, it is a Non-Work WO
            }else{
                Order o = currentOrder.clone();//Clone the usage request
                o.pricebook2Id = standardPriceBookId;//Set the pricebookid
                o.UNITY_Originating_Usage_Request__c = currentOrder.Id;//Set the originating from usage request
                o.Status = UNITY_Constants.ORDER_STATUS_PART_ORDER_REQUIRED;//Set the status to Parts Order Needed
                o.RecordTypeId = UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE;//Set the record type to Part Sourcing Purchase Order
                //Izay: Make the owner of the order the originating work order agent
                o.OwnerId = UserInfo.getUserId();//currentOrder.FSO__WorkOrder__r.UNITY_Agent__c;
                if(s == 'VENDORSUPPLY'){
                    //No action needed if it is from the same source as the usage request
                }else if(s == 'NONE'){
                    //If no suppliyer... clear the vendor and vendor email
                    o.UNITY_Vendor__c = null;
                    o.UNITY_Vendor_Email__c = null;
                }else{
                    if(woVendorMap.containsKey(s)){
                        if(!woVendorMap.get(s).FSO__Orders__r.isEmpty()){
                            Id oid = woVendorMap.get(s).FSO__Orders__r.get(0).Id;
                            oldPOs.put(s,oid);
                            continue;
                        }
                    }
                    //Otherwise, a suppliyer has been identified...
                    o.UNITY_Vendor__c = s;//Set the vendor as the suppliyer
                    o.UNITY_Vendor_Email__c = null;//Clear vendor email
                    //Create WO to house the PO for the suppliyer
                    if(!woVendorMap.containsKey(s)){
                        WorkOrder wo = new WorkOrder();
                        wo.UNITY_Related_Work_Order__c = currentOrder.FSO__WorkOrder__c;
                        wo.CaseId = currentOrder.FSO__WorkOrder__r.CaseId;
                        wo.recordTypeId = UNITY_Constants.WO_NON_WORK_RECORDTYPE;
                        wo.AccountId = currentOrder.AccountId;
                        wo.UNITY_Agent__c = currentOrder.FSO__WorkOrder__r.UNITY_Agent__c;
                        wo.UNITY_Assigned_Vendor__c = s;
                        wo.UNITY_Customer__c = currentOrder.AccountId;
                        if(String.isNotBlank(currentOrder.FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__c))
                            wo.UNITY_Customer_Service_Contract__c = currentOrder.FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__c;
                        wo.UNITY_Work_Window_Begin__c = Datetime.now();
                        wo.Status = 'Parts Needed';
                        wo.City = currentOrder.ShippingCity;
                        wo.PostalCode = currentOrder.ShippingPostalCode;
                        wo.State = currentOrder.ShippingState;
                        wo.Street = currentOrder.ShippingStreet;
                        //wo.OwnerId = order.UNITY_Originating_Usage_Request__c != null ? order.UNITY_Originating_Usage_Request__r.OwnerId : order.OwnerId;
                        //Set new WO Owner as originating work order agent
                        wo.OwnerId = currentOrder.FSO__WorkOrder__r.UNITY_Agent__c;
                        newWOs.put(s,wo);//Add Work Order to map by suppliyer
                    }
                }
                newPOs.put(s,o);//Add to newPOs map by suppliyer
            }
        }
        //If it is a Non-Work WO and there are new WOs in the newWOs map...
        if(!newWOs.values().isEmpty()){
            try{
                insert newWOs.values();//Insert the new WOs
                message += 'Success: Work Order for Supplier(s) created...<br/>';
            }catch(Exception e){
                message = 'Error: ' + e.getMessage();
                result.put('success','false');
                Database.rollback(sp);
            }
        }
        //List of Work Order updated with their new POs
        List<WorkOrder> woToUpdate = new List<WorkOrder>();
        //If there are new POs in newPOs map...
        if(!newPOs.values().isEmpty()){
            try{
                if(isNonWork){
                    //For each PO created... related to a WO either existing one or new one
                    for(String s :newPOs.keySet()){
                        if(woVendorMap.containsKey(s)){
                            newPOs.get(s).FSO__WorkOrder__c = woVendorMap.get(s).Id;//Set the WO on the PO for the suppliyer
                        }else if(newWOs.containsKey(s)){
                            newPOs.get(s).FSO__WorkOrder__c = newWOs.get(s).Id;//Set the WO on the PO for the suppliyer
                        }
                    }
                }
                insert newPOs.values();//insert the new POs
                message += 'Success: Purchase Order(s) created...<br/>';
                //For each PO created... Set the PO on the WO
                for(String s :newPOs.keySet()){
                    String key = '';
                    if(s == 'NONE')
                        continue;
                    if(s == 'VENDORSUPPLY')
                        key = currentOrder.UNITY_Vendor__c;
                    if(woVendorMap.containsKey(key)){
                        //woVendorMap.get(key).UNITY_Current_PO__c = newPOs.get(s).Id;//Set the WO on the PO for the suppliyer
                        //woToUpdate.add(woVendorMap.get(key));
                    }else if(newWOs.containsKey(key)){
                        //newWOs.get(key).UNITY_Current_PO__c = newPOs.get(s).Id;//Set the WO on the PO for the suppliyer
                        //woToUpdate.add(newWOs.get(key));
                    }
                }
                System.debug('#####Izay: woToUpdate = ' + woToUpdate);
            }catch(Exception e){
                message = 'Error: ' + e.getMessage();
                result.put('success','false');
                Database.rollback(sp);
            }
        }
        //For each PO created...
        for(String s :poLinesBySuppliyerMap.keySet()){
            //Find the PO for the POLI Suppliyer (VENDORSUPPLY, NONE, NOCOST, or Id)
            if(oldPOs.containsKey(s)){
                for(OrderItem oi :poLinesBySuppliyerMap.get(s)){
                    oi.OrderId = oldPOs.get(s);//Associate the POLI to the appropriate PO
                }
            }else if(newPOs.containsKey(s)){
                for(OrderItem oi :poLinesBySuppliyerMap.get(s)){
                    oi.OrderId = newPOs.get(s).Id;//Associate the POLI to the appropriate PO
                }
            }
            if(s == 'NOCOST' && !isNonWork){
                if(newPOs.containsKey('VENDORSUPPLY')){
                    for(OrderItem oi :poLinesBySuppliyerMap.get(s)){
                        oi.OrderId = newPOs.get('VENDORSUPPLY').Id;//Associate the POLI to the appropriate PO
                    }
                }
            }
        }
        //After modifying and associating all POLIs to their respective POs...
        //Run an insert
        if(!polisToInsert.isEmpty()){
            try{
                insert polisToInsert;
                message += 'Success: Purchase Order Line Item(s) created...<br/>';
            }catch(Exception e){
                message = 'Error: ' + e.getMessage();
                result.put('success','false');
                Database.rollback(sp);
            }
        }
        //Now, Need to associate the $0 POLIs with their respective Part Sourcing POLIs
        if(!isNonWork){
            if(poLinesBySuppliyerMap.containsKey('NONE')){
                List<OrderItem> poliToUpdate = new List<OrderItem>();
                Integer i = 0;
                for(OrderItem oi :poLinesBySuppliyerMap.get('NONE')){
                    if(poLinesBySuppliyerMap.containsKey('NOCOST')){
                        OrderItem noCostPOLI = poLinesBySuppliyerMap.get('NOCOST').get(i);
                        noCostPOLI.UNITY_Related_Order_Product__c = oi.Id;
                        oi.UNITY_Related_Order_Product__c = noCostPOLI.Id;
                        poliToUpdate.add(noCostPOLI);
                        poliToUpdate.add(oi);
                        i++;
                    }
                }
                if(!poliToUpdate.isEmpty()){
                    try{
                        //update poliToUpdate;
                        updateRelatedOrderItems(JSON.serialize(poliToUpdate));
                        message += 'Success: Associated $0 Purchase Order Line Item(s) to Part Souring Purchase Order Line Item(s)...<br/>';
                    }catch(Exception e){
                        message = 'Error: ' + e.getMessage();
                        result.put('success','false');
                    }
                }
            }
            /*
            if(!woToUpdate.isEmpty()){
                try{
                    updateRelatedWOList(JSON.serialize(woToUpdate));
                }catch(Exception e){
                    Trigger.new[0].addError(e.getMessage());
                    Database.rollback(sp);
                }
            }
			*/
        }
        result.put('message',message);
        return result;
    }
    @RemoteAction
    public static Boolean updateUsageRequestStatus(String urId,String status){
        Boolean success = false;
        setCurrentOrder(urId);
        currentOrder.status = status;
        try{
            update currentOrder;
            success = true;
        }catch(Exception e){
            success = false;
        }
        return success;
    }
    /////////////////////////////////////////////////////////////////////////////////////
    /**This method creates Purchase Order(s) from an usage request that didn't exceed NTE
     * */
    /* ************************************************* 
     * DEPRECATED BY: IZAY
     * This is the old code to Split Part Sourcing POs
     ***************************************************
    public static void createPurchaseOrders(){
        //get the service contract subtype
        String scSub = currentOrder.FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__r.UNITY_Contract_Sub_type__c;
        Boolean isContract = (scSub == 'Contract Pricing' && currentOrder.FSO__WorkOrder__r.UNITY_Include__c);
        Boolean isMenuPrice = (scSub == 'Menu Pricing' && currentOrder.FSO__WorkOrder__r.UNITY_Use_Menu_Pricing__c);
        Boolean isNonWork = (currentOrder.FSO__WorkOrder__r.RecordTypeId == UNITY_Constants.WO_NON_WORK_RECORDTYPE);
        //get the customer service contract to find menu priced lines
        List<UNITY_Service_Contract__c> contractList = [SELECT Id, UNITY_Account__r.RecordTypeId, UNITY_Is_Pass_Through__c, UNITY_Cost_Plus__c, UNITY_Minimum_Labor_Hours__c, UNITY_Max_Allowable_Trip_Charges__c, UNITY_2_Technicians__c,UNITY_Apprentice__c,UNITY_Multi_Technician__c,
                                                        UNITY_Holiday_Multiplier__c,UNITY_OT_Multiplier__c,UNITY_Holiday_Travel_Multiplier__c,UNITY_OT_Travel_Multiplier__c, UNITY_Default_Labor_Rate__c, UNITY_Trip_Charge__c, UNITY_Trip_Charge_Type__c, UNITY_Invoicing_Increments__c, 
                                                        (SELECT Id, UNITY_Labor_Hours__c, UNITY_Trade__c, UNITY_Trip_Charge__c, UNITY_Trip_Charge_Type__c, UNITY_Cost_Plus__c, UNITY_Labor_Cost__c, UNITY_Product__r.Id, UNTIY_Material_Cost__c, UNITY_Self_Perform_Labor_Cost__c,
                                                         UNITY_Self_Perform_Trip_Charge_Cost__c, UNITY_Self_Perform_Trip_Charge_Type__c, UNITY_Holiday_Multiplier__c,UNITY_OT_Multiplier__c,UNITY_Holiday_Travel_Multiplier__c,UNITY_OT_Travel_Multiplier__c, RecordType.DeveloperName 
                                                         FROM UNITY_Service_Contract_Line_Items__r) FROM UNITY_Service_Contract__c WHERE (Id =: currentOrder.FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__c)];
        Map<Id,UNITY_Service_Contract_Line_Item__c> menuPricingMap = new Map<Id,UNITY_Service_Contract_Line_Item__c>();
        for(UNITY_Service_Contract__c serviceContract: contractList){
            for(UNITY_Service_Contract_Line_Item__c scli: serviceContract.UNITY_Service_Contract_Line_Items__r){
                if(scli.RecordType.DeveloperName == UNITY_Constants.SCLI_MENU_PRICING_RT){
                    menuPricingMap.put(scli.UNITY_Product__r.Id,scli);
                }
            }
        }
        
        List<OrderItem> noCostOrderItemList = new List<OrderItem>();
        
        vendorSupplyOrderItemList = new List<OrderItem>();
        noVendorSupplyOrderItemList = new List<OrderItem>();
        
        for(OrderItem iter: currentOrderItemList){
            //Check if the line product is in the menu pricing map
            Boolean isMPProd = menuPricingMap.containsKey(iter.PricebookEntry.Product2Id);
            Boolean isCPLine = iter.UNITY_Include__c;
            Boolean isVendorSource = (currentOrder.UNITY_Vendor__c == iter.UNITY_Part_Source__c);
            //Get the line product type 
            String productType = iter.PricebookEntry.Product2.UNITY_Product_Type__c;
            
            OrderItem newOrderItem = iter.clone();
            
            if (iter.UNITY_Is_Vendor_Supply__c || (isContract && isCPLine) || (isMenuPrice && isMPProd) || (isNonWork && isVendorSource)){
                vendorSupplyOrderItemList.add(newOrderItem);
            }else{
                noVendorSupplyOrderItemList.add(newOrderItem);
                //add $0 to vendor PO if not a Non Work WO
                if(!isNonWork){
                    OrderItem noCostOrderItem = iter.clone();
                    
                    noCostOrderItem.UNITY_Cost__c = 0;
                    noCostOrderItem.UNITY_Total_Cost__c = 0;
                    noCostOrderItem.UNITY_Price__c = 0;
                    noCostOrderItem.UNITY_Total_Price__c = 0;  
                    noCostOrderItem.UNITY_Type__c = 'Non Billable';
                    
                    vendorSupplyOrderItemList.add(noCostOrderItem);
                    
                    noCostOrderItemList.add(noCostOrderItem);
                }
            }
        }
        
        System.debug('#vendorSupplyOrderItemList '+vendorSupplyOrderItemList);
        System.debug('#noVendorSupplyOrderItemList '+noVendorSupplyOrderItemList);
        
        createPurchaseOrder(vendorSupplyOrderItemList, 'Draft', isNonWork);
        createPurchaseOrder(noVendorSupplyOrderItemList, UNITY_Constants.ORDER_STATUS_PART_SOURCE_NEEDED, isNonWork);
        
        List<OrderItem> poliToUpdate = new List<OrderItem>();
        
        for(Integer i=0; i < noVendorSupplyOrderItemList.size(); i++){
            
            if(noCostOrderItemList.size() > i){
                OrderItem noVendorSupplyPOLI = noVendorSupplyOrderItemList.get(i);
                OrderItem noCostPOLI = noCostOrderItemList.get(i);
                noCostPOLI.UNITY_Related_Order_Product__c = noVendorSupplyPOLI.Id;
                noVendorSupplyPOLI.UNITY_Related_Order_Product__c = noCostPOLI.Id;
                poliToUpdate.add(noVendorSupplyPOLI);
                poliToUpdate.add(noCostPOLI);
            }
            
        }
        
        update poliToUpdate;
    }
	*/
    /************************************
     *** CREATE PO FROM USAGE REQUEST ***
	 ************************************ */
    /* ************************************************* 
     * DEPRECATED BY: IZAY
     * This is the old code to Split Part Sourcing POs
     ***************************************************
    public static void createPurchaseOrder(List<OrderItem> orderItems, String status, Boolean isNonWork){
        if (!orderItems.isEmpty()){
            //Set to collect order ids for tax callout
            Set<Id> needTax = new Set<Id>();
            List<OrderItem> toInsertOI = new List<OrderItem>();
            List<Order> toInsertNW = new List<Order>();
            Order purchaseOrder = currentOrder.clone();
            
            purchaseOrder.pricebook2Id = standardPriceBookId;
            purchaseOrder.Status = status;
            purchaseOrder.UNITY_Originating_Usage_Request__c = currentOrder.Id;
            
            if(status == UNITY_Constants.ORDER_STATUS_PART_SOURCE_NEEDED){
                if(isNonWork){
                    purchaseOrder = null;
                    //CHECK FOR MULTIPLE SUPPLIYERS
                    //****************************************************************************************
                    //*** The Part Source on the Line is different from the Suppliyer on the Usage Request ***
                    //****************************************************************************************
                    Map<Id,List<OrderItem>> suppliyerLines = new Map<Id,List<OrderItem>>();
                    //Need to separate the different suppliyers...
                    for(OrderItem oi :orderItems){
                        if(!suppliyerLines.containsKey(oi.UNITY_Part_Source__c))
                            suppliyerLines.put(oi.UNITY_Part_Source__c,new List<OrderItem>());
                        suppliyerLines.get(oi.UNITY_Part_Source__c).add(oi);
                    }
                    //Need to create a PO per Suppliyer....
                    Map<Id,Order> multiSuppliyerOrders = new Map<Id,Order>();
                    //Need to create a Non-Work Work Order per PO...
                    Map<Id,WorkOrder> multiSuppliyerWOs = new Map<Id,WorkOrder>();
                    for(Id id :suppliyerLines.keySet()){
                        //Create PO
                        Order o = currentOrder.clone();
                        o.pricebook2Id = standardPriceBookId;
                        o.UNITY_Originating_Usage_Request__c = currentOrder.Id;
                        o.RecordTypeId = UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE;
                    	o.Status = UNITY_Constants.ORDER_STATUS_PART_ORDER_REQUIRED;
                        o.UNITY_Vendor__c = id;
                        multiSuppliyerOrders.put(id,o);//Add order to map by vendor
                        //Create WO
                        WorkOrder wo = new WorkOrder();
                        //wo.UNITY_Assigned_Vendor__c = id;
                        wo.UNITY_Related_Work_Order__c = currentOrder.FSO__WorkOrder__c;
                        wo.CaseId = currentOrder.FSO__WorkOrder__r.CaseId;
                        wo.recordTypeId = UNITY_Constants.WO_NON_WORK_RECORDTYPE;
                        wo.AccountId = currentOrder.AccountId;
                        wo.UNITY_Customer__c = currentOrder.AccountId;
                        wo.UNITY_Work_Window_Begin__c = Datetime.now();
                        wo.Status = 'Parts Needed';
                        wo.City = currentOrder.ShippingCity;
                        wo.PostalCode = currentOrder.ShippingPostalCode;
                        wo.State = currentOrder.ShippingState;
                        wo.Street = currentOrder.ShippingStreet;
                        multiSuppliyerWOs.put(id,wo);//Add Work Order to map by vendor
                    }
                    //Insert WO(s) for vendor(s)
                    if(!multiSuppliyerWOs.values().isEmpty())
                    	insert multiSuppliyerWOs.values();
                    //Insert Order(s) for vendor(s)
                    if(!multiSuppliyerOrders.values().isEmpty()){
                        for(Order o :multiSuppliyerOrders.values()){
                            //Associate Order to WOrk Order based on vendor
                            System.debug('#####Izay: multiSuppliyerWOs.keySet() = ' + multiSuppliyerWOs.keySet());
                            System.debug('#####Izay: o.UNITY_Vendor__c = ' + o.UNITY_Vendor__c);
                            if(multiSuppliyerWOs.containsKey(o.UNITY_Vendor__c))
                                o.FSO__WorkOrder__c = multiSuppliyerWOs.get(o.UNITY_Vendor__c).Id;
                        }
                        insert multiSuppliyerOrders.values();
                        //Iterate through Orders...
                        for(Order o :multiSuppliyerOrders.values()){
                            needTax.add(o.Id);
                            //Associate POLIs to Order based on vendor
                            if(suppliyerLines.containsKey(o.UNITY_Vendor__c))
                                for(OrderItem oi :suppliyerLines.get(o.UNITY_Vendor__c)){
                                    oi.OrderId = o.Id;
                                    toInsertOI.add(oi);//Add POLI to insert list
                                }
                        }
                        updateOrderFromMultiSource(JSON.serialize(multiSuppliyerOrders.values()));
                    }
                }else{
                    purchaseOrder.UNITY_Vendor__c = null;
                    purchaseOrder.UNITY_Vendor_Email__c = null;
                    purchaseOrder.RecordTypeId = UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE;
                }
            }else{
                if(isNonWork){
                    purchaseOrder.RecordTypeId = UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE;
                    purchaseOrder.Status = UNITY_Constants.ORDER_STATUS_PART_ORDER_REQUIRED;
                }
                else
                    purchaseOrder.RecordTypeId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;
            }
            if(purchaseOrder != null){
                insert purchaseOrder;
            
                for (OrderItem iter: orderItems){
                    iter.OrderId = purchaseOrder.Id;
                    toInsertOI.add(iter);
                }
            }
            	
            System.debug('#orderItems '+orderItems);
            
            if(!toInsertOI.isEmpty())
            	insertOrderItemsFromMultiSource(JSON.serialize(toInsertOI));
            if(!needTax.isEmpty())
                callTaxFromMultiSource(needTax);
        }
    }
    
    @future
    public static void updateOrderFromMultiSource(String orderList){
        UNITY_Constants.isExecutingContext('UNITY_UsageRequest.updateOrderFromMultiSource');
        List<Order> deserializedOrder = (List<Order>)JSON.deserialize(orderList, List<Order>.class);
        update deserializedOrder;
    }
    
    @future
    public static void insertOrderItemsFromMultiSource(String orderItemList){
        UNITY_Constants.isExecutingContext('UNITY_UsageRequest.insertOrderItemsFromMultiSource');
        List<OrderItem> oLines = (List<OrderItem>)JSON.deserialize(orderItemList, List<OrderItem>.class);
        insert oLines;
    }
    
    @future(callout=true)
    public static void callTaxFromMultiSource(Set<Id> oids){
        UNITY_Constants.isExecutingContext('UNITY_UsageRequest.callTaxFromMultiSource');
        System.debug('#####Izay: In callTaxFromMultiSource');
        System.debug('#####Izay: Calling UNITY_CallAvatax.getTaxPO(oids)');
        System.debug('#####Izay: oids = ' + oids);
        UNITY_CallAvatax.AvataxResult taxResult = UNITY_CallAvatax.getTaxPO(oids);
    }
    */
    public static UNITY_Proposal__c createQuote(){
        
        laborAndTravelLines = new List<OrderItem>();
        partLines = new List<OrderItem>();
        allOtherLines = new List<OrderItem>();
        
        for (OrderItem iter: currentOrderItemList){
            
            String productType = iter.PricebookEntry.Product2.UNITY_Product_Type__c;
            
            //OrderItem newOrderItem = iter.clone();
            
            if (productType == 'Labor' || productType == 'Travel'){
                //laborAndTravelLines.add(iter.clone());
                laborAndTravelLines.add(iter);
            }
            else if (productType == 'Part'){
                //partLines.add(iter.clone());
                partLines.add(iter);
            }else {
                allOtherLines.add(iter);
            }
        }
        
        System.debug('#laborAndTravelLines '+laborAndTravelLines);
        System.debug('#partLines '+partLines);
        System.debug('#allOtherLines '+allOtherLines);
        
        UNITY_Proposal__c newQuote = new UNITY_Proposal__c();
        
        newQuote.UNITY_Originating_Usage_Request__c = currentOrder.Id;
        newQuote.UNITY_Account__c = currentOrder.AccountId;
        newQuote.UNITY_Business_Unit_Account__c = currentOrder.UNITY_Business_Unit_Account__c;
        newQuote.UNITY_Effective_Till_Date__c = currentOrder.EffectiveDate;
        newQuote.UNITY_Work_Order__c = currentOrder.FSO__WorkOrder__c;
        newQuote.UNITY_Customer_Margin__c = currentOrder.FSO__WorkOrder__r.UNITY_Customer_Margin__c ;
        newQuote.UNITY_Proposal_Status__c = UNITY_Constants.QT_STATUS_QUOTE_CREATION;       
        newQuote.UNITY_Agent__c = currentOrder.FSO__WorkOrder__r.UNITY_Agent__c; 
        newQuote.UNITY_Customer__c = currentOrder.FSO__WorkOrder__r.UNITY_Customer__c;
        newQuote.UNITY_Customer_Email__c = currentOrder.FSO__WorkOrder__r.UNITY_Customer__r.Account_Email__c;
        newQuote.UNITY_Discount__c = currentOrder.UNITY_Discount__c;
        newQuote.UNITY_Discount_Amount__c = currentOrder.UNITY_Discount_Amount__c;
        newQuote.UNITY_Business_Unit__c = currentOrder.UNITY_Business_Unit__c;
        newQuote.UNITY_Vendor__c = currentOrder.UNITY_Vendor__c;
        newQuote.UNITY_Case__c = currentOrder.FSO__WorkOrder__r.CaseId;
        newQuote.UNITY_Quote_Comments__c = currentOrder.Description;
        //newQuote.UNITY_Vendor_Email__c = currentOrder.UNITY_Vendor_Email__c;
        
        //newQuote.UNITY_Service_Charge__c = currentOrder.UNITY_Vendor__c;
        //newQuote.UNITY_Total_Price_With_Service_Charge__c = currentOrder.UNITY_Total_Price_With_Service_Charge__c;
        
        System.debug('#newQuote '+newQuote);
        
        insert newQuote;
        
        List<UNITY_Proposal_Line_Item__c> newProposalLineItems = new List<UNITY_Proposal_Line_Item__c>();
        
        newProposalLineItems.addAll(createQuoteLineItems(newQuote.Id, laborAndTravelLines));
        newProposalLineItems.addAll(createQuoteLineItems(newQuote.Id, partLines));
        newProposalLineItems.addAll(createQuoteLineItems(newQuote.Id, allOtherLines));
        
        insert newProposalLineItems;
        
        return newQuote;
    }
    
    public static List<UNITY_Proposal_Line_Item__c> createQuoteLineItems(Id newQuoteId, List<OrderItem> orderItemList){
        
        List<UNITY_Proposal_Line_Item__c> quoteLineItems = new List<UNITY_Proposal_Line_Item__c>();
        
        for (OrderItem iter: orderItemList){
            if(String.isBlank(iter.UNITY_Related_Menu_Price_Line__c)){
                UNITY_Proposal_Line_Item__c newQuoteLineItem = new UNITY_Proposal_Line_Item__c();
                if(currentOrder.FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__r.UNITY_Contract_Sub_type__c == 'Contract Pricing' || 
                   currentOrder.FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__r.UNITY_Contract_Sub_type__c == 'Menu Pricing'){
                       newQuoteLineItem.UNITY_Total_Cost__c = iter.UNITY_Total_Cost__c;
                       newQuoteLineItem.UNITY_Total_Price__c = iter.UNITY_Total_Price__c;
                       newQuoteLineItem.UNITY_Price__c = iter.UNITY_Price__c;
                   }
                //newQuoteLineItem.UNITY_Total_Cost__c = iter.UNITY_Total_Cost__c;
                //newQuoteLineItem.UNITY_Total_Price__c = iter.UNITY_Total_Price__c;
                //newQuoteLineItem.UNITY_Price__c = iter.UNITY_Price__c;
                System.debug(LoggingLevel.INFO,'<AK> : iter.UNITY_Cost__c : '+iter.UNITY_Cost__c);
                newQuoteLineItem.UNITY_Cost__c = iter.UNITY_Cost__c;
                System.debug(LoggingLevel.INFO,'<AK> : newQuoteLineItem.UNITY_Cost__c : '+newQuoteLineItem.UNITY_Cost__c);
                newQuoteLineItem.UNITY_Discount__c = iter.UNITY_Discount__c;
                newQuoteLineItem.UNITY_Discount_Amount__c = iter.UNITY_Discount_Amount__c;
                
                //Nat: propagate Multiplier fields
                newQuoteLineItem.UNITY_Customer_Holiday_Multiplier__c = iter.UNITY_Customer_Holiday_Multiplier__c;
                newQuoteLineItem.UNITY_Customer_OT_Multiplier__c = iter.UNITY_Customer_OT_Multiplier__c;
                newQuoteLineItem.UNITY_Vendor_Holiday_Multiplier__c = iter.UNITY_Vendor_Holiday_Multiplier__c;
                newQuoteLineItem.UNITY_Vendor_OT_Multiplier__c = iter.UNITY_Vendor_OT_Multiplier__c;
                
                newQuoteLineItem.UNITY_Proposal__c = newQuoteId;
                newQuoteLineItem.UNITY_Product__c = iter.PricebookEntry.Product2Id;
                newQuoteLineItem.UNITY_PriceBook_Entry_Id__c = (String)iter.PricebookEntry.Id;
                newQuoteLineItem.UNITY_Type__c = iter.UNITY_Type__c;
                newQuoteLineItem.UNITY_Activity_Type__c = iter.UNITY_Activity_Type__c;
               
                newQuoteLineItem.UNITY_Quantity__c = iter.Quantity;
                newQuoteLineItem.UNITY_Vendor_Adjusted_Quantity__c = iter.UNITY_Vendor_Adjusted_Quantity__c;
                newQuoteLineItem.UNITY_Customer_Adjusted_Quantity__c = iter.UNITY_Customer_Adjusted_Quantity__c;
                
                newQuoteLineItem.UNITY_Is_Vendor_Supply__c = iter.UNITY_Is_Vendor_Supply__c;
                newQuoteLineItem.UNITY_Number_of_Techs__c = iter.UNITY_Number_of_Techs__c;
                
                //Izay: propagate unknown/special order part info
                newQuoteLineItem.UNITY_Make__c = iter.UNITY_Make__c;
                newQuoteLineItem.UNITY_Model__c = iter.UNITY_Model__c;
                newQuoteLineItem.UNITY_Description__c = iter.Description;
                newQuoteLineItem.UNITY_Unit_of_Measure__c = iter.UNITY_Unit_of_Measure__c;
                
                newQuoteLineItem.UNITY_Part_Source__c = iter.UNITY_Part_Source__c;   
                newQuoteLineItem.UNITY_Part_On_Hand__c = iter.UNITY_Part_On_Hand__c; 
                newQuoteLineItem.UNITY_Part_Location__c = iter.UNITY_Part_Location__c;
                newQuoteLineItem.UNITY_MP_Labor_Vendor_Adjusted_Qty__c = iter.UNITY_MP_Labor_Vendor_Adjusted_Qty__c;
                newQuoteLineItem.UNITY_MP_Labor_Cost__c = iter.UNITY_MP_Labor_Cost__c;
                newQuoteLineItem.UNITY_Not_Billable__c = iter.UNITY_Not_Billable__c;
                
                //Izay: include fields for intercompany transfer
                newQuoteLineItem.MSPFS_MSP_Cost__c = iter.MSPFS_MSP_Cost__c;
                newQuoteLineItem.MSPFS_MSP_Price__c = iter.MSPFS_MSP_Price__c;
                newQuoteLineItem.MSPFS_Technician__c = iter.MSPFS_Technician__c;
                newQuoteLineItem.MSPFS_Technician2__c = iter.MSPFS_Technician2__c;

                quoteLineItems.add(newQuoteLineItem);
            }
                
        }
        
        return quoteLineItems;
    }
    
    /*
    public static void relateOrderItemToWorkOrder(OrderItem orderItem){
        
        Order relatedOrder = [select id, FSO__WorkOrder__c from Order where id=:orderItem.OrderId];
        
        WorkOrder relatedWorkOrder = [select id, UNITY_Assigned_Vendor__c, CaseId, UNITY_Current_PO__c from WorkOrder where id=: relatedOrder.FSO__WorkOrder__c];
        
        Id assignedVendor = relatedWorkOrder.UNITY_Assigned_Vendor__c;
        
        //GET WO Miner or OEM
        
        if (assignedVendor != null){
            
            if (assignedVendor != orderItem.UNITY_Part_Source__c){
                
                //check if work order already exist for that source
                List<WorkOrder> workOrderList = [select id from WorkOrder where UNITY_Assigned_Vendor__c=:orderItem.UNITY_Part_Source__c];
                
                //the work order already exist
                if (!workOrderList.isEmpty()){
                    
                    Order purchaseOrder = [select id from Order where FSO__WorkOrder__c =: workOrderList.get(0).Id];
                    
                    OrderItem newOrderItem = orderItem.clone();
                    newOrderItem.OrderId = purchaseOrder.Id; 
                    
                    insert newOrderItem;
                }
                else{
                    
                    //create WO
                    WorkOrder newWorkOrder = new WorkOrder();
                    
                    newWorkOrder.UNITY_Assigned_Vendor__c = orderItem.UNITY_Part_Source__c;
                    newWorkOrder.CaseId = relatedWorkOrder.CaseId;
                    
                    insert newWorkOrder;
                    
                    //createPO
                    Order newOrder = new Order();
                    
                    newOrder.RecordTypeId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;
                    
                    newOrder.FSO__WorkOrder__c  = newWorkOrder.Id;    
                    
                    insert newOrder;
                    
                    OrderItem newOrderItem = orderItem.clone();
                    newOrderItem.OrderId = relatedOrder.Id; 
                    
                    insert newOrderItem;
                }
            }
        }
    }
	*/
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /**This method creates Purchase Order(s) from a Part Sourcing PO that has beed se to Parts Source Identified
     * @param order - List<Order>: Orders that match criteria
     * */
    public static void processUsageRequestPartVendorIdentified(List<Order> orders){
        //System.debug('#####Izay: In processUsageRequestPartVendorIdentified...');
        //System.debug('#####Izay: orders = ' + orders);
        //Set to hold order Ids
        Set<Id> oids = new Set<Id>();
        for(Order o :orders){
            oids.add(o.Id);
        }
        orders = [select id,UNITY_Discount__c,UNITY_Discount_Amount__c,UNITY_Business_Unit__c,UNITY_Vendor__c,FSO__WorkOrder__r.CaseId,FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__c,UNITY_Customer__r.MH_SL_CustID__c,UNITY_Customer__r.UNITY_Bill_to_Account__r.MH_SL_CustID__c,
                  FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__r.UNITY_Is_Pass_Through__c,FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__r.UNITY_Contract_Sub_type__c,FSO__WorkOrder__r.UNITY_Customer__r.Account_Email__c,FSO__WorkOrder__r.UNITY_Agent__c,FSO__WorkOrder__r.UNITY_Customer_Margin__c,
                  FSO__WorkOrder__r.UNITY_Customer__c,UNITY_NTE_Exceeded__c,UNITY_Total_Amount__c,UNITY_Business_Unit_Account__c,Status,FSO__WorkOrder__c,UNITY_Total_Cost__c,AccountId,EffectiveDate,FSO__WorkOrder__r.RecordTypeId,
                  Description,UNITY_Shipping_Method__c,UNITY_Shipping_Provider__c,UNITY_Ship_To_Account__c,ShipToContactId,UNITY_Parts_Needed_By__c,UNITY_Expected_Arrival_Date__c,FSO__WorkOrder__r.UNITY_Use_Menu_Pricing__c,FSO__WorkOrder__r.UNITY_Include__c,
                  ShippingStreet,ShippingCity,ShippingState,ShippingStateCode,ShippingPostalCode,ShippingCountry, ShippingCountryCode, UNITY_Actual_Arrival_Date__c,UNITY_Tracking_Number__c,UNITY_Originating_Usage_Request__c,UNITY_Originating_Usage_Request__r.OwnerId,OwnerId
                  FROM Order WHERE Id IN :oids];
        //Set to hold the related $0 line ids
        Set<Id> relatedLineIds = new Set<Id>();
        //Map to hold the order items by order id
        Map<Id,List<OrderItem>> oLinesMap = new Map<Id,List<OrderItem>>();
        //Get all the lines for all the Orders
        List<OrderItem> oLines = [SELECT Id,OrderId,UNITY_Discount__c,UNITY_Discount_Amount__c,UNITY_Discounted_Price__c,UNITY_Vendor_Adjusted_Quantity__c,UNITY_Customer_Adjusted_Quantity__c,UNITY_Cost__c,UNITY_Total_Cost__c,UNITY_Total_Price__c,
                                  UNITY_Activity_Type__c,UNITY_Type__c,UNITY_Vendor_Holiday_Multiplier__c,UNITY_Vendor_OT_Multiplier__c,UNITY_Customer_Holiday_Multiplier__c,UNITY_Customer_OT_Multiplier__c,UNITY_Number_of_Techs__c,UNITY_Related_Order_Product__c,
                                  UNITY_Price__c,PricebookEntryId,Quantity,UnitPrice,PricebookEntry.Id,PricebookEntry.Product2Id,PricebookEntry.Product2.UNITY_Product_Type__c,UNITY_Is_Vendor_Supply__c,UNITY_Part_On_Hand__c,UNITY_Include__c,
                                  UNITY_Part_Source__c,UNITY_Part_Location__c,UNITY_Make__c,UNITY_Model__c,Description,UNITY_Unit_of_Measure__c,UNITY_Sales_Tax__c FROM OrderItem WHERE OrderId IN :oids];
        //For each order item
        for(OrderItem line :oLines){
            //Add the related $0 line id to the relatedLineIds set
            relatedLineIds.add(line.UNITY_Related_Order_Product__c);
            //Put the order item in the orderLinesmap by its order id
            if(!oLinesMap.containsKey(line.OrderId))
                oLinesMap.put(line.OrderId,new List<OrderItem>());
            oLinesMap.get(line.OrderId).add(line);
        }
        //Get the related lines in a map by id
        Map<Id,OrderItem> relatedLinesMap = new Map<Id,OrderItem>([SELECT Id,UNITY_Discount__c,UNITY_Discount_Amount__c,UNITY_Discounted_Price__c,UNITY_Vendor_Adjusted_Quantity__c,UNITY_Customer_Adjusted_Quantity__c,UNITY_Cost__c,UNITY_Total_Cost__c,UNITY_Total_Price__c,
                                  UNITY_Activity_Type__c,UNITY_Type__c,UNITY_Vendor_Holiday_Multiplier__c,UNITY_Vendor_OT_Multiplier__c,UNITY_Customer_Holiday_Multiplier__c,UNITY_Customer_OT_Multiplier__c,UNITY_Number_of_Techs__c,UNITY_Related_Order_Product__c,
                                  UNITY_Price__c,PricebookEntryId,Quantity,UnitPrice,PricebookEntry.Id,PricebookEntry.Product2Id,PricebookEntry.Product2.UNITY_Product_Type__c,UNITY_Is_Vendor_Supply__c,UNITY_Part_On_Hand__c,UNITY_Include__c,
                                  UNITY_Part_Source__c,UNITY_Part_Location__c,UNITY_Make__c,UNITY_Model__c,Description,UNITY_Unit_of_Measure__c,UNITY_Sales_Tax__c FROM OrderItem WHERE Id IN :relatedLineIds]);
        //Collenct all POLIs in a list to run an insert
        List<OrderItem> polisToInsert = new List<OrderItem>();
        Set<Id> caseIds = new Set<Id>();
        Set<Id> suppliyerIds = new Set<Id>();
        Map<Id,Map<String,List<OrderItem>>> orderLinesMap = new Map<Id,Map<String,List<OrderItem>>>();
        for(Order o :orders){
            //Map to hold new POLIs by Suppliyer
            Map<String,List<OrderItem>> poLinesBySuppliyerMap = new Map<String,List<OrderItem>>();
            //Set of Suppliyer Ids
            for(OrderItem iter: oLinesMap.get(o.Id)){
                //Create the new OrderItem for the new PO
                OrderItem newOrderItem = iter.clone();
                //Put the newOrderItem in the poLinesBySuppliyerMap by Suppliyer Id
                if(!poLinesBySuppliyerMap.containsKey(iter.UNITY_Part_Source__c))
                    poLinesBySuppliyerMap.put(iter.UNITY_Part_Source__c,new List<OrderItem>());
                poLinesBySuppliyerMap.get(iter.UNITY_Part_Source__c).add(newOrderItem);
                //Add the suppliyer Id to suppliyerIds
                suppliyerIds.add(iter.UNITY_Part_Source__c);
                //Add newOrderItem to polisToInsert
                polisToInsert.add(newOrderItem);
            }
            orderLinesMap.put(o.Id,poLinesBySuppliyerMap);
            caseIds.add(o.FSO__WorkOrder__r.CaseId);
        }
        //Need to check if there are existing WO for Suppliyer in Parts Order Required status
        Map<Id,WorkOrder> workOrdersMap = 
            new Map<Id,WorkOrder>([SELECT Id,CaseId,UNITY_Assigned_Vendor__c,(SELECT Id,RecordTypeId,Status FROM FSO__Orders__r WHERE RecordTypeId = :UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE 
                                                                              AND Status = :UNITY_Constants.ORDER_STATUS_PART_ORDER_REQUIRED) 
                                   FROM WorkOrder WHERE CaseId IN :caseIds AND UNITY_Assigned_Vendor__c IN :suppliyerIds]);
        //Put the work order by Assigned vendor Id
        Map<Id,WorkOrder> woVendorMap = new Map<Id,WorkOrder>();
        for(WorkOrder wo :workOrdersMap.values()){
            woVendorMap.put(wo.UNITY_Assigned_Vendor__c,wo);
        }
        Map<String,Order> newPOs = new Map<String,Order>();//Holds the POs to be created from the usage request by Suppliyer
        Map<String,WorkOrder> newWOs = new Map<String,WorkOrder>();//Holds the WOs to be created from the usage request by Suppliyer
        Map<String,Id> oldPOs = new Map<String,Id>();
        //Iterate through all order
		//System.debug('#####Izay: orderLinesMap = ' + JSON.serializePretty(orderLinesMap));
        //System.debug('#####Izay: woVendorMap = ' + JSON.serializePretty(woVendorMap));
        for(Order order :orders){
            //Iterate through each suppliyer found (VENDORSUPPLY, NONE, NOCOST, or Id)
        	for(String s :orderLinesMap.get(order.Id).keySet()){
                Order o = order.clone();//Clone the usage request
                o.pricebook2Id = standardPriceBookId;//Set the pricebookid
                o.UNITY_Originating_Usage_Request__c = order.UNITY_Originating_Usage_Request__c;//Set the originating from usage request
                o.Status = UNITY_Constants.ORDER_STATUS_PART_ORDER_REQUIRED;//Set the status to Parts Order Needed
                o.RecordTypeId = UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE;//Set the record type to Part Sourcing Purchase Order
                //Izay: Make the owner of the order the current user
                //o.OwnerId = UserInfo.getUserId();
                //Izay: Make the owner of the order the originating work order agent
                o.OwnerId = order.FSO__WorkOrder__r.UNITY_Agent__c;
                if(woVendorMap.containsKey(s)){
                    if(!woVendorMap.get(s).FSO__Orders__r.isEmpty()){
                        Id oid = woVendorMap.get(s).FSO__Orders__r.get(0).Id;
                        oldPOs.put(s,oid);
                        continue;
                    }
                }
                //Otherwise, a suppliyer has been identified...
                o.UNITY_Vendor__c = s;//Set the vendor as the suppliyer
                o.UNITY_Vendor_Email__c = null;//Clear vendor email
                newPOs.put(s,o);//Add to newPOs map by suppliyer
                //Create WO to house the PO for the suppliyer
                if(!woVendorMap.containsKey(s)){
                	WorkOrder wo = new WorkOrder();
                    wo.UNITY_Related_Work_Order__c = order.FSO__WorkOrder__c;
                    wo.CaseId = order.FSO__WorkOrder__r.CaseId;
                    wo.recordTypeId = UNITY_Constants.WO_NON_WORK_RECORDTYPE;
                    wo.AccountId = order.AccountId;
                    wo.UNITY_Agent__c = order.FSO__WorkOrder__r.UNITY_Agent__c;
                    wo.UNITY_Assigned_Vendor__c = s;
                    wo.UNITY_Customer__c = order.AccountId;
                    if(String.isNotBlank(order.FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__c))
                        wo.UNITY_Customer_Service_Contract__c = order.FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__c;
                    wo.UNITY_Work_Window_Begin__c = Datetime.now();
                    wo.Status = 'Parts Needed';
                    wo.City = order.ShippingCity;
                    wo.PostalCode = order.ShippingPostalCode;
                    wo.State = order.ShippingState;
                    wo.Street = order.ShippingStreet;
                    wo.Country = order.ShippingCountry;
                    //wo.OwnerId = order.UNITY_Originating_Usage_Request__c != null ? order.UNITY_Originating_Usage_Request__r.OwnerId : order.OwnerId;
                    //Set new WO Owner as logged in user
                    //wo.OwnerId = UserInfo.getUserId();
                    //Izay: Make the owner of the work order the originating work order agent
                	wo.OwnerId = order.FSO__WorkOrder__r.UNITY_Agent__c;
                    newWOs.put(s,wo);//Add Work Order to map by suppliyer
                }
            }
        }
        //System.debug('#####Izay: newWOs = ' + JSON.serializePretty(newWOs));
        //System.debug('#####Izay: newPOs = ' + JSON.serializePretty(newPOs));
        //If it is a Non-Work WO and there are new WOs in the newWOs map...
        //System.debug('#####Izay: !newWOs.values().isEmpty() = ' + JSON.serializePretty(!newWOs.values().isEmpty()));
        if(!newWOs.values().isEmpty()){
            try{
                insert newWOs.values();//Insert the new WOs
            }catch(Exception e){
                Trigger.new[0].addError(e.getMessage());
            }
            /*
            //For each WO created...
            for(String s :newWOs.keySet()){
                //Find the PO created for the suppliyer...
                if(newPOs.containsKey(s)){
                    newPOs.get(s).FSO__WorkOrder__c = newWOs.get(s).Id;//Set the WO on the PO for the suppliyer
                }
            }
            */
        }
        //System.debug('#####Izay: newWOs after inser = ' + JSON.serializePretty(newWOs));
        //List of work orders to update
        List<WorkOrder> woToUpdate = new List<WorkOrder>();
        //If there are new POs in newPOs map...
        if(!newPOs.values().isEmpty()){
            try{
                //For each newPOs created...
                for(String s :newPOs.keySet()){
                    if(woVendorMap.containsKey(s)){
                        System.debug('#####Izay: Assigning Wo to PO... WO = ' + JSON.serializePretty(woVendorMap.get(s)));
                        newPOs.get(s).FSO__WorkOrder__c = woVendorMap.get(s).Id;//Set the WO on the PO for the suppliyer
                    }else if(newWOs.containsKey(s)){
                        System.debug('#####Izay: Assigning Wo to PO... WO = ' + JSON.serializePretty(newWOs.get(s).Id));
                        newPOs.get(s).FSO__WorkOrder__c = newWOs.get(s).Id;//Set the WO on the PO for the suppliyer
                    }
                }
                //System.debug('#####Izay: newPOs.values() = ' + JSON.serializePretty(newPOs.values()));
                insert newPOs.values();//insert the new POs
                //For each PO created... Set the PO on the WO
                for(String s :newPOs.keySet()){
                    if(woVendorMap.containsKey(s)){
                        woVendorMap.get(s).UNITY_Current_PO__c = newPOs.get(s).Id;//Set the WO on the PO for the suppliyer
                        woToUpdate.add(woVendorMap.get(s));
                    }else if(newWOs.containsKey(s)){
                        newWOs.get(s).UNITY_Current_PO__c = newPOs.get(s).Id;//Set the WO on the PO for the suppliyer
                        woToUpdate.add(newWOs.get(s));
                    }
                }
            }catch(Exception e){
                //System.debug('#####Izay: After setting related WO e = ' + e.getMessage());
                Trigger.new[0].addError(e.getMessage());
            }
        }
        //For each PO created...
        //Iterate through all order
        for(Order order :orders){
            //Iterate through each suppliyer found (Id)
            for(String s :orderLinesMap.get(order.Id).keySet()){
                //Find the PO for the POLI Suppliyer (Id)
                if(oldPOs.containsKey(s)){
                    for(OrderItem oi :orderLinesMap.get(order.Id).get(s)){
                        oi.OrderId = oldPOs.get(s);//Associate the POLI to the appropriate PO
                    }
                }else if(newPOs.containsKey(s)){
                    for(OrderItem oi :orderLinesMap.get(order.Id).get(s)){
                        oi.OrderId = newPOs.get(s).Id;//Associate the POLI to the appropriate PO
                    }
                }
            }
        }
        //After modifying and associating all POLIs to their respective POs...
        //Run an insert
        if(!polisToInsert.isEmpty()){
            try{
                //System.debug('#####Izay: polisToInsert = ' + JSON.serializePretty(polisToInsert));
                insert polisToInsert;
            }catch(Exception e){
                Trigger.new[0].addError(e.getMessage());
            }
        }
        //Now, Need to associate the $0 POLIs with their respective Part Sourcing POLIs
        //if(!isNonWork){
        List<OrderItem> poliToUpdate = new List<OrderItem>();
        for(OrderItem oi :polisToInsert){
            OrderItem noCostPOLI;
            if(relatedLinesMap.containsKey(oi.UNITY_Related_Order_Product__c)){
                noCostPOLI = relatedLinesMap.get(oi.UNITY_Related_Order_Product__c);
                oi.UNITY_Related_Order_Product__c = noCostPOLI.Id;
                noCostPOLI.UNITY_Related_Order_Product__c = oi.Id;
                poliToUpdate.add(oi);
                poliToUpdate.add(noCostPOLI);
            }
            
        }
        if(!poliToUpdate.isEmpty()){
            try{
                updateRelatedOrderItems(JSON.serialize(poliToUpdate));
            }catch(Exception e){
                Trigger.new[0].addError(e.getMessage());
            }
        }
        if(!woToUpdate.isEmpty()){
            try{
                updateRelatedWOList(JSON.serialize(woToUpdate));
            }catch(Exception e){
                Trigger.new[0].addError(e.getMessage());
            }
        }
    }
    /* ************************************************* 
     * DEPRECATED BY: IZAY
     * This is the old code to Split Part Sourcing POs
     ***************************************************
    public static void processUsageRequestPartVendorIdentified2(List<Order> orderList){
        
        List<OrderItem> orderItemList = [SELECT id,OrderId,UNITY_Vendor_Holiday_Multiplier__c,UNITY_Vendor_OT_Multiplier__c,UNITY_Customer_Holiday_Multiplier__c,
                                         UNITY_Customer_OT_Multiplier__c,UNITY_Cost__c,UNITY_Cost_Calculation_Details__c,UNITY_Price_Calculation_Details__c,UNITY_Cost_Plus__c,
                                         UNITY_Customer_Adjusted_Quantity__c,UNITY_Price__c,UNITY_Total_Price__c,UNITY_Part_On_Hand__c,UNITY_Related_Order_Product__c,
                                         UNITY_Type__c,UNITY_Activity_Type__c,UNITY_Part_Source__c,UNITY_Part_Source__r.Account_Email__c,UNITY_Total_Cost__c,
                                         PricebookEntryId,Quantity,UnitPrice,PricebookEntry.Product2Id,PricebookEntry.Product2.UNITY_Product_Type__c,
                                         UNITY_Is_Vendor_Supply__c,UNITY_Make__c,UNITY_Model__c,Description,UNITY_Actual_Ship_Date__c,UNITY_Expected_Ship_Date__c,UNITY_Tracking_Number__c,UNITY_Unit_of_Measure__c 
                                         FROM OrderItem WHERE orderId IN: orderList];
        List<Id> relatedOrderProducts = new List<Id>();
        
        for (OrderItem iter: orderItemList){
            System.debug(LoggingLevel.INFO,'<AK> : orderItem.UNITY_Related_Order_Product__c  : '+iter.UNITY_Related_Order_Product__c);
            if(iter.UNITY_Related_Order_Product__c!=null)
                relatedOrderProducts.add(iter.UNITY_Related_Order_Product__c);
        }
        Map<Id,OrderItem> relatedOrderItemMap =  new Map<id,OrderItem>([SELECT Id,UNITY_Vendor_Holiday_Multiplier__c,UNITY_Vendor_OT_Multiplier__c,UNITY_Customer_Holiday_Multiplier__c,UNITY_Customer_OT_Multiplier__c,UNITY_Related_Order_Product__c 
                                                                        FROM OrderItem WHERE Id IN: relatedOrderProducts]);
        System.debug(LoggingLevel.INFO,'<AK> : relatedOrderItemMap  : '+relatedOrderItemMap);
        relateOrderItemToWorkOrder(orderItemList,relatedOrderItemMap);
    }*/
    /* ************************************************* 
     * DEPRECATED BY: IZAY
     * This is the old code to Split Part Sourcing POs
     ***************************************************
    public static void relateOrderItemToWorkOrder(List<OrderItem> orderItemList, Map<Id,OrderItem> relatedOrderItemMap){
        
        Map<Id, Id> orderItemOrderMap = new Map<Id, Id>();
        
        Set<Id> sourceSet = new Set<Id>();
        
        //collect related Order Id and Source
        for (OrderItem iter: orderItemList){
            orderItemOrderMap.put(iter.Id, iter.OrderId);
            sourceSet.add(iter.UNITY_Part_Source__c);
        }
        System.debug(LoggingLevel.INFO,'<RB> : sourceSet  : '+sourceSet);
        //Get related orders (Part Sourcing PO in Service WO)
        List<Order> relatedOrders = [SELECT Id,UNITY_Discount__c,UNITY_Discount_Amount__c,UNITY_Business_Unit__c,UNITY_Vendor__c,FSO__WorkOrder__r.CaseId,FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__c,
                                     FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__r.UNITY_Is_Pass_Through__c,FSO__WorkOrder__r.UNITY_Customer__r.Account_Email__c,FSO__WorkOrder__r.UNITY_Agent__c,FSO__WorkOrder__r.UNITY_Customer_Margin__c ,
                                     FSO__WorkOrder__r.UNITY_Customer__c,UNITY_NTE_Exceeded__c,UNITY_Total_Amount__c,UNITY_Business_Unit_Account__c,Status, FSO__WorkOrder__c,UNITY_Total_Cost__c,AccountId,EffectiveDate,
                                     Description,UNITY_Shipping_Method__c,UNITY_Shipping_Provider__c,UNITY_Ship_To_Account__c,ShipToContactId,UNITY_Parts_Needed_By__c,UNITY_Expected_Arrival_Date__c,
                                     ShippingStreet,ShippingCity,ShippingState,ShippingStateCode,ShippingPostalCode,ShippingCountry,UNITY_Actual_Arrival_Date__c,UNITY_Tracking_Number__c 
                                     FROM Order WHERE Id IN: orderItemOrderMap.values()];
        System.debug(LoggingLevel.INFO,'<RB> : relatedOrders  : '+relatedOrders);
        Map<Id,Order> orderMap = new Map<Id,Order>();//Map to hold Part Sourcing PO by its Id
        Map<Id,Id> orderCaseMap = new Map<Id,Id>();//Map to hold Service Case Id by Part Sourcing PO Id
        Map<Id,Id> orderWorkOrderMap = new Map<Id,Id>();//Map to hold Service Work Order Id by Part Sourcing PO Id
        //Populate the maps above
        for(Order iter: relatedOrders){
            orderMap.put(iter.Id, iter);
            orderWorkOrderMap.put(iter.Id,iter.FSO__WorkOrder__c);
            orderCaseMap.put(iter.Id, iter.FSO__WorkOrder__r.CaseId);
        }
        //Get related work orders under same case with same order item source
        List<WorkOrder> workOrderList = [SELECT Id, AccountId,CaseId,UNITY_Related_Work_Order__c,UNITY_Assigned_Vendor__c,
                                         (SELECT Id FROM FSO__Orders__r) 
                                         FROM WorkOrder WHERE CaseId IN :orderCaseMap.values() 
                                         AND  UNITY_Assigned_Vendor__c IN :sourceSet];
        //Map to hold Work Order by 'CaseId->VendorId' key
        Map<String, WorkOrder> workOrderContainerMap = new Map<String, WorkOrder>();
        //For each WOrk Order... put in workOrderContainerMap
        for(WorkOrder iter: workOrderList){
            workOrderContainerMap.put(iter.CaseId+'->'+iter.UNITY_Assigned_Vendor__c, iter);
        }
        System.debug(LoggingLevel.INFO,'<RB> : workOrderContainerMap  : '+workOrderContainerMap);
        //Get related work orders (Originating Service Work Order)
        //List<WorkOrder> relatedWorkOrderList = [SELECT Id,AccountId,UNITY_Customer__c,CaseId,UNITY_Assigned_Vendor__c,UNITY_Current_PO__c 
                                                //FROM WorkOrder WHERE Id IN :orderWorkOrderMap.values()];
        //Get related work orders (Originating Service Work Order)
        Map<Id,WorkOrder> workOrderMap = new Map<Id,WorkOrder>([SELECT Id,AccountId,UNITY_Customer__c,CaseId,UNITY_Assigned_Vendor__c,UNITY_Current_PO__c 
                                                                FROM WorkOrder WHERE Id IN :orderWorkOrderMap.values()]);

        Map<Id,Id> newWOOriginalPOId = new Map<Id,Id>();
        
        List<OrderItem> newOrderItemList = new List<OrderItem>();
        List<WorkOrder> newWorkOrders = new List<WorkOrder>();
        
        Map<OrderItem,WorkOrder> OrderItemNewWorkOrder = new Map<OrderItem,WorkOrder>();
        
        System.debug(LoggingLevel.INFO,'<RB> : workOrderContainerMap'+workOrderContainerMap);
        for(OrderItem currentOrderItem: orderItemList){
            
            Order relatedOrder = orderMap.get(orderItemOrderMap.get(currentOrderItem.Id));
            
            WorkOrder relatedWorkOrder = workOrderMap.get(orderWorkOrderMap.get(relatedOrder.Id));
            
            Id assignedVendor = relatedWorkOrder.UNITY_Assigned_Vendor__c;
            
            System.debug(LoggingLevel.INFO,'<RB> : relatedOrder  : '+relatedOrder);
            System.debug(LoggingLevel.INFO,'<RB> : relatedWorkOrder  : '+relatedWorkOrder);
            System.debug(LoggingLevel.INFO,'<RB> : assignedVendor  : '+assignedVendor);
            System.debug(LoggingLevel.INFO,'<RB> : currentOrderItem'+currentOrderItem);
            if(assignedVendor != null){
                
                // order item is from different source
                if (assignedVendor != currentOrderItem.UNITY_Part_Source__c){
                    
                    String key = relatedWorkOrder.CaseId+'->'+currentOrderItem.UNITY_Part_Source__c;
                    
                    //the work order already exist
                    if (workOrderContainerMap.get(key) != null){
                        
                        //
                        if (workOrderContainerMap.get(key).FSO__Orders__r == null || workOrderContainerMap.get(key).FSO__Orders__r.isEmpty()){
                            
                            OrderItemNewWorkOrder.put(currentOrderItem, workOrderContainerMap.get(key)); 
                        }
                        //
                        else{
                            
                            Order purchaseOrder = workOrderContainerMap.get(key).FSO__Orders__r.get(0);
                            
                            OrderItem newOrderItem = currentOrderItem.clone();
                            newOrderItem.OrderId = purchaseOrder.Id;
                            
                            newOrderItemList.add(newOrderItem);
                        } 
                        
                        newWOOriginalPOId.put(relatedWorkOrder.Id, currentOrderItem.OrderId);       
                    }
                    //the work order doesn't exist
                    else{
                        
                        //create WO
                        WorkOrder newWorkOrder = new WorkOrder();
                        
                        newWorkOrder.UNITY_Assigned_Vendor__c = currentOrderItem.UNITY_Part_Source__c;
                        newWorkOrder.UNITY_Vendor_Email__c = currentOrderItem.UNITY_Part_Source__r.Account_Email__c;
                        newWorkOrder.UNITY_Related_Work_Order__c = relatedWorkOrder.Id;
                        newWorkOrder.CaseId = relatedWorkOrder.CaseId;
                        newWorkOrder.recordTypeId = UNITY_Constants.WO_NON_WORK_RECORDTYPE;
                        newWorkOrder.AccountId = relatedWorkOrder.AccountId;
                        newWorkOrder.UNITY_Customer__c = relatedWorkOrder.UNITY_Customer__c;
                        newWorkOrder.UNITY_Work_Window_Begin__c = Datetime.now();
                        newWorkOrder.Status = 'Parts Needed';
                        
                        Order orderRecord = orderMap.get(currentOrderItem.OrderId);
                        
                        //shipping address
                        
                        newWorkOrder.City = orderRecord.ShippingCity;
                        newWorkOrder.PostalCode = orderRecord.ShippingPostalCode;
                        newWorkOrder.State = orderRecord.ShippingState;
                        newWorkOrder.Street = orderRecord.ShippingStreet;
                        
                        newWorkOrders.add(newWorkOrder);
                        
                        OrderItemNewWorkOrder.put(currentOrderItem, newWorkOrder);
                        
                        //
                        workOrderContainerMap.put(newWorkOrder.CaseId+'->'+newWorkOrder.UNITY_Assigned_Vendor__c, newWorkOrder);
                        //
                        System.debug(LoggingLevel.INFO,'<RB> creating new Non Work Order: '+newWorkOrder);
                        
                        System.debug('#currentOrderItem '+currentOrderItem);
                        
                        newWOOriginalPOId.put(relatedWorkOrder.Id, currentOrderItem.OrderId);
                    }
                }
                // same source -> add lines to the vendor PO
                else{
                    
                    
                }
            }
        }
        
        insert newWorkOrders;
        
        insert newOrderItemList;
        
        
        List<Order> newOrders = new List<Order>();
        Map<Id, Order> workOrderOrder = new Map<Id, Order>();
        
        //for (WorkOrder iter: OrderItemNewWorkOrder.values()){
        for (WorkOrder iter: newWorkOrders){      
            
            System.debug('#workorder '+iter.UNITY_Related_Work_Order__c);
            System.debug('#newWOOriginalPOId '+newWOOriginalPOId);
            
            Order originalOrder = orderMap.get(newWOOriginalPOId.get(iter.UNITY_Related_Work_Order__c));
            
            System.debug('#originalOrder '+originalOrder);
            
            //createPO
            Order newOrder = new Order();
            
            newOrder.RecordTypeId = UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE;
            
            newOrder.FSO__WorkOrder__c  = iter.Id;
            newOrder.AccountId  = iter.AccountId;
            newOrder.EffectiveDate = Date.today();
            newOrder.Status = UNITY_Constants.ORDER_STATUS_PART_ORDER_REQUIRED;
            
            //shipping Address
            
            newOrder.ShippingCity = originalOrder.ShippingCity;
            newOrder.ShippingCountry = originalOrder.ShippingCountry;
            newOrder.ShippingPostalCode = originalOrder.ShippingPostalCode;
            newOrder.ShippingState = originalOrder.ShippingState;
            newOrder.ShippingStateCode = originalOrder.ShippingStateCode;
            newOrder.ShippingStreet = originalOrder.ShippingStreet;
            newOrder.UNITY_Actual_Arrival_Date__c = originalOrder.UNITY_Actual_Arrival_Date__c;
            newOrder.UNITY_Expected_Arrival_Date__c = originalOrder.UNITY_Expected_Arrival_Date__c;
            newOrder.UNITY_Tracking_Number__c = originalOrder.UNITY_Tracking_Number__c;
            newOrder.Description = originalOrder.Description;
            newOrder.ShipToContactId = originalOrder.ShipToContactId;
            newOrder.UNITY_Shipping_Provider__c = originalOrder.UNITY_Shipping_Provider__c;
            newOrder.UNITY_Shipping_Method__c = originalOrder.UNITY_Shipping_Method__c;
            newOrder.UNITY_Ship_To_Account__c = originalOrder.UNITY_Ship_To_Account__c;
            newOrder.UNITY_Parts_Needed_By__c = originalOrder.UNITY_Parts_Needed_By__c;
            
            System.debug('#newOrder '+newOrder);
            
            if(Test.isRunningTest()){
                newOrder.Pricebook2Id = Test.getStandardPricebookId();
            }
            
            newOrders.add(newOrder);
            
            workOrderOrder.put(iter.Id, newOrder);
        }
        
        insert newOrders;
        
        Map<Id,Id> orderByWO = new Map<Id,Id>();
        for(Order o :newOrders){
            orderByWO.put(o.FSO__WorkOrder__c,o.Id);
        }
        for (WorkOrder iter: newWorkOrders){
            if(orderByWO.containsKey(iter.Id)){
                iter.UNITY_Current_PO__c = orderByWO.get(iter.id);
            }
        }
        
        updateNewWorkOrder(JSON.serialize(newWorkOrders));
        
        newOrderItemList = new List<OrderItem>();
        
        System.debug('#OrderItemNewWorkOrder '+OrderItemNewWorkOrder);
        System.debug('#workOrderOrder '+workOrderOrder);
        
        for (OrderItem iter: OrderItemNewWorkOrder.keySet()){
            
            //create Order Item
            OrderItem newOrderItem = iter.clone();
            newOrderItem.UNITY_Is_Vendor_Supply__c = false;
            
            WorkOrder workOrder = OrderItemNewWorkOrder.get(iter);
            
            System.debug('#workOrder '+workOrder);
            
            newOrderItem.OrderId = workOrderOrder.get(workOrder.Id).Id; 
            System.debug('#newOrderItem '+newOrderItem);
            
            newOrderItemList.add(newOrderItem);
        }
        
        System.debug('#newOrderItemList '+newOrderItemList);
        insert newOrderItemList;
        
        List<OrderItem> updatedRelatedOrderItemsList = new List<OrderItem>();
        for (OrderItem iter: newOrderItemList){
            System.debug('#newOrderItem Id '+iter.Id);
            OrderItem relatedOrderItem = relatedOrderItemMap.get(iter.UNITY_Related_Order_Product__c);
            System.debug('#relatedOrderItem '+relatedOrderItem);
            if (relatedOrderItem != null){
                relatedOrderItem.UNITY_Related_Order_Product__c = iter.Id;
                System.debug('#relatedOrderItem after Id set '+relatedOrderItem);
                updatedRelatedOrderItemsList.add(relatedOrderItem);
            }
            
        }
        System.debug('#updatedRelatedOrderItemsList '+updatedRelatedOrderItemsList);
        updateRelatedOrderItems(JSON.serialize(updatedRelatedOrderItemsList));        
    }
    */
    @future
    public static void updateRelatedOrderItems(String orderItemList){
        
        List<OrderItem> deserializedOrderItems = (List<OrderItem>)JSON.deserialize(orderItemList, List<OrderItem>.class);
        
        update deserializedOrderItems;
    }
    /* ************************************************* 
     * DEPRECATED BY: IZAY
     * This is the old code to Split Part Sourcing POs
     ***************************************************
    @future
    public static void updateNewWorkOrder(String woList){
        List<WorkOrder> wos = (List<WorkOrder>)JSON.deserialize(woList, List<WorkOrder>.class);
        update wos;
    }
    */
    @future
    public static void updateRelatedWOList(String woList){
        UNITY_Constants.isExecutingContext('updateRelatedWOList');
        List<WorkOrder> wos = (List<WorkOrder>)JSON.deserialize(woList, List<WorkOrder>.class);
        update wos;
    }
    public static void autopopulateFieldsOnOrder(List<Order> orderList){
        
        Map<Id, Id> OrderWorkOrderMap = new Map<Id, Id>();
        
        for (Order iter: orderList){
            OrderWorkOrderMap.put(iter.Id, iter.FSO__WorkOrder__c);
        }
        
        List<WorkOrder> relatedWorkOrderList = [select id, UNITY_Business_Unit__c, UNITY_Vendor_Contract__c from WorkOrder where id in: OrderWorkOrderMap.values()];
        
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>();
        
        for (WorkOrder iter: relatedWorkOrderList){
            workOrderMap.put(iter.Id, iter);
        }
        
        for (Order iter: orderList){
            
            Id relatedWorkOrderId = OrderWorkOrderMap.get(iter.Id);
            
            WorkOrder relatedWorkOrder = workOrderMap.get(relatedWorkOrderId);
            
            if (iter.UNITY_Business_Unit__c == null){
                iter.UNITY_Business_Unit__c = relatedWorkOrder.UNITY_Business_Unit__c;
            }
            if (iter.UNITY_Vendor_Contract__c == null){   
                iter.UNITY_Vendor_Contract__c = relatedWorkOrder.UNITY_Vendor_Contract__c;
            }    
        }
    }
    
    public static Decimal calculateServicveCharge(Id scid, Decimal urTotal, Decimal incCharges){
        Decimal sCharge = 0;
        Decimal totalVendorSuppliedFinalPrice = urTotal + incCharges;
        List<UNITY_Service_Contract__c> customerSC = [select id, UNITY_Is_Pass_Through__c, (Select id,  UNITY_Threshold_Start__c, UNITY_Threshold_End__c, UNITY_Service_Charge_Percentage__c, UNITY_Service_Charge_Amount__c  FROM UNITY_Service_Contract_Line_Items__r WHERE RecordTypeId = :UNITY_Constants.SCLI_SERVICE_CHARGE_RECORDTYPE) FROM UNITY_Service_Contract__c WHERE UNITY_IS_Active__c = TRUE AND  UNITY_Service_Contract__c.RecordTypeId = :UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE AND UNITY_Is_Pass_Through__c = TRUE AND Id = :scid LIMIT 1];
        if (!customerSC.isEmpty()){
            for (UNITY_Service_Contract_Line_Item__c scli: customerSC[0].UNITY_Service_Contract_Line_Items__r){
                if(totalVendorSuppliedFinalPrice >= scli.UNITY_Threshold_Start__c && (scli.UNITY_Threshold_End__c == null || totalVendorSuppliedFinalPrice <= scli.UNITY_Threshold_End__c)){
                    
                    Decimal serviceChargePercentage = 0;
                    Decimal serviceChargeAmount = 0;
                    
                    if (scli.UNITY_Service_Charge_Percentage__c!=null){
                        serviceChargePercentage = scli.UNITY_Service_Charge_Percentage__c;
                    }
                    if (scli.UNITY_Service_Charge_Amount__c!=null){
                        serviceChargeAmount = scli.UNITY_Service_Charge_Amount__c;
                    }
                    if ((totalVendorSuppliedFinalPrice * (serviceChargePercentage/100)) >= serviceChargeAmount){
                        sCharge = totalVendorSuppliedFinalPrice * (serviceChargePercentage/100);
                    }else if ((totalVendorSuppliedFinalPrice * (serviceChargePercentage/100)) < serviceChargeAmount){
                        sCharge = serviceChargeAmount; 
                    }
                    
                    break;
                }
            }
        }
        return sCharge;
    }
    
    public static Map<string,UNITY_General_Settings__c> generalSettings = UNITY_General_Settings__c.getAll();
    public static Decimal getIncurredCharges(Id cid, Boolean forServiceCharge){
        Set<String> delimitedInvoiceableStatuses = new Set<String>();
        UNITY_General_Settings__c generalSetting = generalSettings.get(UNITY_Constants.PO_INVOICEABLE_STATUSES);
        String POInvoiceableStatuses;
        if (generalSetting!=null){
            POInvoiceableStatuses = generalSetting.UNITY_Value__c;
        }
        if (POInvoiceableStatuses!=null){
            delimitedInvoiceableStatuses = new Set<String>(POInvoiceableStatuses.split(UNITY_Constants.PO_INVOICEABLE_STATUSES_DELIMITER));
        }
        Decimal totalInc = 0;
        List<Order> allPOs = new List<Order>();
        if(forServiceCharge){
            allPOs = [SELECT Id,OrderNumber,AccountId,EffectiveDate,UNITY_Estimated_Tax__c,UNITY_Line_Item_DIscounted_Price__c,UNITY_Final_Price__c,UNITY_Discount__c,
                      (SELECT Id,OrderId,OrderItemNumber,UNITY_Customer_Adjusted_Quantity__c,
                       UNITY_Price__c,UNITY_Type__c,UNITY_Activity_Type__c,UNITY_Discounted_Price__c,UNITY_Total_Price__c,UNITY_Product_Name__c
                       FROM OrderItems WHERE PriceBookEntry.Product2.Name != 'Vendor Service Fee' AND UNITY_Is_Vendor_Supply__c = TRUE 
                       AND UNITY_Not_Billable__c = FALSE
                      ) 
                      FROM Order WHERE FSO__WorkOrder__r.CaseId = :cid
                      AND(RecordTypeId =: UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE 
                          OR 
                          RecordTypeId =: UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE)
                      AND Status IN :delimitedInvoiceableStatuses
                      AND FSO__WorkOrder__r.Status != 'Canceled'];
            for(Order po :allPOs){
                for(OrderItem ot :po.OrderItems){
                	Decimal temp = (ot.UNITY_Discounted_Price__c != null) ? ot.UNITY_Discounted_Price__c : ot.UNITY_Total_Price__c;
                	if(po.UNITY_Discount__c != null && po.UNITY_Discount__c > 0)
                        temp = (1 - po.UNITY_Discount__c) * temp;
                    totalInc += temp;
                }
            }
        }else{
            allPOs = [SELECT Id,OrderNumber,AccountId,EffectiveDate,UNITY_Estimated_Tax__c,UNITY_Line_Item_DIscounted_Price__c,UNITY_Final_Price__c,
                      (SELECT Id,OrderId,OrderItemNumber,UNITY_Customer_Adjusted_Quantity__c,
                       UNITY_Price__c,UNITY_Type__c,UNITY_Activity_Type__c,UNITY_Discounted_Price__c,UNITY_Total_Price__c,UNITY_Product_Name__c
                       FROM OrderItems WHERE PriceBookEntry.Product2.Name != 'Vendor Service Fee'
                       AND UNITY_Not_Billable__c = FALSE
                      ) 
                      FROM Order WHERE FSO__WorkOrder__r.CaseId = :cid
                      AND(RecordTypeId =: UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE 
                          OR 
                          RecordTypeId =: UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE)
                      AND Status IN :delimitedInvoiceableStatuses
                      AND FSO__WorkOrder__r.Status != 'Canceled'];
            for(Order po :allPOs){
                Decimal temp = (po.UNITY_Final_Price__c != null) ? po.UNITY_Final_Price__c : po.UNITY_Line_Item_DIscounted_Price__c;
                totalInc += temp;
            }
        }
        
        return totalInc;
    }
    
    public static void createPOFromUsageRequestBulkified(List<Order> orderList){
        /*
        orderList = [select id, UNITY_Discount__c, UNITY_Discount_Amount__c, UNITY_Business_Unit__c, UNITY_Vendor__c, FSO__WorkOrder__r.CaseId, 
                     FSO__WorkOrder__r.UNITY_Customer__r.Account_Email__c, FSO__WorkOrder__r.UNITY_Agent__c, FSO__WorkOrder__r.UNITY_Truck_On_Site__c,  
                     FSO__WorkOrder__r.UNITY_Customer_Margin__c , FSO__WorkOrder__r.UNITY_Customer__c, UNITY_NTE_Exceeded__c, 
                     UNITY_Total_Amount__c, UNITY_Business_Unit_Account__c, Status, FSO__WorkOrder__c, UNITY_Total_Cost__c, AccountId, 
                     EffectiveDate, UNITY_All_Parts_On_Truck__c, UNITY_All_Parts_On_Truck_Confirmed__c,
                     Description,UNITY_Shipping_Method__c,UNITY_Shipping_Provider__c,UNITY_Ship_To_Account__c,ShipToContactId,
                     UNITY_Parts_Needed_By__c,UNITY_Expected_Arrival_Date__c,ShippingStreet,ShippingCity,ShippingState,ShippingStateCode,
                     ShippingPostalCode,ShippingCountry,UNITY_Actual_Arrival_Date__c,UNITY_Tracking_Number__c,
                     FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__r.UNITY_Is_Pass_Through__c
                     from Order where id in:orderList];
        
        //get related order items
        Map<Id, List<OrderItem>> orderItemMap = new Map<Id, List<OrderItem>>();
        
        List<OrderItem> relatedOrderItemList = [select id, UNITY_Asset__c, OrderId, UNITY_Discount__c, UNITY_Discount_Amount__c, UNITY_Vendor_Adjusted_Quantity__c,
                                                UNITY_Customer_Adjusted_Quantity__c, UNITY_Cost__c, UNITY_Total_Cost__c, UNITY_Total_Price__c, 
                                                UNITY_Activity_Type__c, UNITY_Type__c, UNITY_Vendor_Holiday_Multiplier__c, UNITY_Vendor_OT_Multiplier__c, 
                                                UNITY_Customer_Holiday_Multiplier__c, UNITY_Customer_OT_Multiplier__c, UNITY_Number_of_Techs__c, UNITY_Price__c, 
                                                PricebookEntryId, Quantity, UnitPrice, PricebookEntry.Id, PricebookEntry.Product2Id, 
                                                PricebookEntry.Product2.UNITY_Product_Type__c, UNITY_Is_Vendor_Supply__c, UNITY_Part_On_Hand__c, 
                                                UNITY_Part_Source__c,UNITY_Location_OOS__c,UNITY_Make__c,UNITY_Model__c,Description,UNITY_Unit_of_Measure__c
                                                from OrderItem where OrderId in: orderList];
        
        for (OrderItem iter: relatedOrderItemList){
            
            List<OrderItem> orderItemList = orderItemMap.get(iter.orderId);
            
            if (orderItemList == null){
                orderItemList = new List<OrderItem>();
            }
            
            orderItemList.add(iter);
            
            orderItemMap.put(iter.OrderId, orderItemList);
        }
        
        //get related work orders
        Set<Id> workOrderIdSet = new Set<Id>();
        Map<Id, Order> orderMap = new Map<Id, Order>();
        
        for (Order iter: orderList){
            
            workOrderIdSet.add(iter.FSO__WorkOrder__c);
            orderMap.put(iter.Id, iter);
        }
        
        System.debug('#orderMap '+orderMap);
        
        List<WorkOrder> relatedWorkOrderList = [select Id, CaseId, Case.UNITY_Total_Price__c, Case.UNITY_NTE_Threshold__c from WorkOrder where id =: workOrderIdSet];
        
        Set<Id> ordersToCreateQuote = new Set<Id>();
        Set<Id> ordersToCreatePO = new Set<Id>();
        
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>();
        
        for (WorkOrder iter: relatedWorkOrderList){
            workOrderMap.put(iter.Id, iter);
        }
        
        for (Order iter: orderList){
            
            WorkOrder woRecord = workOrderMap.get(iter.FSO__WorkOrder__c);
            
            Double NTEVal = woRecord.Case.UNITY_NTE_Threshold__c;
            
            Double totalPrice = woRecord.Case.UNITY_Total_Price__c;
            
            Double sCharge = 0;
            
            System.debug('#woRecord '+woRecord);
            
            iter.UNITY_NTE_Exceeded__c = false;
            
            if(iter.FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__r.UNITY_Is_Pass_Through__c){
                Decimal incCharges = getIncurredCharges(iter.FSO__WorkOrder__r.CaseId,true);
                Decimal totaVendorSupply = 0;
                for(OrderItem item :orderItemMap.get(iter.Id)){
                    if(item.UNITY_Is_Vendor_Supply__c)
                        totaVendorSupply += (item.UNITY_Total_Price__c != null)?item.UNITY_Total_Price__c:0;
                }
                sCharge = calculateServicveCharge(iter.FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__c,totaVendorSupply,incCharges);
            }
            
            if (totalPrice!=null && iter.UNITY_Total_Amount__c !=null ){
                
                if ((totalPrice + iter.UNITY_Total_Amount__c + sCharge) > NTEVal){
                    
                    iter.UNITY_NTE_Exceeded__c = true;
                }
            }
            
            if (iter.UNITY_NTE_Exceeded__c){
                // if it is not a Self perfoman technician flow
                if(iter.FSO__WorkOrder__r.UNITY_Truck_On_Site__c == null) {
                    ordersToCreateQuote.add(iter.Id);  
                }   
            }
            else{
                ordersToCreatePO.add(iter.Id);
            }
        }
        
        createQuoteBulkified(ordersToCreateQuote, orderItemMap, orderMap);
        createPOsBulkified(ordersToCreatePO, orderItemMap, orderMap);
        
        update orderList;
		*/
    }
    
    
    public static void createQuoteBulkified(Set<Id> ordersToCreateQuote, Map<Id, List<OrderItem>> orderItemMap, Map<Id, Order> orderMap){
        /*
        List<OrderItem> laborAndTravelLinesList = new List<OrderItem>();
        List<OrderItem> partLinesList = new List<OrderItem>();
        List<OrderItem> allOtherLinesList = new List<OrderItem>();
        
        Map<Id, UNITY_Proposal__c> quotesToCreate = new Map<Id, UNITY_Proposal__c>();
        
        for (Id orderId: ordersToCreateQuote){
            
            Order orderRecord = orderMap.get(orderId);
            
            for (OrderItem orderItem: orderItemMap.get(orderId)){
                
                String productType = orderItem.PricebookEntry.Product2.UNITY_Product_Type__c;
                
                if (productType == 'Labor' || productType == 'Travel'){
                    laborAndTravelLinesList.add(orderItem);
                }
                else if (productType == 'Part'){
                    partLinesList.add(orderItem);
                }else {
                    allOtherLinesList.add(orderItem);
                }
            }
            
            //create Quote
            UNITY_Proposal__c newQuote = new UNITY_Proposal__c();
            
            newQuote.UNITY_Originating_Usage_Request__c = orderRecord.Id;
            newQuote.UNITY_Account__c = orderRecord.AccountId;
            newQuote.UNITY_Business_Unit_Account__c = orderRecord.UNITY_Business_Unit_Account__c;
            newQuote.UNITY_Effective_Till_Date__c = orderRecord.EffectiveDate;
            newQuote.UNITY_Work_Order__c = orderRecord.FSO__WorkOrder__c;
            newQuote.UNITY_Customer_Margin__c = orderRecord.FSO__WorkOrder__r.UNITY_Customer_Margin__c ;
            newQuote.UNITY_Proposal_Status__c = UNITY_Constants.QT_STATUS_QUOTE_CREATION;       
            newQuote.UNITY_Agent__c = orderRecord.FSO__WorkOrder__r.UNITY_Agent__c; 
            newQuote.UNITY_Customer__c = orderRecord.FSO__WorkOrder__r.UNITY_Customer__c;
            newQuote.UNITY_Customer_Email__c = orderRecord.FSO__WorkOrder__r.UNITY_Customer__r.Account_Email__c;
            newQuote.UNITY_Discount__c = orderRecord.UNITY_Discount__c;
            newQuote.UNITY_Discount_Amount__c = orderRecord.UNITY_Discount_Amount__c;
            newQuote.UNITY_Business_Unit__c = orderRecord.UNITY_Business_Unit__c;
            newQuote.UNITY_Vendor__c = orderRecord.UNITY_Vendor__c;
            newQuote.UNITY_Case__c = orderRecord.FSO__WorkOrder__r.CaseId;
            newQuote.UNITY_Quote_Comments__c = orderRecord.Description;
            
            quotesToCreate.put(orderRecord.Id, newQuote);
            
            orderMap.get(orderId).Status = 'In Quote Process';
			
        }
        
        System.debug('#laborAndTravelLines '+laborAndTravelLinesList);
        System.debug('#partLines '+partLinesList);
        System.debug('#allOtherLines '+allOtherLinesList);
        
        insert quotesToCreate.values();
        
        List<UNITY_Proposal_Line_Item__c> newProposalLineItems = new List<UNITY_Proposal_Line_Item__c>();
        
        newProposalLineItems.addAll(createQuoteLineItemsBulkified(laborAndTravelLinesList, quotesToCreate));
        newProposalLineItems.addAll(createQuoteLineItemsBulkified(partLinesList, quotesToCreate));
        newProposalLineItems.addAll(createQuoteLineItemsBulkified(allOtherLinesList, quotesToCreate));
        
        insert newProposalLineItems;
		*/
    }
    
    
    public static List<UNITY_Proposal_Line_Item__c> createQuoteLineItemsBulkified(List<OrderItem> orderItemList, Map<Id, UNITY_Proposal__c> orderQuoteMap){
        
        List<UNITY_Proposal_Line_Item__c> quoteLineItems = new List<UNITY_Proposal_Line_Item__c>();
        /*
        for (OrderItem iter: orderItemList){
            
            UNITY_Proposal_Line_Item__c newQuoteLineItem = new UNITY_Proposal_Line_Item__c();
            
            newQuoteLineItem.UNITY_Quantity__c = iter.Quantity;
            newQuoteLineItem.UNITY_Cost__c = iter.UNITY_Cost__c;
            
            newQuoteLineItem.UNITY_Proposal__c = orderQuoteMap.get(iter.OrderId).Id;
            newQuoteLineItem.UNITY_Product__c = iter.PricebookEntry.Product2Id;
            newQuoteLineItem.UNITY_PriceBook_Entry_Id__c = (String)iter.PricebookEntry.Id;
            newQuoteLineItem.UNITY_Is_Vendor_Supply__c = iter.UNITY_Is_Vendor_Supply__c;
            newQuoteLineItem.UNITY_Type__c = iter.UNITY_Type__c;
            newQuoteLineItem.UNITY_Activity_Type__c = iter.UNITY_Activity_Type__c;
            newQuoteLineItem.UNITY_Vendor_Holiday_Multiplier__c = iter.UNITY_Vendor_Holiday_Multiplier__c;
            newQuoteLineItem.UNITY_Vendor_OT_Multiplier__c = iter.UNITY_Vendor_OT_Multiplier__c;
            newQuoteLineItem.UNITY_Customer_Holiday_Multiplier__c = iter.UNITY_Customer_Holiday_Multiplier__c;
            newQuoteLineItem.UNITY_Customer_OT_Multiplier__c = iter.UNITY_Customer_OT_Multiplier__c;
            newQuoteLineItem.UNITY_Number_of_Techs__c = iter.UNITY_Number_of_Techs__c;
            newQuoteLineItem.UNITY_Vendor_Adjusted_Quantity__c = iter.UNITY_Vendor_Adjusted_Quantity__c;
            newQuoteLineItem.UNITY_Customer_Adjusted_Quantity__c = iter.UNITY_Customer_Adjusted_Quantity__c;
            newQuoteLineItem.UNITY_Discount__c = iter.UNITY_Discount__c;
            newQuoteLineItem.UNITY_Discount_Amount__c = iter.UNITY_Discount_Amount__c;   
            newQuoteLineItem.UNITY_Asset__c = iter.UNITY_Asset__c;
            //Izay: propagate unknown/special order part info
            newQuoteLineItem.UNITY_Make__c = iter.UNITY_Make__c;
            newQuoteLineItem.UNITY_Model__c = iter.UNITY_Model__c;
            newQuoteLineItem.UNITY_Description__c = iter.Description;
            newQuoteLineItem.UNITY_Unit_of_Measure__c = iter.UNITY_Unit_of_Measure__c;
            
            newQuoteLineItem.UNITY_Part_Source__c = iter.UNITY_Part_Source__c;   
            newQuoteLineItem.UNITY_Part_On_Hand__c = iter.UNITY_Part_On_Hand__c; 
            
            
            
            quoteLineItems.add(newQuoteLineItem);
        }
        */
        return quoteLineItems;
    }
    
    
    public static void createPOsBulkified(Set<Id> ordersToCreatePO, Map<Id, List<OrderItem>> orderItemMap, Map<Id, Order> orderMap){
        /*
        Map<Id, List<OrderItem>> noCostOrderItemMap = new Map<Id, List<OrderItem>>();
        
        Map<Id, List<OrderItem>> vendorSupplyOrderItemMap = new Map<Id, List<OrderItem>>();
        Map<Id, List<OrderItem>> noVendorSupplyOrderItemMap = new Map<Id, List<OrderItem>>();
        Map<Id, List<OrderItem>> allPartsEnoughStockOnTruckOrderItemMap = new Map<Id, List<OrderItem>>();
        
        List<OrderItem> nonVendorSupplyOrderItemList = new List<OrderItem>();
        List<OrderItem> noCostOrderItemList = new List<OrderItem>();
        
        for (Id orderId: ordersToCreatePO){
            Order order = orderMap.get(orderId);
            noCostOrderItemMap.put(orderId, new List<OrderItem>());
            vendorSupplyOrderItemMap.put(orderId, new List<OrderItem>());
            noVendorSupplyOrderItemMap.put(orderId, new List<OrderItem>());
            List<OrderItem> vendorSupplyOrderItems = new List<OrderItem>();
            List<OrderItem> allPartsEnoughStockOnTruckItems = new List<OrderItem>();
            Boolean existsAPartOutOfStock = false;
            if(orderItemMap.containsKey(orderId)){
                
                for (OrderItem iter: orderItemMap.get(orderId)){
                    
                    String productType = iter.PricebookEntry.Product2.UNITY_Product_Type__c;
                    
                    OrderItem newOrderItem = iter.clone();
                    
                    if (iter.UNITY_Is_Vendor_Supply__c){
                        vendorSupplyOrderItems.add(newOrderItem);
                    }
                    else{
                        
                        // self perform technician flow
                        if(order.FSO__WorkOrder__r.UNITY_Truck_On_Site__c != null) {
                            // Put on the allPartsEnoughStockOnTruckItems too, 
                            // if all the order items have enough stock.
                            if(!iter.UNITY_Location_OOS__c) {
                                allPartsEnoughStockOnTruckItems.add(newOrderItem);
                            } else {
                                existsAPartOutOfStock = true;
                            }
                        } else {
                            noVendorSupplyOrderItemMap.get(orderId).add(newOrderItem);
                            
                            //add $0 to vendor PO
                            
                            OrderItem noCostOrderItem = iter.clone();
                            
                            noCostOrderItem.UNITY_Cost__c = 0;
                            noCostOrderItem.UNITY_Total_Cost__c = 0;
                            noCostOrderItem.UNITY_Price__c = 0;
                            noCostOrderItem.UNITY_Total_Price__c = 0;  
                            noCostOrderItem.UNITY_Type__c = 'Non Billable';
                            
                            vendorSupplyOrderItemMap.get(orderId).add(noCostOrderItem);
                            
                            noCostOrderItemMap.get(orderId).add(noCostOrderItem);
                            
                            nonVendorSupplyOrderItemList.add(newOrderItem);
                            noCostOrderItemList.add(noCostOrderItem);   
                        }
                        
                    }
                }
                
            }
            
            // add allPartsEnoughStockOnTruckItems list to the map allPartsEnoughStockOnTruckItemMap if not existe any part out of stock
            if (!existsAPartOutOfStock && orderMap.get(orderId).UNITY_All_Parts_On_Truck__c) {
                allPartsEnoughStockOnTruckOrderItemMap.put(orderId, allPartsEnoughStockOnTruckItems);
                //UNITY_All_Parts_On_Truck_Confirmed__c set true
                orderMap.get(orderId).UNITY_All_Parts_On_Truck_Confirmed__c = true;
            } else {
                vendorSupplyOrderItemMap.get(orderId).addAll(vendorSupplyOrderItems);
            }
            
            orderMap.get(orderId).Status = 'PO Created';
        }
        
        System.debug('#vendorSupplyOrderItemMap '+vendorSupplyOrderItemMap);
        System.debug('#noVendorSupplyOrderItemMap '+noVendorSupplyOrderItemMap);
        System.debug('#noCostOrderItemMap '+noCostOrderItemMap);
        System.debug('#allPartsEnoughStockOnTruckOrderItemMap '+allPartsEnoughStockOnTruckOrderItemMap);
        
        createPurchaseOrderBulkified(vendorSupplyOrderItemMap, orderMap, 'Draft');
        createPurchaseOrderBulkified(noVendorSupplyOrderItemMap, orderMap, UNITY_Constants.ORDER_STATUS_PART_SOURCE_NEEDED);
        //UNITY_All_Parts_On_Truck__c is checked and all parts are in stock on the truck, 
        // skip Submitted to Parts Team, and create PO directly and mark as final
        createPurchaseOrderBulkified(allPartsEnoughStockOnTruckOrderItemMap, orderMap, 'Final');
        
        List<OrderItem> poliToUpdate = new List<OrderItem>();
        
        for (Integer i=0; i < nonVendorSupplyOrderItemList.size(); i++){
            
            OrderItem noVendorSupplyPOLI = nonVendorSupplyOrderItemList.get(i);
            OrderItem noCostPOLI = noCostOrderItemList.get(i);
            
            noVendorSupplyPOLI.UNITY_Related_Order_Product__c = noCostPOLI.Id;
            noCostPOLI.UNITY_Related_Order_Product__c = noVendorSupplyPOLI.Id;
            
            poliToUpdate.add(noVendorSupplyPOLI);
            poliToUpdate.add(noCostPOLI);
        }
        
        update poliToUpdate;
        */
    }
    
    public static void createPurchaseOrderBulkified(Map<Id, List<OrderItem>> orderItemMap, Map<Id, Order> orderMap, String status){
        /*
        Map<Id, Order> oldOrderNewOrderMap = new Map<Id, Order>();
        
        List<Order> purchaseOrderToInsert = new List<Order>();
        
        for(Id orderId: orderItemMap.keySet()){
            
            if(!orderItemMap.get(orderId).isEmpty()) {
                Order orderRecord = orderMap.get(orderId);
                
                Order purchaseOrder = orderRecord.clone();
                
                purchaseOrder.pricebook2Id = standardPriceBookId;
                purchaseOrder.Status = status;
                purchaseOrder.UNITY_Originating_Usage_Request__c = orderRecord.Id;
                
                if(status == UNITY_Constants.ORDER_STATUS_PART_SOURCE_NEEDED ){
                    purchaseOrder.UNITY_Vendor__c = null;
                    purchaseOrder.UNITY_Vendor_Email__c = null;
                    purchaseOrder.RecordTypeId = UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE;
                }else{
                    purchaseOrder.RecordTypeId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;
                }
                
                oldOrderNewOrderMap.put(orderRecord.Id, purchaseOrder);
                
                purchaseOrderToInsert.add(purchaseOrder);
            }
        }
        
        insert purchaseOrderToInsert;
        
        List<OrderItem> orderItemToInsert = new List<OrderItem>();
        
        for(Id orderId: orderItemMap.keySet()){
            
            for (OrderItem iter: orderItemMap.get(orderId)){
                
                iter.OrderId = oldOrderNewOrderMap.get(orderId).Id;
                
                orderItemToInsert.add(iter);
            }
        }
        
        insert orderItemToInsert;
		*/
    }
}