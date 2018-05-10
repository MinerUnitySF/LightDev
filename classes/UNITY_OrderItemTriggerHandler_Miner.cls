/**UNITY_OrderItemTriggerHandler_Miner
 * @description: This class is the trigger handler for the OrderItem object (Build by Miner)
 * 				 It run some validations
 * @programer:   Izay Ramos-Irizarry
 * @date:		 4/21/2016
 * @version:	 1.0
 * ==========================================================================
 * Change Log
 * ==========================================================================
 * @description: Deprecated the checkMenuPricingPart, validatePartSource, and checkActualArrivaldate methods. 
 *               The last tow are moved to validation rule and WF Rules respectively
 * @programer:   Izay Ramos-Irizarry
 * @date:        9/24/2016
 */
public class UNITY_OrderItemTriggerHandler_Miner  extends UNITY_BaseHandler{
    
    public override void bulkBefore(){
        if(runTriggerOnce_Before()){
            System.debug('##### On Bulk Before');
            if(Trigger.isInsert || Trigger.isUpdate){
                List<OrderItem> oLines = new List<OrderItem>();
                for(SObject s :Trigger.new){
                    OrderItem line = (OrderItem)s;
                    if(String.isBlank(line.UNITY_GL_Cost_Account__c)|| String.isBlank(line.UNITY_GL_Revenue_Account__c)|| String.isBlank(line.UNITY_GL_Tax_Account__c)){
                        oLines.add(line);
                    }
                }
                System.debug('##### oLines.size(): ' + oLines.size());
                if(!oLines.isEmpty()){
                    setGLValues(oLines);
                }
            }
        }
    }
    
    public override void bulkAfter(){
        if(runTriggerOnce_After()){
            if(Trigger.isUpdate){
                //validatePartSource();
                //checkActualArrivaldate();
                //checkMenuPricingPart();
            }else if(Trigger.isInsert){
            	//checkMenuPricingPart();
            }
        }
    }
    
    @Future(callout=true)
    public static void callGettaxPO(Set<Id> oids){
        if(!oids.isEmpty()){
            UNITY_Constants.isExecutingContext.put('UNITY_OrderItemTriggerHandler_Miner.callGettaxPO',true);
            UNITY_CallAvatax.AvataxResult taxResult = UNITY_CallAvatax.getTaxPO(oids);
        }
    }
    
