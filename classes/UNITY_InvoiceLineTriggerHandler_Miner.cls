public class UNITY_InvoiceLineTriggerHandler_Miner extends UNITY_BaseHandler{
	
    public override void bulkBefore(){
        System.debug('##### On Bulk Before');
        if(Trigger.isInsert || Trigger.isUpdate){
            List<UNITY_Invoice_Line_Item__c> invLines = new List<UNITY_Invoice_Line_Item__c>();
            
            for(SObject s :Trigger.new){
                UNITY_Invoice_Line_Item__c line = (UNITY_Invoice_Line_Item__c)s;
                if(String.isBlank(line.UNITY_GL_Revenue_Account__c)|| String.isBlank(line.UNITY_GL_Tax_Account__c) || String.isBlank(line.UNITY_GL_Sub_Account__c)){
                    invLines.add(line);
                }
                     
            }
            System.debug('##### invLines.size(): ' + invLines.size());
            if(!invLines.isEmpty()){
                setGLValues(invLines);
            }
        }
    }
    
    public override void bulkAfter(){
        System.debug('##### On Bulk Before');
        List<UNITY_Invoice__c> invs = new List<UNITY_Invoice__c>();
        
          List<UNITY_Invoice_Line_Item__c> invPMLines = new List<UNITY_Invoice_Line_Item__c>();
          List<UNITY_Invoice_Line_Item__c> invLaborLines = new List<UNITY_Invoice_Line_Item__c>();
          List<UNITY_Invoice_Line_Item__c> invTravelLines = new List<UNITY_Invoice_Line_Item__c>();
         List<UNITY_Invoice_Line_Item__c> invAllLines = new List<UNITY_Invoice_Line_Item__c>();
        
        if(Trigger.isUpdate){
            for(SObject s :Trigger.new){
                UNITY_Invoice_Line_Item__c line = (UNITY_Invoice_Line_Item__c)s;
                UNITY_Invoice_Line_Item__c oldLine = (UNITY_Invoice_Line_Item__c)Trigger.oldMap.get(line.Id);
                if((line.UNITY_Total_Price__c != oldLine.UNITY_Total_Price__c || 
                    line.UNITY_Quantity__c != oldline.UNITY_Quantity__c || 
                    line.UNITY_Adjusted_Quantity__c != oldLine.UNITY_Adjusted_Quantity__c || 
                    line.UNITY_Line_Status__c != oldLine.UNITY_Line_Status__c ) && 
                   (line.UNITY_Invoice_Status_Formula__c == 'Invoice Creation')){
                       UNITY_Invoice__c inv = new UNITY_Invoice__c(
                           Id = line.UNITY_Invoice__c,
                           UNITY_Tax_Processed__c = false
                       );
                       invs.add(inv);
                   }
            }
        }
       
        if (Trigger.isInsert || Trigger.isUpdate){
              for(SObject s :Trigger.new){
                  UNITY_Invoice_Line_Item__c line = (UNITY_Invoice_Line_Item__c)s;
                  
                if (line.UNITYPM_Is_Preventative_Maintenance__c == true)
                     invPMLines.add(line);
                else if ((line.UNITY_Activity_Type__c.indexOf('Labor') > -1) && line.UNITYPM_Is_Preventative_Maintenance__c == false)//line.UNITY_Activity_Type__c.contains('Labor'))
                       invLaborLines.add(line);
                else if ((line.UNITY_Activity_Type__c.indexOf('Travel') > -1 ) && line.UNITYPM_Is_Preventative_Maintenance__c == false) //line.UNITY_Activity_Type__c.contains('Travel'))
                       invTravelLines.add(line);
                else if (!line.UNITY_Activity_Type__c.contains('Labor') && !line.UNITY_Activity_Type__c.contains('Travel') && !line.UNITYPM_Is_Preventative_Maintenance__c)
                       invAllLines.add(line);
             }
        }
       
       // start Added new ====================================================
            System.debug('##### invPMLines.size(): ' + invPMLines.size());
            if (invPMLines.size() > 0){
                updateInvoicePMLineCount(invPMLines);
             }
             
            System.debug('##### invLaborLines.size(): ' + invLaborLines.size());
            if (invLaborLines.size() > 0){
                updateInvoiceLaborLineCount(invLaborLines);
             }
             
            System.debug('##### invTravelLines.size(): ' + invTravelLines.size());
            if (invTravelLines.size() > 0){
                updateInvoiceTravelLineCount(invTravelLines);
             }
             
            System.debug('##### invAllLines.size(): ' + invAllLines.size());
            if (invAllLines.size() > 0){
                updateInvoicePartLineCount(invAllLines);
             }
            // end Added new ====================================================
       
        if(!invs.isEmpty()){
            try{
                update invs;
            }catch(Exception e){
                if(!Test.isRunningTest())
                    Trigger.new[0].addError('Error updating invoice: ' + e.getMessage());
            }
        }
    }
    
    public override void beforeDelete(SObject so){
        List<UNITY_Invoice_Line_Item__c> invPMLines = new List<UNITY_Invoice_Line_Item__c>();
        if(Trigger.isDelete) {
          UNITY_Invoice_Line_Item__c line = (UNITY_Invoice_Line_Item__c)so; 
            if (line.UNITYPM_Is_Preventative_Maintenance__c)
                     invPMLines.add(line);
           
        }
    }
  
  //==============================================NEW ==============================================================================  
  
    public static void updateInvoicePMLineCount(List<UNITY_Invoice_Line_Item__c> invLines){
         if(!invLines.isEmpty()){
             system.debug('####  neli  updateInvoicePMLineCount  ###');
            System.debug('##### neli invLines.size(): ' + invLines.size());
             
            Set<Id> invids = new Set<Id>();
            
             for(UNITY_Invoice_Line_Item__c line :invLines){
                invids.add(line.UNITY_Invoice__c);
            }
            
            List<UNITY_Invoice__c> invoiceUpdate = new List<UNITY_Invoice__c>();
            AggregateResult[] groupedResults = [SELECT Count(ID),UNITY_Invoice__c  FROM UNITY_Invoice_Line_Item__c WHERE UNITY_Invoice__c IN:invids GROUP BY UNITY_Invoice__c];
            
             for(AggregateResult ar:groupedResults) {
                Id invid = (ID)ar.get('UNITY_Invoice__c');
                Integer count = (Integer)ar.get('expr0');
                
                system.debug('#### neli  invid  ###' + invid);
                
                system.debug('####   neli count  ###' + count);
                
                UNITY_Invoice__c invoice = new UNITY_Invoice__c(Id=invid);
                invoice.UNITYPM_Number_of_Assets__c =count;
                
                system.debug('#### neli  invoice.UNITYPM_Number_of_Assets__c  ###' + invoice.UNITYPM_Number_of_Assets__c);
                
                invoiceUpdate.add(invoice);
           }
           
            if (invoiceUpdate.size()>0)
               update invoiceUpdate;
         }
    }
    
    public static void updateInvoiceLaborLineCount(List<UNITY_Invoice_Line_Item__c> invLines){
         if(!invLines.isEmpty()){
            system.debug('####  neli  updateInvoiceLaborLineCount  ###');
            System.debug('##### neli Labor invLines.size(): ' + invLines.size());
             
            Set<Id> invids = new Set<Id>();
            
             for(UNITY_Invoice_Line_Item__c line :invLines){
                    invids.add(line.UNITY_Invoice__c);
            }
            
            system.debug('####  neli  Labor updateInvoiceLaborLineCount invids  ###' + invids);
            
            List<UNITY_Invoice__c> invoiceUpdate = new List<UNITY_Invoice__c>();
            AggregateResult[] groupedResults = [SELECT Count(ID),UNITY_Invoice__c  FROM UNITY_Invoice_Line_Item__c WHERE UNITY_Invoice__c IN:invids GROUP BY UNITY_Invoice__c];
            
             for(AggregateResult ar:groupedResults) {
                Id invid = (ID)ar.get('UNITY_Invoice__c');
                Integer count = (Integer)ar.get('expr0');
                
                system.debug('#### neli Labor  invid  ###' + invid);
                
                system.debug('####   neli Labor count  ###' + count);
                
                UNITY_Invoice__c invoice = new UNITY_Invoice__c(Id=invid);
                invoice.Number_of_Labor_Lines__c =count;
                
                system.debug('#### neli Labor invoice.Number_of_Labor_Lines__c  ###' + invoice.Number_of_Labor_Lines__c);
                
                invoiceUpdate.add(invoice);
           }
           
            system.debug('####   neli Labor invoiceUpdate.size  ###' + invoiceUpdate.size());
            if (invoiceUpdate.size()>0)
               update invoiceUpdate;
         }
    }
    
    public static void updateInvoiceTravelLineCount(List<UNITY_Invoice_Line_Item__c> invLines){
         if(!invLines.isEmpty()){
            system.debug('####  neli  updateInvoiceTravelLineCount  ###');
            System.debug('##### neli Travel invLines.size(): ' + invLines.size());
             
            Set<Id> invids = new Set<Id>();
            
             for(UNITY_Invoice_Line_Item__c line :invLines){
                  invids.add(line.UNITY_Invoice__c);
            }
            
            
            system.debug('####  neli Travel updateInvoiceTravelLineCount invids  ###' + invids);
            
            List<UNITY_Invoice__c> invoiceUpdate = new List<UNITY_Invoice__c>();
            AggregateResult[] groupedResults = [SELECT Count(ID),UNITY_Invoice__c  FROM UNITY_Invoice_Line_Item__c WHERE UNITY_Invoice__c IN:invids GROUP BY UNITY_Invoice__c];
            
             for(AggregateResult ar:groupedResults) {
                Id invid = (ID)ar.get('UNITY_Invoice__c');
                Integer count = (Integer)ar.get('expr0');
                
                system.debug('#### neli Travel  invid  ###' + invid);
                
                system.debug('####   neli Travel count  ###' + count);
                
                UNITY_Invoice__c invoice = new UNITY_Invoice__c(Id=invid);
                invoice.Number_of_Travel_Lines__c =count;
                
                system.debug('#### neli Travel invoice.UNITYPM_Number_of_Assets__c  ###' + invoice.Number_of_Travel_Lines__c);
                
                invoiceUpdate.add(invoice);
           }
           
            system.debug('####   neli Travel invoiceUpdate.size()  ###' + invoiceUpdate.size());
            if (invoiceUpdate.size()>0)
               update invoiceUpdate;
         }
    }
    
    public static void updateInvoicePartLineCount(List<UNITY_Invoice_Line_Item__c> invLines){
         if(!invLines.isEmpty()){
            system.debug('####  neli  updateInvoicePartLineCount  ###');
            System.debug('##### neli Part  invLines.size(): ' + invLines.size());
             
            Set<Id> invids = new Set<Id>();
            
             for(UNITY_Invoice_Line_Item__c line :invLines){
                invids.add(line.UNITY_Invoice__c);
            }
            
             system.debug('####  neli  updateInvoicePartLineCount invids  ###' + invids);
             
            List<UNITY_Invoice__c> invoiceUpdate = new List<UNITY_Invoice__c>();
            AggregateResult[] groupedResults = [SELECT Count(ID),UNITY_Invoice__c  FROM UNITY_Invoice_Line_Item__c WHERE UNITY_Invoice__c IN:invids GROUP BY UNITY_Invoice__c];
            
             for(AggregateResult ar:groupedResults) {
                Id invid = (ID)ar.get('UNITY_Invoice__c');
                Integer count = (Integer)ar.get('expr0');
                
                system.debug('#### neli Part  invid  ###' + invid);
                
                system.debug('####   neli Part count  ###' + count);
                
                UNITY_Invoice__c invoice = new UNITY_Invoice__c(Id=invid);
               invoice.Number_of_Part_Lines__c =count;
                
               system.debug('#### neli ALL invoice.Number_of_Part_Lines__c  ###' + invoice.Number_of_Part_Lines__c);
                
                invoiceUpdate.add(invoice);
           }
           
            system.debug('####   neli part count invoiceUpdate.size()  ###' + invoiceUpdate.size());
            if (invoiceUpdate.size()>0)
               update invoiceUpdate;
         }
    }
    
    //===================================================================================================================================
    public static void setGLValues(List<UNITY_Invoice_Line_Item__c> invLines){
        System.debug('##### On setGLValues');
        if(!invLines.isEmpty()){
            System.debug('##### invLines.size(): ' + invLines.size());

            Set<Id> invids = new Set<Id>();
            for(UNITY_Invoice_Line_Item__c line :invLines){
                invids.add(line.UNITY_Invoice__c);
            }
            Map<Id,UNITY_Invoice__c> invMap = new Map<Id,UNITY_Invoice__c>([SELECT Id,UNITY_Order_Type__c,UNITY_Agent__r.UNITY_Segment__c FROM UNITY_Invoice__c WHERE Id IN: invids]);
            Set<String> oTypes = new Set<String>();
            for(UNITY_Invoice__c inv :invMap.values()){
                oTypes.add(inv.UNITY_Order_Type__c);
            }
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
            List<UNITY_GL_Segment_Account__c> segAccounts = [SELECT Id,Name,UNITY_Segment__c,UNITY_Seg_Account_Number__c 
                                                         FROM UNITY_GL_Segment_Account__c];
            Map<String,String> segsMap = new Map<String,String>();
            for(UNITY_GL_Segment_Account__c seg :segAccounts){
                if(!segsMap.containsKey(seg.UNITY_Segment__c)){
                    segsMap.put(seg.UNITY_Segment__c,seg.UNITY_Seg_Account_Number__c);
                    System.debug('### seg.UNITY_Segment__c: ' + seg.UNITY_Segment__c);
                }
                    
            }
            List<UNITY_GL_Sub_Account__c> subAccounts = [SELECT Id,Name,UNITY_Sub_Account__c,UNITY_GL_Sub_Account_Number__c 
                                                         FROM UNITY_GL_Sub_Account__c WHERE UNITY_Sub_Account__c IN :oTypes];
            Map<String,String> subsMap = new Map<String,String>();
            for(UNITY_GL_Sub_Account__c sub :subAccounts){
                if(!subsMap.containsKey(sub.UNITY_Sub_Account__c)){
                    subsMap.put(sub.UNITY_Sub_Account__c,sub.UNITY_GL_Sub_Account_Number__c);
                    System.debug('### sub.UNITY_Sub_Account__c: ' + sub.UNITY_Sub_Account__c);
                }
                    
            }
            //Now, I need to find a match for per order line to populate the credit account
            for(UNITY_Invoice_Line_Item__c line :invLines){
                Boolean updated = false;
                Boolean isError = false;
                String otype =  invMap.get(line.UNITY_Invoice__c).UNITY_Order_Type__c;
                String segment = invMap.get(line.UNITY_Invoice__c).UNITY_Agent__r.UNITY_Segment__c;
                System.debug('##### order type: ' + otype);
                if(String.isBlank(line.UNITY_GL_Sub_Account__c)|| String.isBlank(line.UNITY_GL_Revenue_Account__c)|| String.isBlank(line.UNITY_GL_Tax_Account__c)){
                    if(invMap.containsKey(line.UNITY_Invoice__c)){
                        System.debug('##### invMap.contains(UNITY_Invoice__c):' + invMap.containsKey(line.UNITY_Invoice__c));
                        if(glmMap.containsKey(otype)){
                            if(glmMap.get(otype).containsKey(line.UNITY_Type__c)){
                                if(glmMap.get(otype).get(line.UNITY_Type__c).containsKey(line.UNITY_Activity_Type__c)){
                                    System.debug('##### order type: ' + otype);
                                    line.UNITY_GL_Revenue_Account__c = glmMap.get(otype).get(line.UNITY_Type__c).get(line.UNITY_Activity_Type__c).UNITY_Revenue_Account__c;
                                    
                                    line.UNITY_GL_Tax_Account__c = glmMap.get(otype).get(line.UNITY_Type__c).get(line.UNITY_Activity_Type__c).UNITY_Tax_Account__c;
                                }//End contains activity type
                            }//End contains line type
                        }//ENd contains order type
                    }
                    if(String.isNotBlank(otype)){
                        System.debug('### inv.UNITY_Order_Type__c: ' + otype);
                        String subAcct = '';
                        Boolean err = false;
                        if(subsMap.containsKey(otype)){
                            subAcct += subsMap.get(otype);
                            System.debug('### subAcct: ' + line.UNITY_GL_Sub_Account__c);
                        }else{
                            err = true;
                        }
                        if(segsMap.containsKey(segment)){
                            subAcct += segsMap.get(segment);
                            System.debug('### inv.UNITY_GL_Sub_Account__c: ' + line.UNITY_GL_Sub_Account__c);
                        }else{
                            err = true;
                        }
                        if(!err){
                            line.UNITY_GL_Sub_Account__c = subAcct;
                        }else{
                            line.UNITY_GL_Sub_Account__c = '';
                        }
                    }
                }//End if GL Credit Account is Blank
            }//ENd for Line
        }//End if oItemIds is Not Blank
    }
}