public with sharing class UNITY_WorkOrderTriggerHandlerHelper {

    public static void adjustLaborHours(Set<Id> workOrderIdSet){
        
        Map<Id, Double> vendorAdjustedDurationMap = new Map<Id, Double>();
        Map<Id, Double> customerAdjustedDurationMap = new Map<Id, Double>();
        
        //Set<Id> vendorContractIdSet = new Set<Id>();
        //Set<Id> customerContractIdSet = new Set<Id>();
        Set<Id> scIds = new Set<Id>();
        
        //get work orders
        Map<Id, WorkOrder> workOrdeMap = new Map<Id, WorkOrder>([select id,WorkOrderNumber,UNITY_Accepted_Vendor__c,UNITY_Customer_Service_Contract__c, UNITY_Vendor_Contract__c, SFPS_FS_TotalServiceTime__c from WorkOrder where id in:workOrderIdSet]);
        
        for (WorkOrder iter: workOrdeMap.values()){
            //Izay: Added validation for missing customer service contract on WO
            //Izay: Added validation for missing vebndor service contract if has accepted vendor on WO
            //vendorContractIdSet.add(iter.UNITY_Customer_Service_Contract__c);
            //customerContractIdSet.add(iter.UNITY_Vendor_Contract__c);
            if(String.isBlank(iter.UNITY_Customer_Service_Contract__c) && !Test.isRunningTest())
                Trigger.new[0].addError('  ' + iter.WorkOrderNumber + ' is missing the customer service contract.');
            else
                scIds.add(iter.UNITY_Customer_Service_Contract__c);
            if(String.isBlank(iter.UNITY_Vendor_Contract__c) && String.isNotBlank(iter.UNITY_Accepted_Vendor__c) && !Test.isRunningTest()){
                Trigger.new[0].addError('  ' + iter.WorkOrderNumber + ' is missing the vendor service contract for the accepted vendor.');
            }else{
                scIds.add(iter.UNITY_Vendor_Contract__c);
            }
        }
        
        if(!scIds.isEmpty()){
            
            Map<Id, UNITY_Service_Contract__c> serviceContractMap = new Map<Id, UNITY_Service_Contract__c>([select id, UNITY_Is_Pass_Through__c, UNITY_Invoicing_Increments__c, UNITY_Minimum_Labor_Hours__c from UNITY_Service_Contract__c where Id IN :scIds /*in:vendorContractIdSet or Id in:customerContractIdSet*/]);
            
            Map<Id, Boolean> isCustomerThrough = new Map<Id, Boolean>();
            Map<Id, Boolean> needsVendorAdjustment = new Map<Id, Boolean>();
            Map<Id, Boolean> needsCustomerAdjustment = new Map<Id, Boolean>();
            
            //round duration time based on contract information
            for (WorkOrder iter: workOrdeMap.values()){
                
                Double vendorAdjustedDuration = iter.SFPS_FS_TotalServiceTime__c;
                Double customerAdjustedDuration = iter.SFPS_FS_TotalServiceTime__c;
                System.debug('#####Izay: Before UNITY_PriceCalculation.roundLaborHours');
                System.debug('#####Izay: vendorAdjustedDuration = '+vendorAdjustedDuration);
                System.debug('#####Izay: customerAdjustedDuration = '+customerAdjustedDuration);
                UNITY_Service_Contract__c customerSC;
                UNITY_Service_Contract__c vendorSC;
                //Izay: Assign cust service contract
                if(String.isNotBlank(iter.UNITY_Customer_Service_Contract__c))
                    if(serviceContractMap.containsKey(iter.UNITY_Customer_Service_Contract__c))
                        customerSC = serviceContractMap.get(iter.UNITY_Customer_Service_Contract__c);
                //Izay:Assign the vendor service contract
                if(String.isNotBlank(iter.UNITY_Vendor_Contract__c))
                    if(serviceContractMap.containsKey(iter.UNITY_Vendor_Contract__c))
                        vendorSC = serviceContractMap.get(iter.UNITY_Vendor_Contract__c);
                //Izay: Round the labor hrs for customer and vendor if not missing service contracts on WO
                if(customerSC != null){
                    customerAdjustedDuration = UNITY_PriceCalculation.roundLaborHours(customerAdjustedDuration, customerSC.UNITY_Invoicing_Increments__c, customerSC.UNITY_Minimum_Labor_Hours__c);
                    isCustomerThrough.put(iter.Id, customerSC.UNITY_Is_Pass_Through__c);
                    needsCustomerAdjustment.put(iter.Id, customerSC.UNITY_Invoicing_Increments__c != null);
                }
                if(vendorSC != null){
                    vendorAdjustedDuration = UNITY_PriceCalculation.roundLaborHours(vendorAdjustedDuration, vendorSC.UNITY_Invoicing_Increments__c, vendorSC.UNITY_Minimum_Labor_Hours__c);
                    needsVendorAdjustment.put(iter.Id, vendorSC.UNITY_Invoicing_Increments__c != null);
                }
                System.debug('#####Izay: After UNITY_PriceCalculation.roundLaborHours');
                System.debug('#####Izay: vendorAdjustedDuration = '+vendorAdjustedDuration);
                System.debug('#####Izay: customerAdjustedDuration = '+customerAdjustedDuration);
                //Izay: Add the customer and vendor adjusted duration to the durations map dividing by 60 if adjustment is greater than 0
                customerAdjustedDurationMap.put(iter.Id, (customerAdjustedDuration > 0 ? customerAdjustedDuration/60 : customerAdjustedDuration));
                vendorAdjustedDurationMap.put(iter.Id, (vendorAdjustedDuration > 0 ? vendorAdjustedDuration/60 : vendorAdjustedDuration));
                                
            }
            
            System.debug('#####Izay: needsVendorAdjustment = '+needsVendorAdjustment);
            System.debug('#####Izay: needsCustomerAdjustment = '+needsCustomerAdjustment);
            System.debug('#####Izay: isCustomerThrough = '+isCustomerThrough);
            //adjust poli quantity
            //Izay: Updated to get labor lines from Purchase Order only
            List<OrderItem> relatedOrderItem = [SELECT Id,OrderItemNumber,Order.FSO__WorkOrder__c,UNITY_Cost_Calculation_Details__c,UNITY_Price_Calculation_Details__c,
                                                UNITY_Customer_Adjusted_Quantity__c,UNITY_Vendor_Adjusted_Quantity__c,UNITY_Related_Menu_Price_Line__c,UNITY_Not_Billable__c 
                                                FROM OrderItem WHERE Order.FSO__WorkOrder__c IN:workOrderIdSet 
                                                AND Order.RecordTypeId = :UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE
                                                AND PricebookEntry.Product2.UNITY_Product_Type__c = 'Labor'];
            //Map<WorkOrderId, LaborPOLI>
            Map<Id, OrderItem> lastLaborPOLIMap = new Map<Id, OrderItem>();
            
            if(!relatedOrderItem.isEmpty()){
                for (OrderItem iter: relatedOrderItem){
                    SYstem.debug('#####Izay: IN ' + iter.OrderItemNumber);
                    Id workOrderId = iter.Order.FSO__WorkOrder__c;
                    
                    Double customerAdjustedQtty = iter.UNITY_Customer_Adjusted_Quantity__c;
                    Double vendorAdjustedQtty = iter.UNITY_Vendor_Adjusted_Quantity__c;
                    Double vendorDuration = vendorAdjustedDurationMap.get(workOrderId);
                    Double customerDuration = customerAdjustedDurationMap.get(workOrderId);
                    
                    System.debug('#####Izay: customerAdjustedQtty = '+customerAdjustedQtty);
                    System.debug('#####Izay: vendorAdjustedQtty = '+vendorAdjustedQtty);
                    System.debug('#####Izay: vendorDuration = '+vendorDuration);
                    System.debug('#####Izay: customerDuration = '+customerDuration);
                    System.debug('#####Izay: needsVendorAdjustment = '+needsVendorAdjustment.containsKey(workOrderId));
                    if(needsVendorAdjustment.containsKey(workOrderId)){
                        if(needsVendorAdjustment.get(workOrderId)){
                            if (vendorAdjustedQtty <= vendorDuration){
                                vendorDuration -= vendorAdjustedQtty;
                            }
                            else if (vendorDuration == 0){
                                //iter.UNITY_Cost_Calculation_Details__c += '\n\nQuantity adjusted based on Service Time, from '+vendorAdjustedQtty+' to 0';
                                vendorAdjustedQtty = 0;
                            }
                            else{
                                //iter.UNITY_Cost_Calculation_Details__c += '\n\nQuantity adjusted based on Service Time, from '+vendorAdjustedQtty+' to '+vendorDuration;
                                vendorAdjustedQtty = vendorDuration;
                                vendorDuration = 0;
                            }
                            iter.UNITY_Vendor_Adjusted_Quantity__c = vendorAdjustedQtty;
                        }
                        vendorAdjustedDurationMap.put(workOrderId, vendorDuration);
                    }
                    System.debug('#####Izay: needsCustomerAdjustment = '+needsCustomerAdjustment.containsKey(workOrderId));
                    if(needsCustomerAdjustment.containsKey(workOrderId)){
                        if(needsCustomerAdjustment.get(workOrderId) && !isCustomerThrough.get(workOrderId) && 
                           !iter.UNITY_Not_Billable__c && String.isBlank(iter.UNITY_Related_Menu_Price_Line__c)){
                               if (customerAdjustedQtty <= customerDuration){
                                   customerDuration -= customerAdjustedQtty;
                               }
                               else if (customerDuration == 0){
                                   //iter.UNITY_Price_Calculation_Details__c += '\n\nQuantity adjusted based on Service Time, from '+customerAdjustedQtty+' to 0';
                                   customerAdjustedQtty = 0;
                               }
                               else{
                                   //iter.UNITY_Price_Calculation_Details__c += '\n\nQuantity adjusted based on Service Time, from '+customerAdjustedQtty+' to '+customerDuration;
                                   customerAdjustedQtty = customerDuration;
                                   customerDuration = 0;
                               }
                               iter.UNITY_Customer_Adjusted_Quantity__c = customerAdjustedQtty;
                           }
                        customerAdjustedDurationMap.put(workOrderId, customerDuration);
                    }
                    lastLaborPOLIMap.put(workOrderId, iter);
                }
                
                for(WorkOrder iter: workOrdeMap.values()){
                    
                    //add the remaining time to the last labor poli
                    OrderItem lastLaborPOLI; 
                    if(lastLaborPOLIMap.containsKey(iter.Id))
                       lastLaborPOLI = lastLaborPOLIMap.get(iter.Id);
                    
                    System.debug('#lastLaborPOLI '+lastLaborPOLI);
                    
                    if(lastLaborPOLI != null){
                        if(vendorAdjustedDurationMap.containsKey(iter.Id)){
                            if(vendorAdjustedDurationMap.get(iter.Id) != 0 && needsVendorAdjustment.get(iter.Id)){
                                
                                Double duration = vendorAdjustedDurationMap.get(iter.Id);
                                
                                System.debug('#remainingVendorDuration '+duration);
                                
                                Double vendorAdjustedQtty = lastLaborPOLI.UNITY_Vendor_Adjusted_Quantity__c;
                                
                                if (needsVendorAdjustment.get(iter.Id)){
                                    vendorAdjustedQtty += duration;
                                    lastLaborPOLI.UNITY_Vendor_Adjusted_Quantity__c = vendorAdjustedQtty;
                                }
                            }
                        }
                        
                        if(customerAdjustedDurationMap.containsKey(iter.Id)){
                            if (customerAdjustedDurationMap.get(iter.Id) != 0 && needsCustomerAdjustment.get(iter.Id) && !isCustomerThrough.get(iter.Id)){
                                
                                Double duration = customerAdjustedDurationMap.get(iter.Id);
                                
                                System.debug('#remainingCustomerDuration '+duration);
                                
                                Double customerAdjustedQtty = lastLaborPOLI.UNITY_Customer_Adjusted_Quantity__c;
                                 
                                if (needsCustomerAdjustment.get(iter.Id) && !isCustomerThrough.get(iter.Id)&& 
                                    !lastLaborPOLI.UNITY_Not_Billable__c && String.isBlank(lastLaborPOLI.UNITY_Related_Menu_Price_Line__c)){
                                        customerAdjustedQtty += duration;
                                        lastLaborPOLI.UNITY_Customer_Adjusted_Quantity__c = customerAdjustedQtty;
                                    }
                            }
                        }
                    }
                }    
                
                System.debug('#relatedOrderItem '+relatedOrderItem);
                update relatedOrderItem;
            }
            
        }
        
    }
    
    /*
     *  @param workOrderIds for SFPS_Overall_Status = Completed
     *  
     *  When SFPS_Overall_Status = Completed, looks thru all POLI that Vendor = WO.Accepted Vendor and Status = Accepted, 
     *  if WO.BelowMarginCheckBox__c = sum(POLI.UNITY_Price__c - POLI.UNITY_Cost__c) / sum(POLI.UNITY_Price__c) < WO.UNITY_Customer_Margin__c,
     *  where POLI is labor type POLI, mark WO.UNITY_BelowMargin_Actual = Yes 
     * 
     *  When SFPS_Overall_Status = Completed (same trigger in 5-ii), looks thru all POLI that Vendor = WO.Accepted Vendor and Status = Final, 
     *  if there are more than one POLI that has Travel, mark WO.UNITY_MultiTrip_Actual = Yes
    */
    public static void adjustLaborRateAboveOrBelowMarginAndMultiTrip(Map<Id,WorkOrder> workOrderMap) {
      
        System.debug('<RB> : workOrderMap : '+workOrderMap);
        // sum(POLI.UNITY_Price__c - POLI.UNITY_Cost__c)
        Map<Id,Decimal> workOrderMarginSum = new Map<Id,Decimal>();
        // sum(POLI.UNITY_Price__c)
        Map<Id,Decimal> workOrderTotalPriceSum = new Map<Id,Decimal>();
        
        Map<Id,Integer> workOrderTotalTravels = new Map<Id,Integer>();
        
        for(WorkOrder workOrder : [SELECT Id, UNITY_Accepted_Vendor__c, UNITY_Customer_Margin__c, UNITY_BelowMargin_Actual__c,
                                   (SELECT Id, UNITY_Vendor__c, UNITY_Total_Labor_Margin__c, UNITY_Total_Labor_Price__c,
                                    UNITY_Total_Travels_Quantity__c,Status
                                    FROM FSO__Orders__r
                                    WHERE (Status = 'Accepted' OR
                                           Status = 'Final') AND
                                    RecordTypeId =: UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE)
                                   FROM WorkOrder
                                   WHERE Id IN : UNITY_Utils.joiningByIdList(workOrderMap.values())]){
            Decimal currentMarginSum = 0;
            Decimal currentTotalPriceSum = 0;
            Integer currentTotalTravelSum = 0;
            for(Order order : workOrder.FSO__Orders__r) {
                if(order.UNITY_Vendor__c == workOrder.UNITY_Accepted_Vendor__c) {
                    if(order.Status == 'Accepted') {
                        if(workOrderMarginSum.get(workOrder.Id) != null){
                            currentMarginSum = workOrderMarginSum.get(workOrder.Id);
                        }
                        currentMarginSum += order.UNITY_Total_Labor_Margin__c;
                        workOrderMarginSum.put(workOrder.Id, currentMarginSum);
                       
                        if(workOrderTotalPriceSum.get(workOrder.Id) != null){
                            currentTotalPriceSum = workOrderTotalPriceSum.get(workOrder.Id);
                        }
                        currentTotalPriceSum += order.UNITY_Total_Labor_Price__c;
                        workOrderTotalPriceSum.put(workOrder.Id, currentTotalPriceSum); 
                    } else if(order.Status == 'Final') {
                        if(workOrderTotalTravels.get(workOrder.Id) != null){
                            currentTotalTravelSum = workOrderTotalTravels.get(workOrder.Id);
                        }
                        currentTotalTravelSum += (Integer)order.UNITY_Total_Travels_Quantity__c;
                        workOrderTotalTravels.put(workOrder.Id, currentTotalTravelSum);
                    }
                       
                }
            }
            
            WorkOrder workOrderToUpdate = workOrderMap.get(workOrder.Id);
            // update the work order UNITY_BelowMargin_Actual field
            workOrderToUpdate.UNITY_BelowMargin_Actual__c = workOrderTotalPriceSum.get(workOrder.Id) != null &&
                                                    workOrderTotalPriceSum.get(workOrder.Id) != 0 &&
                                                    workOrderMarginSum.get(workOrder.Id)/workOrderTotalPriceSum.get(workOrder.Id) < workOrder.UNITY_Customer_Margin__c;
            System.debug('<RB> : workOrderToUpdate.UNITY_BelowMargin_Actual__c : '+workOrderToUpdate.UNITY_BelowMargin_Actual__c);
            
            // update the work order UNITY_MultiTrip_Actual__c field
            //workOrderToUpdate.UNITY_MultiTrip_Actual__c = workOrderTotalTravels.get(workOrder.Id) != null &&
            //                                      workOrderTotalTravels.get(workOrder.Id) > 0;
            System.debug('<RB> : workOrderToUpdate.UNITY_MultiTrip_Actual__c : '+workOrderToUpdate.UNITY_MultiTrip_Actual__c);
            System.debug('<RB> : workOrderToUpdate : '+workOrderToUpdate);
            
        }
        
    }
    
    public static void propagateIncludeFieldValue(List<WorkOrder> workOrderList){
        
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(workOrderList);
        
        Map<string,UNITY_General_Settings__c> generalSettings = UNITY_General_Settings__c.getAll();
        
        UNITY_General_Settings__c generalSetting = generalSettings.get(UNITY_Constants.PO_INVOICEABLE_STATUSES);
        
        Map<Id, Id> customerServiceContractIdMap = new Map<Id, Id>();
        
        for (WorkOrder iter: workOrderList){
            customerServiceContractIdMap.put(iter.Id, iter.UNITY_Customer_Service_Contract__c);
        }
        
        Map<Id, Map<Id, UNITY_Service_Contract_Line_Item__c>> serviceContractLineItemMap = new Map<Id, Map<Id, UNITY_Service_Contract_Line_Item__c>>();
        
        List<UNITY_Service_Contract__c> serviceContractList = [SELECT Id, (SELECT Id,UNITY_Exclude__c,UNITY_Inclusion__c,UNITY_Product__r.Id from UNITY_Service_Contract_Line_Items__r WHERE RecordType.DeveloperName = 'UNITY_Product_Pricing') 
                                                               FROM UNITY_Service_Contract__c WHERE Id IN :customerServiceContractIdMap.values() AND UNITY_Contract_Sub_type__c = :UNITY_Constants.SC_CONTRACT_PRICING_STATUS];
    
        for (UNITY_Service_Contract__c iter: serviceContractList){
            
            serviceContractLineItemMap.put(iter.Id, new Map<Id, UNITY_Service_Contract_Line_Item__c>());
            
            for (UNITY_Service_Contract_Line_Item__c scli: iter.UNITY_Service_Contract_Line_Items__r){
                
                serviceContractLineItemMap.get(iter.Id).put(scli.UNITY_Product__r.Id, scli);
            }
        }
        
        String POInvoiceableStatuses;
        Set<String> delimitedInvoiceableStatuses = new Set<String>();
        
        if (generalSetting!=null){
            POInvoiceableStatuses = generalSetting.UNITY_Value__c;
        }
        
        if (POInvoiceableStatuses!=null){
            delimitedInvoiceableStatuses = new Set<String>(POInvoiceableStatuses.split(UNITY_Constants.PO_INVOICEABLE_STATUSES_DELIMITER));
        }
        
        List<Order> relatedOrders = [select id, FSO__WorkOrder__c, (select id,OrderItemNumber,UNITY_Include__c,PricebookEntry.Product2.UNITY_Product_Type__c, PricebookEntry.Product2Id from OrderItems) from Order where FSO__WorkOrder__c in:workOrderList and ((Status NOT in: delimitedInvoiceableStatuses and (RecordTypeId =: UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE or RecordTypeId =:UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE)) or ((RecordTypeId =:UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE) and Status != 'In Quote Process' and Status != 'PO Created'))]; 
        
        //List<Order> relatedOrders = [select id, FSO__WorkOrder__c, (select id, PricebookEntry.Product2.UNITY_Product_Type__c, PricebookEntry.Product2Id from OrderItems) from Order where FSO__WorkOrder__c in:workOrderList and ((Status = 'Draft' and (RecordTypeId =: UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE or RecordTypeId =:UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE)) or (RecordTypeId =:UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE and Status = 'Draft'))]; 
        
        List<OrderItem> orderItemToUpdate = new List<OrderItem>();
        
        for (Order iter: relatedOrders){
            
            WorkOrder relatedWO = workOrderMap.get(iter.FSO__WorkOrder__c);
            
            Id serviceContractId = customerServiceContractIdMap.get(relatedWO.Id);
            
            for (OrderItem orderProd: iter.OrderItems){
                
                orderProd.UNITY_Include__c = false;
                
                System.debug('#relatedWO.UNITY_Include__c '+relatedWO.UNITY_Include__c);
                System.debug('#orderProd.PricebookEntry.Product2.UNITY_Product_Type__c '+orderProd.PricebookEntry.Product2.UNITY_Product_Type__c);
                /*
                if(orderProd.PricebookEntry.Product2.UNITY_Product_Type__c == 'Part' && serviceContractId != null && serviceContractLineItemMap.get(serviceContractId).get(orderProd.PricebookEntry.Product2Id) != null && relatedWO.UNITY_Include__c){
                    orderProd.UNITY_Include__c = true;
                }
                */
                if (orderProd.PricebookEntry.Product2.UNITY_Product_Type__c == 'Part' && (serviceContractId != null && serviceContractLineItemMap.get(serviceContractId).get(orderProd.PricebookEntry.Product2Id) != null)){
                    
                    if(serviceContractLineItemMap.get(serviceContractId).get(orderProd.PricebookEntry.Product2Id).UNITY_Exclude__c){
                        //System.debug('Izay: Excluded because of SCLI... POLI: ' + orderProd.OrderItemNumber);
                        orderProd.UNITY_Include__c = false;
                    }else if(serviceContractLineItemMap.get(serviceContractId).get(orderProd.PricebookEntry.Product2Id).UNITY_Inclusion__c){
                        //System.debug('Izay: Included because of SCLI... POLI: ' + orderProd.OrderItemNumber);
                        orderProd.UNITY_Include__c = true;
                    }else{
                        //System.debug('Izay: ' + (relatedWO.UNITY_Include__c ? 'Included' : 'Excluded') + ' because of Work Order... POLI: ' + orderProd.OrderItemNumber);
                        orderProd.UNITY_Include__c = relatedWO.UNITY_Include__c;
                    }
                    //orderItemUpdatedMap.put(orderProd.Id, orderProd);
                }
                else if (orderProd.PricebookEntry.Product2.UNITY_Product_Type__c == 'Labor' || orderProd.PricebookEntry.Product2.UNITY_Product_Type__c == 'Travel' || orderProd.PricebookEntry.Product2.UNITY_Product_Type__c == 'Part'){
                    orderProd.UNITY_Include__c = relatedWO.UNITY_Include__c;
                }
                
            }
            
            orderItemToUpdate.addAll(iter.OrderItems);
            
        }
        
        update orderItemToUpdate;       
    }
    
}