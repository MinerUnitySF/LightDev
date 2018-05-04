/*
* Created by Andy Chasin - Vertiba (Re-written from Code originally supplied by SVMX)
* Created Date - 11-22-2013
*
* When a Work Order is Closed the work details lines are searched for products/Parts used. 
* If a Part is used, the inventory for the consumed from location is decremented by the quantity used
* If the part does not exist at the location, it will add to the location with a negative value for the quantity. 
*/

trigger workOrderStockUsageLocationUpdate on SVMXC__Service_Order__c (before update) 
{

// create Sets
    Set<Id> closedWorkOrderIds = new Set<Id>(); 
    Set<Id> locationIds = new Set<Id>();    
    Set<Id> consumedFromlocationIds = new Set<Id>();    

//Lists
    List<SVMXC__Service_Order__c> closedWorkOrderLst = new List<SVMXC__Service_Order__c>();
    List<SVMXC__Product_Stock__c> productStockInsertLst = new List<SVMXC__Product_Stock__c>();
    List<SVMXC__Product_Stock__c> productStockUpdateLst = new List<SVMXC__Product_Stock__c>();

//Data Maps
    Map<String, List<SVMXC__Service_Order_Line__c>> workOrderWorkDetailsMap = new Map<String, List<SVMXC__Service_Order_Line__c>>();  
    Map<String, List<SVMXC__Product_Stock__c>> locationProductStockMap = new Map<String, List<SVMXC__Product_Stock__c>>();
    
//Insert and update Maps
    Map<String,SVMXC__Product_Stock__c> productStockUpdateMap = new Map<String,SVMXC__Product_Stock__c>();
    Map<String,SVMXC__Product_Stock__c> productStockInsertMap = new Map<String,SVMXC__Product_Stock__c>();
    

    /*
    * Loops through all work orders and build list of closed work orders and their technicians
    */
    for(SVMXC__Service_Order__c workOrder: Trigger.new)
    {
        if(workOrder.SVMXC__Order_Status__c == 'Job/Work Complete' && Trigger.oldMap.get(workOrder.id).SVMXC__Order_Status__c != 'Completed')
        {
            if(!closedWorkOrderIds.contains(workOrder.id))
                {
                    closedWorkOrderLst.add(workOrder);
                    closedWorkOrderIds.add(workOrder.id);
                }
        }
    }
    
    /*
    * continues if there are any 'completed' work orders
    */
    if (closedWorkOrderIds != NULL && closedWorkOrderIds.size() > 0)
    {
        //Builds list of work detail lines for parts
        List<SVMXC__Service_Order_Line__c> workDetailsLst = [select id,  SVMXC__Actual_Quantity2__c, SVMXC__Service_Order__c, SVMXC__Consumed_From_Location__c,
                                                    RecordType.Name, SVMXC__Line_Type__c, Part_Serial_Number__c, SVMXC__Product__c, SVMXC__Product__r.Name 
                                                    from SVMXC__Service_Order_Line__c where SVMXC__Service_Order__c in :closedWorkOrderIds
                                                    and RecordType.Name = 'Usage/Consumption' and SVMXC__Line_Type__c = 'Parts'];
        
        Set<Id> productstockId = new Set<Id>();
        
        //Only continues if there is at least one work detail that line with parts
        if(workDetailsLst != NULL && workDetailsLst.size() > 0)
        {
            
            /*
            *Build map of work details for corresponding work order
            */
            for(SVMXC__Service_Order_Line__c workDetail : workDetailsLst)
            {
                if(workOrderWorkDetailsMap.containsKey(workDetail.SVMXC__Service_Order__c))
                {
                    List<SVMXC__Service_Order_Line__c> wdtemp = workOrderWorkDetailsMap.get(workDetail.SVMXC__Service_Order__c);
                    wdtemp.add(workDetail);
                    workOrderWorkDetailsMap.put(workDetail.SVMXC__Service_Order__c, wdtemp);
                    consumedFromlocationIds.add(workDetail.SVMXC__Consumed_From_Location__c);
                    
                }
                else
                {
                    List<SVMXC__Service_Order_Line__c> wdtemp = new List<SVMXC__Service_Order_Line__c>();
                    wdtemp.add(workDetail);
                    workOrderWorkDetailsMap.put(workDetail.SVMXC__Service_Order__c, wdtemp);
                    consumedFromlocationIds.add(workDetail.SVMXC__Consumed_From_Location__c);
                }
                
            }
            
            List<SVMXC__Site__c> locationlst = [select id from SVMXC__Site__c where id in :consumedFromlocationIds];            
            System.Debug('AC--Locations List =>'+ consumedFromlocationIds);
            List<SVMXC__Product_Stock__c> productStockLst = [select id, SVMXC__Location__c, SVMXC__Status__c, SVMXC__Product__c, SVMXC__Quantity2__c, SVMXC__Product__r.Name 
                                                        from SVMXC__Product_Stock__c where SVMXC__Location__c in :consumedFromlocationIds 
                                                        and SVMXC__Status__c = 'Available'];
            System.debug('ST: prodStcklst '+productStockLst);
            
            /*
            *Build map of productStock for corresponding location
            */
            for(SVMXC__Product_Stock__c productstock : productStockLst)
            {
                productstockId.add(productstock.id);
                if(locationProductStockMap.containsKey(productstock.SVMXC__Location__c))
                {
                    List<SVMXC__Product_Stock__c> pstemp = locationProductStockMap.get(productstock.SVMXC__Location__c);
                    pstemp.add(productstock);
                    locationProductStockMap.put(productstock.SVMXC__Location__c, pstemp);
                }
                else
                {
                    List<SVMXC__Product_Stock__c> pstemp = new List<SVMXC__Product_Stock__c>();
                    pstemp.add(productstock);
                    locationProductStockMap.put(productstock.SVMXC__Location__c, pstemp);
                }
                System.debug('ST: locationProductStockMap '+productstock.SVMXC__Location__c+' and '+productstock);
            }
            
            //Process all work orders
            for(SVMXC__Service_Order__c workOrder: closedWorkOrderLst)
            {
                
                List<SVMXC__Service_Order_Line__c> workOrderWorkDetailLst = new List<SVMXC__Service_Order_Line__c>();
                
                if(workOrderWorkDetailsMap.containsKey(workOrder.id))
                {
                    
                    workOrderWorkDetailLst = workOrderWorkDetailsMap.get(workOrder.id);
                    
                    //loop through work details for a work order
                    for(SVMXC__Service_Order_Line__c workdetail : workOrderWorkDetailLst)
                    {
                        String SerialNum = workdetail.Part_Serial_Number__c;
                        
                        List<SVMXC__Product_Stock__c> locationProductStockLst = new List<SVMXC__Product_Stock__c>();
                        
                            if(locationProductStockMap.containsKey(workdetail.SVMXC__Consumed_From_Location__c))
                            {
                                
                                locationProductStockLst = locationProductStockMap.get(workdetail.SVMXC__Consumed_From_Location__c);
                                System.debug('AV: locationProductStockLst '+ locationProductStockLst);
                                
                                for(SVMXC__Product_Stock__c productStock:locationProductStockLst)
                                {
                                    
                                        if(productStock.SVMXC__Product__c == workdetail.SVMXC__Product__c)
                                        {
                                                                                    
                                            SVMXC__Product_Stock__c pstemp = new SVMXC__Product_Stock__c();
                                            if(productStockUpdateMap.containskey(productStock.id))
                                            {
                                                pstemp = productStockUpdateMap.get(productStock.id);
                                                pstemp.SVMXC__Quantity2__c  = pstemp.SVMXC__Quantity2__c - workdetail.SVMXC__Actual_Quantity2__c;
                                                productStockUpdateMap.put(productStock.id, pstemp);
                                            }
                                            else
                                            {
                                                pstemp = productStock;
                                                pstemp.SVMXC__Quantity2__c  = pstemp.SVMXC__Quantity2__c - workdetail.SVMXC__Actual_Quantity2__c;
                                                productStockUpdateMap.put(productStock.id, pstemp);
                                            }
                                            break;
                                        }
                                        Else
                                        {
                                            SVMXC__Product_Stock__c tempPS = new SVMXC__Product_Stock__c();
                                            tempPS.SVMXC__Quantity2__c=0;
                                            if(productStockInsertMap.containskey(workdetail.SVMXC__Product__c))
                                            {
                                                tempPS = productStockInsertMap.get(workdetail.SVMXC__Product__c);
                                                tempPS.SVMXC__Quantity2__c -= workdetail.SVMXC__Actual_Quantity2__c;
                                                productStockInsertMap.put(workdetail.SVMXC__Product__c, tempPS);
                                                System.debug('ST: prod id 1 is '+workdetail.SVMXC__Product__c);
                                            }
                                            else
                                            {
                                                
                                                tempPS.SVMXC__Quantity2__c -= workdetail.SVMXC__Actual_Quantity2__c;
                                                tempPS.SVMXC__Product__c = workdetail.SVMXC__Product__c;
                                                tempPS.SVMXC__Location__c = workdetail.SVMXC__Consumed_From_Location__c;
                                                tempPS.SVMXC__Status__c = 'Available';
                                                System.debug('ST: prod id is '+workdetail.SVMXC__Product__c);
                                                productStockInsertMap.put(workdetail.SVMXC__Product__c, tempPS);
                                                
                                            }
                                        }
                                }
                                
                            }
                    }
                }
            }
                
                //if there are new products to insert into locaion
                if(productStockInsertMap.size() > 0)
                {
                    Set<String> productId = new Set<String>();
                    productId = productStockInsertMap.keySet();
                    for(String sval:productId)
                    {
                        if(productStockInsertMap.containsKey(sval))
                            productStockInsertLst.add(productStockInsertMap.get(sval));
                    }
                }
                if(productStockInsertLst.size()>0)
                    insert productStockInsertLst;
                
                System.debug('ST: productStockUpdateLst '+ productStockUpdateLst);
                
                //if there are products to update for a location
                if(productStockUpdateMap.size() > 0)
                {
                    Set<String> psidvals = new Set<String>();
                    psidvals = productStockUpdateMap.keySet();
                    for(String sval:psidvals)
                    {
                        if(productStockUpdateMap.containsKey(sval))
                            productStockUpdateLst.add(productStockUpdateMap.get(sval));
                    }
                }
                if(productStockUpdateLst.size() > 0)
                    update productStockUpdateLst;
            }
            
            
        }
        
    }