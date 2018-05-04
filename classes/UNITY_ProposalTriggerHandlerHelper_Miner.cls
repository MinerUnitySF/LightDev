global class UNITY_ProposalTriggerHandlerHelper_Miner {
    public static id standardPriceBookId{get;set;}
    static {
        if(Test.isRunningTest()){
            standardPriceBookId = Test.getStandardPricebookId();
        }else{
            standardPriceBookId = UNITY_Constants.getStandardPriceBookId();
        }
    }
    public static Map<String,String> createPOAndPOLIsFromQuote2(List<UNITY_Proposal__c> quotes){
        Map<String,String> result = new Map<String,String>();
        String message = '';
        result.put('success','true');
        result.put('result','');
        result.put('message','');
        SavePoint sp = Database.setSavepoint();
        Set<Id> urIds = new Set<Id>();
        Set<Id> scIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        Map<Id,Id> urByQuoteId = new Map<Id,Id>();
        for(UNITY_Proposal__c q :quotes){
            urIds.add(q.UNITY_Originating_Usage_Request__c);
            urByQuoteId.put(q.Id,q.UNITY_Originating_Usage_Request__c);
            caseIds.add(q.UNITY_Case__c);
        }
        //Retrieve the work order associated
        Map<Id,WorkOrder> workOrderMap = new Map<Id,WorkOrder>([SELECT Id,UNITY_Current_PO__c,CaseId,UNITY_Assigned_Vendor__c,RecordTypeId,
                                                                UNITY_Business_Unit__c,UNITY_Vendor_Contract__c,UNITY_Include__c,UNITY_Use_Menu_Pricing__c
                                                                FROM WorkOrder
                                                                WHERE Id IN: UNITY_Utils.joiningByFieldList(quotes,'UNITY_Work_Order__c')]);
        //Get the originating Usage Requests
        Map<Id,Order> originatingURMap = new Map<Id,Order>([SELECT id,UNITY_Discount__c,UNITY_Discount_Amount__c,UNITY_Business_Unit__c,UNITY_Vendor__c,FSO__WorkOrder__r.CaseId,FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__c,UNITY_Customer__r.MH_SL_CustID__c,UNITY_Customer__r.UNITY_Bill_to_Account__r.MH_SL_CustID__c,
                                                            FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__r.UNITY_Is_Pass_Through__c,FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__r.UNITY_Contract_Sub_type__c,FSO__WorkOrder__r.UNITY_Customer__r.Account_Email__c,FSO__WorkOrder__r.UNITY_Agent__c,FSO__WorkOrder__r.UNITY_Customer_Margin__c,
                                                            FSO__WorkOrder__r.UNITY_Customer__c,UNITY_NTE_Exceeded__c,UNITY_Total_Amount__c,UNITY_Business_Unit_Account__c,Status,FSO__WorkOrder__c,UNITY_Total_Cost__c,AccountId,EffectiveDate,FSO__WorkOrder__r.RecordTypeId,UNITY_Final_Price__c,UNITY_Line_Item_DIscounted_Price__c,
                                                            Description,UNITY_Shipping_Method__c,UNITY_Shipping_Provider__c,UNITY_Ship_To_Account__c,ShipToContactId,UNITY_Parts_Needed_By__c,UNITY_Expected_Arrival_Date__c,FSO__WorkOrder__r.UNITY_Use_Menu_Pricing__c,FSO__WorkOrder__r.UNITY_Include__c,
                                                            ShippingStreet,ShippingCity,ShippingState,ShippingStateCode,ShippingPostalCode,ShippingCountry, ShippingCountryCode, UNITY_Actual_Arrival_Date__c,UNITY_Tracking_Number__c,OwnerId
                                                            FROM Order WHERE Id IN :urIds]);
        //Get the service contract for all cases
        for(Order o :originatingURMap.values()){
            scIds.add(o.FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__c);
        }
        //Get the customer service contract to find menu priced lines
        List<UNITY_Service_Contract__c> contractList = [SELECT Id, UNITY_Account__r.RecordTypeId, UNITY_Is_Pass_Through__c, UNITY_Cost_Plus__c, UNITY_Minimum_Labor_Hours__c, UNITY_Max_Allowable_Trip_Charges__c, UNITY_2_Technicians__c,UNITY_Apprentice__c,UNITY_Multi_Technician__c,
                                                        UNITY_Holiday_Multiplier__c,UNITY_OT_Multiplier__c,UNITY_Holiday_Travel_Multiplier__c,UNITY_OT_Travel_Multiplier__c, UNITY_Default_Labor_Rate__c, UNITY_Trip_Charge__c, UNITY_Trip_Charge_Type__c, UNITY_Invoicing_Increments__c, 
                                                        (SELECT Id, UNITY_Labor_Hours__c, UNITY_Trade__c, UNITY_Trip_Charge__c, UNITY_Trip_Charge_Type__c, UNITY_Cost_Plus__c, UNITY_Labor_Cost__c, UNITY_Product__r.Id, UNTIY_Material_Cost__c, UNITY_Self_Perform_Labor_Cost__c,
                                                         UNITY_Self_Perform_Trip_Charge_Cost__c, UNITY_Self_Perform_Trip_Charge_Type__c, UNITY_Holiday_Multiplier__c,UNITY_OT_Multiplier__c,UNITY_Holiday_Travel_Multiplier__c,UNITY_OT_Travel_Multiplier__c, RecordType.DeveloperName 
                                                         FROM UNITY_Service_Contract_Line_Items__r) FROM UNITY_Service_Contract__c WHERE (Id IN :scIds)];
        Map<Id,UNITY_Service_Contract_Line_Item__c> menuPricingMap = new Map<Id,UNITY_Service_Contract_Line_Item__c>();
        for(UNITY_Service_Contract__c serviceContract: contractList){
            for(UNITY_Service_Contract_Line_Item__c scli: serviceContract.UNITY_Service_Contract_Line_Items__r){
                if(scli.RecordType.DeveloperName == UNITY_Constants.SCLI_MENU_PRICING_RT){
                    menuPricingMap.put(scli.UNITY_Product__r.Id,scli);
                }
            }
        }
        // retrieve the QL items related to the accepted quote
        Map<Id,List<UNITY_Proposal_Line_Item__c>> quoteWithQuoteLinesMap = new Map<Id,List<UNITY_Proposal_Line_Item__c>>();
        List<UNITY_Proposal_Line_Item__c> allQuoteLineItems = new List<UNITY_Proposal_Line_Item__c>();
        List<UNITY_Proposal_Line_Item__c> quoteLineItems = [SELECT Id, UNITY_Cost__c, UNITY_Total_Cost__c, UNITY_Total_Price__c, UNITY_Quantity__c, 
                                                            UNITY_Product__c, UNITY_Is_Labor_Or_Travel_Concerned__c,UNITY_Proposal__c,
                                                            UNITY_Is_Vendor_Supply__c, UNITY_Price__c,UNITY_Product__r.UNITY_Product_Type__c,
                                                            UNITY_Customer_Holiday_Multiplier__c, UNITY_Customer_OT_Multiplier__c,UNITY_Discount_Amount__c,
                                                            UNITY_Vendor_Holiday_Multiplier__c, UNITY_Vendor_OT_Multiplier__c,UNITY_Discount__c,
                                                            UNITY_Number_of_Techs__c, UNITY_Type__c, UNITY_Activity_Type__c, UNITY_PriceBook_Entry_Id__c,
                                                            UNITY_Part_Source__c, UNITY_Part_On_Hand__c, UNITY_Customer_Adjusted_Quantity__c, UNITY_Vendor_Adjusted_Quantity__c,
                                                            UNITY_Asset__c, UNITY_Make__c,UNITY_Model__c,UNITY_Description__c,UNITY_Unit_of_Measure__c,UNITY_Part_Location__c,
                                                            UNITY_MP_Labor_Vendor_Adjusted_Qty__c,UNITY_Not_Billable__c,UNITY_Related_Menu_Price_Line__c,UNITY_MP_Labor_Cost__c,
                                                            MSPFS_MSP_Cost__c,MSPFS_MSP_Price__c,MSPFS_Technician__c,MSPFS_Technician2__c
                                                            FROM UNITY_Proposal_Line_Item__c
                                                            WHERE UNITY_Proposal__c IN: UNITY_Utils.joiningByIdList(quotes)];
        for(UNITY_Proposal_Line_Item__c poli :quoteLineItems){
            if(!quoteWithQuoteLinesMap.containsKey(poli.UNITY_Proposal__c))
                quoteWithQuoteLinesMap.put(poli.UNITY_Proposal__c, new List<UNITY_Proposal_Line_Item__c>());
            quoteWithQuoteLinesMap.get(poli.UNITY_Proposal__c).add(poli);
            allQuoteLineItems.add(poli);
        }
        
        Map<Id,Map<String,List<OrderItem>>> poLinesBySuppliyerMapByQuote = new Map<Id,Map<String,List<OrderItem>>>();
        //Collenct all POLIs in a list to run an insert
        List<OrderItem> polisToInsert = new List<OrderItem>();
        Map<Id,List<OrderItem>> noCostPOLIListByQuote = new Map<Id,List<OrderItem>>();
        Map<Id,Boolean> isNonWorkMap = new Map<Id,Boolean>();
        //Set of Suppliyer Ids
        Set<Id> suppliyerIds = new Set<Id>();
        
        for(Id qid :quoteWithQuoteLinesMap.keySet()){
            if(urByQuoteId.containsKey(qid)){
                if(originatingURMap.containsKey(urByQuoteId.get(qid))){
                    Order currentOrder = originatingURMap.get(urByQuoteId.get(qid));
                    //Get the service contract subtype
                    String scSub = currentOrder.FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__r.UNITY_Contract_Sub_type__c;
                    //Denotes if the WO is Contract Pricing
                    Boolean isContract = (scSub == 'Contract Pricing' && currentOrder.FSO__WorkOrder__r.UNITY_Include__c);
                    //Denotes if the WO is Menu Pricing
                    Boolean isMenuPrice = (scSub == 'Menu Pricing' && currentOrder.FSO__WorkOrder__r.UNITY_Use_Menu_Pricing__c);
                    //Denotes if the WO is Non-Work
                    Boolean isNonWork = (currentOrder.FSO__WorkOrder__r.RecordTypeId == UNITY_Constants.WO_NON_WORK_RECORDTYPE);
                    isNonWorkMap.put(qid,isNonWork);
                    //Map to hold new POLIs by Suppliyer
                    Map<String,List<OrderItem>> poLinesBySuppliyerMap = new Map<String,List<OrderItem>>();
                    //List to hold $0 lines for Vendor Supply PO
                    List<OrderItem> noCostPOLIList = new List<OrderItem>();
                    for(UNITY_Proposal_Line_Item__c quoteLineItem: quoteWithQuoteLinesMap.get(qid)){
                        if(String.isBlank(quoteLineItem.UNITY_Related_Menu_Price_Line__c)){
                            //Check if the line product is in the menu pricing map
                            Boolean isMPProd = menuPricingMap.containsKey(quoteLineItem.UNITY_Product__c);
                            Boolean isCPLine = false;
                            Boolean isVendorSource = (currentOrder.UNITY_Vendor__c == quoteLineItem.UNITY_Part_Source__c);
                            //Get the line product type 
                            String productType = quoteLineItem.UNITY_Product__r.UNITY_Product_Type__c;
                            
                            //Create the new OrderItem for the new PO
                            OrderItem orderItem = new OrderItem();
                            orderItem.Quantity = quoteLineItem.UNITY_Quantity__c;
                            System.debug(' >>> quoteLineItem.UNITY_PriceBook_Entry_Id__c '+quoteLineItem.UNITY_PriceBook_Entry_Id__c);
                            System.debug(' >>> (Id)quoteLineItem.UNITY_PriceBook_Entry_Id__c '+(Id)quoteLineItem.UNITY_PriceBook_Entry_Id__c);
                            
                            orderItem.PricebookEntryId = (Id)quoteLineItem.UNITY_PriceBook_Entry_Id__c;
                            orderItem.UNITY_Customer_Adjusted_Quantity__c = quoteLineItem.UNITY_Customer_Adjusted_Quantity__c==null?0:quoteLineItem.UNITY_Customer_Adjusted_Quantity__c;
                            orderItem.UNITY_Vendor_Adjusted_Quantity__c = quoteLineItem.UNITY_Vendor_Adjusted_Quantity__c==null?0:quoteLineItem.UNITY_Vendor_Adjusted_Quantity__c;
                            orderItem.UNITY_Cost__c = quoteLineItem.UNITY_Cost__c==null?0:quoteLineItem.UNITY_Cost__c;
                            orderItem.UNITY_Price__c = quoteLineItem.UNITY_Price__c==null?0:quoteLineItem.UNITY_Price__c;
                            orderItem.UNITY_Total_Cost__c = quoteLineItem.UNITY_Total_Cost__c==null?0:quoteLineItem.UNITY_Total_Cost__c;
                            orderItem.UNITY_Total_Price__c = quoteLineItem.UNITY_Total_Price__c==null?0:quoteLineItem.UNITY_Total_Price__c;
                            orderItem.UNITY_Number_of_Techs__c = quoteLineItem.UNITY_Number_of_Techs__c;
                            orderItem.UnitPrice = orderItem.UnitPrice==null?0:orderItem.UnitPrice;
                            orderItem.UNITY_Type__c = quoteLineItem.UNITY_Type__c;
                            orderItem.UNITY_Activity_Type__c = quoteLineItem.UNITY_Activity_Type__c;
                            orderItem.UNITY_Is_Vendor_Supply__c = quoteLineItem.UNITY_Is_Vendor_Supply__c;
                            orderItem.UNITY_Part_Source__c = quoteLineItem.UNITY_Part_Source__c;
                            orderItem.UNITY_Part_Location__c = quoteLineItem.UNITY_Part_Location__c;
                            orderItem.UNITY_Part_On_Hand__c = quoteLineItem.UNITY_Part_On_Hand__c;
                            orderItem.UNITY_Asset__c = quoteLineItem.UNITY_Asset__c;
                            //Izay: propagate unknown/special part info
                            orderItem.UNITY_Make__c = quoteLineItem.UNITY_Make__c;
                            orderItem.UNITY_Model__c = quoteLineItem.UNITY_Model__c;
                            orderItem.UNITY_Unit_of_Measure__c = quoteLineItem.UNITY_Unit_of_Measure__c;
                            orderItem.Description = quoteLineItem.UNITY_Description__c;
                            //Nat: propagate Multiplier fields
                            orderItem.UNITY_Customer_Holiday_Multiplier__c = quoteLineItem.UNITY_Customer_Holiday_Multiplier__c;
                            orderItem.UNITY_Customer_OT_Multiplier__c = quoteLineItem.UNITY_Customer_OT_Multiplier__c;
                            orderItem.UNITY_Vendor_Holiday_Multiplier__c = quoteLineItem.UNITY_Vendor_Holiday_Multiplier__c;
                            orderItem.UNITY_Vendor_OT_Multiplier__c = quoteLineItem.UNITY_Vendor_OT_Multiplier__c;
                            //Izay: Propagate adjustment fields
                            orderItem.UNITY_Discount__c = quoteLineItem.UNITY_Discount__c;
                            orderItem.UNITY_Discount_Amount__c = quoteLineItem.UNITY_Discount_Amount__c;
                            orderItem.UNITY_Not_Billable__c = quoteLineItem.UNITY_Not_Billable__c;
                            orderItem.UNITY_MP_Labor_Vendor_Adjusted_Qty__c = quoteLineItem.UNITY_MP_Labor_Vendor_Adjusted_Qty__c;
                            orderItem.UNITY_MP_Labor_Cost__c = quoteLineItem.UNITY_MP_Labor_Cost__c;
                            //Izay: include fields for intercompany transfer
                            orderItem.MSPFS_MSP_Cost__c = quoteLineItem.MSPFS_MSP_Cost__c;
                            orderItem.MSPFS_MSP_Price__c = quoteLineItem.MSPFS_MSP_Price__c;
                            orderItem.MSPFS_Technician__c = quoteLineItem.MSPFS_Technician__c;
                            orderItem.MSPFS_Technician2__c = quoteLineItem.MSPFS_Technician2__c;
                            //If the line is vebdor supply or contract price include or menu price 
                            //or is a non-work wo and the source is the same as the vendor on the usage request...
                            if(quoteLineItem.UNITY_Is_Vendor_Supply__c || (isContract && isCPLine) || (isMenuPrice && isMPProd) || (isNonWork && isVendorSource)){
                                //Add to poLinesBySuppliyerMap as VENDORSUPPLY
                                if(!poLinesBySuppliyerMap.containsKey('VENDORSUPPLY'))
                                    poLinesBySuppliyerMap.put('VENDORSUPPLY',new List<OrderItem>());
                                poLinesBySuppliyerMap.get('VENDORSUPPLY').add(orderItem);
                                suppliyerIds.add(currentOrder.UNITY_Vendor__c);
                            }else{
                                //If it is a non-work wo and has a Part Source...
                                //Add to poLinesBySuppliyerMap by UNITY_Part_Source__c
                                if(isNonWork && String.isNotBlank(quoteLineItem.UNITY_Part_Source__c)){
                                    if(!poLinesBySuppliyerMap.containsKey(quoteLineItem.UNITY_Part_Source__c))
                                        poLinesBySuppliyerMap.put(quoteLineItem.UNITY_Part_Source__c,new List<OrderItem>());
                                    poLinesBySuppliyerMap.get(quoteLineItem.UNITY_Part_Source__c).add(orderItem);
                                    suppliyerIds.add(quoteLineItem.UNITY_Part_Source__c);
                                    //Otherwise, add to poLinesBySuppliyerMap as NONE (No suppliyer)
                                }else{
                                    if(!poLinesBySuppliyerMap.containsKey('NONE'))
                                        poLinesBySuppliyerMap.put('NONE',new List<OrderItem>());
                                    poLinesBySuppliyerMap.get('NONE').add(orderItem);
                                    if(!isNonWork){
                                        //$0 Line for Vendor Suppy PO
                                        OrderItem noCostPOLI = orderItem.clone();
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
                            polisToInsert.add(orderItem);
                        }
                            
                    }
                    poLinesBySuppliyerMapByQuote.put(qid,poLinesBySuppliyerMap);
                    noCostPOLIListByQuote.put(qid,noCostPOLIList);
                }
            }
        }
        //Need to check if there are existing WO for Suppliyer in Parts Order Required status
        Map<Id,WorkOrder> workOrdersMap = 
            new Map<Id,WorkOrder>([SELECT Id,CaseId,UNITY_Assigned_Vendor__c,
                                   (
                                       SELECT Id,RecordTypeId,Status FROM FSO__Orders__r 
                                       WHERE RecordTypeId = :UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE 
                                       AND Status = :UNITY_Constants.ORDER_STATUS_PART_ORDER_REQUIRED
                                   ) 
                                   FROM WorkOrder WHERE CaseId IN :caseIds AND UNITY_Assigned_Vendor__c IN :suppliyerIds]);
        
        System.debug('#####Izay: workOrdersMap = ' + JSON.serializePretty(workOrdersMap));
        
        //Put the work order by Assigned vendor Id
        Map<String,WorkOrder> woVendorMap = new Map<String,WorkOrder>();
        for(WorkOrder wo :workOrdersMap.values()){
            woVendorMap.put(wo.UNITY_Assigned_Vendor__c,wo);
        }
        
        Map<Id,Map<String,Order>> newPOsByQuote = new Map<Id,Map<String,Order>>();
        Map<Id,Map<String,WorkOrder>> newWOsByQuote = new Map<Id,Map<String,WorkOrder>>();
        Map<Id,Map<String,Id>> oldPOsByQuote = new Map<Id,Map<String,Id>>();
        System.debug('#####Izay: poLinesBySuppliyerMapByQuote = ' + JSON.serializePretty(poLinesBySuppliyerMapByQuote));
        for(Id qid :poLinesBySuppliyerMapByQuote.keySet()){
            if(urByQuoteId.containsKey(qid)){
                if(originatingURMap.containsKey(urByQuoteId.get(qid))){
                    Order currentOrder = originatingURMap.get(urByQuoteId.get(qid));
                    Map<String,Order> newPOs = new Map<String,Order>();//Holds the POs to be created from the usage request by Suppliyer
                    Map<String,WorkOrder> newWOs = new Map<String,WorkOrder>();//Holds the WOs to be created from the usage request by Suppliyer
                    Map<String,Id> oldPOs = new Map<String,Id>();
                    //Denotes if the WO is Non-Work
                    Boolean isNonWork = isNonWorkMap.get(qid);
                    System.debug('#####Izay: poLinesBySuppliyerMap = ' + JSON.serializePretty(poLinesBySuppliyerMapByQuote.get(qid)));
                    System.debug('#####Izay: isNonWork = ' + JSON.serializePretty(isNonWork));
                    //Iterate through each suppliyer found (VENDORSUPPLY, NONE, NOCOST, or Id)
                    for(String s :poLinesBySuppliyerMapByQuote.get(qid).keySet()){
                        //If it is a Service WO... Expecting only VENDORSUPPLY or NONE
                        if(!isNonWork){
                            Order o = currentOrder.clone();//Clone the usage request
                            o.Pricebook2Id = standardPriceBookId;//Set the pricebookid
                            o.UNITY_Originating_Usage_Request__c = currentOrder.Id;//Set the originating from usage request
                            o.OwnerId = currentOrder.FSO__WorkOrder__r.UNITY_Agent__c; 
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
                                s = 'VENDORSUPPLY';//Set s to VENDORSUPPLY
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
                            o.OwnerId = currentOrder.FSO__WorkOrder__r.UNITY_Agent__c;
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
                                    //Set new WO Owner as logged in user
                                    wo.OwnerId = currentOrder.FSO__WorkOrder__r.UNITY_Agent__c;
                                    newWOs.put(s,wo);//Add Work Order to map by suppliyer
                                }
                            }
                            newPOs.put(s,o);//Add to newPOs map by suppliyer
                        }
                    }//End for POLIs By Suppliyer
                    System.debug('#####Izay: newWOs = ' + JSON.serializePretty(newWOs));
                    System.debug('#####Izay: newPOs = ' + JSON.serializePretty(newPOs));
                    System.debug('#####Izay: oldPOs = ' + JSON.serializePretty(oldPOs));
                    if(!newWOs.values().isEmpty())
                        newWOsByQuote.put(qid,newWOs);
                    if(!newPOs.values().isEmpty())
                        newPOsByQuote.put(qid,newPOs);
                    if(!oldPOs.values().isEmpty())
                        oldPOsByQuote.put(qid,oldPOs);
                    System.debug('#####Izay: newWOsByQuote = ' + JSON.serializePretty(newWOsByQuote));
                    System.debug('#####Izay: newPOsByQuote = ' + JSON.serializePretty(newPOsByQuote));
                    System.debug('#####Izay: oldPOsByQuote = ' + JSON.serializePretty(oldPOsByQuote));
                }
            }
        }
        
        //All the work orders to insert
        List<WorkOrder> allToInsertWO = new List<WorkOrder>();
        List<Order> allToInsertOrders = new List<Order>();
        //For each quote
        for(Id qid :poLinesBySuppliyerMapByQuote.keySet()){
            //If there are new work orders... add them to the to inser WOs list 
            if(newWOsByQuote.containsKey(qid))
                allToInsertWO.addAll(newWOsByQuote.get(qid).values());
        }
        //If there are new WOs in the newWOs map...
        if(!allToInsertWO.isEmpty()){
            try{
                System.debug('#####Izay: allToInsertWO = ' + JSON.serializePretty(allToInsertWO));
                insert allToInsertWO;//Insert the new WOs
                message += 'Success: Work Order for Supplier(s) created...<br/>';
            }catch(Exception e){
                message = 'Error: ' + e.getMessage();
                result.put('success','false');
                Database.rollback(sp);
            }
        }
        
        //For each quote
        for(Id qid :poLinesBySuppliyerMapByQuote.keySet()){
            //Denotes if the WO is Non-Work
            Boolean isNonWork = isNonWorkMap.get(qid);
            
            if(newPOsByQuote.containsKey(qid)){
                //For each PO created... related to a WO either existing one or new one
                if(isNonWork){
                    for(String s :newPOsByQuote.get(qid).keySet()){
                        if(woVendorMap.containsKey(s)){
                            newPOsByQuote.get(qid).get(s).FSO__WorkOrder__c = woVendorMap.get(s).Id;//Set the WO on the PO for the suppliyer
                        }else if(newWOsByQuote.containsKey(qid)){
                            if(newWOsByQuote.get(qid).containsKey(s))
                                newPOsByQuote.get(qid).get(s).FSO__WorkOrder__c = newWOsByQuote.get(qid).get(s).Id;//Set the WO on the PO for the suppliyer
                        }
                    }
                }//Else id not Non Work
                //If there are POs to inser... add them to the to insert POs list
                allToInsertOrders.addAll(newPOsByQuote.get(qid).values());
            }
            
        }//End for qid
        
        //If there are new POs in newPOs map...
        if(!allToInsertOrders.isEmpty()){
            try{
                System.debug('#####Izay: allToInsertOrders = ' + JSON.serializePretty(allToInsertOrders));
                insert allToInsertOrders;//insert the new POs
                message += 'Success: Purchase Order(s) created...<br/>';
                //For each quote
                for(Id qid :poLinesBySuppliyerMapByQuote.keySet()){
                    if(urByQuoteId.containsKey(qid)){
                        if(originatingURMap.containsKey(urByQuoteId.get(qid))){
                            Order currentOrder = originatingURMap.get(urByQuoteId.get(qid));
                            if(newPOsByQuote.containsKey(qid)){
                                for(String s :newPOsByQuote.get(qid).keySet()){
                                    String key = '';
                                    if(s == 'NONE')
                                        continue;
                                    if(s == 'VENDORSUPPLY')
                                        key = currentOrder.UNITY_Vendor__c;
                                }
                            }
                        }
                    }
                }
            }catch(Exception e){
                message = 'Error: ' + e.getMessage();
                result.put('success','false');
                Database.rollback(sp);
            }
        }
        
        //For each quote
        for(Id qid :poLinesBySuppliyerMapByQuote.keySet()){
            //Denotes if the WO is Non-Work
            Boolean isNonWork = isNonWorkMap.get(qid);
            //For each PO created...
            for(String s :poLinesBySuppliyerMapByQuote.get(qid).keySet()){
                //Find the PO for the POLI Suppliyer (VENDORSUPPLY, NONE, NOCOST, or Id)
                Boolean oidFound = false;
                if(oldPOsByQuote.containsKey(qid)){
                    if(oldPOsByQuote.get(qid).containsKey(s)){
                        for(OrderItem oi :poLinesBySuppliyerMapByQuote.get(qid).get(s)){
                            oi.OrderId = oldPOsByQuote.get(qid).get(s);//Associate the POLI to the appropriate PO
                            oidFound = true;
                        }
                    }
                }
                if(!oidFound){
                    if(newPOsByQuote.containsKey(qid)){
                        if(newPOsByQuote.get(qid).containsKey(s)){
                            for(OrderItem oi :poLinesBySuppliyerMapByQuote.get(qid).get(s)){
                                oi.OrderId = newPOsByQuote.get(qid).get(s).Id;//Associate the POLI to the appropriate PO
                            }
                        }
                    }
                    if(s == 'NOCOST' && !isNonWork){
                        if(newPOsByQuote.containsKey(qid)){
                            if(newPOsByQuote.get(qid).containsKey('VENDORSUPPLY')){
                                for(OrderItem oi :poLinesBySuppliyerMapByQuote.get(qid).get(s)){
                                    oi.OrderId = newPOsByQuote.get(qid).get('VENDORSUPPLY').Id;//Associate the POLI to the appropriate PO
                                }
                            }
                        }
                    }
                }
            }
        }
        
        //After modifying and associating all POLIs to their respective POs...
        //Run an insert
        if(!polisToInsert.isEmpty()){
            try{
                System.debug('#####Izay: polisToInsert = ' + JSON.serializePretty(polisToInsert));
                insert polisToInsert;
                message += 'Success: Purchase Order Line Item(s) created...<br/>';
            }catch(Exception e){
                message = 'Error: ' + e.getMessage();
                result.put('success','false');
                Database.rollback(sp);
            }
        }
        
        //For each quote
        //related No Cost Lines to PO Lines
        List<OrderItem> poliToUpdate = new List<OrderItem>();
        for(Id qid :poLinesBySuppliyerMapByQuote.keySet()){
            //Denotes if the WO is Non-Work
            Boolean isNonWork = isNonWorkMap.get(qid);
            if(!isNonWork){
                if(poLinesBySuppliyerMapByQuote.get(qid).containsKey('NONE')){
                    Integer i = 0;
                    for(OrderItem oi :poLinesBySuppliyerMapByQuote.get(qid).get('NONE')){
                        if(poLinesBySuppliyerMapByQuote.get(qid).containsKey('NOCOST')){
                            OrderItem noCostPOLI = poLinesBySuppliyerMapByQuote.get(qid).get('NOCOST').get(i);
                            noCostPOLI.UNITY_Related_Order_Product__c = oi.Id;
                            oi.UNITY_Related_Order_Product__c = noCostPOLI.Id;
                            poliToUpdate.add(noCostPOLI);
                            poliToUpdate.add(oi);
                            i++;
                        }
                    }
                }
            }
        }
        
        if(!poliToUpdate.isEmpty()){
            try{
                //update poliToUpdate;
                UNITY_UsageRequestHandler.updateRelatedOrderItems(JSON.serialize(poliToUpdate));
                message += 'Success: Associated $0 Purchase Order Line Item(s) to Part Souring Purchase Order Line Item(s)...<br/>';
            }catch(Exception e){
                message = 'Error: ' + e.getMessage();
                result.put('success','false');
            }
        }
        
        if(!urIds.isEmpty() && result.get('success') == 'true')
            updateUsageRequestStatus(urIds,'PO Created');
        return result;
    }
    @future
    public static void updateUsageRequestStatus(Set<Id> urIds,String status){
        UNITY_Constants.isExecutingContext('updateUsageRequestStatus');
        System.debug('#####Izay: In updateUsageRequestStatus ');
        if(!urIds.isEmpty()){
            List<Order> orders = [SELECT Id,Status FROM Order WHERE Id IN :urIds];
            for(Order o :orders){
                o.Status = status;
            }
            System.debug('#####Izay: orders = ' + JSON.serializePretty(orders));
            update orders;
        }
    }
}