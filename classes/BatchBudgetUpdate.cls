/**This class updates buidget records
***@Developer: Izay Ramos-Irizarry
***@Date:      7/21/2015
***@Version:   1.0
*/
global class BatchBudgetUpdate  implements Database.Batchable<SObject>{
    global string query {get; set;}//String to hold the query to be executed
    //Batch start method
    global Database.QueryLocator start(Database.BatchableContext BC){
        //If there is a query...
        if(String.isNotBlank(query)){
            //Return the query locator for the query
            return Database.getQueryLocator(query);
        //Othertwise...
        }else{
            //Build the query...
            //Get all the work orders that are missing their service report
            query = 'SELECT Id,Name,Service_Revenue_Actual__c,Service_Gross_Actual__c,Period_Month__c,Period_Year__c,End_Date__c,Start_Date__c,Active__c,Equipment_Gross_Actual__c,Equipment_Revenue_Actual__c,' +
                'Equipment_Call_Volume_Actual__c,Equipment_Scheduled_Call_Volume_Actual__c,Equipment_Invoiced_Call_Volume_Actual__c,Service_Gross_Profit_Opportunity_Dollars__c,'+
                'Service_Revenue_Opportunity_Dollars__c,Equipment_Revenue_Opportunity_Dollars__c,Equipment_Gross_Profit_Opportunity__c,'+
                'Service_Call_Volume_Actual__c,Service_Scheduled_Call_Volume_Actual__c,Service_Invoiced_Call_Volume_Actual__c,Super_Center__c,Super_Center__r.Name,' +
                'Super_Center__r.Super_Center__c,Super_Center__r.Segment__c,Segment__c,Segment__r.Segment_Name__c,RecordTypeId' +
                ' FROM Budget__c WHERE (Start_Date__c >= LAST_YEAR AND End_Date__c <= THIS_YEAR) AND Active__c = TRUE' +
                ' ORDER BY Super_Center__r.Name DESC, Start_Date__c ASC';
            //Return the query locator for the query
            return Database.getQueryLocator(query);
        }//End if query
    }//End start method
    
    //Batch execute method
    global void execute(Database.BatchableContext BC, List<Budget__c> scope){
        //Get the budget record type id fpor segment to detyermin if handliing a segment budget or not
        String segRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'Budget__c' AND DeveloperName = 'Segment_Budget'].Id;
        //For each budget period in the batch
        for(Budget__c b :scope){
            
            //Convert start and end date to datetime
            DateTime startDate = DateTime.newInstance(b.Start_Date__c.year(), b.Start_Date__c.month(), b.Start_Date__c.day(), 0, 0, 0);
            DateTime endDate = DateTime.newInstance(b.End_Date__c.year(), b.End_Date__c.month(), b.End_Date__c.day(), 23, 59, 59);
            /* **************************************************************
             * Get all my service work orders with invoices for this period *
             ************************************************************** */
            List<SVMXC__Service_Order__c> serviceOrders = new List<SVMXC__Service_Order__c>();
            if(b.RecordTypeId == segRTId){
                serviceOrders = [SELECT Id,Name,SVMXC__Order_Type__c,SVMXC__Scheduled_Date_Time__c,CreatedDate,SVMXC__Finished_Onsite_Date_Time__c,Super_Center2__c,
                                                           Work_Order_Total__c,Total_Cost__c,Work_Order_Margin_c2__c,SVMXC__Invoice_Created__c,Segment__c
                                                           FROM SVMXC__Service_Order__c WHERE Super_Center2__c = :b.Super_Center__c AND Segment__c = :b.Segment__c
                                                           AND SVMXC__Order_Type__c != 'Sales-EQUIP' AND SVMXC__Order_Status__c != 'Cancelled'
                                                           AND(
                                                               (CreatedDate >= :b.Start_Date__c AND CreatedDate <= :b.End_Date__c) 
                                                               OR(SVMXC__Scheduled_Date_Time__c >= :b.Start_Date__c AND SVMXC__Scheduled_Date_Time__c <= :b.End_Date__c)
                                                           )];
            }else{
                serviceOrders = [SELECT Id,Name,SVMXC__Order_Type__c,SVMXC__Scheduled_Date_Time__c,CreatedDate,SVMXC__Finished_Onsite_Date_Time__c,Super_Center2__c,
                                                           Work_Order_Total__c,Total_Cost__c,Work_Order_Margin_c2__c,SVMXC__Invoice_Created__c,Segment__c
                                                           FROM SVMXC__Service_Order__c WHERE Super_Center2__c = :b.Super_Center__c
                                                           AND SVMXC__Order_Type__c != 'Sales-EQUIP' AND SVMXC__Order_Status__c != 'Cancelled'
                                                           AND(
                                                               (CreatedDate >= :b.Start_Date__c AND CreatedDate <= :b.End_Date__c) 
                                                               OR(SVMXC__Scheduled_Date_Time__c >= :b.Start_Date__c AND SVMXC__Scheduled_Date_Time__c <= :b.End_Date__c)
                                                           )];
            }
            //Get all the Job Counts for service
            Integer allService = 0;//count of ALL SERVICE work orders
            Integer servSchedCount = 0;//count of SCHEDULED SERVICE work orders
            Integer servSchedInv = 0;//count of INVOICE SERVICE work orders
            Decimal servOpptyRevenue = 0;//Total Opportunity Revenue (NOT INVOICED SERVICE work orders)
            Decimal servOpptyGrossProfit = 0;//Total Opportunity Gross Profit (NOT INVOICED SERVICE work orders)
            Integer todayService = 0; //Count of all service created today
            Integer todayServSched = 0; //Count of service scheduled for today
            Integer todayServInv = 0; //Count of service invoiced today
            Decimal todayServOpptyAmount = 0; //Oppty amount for scheduled today
            for(SVMXC__Service_Order__c wo : serviceOrders){
                //If the work order created date is within the budget period...
                if(wo.CreatedDate >= b.Start_Date__c && wo.CreatedDate <= b.End_Date__c){
                    allService ++;//Add one to allService
                    //Count the today values
                    Date woDate = wo.CreatedDate.date();
                    if(woDate == Date.today()){
                        todayService ++;
                    }
                }//End if created
                //If the work order is scheduled within the budget period...
                if(wo.SVMXC__Scheduled_Date_Time__c >= b.Start_Date__c && wo.SVMXC__Scheduled_Date_Time__c <= b.End_Date__c){
                    servSchedCount ++;//Add one to servSchedCount
                    //If the work order has an invoice...
                    if(wo.SVMXC__Invoice_Created__c){
                        servSchedInv ++;//Add one to servSchedInv
                    }else{
                        servOpptyRevenue += (wo.Work_Order_Total__c != null) ? wo.Work_Order_Total__c : 0;
                        servOpptyGrossProfit += wo.Work_Order_Margin_c2__c;
                    }//End if inv
                    //Count the today values
                    Date woDate = wo.SVMXC__Scheduled_Date_Time__c.date();
                    if(woDate == Date.today()){
                        todayServSched ++;
                        //If the work order has an invoice...
                        if(wo.SVMXC__Invoice_Created__c){
                            todayServInv ++;//Add one to servSchedInv
                        }else{
                            todayServOpptyAmount += (wo.Work_Order_Total__c != null) ? wo.Work_Order_Total__c : 0;
                        }//End if inv
                    }
                }//End if scheduled
            }//End for work order
            
            /* ********************************************
             * Update the budget with ACTUALS for SERVICE *
             ******************************************** */
            //Service
            b.Service_Call_Volume_Actual__c = allService;
            b.Service_Scheduled_Call_Volume_Actual__c = servSchedCount;
            b.Service_Invoiced_Call_Volume_Actual__c = servSchedInv;
            b.Service_Revenue_Opportunity_Dollars__c = servOpptyRevenue;
            b.Service_Gross_Profit_Opportunity_Dollars__c = servOpptyGrossProfit;
            b.Today_Service_Job_Created__c = todayService;
            b.Today_Service_Job_Scheduled__c = todayServSched;
            b.Today_Service_Job_Invoiced__c = todayServInv;
            b.Today_Service_Opportunity__c = todayServOpptyAmount;
            /* ***************************************************************
             * Get all my equpment work orders with invoices for this period *
             *************************************************************** */
            List<SVMXC__Service_Order_Line__c> equipDetails = new List<SVMXC__Service_Order_Line__c>();
            //Check if the budget is to a segment
            if(b.RecordTypeId == segRTId){
                equipDetails = [SELECT Id,Deliver_Date__c,SVMXC__Service_Order__c,SVMXC__Service_Order__r.SVMXC__Order_Type__c,Invoice_Detail__c,
                                                               SVMXC__Is_Billable__c,SVMXC__Actual_Price2__c,Vendor_Cost_Per_Unit__c,SVMXC__Total_Line_Price__c
                                                               FROM SVMXC__Service_Order_Line__c
                                                               WHERE SVMXC__Service_Order__r.SVMXC__Order_Type__c = 'Sales-EQUIP' AND SVMXC__Is_Billable__c = TRUE
                                                               AND SVMXC__Service_Order__r.SVMXC__Order_Status__c != 'Cancelled'
                                                               AND SVMXC__Line_Status__c != 'Canceled'
                                                               AND SVMXC__Service_Order__r.Super_Center2__c = :b.Super_Center__c AND SVMXC__Service_Order__r.Segment__c = :b.Segment__c
                                                               AND (Deliver_Date__c >= :b.Start_Date__c AND Deliver_Date__c <= :b.End_Date__c)];
            }else{
                equipDetails = [SELECT Id,Deliver_Date__c,SVMXC__Service_Order__c,SVMXC__Service_Order__r.SVMXC__Order_Type__c,Invoice_Detail__c,
                                                               SVMXC__Is_Billable__c,SVMXC__Actual_Price2__c,Vendor_Cost_Per_Unit__c,SVMXC__Total_Line_Price__c
                                                               FROM SVMXC__Service_Order_Line__c
                                                               WHERE SVMXC__Service_Order__r.SVMXC__Order_Type__c = 'Sales-EQUIP' AND SVMXC__Is_Billable__c = TRUE
                                                               AND SVMXC__Service_Order__r.SVMXC__Order_Status__c != 'Cancelled'
                                                               AND SVMXC__Line_Status__c != 'Canceled'
                                                               AND SVMXC__Service_Order__r.Super_Center2__c = :b.Super_Center__c
                                                               AND (Deliver_Date__c >= :b.Start_Date__c AND Deliver_Date__c <= :b.End_Date__c)];
            }
            //Integer allEquip = 0;//count of ALL EQUIP work orders
            Integer equipSchedCount = 0;//count of SCHEDULED EQUIP work orders
            integer equipSchedInv = 0;//count of W/ INVOICE EQUIP work orders
            Decimal equipOpptyRevenue = 0;
            Decimal equipOpptyGrossProfit = 0;
            Decimal todayEquipOpptyAmount = 0; //Oppty amount for scheduled today
            if(equipDetails.size() > 0){
                Set<Id> woids = new Set<Id>();//hold the work order ids for the lines
                //For each detail line...
                for(SVMXC__Service_Order_Line__c line :equipDetails){
                    //woids.add(line.SVMXC__Service_Order__c);//Add the work order id to the woids set
                    //If the work order created date is within the budget period...
                    //allEquip ++;//Add one to allEquip
                    //If the work order is scheduled within the budget period...
                    equipSchedCount ++;//Add one to equipSchedCount
                    //If the work order has an invoice...
                    if(String.isNotBlank(line.Invoice_Detail__c)){
                        equipSchedInv ++;//Add one to equipSchedInv
                    }else{
                        Decimal linePrice = (line.SVMXC__Total_Line_Price__c != null) ? line.SVMXC__Total_Line_Price__c : 0;
                        Decimal lineCost = (line.Vendor_Cost_Per_Unit__c != null) ? line.Vendor_Cost_Per_Unit__c : 0;
                        Decimal lineMargin = linePrice - lineCost;
                        equipOpptyRevenue += linePrice;
                        equipOpptyGrossProfit += lineMargin;
                        if(line.Deliver_Date__c == Date.today()){
                            todayEquipOpptyAmount += linePrice;
                        }
                    }//End if inv else
                }
            }//End if equipDetails
            
            /* **********************************************
             * Update the budget with ACTUALS for EQUIPMENT *
             ********************************************** */
            //Equipment
            b.Equipment_Call_Volume_Actual__c = equipSchedCount;
            b.Equipment_Scheduled_Call_Volume_Actual__c = equipSchedCount;
            b.Equipment_Invoiced_Call_Volume_Actual__c = equipSchedInv;
            b.Equipment_Revenue_Opportunity_Dollars__c = equipOpptyRevenue;
            b.Equipment_Gross_Profit_Opportunity__c = equipOpptyGrossProfit;
            b.Today_Equipment_Opportunity__c = todayEquipOpptyAmount;
            /* ********************************************
             * Get all the invoices for the budget period *
             ******************************************** */
            List<MH_Invoice__c> invoices = new List<MH_Invoice__c>();
            if(b.RecordTypeId == segRTId){
                invoices = [SELECT Id,Name,Invoice_Details_Revenue__c,Invoice_Margin__c,SL_Invoice_Date_c__c,Work_Order__c,Work_Order__r.Super_Center2__c,
                                            Work_Order__r.SVMXC__Order_Type__c,Work_Order__r.Super_Center__c,Work_Order__r.SVMXC__Order_Status__c,Status__c,Supercenter_Formula__c
                                            FROM MH_Invoice__c WHERE (Status__c != 'Void' AND Status__c != 'Reversed') 
                                            AND Work_Order__r.Super_Center2__c = :b.Super_Center__c AND Work_Order__r.Segment__c = :b.Segment__c
                                            AND (SL_Invoice_Date_c__c >= :b.Start_Date__c AND SL_Invoice_Date_c__c <= :b.End_Date__c)];
            }else{
                invoices = [SELECT Id,Name,Invoice_Details_Revenue__c,Invoice_Margin__c,SL_Invoice_Date_c__c,Work_Order__c,Work_Order__r.Super_Center2__c,
                                            Work_Order__r.SVMXC__Order_Type__c,Work_Order__r.Super_Center__c,Work_Order__r.SVMXC__Order_Status__c,Status__c,Supercenter_Formula__c
                                            FROM MH_Invoice__c WHERE (Status__c != 'Void' AND Status__c != 'Reversed') 
                                            AND Work_Order__r.Super_Center2__c = :b.Super_Center__c
                                            AND (SL_Invoice_Date_c__c >= :b.Start_Date__c AND SL_Invoice_Date_c__c <= :b.End_Date__c)];
            }
            //Get the actuals from invoices for this budget period
            Decimal servRevenue = 0;//Total revenue for SERVICE work orders
            Decimal servGross = 0;//Total gross for SERVICE work order
            Decimal equipRevenue = 0;//Total revenue for EQUIPMENT work orders
            Decimal equipGross = 0;//Total gross for EQUIPMENT work order
            Decimal todayEquipInvoiced = 0; //Amount invoiced
            Decimal todayServInvoiced = 0; //Amount invoiced
            for(MH_Invoice__c inv :invoices){
                //If the work order is equipment...
                if(inv.Work_Order__r.SVMXC__Order_Type__c == 'Sales-EQUIP'){
                    equipRevenue += inv.Invoice_Details_Revenue__c;
                    equipGross += inv.Invoice_Margin__c;
                    if(inv.SL_Invoice_Date_c__c == Date.today()){
                        todayEquipInvoiced += inv.Invoice_Details_Revenue__c;
                    }
                //Otherwise, if the work order is equipment...
                }else{
                    servRevenue += inv.Invoice_Details_Revenue__c;
                    servGross += inv.Invoice_Margin__c;
                    if(inv.SL_Invoice_Date_c__c == Date.today()){
                        todayServInvoiced += inv.Invoice_Details_Revenue__c;
                    }
                }//End if equip or service
            }//End for invoices
            /* ********************************
             * Update the budget with actuals *
             ******************************** */
            b.Equipment_Gross_Actual__c = equipGross;
            b.Equipment_Revenue_Actual__c = equipRevenue;
            b.Service_Gross_Actual__c = servGross;
            b.Service_Revenue_Actual__c = servRevenue;
            b.Today_Service_Invoiced__c = todayServInvoiced;
            b.Today_Equipment_Invoiced__c = todayEquipInvoiced;
        }
        try{
            update scope;
        }catch(Exception e){
            System.debug('================= Error: ' + e.getMessage());
        }
    }//End execute method
    
    //Batch finish method
    global void finish(Database.BatchableContext BC){
        AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed,
                          TotalJobItems, CreatedBy.Email, ExtendedStatus
                          FROM AsyncApexJob WHERE Id = :bc.getJobId()];        
        if(a.Status == 'Completed' && a.NumberOfErrors > 0) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            // Send the email to the job submitter
            String[] toAddresses = new String[] {a.CreatedBy.Email};
            mail.setToAddresses(toAddresses);
            mail.setSenderDisplayName('Batch Updating Budget');
            mail.setSubject('BatchUpdateBudget  Status: ' + a.Status);
            mail.setHTMLBody('<p>The batch Apex job, <strong>BatchBudgetUpdate</strong> completed.</p>' + 
                '<p>Number of Batches: ' + a.TotalJobItems + '</p>' + 
                '<p>Number of Errors:'+ a.NumberOfErrors + '</p>' +  
                '<p>ExtendedStatus: ' + a.ExtendedStatus);
            // Add your attachment to the email.
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }//End finish method
}