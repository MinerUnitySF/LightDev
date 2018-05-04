/**UNITY_OrderTriggerHandler_Miner
* @description: This class handles the pricing for POs and Quotes
* @programer:   SFDC
* @date:        4/17/2016 - Deployed to Prod
* @version:     1.0
* =====================================================
* Change Log
* =====================================================
* @description: - Added support for Contract Pricing
*               - Added support for Menu Pricing
*               - Fixed Rounding Issues on POs and Quotes
*               - Added suppoert for Not-Billable POLIs and QLIs
*               - Other bugfixes and enhancements
* @programer:   Izay Ramos
* =====================================================
* @description: Added support to get line cost from Vendor Service Contract on Stocking POs
* @programer:   Izay Ramos
* @date:        9/7/2016
* @version:     3.01
* =====================================================
* @description: Fixed bug with menu pricing labot line total price on insert
* @programer:   Izay Ramos-Irizarry
* @date:        9/24/2016
* =====================================================
*/
public with sharing class UNITY_PriceCalculation {

    private static Map<string,UNITY_General_Settings__c> generalSettings = UNITY_General_Settings__c.getAll();
    private static String LABOR_PRICEBOOKENTRY_ID;
    private static String LABOR_PRODUCT_ID;
    static{
        if(LABOR_PRICEBOOKENTRY_ID == null || LABOR_PRODUCT_ID == null){
            PricebookEntry laborPBE = [SELECT Id,Product2Id FROM PricebookEntry WHERE Product2.UNITY_Product_Type__c = 'Labor' AND Product2.ProductCode = 'Miner-Labor'
                                       AND PriceBook2Id = :UNITY_Constants.getStandardPriceBookId() LIMIT 1];
            LABOR_PRICEBOOKENTRY_ID = laborPBE.Id;
            LABOR_PRODUCT_ID = laborPBE.Product2Id;
        }
    }
    /*
    public static void updateLocationStock(List<Id> orderItemIdList){

        //query order item records
        List<OrderItem> orderItemList = [select id, UNITY_Customer_Adjusted_Quantity__c, UNITY_Price__c, OrderId, PricebookEntry.Product2Id, Order.UNITY_Location__c from OrderItem where Id in: orderItemIdList];

        Set<Id> locationIdSet = new Set<Id>();
        Set<Id> productIdSet = new Set<Id>();

        // get related locations and products
        for (OrderItem iter: orderItemList){

            locationIdSet.add(iter.Order.UNITY_Location__c);
            productIdSet.add(iter.PricebookEntry.Product2Id);
        }

        //query existing location stock records
        List<FSO__LocationStock__c> locationStockList = [select id, UNITY_Last_Action_PO__c, FSO__Product__c, FSO__Location__c, FSO__Quantity__c, UNITY_MAC__c from FSO__LocationStock__c where FSO__Product__c in: productIdSet and FSO__Location__c in:locationIdSet];

        Map<String, FSO__LocationStock__c> locationStockMap = new Map<String, FSO__LocationStock__c>();

        for (FSO__LocationStock__c iter: locationStockList){

            String key = iter.FSO__Product__c + '|' + iter.FSO__Location__c;

            locationStockMap.put(key, iter);
        }

        System.debug('#locationStockMap '+locationStockMap);

        List<FSO__LocationStock__c> locationStocktToBeUpserted = new List<FSO__LocationStock__c>();

        for (OrderItem iter: orderItemList){

            String key = iter.PricebookEntry.Product2Id+'|'+iter.Order.UNITY_Location__c;

            System.debug('#key '+key);

            if (locationStockMap.get(key) != null){
                //update FSO__LocationStock__c

                FSO__LocationStock__c stock = locationStockMap.get(key);

                System.debug('#stock '+stock);
                System.debug('#OrderItem '+iter);

                Double oldQtty = stock.FSO__Quantity__c;

                stock.FSO__Quantity__c = stock.FSO__Quantity__c + iter.UNITY_Customer_Adjusted_Quantity__c;
                stock.UNITY_MAC__c = (oldQtty * stock.UNITY_MAC__c + iter.UNITY_Customer_Adjusted_Quantity__c * iter.UNITY_Price__c)/(oldQtty+iter.UNITY_Customer_Adjusted_Quantity__c);
                //stock.UNITY_Landed_Cost__c = stock.UNITY_MAC__c * 1.2;
                stock.UNITY_Last_Action_PO__c = iter.OrderId;

                locationStocktToBeUpserted.add(stock);

            }else{
                //create FSO__LocationStock__c
                FSO__LocationStock__c stock = new FSO__LocationStock__c();

                stock.FSO__Quantity__c = iter.UNITY_Customer_Adjusted_Quantity__c;
                stock.UNITY_MAC__c = iter.UNITY_Price__c;
                stock.FSO__Location__c = iter.Order.UNITY_Location__c;
                stock.FSO__Product__c = iter.PricebookEntry.Product2Id;
                stock.UNITY_Last_Action_PO__c = iter.OrderId;

                locationStocktToBeUpserted.add(stock);
            }
        }

        upsert locationStocktToBeUpserted;
    }
*/

/* **********************************************************************************************************************
 * ******************** RECALCULATE PO LINES PRICE **********************************************************************
 * ********************************************************************************************************************** */
    public static Map<id,OrderItem> recalculateOrderItemPricing (Map<Id,OrderItem> orderItemsMap){
        // query order item records
        List<OrderItem> orderItemList = orderItemsMap.values();
        Set<Id> workOrerIdSet = new Set<Id>();
        Map<Id, Id> vendorContractMap = new Map<Id, Id>();
        Set<Id> productIds = new Set<Id>();
        //Need to get the resource (tech ids) from the POLIs to find the burden rate
        Set<Id> techIds = new Set<Id>();
        for(OrderItem iter: orderItemList){
            if(iter.PricebookEntry.Product2.UNITY_Product_Type__c == 'Part'){
                productIds.add(iter.PricebookEntry.Product2Id);
            }

			if (iter.Order.FSO__WorkOrder__c != null)
            	workOrerIdSet.add(iter.Order.FSO__WorkOrder__c);

            vendorContractMap.put(iter.OrderId, iter.Order.UNITY_Vendor_Contract__c);
            //Izay: Added to get techs record
            if(String.isNotBlank(iter.MSPFS_Technician__c))
                techIds.add(iter.MSPFS_Technician__c);
            if(String.isNotBlank(iter.MSPFS_Technician2__c))
                techIds.add(iter.MSPFS_Technician2__c);
        }
        
        //<AK> related Stockable Products (Location Stock)
        List<FSO__LocationStock__c> locationStockList = [Select Id,UNITY_Landed_Cost__c,FSO__Quantity__c,FSO__Product__c,FSO__Location__r.UNITY_Business_Unit_Account__c from FSO__LocationStock__c where FSO__Product__c in :productIds];
        Map<String, FSO__LocationStock__c> productToLocationStockMap = new Map<String, FSO__LocationStock__c>();
        for(FSO__LocationStock__c iter: locationStockList){
            productToLocationStockMap.put(iter.FSO__Product__c +'|'+iter.FSO__Location__r.UNITY_Business_Unit_Account__c, iter);
        }
        //Izay: Get resource(tech) record
        Map<Id,CKSW_BASE__Resource__c> techsMap = new Map<Id,CKSW_BASE__Resource__c>([SELECT Id,MSPFS_Burden_Rate__c FROM CKSW_BASE__Resource__c WHERE Id IN :techIds]);
        // related work orders
        //<AK> Added UNITY_Business_Unit_Account__c to select clause
        List<WorkOrder> workOrderList = [SELECT id, SFPS_FS_OverallStatus__c, SFPS_FS_TotalServiceTime__c, UNITY_Use_Menu_Pricing__c, UNITY_Trade__r.UNITY_Skill_Broad__c,
                                         UNITY_Customer__r.UNITY_Customer_Size__c, UNITY_Business_Unit__c, UNITY_Business_Unit_Account__c, UNITY_Customer_Service_Contract__c,
                                         UNITY_Vendor_Contract__c, UNITY_Secondary_Technician__c,UNITY_Assigned_Vendor__c,UNITY_Assigned_Vendor__r.RecordType.DeveloperName,RecordTypeId,
                                         UNITY_Business_Unit_Account__r.MSPFS_Is_MSP_BU__c,MSPFS_Intercompany_Transfer__c
                                         FROM WorkOrder WHERE Id IN:workOrerIdSet];
        //Map <workOrderId, customerContractId>
        Map<Id, Id> workOrderCustomerContractMap = new Map<Id, Id>();
        //Map <workOrderId, workOrder>
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>();
        //<AK>Set<Broad>
        Set<String> broads = new Set<String>();
        //<AK>Set<CustomerSize>
        Set<String> customerSizes = new Set<String>();
        //<AK>Set<BusinessUnitAccount>
        Set<String> buAccounts = new Set<String>();
        for (WorkOrder iter: workOrderList){
            workOrderCustomerContractMap.put(iter.id, iter.UNITY_Customer_Service_Contract__c);
            workOrderMap.put(iter.id, iter);
            //<AK>
            broads.add(iter.UNITY_Trade__r.UNITY_Skill_Broad__c);
            buAccounts.add(iter.UNITY_Business_Unit_Account__c);
            customerSizes.add(iter.UNITY_Customer__r.UNITY_Customer_Size__c);
        }
        //<AK>
        //Map<Broad|CustomerSize|BusinessUnitAccount, CostPlus>
        Map<String,Decimal> costPlusFromAccountPricingMatrix = new Map<String,Decimal>();
        //Map<ProductId|BusinessUnitAccount, CostPlus>
        Map<String,Decimal> costPlusByBUAndPart = new Map<String,Decimal>();
        List<UNITY_Account_Pricing_Matrix__c> accountPricingMatrix = [Select Id, UNITY_Broad__c, UNITY_Business_Unit_Account__c, UNITY_Customer_Size__c, UNITY_Cost_Plus__c from UNITY_Account_Pricing_Matrix__c where UNITY_Broad__c in :broads AND UNITY_Business_Unit_Account__c in :buAccounts AND UNITY_Customer_Size__c in :customerSizes];
        List<UNITY_BU_Markup_Junction__c> buMarkupJunction = [Select Id, UNITY_BU_Account__c, UNITY_Product__c, UNITY_Markup__c from UNITY_BU_Markup_Junction__c where UNITY_BU_Account__c in :buAccounts AND UNITY_Product__c in :productIds];
        for (UNITY_Account_Pricing_Matrix__c iter : accountPricingMatrix){
            String key = iter.UNITY_Broad__c + '|' + iter.UNITY_Business_Unit_Account__c + '|' + iter.UNITY_Customer_Size__c;
            costPlusFromAccountPricingMatrix.put(key, iter.UNITY_Cost_Plus__c);
        }
        for (UNITY_BU_Markup_Junction__c iter : buMarkupJunction){
            String key = iter.UNITY_BU_Account__c + '|' + iter.UNITY_Product__c;
            costPlusByBUAndPart.put(key, iter.UNITY_Markup__c);
        }
        //Map<productId, price>
        Map<Id, Map<Id,Decimal>> productPriceMap = new Map<Id, Map<Id,Decimal>>();
        //Map<productId, costPlus>
        Map<Id, Map<Id,Decimal>> productCostPlusMap = new Map<Id, Map<Id,Decimal>>();

        //Map<SCId, SCLI>>
        Map<Id, Map<String,UNITY_Service_Contract_Line_Item__c>> menuPricingMap = new Map<Id, Map<String,UNITY_Service_Contract_Line_Item__c>>();
        
        //Map<serviceContractId, List<tradeId, SCLI>>
        Map<Id, Map<String,UNITY_Service_Contract_Line_Item__c>> serviceContractLineByTradeMap = new Map<Id, Map<String,UNITY_Service_Contract_Line_Item__c>>();

        //Map<serviceContractId, vendorServiceContract>
        Map<Id, UNITY_Service_Contract__c> serviceContractMap = new Map<Id, UNITY_Service_Contract__c>();

        //<AK>Added UNITY_Cost_Plus__c in select clause
        List<UNITY_Service_Contract__c> contractList = [SELECT Id, UNITY_Account__r.RecordTypeId, UNITY_Is_Pass_Through__c, UNITY_Cost_Plus__c, UNITY_Minimum_Labor_Hours__c, UNITY_Max_Allowable_Trip_Charges__c, UNITY_2_Technicians__c,UNITY_Apprentice__c,UNITY_Multi_Technician__c,
                                                        UNITY_Holiday_Multiplier__c,UNITY_OT_Multiplier__c,UNITY_Holiday_Travel_Multiplier__c,UNITY_OT_Travel_Multiplier__c, UNITY_Default_Labor_Rate__c, UNITY_Trip_Charge__c, UNITY_Trip_Charge_Type__c, UNITY_Invoicing_Increments__c, 
                                                        (SELECT Id, UNITY_Labor_Hours__c, UNITY_Trade__c, UNITY_Trip_Charge__c, UNITY_Trip_Charge_Type__c, UNITY_Cost_Plus__c, UNITY_Labor_Cost__c, UNITY_Product__r.Id, UNTIY_Material_Cost__c, UNITY_Self_Perform_Labor_Cost__c,
                                                         UNITY_Self_Perform_Trip_Charge_Cost__c, UNITY_Self_Perform_Trip_Charge_Type__c, UNITY_Holiday_Multiplier__c,UNITY_OT_Multiplier__c,UNITY_Holiday_Travel_Multiplier__c,UNITY_OT_Travel_Multiplier__c, RecordType.DeveloperName 
                                                         FROM UNITY_Service_Contract_Line_Items__r) FROM UNITY_Service_Contract__c WHERE (Id IN: vendorContractMap.values()) OR (id in: workOrderCustomerContractMap.values())];

        System.debug('#####Izay: contractList = ' + contractList);
        for(UNITY_Service_Contract__c serviceContract: contractList){

            serviceContractMap.put(serviceContract.Id, serviceContract);

            productPriceMap.put(serviceContract.Id, new Map<Id, Decimal>());
            productCostPlusMap.put(serviceContract.Id, new Map<Id, Decimal>());
            serviceContractLineByTradeMap.put(serviceContract.Id, new Map<String, UNITY_Service_Contract_Line_Item__c>());
            for (UNITY_Service_Contract_Line_Item__c scli: serviceContract.UNITY_Service_Contract_Line_Items__r){
                if (scli.RecordType.DeveloperName == 'UNITY_Product_Pricing' && scli.UNTIY_Material_Cost__c != null){
                    productPriceMap.get(serviceContract.Id).put(scli.UNITY_Product__r.Id, scli.UNTIY_Material_Cost__c);
                }
                else if(scli.RecordType.DeveloperName == 'UNITY_Product_Pricing' && scli.UNITY_Cost_Plus__c != null){
                    productCostPlusMap.get(serviceContract.Id).put(scli.UNITY_Product__r.Id, scli.UNITY_Cost_Plus__c);
                }else if(scli.RecordType.DeveloperName == UNITY_Constants.SCLI_HOURLY_RATE_RT){
                    serviceContractLineByTradeMap.get(serviceContract.Id).put(scli.UNITY_Trade__c+'|'+UNITY_Constants.SCLI_HOURLY_RATE_RT, scli);
                }else if(scli.RecordType.DeveloperName == UNITY_Constants.SCLI_PRODUCT_PRICING_RULE_RT){
                    serviceContractLineByTradeMap.get(serviceContract.Id).put(scli.UNITY_Trade__c+'|'+UNITY_Constants.SCLI_PRODUCT_PRICING_RULE_RT, scli);
                }else if(scli.RecordType.DeveloperName == UNITY_Constants.SCLI_NTE_RT){
                    serviceContractLineByTradeMap.get(serviceContract.Id).put(scli.UNITY_Trade__c+'|'+UNITY_Constants.SCLI_NTE_RT, scli);
                }
                else if (scli.RecordType.DeveloperName == UNITY_Constants.SCLI_MENU_PRICING_RT){
                    if(!menuPricingMap.containsKey(serviceContract.Id))
                        menuPricingMap.put(serviceContract.Id, new Map<String,UNITY_Service_Contract_Line_Item__c>());
                    menuPricingMap.get(serviceContract.Id).put(scli.UNITY_Product__r.Id,scli);
                }
            }
        }
        System.debug('#####Izay: productPriceMap = ' + productPriceMap);
        //Get related Orders with Order Items
        List<Order> orderList = [SELECT Id, FSO__WorkOrder__c, UNITY_Vendor_Contract__c, FSO__WorkOrder__r.UNITY_Trade__c,FSO__WorkOrder__r.UNITY_Assigned_Vendor__c,FSO__WorkOrder__r.UNITY_Assigned_Vendor__r.RecordTypeId, 
                                 UNITY_Business_Unit_Account__c,UNITY_Work_Order_Type__c,RecordTypeId,MSPFS_Skip_Pricing_Rules__c,
                                 (SELECT Id, UNITY_Type__c, UNITY_Include__c, UNITY_Vendor_Adjusted_Quantity__c, UNITY_Customer_Adjusted_Quantity__c, UNITY_Cost__c, PricebookEntry.Name, 
                                  Quantity, PricebookEntry.UnitPrice,UNITY_Related_Menu_Price_Line__c,PricebookEntry.Product2.Name,PricebookEntry.Product2Id,PricebookEntry.Product2.UNITY_Landed_Cost__c, 
                                  PricebookEntry.Product2.UNITY_Product_Type__c, PricebookEntry.Product2.Broad__c, UNITY_Customer_OT_Multiplier__c,UNITY_MP_Labor_Vendor_Adjusted_Qty__c,UNITY_MP_Labor_Cost__c,
                                  UNITY_Customer_Holiday_Multiplier__c,UNITY_Vendor_OT_Multiplier__c,UNITY_Vendor_Holiday_Multiplier__c,UNITY_Number_of_Techs__c,UNITY_Is_Vendor_Supply__c,
                                  UNITY_Part_On_Hand__c,UNITY_Product_Type__c,UNITY_Not_Billable__c,UNITY_Total_Price__c,UNITY_Part_Location__c,MSPFS_Technician__c,MSPFS_Technician2__c,MSPFS_MSP_Cost__c,MSPFS_MSP_Price__c
                                  FROM OrderItems WHERE IsDeleted = FALSE) FROM Order WHERE FSO__WorkOrder__c in: workOrerIdSet];
        
        System.debug('#orderList '+orderList);
        System.debug('#serviceContractLineByTradeMap '+serviceContractLineByTradeMap);
        System.debug('#menuPricingMap '+menuPricingMap);

        //List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
        Map<id,OrderItem> orderItemsToUpdateMap = new Map<id,OrderItem>();

        //MENU PRICING - SET DATA FROM SERVICE CONTRACT
        Map<Id, Set<Id>> menuPricingProduct = new Map<Id, Set<Id>>();
        Map<Id, Map<Id,OrderItem>> mpLinesMap = new Map<Id, Map<Id,OrderItem>>();
        Map<String, OrderItem> mpLineLaborMap = new Map<String, OrderItem>(); 
        Map<Id, Boolean> appliesMenuPricing = new Map<Id, Boolean>();
        List<OrderItem> toInsert_mpLabor = new List<OrderItem>();
        List<OrderItem> toUpdate_mpLabor = new List<OrderItem>();
        //Izay:Set to hold the Location Stock for part lines that have location
        Set<Id> stockLocationIds = new Set<Id>();
        for(Order orderRecord: orderList){
            appliesMenuPricing.put(orderRecord.Id, false);
            Boolean useMenuPricing = (workOrderMap.containsKey(orderRecord.FSO__WorkOrder__c))?workOrderMap.get(orderRecord.FSO__WorkOrder__c).UNITY_Use_Menu_Pricing__c:false;
            Id customerServiceContractId = workOrderCustomerContractMap.get(orderRecord.FSO__WorkOrder__c);
            if(menuPricingMap.containsKey(customerServiceContractId)){
                if(useMenuPricing){
                    Boolean hasMPLine = false;
                    for(OrderItem orderProd: orderRecord.OrderItems){
                        if(menuPricingMap.get(customerServiceContractId).containsKey(orderProd.PricebookEntry.Product2Id)){
                            hasMPLine = true;
                            if(!menuPricingProduct.containsKey(orderRecord.Id))
                                menuPricingProduct.put(orderRecord.Id,new Set<Id>());
                            menuPricingProduct.get(orderRecord.Id).add(orderProd.PricebookEntry.Product2Id);
                            if(!mpLinesMap.containsKey(orderRecord.Id))
                                mpLinesMap.put(orderRecord.Id,new Map<Id,OrderItem>());
                            mpLinesMap.get(orderRecord.Id).put(orderProd.Id,orderProd);
                        }
                        //Collect the menu price labor lines in the mpLineLaborMap
                        if(orderProd.UNITY_Product_Type__c == 'Labor' && String.isNotBlank(orderProd.UNITY_Related_Menu_Price_Line__c)){
                            mpLineLaborMap.put(orderProd.UNITY_Related_Menu_Price_Line__c,orderProd);
                        }
                    }
                    //appliesMenuPricing.put(orderRecord.Id, hasMPLine);
                }
                appliesMenuPricing.put(orderRecord.Id, useMenuPricing);
            }
            for(OrderItem orderProd: orderRecord.OrderItems){
                if(orderProd.PricebookEntry.Product2.UNITY_Product_Type__c == 'Part'){
                    //If the Part Line has a Stock Location...
                    if(String.isNotBlank(orderProd.UNITY_Part_Location__c))
                        stockLocationIds.add(orderProd.UNITY_Part_Location__c);//Add location id to the stockLocationIds set
                }
            }
        }
        System.debug('#####Izay: stockLocationIds = ' + JSON.serializePretty(stockLocationIds));
        System.debug('#####Izay: productIds = ' + JSON.serializePretty(productIds));
        //Izay: Get the location stock for the stock locations and the parts...
        List<FSO__LocationStock__c> myLocationStock = [SELECT Id,FSO__Location__c,UNITY_Landed_Cost__c,FSO__Quantity__c,FSO__Product__c,UNITY_MAC__c,UNITY_Last_Purchase_Order_Unit_Cost__c 
                                                       FROM FSO__LocationStock__c WHERE FSO__Location__c IN :stockLocationIds AND FSO__Product__c IN :productIds];
        System.debug('#####Izay: myLocationStock = ' + JSON.serializePretty(myLocationStock));
        Map<Id,Map<Id,FSO__LocationStock__c>> stockProdMap = new Map<Id,Map<Id,FSO__LocationStock__c>>();
        for(FSO__LocationStock__c lStock :myLocationStock){
            if(!stockProdMap.containsKey(lStock.FSO__Location__c))
                stockProdMap.put(lStock.FSO__Location__c,new Map<Id,FSO__LocationStock__c>());
            if(!stockProdMap.get(lStock.FSO__Location__c).containsKey(lStock.FSO__Product__c))
                stockProdMap.get(lStock.FSO__Location__c).put(lStock.FSO__Product__c,lStock);
        }
        System.debug('#####Izay: stockProdMap = ' + JSON.serializePretty(stockProdMap));

/* **********************************************************************************************************************
 * ******************** LOOP TRHOUGH ORDERS TO CALCULATE PRICE **********************************************************
 * ********************************************************************************************************************** */
        for(Order orderRecord: orderList){
            //Izay: Skip pricing logic if the Po is flagged as skip pricing rules
            if(orderRecord.MSPFS_Skip_Pricing_Rules__c)
                continue;
            
            String NWWORTID = UNITY_Constants.WO_NON_WORK_RECORDTYPE;
            Id vendorServiceContractId = vendorContractMap.get(orderRecord.Id);
            Id customerServiceContractId = workOrderCustomerContractMap.get(orderRecord.FSO__WorkOrder__c);
            Boolean isNonWork = workOrderMap.containsKey(orderRecord.FSO__WorkOrder__c)?(workOrderMap.get(orderRecord.FSO__WorkOrder__c).RecordTypeId == NWWORTID ? true : false):false;
            Boolean isStockingPO = (orderRecord.RecordTypeId == UNITY_Constants.ORDER_STOCKING_PURCHASE_ORDER_RECORDTYPE);
            Boolean isIntercompany = workOrderMap.containsKey(orderRecord.FSO__WorkOrder__c) ? workOrderMap.get(orderRecord.FSO__WorkOrder__c).MSPFS_Intercompany_Transfer__c : false;
            if((vendorServiceContractId != null && customerServiceContractId != null)
               || (isNonWork && customerServiceContractId != null) || (isStockingPO && vendorServiceContractId != null)){

                   Id trade = orderRecord.FSO__WorkOrder__r.UNITY_Trade__c;
                   String byTradeAndProductPricingRuleKey = trade + '|'+UNITY_Constants.SCLI_PRODUCT_PRICING_RULE_RT;
                   String byTradeAndHourlyRateKey = trade + '|'+UNITY_Constants.SCLI_HOURLY_RATE_RT;
                   String byTradeAndNTEKey = trade + '|'+UNITY_Constants.SCLI_NTE_RT;
                   
                   String broad = workOrderMap.containsKey(orderRecord.FSO__WorkOrder__c)?workOrderMap.get(orderRecord.FSO__WorkOrder__c).UNITY_Trade__r.UNITY_Skill_Broad__c:'';
                   String businessUnit = workOrderMap.containsKey(orderRecord.FSO__WorkOrder__c)?workOrderMap.get(orderRecord.FSO__WorkOrder__c).UNITY_Business_Unit__c:'';
                   String customerSize = workOrderMap.containsKey(orderRecord.FSO__WorkOrder__c)?workOrderMap.get(orderRecord.FSO__WorkOrder__c).UNITY_Customer__r.UNITY_Customer_Size__c:'';
                   
                   String workOrderOverallStatus = workOrderMap.containsKey(orderRecord.FSO__WorkOrder__c)?workOrderMap.get(orderRecord.FSO__WorkOrder__c).SFPS_FS_OverallStatus__c:'';
                   Double workOrderServiceTime = workOrderMap.containsKey(orderRecord.FSO__WorkOrder__c)?workOrderMap.get(orderRecord.FSO__WorkOrder__c).SFPS_FS_TotalServiceTime__c:0;
                   
                   String assignedServiceAccountRecordType = '';
                   
                   if(String.isNotBlank(vendorServiceContractId)){
                       if(serviceContractMap.get(vendorServiceContractId)!=null){
                           assignedServiceAccountRecordType = serviceContractMap.get(vendorServiceContractId).Unity_Account__r.RecordTypeId;
                       }
                   }
                       
                   Decimal defaultCostPlusFromSC = 0;
                   if(serviceContractMap.get(customerServiceContractId)!=null && serviceContractMap.get(customerServiceContractId).UNITY_Cost_Plus__c != null){
                       defaultCostPlusFromSC = serviceContractMap.get(customerServiceContractId).UNITY_Cost_Plus__c;
                   }
                   Boolean isPassThroughCustomer = false;
                   if(serviceContractMap.get(customerServiceContractId)!=null){
                       isPassThroughCustomer = serviceContractMap.get(customerServiceContractId).UNITY_Is_Pass_Through__c;
                   }
                   system.debug('@@ : isPassThroughCustomer : '+isPassThroughCustomer);
                   
                   //Decimal customerSecondaryTechnicianMultiplier = 0;
                   //Decimal vendorSecondaryTechnicianMultiplier = 0;
                   
                   Decimal customer2TechMultiplier = 1;
                   Decimal customerMultiTechMultiplier = 1;
                   Decimal customerApprenticeMultiplier = 1;
                   Decimal customerOTLaborMultiplier = 1;
                   Decimal customerOTTravelMultiplier = 1;
                   Decimal customerHolidayLaborMultiplier = 1;
                   Decimal customerHolidayTravelMultiplier = 1;
                   
                   Decimal vendor2TechMultiplier = 1;
                   Decimal vendorMultiTechMultiplier = 1;
                   Decimal vendorApprenticeMultiplier = 1;
                   Decimal vendorOTLaborMultiplier = 1;
                   Decimal vendorOTTravelMultiplier = 1;
                   Decimal vendorHolidayLaborMultiplier = 1;
                   Decimal vendorHolidayTravelMultiplier = 1;

                   if(String.isNotBlank(customerServiceContractId)){
                        if(serviceContractMap.get(customerServiceContractId).UNITY_2_Technicians__c!=null){
                           customer2TechMultiplier = serviceContractMap.get(customerServiceContractId).UNITY_2_Technicians__c;
                       }
                       if(serviceContractMap.get(customerServiceContractId).UNITY_Apprentice__c!=null){
                           customerApprenticeMultiplier = serviceContractMap.get(customerServiceContractId).UNITY_Apprentice__c;
                       }
                       if(serviceContractMap.get(customerServiceContractId).UNITY_Multi_Technician__c!=null){
                           customerMultiTechMultiplier = serviceContractMap.get(customerServiceContractId).UNITY_Multi_Technician__c;
                       }
                       if(serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Holiday_Multiplier__c != null){
                           customerHolidayLaborMultiplier = serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Holiday_Multiplier__c;
                       }else if(serviceContractMap.get(customerServiceContractId).UNITY_Holiday_Multiplier__c!=null){
                           customerHolidayLaborMultiplier = serviceContractMap.get(customerServiceContractId).UNITY_Holiday_Multiplier__c;
                       }
                       if(serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_OT_Multiplier__c != null){
                           customerOTLaborMultiplier = serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_OT_Multiplier__c;
                       }else if(serviceContractMap.get(customerServiceContractId).UNITY_OT_Multiplier__c!=null){
                           customerOTLaborMultiplier = serviceContractMap.get(customerServiceContractId).UNITY_OT_Multiplier__c;
                       }
                       if(serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Holiday_Travel_Multiplier__c != null){
                           customerHolidayTravelMultiplier = serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Holiday_Travel_Multiplier__c;
                       }else if(serviceContractMap.get(customerServiceContractId).UNITY_Holiday_Travel_Multiplier__c!=null){
                           customerHolidayTravelMultiplier = serviceContractMap.get(customerServiceContractId).UNITY_Holiday_Travel_Multiplier__c;
                       }
                       if(serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_OT_Travel_Multiplier__c != null){
                           customerOTTravelMultiplier = serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_OT_Travel_Multiplier__c;
                       }else if(serviceContractMap.get(customerServiceContractId).UNITY_OT_Travel_Multiplier__c!=null){
                           customerOTTravelMultiplier = serviceContractMap.get(customerServiceContractId).UNITY_OT_Travel_Multiplier__c;
                       }
                   }
                   
                       
                   if(String.isNotBlank(vendorServiceContractId)){
                       if(serviceContractMap.get(vendorServiceContractId).UNITY_2_Technicians__c!=null){
                           vendor2TechMultiplier = serviceContractMap.get(vendorServiceContractId).UNITY_2_Technicians__c;
                       }
                       if(serviceContractMap.get(vendorServiceContractId).UNITY_Apprentice__c!=null){
                           vendorApprenticeMultiplier = serviceContractMap.get(vendorServiceContractId).UNITY_Apprentice__c;
                       }
                       if(serviceContractMap.get(vendorServiceContractId).UNITY_Multi_Technician__c!=null){
                           vendorMultiTechMultiplier = serviceContractMap.get(vendorServiceContractId).UNITY_Multi_Technician__c;
                       }
                       if(serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Holiday_Multiplier__c != null){
                           vendorHolidayLaborMultiplier = serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Holiday_Multiplier__c;
                       }else if(serviceContractMap.get(vendorServiceContractId).UNITY_Holiday_Multiplier__c!=null){
                           vendorHolidayLaborMultiplier = serviceContractMap.get(vendorServiceContractId).UNITY_Holiday_Multiplier__c;
                       }
                       
                       if(serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_OT_Multiplier__c != null){
                           vendorOTLaborMultiplier = serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_OT_Multiplier__c;
                       }else if(serviceContractMap.get(vendorServiceContractId).UNITY_OT_Multiplier__c!=null){
                           vendorOTLaborMultiplier = serviceContractMap.get(vendorServiceContractId).UNITY_OT_Multiplier__c;
                       }
                       
                       if(serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Holiday_Travel_Multiplier__c != null){
                           vendorHolidayTravelMultiplier = serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Holiday_Travel_Multiplier__c;
                       }else if(serviceContractMap.get(vendorServiceContractId).UNITY_Holiday_Travel_Multiplier__c!=null){
                           vendorHolidayTravelMultiplier = serviceContractMap.get(vendorServiceContractId).UNITY_Holiday_Travel_Multiplier__c;
                       }
                       System.debug('#####Izay: vendorHolidayTravelMultiplier = ' + vendorHolidayTravelMultiplier);
                       if(serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_OT_Travel_Multiplier__c != null){
                           vendorOTTravelMultiplier = serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_OT_Travel_Multiplier__c;
                       }else if(serviceContractMap.get(vendorServiceContractId).UNITY_OT_Travel_Multiplier__c!=null){
                           vendorOTTravelMultiplier = serviceContractMap.get(vendorServiceContractId).UNITY_OT_Travel_Multiplier__c;
                       }
                   }
                       
                   
                   Decimal accountBasedMarkup = costPlusFromAccountPricingMatrix.get(broad+'|'+orderRecord.UNITY_Business_Unit_Account__c+'|'+customerSize);
                   if (accountBasedMarkup == null){
                       accountBasedMarkup = 0;
                   }

                for(OrderItem onOrderItem: orderRecord.OrderItems){
                    if(orderItemsMap.containsKey(onOrderItem.Id)){

                        System.debug('#onOrderItem '+onOrderItem);

                        OrderItem orderItem = orderItemsMap.get(onOrderItem.id);
                        //Izay: If it is a Stocking PO set the POLI as Not Billable
                        if(isStockingPO){
                            orderItem.UNITY_Not_Billable__c = true;
                            onOrderItem.UNITY_Not_Billable__c = true;
                        }

                        Id productId = orderItem.PricebookEntry.Product2Id;
                        String productName = orderItem.PricebookEntry.Name;

                        Decimal landedCostFromInventory = 0;
                        Decimal locationStockQuantity = 0;
                        String key = productId +'|'+orderRecord.UNITY_Business_Unit_Account__c;
                        if(productToLocationStockMap.get(key) !=null){
                            landedCostFromInventory = productToLocationStockMap.get(key).UNITY_Landed_Cost__c;
                            locationStockQuantity = productToLocationStockMap.get(key).FSO__Quantity__c;
                        }
                        
                        Boolean includeFromContractPricing = orderItem.UNITY_Include__c;

                        Decimal costByProductFromSCLI = -1;
                        Decimal costPlusByProductFromSCLI = 0;
                        Decimal laborCostByTradeFromSCLI = 0;
                        Decimal defaultLaborCostFromSC = 0;
                        Decimal vendorTripCharge;
                        String vendorTripChargeType;

                        if(String.isNotBlank(vendorServiceContractId)){
                            if(productPriceMap.get(vendorServiceContractId).get(productId)!=null){
                                costByProductFromSCLI = productPriceMap.get(vendorServiceContractId).get(productId);
                            }
                            if(productCostPlusMap.get(vendorServiceContractId).get(productId)!=null){
                                costPlusByProductFromSCLI = productCostPlusMap.get(vendorServiceContractId).get(productId);
                            }
                            if(serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Labor_Cost__c != null){
                                laborCostByTradeFromSCLI = serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Labor_Cost__c;
                            }
                            if(serviceContractMap.get(vendorServiceContractId).UNITY_Default_Labor_Rate__c != null){
                                defaultLaborCostFromSC = serviceContractMap.get(vendorServiceContractId).UNITY_Default_Labor_Rate__c;
                            }
                            if(serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Trip_Charge__c != null && serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Trip_Charge_Type__c != null){
                                vendorTripCharge = serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Trip_Charge__c;
                                vendorTripChargeType = serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Trip_Charge_Type__c;
                            }else{
                                vendorTripCharge = serviceContractMap.get(vendorServiceContractId).UNITY_Trip_Charge__c;
                                vendorTripChargeType = serviceContractMap.get(vendorServiceContractId).UNITY_Trip_Charge_Type__c;
                            }
                        }

                        Decimal priceByProductFromSCLI = -1;
                        Decimal costPlusByTradeFromSCLI = 0;
                        Decimal laborPriceByTradeFromSCLI = 0;
                        Decimal defaultLaborPriceFromSC = 0;
                        Decimal customerTripCharge;
                        String customerTripChargeType;

                        if(String.isNotBlank(customerServiceContractId)){
                            if(productPriceMap.get(customerServiceContractId).get(productId)!=null){
                                priceByProductFromSCLI = productPriceMap.get(customerServiceContractId).get(productId);
                            }
                            if(serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndProductPricingRuleKey) != null && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndProductPricingRuleKey).UNITY_Cost_Plus__c != null){
                                costPlusByTradeFromSCLI = serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndProductPricingRuleKey).UNITY_Cost_Plus__c;
                            }
                            if(serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Labor_Cost__c != null){
                                laborPriceByTradeFromSCLI = serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Labor_Cost__c;
                            }
                            if(serviceContractMap.get(customerServiceContractId).UNITY_Default_Labor_Rate__c != null){
                                defaultLaborPriceFromSC = serviceContractMap.get(customerServiceContractId).UNITY_Default_Labor_Rate__c;
                            }
                            //If Miner Self Perform has a set COST for labor by trade for the Customer, then use the self perform COST on customer's SC instead of COST on self perform (Vendor's) SC.
                            if(assignedServiceAccountRecordType == UNITY_Constants.ACCOUNT_MINER_RECORDTYPE && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Self_Perform_Labor_Cost__c != null) {
                                laborCostByTradeFromSCLI = serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Self_Perform_Labor_Cost__c;
                            }
                            //If Miner Self Perform has a set COST for Travel by trade for the Customer, then use the self perform COST on customer's SC instead of COST on self perform (Vendor's) SC.
                            if(assignedServiceAccountRecordType == UNITY_Constants.ACCOUNT_MINER_RECORDTYPE && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Self_Perform_Trip_Charge_Type__c != null && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Self_Perform_Trip_Charge_Cost__c != null) {
                                vendorTripCharge = serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Self_Perform_Trip_Charge_Cost__c;
                                vendorTripChargeType = serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Self_Perform_Trip_Charge_Type__c;
                            }
                            if(serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Trip_Charge__c != null && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Trip_Charge_Type__c != null){
                                customerTripCharge = serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Trip_Charge__c;
                                customerTripChargeType = serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Trip_Charge_Type__c;
                            }else{
                                customerTripCharge = serviceContractMap.get(customerServiceContractId).UNITY_Trip_Charge__c;
                                customerTripChargeType = serviceContractMap.get(customerServiceContractId).UNITY_Trip_Charge_Type__c;
                            }
                        }

                        Decimal BUBasedMarkup = costPlusByBUAndPart.get(orderRecord.UNITY_Business_Unit_Account__c+'|'+productId);
                        if(BUBasedMarkup == null){
                            BUBasedMarkup = 0;
                        }

                        orderItem.UNITY_Cost_Calculation_Details__c = '';
                        orderItem.UNITY_Price_Calculation_Details__c = '';

                        System.debug('#onOrderItem '+onOrderItem);
                        System.debug(LoggingLevel.INFO,'#trade '+trade);
                        System.debug(LoggingLevel.INFO,'#serviceContractLineByTradeMap '+serviceContractLineByTradeMap);
                        System.debug(LoggingLevel.INFO,'#laborCostByTradeFromSCLI '+laborCostByTradeFromSCLI);
                        System.debug(LoggingLevel.INFO,'#assignedServiceAccountRecordType '+assignedServiceAccountRecordType);
                        System.debug(LoggingLevel.INFO,'#UNITY_Constants.ACCOUNT_MINER_RECORDTYPE '+UNITY_Constants.ACCOUNT_MINER_RECORDTYPE);
                        System.debug(LoggingLevel.INFO,'<AK> : BEFORE EVERYTHING!! UNITY_Product_Type__c : '+orderItem.PricebookEntry.Product2.UNITY_Product_Type__c);
                        System.debug(LoggingLevel.INFO,'<AK> : orderItem.UNITY_Type__c : '+orderItem.UNITY_Type__c);
                        System.debug(LoggingLevel.INFO,'<AK> : onOrderItem.UNITY_Type__c : '+onOrderItem.UNITY_Type__c);
/* **********************************************************************************************************************
 * ******************** PO Non Billable Line Pricing Rule ***************************************************************
 * ********************************************************************************************************************** */
                        if(orderItem.UNITY_Type__c == 'Non Billable'){
                            System.debug(LoggingLevel.INFO,'<AK> : inside Non Billable : onOrderItem.UNITY_Type__c : '+onOrderItem.UNITY_Type__c);
                            
                            orderItem.UNITY_Price__c = 0;
                            orderItem.UNITY_Cost__c = 0;
                            orderItem.UNITY_Total_Price__c = 0;
                            orderItem.UNITY_Total_Cost__c = 0;
                            
                            orderItem.UNITY_Price_Calculation_Details__c += 'Non Billable Product, Price: 0\n';
                            orderItem.UNITY_Cost_Calculation_Details__c += 'Non Billable Product, Cost: 0\n';
/* **********************************************************************************************************************
 * ******************** PO Part Line Pricing Rule ***********************************************************************
 * ********************************************************************************************************************** */                        
                        }else if(orderItem.PricebookEntry.Product2.UNITY_Product_Type__c == 'Part'){
                            System.debug(LoggingLevel.INFO,'<AK> : inside else if : onOrderItem.UNITY_Type__c : '+onOrderItem.UNITY_Type__c);
                            if (orderItem.UNITYPM_Non_Payable__c){
                                orderItem.UNITY_Cost__c = orderItem.UNITYPM_Cost_For_Non_Payable__c;
                            }
                            orderItem.UNITY_Cost_Calculation_Details__c += 'Original Cost: '+orderItem.UNITY_Cost__c+'\n';
                            orderItem.UNITY_Price_Calculation_Details__c += 'Original Price: '+orderItem.UNITY_Price__c+'\n';
                            //VENDOR: COST CALCULATION
                            system.debug('@@ : costByProductFromSCLI : '+costByProductFromSCLI);
                            system.debug('@@ : costPlusByProductFromSCLI : '+costPlusByProductFromSCLI);
                            system.debug('@@ : landedCostFromInventory : '+landedCostFromInventory);
                            system.debug('@@ : locationStockQuantity : '+locationStockQuantity);
                            system.debug('@@ : orderItem.UNITY_Is_Vendor_Supply__c : '+orderItem.UNITY_Is_Vendor_Supply__c);
                            system.debug('@@ : orderItem.UNITY_Part_Source__c : '+orderItem.UNITY_Part_Source__c);
                            /*if(orderItem.UNITY_Is_Vendor_Supply__c){
                                //orderItem.UNITY_Part_Source__c = null;
                                //orderItem.UNITY_Part_On_Hand__c = false;
                            }else */
                            if(String.isNotBlank(onOrderItem.UNITY_Part_Location__c) && 
                               (orderItem.Order.RecordTypeId != UNITY_Constants.ORDER_STOCKING_PURCHASE_ORDER_RECORDTYPE)
                              ){
                                //Izay:Changed to use stockProdMap
                                System.debug('#####:Izay: has UNITY_Part_Location__c = true');
                                System.debug('#####:Izay: stockProdMap.containsKey(onOrderItem.UNITY_Part_Location__c) = ' + stockProdMap.containsKey(onOrderItem.UNITY_Part_Location__c));
                                if(stockProdMap.containsKey(onOrderItem.UNITY_Part_Location__c)){
                                    System.debug('#####:Izay: stockProdMap.containsKey(onOrderItem.UNITY_Part_Location__c) = ' + stockProdMap.containsKey(onOrderItem.UNITY_Part_Location__c));
                                    if(stockProdMap.containsKey(onOrderItem.UNITY_Part_Location__c)){
                                        if(stockProdmap.get(onOrderItem.UNITY_Part_Location__c).containsKey(onOrderItem.PricebookEntry.Product2Id)){
                                            FSO__LocationStock__c pStock = stockProdMap.get(onOrderItem.UNITY_Part_Location__c).get(onOrderItem.PricebookEntry.Product2Id);
                                            orderItem.UNITY_Part_On_Hand__c = ((pStock.FSO__Quantity__c - orderItem.Quantity) >= 0);
                                            //orderItem.UNITY_Location_Available_Quantity__c = pStock.FSO__Quantity__c;
                                            Decimal myCost = (
                                                (pStock.UNITY_Landed_Cost__c != null) ? pStock.UNITY_Landed_Cost__c : 
                                                (pStock.UNITY_MAC__c != null) ? pStock.UNITY_MAC__c : 
                                                (pStock.UNITY_Last_Purchase_Order_Unit_Cost__c != null) ? pStock.UNITY_Last_Purchase_Order_Unit_Cost__c : 0
                                            );
                                            if(isIntercompany && orderItem.UNITY_Is_Vendor_Supply__c)
                                                orderItem.MSPFS_MSP_Cost__c = myCost;
                                            else{
                                                orderItem.UNITY_Cost__c = myCost;
                                                orderItem.UNITY_Cost_Calculation_Details__c += 'Cost from Inventory Location Stock: ' + myCost;
                                            }
                                            //orderItem.UNITY_Cost__c = myCost;
                                            //orderItem.UNITY_Cost_Calculation_Details__c += 'Cost from Inventory Location Stock: ' + myCost;
                                        }else{
                                            orderItem.UNITY_Part_On_Hand__c = false;
                                        }
                                    }
                                }
                            }
                            if(orderItem.UNITY_Cost__c == null || orderItem.UNITY_Cost__c <= 0){
                                if(orderItem.UNITY_Is_Vendor_Supply__c && costPlusByProductFromSCLI > 0){
                                    orderItem.UNITY_Cost_Calculation_Details__c += 'Cost Plus from Service Contract Line Item: '+costPlusByProductFromSCLI+'\n';
                                    orderItem.UNITY_Cost_Plus__c = costPlusByProductFromSCLI;
                                }else if(orderItem.UNITY_Is_Vendor_Supply__c && costByProductFromSCLI >= 0){
                                    orderItem.UNITY_Cost_Calculation_Details__c += 'Cost from Service Contract Line Item: '+costByProductFromSCLI+'\n';
                                    orderItem.UNITY_Cost__c = costByProductFromSCLI.setScale(2,System.RoundingMode.HALF_DOWN);
                                }else if(isStockingPO && costByProductFromSCLI >= 0){
                                    orderItem.UNITY_Cost_Calculation_Details__c += 'Cost from Vendor Service Contract Line Item: '+costByProductFromSCLI+'\n';
                                    orderItem.UNITY_Cost__c = costByProductFromSCLI.setScale(2,System.RoundingMode.HALF_DOWN);
                                    /*
                                    if(!orderItem.UNITY_Is_Vendor_Supply__c && landedCostFromInventory > 0){
                                        orderItem.UNITY_Cost_Calculation_Details__c += 'Landed Cost from Inventory: '+landedCostFromInventory+'\n';
                                        orderItem.UNITY_Cost__c = landedCostFromInventory.setScale(2,System.RoundingMode.HALF_DOWN);
                                        if (orderItem.UNITY_Part_Source__c == null){
                                            orderItem.UNITY_Part_Source__c = orderRecord.UNITY_Business_Unit_Account__c;
                                        }
                                        orderItem.UNITY_Part_On_Hand__c = (locationStockQuantity - orderItem.Quantity>=0);
                                    }
                                    */
                                }
                                if(orderItem.UNITY_Cost__c == null){
                                    orderItem.UNITY_Cost_Calculation_Details__c += 'Cost not found: 0\n';
                                    orderItem.UNITY_Cost__c = 0; //No Cost found. Agent MUST manually enter it.
                                }
                            }
                            system.debug('@@ : orderItem.UNITY_Cost__c : '+orderItem.UNITY_Cost__c);
                            orderItem.UNITY_Vendor_Adjusted_Quantity__c = orderItem.Quantity;
                            orderItem.UNITY_Total_Cost__c = orderItem.UNITY_Cost__c * orderItem.UNITY_Vendor_Adjusted_Quantity__c;
                            
                            //CUSTOMER PRICE CALCULATION FOR PARTS STARTS HERE
                            system.debug('@@ : priceByProductFromSCLI : '+priceByProductFromSCLI);
                            system.debug('@@ : costPlusByTradeFromSCLI : '+costPlusByTradeFromSCLI);
                            system.debug('@@ : defaultCostPlusFromSC : '+defaultCostPlusFromSC);
                            system.debug('@@ : accountBasedMarkup : '+accountBasedMarkup);
                            system.debug('@@ : BUBasedMarkup : '+BUBasedMarkup);
                            //CUSTOMER: CONTRACT PRICING
                            if(includeFromContractPricing){
                                orderItem.UNITY_Customer_Adjusted_Quantity__c = orderItem.quantity != null ? orderItem.quantity : 1;
                                orderItem.UNITY_Total_Price__c = 0;
                                orderItem.UNITY_Price__c = 0;
                                orderItem.UNITY_Price_Calculation_Details__c += 'Price: 0 (Contract Pricing)\n';
                            //CUSTOMER: NOT BILLABLE LINE
                            }else if(onOrderItem.UNITY_Not_Billable__c){
                                orderItem.UNITY_Customer_Adjusted_Quantity__c = 0;
                                orderItem.UNITY_Total_Price__c = 0;
                                orderItem.UNITY_Price__c = 0;
                                orderItem.UNITY_Price_Calculation_Details__c = 'Price: 0 (Not Billable Line)\n';
                                orderItem.UNITY_Sales_Tax__c = 0;
                            //CUSTOMER: MENU PRICING & STANDARD PRICING
                            }else{
                                Boolean standardPrice = true;
                                //CUSTOMER: MENU PRICING
                                if((trigger.isInsert || trigger.isUpdate) && appliesMenuPricing.get(orderRecord.Id)  && menuPricingMap.containsKey(customerServiceContractId) && mpLinesMap.containsKey(orderRecord.Id)){
                                    System.debug('###Izay: menuPricingMap.get(customerServiceContractId): ' + menuPricingMap.get(customerServiceContractId));
                                    System.debug('###Izay: orderItem.PricebookEntry.Product2Id: ' + orderItem.PricebookEntry.Product2Id);
                                    if(menuPricingMap.get(customerServiceContractId).containsKey(orderItem.PricebookEntry.Product2Id)){
                                        standardPrice = false;
                                        System.debug('#####Izay: orderItem.Quantity = ' + orderItem.Quantity);
                                        orderItem.UNITY_Price__c = menuPricingMap.get(customerServiceContractId).get(orderItem.PricebookEntry.Product2Id).UNTIY_Material_Cost__c;
                                        orderItem.Quantity = (orderItem.Quantity != null)?orderItem.Quantity:1;
                                        System.debug('#####Izay: orderItem.Quantity = ' + orderItem.Quantity);
                                        orderItem.UNITY_Customer_Adjusted_Quantity__c = (orderItem.Quantity != null)?orderItem.Quantity:1;
                                        System.debug('#####Izay: orderItem.UNITY_Customer_Adjusted_Quantity__c = ' + orderItem.UNITY_Customer_Adjusted_Quantity__c);
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Price (Menu Pricing): '+orderItem.UNITY_Price__c+'\n';
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Customer Quantity Adjusted (Menu Pricing): '+orderItem.Quantity+'\n';
                                        String mpkey = orderItem.Id;
                                        OrderItem mpLabor;
                                        if(!mpLineLaborMap.containsKey(mpkey)){
                                            mpLabor = new OrderItem();
                                            mpLabor.OrderId = orderRecord.Id;
                                            mpLabor.UNITY_Related_Menu_Price_Line__c = orderItem.Id;
                                            mpLabor.PricebookEntryId = LABOR_PRICEBOOKENTRY_ID;
                                            mpLabor.UNITY_Is_Vendor_Supply__c = true;
                                            mpLabor.UNITY_Type__c = 'Vendor Services';
                                            mpLabor.UNITY_Activity_Type__c = 'Vendor Standard Labor';
                                            toInsert_mpLabor.add(mpLabor);
                                        }else{
                                            mpLabor = mpLineLaborMap.get(mpkey);
                                            orderItemsToUpdateMap.put(mpLabor.Id,mpLabor);
                                        }
                                        if(mpLabor != null){
                                            //MENU PRICING: Labor Line Price Calculation
                                            mpLabor.UNITY_Price_Calculation_Details__c = '';
                                            mpLabor.UnitPrice = menuPricingMap.get(customerServiceContractId).get(orderItem.PricebookEntry.Product2Id).UNITY_Labor_Cost__c;
                                            mpLabor.UNITY_Price__c = menuPricingMap.get(customerServiceContractId).get(orderItem.PricebookEntry.Product2Id).UNITY_Labor_Cost__c;
                                            mpLabor.UNITY_Price_Calculation_Details__c += 'Price (Menu Pricing): '+mpLabor.UNITY_Price__c+'\n';
                                            if(mpLabor.Quantity == null)
                                                mpLabor.Quantity = (onOrderItem.UNITY_MP_Labor_Vendor_Adjusted_Qty__c != null && onOrderItem.UNITY_MP_Labor_Vendor_Adjusted_Qty__c != 0) ?
                                                    onOrderItem.UNITY_MP_Labor_Vendor_Adjusted_Qty__c : menuPricingMap.get(customerServiceContractId).get(orderItem.PricebookEntry.Product2Id).UNITY_Labor_Hours__c;
                                            mpLabor.UNITY_Customer_Adjusted_Quantity__c = (menuPricingMap.get(customerServiceContractId).get(orderItem.PricebookEntry.Product2Id).UNITY_Labor_Hours__c * orderItem.UNITY_Customer_Adjusted_Quantity__c);
                                            mpLabor.UNITY_Price_Calculation_Details__c += 'Customer Quantity Adjusted (Menu Pricing): '+mpLabor.UNITY_Customer_Adjusted_Quantity__c+'\n';                                            
                                            mpLabor.UNITY_Price_Calculation_Details__c += 'Menu Price Labor Qty: '+(menuPricingMap.get(customerServiceContractId).get(orderItem.PricebookEntry.Product2Id).UNITY_Labor_Hours__c)+'\n';
                                            mpLabor.UNITY_Price_Calculation_Details__c += 'Menu Price Line Qty: '+mpLabor.UNITY_Customer_Adjusted_Quantity__c+'\n';
                                            mpLabor.UNITY_Total_Price__c = mpLabor.UNITY_Price__c * mpLabor.UNITY_Customer_Adjusted_Quantity__c;
                                            mpLabor.UNITY_Price_Calculation_Details__c += 'Total Price (Menu Pricing): '+mpLabor.UNITY_Total_Price__c+'\n';
                                            mpLabor.Description = onOrderItem.PricebookEntry.Product2.Name+' Labor';
                                            //Need to run vendor cost here...
                                            //MENU PRICING: Labor Line Cost Calculation
                                            mpLabor.UNITY_Cost_Calculation_Details__c = '';
                                            mpLabor.UNITY_Cost_Calculation_Details__c += 'Original Cost: '+mpLabor.UNITY_Cost__c+'\n';
                                            if (mpLabor.UNITY_Cost__c == null || mpLabor.UNITY_Cost__c <= 0){
                                                if(onOrderItem.UNITY_MP_Labor_Cost__c != null && onOrderItem.UNITY_MP_Labor_Cost__c != 0){
                                                    mpLabor.UNITY_Cost_Calculation_Details__c += 'Cost from MP Labor Cost (Menu Pricing): '+onOrderItem.UNITY_MP_Labor_Cost__c+'\n';
                                                    mpLabor.UNITY_Cost__c = onOrderItem.UNITY_MP_Labor_Cost__c.setScale(2,System.RoundingMode.HALF_DOWN);
                                                }
                                                else if (laborCostByTradeFromSCLI > 0){
                                                    mpLabor.UNITY_Cost_Calculation_Details__c += 'Cost from Service Contract Line Item by Trade: '+laborCostByTradeFromSCLI+'\n';
                                                    mpLabor.UNITY_Cost__c = laborCostByTradeFromSCLI.setScale(2,System.RoundingMode.HALF_DOWN);
                                                }
                                                else if(defaultLaborCostFromSC > 0){
                                                    mpLabor.UNITY_Cost_Calculation_Details__c += 'Default Cost from Service Contract: '+defaultLaborCostFromSC+'\n';
                                                    mpLabor.UNITY_Cost__c = defaultLaborCostFromSC.setScale(2,System.RoundingMode.HALF_DOWN);
                                                }
                                            }
                                            //MENU PRICING: Set the Vendor Adjusted Quantity
                                            mpLabor.UNITY_Vendor_Adjusted_Quantity__c = mpLabor.Quantity;
                                            mpLabor.UNITY_Cost_Calculation_Details__c += 'Vendor Quantity Adjusted (Menu Pricing): '+mpLabor.Quantity+'\n';
                                            mpLabor.UNITY_Total_Cost__c = mpLabor.UNITY_Cost__c * mpLabor.UNITY_Vendor_Adjusted_Quantity__c;
                                            //MENU PRICING: Set the Labor Vendor Adjusted Qty and Cost on the Menu Price Line
                                            orderItem.UNITY_MP_Labor_Vendor_Adjusted_Qty__c = mpLabor.UNITY_Vendor_Adjusted_Quantity__c;
                                            orderItem.UNITY_MP_Labor_Cost__c = mpLabor.UNITY_Cost__c;
                                        }
                                        orderItem.UNITY_Total_Price__c = orderItem.UNITY_Price__c * orderItem.UNITY_Customer_Adjusted_Quantity__c;
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Total Price (Menu Pricing): '+orderItem.UNITY_Total_Price__c+'\n';
                                    }
                                    /*
                                    else if(trigger.isInsert){
                                        orderItem.UNITY_Price__c = 0;
                                        orderItem.UNITY_Customer_Adjusted_Quantity__c = orderItem.quantity;
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Price (Menu Pricing): '+orderItem.UNITY_Price__c+'\n';
                                    }else{
                                        orderItem.UNITY_Price__c = 0;
                                        orderItem.UNITY_Customer_Adjusted_Quantity__c = orderItem.quantity;
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Price (Menu Pricing): '+orderItem.UNITY_Price__c+'\n';
                                    }
                                    */
                                }
                                //CUSTOMER: STANDARD PRICING
                                if(standardPrice){
                                    if(priceByProductFromSCLI != null && priceByProductFromSCLI >= 0){
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Price from Service Contract Line Item by Product: '+priceByProductFromSCLI+'\n';
                                        orderItem.UNITY_Price__c = priceByProductFromSCLI;
                                    }else{
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Price from Order Item Cost: '+orderItem.UNITY_Cost__c+'\n';
                                        orderItem.UNITY_Price__c = orderItem.UNITY_Cost__c;
                                        if(costPlusByTradeFromSCLI > 0){
                                            orderItem.UNITY_Price_Calculation_Details__c += 'Cost Plus from Service Contract Line Item by Trade: '+costPlusByTradeFromSCLI+'\n';
                                            orderItem.UNITY_Cost_Plus__c = costPlusByTradeFromSCLI;
                                        }else if(defaultCostPlusFromSC > 0){
                                            orderItem.UNITY_Price_Calculation_Details__c += 'Default Cost Plus from Service Contract: '+defaultCostPlusFromSC+'\n';
                                            orderItem.UNITY_Cost_Plus__c = defaultCostPlusFromSC;
                                        }else{
                                            orderItem.UNITY_Price_Calculation_Details__c += 'Cost Plus (accountBasedMarkup + BUBasedMarkup): '+accountBasedMarkup + BUBasedMarkup+'\n';
                                            orderItem.UNITY_Cost_Plus__c = accountBasedMarkup + BUBasedMarkup;
                                        }
                                    }
                                    
                                    system.debug('@@ : orderItem.UNITY_Cost__c : '+orderItem.UNITY_Cost__c);
                                    system.debug('@@ : orderItem.UNITY_Cost_Plus__c : '+ orderItem.UNITY_Cost_Plus__c);
                                    
                                    
                                    orderItem.UNITY_Customer_Adjusted_Quantity__c = orderItem.Quantity;
                                    system.debug('@@ : orderItem.UNITY_Customer_Adjusted_Quantity__c : '+orderItem.UNITY_Customer_Adjusted_Quantity__c);
                                    system.debug('@@ : assignedServiceAccountRecordType : '+assignedServiceAccountRecordType);
                                    system.debug('@@ : UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE : '+UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE);
                                    system.debug('@@ : orderItem.UNITY_Is_Vendor_Supply__c : '+orderItem.UNITY_Is_Vendor_Supply__c);
                                    
                                    if(isPassThroughCustomer && orderItem.UNITY_Is_Vendor_Supply__c){
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Customer is Pass Through. Defaulting the Price back to Vendor Cost: '+orderItem.UNITY_Cost__c+'\n';
                                        orderItem.UNITY_Price__c = orderItem.UNITY_Cost__c;
                                        orderItem.UNITY_Total_Price__c = orderItem.UNITY_Total_Cost__c;
                                        orderItem.UNITY_Customer_Adjusted_Quantity__c = orderItem.UNITY_Vendor_Adjusted_Quantity__c;
                                    }else{
                                        if(orderItem.UNITY_Cost_Plus__c!=null || orderItem.UNITY_Cost_Plus__c > 0){
                                            orderItem.UNITY_Price__c = orderItem.UNITY_Price__c + (orderItem.UNITY_Price__c * (orderItem.UNITY_Cost_Plus__c/100)).setScale(2,System.RoundingMode.HALF_DOWN);
                                        }
                                        orderItem.UNITY_Total_Price__c = orderItem.UNITY_Price__c * orderItem.UNITY_Customer_Adjusted_Quantity__c;
                                    }
                                }
                                
                            }

/* **********************************************************************************************************************
 * ******************** PO LABOR LINE PRICE CALCULATION *****************************************************************
 * ********************************************************************************************************************** */
                        }else if(orderItem.PricebookEntry.Product2.UNITY_Product_Type__c == 'Labor'){
                            
                            Double vendorQuantityToUse = orderItem.Quantity;
                            Double customerQuantityToUse = orderItem.Quantity;
                            
                            if(workOrderOverallStatus == 'Completed' && workOrderServiceTime != null){
                                //Added check to validate if the adjusted qty is null or not
                                vendorQuantityToUse = (orderItem.UNITY_Vendor_Adjusted_Quantity__c != null) ? orderItem.UNITY_Vendor_Adjusted_Quantity__c : orderItem.Quantity;
                                customerQuantityToUse = (orderItem.UNITY_Customer_Adjusted_Quantity__c != null) ? orderItem.UNITY_Customer_Adjusted_Quantity__c : orderItem.Quantity;
                            }
                            
                            System.debug(LoggingLevel.INFO,'<AK> : BEFORE EVERYTHING!! UNITY_Product_Type__c : '+orderItem.PricebookEntry.Product2.UNITY_Product_Type__c);
                            
                            orderItem.UNITY_Cost_Calculation_Details__c += 'Original Cost: '+orderItem.UNITY_Cost__c+'\n';
                            orderItem.UNITY_Price_Calculation_Details__c += 'Original Price: '+orderItem.UNITY_Price__c+'\n';
                            
                            Decimal vendorLaborMultiplier = 1;
                            Decimal customerLaborMultiplier = 1;
                            
                            Decimal vendorTechMultiplier = 1;
                            Decimal customerTechMultiplier = 1;
                            
                            // VENDOR COST CALCULATION
                            System.debug('###Izay: appliesMenuPricing.get(orderRecord.Id): ' + appliesMenuPricing.get(orderRecord.Id));
                            System.debug('###Izay: menuPricingMap.get(customerServiceContractId): ' + menuPricingMap.get(customerServiceContractId));
                            // MENU PRICING: Set the Vendor Adjusted Quantity
                            /*
                            if(trigger.isInsert && appliesMenuPricing.get(orderRecord.Id) && menuPricingMap.containsKey(customerServiceContractId) && mpLinesMap.containsKey(orderRecord.Id)){
                                Decimal tempQty = 0 ; 
                                if(mpLinesMap.containsKey(orderRecord.Id)){
                                    for(OrderItem oi :mpLinesMap.get(orderRecord.Id)){
                                        tempQty += menuPricingMap.get(customerServiceContractId).get(oi.PricebookEntry.Product2Id).UNITY_Labor_Hours__c;
                                    }
                                }
                                orderItem.UNITY_Vendor_Adjusted_Quantity__c = tempQty;
                                vendorQuantityToUse = orderItem.UNITY_Vendor_Adjusted_Quantity__c;
                                orderItem.UNITY_Cost_Calculation_Details__c += 'Quantity adjusted (Menu Pricing): '+orderItem.UNITY_Vendor_Adjusted_Quantity__c+'\n';
                            }
                            */
                            //Izay: Updated to get Labor Cost rate from Tech profile for MSP BU POs
                            Boolean isMspBu = workOrderMap.containsKey(orderRecord.FSO__WorkOrder__c)?workOrderMap.get(orderRecord.FSO__WorkOrder__c).UNITY_Business_Unit_Account__r.MSPFS_Is_MSP_BU__c:false;
                            System.debug('Izay: IsMSPBU = ' + isMspBu);
                            if(isMspBu){
                                Decimal rate = 0;
                                System.debug('Izay: isNotBlank(orderItem.MSPFS_Technician__c) = ' + String.isNotBlank(orderItem.MSPFS_Technician__c));
                                if(String.isNotBlank(orderItem.MSPFS_Technician__c)){
                                    System.debug('Izay: techsMap.containsKey(orderItem.MSPFS_Technician__c) = ' + techsMap.containsKey(orderItem.MSPFS_Technician__c));
                                    if(techsMap.containsKey(orderItem.MSPFS_Technician__c)){
                                        Decimal tech1Rate = techsMap.get(orderItem.MSPFS_Technician__c).MSPFS_Burden_Rate__c != null ?
                                            techsMap.get(orderItem.MSPFS_Technician__c).MSPFS_Burden_Rate__c : 0;
                                        System.debug('Izay: tech1Rate = ' + tech1Rate);
                                        rate += tech1Rate;
                                    }
                                }
                                if(String.isNotBlank(orderItem.MSPFS_Technician2__c)){
                                    if(techsMap.containsKey(orderItem.MSPFS_Technician2__c)){
                                        Decimal tech2Rate = techsMap.get(orderItem.MSPFS_Technician2__c).MSPFS_Burden_Rate__c != null ?
                                            techsMap.get(orderItem.MSPFS_Technician2__c).MSPFS_Burden_Rate__c : 0;
                                        rate += tech2Rate;
                                    }
                                }
                                orderItem.UNITY_Cost_Calculation_Details__c += 'Cost from Technician(s) Burden Rate: '+rate+'\n';
                                orderItem.UNITY_Cost__c = rate.setScale(2,System.RoundingMode.HALF_DOWN);
                            }else
                            if(orderItem.UNITY_Cost__c == null || orderItem.UNITY_Cost__c <= 0){
                                if (laborCostByTradeFromSCLI > 0){
                                    orderItem.UNITY_Cost_Calculation_Details__c += 'Cost from Service Contract Line Item by Trade: '+laborCostByTradeFromSCLI+'\n';
                                    orderItem.UNITY_Cost__c = laborCostByTradeFromSCLI.setScale(2,System.RoundingMode.HALF_DOWN);
                                }
                                else if(defaultLaborCostFromSC > 0){
                                    orderItem.UNITY_Cost_Calculation_Details__c += 'Default Cost from Service Contract: '+defaultLaborCostFromSC+'\n';
                                    orderItem.UNITY_Cost__c = defaultLaborCostFromSC.setScale(2,System.RoundingMode.HALF_DOWN);
                                }
                            }
                            if(orderItem.UNITY_Vendor_OT_Multiplier__c){
                                orderItem.UNITY_Cost_Calculation_Details__c += 'Vendor OT Labor Multiplier Applied : '+vendorOTLaborMultiplier+'\n';
                                vendorLaborMultiplier = vendorOTLaborMultiplier;
                            }else if(orderItem.UNITY_Vendor_Holiday_Multiplier__c){
                                orderItem.UNITY_Cost_Calculation_Details__c += 'Vendor Holiday Labor Multiplier Applied : '+vendorHolidayLaborMultiplier+'\n';
                                vendorLaborMultiplier = vendorHolidayLaborMultiplier;
                            }
                            if(orderItem.UNITY_Number_of_Techs__c == '2 Technicians'){
                                orderItem.UNITY_Cost_Calculation_Details__c += 'Vendor 2 Tech Multiplier Applied : '+vendor2TechMultiplier+'\n';
                                vendorTechMultiplier = vendor2TechMultiplier;
                            }else if (orderItem.UNITY_Number_of_Techs__c == 'Multi-Tech'){
                                orderItem.UNITY_Cost_Calculation_Details__c += 'Vendor Multi-Tech Multiplier Applied : '+vendorMultiTechMultiplier+'\n';
                                vendorTechMultiplier = vendorMultiTechMultiplier;
                            }else if (orderItem.UNITY_Number_of_Techs__c == '1 Technician + Apprentice'){
                                orderItem.UNITY_Cost_Calculation_Details__c += 'Vendor 1 Technician + Apprentice Multiplier Applied : '+vendorApprenticeMultiplier+'\n';
                                vendorTechMultiplier = vendorApprenticeMultiplier;
                            }
                            
                            System.debug(LoggingLevel.INFO,'<AK> : assignedServiceAccountRecordType : '+assignedServiceAccountRecordType);
                            
                            System.debug(LoggingLevel.INFO,'<AK> : orderItem.UNITY_Cost__c : '+orderItem.UNITY_Cost__c);
                            
                            //orderItem.UNITY_Cost__c = orderItem.UNITY_Cost__c * vendorLaborMultiplier * vendorTechMultiplier;
                            System.debug(LoggingLevel.INFO,'<AK> : orderItem.UNITY_Cost__c : '+orderItem.UNITY_Cost__c);
                            
                            orderItem.UNITY_Vendor_Adjusted_Quantity__c = roundLaborHours(vendorQuantityToUse, serviceContractMap.get(vendorServiceContractId).UNITY_Invoicing_Increments__c, serviceContractMap.get(vendorServiceContractId).UNITY_Minimum_Labor_Hours__c);
                            
                            if(orderItem.UNITY_Vendor_Adjusted_Quantity__c==null){
                                if(vendorQuantityToUse !=null){
                                    orderItem.UNITY_Vendor_Adjusted_Quantity__c = vendorQuantityToUse;
                                }else{
                                    orderItem.UNITY_Vendor_Adjusted_Quantity__c = orderItem.Quantity;
                                }
                            }
                            
                            System.debug(LoggingLevel.INFO,'<AK> : orderItem.UNITY_Vendor_Adjusted_Quantity__c : '+orderItem.UNITY_Vendor_Adjusted_Quantity__c);
                            
                            orderItem.UNITY_Total_Cost__c = orderItem.UNITY_Cost__c * vendorLaborMultiplier * vendorTechMultiplier * orderItem.UNITY_Vendor_Adjusted_Quantity__c;
                            System.debug(LoggingLevel.INFO,'<AK> : orderItem.UNITY_Total_Cost__c : '+orderItem.UNITY_Total_Cost__c);
                            
                            System.debug(LoggingLevel.INFO,'<AK> : orderItem.UNITY_Cost_Calculation_Details__c : '+orderItem.UNITY_Cost_Calculation_Details__c);
                            
                            //Izay: Populate MSP Price with Cost if it is intercompany transfer and Cost != null or > 0
                            System.debug('Izay: isIntercompany = ' + isIntercompany);
                            if(isIntercompany && orderItem.UNITY_Is_Vendor_Supply__c && orderItem.UNITY_Total_Cost__c != null && orderItem.UNITY_Total_Cost__c > 0 && orderItem.UNITY_Vendor_Adjusted_Quantity__c != null && orderItem.UNITY_Vendor_Adjusted_Quantity__c > 0){
                                orderItem.MSPFS_MSP_Price__c = orderItem.UNITY_Total_Cost__c/orderItem.UNITY_Vendor_Adjusted_Quantity__c;
                            }

                            //CUSTOMER PRICE CALCULATION
                            //CUSTOMER: CONTRACT PRICING
                            if(includeFromContractPricing){
                                orderItem.UNITY_Customer_Adjusted_Quantity__c = orderItem.quantity != null ? orderItem.quantity : 1;
                                orderItem.UNITY_Total_Price__c = 0;
                                orderItem.UNITY_Price__c = 0;
                                orderItem.UNITY_Price_Calculation_Details__c += 'Price: 0 (Contract Pricing)\n';
                            }else if(onOrderItem.UNITY_Not_Billable__c){
                                orderItem.UNITY_Customer_Adjusted_Quantity__c = 0;
                                orderItem.UNITY_Total_Price__c = 0;
                                orderItem.UNITY_Price__c = 0;
                                orderItem.UNITY_Price_Calculation_Details__c = 'Price: 0 (Not Billable Line)\n';
                                orderItem.UNITY_Sales_Tax__c = 0;
                            }else{
                                System.debug('#####Izay: Checking if menu pricing...');
                                System.debug('#####Izay: Trigger.isUpdate = ' + Trigger.isUpdate);
                                System.debug('#####Izay: appliesMenuPricing.get(orderRecord.Id) = ' + appliesMenuPricing.get(orderRecord.Id));
                                System.debug('#####Izay: menuPricingMap.containsKey(customerServiceContractId) = ' + menuPricingMap.containsKey(customerServiceContractId));
                                System.debug('#####Izay: mpLinesMap.containsKey(orderRecord.Id) = ' + mpLinesMap.containsKey(orderRecord.Id));
                                System.debug('#####Izay: String.isNotBlank(onOrderItem.UNITY_Related_Menu_Price_Line__c) = ' + String.isNotBlank(onOrderItem.UNITY_Related_Menu_Price_Line__c));
                                //CUSTOMER: MENU PRICING: The labor hours and rate come from the menu pricing record if it exists
                                if(Trigger.isUpdate && appliesMenuPricing.get(orderRecord.Id) && menuPricingMap.containsKey(customerServiceContractId)  && mpLinesMap.containsKey(orderRecord.Id) && String.isNotBlank(onOrderItem.UNITY_Related_Menu_Price_Line__c)){
                                    System.debug('#####Izay: It is menu pricing labor line for: ' + onOrderItem.UNITY_Related_Menu_Price_Line__c);
                                    if(mpLinesMap.get(orderRecord.Id).containsKey(onOrderItem.UNITY_Related_Menu_Price_Line__c) && !orderItemsMap.containsKey(onOrderItem.UNITY_Related_Menu_Price_Line__c)){
                                        System.debug('#####Izay: mpLinesMap.containsKey: true');
                                        OrderItem mpLine = mpLinesMap.get(orderRecord.Id).get(onOrderItem.UNITY_Related_Menu_Price_Line__c);
                                        orderItem.UNITY_Price__c = menuPricingMap.get(customerServiceContractId).get(mpLine.PricebookEntry.Product2Id).UNITY_Labor_Cost__c;
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Price (Menu Pricing): '+orderItem.UNITY_Price__c+'\n';
                                        orderItem.UNITY_Customer_Adjusted_Quantity__c = (menuPricingMap.get(customerServiceContractId).get(mpLine.PricebookEntry.Product2Id).UNITY_Labor_Hours__c * mpLine.UNITY_Customer_Adjusted_Quantity__c);
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Customer Quantity Adjusted (Menu Pricing): '+orderItem.UNITY_Customer_Adjusted_Quantity__c+'\n';
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Menu Price Labor Qty: '+(menuPricingMap.get(customerServiceContractId).get(mpLine.PricebookEntry.Product2Id).UNITY_Labor_Hours__c)+'\n';
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Menu Price Line Qty: '+mpLine.UNITY_Customer_Adjusted_Quantity__c+'\n';
                                        orderItem.UNITY_Total_Price__c = orderItem.UNITY_Price__c * orderItem.UNITY_Customer_Adjusted_Quantity__c;
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Total Price (Menu Pricing): '+orderItem.UNITY_Total_Price__c+'\n';
                                        orderItem.Description = mpLine.PricebookEntry.Product2.Name+' Labor';
                                        //Set the MP Labor Vendor Adjusted Qty on the Menu price Line
                                        mpLine.UNITY_MP_Labor_Vendor_Adjusted_Qty__c = orderItem.UNITY_Vendor_Adjusted_Quantity__c;
                                        mpLine.UNITY_MP_Labor_Cost__c = orderItem.UNITY_Cost__c;
                                        orderItemsToUpdateMap.put(mpLine.Id,mpLine);
                                    }else{
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Price (Menu Pricing): '+orderItem.UNITY_Price__c+'\n';
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Customer Quantity Adjusted (Menu Pricing): '+orderItem.UNITY_Customer_Adjusted_Quantity__c+'\n';
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Total Price (Menu Pricing): '+onOrderItem.UNITY_Total_Price__c+'\n';
                                    }
                                }else{
                                    if (laborPriceByTradeFromSCLI > 0){
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Price from Service Contract Line Item by Trade: '+laborPriceByTradeFromSCLI+'\n';
                                        orderItem.UNITY_Price__c = laborPriceByTradeFromSCLI;
                                    }
                                    else if(defaultLaborPriceFromSC > 0){
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Price from Default Labor Price on Service Contract: '+defaultLaborPriceFromSC+'\n';
                                        orderItem.UNITY_Price__c = defaultLaborPriceFromSC;
                                    }
                                    else{
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Price from Order Item Cost: '+orderItem.UNITY_Cost__c+'\n';
                                        orderItem.UNITY_Price__c = orderItem.UNITY_Cost__c;
                                        
                                        if (costPlusByTradeFromSCLI > 0){
                                            orderItem.UNITY_Price_Calculation_Details__c += 'Cost Plus from Service Contract Line Item by Trade: '+costPlusByTradeFromSCLI+'\n';
                                            orderItem.UNITY_Cost_Plus__c = costPlusByTradeFromSCLI;
                                        } else {
                                            orderItem.UNITY_Price_Calculation_Details__c += 'Cost Plus (accountBasedMarkup + BUBasedMarkup): '+accountBasedMarkup + BUBasedMarkup+'\n';
                                            orderItem.UNITY_Cost_Plus__c = accountBasedMarkup + BUBasedMarkup;
                                        }
                                    }
                                    
                                    orderItem.UNITY_Customer_Adjusted_Quantity__c = roundLaborHours(customerQuantityToUse, serviceContractMap.get(customerServiceContractId).UNITY_Invoicing_Increments__c, serviceContractMap.get(customerServiceContractId).UNITY_Minimum_Labor_Hours__c);
                                    
                                    if(orderItem.UNITY_Customer_Adjusted_Quantity__c==null){
                                        if(customerQuantityToUse !=null){
                                            orderItem.UNITY_Customer_Adjusted_Quantity__c = customerQuantityToUse;
                                        }else{
                                            orderItem.UNITY_Customer_Adjusted_Quantity__c = orderItem.Quantity;
                                        }
                                    }
                                    
                                    System.debug(LoggingLevel.INFO,'<AK> : orderItem.UNITY_Customer_OT_Multiplier__c : '+orderItem.UNITY_Customer_OT_Multiplier__c);
                                    System.debug(LoggingLevel.INFO,'<AK> : orderItem.UNITY_Customer_Holiday_Multiplier__c : '+orderItem.UNITY_Customer_Holiday_Multiplier__c);
                                    System.debug(LoggingLevel.INFO,'<AK> : customerOTLaborMultiplier : '+customerOTLaborMultiplier);
                                    System.debug(LoggingLevel.INFO,'<AK> : customerHolidayLaborMultiplier : '+customerHolidayLaborMultiplier);
                                    
                                    if (orderItem.UNITY_Customer_OT_Multiplier__c){
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Customer OT Labor Multiplier Applied : '+customerOTLaborMultiplier+'\n';
                                        customerLaborMultiplier = customerOTLaborMultiplier;
                                    }else if(orderItem.UNITY_Customer_Holiday_Multiplier__c){
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Customer Holiday Labor Multiplier Applied : '+customerHolidayLaborMultiplier+'\n';
                                        customerLaborMultiplier = customerHolidayLaborMultiplier;
                                    }
                                    
                                    System.debug(LoggingLevel.INFO,'<AK> : customerLaborMultiplier : '+customerLaborMultiplier);
                                    System.debug(LoggingLevel.INFO,'<AK> : orderItem.UNITY_Price_Calculation_Details__c : '+orderItem.UNITY_Price_Calculation_Details__c);
                                    
                                    
                                    if (orderItem.UNITY_Number_of_Techs__c == '2 Technicians'){
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Customer 2 Tech Multiplier Applied : '+customer2TechMultiplier+'\n';
                                        customerTechMultiplier = customer2TechMultiplier;
                                    }else if (orderItem.UNITY_Number_of_Techs__c == 'Multi-Tech'){
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Customer Multi-Tech Multiplier Applied : '+customerMultiTechMultiplier+'\n';
                                        customerTechMultiplier = customerMultiTechMultiplier;
                                    }else if (orderItem.UNITY_Number_of_Techs__c == '1 Technician + Apprentice'){
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Customer 1 Technician + Apprentice Multiplier Applied : '+customerApprenticeMultiplier+'\n';
                                        customerTechMultiplier = customerApprenticeMultiplier;
                                    }
                                    
                                    System.debug(LoggingLevel.INFO,'<AK> : Labor POLI : isPassThroughCustomer : '+isPassThroughCustomer);
                                    System.debug(LoggingLevel.INFO,'<AK> : Labor POLI : orderItem.UNITY_Is_Vendor_Supply__c : '+orderItem.UNITY_Is_Vendor_Supply__c);
                                    
                                    if(isPassThroughCustomer && orderItem.UNITY_Is_Vendor_Supply__c){
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Customer is Pass Through. Defaulting the Price back to Vendor Cost: '+orderItem.UNITY_Cost__c+'\n';
                                        orderItem.UNITY_Price__c = orderItem.UNITY_Cost__c;
                                        orderItem.UNITY_Customer_Adjusted_Quantity__c = orderItem.UNITY_Vendor_Adjusted_Quantity__c;
                                        orderItem.UNITY_Total_Price__c = orderItem.UNITY_Total_Cost__c;
                                    }else{
                                        if(orderItem.UNITY_Cost_Plus__c!=null || orderItem.UNITY_Cost_Plus__c > 0){
                                            orderItem.UNITY_Price__c = orderItem.UNITY_Price__c + (orderItem.UNITY_Price__c * (orderItem.UNITY_Cost_Plus__c/100)).setScale(2,System.RoundingMode.HALF_DOWN);
                                        }
                                        
                                        orderItem.UNITY_Total_Price__c = orderItem.UNITY_Price__c * customerLaborMultiplier * customerTechMultiplier * orderItem.UNITY_Customer_Adjusted_Quantity__c;
                                    }
                                }
                                
                                System.debug(LoggingLevel.INFO,'<AK> : orderItem.UNITY_Price_Calculation_Details__c : '+orderItem.UNITY_Price_Calculation_Details__c);
                                
                                //orderItem.UNITY_Price__c = orderItem.UNITY_Price__c * customerLaborMultiplier * customerTechMultiplier;
                                
                            }
                        }
/* **********************************************************************************************************************
 * ******************** PO TRAVEL LINE CALCULATE PRICE ******************************************************************
 * ********************************************************************************************************************** */
                        else if (orderItem.PricebookEntry.Product2.UNITY_Product_Type__c == 'Travel'){
                            orderItem.UNITY_Cost_Calculation_Details__c += 'Original Cost: '+orderItem.UNITY_Cost__c+'\n';
                            orderItem.UNITY_Price_Calculation_Details__c += 'Original Price: '+orderItem.UNITY_Price__c+'\n';
                            
                            Decimal vendorTravelMultiplier = 1;
                            Decimal customerTravelMultiplier = 1;
                            Decimal vendorTechMultiplier = 1;
                            Decimal customerTechMultiplier = 1;
                            system.debug('@@ : orderItem.UNITY_Cost__c : '+orderItem.UNITY_Cost__c);
                            system.debug('@@ : vendorTripCharge : '+vendorTripCharge);
                            system.debug('@@ : vendorTripChargeType : '+vendorTripChargeType);
                            //Izay: Updated to get Labor Cost rate from Tech profile for MSP BU POs
                            Boolean isMspBu = workOrderMap.containsKey(orderRecord.FSO__WorkOrder__c)?workOrderMap.get(orderRecord.FSO__WorkOrder__c).UNITY_Business_Unit_Account__r.MSPFS_Is_MSP_BU__c:false;
                            if(isMspBu){
                                Decimal rate = 0;
                                System.debug('Izay: isNotBlank(orderItem.MSPFS_Technician__c) = ' + String.isNotBlank(orderItem.MSPFS_Technician__c));
                                if(String.isNotBlank(orderItem.MSPFS_Technician__c)){
                                    System.debug('Izay: techsMap.containsKey(orderItem.MSPFS_Technician__c) = ' + techsMap.containsKey(orderItem.MSPFS_Technician__c));
                                    if(techsMap.containsKey(orderItem.MSPFS_Technician__c)){
                                        Decimal tech1Rate = techsMap.get(orderItem.MSPFS_Technician__c).MSPFS_Burden_Rate__c != null ?
                                            techsMap.get(orderItem.MSPFS_Technician__c).MSPFS_Burden_Rate__c : 0;
                                        System.debug('Izay: tech1Rate = ' + tech1Rate);
                                        rate += tech1Rate;
                                    }
                                }
                                if(String.isNotBlank(orderItem.MSPFS_Technician2__c)){
                                    if(techsMap.containsKey(orderItem.MSPFS_Technician2__c)){
                                        Decimal tech2Rate = techsMap.get(orderItem.MSPFS_Technician2__c).MSPFS_Burden_Rate__c != null ?
                                            techsMap.get(orderItem.MSPFS_Technician2__c).MSPFS_Burden_Rate__c : 0;
                                        rate += tech2Rate;
                                    }
                                }
                                orderItem.UNITY_Cost_Calculation_Details__c += 'Cost from Technician(s) Burden Rate: '+rate+'\n';
                                orderItem.UNITY_Cost__c = rate.setScale(2,System.RoundingMode.HALF_DOWN);
                                vendorTripCharge = rate.setScale(2,System.RoundingMode.HALF_DOWN);
                                system.debug('@@ Izay: orderItem.UNITY_Cost__c : '+orderItem.UNITY_Cost__c);
                                system.debug('@@ Izay: vendorTripCharge : '+ vendorTripCharge);
                                system.debug('@@ Izay: vendorTripChargeType : '+ vendorTripChargeType);
                                if (vendorTripChargeType == 'Hourly Rate'){
                                    orderItem.UNITY_Vendor_Adjusted_Quantity__c = orderItem.Quantity;
                                    orderItem.UNITY_Subtype__c = 'Hourly Rate';
                                }else if (vendorTripChargeType == 'Flat Fee'){
                                    orderItem.UNITY_Vendor_Adjusted_Quantity__c = 1;
                                    orderItem.UNITY_Subtype__c = 'Flat Fee';
                                }
                            }else
                            // VENDOR COST CALCULATION
                            if (orderItem.UNITY_Cost__c == null || orderItem.UNITY_Cost__c <= 0){
                                if(vendorTripCharge != null && vendorTripChargeType!= null){
                                    
                                    if (vendorTripChargeType == 'Flat Fee'){
                                        orderItem.UNITY_Cost_Calculation_Details__c += 'Cost from Service Contract (Flat Fee): '+vendorTripCharge+'\n';
                                        orderItem.UNITY_Cost__c = vendorTripCharge.setScale(2,System.RoundingMode.HALF_DOWN);
                                        orderItem.UNITY_Vendor_Adjusted_Quantity__c = 1;
                                        orderItem.UNITY_Subtype__c = 'Flat Fee';
                                    }
                                    else if (vendorTripChargeType == 'Hourly Rate'){
                                        orderItem.UNITY_Cost_Calculation_Details__c += 'Cost from Service Contract (Hourly Rate): '+vendorTripCharge+'\n';
                                        orderItem.UNITY_Cost__c = vendorTripCharge.setScale(2,System.RoundingMode.HALF_DOWN);
                                        orderItem.UNITY_Vendor_Adjusted_Quantity__c = orderItem.Quantity;
                                        orderItem.UNITY_Subtype__c = 'Hourly Rate';
                                    }
                                }
                            }else{
                                if(vendorTripChargeType!= null){
                                    if (vendorTripChargeType == 'Hourly Rate'){
                                        orderItem.UNITY_Vendor_Adjusted_Quantity__c = orderItem.Quantity;
                                    }else if (vendorTripChargeType == 'Flat Fee'){
                                        orderItem.UNITY_Vendor_Adjusted_Quantity__c = 1;
                                    }
                                }
                            }
                            
                            system.debug('@@ : orderItem.UNITY_Cost__c : '+orderItem.UNITY_Cost__c);
                            system.debug('@@ : orderItem.UNITY_Vendor_Adjusted_Quantity__c : '+orderItem.UNITY_Vendor_Adjusted_Quantity__c);
                            system.debug('@@ : vendorTravelMultiplier : '+vendorTravelMultiplier);
                            
                            //we don't apply any multipliers if it's flat fee
                            if(vendorTripChargeType != 'Flat Fee'){
                                if (orderItem.UNITY_Vendor_OT_Multiplier__c){
                                    orderItem.UNITY_Cost_Calculation_Details__c += 'Vendor OT Travel Multiplier Applied : '+vendorOTTravelMultiplier+'\n';
                                    vendorTravelMultiplier = vendorOTTravelMultiplier;
                                }else if(orderItem.UNITY_Vendor_Holiday_Multiplier__c){
                                    orderItem.UNITY_Cost_Calculation_Details__c += 'Vendor Holiday Travel Multiplier Applied : '+vendorHolidayTravelMultiplier+'\n';
                                    vendorTravelMultiplier = vendorHolidayTravelMultiplier;
                                }
                                system.debug('@@ : orderItem.UNITY_Cost_Calculation_Details__c : '+orderItem.UNITY_Cost_Calculation_Details__c);
                                system.debug('@@ : vendorTravelMultiplier : '+vendorTravelMultiplier);
                                
                                if (orderItem.UNITY_Number_of_Techs__c == '2 Technicians'){
                                    orderItem.UNITY_Cost_Calculation_Details__c += 'Vendor 2 Tech Multiplier Applied : '+vendor2TechMultiplier+'\n';
                                    vendorTechMultiplier = vendor2TechMultiplier;
                                }else if (orderItem.UNITY_Number_of_Techs__c == 'Multi-Tech'){
                                    orderItem.UNITY_Cost_Calculation_Details__c += 'Vendor Multi-Tech Multiplier Applied : '+vendorMultiTechMultiplier+'\n';
                                    vendorTechMultiplier = vendorMultiTechMultiplier;
                                }else if (orderItem.UNITY_Number_of_Techs__c == '1 Technician + Apprentice'){
                                    orderItem.UNITY_Cost_Calculation_Details__c += 'Vendor 1 Technician + Apprentice Multiplier Applied : '+vendorApprenticeMultiplier+'\n';
                                    vendorTechMultiplier = vendorApprenticeMultiplier;
                                }
                            }
                            
                            system.debug('@@ : orderItem.UNITY_Cost__c : '+orderItem.UNITY_Cost__c);
                            //orderItem.UNITY_Cost__c = orderItem.UNITY_Cost__c * vendorTravelMultiplier * vendorTechMultiplier;
                            
                            orderItem.UNITY_Total_Cost__c = orderItem.UNITY_Cost__c * vendorTravelMultiplier * vendorTechMultiplier * orderItem.UNITY_Vendor_Adjusted_Quantity__c;
                            system.debug('@@ : orderItem.UNITY_Total_Cost__c : '+orderItem.UNITY_Total_Cost__c);
                            
                            //Izay: Populate MSP Price with Cost if it is intercompany transfer and Cost != null or > 0
                            if(isIntercompany && orderItem.UNITY_Is_Vendor_Supply__c  && orderItem.UNITY_Total_Cost__c != null && orderItem.UNITY_Total_Cost__c > 0 && orderItem.UNITY_Vendor_Adjusted_Quantity__c != null && orderItem.UNITY_Vendor_Adjusted_Quantity__c > 0){
                                orderItem.MSPFS_MSP_Price__c = orderItem.UNITY_Total_Cost__c/orderItem.UNITY_Vendor_Adjusted_Quantity__c;
                            }

                            // CUSTOMER PRICE CALCULATION
                            
                            system.debug('@@ : customerTripCharge : '+customerTripCharge);
                            system.debug('@@ : customerTripChargeType : '+customerTripChargeType);
                            system.debug('@@ : costPlusByTradeFromSCLI : '+costPlusByTradeFromSCLI);
                            system.debug('@@ : accountBasedMarkup : '+accountBasedMarkup);
                            system.debug('@@ : BUBasedMarkup : '+BUBasedMarkup);
                            
                            if(includeFromContractPricing){
                                if(Trigger.isInsert){
                                    orderItem.UNITY_Customer_Adjusted_Quantity__c = orderItem.quantity != null ? orderItem.quantity : 1;
                                    orderItem.UNITY_Price__c = 0;
                                    orderItem.UNITY_Total_Price__c = 0;
                                    orderItem.UNITY_Price_Calculation_Details__c += 'Price: 0 (Contract Pricing)\n';
                                }else if(Trigger.isUpdate){
                                    orderItem.UNITY_Customer_Adjusted_Quantity__c = orderItem.quantity != null ? orderItem.quantity : 1;
                                    orderItem.UNITY_Total_Price__c = orderItem.UNITY_Price__c * orderItem.UNITY_Customer_Adjusted_Quantity__c;
                                    orderItem.UNITY_Price_Calculation_Details__c += 'Price: 0 (Contract Pricing)\n';
                                }
                            }else if(onOrderItem.UNITY_Not_Billable__c){
                                orderItem.UNITY_Customer_Adjusted_Quantity__c = 0;
                                orderItem.UNITY_Total_Price__c = 0;
                                orderItem.UNITY_Price__c = 0;
                                orderItem.UNITY_Price_Calculation_Details__c = 'Price: 0 (Not Billable Line)\n';
                                orderItem.UNITY_Sales_Tax__c = 0;
                            }else{
                                if(customerTripCharge != null && customerTripChargeType!= null){
                                    
                                    if (customerTripChargeType == 'Flat Fee'){
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Price from Customer Trip Charge (Flat Fee): '+customerTripCharge+'\n';
                                        orderItem.UNITY_Price__c = customerTripCharge;
                                        orderItem.UNITY_Customer_Adjusted_Quantity__c = 1;
                                    }
                                    else if (customerTripChargeType == 'Hourly Rate'){
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Price from Customer Trip Charge (Hourly Rate): '+customerTripCharge+'\n';
                                        orderItem.UNITY_Price__c = customerTripCharge;
                                        orderItem.UNITY_Customer_Adjusted_Quantity__c = orderItem.Quantity;
                                    }
                                }else{
                                    orderItem.UNITY_Price_Calculation_Details__c += 'Price from Order Item Cost: '+orderItem.UNITY_Cost__c+'\n';
                                    orderItem.UNITY_Price__c = orderItem.UNITY_Cost__c;
                                    
                                    if (costPlusByTradeFromSCLI > 0){
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Cost Plus form Service Contract Line Item by Trade: '+costPlusByTradeFromSCLI+'\n';
                                        orderItem.UNITY_Cost_Plus__c = costPlusByTradeFromSCLI;
                                    } else {
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Cost Plus (accountBasedMarkup + BUBasedMarkup): '+accountBasedMarkup + BUBasedMarkup+'\n';
                                        orderItem.UNITY_Cost_Plus__c = accountBasedMarkup + BUBasedMarkup;
                                    }
                                }
                                
                                system.debug('@@ : orderItem.UNITY_Cost_Plus__c : '+orderItem.UNITY_Cost_Plus__c);
                                system.debug('@@ : orderItem.UNITY_Price__c : '+orderItem.UNITY_Price__c);
                                system.debug('@@ : orderItem.UNITY_Customer_Adjusted_Quantity__c : '+orderItem.UNITY_Customer_Adjusted_Quantity__c);
                                
                                //we don't apply any multipliers if it's flat fee
                                if (customerTripChargeType != 'Flat Fee'){
                                    if (orderItem.UNITY_Customer_OT_Multiplier__c){
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Customer OT Travel Multiplier Applied : '+customerOTTravelMultiplier+'\n';
                                        customerTravelMultiplier = customerOTTravelMultiplier;
                                    }else if(orderItem.UNITY_Customer_Holiday_Multiplier__c){
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Customer Holiday Travel Multiplier Applied : '+customerHolidayTravelMultiplier+'\n';
                                        customerTravelMultiplier = customerHolidayTravelMultiplier;
                                    }
                                    
                                    if (orderItem.UNITY_Number_of_Techs__c == '2 Technicians'){
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Customer 2 Tech Multiplier Applied : '+customer2TechMultiplier+'\n';
                                        customerTechMultiplier = customer2TechMultiplier;
                                    }else if (orderItem.UNITY_Number_of_Techs__c == 'Multi-Tech'){
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Customer Multi-Tech Multiplier Applied : '+customerMultiTechMultiplier+'\n';
                                        customerTechMultiplier = customerMultiTechMultiplier;
                                    }else if (orderItem.UNITY_Number_of_Techs__c == '1 Technician + Apprentice'){
                                        orderItem.UNITY_Price_Calculation_Details__c += 'Customer 1 Technician + Apprentice Multiplier Applied : '+customerApprenticeMultiplier+'\n';
                                        customerTechMultiplier = customerApprenticeMultiplier;
                                    }
                                }
                                
                                if(isPassThroughCustomer && orderItem.UNITY_Is_Vendor_Supply__c){
                                    orderItem.UNITY_Price_Calculation_Details__c += 'Customer is Pass Through. Defaulting the Price back to Vendor Cost: '+orderItem.UNITY_Cost__c+'\n';
                                    orderItem.UNITY_Price__c = orderItem.UNITY_Cost__c;
                                    orderItem.UNITY_Customer_Adjusted_Quantity__c = orderItem.UNITY_Vendor_Adjusted_Quantity__c;
                                    orderItem.UNITY_Total_Price__c = orderItem.UNITY_Total_Cost__c;
                                }else{
                                    if(orderItem.UNITY_Cost_Plus__c!=null || orderItem.UNITY_Cost_Plus__c > 0){
                                        orderItem.UNITY_Price__c = orderItem.UNITY_Price__c + (orderItem.UNITY_Price__c * (orderItem.UNITY_Cost_Plus__c/100)).setScale(2,System.RoundingMode.HALF_DOWN);
                                    }
                                    //else{
                                    //    orderItem.UNITY_Price__c = orderItem.UNITY_Cost__c;
                                    //}
                                    
                                    orderItem.UNITY_Price__c = orderItem.UNITY_Price__c * customerTravelMultiplier * customerTechMultiplier;
                                    orderItem.UNITY_Total_Price__c = (orderItem.UNITY_Price__c != null ? orderItem.UNITY_Price__c: 0)  * (orderItem.UNITY_Customer_Adjusted_Quantity__c != null ? orderItem.UNITY_Customer_Adjusted_Quantity__c : 0);
                                }
                                
                                system.debug('@@ : orderItem.UNITY_Price__c : '+orderItem.UNITY_Price__c);
                                
                                system.debug('@@ : orderItem.UNITY_Price__c : '+orderItem.UNITY_Price__c);
                                
                                system.debug('@@ : orderItem.UNITY_Total_Price__c : '+orderItem.UNITY_Total_Price__c);
                                
                                system.debug('@@ : serviceContractMap.get(customerServiceContractId).UNITY_Max_Allowable_Trip_Charges__c : '+serviceContractMap.get(customerServiceContractId).UNITY_Max_Allowable_Trip_Charges__c);
                                
                                //if (serviceContractMap.get(customerServiceContractId).UNITY_Max_Allowable_Trip_Charges__c !=null && orderItem.UNITY_Total_Price__c > serviceContractMap.get(customerServiceContractId).UNITY_Max_Allowable_Trip_Charges__c){
                                //    orderItem.UNITY_Total_Price__c = serviceContractMap.get(customerServiceContractId).UNITY_Max_Allowable_Trip_Charges__c;
                                //}
                            }
                        }else if (generalSettings.get(UNITY_Constants.SERVICE_FEE_PRODUCT_TYPE_CS_KEY)!=null && orderItem.PricebookEntry.Product2.UNITY_Product_Type__c == generalSettings.get(UNITY_Constants.SERVICE_FEE_PRODUCT_TYPE_CS_KEY).UNITY_Value__c){
                            orderItem.UNITY_Cost_Calculation_Details__c += 'Cost Calculated from Vendor Service Contract Line Items for Service Fee: '+orderItem.UNITY_Cost__c+'\n';
                            orderItem.UNITY_Vendor_Adjusted_Quantity__c = orderItem.Quantity;
                            orderItem.UNITY_Total_Cost__c = orderItem.UNITY_Cost__c * orderItem.UNITY_Vendor_Adjusted_Quantity__c;
                            
                            orderItem.UNITY_Price_Calculation_Details__c += 'Service Fee Line Items have $0 Price: '+0+'\n';
                            orderItem.UNITY_Price__c = 0;
                            orderItem.UNITY_Customer_Adjusted_Quantity__c = orderItem.Quantity;
                            orderItem.UNITY_Total_Price__c = orderItem.UNITY_Price__c * orderItem.UNITY_Customer_Adjusted_Quantity__c;
                            orderItem.UNITY_Type__c = 'Service Fee';
                            orderItem.UNITY_Activity_Type__c = 'Service Fee';

                        }else{
                            if (orderItem.UNITYPM_Non_Payable__c){
                                orderItem.UNITY_Cost__c = orderItem.UNITYPM_Cost_For_Non_Payable__c;
                            }
                            // VENDOR COST CALCULATION
                            if (orderItem.UNITY_Cost__c == null || orderItem.UNITY_Cost__c <= 0){
                                if (costByProductFromSCLI >= 0){
                                    orderItem.UNITY_Cost__c = costByProductFromSCLI.setScale(2,System.RoundingMode.HALF_DOWN);
                                }
                                if (orderItem.UNITY_Cost__c == null){
                                    orderItem.UNITY_Cost__c = 0; //No Cost found. Agent MUST manually enter it.
                                }
                            }
                            orderItem.UNITY_Vendor_Adjusted_Quantity__c = orderItem.Quantity;
                            orderItem.UNITY_Total_Cost__c = orderItem.UNITY_Cost__c * orderItem.UNITY_Vendor_Adjusted_Quantity__c;
                            
                            // CUSTOMER PRICE CALCULATION
                            orderItem.UNITY_Price__c = orderItem.UNITY_Cost__c;
                            if(orderItem.UNITY_Not_Billable__c){
                                orderItem.UNITY_Customer_Adjusted_Quantity__c = 0;
                                orderItem.UNITY_Total_Price__c = 0;
                                orderItem.UNITY_Price__c = 0;
                                orderItem.UNITY_Price_Calculation_Details__c = 'Price: 0 (Not Billable Line)\n';
                                orderItem.UNITY_Sales_Tax__c = 0;
                            }//CUSTOMER: CONTRACT PRICING
                            if(includeFromContractPricing){
                                orderItem.UNITY_Customer_Adjusted_Quantity__c = orderItem.quantity != null ? orderItem.quantity : 1;
                                orderItem.UNITY_Total_Price__c = 0;
                                orderItem.UNITY_Price__c = 0;
                                orderItem.UNITY_Price_Calculation_Details__c += 'Price: 0 (Contract Pricing)\n';
                            //CUSTOMER: NOT BILLABLE LINE
                            }else if(onOrderItem.UNITY_Not_Billable__c){
                                orderItem.UNITY_Customer_Adjusted_Quantity__c = 0;
                                orderItem.UNITY_Total_Price__c = 0;
                                orderItem.UNITY_Price__c = 0;
                                orderItem.UNITY_Price_Calculation_Details__c = 'Price: 0 (Not Billable Line)\n';
                                orderItem.UNITY_Sales_Tax__c = 0;
                            //CUSTOMER: MENU PRICING & STANDARD PRICING
                            }else if ( priceByProductFromSCLI != null && priceByProductFromSCLI >= 0){
                                orderItem.UNITY_Price__c = priceByProductFromSCLI;
                            } else {
                                orderItem.UNITY_Price__c = orderItem.UNITY_Cost__c;
                                if (costPlusByTradeFromSCLI > 0){
                                    orderItem.UNITY_Cost_Plus__c = costPlusByTradeFromSCLI;
                                } else if (defaultCostPlusFromSC > 0){
                                    orderItem.UNITY_Cost_Plus__c = defaultCostPlusFromSC;
                                } else {
                                    orderItem.UNITY_Cost_Plus__c = accountBasedMarkup + BUBasedMarkup;
                                }
                            }
                            
                            orderItem.UNITY_Customer_Adjusted_Quantity__c = orderItem.Quantity;
                            
                            if(isPassThroughCustomer && orderItem.UNITY_Is_Vendor_Supply__c){
                                orderItem.UNITY_Price_Calculation_Details__c += 'Customer is Pass Through. Defaulting the Price back to Vendor Cost: '+orderItem.UNITY_Cost__c+'\n';
                                orderItem.UNITY_Price__c = orderItem.UNITY_Cost__c;
                                orderItem.UNITY_Customer_Adjusted_Quantity__c = orderItem.UNITY_Vendor_Adjusted_Quantity__c;
                                orderItem.UNITY_Total_Price__c = orderItem.UNITY_Total_Cost__c;
                            }else{
                                
                                orderItem.UNITY_Customer_Adjusted_Quantity__c = orderItem.Quantity;
                                
                                if(orderItem.UNITY_Cost_Plus__c!=null || orderItem.UNITY_Cost_Plus__c > 0){
                                    orderItem.UNITY_Price__c = orderItem.UNITY_Price__c + (orderItem.UNITY_Price__c * (orderItem.UNITY_Cost_Plus__c/100)).setScale(2,System.RoundingMode.HALF_DOWN);
                                }
                                
                                orderItem.UNITY_Total_Price__c = orderItem.UNITY_Price__c * orderItem.UNITY_Customer_Adjusted_Quantity__c;
                            }
                        }
                        //<AK> orderItemsToUpdate.add(orderItem);
                        orderItemsToUpdateMap.put(orderItem.id, orderItem);
                    }
                }
            }
        }
        //<AK>System.debug('#orderItemsToUpdate '+orderItemsToUpdate);
        //<AK>update orderItemsToUpdate;
        if(!toInsert_mpLabor.isEmpty()){
            //UNITY_Constants.isExecutingContext('recalculatePricing');
            insert toInsert_mpLabor;
        }
        return  orderItemsToUpdateMap;
    }

    /** need to rewrite this to use a dynamic function that can be used for both Order and Proposal */
    public static void recalculateProposalPricing (Set<Id> proposalItemIdSet){
        // query proposal records
        List<UNITY_Proposal_Line_Item__c> proposalItemList = [SELECT id, UNITY_Proposal__c,UNITY_Proposal__r.UNITY_Work_Order__c, UNITY_Product__c, UNITY_Product__r.UNITY_Product_Type__c,
                                                              MSPFS_Technician__c,MSPFS_Technician2__c,MSPFS_MSP_Cost__c,MSPFS_MSP_Price__c 
                                                              FROM UNITY_Proposal_Line_Item__c WHERE Id IN:proposalItemIdSet];

        Set<Id> parentIds = new Set<Id>();
        Set<Id> workOrerIdSet = new Set<Id>();

        //<AK>
        Set<Id> productIds = new Set<Id>();
        //Need to get the resource (tech ids) from the QLIs to find the burden rate
        Set<Id> techIds = new Set<Id>();
        for (UNITY_Proposal_Line_Item__c iter: proposalItemList){
            //<AK>
            if(iter.UNITY_Product__r.UNITY_Product_Type__c == 'Part'){
                productIds.add(iter.UNITY_Product__c);
            }

            workOrerIdSet.add(iter.UNITY_Proposal__r.UNITY_Work_Order__c);
            parentIds.add(iter.UNITY_Proposal__c);
            //Izay: Added to get techs record
            if(String.isNotBlank(iter.MSPFS_Technician__c))
                techIds.add(iter.MSPFS_Technician__c);
            if(String.isNotBlank(iter.MSPFS_Technician2__c))
                techIds.add(iter.MSPFS_Technician2__c);
        }
        //Izay: Get resource(tech) record
        Map<Id,CKSW_BASE__Resource__c> techsMap = new Map<Id,CKSW_BASE__Resource__c>([SELECT Id,MSPFS_Burden_Rate__c FROM CKSW_BASE__Resource__c WHERE Id IN :techIds]);
        //<AK> related Stockable Products (Location Stock)
        List<FSO__LocationStock__c> locationStockList = [Select Id, UNITY_Landed_Cost__c, FSO__Quantity__c, FSO__Product__c, FSO__Location__r.UNITY_Business_Unit_Account__c from FSO__LocationStock__c where FSO__Product__c in :productIds];
        Map<String, FSO__LocationStock__c> productToLocationStockMap = new Map<String, FSO__LocationStock__c>();
        for (FSO__LocationStock__c iter: locationStockList){
            productToLocationStockMap.put(iter.FSO__Product__c +'|'+iter.FSO__Location__r.UNITY_Business_Unit_Account__c, iter);
        }
        system.debug('@@ : productToLocationStockMap : '+productToLocationStockMap);

        // related work orders
        List<WorkOrder> workOrderList = [SELECT id, SFPS_FS_OverallStatus__c, SFPS_FS_TotalServiceTime__c, UNITY_Use_Menu_Pricing__c, UNITY_Trade__r.UNITY_Skill_Broad__c,
                                         UNITY_Customer__r.UNITY_Customer_Size__c, UNITY_Business_Unit__c, UNITY_Business_Unit_Account__c, UNITY_Customer_Service_Contract__c,
                                         UNITY_Vendor_Contract__c, UNITY_Secondary_Technician__c,UNITY_Assigned_Vendor__c,UNITY_Assigned_Vendor__r.RecordType.DeveloperName,RecordTypeId,
                                         UNITY_Business_Unit_Account__r.MSPFS_Is_MSP_BU__c,MSPFS_Intercompany_Transfer__c
                                         FROM WorkOrder WHERE Id IN:workOrerIdSet];

        //Map <workOrderId, vendorContractId>
        Map<Id, Id> workOrderVendorContractMap = new Map<Id, Id>();

        //Map <workOrderId, customerContractId>
        Map<Id, Id> workOrderCustomerContractMap = new Map<Id, Id>();

        //Map <workOrderId, workOrder>
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>();

        //<AK>Set<Broad>
        Set<String> broads = new Set<String>();

        //<AK>Set<CustomerSize>
        Set<String> customerSizes = new Set<String>();

        //<AK>Set<BusinessUnitAccount>
        Set<String> buAccounts = new Set<String>();

        for (WorkOrder iter: workOrderList){
            workOrderVendorContractMap.put(iter.id, iter.UNITY_Vendor_Contract__c);
            workOrderCustomerContractMap.put(iter.id, iter.UNITY_Customer_Service_Contract__c);
            workOrderMap.put(iter.id, iter);

            //<AK>
            broads.add(iter.UNITY_Trade__r.UNITY_Skill_Broad__c);
            buAccounts.add(iter.UNITY_Business_Unit_Account__c);
            customerSizes.add(iter.UNITY_Customer__r.UNITY_Customer_Size__c);
        }

        //<AK>
        //Map<Broad|CustomerSize|BusinessUnitAccount, CostPlus>
        Map<String,Decimal> costPlusFromAccountPricingMatrix = new Map<String,Decimal>();

        //Map<ProductId|BusinessUnitAccount, CostPlus>
        Map<String,Decimal> costPlusByBUAndPart = new Map<String,Decimal>();

        List<UNITY_Account_Pricing_Matrix__c> accountPricingMatrix = [Select Id, UNITY_Broad__c, UNITY_Business_Unit_Account__c, UNITY_Customer_Size__c, UNITY_Cost_Plus__c from UNITY_Account_Pricing_Matrix__c where UNITY_Broad__c in :broads AND UNITY_Business_Unit_Account__c in :buAccounts AND UNITY_Customer_Size__c in :customerSizes];
        List<UNITY_BU_Markup_Junction__c> buMarkupJunction = [Select Id, UNITY_BU_Account__c, UNITY_Product__c, UNITY_Markup__c from UNITY_BU_Markup_Junction__c where UNITY_BU_Account__c in :buAccounts AND UNITY_Product__c in :productIds];

        for (UNITY_Account_Pricing_Matrix__c iter : accountPricingMatrix){
            String key = iter.UNITY_Broad__c + '|' + iter.UNITY_Business_Unit_Account__c + '|' + iter.UNITY_Customer_Size__c;
            costPlusFromAccountPricingMatrix.put(key, iter.UNITY_Cost_Plus__c);
        }

        for (UNITY_BU_Markup_Junction__c iter : buMarkupJunction){
            String key = iter.UNITY_BU_Account__c + '|' + iter.UNITY_Product__c;
            costPlusByBUAndPart.put(key, iter.UNITY_Markup__c);
        }

        //Map<productId, price>
        Map<Id, Map<Id,Decimal>> productPriceMap = new Map<Id, Map<Id,Decimal>>();
        //Map<productId, costPlus>
        Map<Id, Map<Id,Decimal>> productCostPlusMap = new Map<Id, Map<Id,Decimal>>();

        //Map<SCId, Map<String,SCLI>>
        Map<Id, Map<String,UNITY_Service_Contract_Line_Item__c>> menuPricingMap = new Map<Id, Map<String,UNITY_Service_Contract_Line_Item__c>>();

        //Map<serviceContractId, List<tradeId, SCLI>>
        Map<Id, Map<String,UNITY_Service_Contract_Line_Item__c>> serviceContractLineByTradeMap = new Map<Id, Map<String,UNITY_Service_Contract_Line_Item__c>>();

        //Map<serviceContractId, vendorServiceContract>
        Map<Id, UNITY_Service_Contract__c> serviceContractMap = new Map<Id, UNITY_Service_Contract__c>();

        List<UNITY_Service_Contract__c> contractList = [select id, UNITY_Is_Pass_Through__c, UNITY_Cost_Plus__c, UNITY_Minimum_Labor_Hours__c, UNITY_Max_Allowable_Trip_Charges__c, UNITY_2_Technicians__c,UNITY_Apprentice__c,UNITY_Multi_Technician__c,UNITY_Holiday_Multiplier__c,UNITY_OT_Multiplier__c,UNITY_Holiday_Travel_Multiplier__c,UNITY_OT_Travel_Multiplier__c, UNITY_Default_Labor_Rate__c, UNITY_Trip_Charge__c, UNITY_Trip_Charge_Type__c, UNITY_Invoicing_Increments__c, (select id, UNITY_Labor_Hours__c, UNITY_Trip_Charge__c, UNITY_Trip_Charge_Type__c, UNITY_Trade__c, UNITY_Cost_Plus__c, UNITY_Labor_Cost__c, UNITY_Product__r.Id, UNTIY_Material_Cost__c, UNITY_Self_Perform_Labor_Cost__c, UNITY_Self_Perform_Trip_Charge_Cost__c, UNITY_Self_Perform_Trip_Charge_Type__c, UNITY_Holiday_Multiplier__c,UNITY_OT_Multiplier__c,UNITY_Holiday_Travel_Multiplier__c,UNITY_OT_Travel_Multiplier__c, RecordType.DeveloperName from UNITY_Service_Contract_Line_Items__r) from UNITY_Service_Contract__c where (id in: workOrderVendorContractMap.values()) OR (id in: workOrderCustomerContractMap.values())];
        
        for(UNITY_Service_Contract__c serviceContract: contractList){

            serviceContractMap.put(serviceContract.Id, serviceContract);

            productPriceMap.put(serviceContract.Id, new Map<Id, Decimal>());
            productCostPlusMap.put(serviceContract.Id, new Map<Id, Decimal>());
            serviceContractLineByTradeMap.put(serviceContract.Id, new Map<String, UNITY_Service_Contract_Line_Item__c>());
            
            for(UNITY_Service_Contract_Line_Item__c scli: serviceContract.UNITY_Service_Contract_Line_Items__r){
                //System.debug('###Izay: SCLI Record Type? ' + scli.RecordType.DeveloperName);
                if (scli.RecordType.DeveloperName == 'UNITY_Product_Pricing' && scli.UNTIY_Material_Cost__c != null){
                    productPriceMap.get(serviceContract.Id).put(scli.UNITY_Product__r.Id, scli.UNTIY_Material_Cost__c);
                }
                else if(scli.RecordType.DeveloperName == 'UNITY_Product_Pricing' && scli.UNITY_Cost_Plus__c != null){
                    productCostPlusMap.get(serviceContract.Id).put(scli.UNITY_Product__r.Id, scli.UNITY_Cost_Plus__c);
                }else if(scli.RecordType.DeveloperName == UNITY_Constants.SCLI_HOURLY_RATE_RT){
                    serviceContractLineByTradeMap.get(serviceContract.Id).put(scli.UNITY_Trade__c+'|'+UNITY_Constants.SCLI_HOURLY_RATE_RT, scli);
                }else if(scli.RecordType.DeveloperName == UNITY_Constants.SCLI_PRODUCT_PRICING_RULE_RT){
                    serviceContractLineByTradeMap.get(serviceContract.Id).put(scli.UNITY_Trade__c+'|'+UNITY_Constants.SCLI_PRODUCT_PRICING_RULE_RT, scli);
                }else if(scli.RecordType.DeveloperName == UNITY_Constants.SCLI_NTE_RT){
                    serviceContractLineByTradeMap.get(serviceContract.Id).put(scli.UNITY_Trade__c+'|'+UNITY_Constants.SCLI_NTE_RT, scli);
                }
                else if (scli.RecordType.DeveloperName == UNITY_Constants.SCLI_MENU_PRICING_RT){
                    //System.debug('###Izay: Found menu pricing line type...');
                    //System.debug('###Izay: Adding line to menuPricingMap...');
                    if(!menuPricingMap.containsKey(serviceContract.Id))
                        menuPricingMap.put(serviceContract.Id, new Map<String,UNITY_Service_Contract_Line_Item__c>());
                    menuPricingMap.get(serviceContract.Id).put(scli.UNITY_Product__r.Id,scli);
                    //System.debug('###Izay: menuPricingMap: ' + menuPricingMap);
                }
            }
        }

        //get related proposals
        List<UNITY_Proposal__c> proposalList = [SELECT id, UNITY_Business_Unit_Account__c, UNITY_Work_Order__c, UNITY_Work_Order__r.UNITY_Trade__c,UNITY_Work_Order__r.UNITY_Assigned_Vendor__c,UNITY_Work_Order__r.UNITY_Assigned_Vendor__r.RecordTypeId, 
                                                (SELECT id, UNITY_Type__c, UNITY_Vendor_Adjusted_Quantity__c, UNITY_Customer_Adjusted_Quantity__c, UNITY_Cost__c, UNITY_Quantity__c, UNITY_Unit_Price__c, UNITY_Product__c,UNITY_Related_Menu_Price_Line__c,
                                                 UNITY_Product__r.Name, UNITY_Product__r.UNITY_Landed_Cost__c, UNITY_Product__r.UNITY_Product_Type__c, UNITY_Product__r.Broad__c, UNITY_Customer_OT_Multiplier__c,UNITY_MP_Labor_Vendor_Adjusted_Qty__c,UNITY_MP_Labor_Cost__c,
                                                 UNITY_Customer_Holiday_Multiplier__c,UNITY_Vendor_OT_Multiplier__c,UNITY_Vendor_Holiday_Multiplier__c,UNITY_Number_of_Techs__c,UNITY_Is_Vendor_Supply__c,UNITY_Part_On_Hand__c,UNITY_Not_Billable__c,UNITY_Part_Location__c,
                                                 MSPFS_Technician__c,MSPFS_Technician2__c,MSPFS_MSP_Cost__c,MSPFS_MSP_Price__c
                                                 FROM Proposal_Line_Items__r WHERE IsDeleted = FALSE) FROM UNITY_Proposal__c WHERE Id IN :parentIds];

        System.debug('#productPriceMap '+productPriceMap);
        System.debug('#serviceContractLineByTradeMap '+serviceContractLineByTradeMap);

        List<UNITY_Proposal_Line_item__c> proposalItemsToUpdate = new List<UNITY_Proposal_Line_item__c>();

        // *************************************
        // ********* Set menu Pricing data *****
        // *************************************
        Map<Id, Set<Id>> menuPricingProduct = new Map<Id, Set<Id>>();
        Map<Id, Map<Id,UNITY_Proposal_Line_Item__c>> mpLinesMap = new Map<Id, Map<Id,UNITY_Proposal_Line_Item__c>>();
        Map<String, UNITY_Proposal_Line_Item__c> mpLineLaborMap = new Map<String, UNITY_Proposal_Line_Item__c>(); 
        Map<Id, Boolean> appliesMenuPricing = new Map<Id, Boolean>();
        List<UNITY_Proposal_Line_Item__c> toInsert_mpLabor = new List<UNITY_Proposal_Line_Item__c>();
        List<UNITY_Proposal_Line_Item__c> toUpdate_mpLabor = new List<UNITY_Proposal_Line_Item__c>();
        //Izay: Set to hold stock location ids
        Set<Id> stockLocationIds = new Set<Id>();
        for(UNITY_Proposal__c proposalRecord: proposalList){
            appliesMenuPricing.put(proposalRecord.Id, false);
            Boolean useMenuPricing = workOrderMap.get(proposalRecord.UNITY_Work_Order__c).UNITY_Use_Menu_Pricing__c;
            Id customerServiceContractId = workOrderCustomerContractMap.get(proposalRecord.UNITY_Work_Order__c);
            if(menuPricingMap.containsKey(customerServiceContractId)){
                if(useMenuPricing){
                    Boolean hasMPLine = false;
                    for(UNITY_Proposal_Line_item__c proposalItem: proposalRecord.Proposal_Line_Items__r){
                        if(menuPricingMap.get(customerServiceContractId).containsKey(proposalItem.UNITY_Product__c)){
                            hasMPLine = true;
                            if(!menuPricingProduct.containsKey(proposalRecord.Id))
                                menuPricingProduct.put(proposalRecord.Id,new Set<Id>());
                            menuPricingProduct.get(proposalRecord.Id).add(proposalItem.UNITY_Product__c);
                            if(!mpLinesMap.containsKey(proposalRecord.Id))
                                mpLinesMap.put(proposalRecord.Id,new Map<Id,UNITY_Proposal_Line_Item__c>());
                            mpLinesMap.get(proposalRecord.Id).put(proposalItem.Id,proposalItem);
                        }
                        //Collect the menu price labor lines in the mpLineLaborMap
                        if(proposalItem.UNITY_Product__r.UNITY_Product_Type__c == 'Labor' && String.isNotBlank(proposalItem.UNITY_Related_Menu_Price_Line__c)){
                            mpLineLaborMap.put(proposalItem.UNITY_Related_Menu_Price_Line__c,proposalItem);
                        }
                    }
                    //appliesMenuPricing.put(orderRecord.Id, hasMPLine);
                }
                appliesMenuPricing.put(proposalRecord.Id, useMenuPricing);
            }
            for(UNITY_Proposal_Line_item__c proposalItem: proposalRecord.Proposal_Line_Items__r){
                if(proposalItem.UNITY_Product__r.UNITY_Product_Type__c == 'Part'){
                    //If the Part Line has a Stock Location...
                    if(String.isNotBlank(proposalItem.UNITY_Part_Location__c))
                        stockLocationIds.add(proposalItem.UNITY_Part_Location__c);//Add location id to the stockLocationIds set
                }
            }
        }
        System.debug('#####Izay: stockLocationIds = ' + JSON.serializePretty(stockLocationIds));
        System.debug('#####Izay: productIds = ' + JSON.serializePretty(productIds));
        //Izay: Get the location stock for the stock locations and the parts...
        List<FSO__LocationStock__c> myLocationStock = [SELECT Id,FSO__Location__c,UNITY_Landed_Cost__c,FSO__Quantity__c,FSO__Product__c,UNITY_MAC__c,UNITY_Last_Purchase_Order_Unit_Cost__c 
                                                       FROM FSO__LocationStock__c WHERE FSO__Location__c IN :stockLocationIds AND FSO__Product__c IN :productIds];
        System.debug('#####Izay: myLocationStock = ' + JSON.serializePretty(myLocationStock));
        Map<Id,Map<Id,FSO__LocationStock__c>> stockProdMap = new Map<Id,Map<Id,FSO__LocationStock__c>>();
        for(FSO__LocationStock__c lStock :myLocationStock){
            if(!stockProdMap.containsKey(lStock.FSO__Location__c))
                stockProdMap.put(lStock.FSO__Location__c,new Map<Id,FSO__LocationStock__c>());
            if(!stockProdMap.get(lStock.FSO__Location__c).containsKey(lStock.FSO__Product__c))
                stockProdMap.get(lStock.FSO__Location__c).put(lStock.FSO__Product__c,lStock);
        }
        System.debug('#####Izay: stockProdMap = ' + JSON.serializePretty(stockProdMap));
        System.debug('#####Izay: proposalList = ' + JSON.serializePretty(proposalList));
        for(UNITY_Proposal__c proposalRecord: proposalList){
            // Non Work Work Order record type id
            String NWWORTID = UNITY_Constants.WO_NON_WORK_RECORDTYPE;
            Id vendorServiceContractId = workOrderVendorContractMap.get(proposalRecord.UNITY_Work_Order__c);
            Id customerServiceContractId = workOrderCustomerContractMap.get(proposalRecord.UNITY_Work_Order__c);
            Boolean isNonWork = (workOrderMap.get(proposalRecord.UNITY_Work_Order__c).RecordTypeId == NWWORTID) ? true : false;
            System.debug('#####Izay: vendorServiceContractId = ' + JSON.serializePretty(vendorServiceContractId));
            System.debug('#####Izay: customerServiceContractId = ' + JSON.serializePretty(customerServiceContractId));
            System.debug('#####Izay: isNonWork = ' + JSON.serializePretty(isNonWork));
            if((vendorServiceContractId != null && customerServiceContractId != null) || 
               (isNonWork && customerServiceContractId != null)){

                Id trade = proposalRecord.UNITY_Work_Order__r.UNITY_Trade__c;
                String byTradeAndProductPricingRuleKey = trade + '|'+UNITY_Constants.SCLI_PRODUCT_PRICING_RULE_RT;
                String byTradeAndHourlyRateKey = trade + '|'+UNITY_Constants.SCLI_HOURLY_RATE_RT;
                String byTradeAndNTEKey = trade + '|'+UNITY_Constants.SCLI_NTE_RT;

                String broad = workOrderMap.get(proposalRecord.UNITY_Work_Order__c).UNITY_Trade__r.UNITY_Skill_Broad__c;
                String businessUnit = workOrderMap.get(proposalRecord.UNITY_Work_Order__c).UNITY_Business_Unit__c;
                String customerSize = workOrderMap.get(proposalRecord.UNITY_Work_Order__c).UNITY_Customer__r.UNITY_Customer_Size__c;
                String assignedServiceAccountRecordType = (String.isNotBlank(proposalRecord.UNITY_Work_Order__c)) ? proposalRecord.UNITY_Work_Order__r.UNITY_Assigned_Vendor__r.RecordTypeId : '';

                System.debug(LoggingLevel.INFO,'<AK> : customerServiceContractId : '+customerServiceContractId);
                System.debug(LoggingLevel.INFO,'<AK> : serviceContractMap.get(customerServiceContractId) : '+serviceContractMap.get(customerServiceContractId));
                System.debug(LoggingLevel.INFO,'<AK> : serviceContractMap.get(customerServiceContractId) : '+serviceContractMap.get(customerServiceContractId).UNITY_Cost_Plus__c);

                Decimal defaultCostPlusFromSC = 0;
                if(serviceContractMap.get(customerServiceContractId)!=null && serviceContractMap.get(customerServiceContractId).UNITY_Cost_Plus__c != null){
                    defaultCostPlusFromSC = serviceContractMap.get(customerServiceContractId).UNITY_Cost_Plus__c;
                }
                System.debug(LoggingLevel.INFO,'<AK> : defaultCostPlusFromSC : '+defaultCostPlusFromSC);

                Boolean isPassThroughCustomer = false;
                if(serviceContractMap.get(customerServiceContractId)!=null){
                    isPassThroughCustomer = serviceContractMap.get(customerServiceContractId).UNITY_Is_Pass_Through__c;
                }
                System.debug('#####Izay: [quote] isPassThroughCustomer = ' + isPassThroughCustomer);
                //Decimal customerSecondaryTechnicianMultiplier = 0;
                //Decimal vendorSecondaryTechnicianMultiplier = 0;

                Decimal customer2TechMultiplier = 1;
                Decimal customerMultiTechMultiplier = 1;
                Decimal customerApprenticeMultiplier = 1;
                Decimal customerOTLaborMultiplier = 1;
                Decimal customerOTTravelMultiplier = 1;
                Decimal customerHolidayLaborMultiplier = 1;
                Decimal customerHolidayTravelMultiplier = 1;

                Decimal vendor2TechMultiplier = 1;
                Decimal vendorMultiTechMultiplier = 1;
                Decimal vendorApprenticeMultiplier = 1;
                Decimal vendorOTLaborMultiplier = 1;
                Decimal vendorOTTravelMultiplier = 1;
                Decimal vendorHolidayLaborMultiplier = 1;
                Decimal vendorHolidayTravelMultiplier = 1;

                if(serviceContractMap.get(customerServiceContractId).UNITY_2_Technicians__c!=null){
                    customer2TechMultiplier = serviceContractMap.get(customerServiceContractId).UNITY_2_Technicians__c;
                }
                if(serviceContractMap.get(customerServiceContractId).UNITY_Apprentice__c!=null){
                    customerApprenticeMultiplier = serviceContractMap.get(customerServiceContractId).UNITY_Apprentice__c;
                }
                if(serviceContractMap.get(customerServiceContractId).UNITY_Multi_Technician__c!=null){
                    customerMultiTechMultiplier = serviceContractMap.get(customerServiceContractId).UNITY_Multi_Technician__c;
                }
                if(serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Holiday_Multiplier__c != null){
                    customerHolidayLaborMultiplier = serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Holiday_Multiplier__c;
                }else if(serviceContractMap.get(customerServiceContractId).UNITY_Holiday_Multiplier__c!=null){
                    customerHolidayLaborMultiplier = serviceContractMap.get(customerServiceContractId).UNITY_Holiday_Multiplier__c;
                }
                if(serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_OT_Multiplier__c != null){
                    customerOTLaborMultiplier = serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_OT_Multiplier__c;
                }else if(serviceContractMap.get(customerServiceContractId).UNITY_OT_Multiplier__c!=null){
                    customerOTLaborMultiplier = serviceContractMap.get(customerServiceContractId).UNITY_OT_Multiplier__c;
                }
                if(serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Holiday_Travel_Multiplier__c != null){
                    customerHolidayTravelMultiplier = serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Holiday_Travel_Multiplier__c;
                }else if(serviceContractMap.get(customerServiceContractId).UNITY_Holiday_Travel_Multiplier__c!=null){
                    customerHolidayTravelMultiplier = serviceContractMap.get(customerServiceContractId).UNITY_Holiday_Travel_Multiplier__c;
                }
                if(serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_OT_Travel_Multiplier__c != null){
                    customerOTTravelMultiplier = serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_OT_Travel_Multiplier__c;
                }else if(serviceContractMap.get(customerServiceContractId).UNITY_OT_Travel_Multiplier__c!=null){
                    customerOTTravelMultiplier = serviceContractMap.get(customerServiceContractId).UNITY_OT_Travel_Multiplier__c;
                }
                if(vendorServiceContractId != null){
                    if(serviceContractMap.get(vendorServiceContractId).UNITY_2_Technicians__c!=null){
                        vendor2TechMultiplier = serviceContractMap.get(vendorServiceContractId).UNITY_2_Technicians__c;
                    }
                    if(serviceContractMap.get(vendorServiceContractId).UNITY_Apprentice__c!=null){
                        vendorApprenticeMultiplier = serviceContractMap.get(vendorServiceContractId).UNITY_Apprentice__c;
                    }
                    if(serviceContractMap.get(vendorServiceContractId).UNITY_Multi_Technician__c!=null){
                        vendorMultiTechMultiplier = serviceContractMap.get(vendorServiceContractId).UNITY_Multi_Technician__c;
                    }
                    if(serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Holiday_Multiplier__c != null){
                        vendorHolidayLaborMultiplier = serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Holiday_Multiplier__c;
                    }else if(serviceContractMap.get(vendorServiceContractId).UNITY_Holiday_Multiplier__c!=null){
                        vendorHolidayLaborMultiplier = serviceContractMap.get(vendorServiceContractId).UNITY_Holiday_Multiplier__c;
                    }
                    if(serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_OT_Multiplier__c != null){
                        vendorOTLaborMultiplier = serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_OT_Multiplier__c;
                    }else if(serviceContractMap.get(vendorServiceContractId).UNITY_OT_Multiplier__c!=null){
                        vendorOTLaborMultiplier = serviceContractMap.get(vendorServiceContractId).UNITY_OT_Multiplier__c;
                    }
                    if(serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Holiday_Travel_Multiplier__c != null){
                        vendorHolidayTravelMultiplier = serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Holiday_Travel_Multiplier__c;
                    }else if(serviceContractMap.get(vendorServiceContractId).UNITY_Holiday_Travel_Multiplier__c!=null){
                        vendorHolidayTravelMultiplier = serviceContractMap.get(vendorServiceContractId).UNITY_Holiday_Travel_Multiplier__c;
                    }
                    if(serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_OT_Travel_Multiplier__c != null){
                        vendorOTTravelMultiplier = serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_OT_Travel_Multiplier__c;
                    }else if(serviceContractMap.get(vendorServiceContractId).UNITY_OT_Travel_Multiplier__c!=null){
                        vendorOTTravelMultiplier = serviceContractMap.get(vendorServiceContractId).UNITY_OT_Travel_Multiplier__c;
                    }
                }
                    
                Decimal accountBasedMarkup = costPlusFromAccountPricingMatrix.get(broad+'|'+proposalRecord.UNITY_Business_Unit_Account__c+'|'+customerSize);
                if(accountBasedMarkup == null){
                    accountBasedMarkup = 0;
                }
                for(UNITY_Proposal_Line_Item__c proposalItem: proposalRecord.Proposal_Line_Items__r){
                    if(proposalItemIdSet.contains(proposalItem.Id)){
                        
                        Id productId = proposalItem.UNITY_Product__c;
                        String productName = proposalItem.UNITY_Product__r.Name;
                        
                        System.debug('#Izay: productId '+productId);
                        System.debug('#Izay: productName '+productName);
                        System.debug('#Izay: prodcutType '+proposalItem.UNITY_Product__r.UNITY_Product_Type__c);
                        
                        Decimal costByProductFromSCLI = -1;
                        if(vendorServiceContractId != null){
                            if (productPriceMap.get(vendorServiceContractId).get(productId)!=null){
                                costByProductFromSCLI = productPriceMap.get(vendorServiceContractId).get(productId);
                            }
                        }
                        Decimal landedCostFromInventory = 0;
                        String key = productId +'|'+proposalRecord.UNITY_Business_Unit_Account__c;
                        if(productToLocationStockMap.get(key) !=null){
                            landedCostFromInventory = productToLocationStockMap.get(key).UNITY_Landed_Cost__c;
                        }
                        Decimal priceByProductFromSCLI = -1;
                        if(productPriceMap.get(customerServiceContractId).get(productId)!=null){
                            priceByProductFromSCLI = productPriceMap.get(customerServiceContractId).get(productId);
                        }
                        Decimal costPlusByProductFromSCLI = 0;
                        if(vendorServiceContractId != null){
                            if (productCostPlusMap.get(vendorServiceContractId).get(productId)!=null){
                                costPlusByProductFromSCLI = productCostPlusMap.get(vendorServiceContractId).get(productId);
                            }
                        }
                        Decimal costPlusByTradeFromSCLI = 0;
                        if(serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndProductPricingRuleKey) != null && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndProductPricingRuleKey).UNITY_Cost_Plus__c != null){
                            costPlusByTradeFromSCLI = serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndProductPricingRuleKey).UNITY_Cost_Plus__c;
                        }
                        Decimal laborCostByTradeFromSCLI = 0;
                        if(vendorServiceContractId != null){
                            if (serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Labor_Cost__c != null){
                                laborCostByTradeFromSCLI = serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Labor_Cost__c;
                            }
                        }
                        //If Miner Self Perform has a set COST for labor by trade for the Customer, then use the self perform COST on customer's SC instead of COST on self perform (Vendor's) SC.
                        if(assignedServiceAccountRecordType == UNITY_Constants.ACCOUNT_MINER_RECORDTYPE && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Self_Perform_Labor_Cost__c != null) {
                            laborCostByTradeFromSCLI = serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Self_Perform_Labor_Cost__c;
                        }
                        Decimal defaultLaborCostFromSC = 0;
                        if(vendorServiceContractId != null){
                            if(serviceContractMap.get(vendorServiceContractId).UNITY_Default_Labor_Rate__c != null){
                                defaultLaborCostFromSC = serviceContractMap.get(vendorServiceContractId).UNITY_Default_Labor_Rate__c;
                            }
                        }
                        Decimal laborPriceByTradeFromSCLI = 0;
                        if(serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Labor_Cost__c != null){
                            laborPriceByTradeFromSCLI = serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Labor_Cost__c;
                        }
                        
                        Decimal defaultLaborPriceFromSC = 0;
                        if(serviceContractMap.get(customerServiceContractId).UNITY_Default_Labor_Rate__c != null){
                            defaultLaborPriceFromSC = serviceContractMap.get(customerServiceContractId).UNITY_Default_Labor_Rate__c;
                        }
                        
                        Decimal BUBasedMarkup = costPlusByBUAndPart.get(proposalRecord.UNITY_Business_Unit_Account__c+'|'+productId);
                        if(BUBasedMarkup == null){
                            BUBasedMarkup = 0;
                        }
                        
                        Decimal vendorTripCharge;
                        String vendorTripChargeType;
                        if(vendorServiceContractId != null){
                            if (serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Trip_Charge__c != null && serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Trip_Charge_Type__c != null){
                                vendorTripCharge = serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Trip_Charge__c;
                                vendorTripChargeType = serviceContractLineByTradeMap.get(vendorServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Trip_Charge_Type__c;
                            }else{
                                vendorTripCharge = serviceContractMap.get(vendorServiceContractId).UNITY_Trip_Charge__c;
                                vendorTripChargeType = serviceContractMap.get(vendorServiceContractId).UNITY_Trip_Charge_Type__c;
                            }
                        }
                        
                        //If Miner Self Perform has a set COST for Travel by trade for the Customer, then use the self perform COST on customer's SC instead of COST on self perform (Vendor's) SC.
                        if(assignedServiceAccountRecordType == UNITY_Constants.ACCOUNT_MINER_RECORDTYPE && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Self_Perform_Trip_Charge_Type__c != null && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Self_Perform_Trip_Charge_Cost__c != null) {
                            vendorTripCharge = serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Self_Perform_Trip_Charge_Cost__c;
                            vendorTripChargeType = serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Self_Perform_Trip_Charge_Type__c;
                        }
                        
                        Decimal customerTripCharge;
                        String customerTripChargeType;
                        if (serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey) != null && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Trip_Charge__c != null && serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Trip_Charge_Type__c != null){
                            customerTripCharge = serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Trip_Charge__c;
                            customerTripChargeType = serviceContractLineByTradeMap.get(customerServiceContractId).get(byTradeAndHourlyRateKey).UNITY_Trip_Charge_Type__c;
                        }else{
                            customerTripCharge = serviceContractMap.get(customerServiceContractId).UNITY_Trip_Charge__c;
                            customerTripChargeType = serviceContractMap.get(customerServiceContractId).UNITY_Trip_Charge_Type__c;
                        }
                        if(proposalItem.UNITY_Type__c == 'Non Billable'){
                            proposalItem.UNITY_Price__c = 0;
                            proposalItem.UNITY_Cost__c = 0;
                            proposalItem.UNITY_Total_Price__c = 0;
                            proposalItem.UNITY_Total_Cost__c = 0;
                        
                        }
/* **********************************************************************************************************************
 * ******************** QUOTE PART LINE CALCULATE PRICE AND COST ********************************************************
 * ********************************************************************************************************************** */
                        else if(proposalItem.UNITY_Product__r.UNITY_Product_Type__c == 'Part'){
                            //VENDOR: COST CALCULATION FOR PART LINES
                            System.debug('#####Izay: has Part Location = ' + JSON.serializePretty(String.isNotBlank(proposalItem.UNITY_Part_Location__c)));
                            if(String.isNotBlank(proposalItem.UNITY_Part_Location__c)){
                                //Izay:Changed to use stockProdMap
                                System.debug('#####:Izay: has UNITY_Part_Location__c = true');
                                System.debug('#####:Izay: stockProdMap.containsKey(proposalItem.UNITY_Part_Location__c) = ' + stockProdMap.containsKey(proposalItem.UNITY_Part_Location__c));
                                if(stockProdMap.containsKey(proposalItem.UNITY_Part_Location__c)){
                                    System.debug('#####:Izay: stockProdMap.containsKey(proposalItem.UNITY_Part_Location__c) = ' + stockProdMap.containsKey(proposalItem.UNITY_Part_Location__c));
                                    if(stockProdMap.containsKey(proposalItem.UNITY_Part_Location__c)){
                                        if(stockProdMap.get(proposalItem.UNITY_Part_Location__c).containsKey(proposalItem.UNITY_Product__c)){
                                            FSO__LocationStock__c pStock = stockProdMap.get(proposalItem.UNITY_Part_Location__c).get(proposalItem.UNITY_Product__c);
                                            //proposalItem.UNITY_Part_On_Hand__c = ((pStock.FSO__Quantity__c - orderItem.Quantity) >= 0);
                                            //orderItem.UNITY_Location_Available_Quantity__c = pStock.FSO__Quantity__c;
                                            Decimal myCost = (
                                                (pStock.UNITY_Landed_Cost__c != null) ? pStock.UNITY_Landed_Cost__c : 
                                                (pStock.UNITY_MAC__c != null) ? pStock.UNITY_MAC__c : 
                                                (pStock.UNITY_Last_Purchase_Order_Unit_Cost__c != null) ? pStock.UNITY_Last_Purchase_Order_Unit_Cost__c : 0
                                            );
                                            proposalItem.UNITY_Cost__c = myCost;
                                            //proposalItem.UNITY_Cost_Calculation_Details__c += 'Cost from Inventory Location Stock: ' + myCost;
                                        }else{
                                            //proposalItem.UNITY_Part_On_Hand__c = false;
                                        }
                                    }
                                }
                            }
                            if(proposalItem.UNITY_Cost__c == null || proposalItem.UNITY_Cost__c <= 0){
                                if(proposalItem.UNITY_Is_Vendor_Supply__c && costPlusByProductFromSCLI > 0){
                                    proposalItem.UNITY_Cost_Plus__c = costPlusByProductFromSCLI;
                                }
                                else if(proposalItem.UNITY_Is_Vendor_Supply__c && costByProductFromSCLI >= 0){
                                    proposalItem.UNITY_Cost__c = costByProductFromSCLI.setScale(2,System.RoundingMode.HALF_DOWN);
                                }else{
                                    if(!proposalItem.UNITY_Is_Vendor_Supply__c && landedCostFromInventory > 0){
                                        proposalItem.UNITY_Cost__c = landedCostFromInventory.setScale(2,System.RoundingMode.HALF_DOWN);
                                    }
                                }
                                if(proposalItem.UNITY_Cost__c == null){
                                    proposalItem.UNITY_Cost__c = 0; //No Cost found. Agent MUST manually enter it.
                                }
                            }
                            
                            proposalItem.UNITY_Vendor_Adjusted_Quantity__c = proposalItem.UNITY_Quantity__c;
                            proposalItem.UNITY_Total_Cost__c = proposalItem.UNITY_Cost__c * proposalItem.UNITY_Vendor_Adjusted_Quantity__c;
                            
                            System.debug(LoggingLevel.INFO,'<AK> : defaultCostPlusFromSC : '+defaultCostPlusFromSC);
                            //CUSTOMER: PRICE CALCULATION STARTS HERE
                            //CUSTOMER: NOT BILLABLE LINE
                            if(proposalItem.UNITY_Not_Billable__c){
                                proposalItem.UNITY_Price__c = 0;
                                proposalItem.UNITY_Total_Price__c = 0;
                                proposalItem.UNITY_Customer_Adjusted_Quantity__c = 0;
                                proposalItem.UNITY_Sales_Tax__c = 0;
                            //CUSTOMER: MENU PRICING & STANDARD PRICING
                            }else{
                                Boolean standardPrice = true;
                                //CUSTOMER: MENU PRICING
                                System.debug('#####Izay: appliesMenuPricing = ' + appliesMenuPricing.get(proposalRecord.Id));
                                System.debug('#####Izay: menuPricingMap has SC = ' + menuPricingMap.containsKey(customerServiceContractId));
                                System.debug('#####Izay: mpLinesMap has Line = ' + mpLinesMap.containsKey(proposalRecord.Id));
                                if((Trigger.isInsert || Trigger.isUpdate) && appliesMenuPricing.get(proposalRecord.Id) && menuPricingMap.containsKey(customerServiceContractId) && mpLinesMap.containsKey(proposalRecord.Id)){
                                    //If the Part Line is a Menu Price Line
                                    System.debug('#####Izay: menuPricingMap has Product = ' + menuPricingMap.get(customerServiceContractId).containsKey(proposalItem.UNITY_Product__c));
                                    if(menuPricingMap.get(customerServiceContractId).containsKey(proposalItem.UNITY_Product__c)){
                                        standardPrice = false;
                                        proposalItem.UNITY_Price__c = menuPricingMap.get(customerServiceContractId).get(proposalItem.UNITY_Product__c).UNTIY_Material_Cost__c;
                                        proposalItem.UNITY_Quantity__c = (proposalItem.UNITY_Quantity__c != null)?proposalItem.UNITY_Quantity__c:1;
                                        proposalItem.UNITY_Customer_Adjusted_Quantity__c = (proposalItem.UNITY_Quantity__c != null)?proposalItem.UNITY_Quantity__c:1;
                                        String mpkey = proposalItem.Id;
                                        UNITY_Proposal_Line_Item__c mpLabor;
                                        //MENU PRICING: Create or Set Manu Pricing Labor Line
                                        System.debug('#####Izay: mpLineLaborMap has this line Id = ' + mpLineLaborMap.containsKey(mpkey));
                                        if(!mpLineLaborMap.containsKey(mpkey)){
                                            mpLabor = new UNITY_Proposal_Line_Item__c();
                                            mpLabor.UNITY_Proposal__c = proposalRecord.Id;
                                            mpLabor.UNITY_Related_Menu_Price_Line__c = proposalItem.Id;
                                            mpLabor.UNITY_PriceBook_Entry_Id__c = LABOR_PRICEBOOKENTRY_ID;
                                            mpLabor.UNITY_Product__c = LABOR_PRODUCT_ID;
                                            mpLabor.UNITY_Is_Vendor_Supply__c = true;
                                            mpLabor.UNITY_Type__c = 'Vendor Services';
                                            mpLabor.UNITY_Activity_Type__c = 'Vendor Standard Labor';
                                            //mpLabor.UNITY_Price_Calculation_Details__c = '';
                                            toInsert_mpLabor.add(mpLabor);
                                        }else{
                                            mpLabor = mpLineLaborMap.get(mpkey);
                                            //mpLabor.UNITY_Price_Calculation_Details__c = '';
                                            if(!proposalItemIdSet.contains(mpLabor.Id))
                                                toUpdate_mpLabor.add(mpLabor);
                                        }
                                        //MENU PRICING: Labor Line
                                        System.debug('#####Izay: mpLabor = ' + mpLabor);
                                        if(mpLabor != null && !proposalItemIdSet.contains(mpLabor.Id)){
                                            //MENU PRICING: Labor Line Customer Price
                                            mpLabor.UNITY_Price__c = menuPricingMap.get(customerServiceContractId).get(proposalItem.UNITY_Product__c).UNITY_Labor_Cost__c;
                                            //mpLabor.UNITY_Price_Calculation_Details__c += 'Price (Menu Pricing): '+mpLabor.UNITY_Price__c+'\n';
                                            if(mpLabor.UNITY_Quantity__c == null)
                                                mpLabor.UNITY_Quantity__c = (proposalItem.UNITY_MP_Labor_Vendor_Adjusted_Qty__c != null && proposalItem.UNITY_MP_Labor_Vendor_Adjusted_Qty__c != 0) ?
                                                    proposalItem.UNITY_MP_Labor_Vendor_Adjusted_Qty__c : menuPricingMap.get(customerServiceContractId).get(proposalItem.UNITY_Product__c).UNITY_Labor_Hours__c;
                                            mpLabor.UNITY_Customer_Adjusted_Quantity__c = (menuPricingMap.get(customerServiceContractId).get(proposalItem.UNITY_Product__c).UNITY_Labor_Hours__c * proposalItem.UNITY_Customer_Adjusted_Quantity__c);
                                            //mpLabor.UNITY_Price_Calculation_Details__c += 'Customer UNITY_Quantity__c Adjusted (Menu Pricing): '+mpLabor.UNITY_Customer_Adjusted_Quantity__c+'\n';                                            
                                            //mpLabor.UNITY_Price_Calculation_Details__c += 'Menu Price Labor Qty: '+(menuPricingMap.get(customerServiceContractId).get(proposalItem.UNITY_Product__c).UNITY_Labor_Hours__c)+'\n';
                                            //mpLabor.UNITY_Price_Calculation_Details__c += 'Menu Price Line Qty: '+mpLabor.UNITY_Customer_Adjusted_Quantity__c+'\n';
                                            mpLabor.UNITY_Total_Price__c = mpLabor.UNITY_Price__c * proposalItem.UNITY_Customer_Adjusted_Quantity__c;
                                            //mpLabor.UNITY_Price_Calculation_Details__c += 'Total Price (Menu Pricing): '+mpLabor.UNITY_Total_Price__c+'\n';
                                            mpLabor.UNITY_Description__c = proposalItem.UNITY_Product__r.Name+' Labor';
                                            //Need to run vendor cost here...
                                            //MENU PRICING: Labor Line Vendor Cost
                                            //mpLabor.UNITY_Cost_Calculation_Details__c += 'Original Cost: '+mpLabor.UNITY_Cost__c+'\n';
                                            if (mpLabor.UNITY_Cost__c == null || mpLabor.UNITY_Cost__c <= 0){
                                                if(proposalItem.UNITY_MP_Labor_Cost__c != null && proposalItem.UNITY_MP_Labor_Cost__c > 0){
                                                    mpLabor.UNITY_Cost__c = proposalItem.UNITY_MP_Labor_Cost__c;
                                                }
                                                else if (laborCostByTradeFromSCLI > 0){
                                                    //mpLabor.UNITY_Cost_Calculation_Details__c += 'Cost from Service Contract Line Item by Trade: '+laborCostByTradeFromSCLI+'\n';
                                                    mpLabor.UNITY_Cost__c = laborCostByTradeFromSCLI.setScale(2,System.RoundingMode.HALF_DOWN);
                                                }
                                                else if(defaultLaborCostFromSC > 0){
                                                    //mpLabor.UNITY_Cost_Calculation_Details__c += 'Default Cost from Service Contract: '+defaultLaborCostFromSC+'\n';
                                                    mpLabor.UNITY_Cost__c = defaultLaborCostFromSC.setScale(2,System.RoundingMode.HALF_DOWN);
                                                }
                                            }
                                            //MENU PRICING: Set the Vendor Adjusted Quantity
                                            mpLabor.UNITY_Vendor_Adjusted_Quantity__c = mpLabor.UNITY_Quantity__c;
                                            //mpLabor.UNITY_Cost_Calculation_Details__c += 'Vendor UNITY_Quantity__c adjusted (Menu Pricing): '+mpLabor.UNITY_Quantity__c+'\n';
                                            mpLabor.UNITY_Total_Cost__c = mpLabor.UNITY_Cost__c * mpLabor.UNITY_Vendor_Adjusted_Quantity__c;
                                            //MENU PRICING: Set the Vendor Adjusted Qty for Labor on the Menu Price Line
                                            proposalItem.UNITY_MP_Labor_Vendor_Adjusted_Qty__c = mpLabor.UNITY_Vendor_Adjusted_Quantity__c;
                                            proposalItem.UNITY_MP_Labor_Cost__c = mpLabor.UNITY_Cost__c;
                                        }
                                        proposalItem.UNITY_Total_Price__c = proposalItem.UNITY_Price__c * proposalItem.UNITY_Customer_Adjusted_Quantity__c;
                                    }
                                    /*
                                    else if(trigger.isInsert){
                                        proposalItem.UNITY_Price__c = 0;
                                        proposalItem.UNITY_Customer_Adjusted_Quantity__c = proposalItem.UNITY_Quantity__c;
                                        //proposalItem.UNITY_Price_Calculation_Details__c += 'Price (Menu Pricing): '+proposalItem.UNITY_Price__c+'\n';
                                    }else{
                                        proposalItem.UNITY_Price__c = 0;
                                        proposalItem.UNITY_Customer_Adjusted_Quantity__c = proposalItem.UNITY_Quantity__c;
                                        //proposalItem.UNITY_Price_Calculation_Details__c += 'Price (Menu Pricing): '+proposalItem.UNITY_Price__c+'\n';
                                    }
                                    */
                                }
                                //CUSTOMER: STANDARD PRICING
                                if(standardPrice){
                                
                                    if(priceByProductFromSCLI != null && priceByProductFromSCLI >= 0){
                                        proposalItem.UNITY_Price__c = priceByProductFromSCLI;
                                    }else{
                                        proposalItem.UNITY_Price__c = proposalItem.UNITY_Cost__c;
                                        if(costPlusByTradeFromSCLI > 0){
                                            proposalItem.UNITY_Cost_Plus__c = costPlusByTradeFromSCLI;
                                        }else if(defaultCostPlusFromSC > 0){
                                            proposalItem.UNITY_Cost_Plus__c = defaultCostPlusFromSC;
                                        }else{
                                            proposalItem.UNITY_Cost_Plus__c = accountBasedMarkup + BUBasedMarkup;
                                        }
                                    }
                                    
                                    System.debug(LoggingLevel.INFO,'<AK> : proposalItem.UNITY_Cost_Plus__c : '+proposalItem.UNITY_Cost_Plus__c);
                                    
                                    proposalItem.UNITY_Customer_Adjusted_Quantity__c = proposalItem.UNITY_Quantity__c;
                                    
                                    System.debug(LoggingLevel.INFO,'<AK> : proposalItem.UNITY_Customer_Adjusted_Quantity__c : '+proposalItem.UNITY_Customer_Adjusted_Quantity__c);
                                    
                                    if(isPassThroughCustomer && proposalItem.UNITY_Is_Vendor_Supply__c){
                                        proposalItem.UNITY_Price__c = proposalItem.UNITY_Cost__c;
                                        proposalItem.UNITY_Customer_Adjusted_Quantity__c = proposalItem.UNITY_Vendor_Adjusted_Quantity__c;
                                        proposalItem.UNITY_Total_Price__c = proposalItem.UNITY_Total_Cost__c;
                                    }else{
                                        if(proposalItem.UNITY_Cost_Plus__c!=null || proposalItem.UNITY_Cost_Plus__c > 0){
                                            proposalItem.UNITY_Price__c = proposalItem.UNITY_Price__c + (proposalItem.UNITY_Price__c * (proposalItem.UNITY_Cost_Plus__c/100)).setScale(2,System.RoundingMode.HALF_DOWN);
                                        }
                                        
                                        proposalItem.UNITY_Total_Price__c = proposalItem.UNITY_Price__c * proposalItem.UNITY_Customer_Adjusted_Quantity__c;
                                    }
                                }
                            }
                            //System.debug(LoggingLevel.INFO,'<AK> : proposalItem.UNITY_Price__c : '+proposalItem.UNITY_Price__c);
                            //System.debug(LoggingLevel.INFO,'<AK> : proposalItem.UNITY_Total_Price__c : '+proposalItem.UNITY_Total_Price__c);
                        }
/* **********************************************************************************************************************
 * ******************** QUOTE LABOR LINE CALCULATE PRICE AND COST *******************************************************
 * ********************************************************************************************************************** */
                        else if (proposalItem.UNITY_Product__r.UNITY_Product_Type__c == 'Labor'){
                            
                            Decimal vendorLaborMultiplier = 1;
                            Decimal customerLaborMultiplier = 1;
                            
                            Decimal vendorTechMultiplier = 1;
                            Decimal customerTechMultiplier = 1;
                            
                            //VENDOR: COST CALCULATION
                            /*
                            if(trigger.isUpdate && appliesMenuPricing.get(proposalRecord.Id) && menuPricingMap.containsKey(customerServiceContractId)){
                                Decimal tempQty = 0 ; 
                                for(UNITY_Proposal_Line_Item__c qLine :mpLinesMap.get(proposalRecord.Id)){
                                tempQty += menuPricingMap.get(customerServiceContractId).get(qLine.UNITY_Product__c).UNITY_Labor_Hours__c;
                            }
                            proposalItem.UNITY_Vendor_Adjusted_Quantity__c = tempQty;
                            //vendorQuantityToUse = proposalItem.UNITY_Vendor_Adjusted_Quantity__c;
                            //proposalItem.UNITY_Cost_Calculation_Details__c += 'Quantity adjusted (Menu Pricing): '+orderItem.UNITY_Vendor_Adjusted_Quantity__c+'\n';
                            }*/
                            //Izay: Updated to get Labor Cost rate from Tech profile for MSP BU POs
                            Boolean isMspBu = workOrderMap.containsKey(proposalRecord.UNITY_Work_Order__c)?workOrderMap.get(proposalRecord.UNITY_Work_Order__c).UNITY_Business_Unit_Account__r.MSPFS_Is_MSP_BU__c:false;
                            if(isMspBu){
                                Decimal rate = 0;
                                if(String.isNotBlank(proposalItem.MSPFS_Technician__c)){
                                    if(techsMap.containsKey(proposalItem.MSPFS_Technician__c)){
                                        Decimal tech1Rate = techsMap.get(proposalItem.MSPFS_Technician__c).MSPFS_Burden_Rate__c != null ?
                                            techsMap.get(proposalItem.MSPFS_Technician__c).MSPFS_Burden_Rate__c : 0;
                                        rate += tech1Rate;
                                    }
                                }
                                if(String.isNotBlank(proposalItem.MSPFS_Technician2__c)){
                                    if(techsMap.containsKey(proposalItem.MSPFS_Technician2__c)){
                                        Decimal tech2Rate = techsMap.get(proposalItem.MSPFS_Technician2__c).MSPFS_Burden_Rate__c != null ?
                                            techsMap.get(proposalItem.MSPFS_Technician2__c).MSPFS_Burden_Rate__c : 0;
                                        rate += tech2Rate;
                                    }
                                }
                                //proposalItem.UNITY_Cost_Calculation_Details__c += 'Cost from Technician(s) Burden Rate: '+rate+'\n';
                                proposalItem.UNITY_Cost__c = rate.setScale(2,System.RoundingMode.HALF_DOWN);
                                proposalItem.UNITY_Vendor_Adjusted_Quantity__c = proposalItem.UNITY_Quantity__c;
                            }else
                            if (proposalItem.UNITY_Cost__c == null || proposalItem.UNITY_Cost__c <= 0){
                                if (laborCostByTradeFromSCLI > 0){
                                    proposalItem.UNITY_Cost__c = laborCostByTradeFromSCLI.setScale(2,System.RoundingMode.HALF_DOWN);
                                }
                                else if(defaultLaborCostFromSC > 0){
                                    proposalItem.UNITY_Cost__c = defaultLaborCostFromSC.setScale(2,System.RoundingMode.HALF_DOWN);
                                }
                            }
                            
                            if (proposalItem.UNITY_Vendor_OT_Multiplier__c){
                                //proposalItem.UNITY_Cost_Calculation_Details__c += 'Vendor OT Labor Multiplier Applied : '+vendorOTLaborMultiplier+'\n';
                                vendorLaborMultiplier = vendorOTLaborMultiplier;
                            }else if(proposalItem.UNITY_Vendor_Holiday_Multiplier__c){
                                //orderItem.UNITY_Cost_Calculation_Details__c += 'Vendor Holiday Labor Multiplier Applied : '+vendorHolidayLaborMultiplier+'\n';
                                vendorLaborMultiplier = vendorHolidayLaborMultiplier;
                            }
                            
                            if (proposalItem.UNITY_Number_of_Techs__c == '2 Technicians'){
                                //proposalItem.UNITY_Cost_Calculation_Details__c += 'Vendor 2 Tech Multiplier Applied : '+vendor2TechMultiplier+'\n';
                                vendorTechMultiplier = vendor2TechMultiplier;
                            }else if (proposalItem.UNITY_Number_of_Techs__c == 'Multi-Tech'){
                                //proposalItem.UNITY_Cost_Calculation_Details__c += 'Vendor Multi-Tech Multiplier Applied : '+vendorMultiTechMultiplier+'\n';
                                vendorTechMultiplier = vendorMultiTechMultiplier;
                            }else if (proposalItem.UNITY_Number_of_Techs__c == '1 Technician + Apprentice'){
                                //proposalItem.UNITY_Cost_Calculation_Details__c += 'Vendor 1 Technician + Apprentice Multiplier Applied : '+vendorApprenticeMultiplier+'\n';
                                vendorTechMultiplier = vendorApprenticeMultiplier;
                            }
                            
                            proposalItem.UNITY_Total_Cost__c = ((proposalItem.UNITY_Cost__c!=null)?proposalItem.UNITY_Cost__c:0) * ((vendorLaborMultiplier!=null)?vendorLaborMultiplier:1) * ((vendorTechMultiplier!=null)?vendorTechMultiplier:1) * ((proposalItem.UNITY_Vendor_Adjusted_Quantity__c!=null)?proposalItem.UNITY_Vendor_Adjusted_Quantity__c:0);
                            
                            // CUSTOMER PRICE CALCULATION
                            
                            if(proposalItem.UNITY_Not_Billable__c){
                                proposalItem.UNITY_Price__c = 0;
                                proposalItem.UNITY_Total_Price__c = 0;
                                proposalItem.UNITY_Customer_Adjusted_Quantity__c = 0;
                                proposalItem.UNITY_Sales_Tax__c = 0;
                            }
                            //MENU PRICING: The labor hours come from the menu pricing record if it exists
                            else if(trigger.isUpdate && appliesMenuPricing.get(proposalRecord.Id) && menuPricingMap.containsKey(customerServiceContractId) && mpLinesMap.containsKey(proposalRecord.Id)){
                                
                                if(mpLinesMap.get(proposalRecord.Id).containsKey(proposalItem.UNITY_Related_Menu_Price_Line__c) && !proposalItemIdSet.contains(proposalItem.UNITY_Related_Menu_Price_Line__c)){
                                    System.debug('#####Izay: mpLinesMap.containsKey: true');
                                    UNITY_Proposal_Line_Item__c mpLine = mpLinesMap.get(proposalRecord.Id).get(proposalItem.UNITY_Related_Menu_Price_Line__c);
                                    proposalItem.UNITY_Price__c = menuPricingMap.get(customerServiceContractId).get(mpLine.UNITY_Product__c).UNITY_Labor_Cost__c;
                                    //proposalItem.UNITY_Price_Calculation_Details__c += 'Price (Menu Pricing): '+proposalItem.UNITY_Price__c+'\n';
                                    //proposalItem.UNITY_Quantity__c = menuPricingMap.get(customerServiceContractId).get(mpLine.UNITY_Product__c).UNITY_Labor_Hours__c;
                                    proposalItem.UNITY_Customer_Adjusted_Quantity__c = (menuPricingMap.get(customerServiceContractId).get(mpLine.UNITY_Product__c).UNITY_Labor_Hours__c * mpLine.UNITY_Customer_Adjusted_Quantity__c);
                                    //proposalItem.UNITY_Price_Calculation_Details__c += 'Customer Quantity Adjusted (Menu Pricing): '+proposalItem.UNITY_Customer_Adjusted_Quantity__c+'\n';
                                    //proposalItem.UNITY_Price_Calculation_Details__c += 'Menu Price Labor Qty: '+(menuPricingMap.get(customerServiceContractId).get(mpLine.UNITY_Product__c).UNITY_Labor_Hours__c)+'\n';
                                    //proposalItem.UNITY_Price_Calculation_Details__c += 'Menu Price Line Qty: '+mpLine.UNITY_Customer_Adjusted_Quantity__c+'\n';
                                    proposalItem.UNITY_Total_Price__c = proposalItem.UNITY_Price__c * proposalItem.UNITY_Customer_Adjusted_Quantity__c;
                                    //proposalItem.UNITY_Price_Calculation_Details__c += 'Total Price (Menu Pricing): '+proposalItem.UNITY_Total_Price__c+'\n';
                                    proposalItem.UNITY_Description__c = mpLine.UNITY_Product__r.Name+' Labor';
                                    //Set the MP Labor Vendor Adjysted Qty and Cost on Menu Price Line
                                    mpLine.UNITY_MP_Labor_Vendor_Adjusted_Qty__c = proposalItem.UNITY_Vendor_Adjusted_Quantity__c;
                                    mpLine.UNITY_MP_Labor_Cost__c = proposalItem.UNITY_Cost__c;
                                    toUpdate_mpLabor.add(mpLine);
                                }

                            }else{
                                if (laborPriceByTradeFromSCLI > 0){
                                    proposalItem.UNITY_Price__c = laborPriceByTradeFromSCLI;
                                }
                                else if(defaultLaborPriceFromSC > 0){
                                    proposalItem.UNITY_Price__c = defaultLaborPriceFromSC;
                                }
                                else{
                                    proposalItem.UNITY_Price__c = proposalItem.UNITY_Cost__c;
                                    
                                    if (costPlusByTradeFromSCLI > 0){
                                        proposalItem.UNITY_Cost_Plus__c = costPlusByTradeFromSCLI;
                                    } else {
                                        proposalItem.UNITY_Cost_Plus__c = accountBasedMarkup + BUBasedMarkup;
                                    }
                                }
                                proposalItem.UNITY_Customer_Adjusted_Quantity__c = roundLaborHours(proposalItem.UNITY_Quantity__c, serviceContractMap.get(customerServiceContractId).UNITY_Invoicing_Increments__c, serviceContractMap.get(customerServiceContractId).UNITY_Minimum_Labor_Hours__c);
                                
                                if (proposalItem.UNITY_Customer_OT_Multiplier__c){
                                    //proposalItem.UNITY_Price_Calculation_Details__c += 'Customer OT Labor Multiplier Applied : '+customerOTLaborMultiplier+'\n';
                                    customerLaborMultiplier = customerOTLaborMultiplier;
                                }else if(proposalItem.UNITY_Customer_Holiday_Multiplier__c){
                                    //proposalItem.UNITY_Price_Calculation_Details__c += 'Customer Holiday Labor Multiplier Applied : '+customerHolidayLaborMultiplier+'\n';
                                    customerLaborMultiplier = customerHolidayLaborMultiplier;
                                }
                                if (proposalItem.UNITY_Number_of_Techs__c == '2 Technicians'){
                                    //proposalItem.UNITY_Price_Calculation_Details__c += 'Customer 2 Tech Multiplier Applied : '+customer2TechMultiplier+'\n';
                                    customerTechMultiplier = customer2TechMultiplier;
                                }else if (proposalItem.UNITY_Number_of_Techs__c == 'Multi-Tech'){
                                    //proposalItem.UNITY_Price_Calculation_Details__c += 'Customer Multi-Tech Multiplier Applied : '+customerMultiTechMultiplier+'\n';
                                    customerTechMultiplier = customerMultiTechMultiplier;
                                }else if (proposalItem.UNITY_Number_of_Techs__c == '1 Technician + Apprentice'){
                                    //proposalItem.UNITY_Price_Calculation_Details__c += 'Customer 1 Technician + Apprentice Multiplier Applied : '+customerApprenticeMultiplier+'\n';
                                    customerTechMultiplier = customerApprenticeMultiplier;
                                }
                                if(isPassThroughCustomer && proposalItem.UNITY_Is_Vendor_Supply__c){
                                    proposalItem.UNITY_Price__c = proposalItem.UNITY_Cost__c;
                                    proposalItem.UNITY_Total_Price__c = proposalItem.UNITY_Total_Cost__c;
                                    proposalItem.UNITY_Customer_Adjusted_Quantity__c = proposalItem.UNITY_Vendor_Adjusted_Quantity__c;
                                }else{
                                    if(proposalItem.UNITY_Cost_Plus__c!=null || proposalItem.UNITY_Cost_Plus__c > 0){
                                        proposalItem.UNITY_Price__c = proposalItem.UNITY_Price__c + (proposalItem.UNITY_Price__c * (proposalItem.UNITY_Cost_Plus__c/100)).setScale(2,System.RoundingMode.HALF_DOWN);
                                    }
                                    //else{
                                    //    proposalItem.UNITY_Price__c = proposalItem.UNITY_Cost__c;
                                    //}
                                    
                                    
                                    proposalItem.UNITY_Total_Price__c = proposalItem.UNITY_Price__c * customerLaborMultiplier * customerTechMultiplier * proposalItem.UNITY_Customer_Adjusted_Quantity__c;
                                }
                            }
                            //proposalItem.UNITY_Price__c = proposalItem.UNITY_Price__c * customerLaborMultiplier * customerTechMultiplier;
                        }
/* **********************************************************************************************************************
 * ******************** QUOTE TRAVEL LINE CALCULATE PRICE AND COST ******************************************************
 * ********************************************************************************************************************** */
                        else if (proposalItem.UNITY_Product__r.UNITY_Product_Type__c == 'Travel'){
                            
                            System.debug(LoggingLevel.INFO,'<AK> : proposalItem.UNITY_Product__r.UNITY_Product_Type__c : '+proposalItem.UNITY_Product__r.UNITY_Product_Type__c);
                            
                            Decimal vendorTravelMultiplier = 1;
                            Decimal customerTravelMultiplier = 1;
                            Decimal vendorTechMultiplier = 1;
                            Decimal customerTechMultiplier = 1;
                            
                            // VENDOR COST CALCULATION
                            System.debug(LoggingLevel.INFO,'<AK> : proposalItem.UNITY_Cost__c : '+proposalItem.UNITY_Cost__c);
                            System.debug(LoggingLevel.INFO,'<AK> : vendorTripCharge : '+vendorTripCharge);
                            System.debug(LoggingLevel.INFO,'<AK> : vendorTripChargeType : '+vendorTripChargeType);
                            System.debug(LoggingLevel.INFO,'<AK> : proposalItem.UNITY_Quantity__c : '+proposalItem.UNITY_Quantity__c);
                            System.debug(LoggingLevel.INFO,'<AK> : proposalItem.UNITY_Cost__c : '+proposalItem.UNITY_Cost__c);
                            //Izay: Updated to get Labor Cost rate from Tech profile for MSP BU POs
                            Boolean isMspBu = workOrderMap.containsKey(proposalRecord.UNITY_Work_Order__c)?workOrderMap.get(proposalRecord.UNITY_Work_Order__c).UNITY_Business_Unit_Account__r.MSPFS_Is_MSP_BU__c:false;
                            if(isMspBu){
                                Decimal rate = 0;
                                if(String.isNotBlank(proposalItem.MSPFS_Technician__c)){
                                    if(techsMap.containsKey(proposalItem.MSPFS_Technician__c)){
                                        Decimal tech1Rate = techsMap.get(proposalItem.MSPFS_Technician__c).MSPFS_Burden_Rate__c != null ?
                                            techsMap.get(proposalItem.MSPFS_Technician__c).MSPFS_Burden_Rate__c : 0;
                                        rate += tech1Rate;
                                    }
                                }
                                if(String.isNotBlank(proposalItem.MSPFS_Technician2__c)){
                                    if(techsMap.containsKey(proposalItem.MSPFS_Technician2__c)){
                                        Decimal tech2Rate = techsMap.get(proposalItem.MSPFS_Technician2__c).MSPFS_Burden_Rate__c != null ?
                                            techsMap.get(proposalItem.MSPFS_Technician2__c).MSPFS_Burden_Rate__c : 0;
                                        rate += tech2Rate;
                                    }
                                }
                                //proposalItem.UNITY_Cost_Calculation_Details__c += 'Cost from Technician(s) Burden Rate: '+rate+'\n';
                                proposalItem.UNITY_Cost__c = rate.setScale(2,System.RoundingMode.HALF_DOWN);
                                proposalItem.UNITY_Vendor_Adjusted_Quantity__c = proposalItem.UNITY_Quantity__c;
                            }else
                            if (proposalItem.UNITY_Cost__c == null || proposalItem.UNITY_Cost__c <= 0){
                                System.debug(LoggingLevel.INFO,'<AK> : inside Cost!=null : '+proposalItem.UNITY_Cost__c);
                                if(vendorTripCharge != null && vendorTripChargeType!= null){
                                    System.debug(LoggingLevel.INFO,'<AK> : vendorTripCharge!=null : '+vendorTripCharge);
                                    System.debug(LoggingLevel.INFO,'<AK> : vendorTripChargeType!=null : '+vendorTripChargeType);
                                    
                                    if (vendorTripChargeType == 'Flat Fee'){
                                        proposalItem.UNITY_Cost__c = vendorTripCharge.setScale(2,System.RoundingMode.HALF_DOWN);
                                        proposalItem.UNITY_Vendor_Adjusted_Quantity__c = 1;
                                    }
                                    else if (vendorTripChargeType == 'Hourly Rate'){
                                        proposalItem.UNITY_Cost__c = vendorTripCharge.setScale(2,System.RoundingMode.HALF_DOWN);
                                        proposalItem.UNITY_Vendor_Adjusted_Quantity__c = proposalItem.UNITY_Quantity__c;
                                        System.debug(LoggingLevel.INFO,'<AK> : proposalItem.UNITY_Vendor_Adjusted_Quantity__c : '+proposalItem.UNITY_Vendor_Adjusted_Quantity__c);
                                    }
                                }
                            }else{
                                if(vendorTripCharge != null && vendorTripChargeType!= null){
                                    if (vendorTripChargeType == 'Hourly Rate'){
                                        proposalItem.UNITY_Vendor_Adjusted_Quantity__c = proposalItem.UNITY_Quantity__c;
                                    }else if (vendorTripChargeType == 'Flat Fee'){
                                        proposalItem.UNITY_Vendor_Adjusted_Quantity__c = 1;
                                    }
                                }
                            }
                            System.debug(LoggingLevel.INFO,'<AK> : proposalItem.UNITY_Cost__c : '+proposalItem.UNITY_Cost__c);
                            System.debug(LoggingLevel.INFO,'<AK> : proposalItem.UNITY_Vendor_Adjusted_Quantity__c : '+proposalItem.UNITY_Vendor_Adjusted_Quantity__c);
                            if(vendorTripChargeType != 'Flat Fee'){
                                if (proposalItem.UNITY_Vendor_OT_Multiplier__c){
                                    //proposalItem.UNITY_Cost_Calculation_Details__c += 'Vendor OT Travel Multiplier Applied : '+vendorOTTravelMultiplier+'\n';
                                    vendorTravelMultiplier = vendorOTTravelMultiplier;
                                }else if(proposalItem.UNITY_Vendor_Holiday_Multiplier__c){
                                    //proposalItem.UNITY_Cost_Calculation_Details__c += 'Vendor Holiday Travel Multiplier Applied : '+vendorHolidayTravelMultiplier+'\n';
                                    vendorTravelMultiplier = vendorHolidayTravelMultiplier;
                                }
                                if (proposalItem.UNITY_Number_of_Techs__c == '2 Technicians'){
                                    //proposalItem.UNITY_Cost_Calculation_Details__c += 'Vendor 2 Tech Multiplier Applied : '+vendor2TechMultiplier+'\n';
                                    vendorTechMultiplier = vendor2TechMultiplier;
                                }else if (proposalItem.UNITY_Number_of_Techs__c == 'Multi-Tech'){
                                    //proposalItem.UNITY_Cost_Calculation_Details__c += 'Vendor Multi-Tech Multiplier Applied : '+vendorMultiTechMultiplier+'\n';
                                    vendorTechMultiplier = vendorMultiTechMultiplier;
                                }else if (proposalItem.UNITY_Number_of_Techs__c == '1 Technician + Apprentice'){
                                    //proposalItem.UNITY_Cost_Calculation_Details__c += 'Vendor 1 Technician + Apprentice Multiplier Applied : '+vendorApprenticeMultiplier+'\n';
                                    vendorTechMultiplier = vendorApprenticeMultiplier;
                                }
                            }
                                
                            //proposalItem.UNITY_Cost__c = proposalItem.UNITY_Cost__c * vendorTravelMultiplier * vendorTechMultiplier;
                            System.debug('#proposalItem '+proposalItem);
                            
                            proposalItem.UNITY_Total_Cost__c = proposalItem.UNITY_Cost__c * vendorTravelMultiplier * vendorTechMultiplier * proposalItem.UNITY_Vendor_Adjusted_Quantity__c;
                            
                            // CUSTOMER PRICE CALCULATION
                            if(proposalItem.UNITY_Not_Billable__c){
                                proposalItem.UNITY_Price__c = 0;
                                proposalItem.UNITY_Total_Price__c = 0;
                                proposalItem.UNITY_Customer_Adjusted_Quantity__c = 0;
                                proposalItem.UNITY_Sales_Tax__c = 0;
                            }else if(customerTripCharge != null && customerTripChargeType!= null){
                                if (customerTripChargeType == 'Flat Fee'){
                                    proposalItem.UNITY_Price__c = customerTripCharge;
                                    proposalItem.UNITY_Customer_Adjusted_Quantity__c = 1;
                                }
                                else if (customerTripChargeType == 'Hourly Rate'){
                                    proposalItem.UNITY_Price__c = customerTripCharge;
                                    proposalItem.UNITY_Customer_Adjusted_Quantity__c = proposalItem.UNITY_Quantity__c;
                                }
                            }else{
                                proposalItem.UNITY_Price__c = proposalItem.UNITY_Cost__c;
                                
                                if (costPlusByTradeFromSCLI > 0){
                                    proposalItem.UNITY_Cost_Plus__c = costPlusByTradeFromSCLI;
                                } else {
                                    proposalItem.UNITY_Cost_Plus__c = accountBasedMarkup + BUBasedMarkup;
                                }
                            }
                            System.debug(LoggingLevel.INFO,'<AK> : proposalItem.UNITY_Customer_Adjusted_Quantity__c : '+proposalItem.UNITY_Customer_Adjusted_Quantity__c);
                            System.debug(LoggingLevel.INFO,'<AK> : proposalItem.UNITY_Price__c : '+proposalItem.UNITY_Price__c);
                            System.debug(LoggingLevel.INFO,'<AK> : proposalItem.UNITY_Cost_Plus__c : '+proposalItem.UNITY_Cost_Plus__c);
                            if (customerTripChargeType != 'Flat Fee'){
                                if (proposalItem.UNITY_Customer_OT_Multiplier__c){
                                    //proposalItem.UNITY_Price_Calculation_Details__c += 'Customer OT Travel Multiplier Applied : '+customerOTTravelMultiplier+'\n';
                                    customerTravelMultiplier = customerOTTravelMultiplier;
                                }else if(proposalItem.UNITY_Customer_Holiday_Multiplier__c){
                                    //proposalItem.UNITY_Price_Calculation_Details__c += 'Customer Holiday Travel Multiplier Applied : '+customerHolidayTravelMultiplier+'\n';
                                    customerTravelMultiplier = customerHolidayTravelMultiplier;
                                }
                                if (proposalItem.UNITY_Number_of_Techs__c == '2 Technicians'){
                                    //proposalItem.UNITY_Price_Calculation_Details__c += 'Customer 2 Tech Multiplier Applied : '+customer2TechMultiplier+'\n';
                                    customerTechMultiplier = customer2TechMultiplier;
                                }else if (proposalItem.UNITY_Number_of_Techs__c == 'Multi-Tech'){
                                    //proposalItem.UNITY_Price_Calculation_Details__c += 'Customer Multi-Tech Multiplier Applied : '+customerMultiTechMultiplier+'\n';
                                    customerTechMultiplier = customerMultiTechMultiplier;
                                }else if (proposalItem.UNITY_Number_of_Techs__c == '1 Technician + Apprentice'){
                                    //proposalItem.UNITY_Price_Calculation_Details__c += 'Customer 1 Technician + Apprentice Multiplier Applied : '+customerApprenticeMultiplier+'\n';
                                    customerTechMultiplier = customerApprenticeMultiplier;
                                }
                            }
                                
                            if(isPassThroughCustomer && proposalItem.UNITY_Is_Vendor_Supply__c){
                                proposalItem.UNITY_Price__c = proposalItem.UNITY_Cost__c;
                                proposalItem.UNITY_Total_Price__c = proposalItem.UNITY_Total_Cost__c;
                                proposalItem.UNITY_Customer_Adjusted_Quantity__c = proposalItem.UNITY_Vendor_Adjusted_Quantity__c;
                            }else{
                                if(proposalItem.UNITY_Cost_Plus__c!=null || proposalItem.UNITY_Cost_Plus__c > 0){
                                    proposalItem.UNITY_Price__c = proposalItem.UNITY_Price__c + (proposalItem.UNITY_Price__c * (proposalItem.UNITY_Cost_Plus__c/100)).setScale(2,System.RoundingMode.HALF_DOWN);
                                }
                                
                                //proposalItem.UNITY_Price__c = proposalItem.UNITY_Price__c * customerTravelMultiplier * customerTechMultiplier;
                                proposalItem.UNITY_Total_Price__c = proposalItem.UNITY_Price__c * customerTravelMultiplier * customerTechMultiplier * proposalItem.UNITY_Customer_Adjusted_Quantity__c;
                            }
                            System.debug(LoggingLevel.INFO,'<AK> : proposalItem.UNITY_Price__c : '+proposalItem.UNITY_Price__c);
                            System.debug(LoggingLevel.INFO,'<AK> : customerTravelMultiplier : '+customerTravelMultiplier);
                            System.debug(LoggingLevel.INFO,'<AK> : customerTechMultiplier : '+customerTechMultiplier);
                            //proposalItem.UNITY_Price__c = proposalItem.UNITY_Price__c * customerTravelMultiplier * customerTechMultiplier;
                            System.debug(LoggingLevel.INFO,'<AK> : proposalItem.UNITY_Total_Price__c : '+proposalItem.UNITY_Total_Price__c);
                        }
                        else{
                            // VENDOR COST CALCULATION
                            if (proposalItem.UNITY_Cost__c == null || proposalItem.UNITY_Cost__c <= 0){
                                
                                if (costByProductFromSCLI > 0){
                                    proposalItem.UNITY_Cost__c = costByProductFromSCLI.setScale(2,System.RoundingMode.HALF_DOWN);
                                }
                                if (proposalItem.UNITY_Cost__c == null){
                                    proposalItem.UNITY_Cost__c = 0; //No Cost found. Agent MUST manually enter it.
                                }
                            }
                            proposalItem.UNITY_Vendor_Adjusted_Quantity__c = proposalItem.UNITY_Quantity__c;
                            proposalItem.UNITY_Total_Cost__c = proposalItem.UNITY_Cost__c * proposalItem.UNITY_Vendor_Adjusted_Quantity__c;
                            
                            // CUSTOMER PRICE CALCULATION
                            if(proposalItem.UNITY_Not_Billable__c){
                                proposalItem.UNITY_Price__c = 0;
                                proposalItem.UNITY_Total_Price__c = 0;
                                proposalItem.UNITY_Customer_Adjusted_Quantity__c = 0;
                                proposalItem.UNITY_Sales_Tax__c = 0;
                            }else if ( priceByProductFromSCLI != null && priceByProductFromSCLI > 0){
                                proposalItem.UNITY_Price__c = priceByProductFromSCLI;
                            }else{
                                proposalItem.UNITY_Price__c = proposalItem.UNITY_Cost__c;
                                if (costPlusByTradeFromSCLI > 0){
                                    proposalItem.UNITY_Cost_Plus__c = costPlusByTradeFromSCLI;
                                } else if (defaultCostPlusFromSC > 0){
                                    proposalItem.UNITY_Cost_Plus__c = defaultCostPlusFromSC;
                                } else {
                                    proposalItem.UNITY_Cost_Plus__c = accountBasedMarkup + BUBasedMarkup;
                                }
                            }
                            proposalItem.UNITY_Customer_Adjusted_Quantity__c = proposalItem.UNITY_Quantity__c;
                            
                            if(isPassThroughCustomer && proposalItem.UNITY_Is_Vendor_Supply__c){
                                proposalItem.UNITY_Price__c = proposalItem.UNITY_Cost__c;
                                proposalItem.UNITY_Total_Price__c = proposalItem.UNITY_Total_Cost__c;
                                proposalItem.UNITY_Customer_Adjusted_Quantity__c = proposalItem.UNITY_Vendor_Adjusted_Quantity__c;
                            }else{
                                if(proposalItem.UNITY_Cost_Plus__c!=null || proposalItem.UNITY_Cost_Plus__c > 0){
                                    proposalItem.UNITY_Price__c = proposalItem.UNITY_Price__c + (proposalItem.UNITY_Price__c * (proposalItem.UNITY_Cost_Plus__c/100)).setScale(2,System.RoundingMode.HALF_DOWN);
                                }
                                //else{
                                //    proposalItem.UNITY_Price__c = proposalItem.UNITY_Cost__c;
                                //}
                                proposalItem.UNITY_Total_Price__c = proposalItem.UNITY_Price__c * proposalItem.UNITY_Customer_Adjusted_Quantity__c;
                            }
                        }
                        proposalItemsToUpdate.add(proposalItem);
                    }
                }
            }
        }
        if(!toInsert_mpLabor.isEmpty()){
            insert toInsert_mpLabor;
        }
        if(!toUpdate_mpLabor.isEmpty()){
            proposalItemsToUpdate.addAll(toUpdate_mpLabor);
        }
        update proposalItemsToUpdate;
        /* *****************************************************************************
         * Izay: Added this check to prevent calling the @future method multiple times *
         ***************************************************************************** */
        //if(!UNITY_Constants.isExecutingContext('UNITY_PriceCalculation.callAvataxForProposal') && 
           //!UNITY_Constants.isExecutingContext('UNITY_CallAvatax.setTaxQuote'))
            //callAvataxForProposal(new List<Id>(new Map<Id, UNITY_Proposal_Line_Item__c>(proposalItemsToUpdate).keySet()));
    }

    @Future(callout=true)
    public static void callAvataxForProposal(List<Id> proposalIdList){

        if(!proposalIdList.isEmpty()){
            UNITY_CallAvatax.AvataxResult taxResult = UNITY_CallAvatax.getTaxQuote(proposalIdList,'lines');
            System.debug('#taxResult ' + taxResult);
        }
    }

    public static Decimal roundLaborHours(Decimal hours, String incrementType, Decimal minimumLaborHours){

        Decimal result = hours;

        if (incrementType == 'Next ½ hr'){

            result = (result * 2).round(System.RoundingMode.CEILING) / 2.0;

        }
        else if (incrementType == 'Next ¼ hr'){

            result = (result * 4).round(System.RoundingMode.CEILING) / 4.0;
        }

        //incrementType = IVR in WO trigger

        if (result < minimumLaborHours){
            result = minimumLaborHours;
        }

        return result;

    }


    @future
    public static void recalculateWorkOrderPricingFields(List<Id> orderIdList){
        UNITY_Constants.isExecutingContext('recalculateWorkOrderPricingFields');
        List<Order> orderList = [select id, FSO__WorkOrder__c from Order where id in:orderIdList];

        recalculateWorkOrderPricingFieldsFuture(orderList);
    }

    public static void recalculateWorkOrderPricingFieldsFuture(List<Order> orderList){

        System.debug('#orderList '+orderList);

        Set<Id> workOrderIdSet = new Set<Id>();

        for (Order iter: orderList){

            workOrderIdSet.add(iter.FSO__WorkOrder__c);
        }

        UNITY_General_Settings__c generalSetting = generalSettings.get(UNITY_Constants.PO_INVOICEABLE_STATUSES);

        String POInvoiceableStatuses;
        Set<String> delimitedInvoiceableStatuses = new Set<String>();

        if (generalSetting!=null){
            POInvoiceableStatuses = generalSetting.UNITY_Value__c;
        }

        if (POInvoiceableStatuses!=null){
            delimitedInvoiceableStatuses = new Set<String>(POInvoiceableStatuses.split(UNITY_Constants.PO_INVOICEABLE_STATUSES_DELIMITER));
        }

        List<WorkOrder> workOrderList = [SELECT Id, CaseId, UNITY_Work_Order_Total__c, UNITY_Total_Cost__c, UNITY_Sales_Tax__c, UNITY_Work_Order_Margin__c, 
                                         (SELECT Id, UNITY_Total_Cost__c,  UNITY_Total_Amount__c, UNITY_Sales_Tax__c FROM FSO__Orders__r WHERE Status IN: delimitedInvoiceableStatuses 
                                         AND (RecordTypeId = :UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE OR RecordTypeId = :UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE
                                            OR RecordTypeId = :UNITY_Constants.ADJUSTMENT_PURCHASE_ORDER_RECORDTYPE)) 
                                         FROM WorkOrder WHERE Id IN:workOrderIdSet];

        System.debug('#workOrderList '+workOrderList);

        List<WorkOrder> workOrderToUpdate = new List<WorkOrder>();

        for (WorkOrder iter: workOrderList){

            iter.UNITY_Work_Order_Total__c = 0;
            iter.UNITY_Total_Cost__c = 0;
            iter.UNITY_Sales_Tax__c = 0;

            for (Order o: iter.FSO__Orders__r){

                if (o.UNITY_Total_Amount__c != null){
                    iter.UNITY_Work_Order_Total__c += o.UNITY_Total_Amount__c;
                }
                if (o.UNITY_Total_Cost__c != null){
                    iter.UNITY_Total_Cost__c += o.UNITY_Total_Cost__c;
                }
                if (o.UNITY_Sales_Tax__c != null){
                    iter.UNITY_Sales_Tax__c += o.UNITY_Sales_Tax__c;
                }

                //iter.UNITY_Work_Order_Margin__c = iter.UNITY_Work_Order_Total__c + iter.UNITY_Sales_Tax__c - iter.UNITY_Total_Cost__c;

            }
            iter.UNITY_Work_Order_Margin__c = iter.UNITY_Work_Order_Total__c - iter.UNITY_Total_Cost__c;

            workOrderToUpdate.add(iter);
        }

        System.debug('#workOrderToUpdate '+workOrderToUpdate);

        update workOrderToUpdate;

        recalculateCasePricingFields(workOrderToUpdate);
    }

    public static void recalculateCasePricingFields(List<WorkOrder> workOrderList){

        System.debug('#workOrderList '+workOrderList);

        Set<Id> caseIdSet = new Set<Id>();

        for (WorkOrder iter: workOrderList){

            caseIdSet.add(iter.CaseId);
        }

        List<Case> caseList = [select id, UNITY_Total_Price__c, UNITY_Total_Cost__c, UNITY_Sales_Tax__c, (Select Id, UNITY_Work_Order_Total__c, UNITY_Total_Cost__c, UNITY_Sales_Tax__c, UNITY_Work_Order_Margin__c From WorkOrders) from Case where id in:caseIdSet];

        System.debug('#caseList '+caseList);

        List<Case> caseToUpdate = new List<Case>();

        for (Case iter: caseList){

            iter.UNITY_Total_Price__c = 0;
            iter.UNITY_Total_Cost__c = 0;
            iter.UNITY_Sales_Tax__c = 0;

            for (WorkOrder wo: iter.WorkOrders){

                if (wo.UNITY_Work_Order_Total__c != null){
                    iter.UNITY_Total_Price__c += wo.UNITY_Work_Order_Total__c;
                }
                if (wo.UNITY_Total_Cost__c != null){
                    iter.UNITY_Total_Cost__c += wo.UNITY_Total_Cost__c;
                }
                if (wo.UNITY_Sales_Tax__c != null){
                    iter.UNITY_Sales_Tax__c += wo.UNITY_Sales_Tax__c;
                }
            }

            caseToUpdate.add(iter);
        }

        System.debug('#caseToUpdate '+caseToUpdate);

        update caseToUpdate;
    }

    /*
    Izay: Deprecated 
    // Update Location Stock 2/24/2017
    public static void updateLocationStock(Map<id,OrderItem> orderItemsMap){

        //query order item records
        //List<OrderItem> orderItemList = [select id, UNITY_Customer_Adjusted_Quantity__c, UNITY_Price__c, OrderId, PricebookEntry.Product2Id, Order.UNITY_Location__c from OrderItem where Id in: orderItemIdList];
        List<OrderItem> orderItemList = orderItemsMap.values();

        Set<Id> locationIdSet = new Set<Id>();
        Set<Id> productIdSet = new Set<Id>();

        // get related locations and products
        for (OrderItem iter: orderItemList){

            locationIdSet.add(iter.Order.UNITY_Location__c);
            productIdSet.add(iter.PricebookEntry.Product2Id);
        }

        //query existing location stock records
        List<FSO__LocationStock__c> locationStockList = [select id, UNITY_Last_Action_PO__c, FSO__Product__c, FSO__Location__c, FSO__Quantity__c, UNITY_MAC__c from FSO__LocationStock__c where FSO__Product__c in: productIdSet and FSO__Location__c in:locationIdSet];

        Map<String, FSO__LocationStock__c> locationStockMap = new Map<String, FSO__LocationStock__c>();

        for (FSO__LocationStock__c iter: locationStockList){

            String key = iter.FSO__Product__c + '|' + iter.FSO__Location__c;

            locationStockMap.put(key, iter);
        }

        System.debug('#locationStockMap '+locationStockMap);

        List<FSO__LocationStock__c> locationStocktToBeUpserted = new List<FSO__LocationStock__c>();

        for (OrderItem iter: orderItemList){

            String key = iter.PricebookEntry.Product2Id+'|'+iter.Order.UNITY_Location__c;

            System.debug('#key '+key);

            if (locationStockMap.get(key) != null){
                //update FSO__LocationStock__c

                FSO__LocationStock__c stock = locationStockMap.get(key);

                System.debug('#stock '+stock);
                System.debug('#OrderItem '+iter);

                Double oldQtty = stock.FSO__Quantity__c;

                stock.FSO__Quantity__c = stock.FSO__Quantity__c + iter.UNITY_Customer_Adjusted_Quantity__c;
                Double allQty = (oldQtty * stock.UNITY_MAC__c + iter.UNITY_Customer_Adjusted_Quantity__c * iter.UNITY_Price__c);
                Double oldPlusCustQty = (oldQtty+iter.UNITY_Customer_Adjusted_Quantity__c);
                if(allQty != null && allQty !=0 && oldPlusCustQty != null && oldPlusCustQty !=0){
                    stock.UNITY_MAC__c = allQty/oldPlusCustQty;
                }
                //stock.UNITY_Landed_Cost__c = stock.UNITY_MAC__c * 1.2;
                stock.UNITY_Last_Action_PO__c = iter.OrderId;

                locationStocktToBeUpserted.add(stock);

            }else{
                //create FSO__LocationStock__c
                FSO__LocationStock__c stock = new FSO__LocationStock__c();

                stock.FSO__Quantity__c = iter.UNITY_Customer_Adjusted_Quantity__c;
                stock.UNITY_MAC__c = iter.UNITY_Price__c;
                stock.FSO__Location__c = iter.Order.UNITY_Location__c;
                stock.FSO__Product__c = iter.PricebookEntry.Product2Id;
                stock.UNITY_Last_Action_PO__c = iter.OrderId;

                locationStocktToBeUpserted.add(stock);
            }
        }

        upsert locationStocktToBeUpserted;
    }*/

}