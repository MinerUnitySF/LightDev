global without sharing class MSPFS_IntercompanyProcessingBatch implements Database.Batchable<sObject> {
    
    global String query;
    
    global MSPFS_IntercompanyProcessingBatch() {
        if(String.isBlank(this.query)){
            this.query = 'SELECT Id,CaseId,WOrkOrderNumber,MSPFS_Intercompany_MSP_Revenue_Processed__c,MSPFS_Intercompany_Transfer__c,Status,UNITY_Attachment_Compliant__c,UNITY_Accepted_Vendor__c,UNITY_Accepted_Vendor__r.BU_Unique_Field__c,UNITY_Business_Unit_Account__c ' + 
                         'FROM WorkOrder WHERE MSPFS_Intercompany_MSP_Revenue_Processed__c = FALSE AND MSPFS_Intercompany_Transfer__c = TRUE AND UNITY_Attachment_Compliant__c = TRUE AND Status = \'Completed\'';
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        if(!scope.isEmpty()){
            //First make sure that the work order is intercompany transfer and that it hasn't been processed previously.
            Map<Id,WorkOrder> validWOsMap = new Map<Id,WOrkOrder>();
            Set<Id> mspBUIds = new Set<Id>();
            for(sObject obj :scope){
                WorkOrder wo = (WorkOrder)obj;
                if(!wo.MSPFS_Intercompany_MSP_Revenue_Processed__c && wo.MSPFS_Intercompany_Transfer__c && wo.Status == 'Completed' && wo.UNITY_Attachment_Compliant__c){
                    validWOsMap.put(wo.Id,wo);
                    mspBUIds.add(wo.UNITY_Accepted_Vendor__c);
                }
            }
            System.debug(Logginglevel.DEBUG,'Izay: validWOsMap = ' + JSON.serializePretty(validWOsMap));
            //If there are valid work order... continue with the process
            if(!validWOsMap.keySet().isEmpty()){
                //Need to get all the POs related to the WO where the vendor is MSP BU (same as accepted vendor on the WOs)
                Map<Id,Order> ordersMap = new Map<Id,Order>([SELECT Id,FSO__WorkOrder__c,UNITY_Vendor__c,UNITY_Vendor__r.BU_Unique_Field__c,UNITY_Work_Order_Type__c,EffectiveDate,
                                                            (SELECT Id,MSPFS_MSP_Cost__c,MSPFS_MSP_Price__c,UNITY_Is_Vendor_Supply__c,PricebookEntry.Product2.UNITY_Product_Type__c,
                                                            UNITY_Vendor_Adjusted_Quantity__c,UNITY_Total_Cost__c,UNITY_Activity_Type__c,UNITY_Type__c
                                                            FROM OrderItems WHERE UNITY_Is_Vendor_Supply__c = true AND UNITY_Not_Billable__c = FALSE)
                                                            FROM Order WHERE FSO__WorkOrder__c IN :validWOsMap.keySet() 
                                                            AND UNITY_Vendor__c IN :mspBUIds 
                                                            AND Status IN ('Accepted','Final')
                                                            AND MSPFS_Intercompany_MSP_Revenue_Processed__c = FALSE
                                                            AND RecordTypeId = :UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE]);
                if(!ordersMap.keySet().isEmpty()){
                    //Now need to place the orders in a map by work order id
                    Map<Id,List<Order>> woOrdersMap = new Map<Id,List<Order>>();
                    Map<Id,Order> newOrdersByWOMap = new Map<Id,Order>();//Holds new orders by the work order id and old order id
                    Map<Id,List<OrderItem>> newOrderItemsByWOId = new Map<Id,List<orderItem>>();//Holds new order items by work order id
                    List<Order> ordersToInsert = new List<Order>();//Holds mew orders to be inserted
                    List<OrderItem> orderItemsToInsert = new List<OrderItem>();//Holds new order items to be inserted
                    for(Order o :ordersMap.values()){
                        if(!woOrdersMap.containsKey(o.FSO__WorkOrder__c))
                            woOrdersMap.put(o.FSO__WorkOrder__c,new List<Order>());
                        woOrdersMap.get(o.FSO__WorkOrder__c).add(o);
                    }
                    //Now need to go through each work order and POs and create New POs to account for MSP Cost
                    Set<Id> toRemove = new Set<Id>();//collect the work orde3r id for any WO with errors (no msp cost)
                    for(WorkOrder wo :validWOsMap.values()){
                        Boolean skip = false;//denotes if the work order needs to be skipped
                        if(woOrdersMap.containsKey(wo.Id)){
                            /* ===================================
                            ** Create the new order
                            ** =================================== */
                            Order newOrder = new Order();
                            newOrder.FSO__WorkOrder__c = wo.Id;
                            newOrder.AccountId = wo.UNITY_Business_Unit_Account__c;
                            newOrder.UNITY_Customer__c = wo.UNITY_Business_Unit_Account__c;
                            newOrder.UNITY_GL_Sub_Account__c = null;
                            newOrder.UNITY_GL_Segment_Account__c = null;
                            newOrder.UNITY_Business_Unit__c = wo.UNITY_Accepted_Vendor__r.BU_Unique_Field__c;
                            newOrder.UNITY_Business_Unit_Account__c = wo.UNITY_Accepted_Vendor__c;
                            newOrder.UNITY_Invoice__c = null;
                            newOrder.UNITY_Invoiced__c = false;
                            newOrder.EffectiveDate = Date.today();
                            newOrder.MSPFS_Skip_Pricing_Rules__c= true;
                            newOrder.Status = 'Draft';
                            newOrder.UNITY_Tax_Processed__c = true;
                            newOrder.MSPFS_Intercompany_Transfer__c= true;
                            for(Order o :woOrdersMap.get(wo.Id)){
                                /* ===================================
                                ** Create the new order items
                                ** =================================== */
                                for(OrderItem oItem :o.OrderItems){
                                    //=======================================
                                    //May want to validate here that MSP Cost, MSP Price, and Vendor Adjusted Qty are populated
                                    //=======================================
                                    if(oItem.MSPFS_MSP_Cost__c == null || oItem.MSPFS_MSP_Price__c == null){
                                        skip = true;
                                        toRemove.add(wo.Id);
                                        break;
                                    }
                                    OrderItem newOrderItem = oItem.clone(false,true,false,false);
                                    newOrderItem.UNITY_Cost__c = oItem.MSPFS_MSP_Cost__c;
                                    newOrderItem.UNITY_Total_Cost__c = oItem.UNITY_Vendor_Adjusted_Quantity__c * oItem.MSPFS_MSP_Cost__c;
                                    newOrderItem.UNITY_Price__c = oItem.MSPFS_MSP_Price__c;
                                    newOrderItem.UnitPrice  = oItem.MSPFS_MSP_Price__c;
                                    newOrderItem.Quantity = oItem.UNITY_Vendor_Adjusted_Quantity__c;
                                    newOrderItem.UNITY_Customer_Adjusted_Quantity__c = oItem.UNITY_Vendor_Adjusted_Quantity__c;
                                    newOrderItem.UNITY_Total_Price__c = oItem.UNITY_Total_Cost__c;
                                    newOrderItem.MSPFS_MSP_Cost__c = null;
                                    newOrderItem.MSPFS_MSP_Price__c = null;
                                    newOrderItem.UNITY_Sales_Tax__c = 0;
                                    newOrderItem.UNITY_GL_Revenue_Account__c = null;
                                    newOrderItem.UNITY_GL_Cost_Account__c = null;
                                    newOrderItem.UNITY_GL_Tax_Account__c = null;
                                    newOrderItem.UNITY_Related_Order_Product__c = oItem.Id;
                                    //Update the line type activity type fields to match what it should be for MSP BU
                                    if(oItem.PricebookEntry.Product2.UNITY_Product_Type__c.contains('Labor')){
                                        if(o.UNITY_Work_Order_Type__c == 'Project')
                                            newOrderItem.UNITY_Type__c = 'Labor - Installation';
                                        else 
                                            newOrderItem.UNITY_Type__c = 'Labor - Service';
                                        if(o.UNITY_Work_Order_Type__c == 'PM')
                                            newOrderItem.UNITY_Activity_Type__c = 'Preventative Maintenance';
                                        else
                                            newOrderItem.UNITY_Activity_Type__c = oItem.UNITY_Activity_Type__c.substring(7);
                                    }else
                                    if(oItem.PricebookEntry.Product2.UNITY_Product_Type__c.contains('Travel')){
                                        newOrderItem.UNITY_Type__c = 'Travel';
                                        if(o.UNITY_Work_Order_Type__c == 'PM')
                                            newOrderItem.UNITY_Activity_Type__c = 'Preventative Maintenance';
                                        else
                                            newOrderItem.UNITY_Activity_Type__c = oItem.UNITY_Activity_Type__c.substring(7);
                                    }else
                                    if(oItem.PricebookEntry.Product2.UNITY_Product_Type__c.contains('Part')){
                                        newOrderItem.UNITY_Type__c = 'Parts';
                                        newOrderItem.UNITY_Activity_Type__c = oItem.UNITY_Activity_Type__c;
                                    }else{
                                        newOrderItem.UNITY_Type__c = oItem.UNITY_Type__c;
                                        newOrderItem.UNITY_Activity_Type__c = oItem.UNITY_Activity_Type__c;
                                    }

                                    if(!newOrderItemsByWOId.containsKey(wo.Id))
                                        newOrderItemsByWOId.put(wo.Id,new List<OrderItem>());
                                    newOrderItemsByWOId.get(wo.Id).add(newOrderItem);
                                }
                                //stop if skip is true
                                if(skip)
                                    break;
                            }
                            if(!skip){
                                //Add the new order in toInsert list
                                ordersToInsert.add(newOrder);
                                //Put the new order in the map by wo id
                                newOrdersByWOMap.put(wo.Id,newOrder);
                            }
                        }
                    }
                    //Remove any work order that needs skipping from all the maps
                    if(!toRemove.isEmpty()){
                        for(Id id :toRemove){
                            if(validWOsMap.containsKey(id))
                                validWOsMap.remove(id);
                            if(newOrdersByWOMap.containsKey(id))
                                newOrdersByWOMap.remove(id);
                            if(newOrderItemsByWOId.containsKey(id))
                                newOrderItemsByWOId.remove(id);
                        }
                    }
                    //Now need to insert the orders
                    //Then, parent the new order items to the new orders
                    //Then insert the order items
                    SavePoint sp = Database.setSavepoint();//Save point to revert back to if an error is thrown
                    Set<Id> orderItemIds = new Set<Id>();
                    Map<Id,OrderItem> orderItemsMap = new Map<Id,OrderItem>();
                    try{
                        System.debug('Izay: Intercompany - inserting orders. line');
                        insert ordersToInsert;
                        for(Id woId :newOrdersByWOMap.keySet()){
                            for(OrderItem item :newOrderItemsByWOId.get(woId)){
                                item.OrderId = newOrdersByWOMap.get(woId).Id;
                                System.debug('Izay: OrderId = ' + item.OrderId);
                                orderItemsToInsert.add(item);
                            }
                        }
                        System.debug('Izay: Intercompany - inserting orders lines');
                        insert orderItemsToInsert;
                        for(OrderItem oi :orderItemsToInsert){
                            orderItemIds.add(oi.Id);
                        }
                        orderItemsMap = new Map<Id,OrderItem>([SELECT Id,UNITY_Price__c,UNITY_Customer_Adjusted_Quantity__c,UNITY_Cost__c,OrderId,
                                                               UNITY_Sales_Tax__c,UNITY_Discount__c,UNITY_Discount_Amount__c,PricebookEntry.Product2Id,
                                                               UNITY_Tax_Code__c,UNITY_Is_Vendor_Supply__c,UNITY_GL_Revenue_Account__c,UNITY_GL_Tax_Account__c,
                                                               UNITY_GL_Sub_Account__c,UNITY_Type__c,UNITY_Activity_Type__c,UNITY_Asset__c,UNITY_Unknown_Part_Description__c
                                                               FROM OrderItem WHERE Id IN :orderItemIds]);
                    }catch(Exception e){
                        Database.rollback(sp);
                        Trigger.new[0].addError('Error while processing MSP revenue. Error: ' + e.getMessage() + '. Stacktrace: ' + e.getStackTraceString());
                    }
                    //If we get to this point with no errors... now need to create the invoice
                    Map<Id,UNITY_Invoice__c> invoiceByWOId = new Map<Id,UNITY_Invoice__c>();
                    Map<Id,List<UNITY_Invoice_Line_Item__c>> invLinesByWOId = new Map<Id,List<UNITY_Invoice_Line_Item__c>>();//Invoicelines by WOId
                    for(WorkOrder wo :validWOsMap.values()){
                        if(newOrdersByWOMap.containsKey(wo.Id) && newOrderItemsByWOId.containsKey(wo.Id)){
                            UNITY_Invoice__c invoice = new UNITY_Invoice__c();
                            invoice.UNITY_Case__c = wo.CaseId;
                            invoice.UNITY_Customer__c = wo.UNITY_Business_Unit_Account__c;
                            invoice.UNITY_Business_Unit_Account__c = wo.UNITY_Accepted_Vendor__c;
                            invoice.UNITY_Status__c = 'Invoice Creation';
                            invoice.UNITY_Vendor_Service_Fee__c = 0;
                            invoice.UNITY_Discount_from_POs__c = 0;
                            invoice.UNITY_Discount_Amount__c = 0;
                            invoice.UNITY_Tax_Processed__c = true;
                            invoice.UNITY_Tax_Process_Result__c = 'Success: Intercompany Tansfer Invoice.';
                            invoice.MSPFS_Intercompany_Transfer__c= true;
                            invoice.MSPFS_Intercompany_SL_Processed__c = false;
                            invoice.UNITY_SL_Processed__c = false;
                            invoiceByWOId.put(wo.Id,invoice);
                            //Create the invoice lines
                            List<UNITY_Invoice_Line_Item__c> invLines = new List<UNITY_Invoice_Line_Item__c>();
                            for(OrderItem item :newOrderItemsByWOId.get(wo.Id)){
                                OrderItem oItem;
                                if(orderItemsMap.containsKey(item.Id)){
                                    oItem =  orderItemsMap.get(item.Id);
                                }
                                if(oItem != null){
                                    //Need to create the invoice lines here...
                                    UNITY_Invoice_Line_Item__c invLine = new UNITY_Invoice_Line_Item__c();
                                    invLine.UNITY_Total_Price__c = oItem.UNITY_Price__c * oItem.UNITY_Customer_Adjusted_Quantity__c;
                                    invLine.UNITY_Cost__c = oItem.UNITY_Cost__c * oItem.UNITY_Customer_Adjusted_Quantity__c;
                                    invLine.UNITY_Sales_Tax__c = 0;
                                    invLine.UNITY_PO_Price__c = oItem.UNITY_Price__c; 
                                    invLine.UNITY_Quantity__c = oItem.UNITY_Customer_Adjusted_Quantity__c;
                                    invLine.UNITY_Adjusted_Quantity__c = oItem.UNITY_Customer_Adjusted_Quantity__c;
                                    //Izay: Added this additional fields to the invoice ceration
                                    //to support SL Integration
                                    invLine.UNITY_Discount__c = oItem.UNITY_Discount__c;
                                    invLine.UNITY_Discount_Amount__c = oItem.UNITY_Discount_Amount__c;
                                    invLine.Product__c = oItem.PricebookEntry.Product2Id;
                                    //invLine.UNITY_Tax_Code__c = oItem.UNITY_Tax_Code__c;
                                    invLine.UNITY_Is_Vendor_Supply__c = oItem.UNITY_Is_Vendor_Supply__c;
                                    invLine.UNITY_GL_Revenue_Account__c = oItem.UNITY_GL_Revenue_Account__c;
                                    invLine.UNITY_GL_Tax_Account__c = oItem.UNITY_GL_Tax_Account__c;
                                    invLine.UNITY_GL_Sub_Account__c = oItem.UNITY_GL_Sub_Account__c;
                                    invLine.UNITY_Type__c = oItem.UNITY_Type__c;
                                    invLine.UNITY_Activity_Type__c = oItem.UNITY_Activity_Type__c;
                                    invLine.UNITY_WorkOrder__c = wo.Id;
                                    invLine.UNITY_Asset__c = oItem.UNITY_Asset__c;
                                    invLine.UNITY_Description__c = oItem.UNITY_Unknown_Part_Description__c;

                                    invLines.add(invLine);
                                
                                }
                            }
                            if(!invLines.isEmpty()){
                                invLinesByWOId.put(wo.Id,invLines);
                            }
                        }//End if has Order
                    }//End for WO
                    //Insert the invoice
                    //Then, create the invoice lines
                    //And related the POs to the invoice
                    try{
                        System.debug('Izay: Intercompany - inserting invoice');
                        insert invoiceByWOId.values();
                        List<Order> ordersToUpdate = new List<Order>();//Orders to update
                        //List<UNITY_Invoice_Line_Item__c> invLines = new List<UNITY_Invoice_Line_Item__c>();//Invoicelines to update
                        List<UNITY_Invoice_Line_Item__c> invLinesToInsert = new List<UNITY_Invoice_Line_Item__c>();//Invoice lines to insert
                        Set<Id> invIds = new Set<Id>();//Holds the invoice ids
                        for(Id woId :invoiceByWOId.keySet()){
                            //Add the invoice id to set 
                            invIds.add(invoiceByWOId.get(woId).Id);
                            if(newOrdersByWOMap.containsKey(woId)){
                                //Associate the PO with the invoice and finalize POs
                                newOrdersByWOMap.get(woId).UNITY_Invoice__c = invoiceByWOId.get(woId).Id;
                                newOrdersByWOMap.get(woId).UNITY_Invoiced__c = true;
                                ordersToUpdate.add(newOrdersByWOMap.get(woId));
                                //Associate the invoice lines to their respective invoice
                                if(invLinesByWOId.containsKey(woId)){
                                    for(UNITY_Invoice_Line_Item__c invLine :invLinesByWOId.get(woId)){
                                        invLine.UNITY_Invoice__c = invoiceByWOId.get(woId).Id;
                                        invLinesToInsert.add(invLine);
                                    }
                                }
                            }
                        }
                        System.debug('Izay: Intercompany - invLinesToInsert = ' + JSON.serializePretty(invLinesToInsert));
                        System.debug('Izay: Intercompany - ordersToUpdate.' + JSON.serializePretty(ordersToUpdate));
                        if(!invLinesToInsert.isEmpty()){
                            System.debug('Izay: Intercompany - inserting invoice lines');
                            insert invLinesToInsert;
                            
                            if(!ordersToUpdate.isEmpty()){
                                System.debug('Izay: Intercompany - updating orders');
                                UNITY_OrderTriggerHandler_Miner.isFirstTriggerRun_Before = true;
                                update ordersToUpdate;
                            }
                            List<WorkOrder> workOrdersToUpdate = new List<WorkOrder>();
                            //Finilize the POs first
                            if(!ordersToUpdate.isEmpty()){
                                for(Order o :ordersToUpdate){
                                    o.Status = 'Final';
                                }
                                System.debug('Izay: Intercompany - updating orders to Final');
                                UNITY_OrderTriggerHandler_Miner.isFirstTriggerRun_Before = true;
                                update ordersToUpdate;
                            }
                            //Now need to finalize the invoice
                            List<UNITY_Invoice__c> invoices = [SELECT Id,UNITY_Status__c FROM UNITY_Invoice__c WHERE Id IN :invIds];
                            for(UNITY_Invoice__c inv :invoices){
                                inv.UNITY_Status__c = 'Accepted';
                                inv.UNITY_Invoice_Status__c =  'Invoice Finalized';
                                inv.UNITY_Tax_Posted__c = true;
                            }
                            System.debug('Izay: Intercompany - updating invoices to Invoice Finalize');
                            System.debug('invoices: ' + JSON.serializePretty(invoices));
                            update invoices;
                            for(Order o :ordersMap.values()){
                                if(invoiceByWOId.containsKey(o.FSO__WorkOrder__c)){
                                    o.MSPFS_Intercompany_MSP_Revenue_Processed__c = true;
                                }
                            }
                            for(WorkOrder wo :validWOsMap.values()){
                                if(invoiceByWOId.containsKey(wo.Id)){
                                    wo.MSPFS_Intercompany_MSP_Revenue_Processed__c = true;
                                    System.debug('Izay: Intercompany - updating work order');
                                    workOrdersToUpdate.add(wo);
                                }
                            }
                            update ordersMap.values();
                            update workOrdersToUpdate;
                        }

                    }catch(Exception e){
                        Database.rollback(sp);
                        //Throw exception to trigger.new[0]
                        System.debug('Error while processing MSP revenue. Error: ' + e.getMessage() + '. Stacktrace: ' + e.getStackTraceString());
                        //Trigger.new[0].addError('Error while processing MSP revenue. Error: ' + e.getMessage() + '. Stacktrace: ' + e.getStackTraceString());
                    }
                }//End if orders
            }//End if valid work orders
        }//End if work orders
    }
    
    global void finish(Database.BatchableContext BC) {
        //Send POs to SL
        String queryPO = 'SELECT Id FROM Order WHERE UNITY_Invoice__r.MSPFS_Intercompany_Transfer__c = TRUE AND (UNITY_SL_Processed__c = FALSE OR (UNITY_SL_Processed__c = TRUE AND UNITY_SL_Process_Complete__c = FALSE) )';
        UNITY_IntegrationCalloutBatch_Miner bPO = new UNITY_IntegrationCalloutBatch_Miner(UNITY_Constants.IntegrationType.PURCHASE_ORDER);
        bPO.query = queryPO;
        database.executeBatch(bPO,10);
        //Send Invoice to SL
        String queryInv = 'SELECT Id FROM UNITY_Invoice__c WHERE MSPFS_Intercompany_Transfer__c = TRUE AND (UNITY_SL_Processed__c = FALSE OR (UNITY_SL_Processed__c = TRUE AND UNITY_SL_Process_Complete__c = FALSE) )';
        UNITY_IntegrationCalloutBatch_Miner bInv = new UNITY_IntegrationCalloutBatch_Miner(UNITY_Constants.IntegrationType.INVOICE);
        bInv.query = queryInv;
        database.executeBatch(bInv,10); 
        /*
        Need to poptentially call tax batch here...
        */
    }

}