    public static void setGLValues(List<OrderItem> oLines){
        System.debug('##### On setGLValues');
        if(!oLines.isEmpty()){
            System.debug('##### oLines.size(): ' + oLines.size());
            /*List<OrderItem> toUpdate = new List<OrderItem>();
            List<OrderItem> oLines = [SELECT Id,OrderId,Order.UNITY_Work_Order_Type__c,UNITY_Type__c,UNITY_Activity_Type__c,UNITY_GL_Cost_Account__c,
                                      UNITY_GL_Revenue_Account__c,UNITY_GL_Tax_Account__c
                                      FROM OrderItem WHERE Id IN :oItemIds];
			*/
            Set<Id> oids = new Set<Id>();
            for(OrderItem line :oLines){
                oids.add(line.OrderId);
            }
            Map<Id,Order> oMap = new Map<Id,Order>([SELECT Id,UNITY_Work_Order_Type__c FROM Order WHERE Id IN: oids]);
            
            List<UNITY_GL_Matrix__c> glMatrix = [SELECT Id,Name,UNITY_Order_Type__c,UNITY_Line_Type__c,UNITY_Activity_Type__c,UNITY_Cost_Account__c,
                                                 UNITY_Revenue_Account__c,UNITY_Tax_Account__c 
                                                 FROM UNITY_GL_Matrix__c];
            //Create a map of CreditAccount by ActivityType by LineType by OrderType
            //to make it easier to find a match per line
            Map<String,Map<String,Map<String,UNITY_GL_Matrix__c>>> glmMap = new Map<String,Map<String,Map<String,UNITY_GL_Matrix__c>>>();
            for(UNITY_GL_Matrix__c entry :glMatrix){
                if(!glmMap.containsKey(entry.UNITY_Order_Type__c)){
                    Map<String,Map<String,UNITY_GL_Matrix__c>> tempMap = new Map<String,Map<String,UNITY_GL_Matrix__c>>();
                    Map<String,UNITY_GL_Matrix__c> tempMap2 = new Map<String,UNITY_GL_Matrix__c>();
                    tempMap2.put(entry.UNITY_Activity_Type__c,entry);
                    tempMap.put(entry.UNITY_Line_Type__c,tempMap2);
                    glmMap.put(entry.UNITY_Order_Type__c,tempMap);
                }else if(!glmMap.get(entry.UNITY_Order_Type__c).containsKey(entry.UNITY_Line_Type__c)){
                    Map<String,UNITY_GL_Matrix__c> tempMap = new Map<String,UNITY_GL_Matrix__c>();
                    tempMap.put(entry.UNITY_Activity_Type__c,entry);
                    glmMap.get(entry.UNITY_Order_Type__c).put(entry.UNITY_Line_Type__c,tempMap);
                }else{
                    glmMap.get(entry.UNITY_Order_Type__c).get(entry.UNITY_Line_Type__c).put(entry.UNITY_Activity_Type__c,entry);
                }
            }//End for GL Matrix
            //Now, I need to find a match for per order line to populate the credit account
            for(OrderItem line :oLines){
                Boolean updated = false;
                Boolean isError = false;
                if(String.isBlank(line.UNITY_GL_Cost_Account__c)|| String.isBlank(line.UNITY_GL_Revenue_Account__c)|| String.isBlank(line.UNITY_GL_Tax_Account__c)){
                    if(oMap.containsKey(line.OrderId)){
                        String otype = oMap.get(line.OrderId).UNITY_Work_Order_Type__c;
                        System.debug('##### order type: ' + otype);
                        System.debug('##### oMap.contains(OrderId):' + oMap.containsKey(line.OrderId));
                        if(glmMap.containsKey(otype)){
                            if(glmMap.get(otype).containsKey(line.UNITY_Type__c)){
                                if(glmMap.get(otype).get(line.UNITY_Type__c).containsKey(line.UNITY_Activity_Type__c)){
                                    line.UNITY_GL_Cost_Account__c = glmMap.get(otype).get(line.UNITY_Type__c).get(line.UNITY_Activity_Type__c).UNITY_Cost_Account__c;
                                    System.debug('##### order type: ' + otype);
                                    line.UNITY_GL_Revenue_Account__c = glmMap.get(otype).get(line.UNITY_Type__c).get(line.UNITY_Activity_Type__c).UNITY_Revenue_Account__c;
                                    
                                    line.UNITY_GL_Tax_Account__c = glmMap.get(otype).get(line.UNITY_Type__c).get(line.UNITY_Activity_Type__c).UNITY_Tax_Account__c;
                                    updated = true;
                                }//End contains activity type
                            }//End contains line type
                        }//ENd contains order type
                    }
                        
                    if(String.isBlank(line.UNITY_GL_Cost_Account__c)){
                        //Need to flag the line here... NO Credit Account Found
                        isError = true;
                    }else if(String.isBlank(line.UNITY_GL_Revenue_Account__c)){
                        //Net to flag the line here... No Revenue Accouint Found
                        isError = true;
                    }else if(String.isBlank(line.UNITY_GL_Tax_Account__c)){
                        //Need to flag the line here... No Tax Account FOund
                        isError = true;
                    }
                }//End if GL Credit Account is Blank
            }//ENd for Line
        }//End if oItemIds is Not Blank
    }
    /** This method delete all part lines from a PO if the WO is Menu Pricing and the vendor running the job has that part contyracted as menu price
     * 
    public static void checkMenuPricingPart(){
        System.debug('##### In checkMenuPricingPart()');
        Map<Id,List<OrderItem>> oMap = new Map<Id,List<OrderItem>>();
        for(OrderItem oi :(List<OrderItem>)Trigger.new){
            if(oi.UNITY_Is_Menu_Pricing__c){
                if(!oMap.containsKey(oi.OrderId)){
                    oMap.put(oi.OrderId,new List<OrderItem>());
                }
            }
        }
        System.debug('##### oMap.keySet().isEmpty(): ' + oMap.keySet().isEmpty());
        if(!oMap.keySet().isEmpty()){
            List<Order> orders = [SELECT Id,UNITY_Vendor__c,UNITY_Work_Order_Type__c FROM Order WHERE Id IN :oMap.keySet()];
            System.debug('##### orders.size(): ' + orders.size());
            List<OrderItem> oItems = [SELECT Id,UNITY_Activity_Type__c,UNITY_Is_Menu_Pricing__c,UNITY_Product_Id__c,OrderId FROM OrderItem WHERE OrderId IN :oMap.keySet() AND IsDeleted = FALSE];
            System.debug('##### oItems.size(): ' + oItems.size());
            Set<Id> vids = new Set<Id>();
            for(Order o :orders){
                vids.add(o.UNITY_Vendor__c);
            }
            for(OrderItem oi :oItems){
                if(oMap.containsKey(oi.OrderId)){
                    oMap.get(oi.OrderId).add(oi);
                }
            }
            String SCLIPPRTID = UNITY_Constants.SCLI_PRODUCT_PRICING_RECORDTYPE;
            List<UNITY_Service_Contract__c> vSC = [SELECT Id,Name,UNITY_Account__c,UNITY_Is_Active__c,RecordTypeId,
                                                   (SELECT Id,Name,UNITY_Product__c FROM UNITY_Service_Contract_Line_Items__r WHERE RecordTypeId = :SCLIPPRTID)
                                                   FROM UNITY_Service_Contract__c WHERE UNITY_Account__c IN :vids AND UNITY_Is_Active__c = TRUE];
            System.debug('##### vSC.size(): ' + vSC.size());
            Map<Id,List<UNITY_Service_Contract__c>> vSCMap = new Map<Id,List<UNITY_Service_Contract__c>>();
            for(UNITY_Service_Contract__c sc :vSC){
                if(!sc.UNITY_Service_Contract_Line_Items__r.isEmpty()){
                    if(!vSCMap.containsKey(sc.UNITY_Account__c)){
                        vSCMap.put(sc.UNITY_Account__c,new List<UNITY_Service_Contract__c>{sc});
                    }else{
                        vSCMap.get(sc.UNITY_Account__c).add(sc);
                    }
                }
            }
            System.debug('##### vSCMap.keySet().size(): ' + vSCMap.keySet().size());
            List<OrderItem> toDelete = new List<OrderItem>();
            for(Order o :orders){
                String SCServiceRT = UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE;
                String SCProjectRT = UNITY_Constants.SC_PROJECT_MANAGEMENT_RECORDTYPE;
                String SCPMRT = UNITY_Constants.SC_PREVENTATIVE_MAINTENANCE_RECORDTYPE;
                Boolean vHasMP = false;
                Set<Id> mpProdsSC = new Set<Id>();
                System.debug('##### vSCMap.containsKey(o.UNITY_Vendor__c): ' + vSCMap.containsKey(o.UNITY_Vendor__c));
                if(vSCMap.containsKey(o.UNITY_Vendor__c)){
                    //System.debug('##### vpid: ' + pid);
                    for(UNITY_Service_Contract__c sc :vSCMap.get(o.UNITY_Vendor__c)){
                        System.debug('##### o.UNITY_Work_Order_Type__c: ' + o.UNITY_Work_Order_Type__c);
                        System.debug('##### sc.RecordTypeId: ' + sc.RecordTypeId);
                        if((o.UNITY_Work_Order_Type__c == 'Service' && sc.RecordTypeId == SCServiceRT) || 
                           (o.UNITY_Work_Order_Type__c == 'Project' && sc.RecordTypeId == SCProjectRT) ||
                           (o.UNITY_Work_Order_Type__c == 'PM' && sc.RecordTypeId == SCPMRT) ){
                               for(UNITY_Service_Contract_Line_Item__c scli: sc.UNITY_Service_Contract_Line_Items__r){
                                   System.debug('##### scli.UNITY_Product__c: ' + scli.UNITY_Product__c);
                                   //System.debug('##### vpid: ' + pid);
                                   mpProdsSC.add(scli.UNITY_Product__c);
                               }
                           }
                    }
                    for(OrderItem oi :oMap.get(o.Id)){
                        if(mpProdsSC.contains(oi.UNITY_Product_Id__c)){
                            vHasMP = true;
                            break;
                        }
                    }
                }
                if(vHasMP){
                    for(OrderItem oi :oMap.get(o.Id)){
                        if(!mpProdsSC.contains(oi.UNITY_Product_Id__c) && 
                          (oi.UNITY_Activity_Type__c.indexOf('Part') != -1)){
                            toDelete.add(oi);
                        }
                    }
                }
            }
            if(!toDelete.isEmpty()){
                try{
                    delete toDelete;
                }catch(Exception e){
                    Trigger.new[0].addError(e.getMessage());
                }
            }
        }
    }
    */
    /*
    public static void validatePartSource(){
        String usagertRTId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
        String partsSourceRTId = UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE;
        String poRTId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;
        Set<Id> polids = new Set<Id>();
        for(SObject so :Trigger.new){
            OrderItem oItem = (OrderItem)so;
            if((oItem.UNITY_Order_Record_Type_Id__c == usagertRTId || oItem.UNITY_Order_Record_Type_Id__c == partsSourceRTId) && 
               (oItem.UNITY_Cost__c != null && oItem.UNITY_Cost__c > 0) && 
               String.isBlank(oItem.UNITY_Part_Source__c) && !oItem.UNITY_Is_Vendor_Supply__c &&
               (oItem.UNITY_Type__c == 'Parts' || (oItem.UNITY_Type__c == 'Vendor Services' && oItem.UNITY_Activity_Type__c.contains('Parts')))){
                   Trigger.new[0].addError(' Part Source is required when entering a cost and the part is not vendor supply. ');
            }
        }
    }
    */
    /*
    public static void checkActualArrivaldate(){
        if(checkArrivalDateOnce()){
            if(Trigger.isUpdate){
                String poRTId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;
                String poPSRTId = UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE;
                String woPSRTId = UNITY_Constants.WO_NON_WORK_RECORDTYPE;
                String woSRRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;
                Set<Id> oids = new Set<Id>();
                for(SObject so: Trigger.new){
                    OrderItem line = (OrderItem)so;
                    OrderItem oldLine = (OrderItem)Trigger.oldMap.get(line.id);
                    if(line.UNITY_Actual_Ship_Date__c != null && oldLine.UNITY_Actual_Ship_Date__c != line.UNITY_Actual_Ship_Date__c) {
                        //Izay: get the id for POLIs that gor Actual Arrival Date set
                        oids.add(line.Orderid);
                    }
                }
                if(!oids.isEmpty()){
                    //Izay: Get all the lines for the Order which actual arrival date changed
                    Map<Id,Order> osMap = new Map<Id,Order>([SELECT Id,UNITY_Shipping_Method__c,FSO__WorkOrder__c,Status,FSO__WorkOrder__r.RecordTypeId FROM Order WHERE Id IN: oids AND (RecordTypeId = :poRTId OR RecordTypeId = :poPSRTId)]);
                    Set<Id> woids = new Set<Id>();//Add work order Id to set
                    for(Order o :osMap.values()){
                        if(!o.OrderItems.isEmpty()){
                            woids.add(o.FSO__WorkOrder__c);
                        }
                    }
                    if(!woids.isEmpty()){
                        //Izay:get the Orders for the Work Orders to see if need to Update Work Order Status 
                        osMap = new Map<Id,Order>([SELECT Id,UNITY_Shipping_Method__c,FSO__WorkOrder__c,Status,FSO__WorkOrder__r.RecordTypeId,(SELECT Id,UNITY_Actual_Ship_Date__c FROM OrderItems WHERE UNITY_Activity_Type__c LIKE '%Part%' AND UNITY_Is_Vendor_Supply__c = FALSE) FROM Order WHERE FSO__WorkOrder__c IN: woids AND ((FSO__WorkOrder__r.RecordTypeId = :woSRRTId AND RecordTypeId = :poRTId) OR (FSO__WorkOrder__r.RecordTypeId = :woPSRTId AND RecordTypeId = :poPSRTId))]);
                        Map<Id,List<Order>> orderByWOId = new Map<Id,List<Order>>();
                        //Izay: Put all Order in a map by Work Order Id
                        for(Order o :osMap.values()){
                            if(!orderByWOId.containsKey(o.FSO__WorkOrder__c))
                                orderByWOId.put(o.FSO__WorkOrder__c, new List<Order>());
                            orderByWOId.get(o.FSO__WorkOrder__c).add(o);
                        }
                        List<WorkOrder> workOrders = new List<WorkOrder>();
                        List<Order> orderToUpdate = new List<Order>();
                        //Izay: For each work order id...
                        for(Id id :woids){
                            //If in the map...
                            if(orderByWOId.containsKey(id)){
                                Boolean allArrived = true;//Denotes if all parts arrived
                                String status = '';//What status are we going to
                                for(Order o :orderByWOId.get(id)){
                                    Boolean allArrOrd = true;//denotes if all the Parts arrived in an order
                                    status = '';
                                    if(o.FSO__WorkOrder__r.RecordTypeId == woSRRTId)//If it is a service work order...
                                        status = 'Pending Re-Dispatch';//The status goes to Re-Dispatch
                                    else
                                        status = 'Completed';//Else the status goes to Completed
                                    //if(o.UNITY_Shipping_Method__c != 'Pickup'){
                                    for(OrderItem item :o.OrderItems){
                                        //For each part line... If the Actual Arrival Date is null
                                        if(item.UNITY_Actual_Ship_Date__c == null){
                                            allArrived = false;//Set all arrived for the WO to false
                                            allArrOrd = false;//Set all arrived for the Order to false
                                            break;
                                        }
                                    }
                                    //}
                                    if(allArrOrd && status == 'Completed'){
                                        o.Status = status;
                                        orderToUpdate.add(o);
                                    }
                                }
                                if(allArrived){
                                    if(Status == 'Pending Re-Dispatch'){
                                        WorkOrder wo = new WorkOrder(
                                            Id = id,
                                            Status = status
                                        );
                                        workOrders.add(wo);
                                    }
                                }
                            }
                        }
                        try{
                            update workOrders;
                            update orderToUpdate;
                        }catch(Exception e){
                            Trigger.new[0].addError('Error: ' + e.getMessage());
                            //System.debug('##### Error: ' + e.getmessage());
                        }
                    }
                }
            }
        }
    }
    */
    /**
    *** This variable and method are used to prevent triggers recursion on before insert/update
    */
    public static Boolean isFirstTriggerRun_Before = true;
    public static Boolean runTriggerOnce_Before(){
        if(isFirstTriggerRun_Before){
            isFirstTriggerRun_Before = false;
            return true;
        }else{
            return isFirstTriggerRun_Before;
        }
    }
    /**
    *** This variable and method are used to prevent triggers recursion on after insert/update
    */
    public static Boolean isFirstTriggerRun_After = true;
    public static Boolean runTriggerOnce_After(){
        if(isFirstTriggerRun_After){
            isFirstTriggerRun_After = false;
            return true;
        }else{
            return isFirstTriggerRun_After;
        }
    }
    /*
    public static Boolean isFirstCheckArrivalDateRun = true;
    public static Boolean checkArrivalDateOnce(){
        if(isFirstTriggerRun_Before){
            isFirstCheckArrivalDateRun = false;
            return true;
        }else{
            return isFirstCheckArrivalDateRun;
        }
    }
    */
}