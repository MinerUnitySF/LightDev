/**UNITY_CallAvatax
 * @description: This class handles the integration with 
 * @programer:   Izay Ramos-Irizarry
 *
 * Functionalities
 * - Callout to Avatax to get tax on POs, Quotes, and Invoices
 * ========================================================================
 * Changelog
 * ========================================================================
 * @description: Fixed bug with invoice tax code association and tax code exceptions.
 * @programmer:  Izay Ramos-Irizarry
 * @date:        10/20/2016
 */
global with sharing class UNITY_CallAvatax {

    //##############################################
    /**Query used across multiple methods consolidated for ease of maintenance.
     * @param recordIds 
     */
    //##############################################
    private static List<Order> orderQuery( Set<Id> recordIds ) {
        return [SELECT Id, 
                    OrderNumber, 
                    FSO__WorkOrder__c, 
                    UNITY_Work_Order_Type__c,
                    UNITY_Tax_Process_Result__c,
                    UNITY_Total_Amount__c,
                    UNITY_Final_Price__c,
                    UNITY_Line_Item_Discounted_Price__c,

                    UNITY_Customer__c,
                    UNITY_Customer__r.MH_SL_CustID__c, 
                    UNITY_Customer__r.UNITY_Bill_to_Account__r.MH_SL_CustID__c, 
                    UNITY_Customer__r.UNITY_Tax_Exempt__c,
                    UNITY_Customer__r.UNITY_Bill_To_Account__r.UNITY_Tax_Exempt__c,

                    AccountId,
                    Account.BillingStreet,
                    Account.BillingCity,
                    Account.BillingStateCode,
                    Account.BillingPostalCode,
                    Account.ShippingStreet,
                    Account.ShippingCity,
                    Account.ShippingStateCode,
                    Account.ShippingPostalCode,
                    Account.UNITY_Tax_Exempt__c,
                    Account.MH_SL_CustID__c,
                    Account.MSPFS_MSP_Bill_to_Self__c,
                    Account.MSPFS_MSP_Bill_to_Account__r.MH_SL_CustID__c,
                    Account.MSPFS_MSP_Bill_to_Account__r.UNITY_Tax_Exempt__c,
                	Account.UNITY_Bill_to_Self__c,
                    Account.UNITY_Bill_To_Account__c,
                    Account.UNITY_Bill_To_Account__r.MH_SL_CustID__c,
                    Account.UNITY_Bill_To_Account__r.UNITY_Tax_Exempt__c,
                    Account.UNITY_Bill_To_Account__r.BillingStreet,
                    Account.UNITY_Bill_To_Account__r.BillingCity,
                    Account.UNITY_Bill_To_Account__r.BillingStateCode,

                    UNITY_Business_Unit_Account__c,
                	UNITY_Business_Unit_Account__r.MSPFS_Is_MSP_BU__c,
                    UNITY_Business_Unit_Account__r.UNITY_Bill_to_Self__c,
                    UNITY_Business_Unit_Account__r.UNITY_Company_Code__c,
                    UNITY_Business_Unit_Account__r.BillingStreet,
                    UNITY_Business_Unit_Account__r.BillingCity,
                    UNITY_Business_Unit_Account__r.BillingStateCode,
                    UNITY_Business_Unit_Account__r.BillingPostalCode
                
                FROM Order 
                WHERE Id IN :recordIds];
    }

    //##############################################
    /**Query used across multiple methods consolidated for ease of maintenance.
     * @param recordIds 
     */
    //##############################################
    private static Account customerQuery( Id recordId ) {
        return [SELECT Id,
                    Name,
                    BillingStreet,
                    BillingCity,
                    BillingStateCode,
                    BillingPostalCode,
                    ShippingStreet,
                    ShippingCity,
                    ShippingStateCode,
                    ShippingPostalCode,
                    
                    MH_SL_CustID__c,
                    
                    UNITY_Tax_Exempt__c,

                    UNITY_Bill_to_Account__c,
                    UNITY_Bill_to_Account__r.MH_SL_CustID__c,
                    UNITY_Bill_to_Account__r.UNITY_Tax_Exempt__c
                FROM Account 
                WHERE Id = :recordId LIMIT 1];
    }

    //##############################################
    /**This method gets the tax for po lines
     * @param recordIds List<Id>: The po line ids
     */
    //##############################################
    global static UNITY_CallAvatax.AvataxResult getTaxPO(Set<Id> recordIds){ 
        System.debug('##### getting PO Tax...');
        Boolean success = false;
        String message = '';
        Decimal totalTax = 0;
        UNITY_CallAvatax.AvataxResult result;
        //Get the avatax auth values
        List<Key_Value_Store__c> kvslist = new List<Key_Value_Store__c>();
        kvslist = [SELECT Id,Name,Value__c FROM Key_Value_Store__c];
        String user = '';
        String pass = '';
        for(Key_Value_Store__c kvsindex : kvslist){
            if (kvsindex.Name.toLowerCase() == 'avatax account id')
                user = kvsindex.Value__c;
            if (kvsindex.Name.toLowerCase() == 'avatax license key')
                pass = kvsindex.Value__c;
        }
        //Map to hold Order Line by Order Id
        MaP<Id,List<OrderItem>> oLinesMap = new Map<Id,List<OrderItem>>();
        //List to hold POs
        List<Order> orders = new List<Order>();
        //Now, Need to query order and/or quote records
        System.debug('#####Izay: In UNITY_CallAvatax.getTaxPO()');
        System.debug('#####Izay: recordIds.size() = ' + recordIds.size());
        if(recordIds.size() > 0){
            orders = orderQuery( recordIds );
            //Get the order line records
            List<OrderItem> oLines = [SELECT Id,OrderId,OrderItemNumber,Quantity,UnitPrice,UNITY_Cost_Plus__c,UNITY_Actual_Quantity__c,UNITY_Customer_Adjusted_Quantity__c,
                                      UNITY_Price__c,UNITY_Sales_Tax__c,UNITY_Vendor_Adjusted_Quantity__c,UNITY_Tax_Code__c,UNITY_Type__c,UNITY_Activity_Type__c,UNITY_Discounted_Price__c 
                                      FROM OrderItem WHERE OrderId IN :recordIds
                                      AND PriceBookEntry.Product2.Name != 'Vendor Service Fee'
                                      AND UNITY_Not_Billable__c = FALSE];
            //Add the order line records to the order lines map
            for(OrderItem oLine : oLines){
                if(!oLinesMap.containsKey(oLine.OrderId)){
                    List<OrderItem> temp = new List<OrderItem>();
                    temp.add(oLine);
                    oLinesMap.put(oLine.OrderId,temp);
                }else{
                    oLinesMap.get(oLine.OrderId).add(oLine);
                }
            }
        }
        //If there are work orders to get tax for...
        if ( orders.size() > 0 ) {
            //Begin constructing the avatax callout payload
            avataxAvalaraComServicesAlt.TaxSvcAltSecSoap taxSvc = new avataxAvalaraComServicesAlt.TaxSvcAltSecSoap();
            taxSvc.Security = new avataxAvalaraComServicesAlt.Security();
            taxSvc.Security.UsernameToken = new avataxAvalaraComServicesAlt.UsernameToken_element();
            taxSvc.Security.UsernameToken.Username = user;
            taxSvc.Security.UsernameToken.Password = pass;
            taxSvc.Profile = new avataxAvalaraComServicesAlt.Profile();
            taxSvc.Profile.Name = '1.0.0';
            taxSvc.Profile.Client = 'My Application Name,1.0';
            taxSvc.Profile.Machine = 'My Machine Name';
            for ( Order o : orders ) {
                //String custId = String.isNotBlank(o.UNITY_Customer__r.MH_SL_CustID__c) ? o.UNITY_Customer__r.MH_SL_CustID__c : o.UNITY_Customer__r.UNITY_Bill_to_Account__r.MH_SL_CustID__c;
                String custId;
                String exemptString;
                if ( o.UNITY_Customer__c!=null && o.AccountId!=null && o.UNITY_Customer__c == o.AccountId ) {
                    if ( o.Account.MSPFS_MSP_Bill_to_Self__c || o.Account.UNITY_Bill_to_Self__c ) {
                        custId = o.Account.MH_SL_CustID__c;
                        exemptString = ( o.Account.UNITY_Tax_Exempt__c ) ? 'Exempt' : '';
                    } else if ( o.UNITY_Business_Unit_Account__r.MSPFS_Is_MSP_BU__c ) {
                        custId = o.Account.MSPFS_MSP_Bill_To_Account__r.MH_SL_CustID__c;
                        exemptString = ( o.Account.MSPFS_MSP_Bill_To_Account__r.UNITY_Tax_Exempt__c ) ? 'Exempt' : '';
                    } else {
                        custId = o.Account.UNITY_Bill_To_Account__r.MH_SL_CustID__c;
                        exemptString = ( o.Account.UNITY_Bill_To_Account__r.UNITY_Tax_Exempt__c ) ? 'Exempt' : '';
                    }
                } else {
                    custId = o.UNITY_Customer__r.MH_SL_CustID__c;
                    exemptString = ( o.UNITY_Customer__r.UNITY_Tax_Exempt__c ) ? 'Exempt' : '';
                }

                Decimal discount = (o.UNITY_Line_Item_Discounted_Price__c != null && o.UNITY_Final_Price__c != null) ? (o.UNITY_Line_Item_Discounted_Price__c - o.UNITY_Final_Price__c) : 0;
                //Build the tax request for the order
                avataxAvalaraComServicesAlt.GetTaxRequest gtreq = new avataxAvalaraComServicesAlt.GetTaxRequest();
                gtreq.CustomerCode = custId;
                gtreq.ExemptionNo = exemptString;
                //gtreq.ExemptionNo = (o.UNITY_Customer__r.UNITY_Tax_Exempt__c) ? 'Exempt' :(o.UNITY_Customer__r.UNITY_Bill_To_Account__r.UNITY_Tax_Exempt__c ? 'Exempt' : '');
                gtreq.DocType = 'SalesOrder';
                gtreq.CompanyCode = o.UNITY_Business_Unit_Account__r.UNITY_Company_Code__c;//Business Unit company code
                gtreq.Discount = discount; 
                gtreq.DetailLevel = 'Tax';
                gtreq.HashCode = 0;
                gtreq.ServiceMode = 'Automatic';
                gtreq.ExchangeRate = 0;
                gtreq.ExchangeRateEffDate = date.today();
                gtreq.PaymentDate = date.today(); 
                //Now Need to add the addresses
                //Origni Address (The Business Unity performing the work/sale)
                avataxAvalaraComServicesAlt.BaseAddress orgAddr = new avataxAvalaraComServicesAlt.BaseAddress();
                orgAddr.AddressCode = 'Origin';
                orgAddr.Line1 = o.UNITY_Business_Unit_Account__r.BillingStreet;//***BU BillingStreet***
                orgAddr.City = o.UNITY_Business_Unit_Account__r.BillingCity;//***BU BillingCity***
                orgAddr.Region = o.UNITY_Business_Unit_Account__r.BillingStateCode;//***BU BillingStateCode***
                orgAddr.PostalCode = o.UNITY_Business_Unit_Account__r.BillingPostalCode;//***BU BillingPostalCode***
                orgAddr.TaxRegionId = 0;
                avataxAvalaraComServicesAlt.BaseAddress dstAddr = new avataxAvalaraComServicesAlt.BaseAddress();
                //Destination Address (The Location Shipping Address)
                dstAddr.AddressCode = 'Destination';
                dstAddr.Line1 = o.Account.ShippingStreet;//'11827 Tech Com Dr #116'; 
                dstAddr.City = o.Account.ShippingCity;//'San Antonio'; 
                dstAddr.Region = o.Account.ShippingStateCode;//'TX'; 
                dstAddr.PostalCode = o.Account.ShippingPostalCode;//'78233'; 
                dstAddr.TaxRegionId = 0;
                //Add the addresses to the tax request
                gtreq.Addresses = new avataxAvalaraComServicesAlt.ArrayOfBaseAddress();
                gtreq.Addresses.BaseAddress = new avataxAvalaraComServicesAlt.BaseAddress[2];
                gtreq.Addresses.BaseAddress[0] = orgAddr;
                gtreq.Addresses.BaseAddress[1] = dstAddr;
                //Set the address codes on the tax request
                gtreq.OriginCode = orgAddr.AddressCode;
                gtreq.DestinationCode = dstAddr.AddressCode;
                //Now Need to add tyhe line items
                gtreq.Lines = new avataxAvalaraComServicesAlt.ArrayOfLine();
                if(oLinesMap.containsKey(o.Id)){
                    gtreq.Lines.Line = new avataxAvalaraComServicesAlt.Line[oLinesMap.get(o.Id).size()];
                    //Get the tax code for the order lines
                    //List<Id> oids = new List<Id>();
                    //oids.add(o.Id);
                    List<OrderItem> oLines = getTaxCodePO(o,oLinesMap.get(o.Id));
                    System.debug('================== oLines.size(): ' + oLines.size());
                    Map<String, OrderItem> itemsMap = new Map<String, OrderItem>();
                    for(Integer i = 0; i < oLines.size(); i++){
                        //Get the order item
                        OrderItem item = oLines[i];
                        //Add the item to the items map
                        itemsMap.put(item.OrderItemNumber,item);
                        //Create the line for the tax request
                        gtreq.Lines.Line[i] = new avataxAvalaraComServicesAlt.Line();
                        gtreq.Lines.Line[i].No = item.OrderItemNumber;
                        gtreq.Lines.Line[i].Amount = (item.UNITY_Discounted_Price__c != null) ? item.UNITY_Discounted_Price__c : item.UNITY_Price__c;
                        gtreq.Lines.Line[i].Qty = (item.UNITY_Customer_Adjusted_Quantity__c != null) ? item.UNITY_Customer_Adjusted_Quantity__c : 0;
                        gtreq.Lines.Line[i].Discounted = (discount > 0);
                        gtreq.Lines.Line[i].OriginCode = 'Origin';
                        gtreq.Lines.Line[i].DestinationCode = 'Destination';
                        gtreq.Lines.Line[i].TaxCode = item.UNITY_Tax_Code__c;
                    }
                    gtreq.DocDate = Date.Today();
                    gtreq.Commit_x=false;
                    //Set the tax result
                    avataxAvalaraComServicesAlt.GetTaxResult gtres = null;
                    //Try to make the call to avatax
                    try{
                        //System.debug('====== JSON Request: ' + JSON.serializePretty(gtreq));
                        gtres = taxSvc.GetTax(gtreq);
                        System.debug('====== JSON Result: ' + JSON.serializePretty(gtres));
                        if(gtres.ResultCode == 'Success'){
                            success = true;
                            totalTax = gtres.TotalTax;
                            totalTax = totalTax.setScale(2,System.RoundingMode.HALF_DOWN);
                            message = 'Result Code: '+gtres.ResultCode + '\n' +
                                'Total Tax: $' + totalTax + '\n' +  
                                'Total Amount: $' + gtres.TotalAmount + '\n' +
                                'Total Discount: $' + gtres.TotalDiscount + '\n';
                                if(!Test.isRunningTest())
                                    message += 'Tax Addeses: Site/Location: ' + gtres.TaxAddresses.TaxAddress[0].Region + ', BU:  ' + gtres.TaxAddresses.TaxAddress[1].Region;
                            //system.debug('sampleresult:' + gtres.TotalTax);
                            if(gtres.TaxLines != null){
                                if(gtres.TaxLines.TaxLine != null){
                                    message += '\nTax Rate: ' + gtres.TaxLines.TaxLine[0].Rate;
                                    List<OrderItem> itemsList = new List<OrderItem>();
                                    for(avataxavalaraComServicesAlt.TaxLine tl : gtres.TaxLines.TaxLine){
                                        if(itemsMap.containsKey(tl.No)){
                                            itemsMap.get(tl.No).UNITY_Sales_Tax__c = tl.Tax.setScale(2,System.RoundingMode.HALF_DOWN);
                                            itemsList.add(itemsMap.get(tl.No));
                                        }
                                    }
                                    update itemsList;
                                }
                            }
                        }else{
                            success = false;
                            message =  'Result Code: '+gtres.ResultCode + '\n';
                            message += 'Summary: ' + ((gtres.Messages != null) ? gtres.Messages.Message[0].Summary : 'Not available')+'\n';
                            message += 'Details: '+((gtres.Messages != null) ? gtres.Messages.Message[0].Details: 'Not available')+'\n';
                            message += 'Refers To: '+((gtres.Messages != null) ? gtres.Messages.Message[0].RefersTo: 'Not available')+'\n';
                            message += 'Source: '+((gtres.Messages != null) ? gtres.Messages.Message[0].Source: 'Not available');
                        }
                        o.UNITY_Tax_Processed__c = true;
                        o.UNITY_Tax_Process_Result__c = message;
                    }catch(Exception ex){
                        success = false;
                        message = 'GetTax Threw an Exception: ' + ex.getmessage();
                        System.debug('================== ' + message);
                    }
                }
            }
            update orders;
        }
        result = new UNITY_CallAvatax.AvataxResult(success,message,totalTax);
        return result;
    }

    global static UNITY_CallAvatax.AvataxResult getServiceChargeTax( Id locId, Id buId, Id custId, Decimal amount ){
        UNITY_CallAvatax.AvataxResult result;
        //Get the avatax auth values
        List<Key_Value_Store__c> kvslist = new List<Key_Value_Store__c>();
        kvslist = [SELECT Id,Name,Value__c FROM Key_Value_Store__c];
        String user = '';
        String pass = '';
        String message = '';
        Boolean success = false;
        Decimal totalTax = 0;
        for(Key_Value_Store__c kvsindex : kvslist){
            if (kvsindex.Name.toLowerCase() == 'avatax account id')
                user = kvsindex.Value__c;
            if (kvsindex.Name.toLowerCase() == 'avatax license key')
                pass = kvsindex.Value__c;
        }
        //Begin constructing the avatax callout payload
        avataxAvalaraComServicesAlt.TaxSvcAltSecSoap taxSvc = new avataxAvalaraComServicesAlt.TaxSvcAltSecSoap();
        taxSvc.Security = new avataxAvalaraComServicesAlt.Security();
        taxSvc.Security.UsernameToken = new avataxAvalaraComServicesAlt.UsernameToken_element();
        taxSvc.Security.UsernameToken.Username = user;
        taxSvc.Security.UsernameToken.Password = pass;
        taxSvc.Profile = new avataxAvalaraComServicesAlt.Profile();
        taxSvc.Profile.Name = '1.0.0';
        taxSvc.Profile.Client = 'My Application Name,1.0';
        taxSvc.Profile.Machine = 'My Machine Name';
        Account bu = [SELECT Id,Name,UNITY_Company_Code__c,BillingStreet,BillingCity,BillingStateCode,BillingPostalCode FROM Account WHERE Id = :buId LIMIT 1];
        Account loc = [SELECT Id,Name,BillingStreet,BillingCity,BillingStateCode,BillingPostalCode,ShippingStreet,ShippingCity,ShippingStateCode,ShippingPostalCode,
                       UNITY_Bill_to_Account__c,MH_SL_CustID__c,UNITY_Bill_to_Account__r.MH_SL_CustID__c,UNITY_Tax_Exempt__c,UNITY_Bill_to_Account__r.UNITY_Tax_Exempt__c
                       FROM Account WHERE Id = :locId LIMIT 1];
        Account cust;
        if(custId != null){
            cust = [SELECT Id,Name,BillingStreet,BillingCity,BillingStateCode,BillingPostalCode,ShippingStreet,ShippingCity,ShippingStateCode,ShippingPostalCode,
                    UNITY_Bill_to_Account__c,MH_SL_CustID__c,UNITY_Bill_to_Account__r.MH_SL_CustID__c,UNITY_Tax_Exempt__c,UNITY_Bill_to_Account__r.UNITY_Tax_Exempt__c
                    FROM Account WHERE Id = :custId LIMIT 1];
        }

        String slCustId = (cust != null) ? (String.isNotBlank(cust.MH_SL_CustID__c) ? cust.MH_SL_CustID__c : loc.UNITY_Bill_to_Account__r.MH_SL_CustID__c) : loc.UNITY_Bill_to_Account__r.MH_SL_CustID__c;
        Boolean exempt = (cust != null) ? (cust.UNITY_Tax_Exempt__c ? cust.UNITY_Tax_Exempt__c : loc.UNITY_Bill_to_Account__r.UNITY_Tax_Exempt__c) : loc.UNITY_Bill_to_Account__r.UNITY_Tax_Exempt__c;
        //Build the tax request for the order
        avataxAvalaraComServicesAlt.GetTaxRequest gtreq = new avataxAvalaraComServicesAlt.GetTaxRequest();
        gtreq.CustomerCode = slCustId;
        gtreq.ExemptionNo = (exempt)?'Exempt':'';
        gtreq.DocType = 'SalesOrder';
        gtreq.CompanyCode = bu.UNITY_Company_Code__c;//Business Unit company code
        gtreq.Discount = 0; 
        gtreq.DetailLevel = 'Tax';
        gtreq.HashCode = 0;
        gtreq.ServiceMode = 'Automatic';
        gtreq.ExchangeRate = 0;
        gtreq.ExchangeRateEffDate = date.today();
        gtreq.PaymentDate = date.today(); 
        //Now Need to add the addresses
        //Origni Address (The Business Unity performing the work/sale)
        avataxAvalaraComServicesAlt.BaseAddress orgAddr = new avataxAvalaraComServicesAlt.BaseAddress();
        orgAddr.AddressCode = 'Origin';
        orgAddr.Line1 = bu.BillingStreet;//***BU BillingStreet***
        orgAddr.City = bu.BillingCity;//***BU BillingCity***
        orgAddr.Region = bu.BillingStateCode;//***BU BillingStateCode***
        orgAddr.PostalCode = bu.BillingPostalCode;//***BU BillingPostalCode***
        orgAddr.TaxRegionId = 0;
        avataxAvalaraComServicesAlt.BaseAddress dstAddr = new avataxAvalaraComServicesAlt.BaseAddress();
        //Destination Address (The Location Shipping Address)
        dstAddr.AddressCode = 'Destination';
        dstAddr.Line1 = loc.ShippingStreet;//'11827 Tech Com Dr #116'; 
        dstAddr.City = loc.ShippingCity;//'San Antonio'; 
        dstAddr.Region = loc.ShippingStateCode;//'TX'; 
        dstAddr.PostalCode = loc.ShippingPostalCode;//'78233'; 
        dstAddr.TaxRegionId = 0;
        //Add the addresses to the tax request
        gtreq.Addresses = new avataxAvalaraComServicesAlt.ArrayOfBaseAddress();
        gtreq.Addresses.BaseAddress = new avataxAvalaraComServicesAlt.BaseAddress[2];
        gtreq.Addresses.BaseAddress[0] = orgAddr;
        gtreq.Addresses.BaseAddress[1] = dstAddr;
        //Set the address codes on the tax request
        gtreq.OriginCode = orgAddr.AddressCode;
        gtreq.DestinationCode = dstAddr.AddressCode;
        //Now Need to add tyhe line items
        gtreq.Lines = new avataxAvalaraComServicesAlt.ArrayOfLine();
        gtreq.Lines.Line = new avataxAvalaraComServicesAlt.Line[1];
        //Get the tax code for the order lines
        //Create the line for the tax request
        gtreq.Lines.Line[0] = new avataxAvalaraComServicesAlt.Line();
        gtreq.Lines.Line[0].No = 'ServiceCharge';
        gtreq.Lines.Line[0].Amount = amount;
        gtreq.Lines.Line[0].Qty = 1;
        gtreq.Lines.Line[0].Discounted = false;
        gtreq.Lines.Line[0].OriginCode = 'Origin';
        gtreq.Lines.Line[0].DestinationCode = 'Destination';
        gtreq.Lines.Line[0].TaxCode = 'S0000001';
        
        gtreq.DocDate = Date.Today();
        gtreq.Commit_x=false;
        //Set the tax result
        avataxAvalaraComServicesAlt.GetTaxResult gtres = null;
        //Try to make the call to avatax
        try{
            //System.debug('====== JSON Request: ' + JSON.serializePretty(gtreq));
            gtres = taxSvc.GetTax(gtreq);
            System.debug('====== JSON Result: ' + JSON.serializePretty(gtres));
            if(gtres.ResultCode == 'Success'){
                success = true;
                totalTax = gtres.TotalTax;
                totalTax = totalTax.setScale(2,System.RoundingMode.HALF_DOWN);
                message = 'Result Code: '+gtres.ResultCode + '\n' +
                    'Total Tax: $' + totalTax + '\n' +  
                    'Total Amount: $' + gtres.TotalAmount + '\n' +
                    'Total Discount: $' + gtres.TotalDiscount + '\n';
                if(!Test.isRunningTest())
                    message += 'Tax Addeses: Site/Location: ' + gtres.TaxAddresses.TaxAddress[0].Region + ', BU:  ' + gtres.TaxAddresses.TaxAddress[1].Region;
            }else{
                success = false;
                message =  'Result Code: '+gtres.ResultCode + '\n';
                message += 'Summary: ' + ((gtres.Messages != null) ? gtres.Messages.Message[0].Summary : 'Not available')+'\n';
                message += 'Details: '+((gtres.Messages != null) ? gtres.Messages.Message[0].Details: 'Not available')+'\n';
                message += 'Refers To: '+((gtres.Messages != null) ? gtres.Messages.Message[0].RefersTo: 'Not available')+'\n';
                message += 'Source: '+((gtres.Messages != null) ? gtres.Messages.Message[0].Source: 'Not available');
            }
        }catch(Exception ex){
            success = false;
            message = 'GetTax Threw an Exception: ' + ex.getmessage();
            System.debug('================== ' + message);
        }
        result = new UNITY_CallAvatax.AvataxResult(success,message,totalTax);
        return result;
    }

    //##############################################
    /**This method gets the tax for quote lines
     * @param recordIds List<Id>: The quote or quote line ids
     * @param enitty String: Defines the type of ids beinf passed to the method. 'lines' or 'quote'
     */
    //##############################################
    global static UNITY_CallAvatax.AvataxResult getTaxQuote(List<Id> recordIds,String entity){
        UNITY_Constants.isExecutingContext.put('UNITY_CallAvatax.getTaxQuote',true);
        Boolean success = false;
        String message = '';
        Decimal totalTax = 0;
        UNITY_CallAvatax.AvataxResult result;
        //Get the avatax auth values
        List<Key_Value_Store__c> kvslist = new List<Key_Value_Store__c>();
        kvslist = [SELECT Id,Name,Value__c FROM Key_Value_Store__c];
        String user = '';
        String pass = '';
        for(Key_Value_Store__c kvsindex : kvslist){
            if (kvsindex.Name.toLowerCase() == 'avatax account id')
                user = kvsindex.Value__c;
            if (kvsindex.Name.toLowerCase() == 'avatax license key')
                pass = kvsindex.Value__c;
        }
        //Map to hold Quote Line by Quote ID
        Map<Id,List<UNITY_Proposal_Line_Item__c>> qLinesMap = new Map<Id,List<UNITY_Proposal_Line_Item__c>>();
        List<UNITY_Proposal__c> quotes = new List<UNITY_Proposal__c>();
        //Now, Need to query order and/or quote records
        if(recordIds.size() > 0){
            //List to hold Quote Lines
            List<UNITY_Proposal_Line_Item__c> allQLines = new List<UNITY_Proposal_Line_Item__c>();
            if(entity == 'lines'){
                allQLines = [SELECT Id,Name,UNITY_Proposal__c,UNITY_Quantity__c,UNITY_Total_Price__c,UNITY_Cost_Plus__c,UNITY_Available_Quantity__c,UNITY_Customer_Adjusted_Quantity__c,
                             UNITY_Price__c,UNITY_Sales_Tax__c,UNITY_Vendor_Adjusted_Quantity__c,UNITY_Tax_Code__c,UNITY_Type__c,UNITY_Activity_Type__c,UNITY_Discount__c,UNITY_Discounted_Price__c
                             FROM UNITY_Proposal_Line_Item__c WHERE Id IN : recordIds AND UNITY_Not_Billable__c = FALSE];
            }else{
                allQLines = [SELECT Id,Name,UNITY_Proposal__c,UNITY_Quantity__c,UNITY_Total_Price__c,UNITY_Cost_Plus__c,UNITY_Available_Quantity__c,UNITY_Customer_Adjusted_Quantity__c,
                             UNITY_Price__c,UNITY_Sales_Tax__c,UNITY_Vendor_Adjusted_Quantity__c,UNITY_Tax_Code__c,UNITY_Type__c,UNITY_Activity_Type__c,UNITY_Discount__c,UNITY_Discounted_Price__c
                             FROM UNITY_Proposal_Line_Item__c WHERE UNITY_Proposal__c IN : recordIds AND UNITY_Not_Billable__c = FALSE];
            }
                
            //Place quote lines in lines map
            for(UNITY_Proposal_Line_Item__c qLine: allQLines){
                if(!qLinesMap.containsKey(qLine.UNITY_Proposal__c)){
                    List<UNITY_Proposal_Line_Item__c> temp = new List<UNITY_Proposal_Line_Item__c>();
                    temp.add(qLine);
                    qLinesMap.put(qLine.UNITY_Proposal__c,temp);
                }else{
                    qLinesMap.get(qLine.UNITY_Proposal__c).add(qLine);
                }
            }
            //Now need to get the quote record for all lines
            quotes = [SELECT Id,Name,UNITY_Account__c,UNITY_Customer__c,UNITY_Customer__r.MH_SL_CustID__c,UNITY_Customer__r.UNITY_Tax_Exempt__c,
                      UNITY_Account__r.ShippingStreet,UNITY_Account__r.ShippingCity,UNITY_Account__r.ShippingStateCode,UNITY_Account__r.ShippingPostalCode,
                      UNITY_Account__r.UNITY_Bill_To_Account__r.UNITY_Tax_Exempt__c,
                      UNITY_Account__r.UNITY_Bill_To_Account__r.MH_SL_CustID__c,
                      UNITY_Account__r.MH_SL_CustID__c,
                      UNITY_Account__r.UNITY_Tax_Exempt__c,
                      UNITY_Account__r.MSPFS_MSP_Bill_to_Self__c,
                      UNITY_Account__r.UNITY_Bill_to_Self__c,
                      UNITY_Account__r.MSPFS_MSP_Bill_To_Account__r.MH_SL_CustID__c,
                      UNITY_Account__r.MSPFS_MSP_Bill_To_Account__r.UNITY_Tax_Exempt__c,
                      UNITY_Business_Unit_Account__r.MSPFS_Is_MSP_BU__c,
                      UNITY_Master_Quote__c,UNITY_Master_Quote__r.UNITY_Service_Charge__c,UNITY_Master_Quote__r.UNITY_Service_Charge_Tax__c,
                      UNITY_Business_Unit_Account__c,UNITY_Business_Unit_Account__r.UNITY_Company_Code__c,
                      UNITY_Business_Unit_Account__r.BillingStreet,UNITY_Business_Unit_Account__r.BillingCity,UNITY_Business_Unit_Account__r.BillingStateCode,UNITY_Business_Unit_Account__r.BillingPostalCode,
                      UNITY_Work_Order_Type__c,UNITY_Line_Item_Discounted_Price__c,UNITY_Final_Price2__c
                      FROM UNITY_Proposal__c WHERE Id IN :qLinesMap.keySet()];
        }
        //If there are work orders to get tax for...
        if(quotes.size() > 0){
            //Begin constructing the avatax callout payload
            avataxAvalaraComServicesAlt.TaxSvcAltSecSoap taxSvc = new avataxAvalaraComServicesAlt.TaxSvcAltSecSoap();
            taxSvc.Security = new avataxAvalaraComServicesAlt.Security();
            taxSvc.Security.UsernameToken = new avataxAvalaraComServicesAlt.UsernameToken_element();
            taxSvc.Security.UsernameToken.Username = user;
            taxSvc.Security.UsernameToken.Password = pass;
            taxSvc.Profile = new avataxAvalaraComServicesAlt.Profile();
            taxSvc.Profile.Name = '1.0.0';
            taxSvc.Profile.Client = 'My Application Name,1.0';
            taxSvc.Profile.Machine = 'My Machine Name';
            for(UNITY_Proposal__c q :quotes){
                //Build the tax request for the order
                //String custCode = String.isNotBlank(q.UNITY_Customer__r.MH_SL_CustID__c) ? q.UNITY_Customer__r.MH_SL_CustID__c : q.UNITY_Account__r.UNITY_Bill_To_Account__r.MH_SL_CustID__c;
                String custId;
                String exemptString;
                if ( q.UNITY_Customer__c!=null && q.UNITY_Account__c!=null && q.UNITY_Customer__c == q.UNITY_Account__c ) {
                    if ( q.UNITY_Account__r.MSPFS_MSP_Bill_to_Self__c || q.UNITY_Account__r.UNITY_Bill_to_Self__c ) {
                        custId = q.UNITY_Account__r.MH_SL_CustID__c;
                        exemptString = ( q.UNITY_Account__r.UNITY_Tax_Exempt__c ) ? 'Exempt' : '';
                    } else if ( q.UNITY_Business_Unit_Account__r.MSPFS_Is_MSP_BU__c ) {
                        custId = q.UNITY_Account__r.MSPFS_MSP_Bill_To_Account__r.MH_SL_CustID__c;
                        exemptString = ( q.UNITY_Account__r.MSPFS_MSP_Bill_To_Account__r.UNITY_Tax_Exempt__c ) ? 'Exempt' : '';
                    } else {
                        custId = q.UNITY_Account__r.UNITY_Bill_To_Account__r.MH_SL_CustID__c;
                        exemptString = ( q.UNITY_Account__r.UNITY_Bill_To_Account__r.UNITY_Tax_Exempt__c ) ? 'Exempt' : '';
                    }
                } else {
                    custId = q.UNITY_Customer__r.MH_SL_CustID__c;
                    exemptString = ( q.UNITY_Customer__r.UNITY_Tax_Exempt__c ) ? 'Exempt' : '';
                }
                Decimal discount = (q.UNITY_Line_Item_Discounted_Price__c != null && q.UNITY_Final_Price2__c != null) ? 
                    q.UNITY_Line_Item_Discounted_Price__c - q.UNITY_Final_Price2__c : 0;
                avataxAvalaraComServicesAlt.GetTaxRequest gtreq = new avataxAvalaraComServicesAlt.GetTaxRequest();
                gtreq.DocType = 'SalesOrder';
                gtreq.CompanyCode = q.UNITY_Business_Unit_Account__r.UNITY_Company_Code__c;
                gtreq.CustomerCode = custId;
                gtreq.Discount = discount;
                gtreq.DetailLevel = 'Tax';
                gtreq.HashCode = 0;
                gtreq.ServiceMode = 'Automatic';
                gtreq.ExchangeRate = 0;
                gtreq.ExchangeRateEffDate = date.today();
                gtreq.PaymentDate = date.today();
                gtreq.ExemptionNo = exemptString;
                //Now Need to add the addresses
                //Origni Address (The Business Unity performing the work/sale)
                avataxAvalaraComServicesAlt.BaseAddress orgAddr = new avataxAvalaraComServicesAlt.BaseAddress();
                orgAddr.AddressCode = 'Origin';
                orgAddr.Line1 = q.UNITY_Business_Unit_Account__r.BillingStreet;//***BU BillingStreet***
                orgAddr.City = q.UNITY_Business_Unit_Account__r.BillingCity;//***BU BillingCity***
                orgAddr.Region = q.UNITY_Business_Unit_Account__r.BillingStateCode;//***BU BillingStateCode***
                orgAddr.PostalCode = q.UNITY_Business_Unit_Account__r.BillingPostalCode;//***BU BillingPostalCode***
                orgAddr.TaxRegionId = 0;
                avataxAvalaraComServicesAlt.BaseAddress dstAddr = new avataxAvalaraComServicesAlt.BaseAddress();
                //Destination Address (The Location Shipping Address)
                dstAddr.AddressCode = 'Destination';
                dstAddr.Line1 = q.UNITY_Account__r.ShippingStreet;//'11827 Tech Com Dr #116'; 
                dstAddr.City = q.UNITY_Account__r.ShippingCity;//'San Antonio'; 
                dstAddr.Region = q.UNITY_Account__r.ShippingStateCode;//'TX'; 
                dstAddr.PostalCode = q.UNITY_Account__r.ShippingPostalCode;//'78233'; 
                dstAddr.TaxRegionId = 0;
                //Add the addresses to the tax request
                gtreq.Addresses = new avataxAvalaraComServicesAlt.ArrayOfBaseAddress();
                gtreq.Addresses.BaseAddress = new avataxAvalaraComServicesAlt.BaseAddress[2];
                gtreq.Addresses.BaseAddress[0] = orgAddr;
                gtreq.Addresses.BaseAddress[1] = dstAddr;
                //Set the address codes on the tax request
                gtreq.OriginCode = orgAddr.AddressCode;
                gtreq.DestinationCode = dstAddr.AddressCode;
                //Get the tax code for the order lines
                List<UNITY_Proposal_Line_Item__c> qLines = getTaxCodeQuote(q,qLinesMap.get(q.Id));
                //Now Need to add tyhe line items
                gtreq.Lines = new avataxAvalaraComServicesAlt.ArrayOfLine();
                gtreq.Lines.Line = new avataxAvalaraComServicesAlt.Line[qLines.size()];
                Map<String, UNITY_Proposal_Line_Item__c> itemsMap = new Map<String, UNITY_Proposal_Line_Item__c>();
                for(Integer i = 0; i < qLines.size(); i++){
                    //Get the order item
                    UNITY_Proposal_Line_Item__c item = qLines[i];
                    //Create the line for the tax request
                    gtreq.Lines.Line[i] = new avataxAvalaraComServicesAlt.Line();
                    gtreq.Lines.Line[i].No = item.Name;
                    //Add the item to the items map
                    itemsMap.put(item.Name,item);
                    gtreq.Lines.Line[i].Amount = (item.UNITY_Discounted_Price__c != null) ? item.UNITY_Discounted_Price__c : (item.UNITY_Total_Price__c != null) ? item.UNITY_Total_Price__c : 0;
                    gtreq.Lines.Line[i].Qty = (item.UNITY_Customer_Adjusted_Quantity__c != null) ? item.UNITY_Customer_Adjusted_Quantity__c : (item.UNITY_Quantity__c != null) ? item.UNITY_Quantity__c: 0;
                    gtreq.Lines.Line[i].Discounted = (discount > 0);
                    gtreq.Lines.Line[i].OriginCode = 'Origin';
                    gtreq.Lines.Line[i].DestinationCode = 'Destination';
                    gtreq.Lines.Line[i].TaxCode = item.UNITY_Tax_Code__c;
                }
                gtreq.DocDate = Date.Today();
                gtreq.Commit_x=false;
                //Set the tax result
                avataxAvalaraComServicesAlt.GetTaxResult gtres = null;
                //Try to make the call to avatax
                try{
                    //System.debug('====== JSON Request: ' + JSON.serializePretty(gtreq));
                    gtres = taxSvc.GetTax(gtreq);
                    System.debug('====== JSON Result: ' + JSON.serializePretty(gtres));
                    if(gtres.ResultCode == 'Success'){
                        success = true;
                        totalTax = gtres.TotalTax;
                        totalTax = totalTax.setScale(2,System.RoundingMode.HALF_DOWN);
                        message = 'Result Code: '+gtres.ResultCode + '\n' +
                            'Total Tax: $' + totalTax + '\n' +  
                            'Total Amount: $' + gtres.TotalAmount + '\n' +
                            'Total Discount: $' + gtres.TotalDiscount + '\n';
                        if(!Test.isRunningTest())
                            message += 'Tax Addeses: Site/Location: ' + gtres.TaxAddresses.TaxAddress[0].Region + ', BU:  ' + gtres.TaxAddresses.TaxAddress[1].Region;
                        //system.debug('sampleresult:' + gtres.TotalTax);
                        if(gtres.TaxLines != null){
                            if(gtres.TaxLines.TaxLine != null){
                                message += '\nTax Rate: ' + gtres.TaxLines.TaxLine[0].Rate;
                                List<UNITY_Proposal_Line_Item__c> itemsList = new List<UNITY_Proposal_Line_Item__c>();
                                for(avataxavalaraComServicesAlt.TaxLine tl : gtres.TaxLines.TaxLine){
                                    if(itemsMap.containsKey(tl.No)){
                                        itemsMap.get(tl.No).UNITY_Sales_Tax__c = tl.Tax.setScale(2,System.RoundingMode.HALF_DOWN);
                                        itemsList.add(itemsMap.get(tl.No));
                                    }
                                }
                                update itemsList;
                            }
                        }
                    }else{
                        success = false;
                        message =  'Result Code: '+gtres.ResultCode + '\n';
                        message += 'Summary: ' + ((gtres.Messages != null) ? gtres.Messages.Message[0].Summary : 'Not available')+'\n';
                        message += 'Details: '+((gtres.Messages != null) ? gtres.Messages.Message[0].Details: 'Not available')+'\n';
                        message += 'Refers To: '+((gtres.Messages != null) ? gtres.Messages.Message[0].RefersTo: 'Not available')+'\n';
                        message += 'Source: '+((gtres.Messages != null) ? gtres.Messages.Message[0].Source: 'Not available');
                    }
                    q.UNITY_Tax_Processed__c = true;
                    q.UNITY_Tax_Process_Result__c = message;
                    update q;
                }catch(Exception ex){
                    success = false;
                    message = 'GetTax Threw an Exception: ' + ex.getmessage();
                    //System.debug('================== ' + message);
                }
            }
        }
        result = new UNITY_CallAvatax.AvataxResult(success,message,totalTax);
        System.debug('====== Result Returned: ' + JSON.serializePretty(result));
        return result;
    }

    //##############################################
    /**This method gets the tax for Service charge on quote and invoice
     * @param recordIds List<Id>: The quote or invoice ids
     * @param enitty String: Defines the type of ids being passed to the method. 'invoice' or 'quote'
     */
    //##############################################
    global static UNITY_CallAvatax.AvataxResult getTaxServiceCharge(List<Id> recordIds,String entity){
        UNITY_Constants.isExecutingContext.put('UNITY_CallAvatax.getTaxServiceCharge',true);
        Boolean success = false;
        String message = '';
        Decimal totalTax = 0;
        UNITY_CallAvatax.AvataxResult result;
        //Get the avatax auth values
        List<Key_Value_Store__c> kvslist = new List<Key_Value_Store__c>();
        kvslist = [SELECT Id,Name,Value__c FROM Key_Value_Store__c];
        String user = '';
        String pass = '';
        for(Key_Value_Store__c kvsindex : kvslist){
            if (kvsindex.Name.toLowerCase() == 'avatax account id')
                user = kvsindex.Value__c;
            if (kvsindex.Name.toLowerCase() == 'avatax license key')
                pass = kvsindex.Value__c;
        }
        List<UNITY_Proposal__c> quotes = new List<UNITY_Proposal__c>();
        List<UNITY_Invoice__c> invs = new List<UNITY_Invoice__c>();
        //Now, Need to query order and/or quote records
        if(recordIds.size() > 0){
            if(entity == 'quote'){
                //Now need to get the quote record for all lines
                quotes = [SELECT Id,Name,UNITY_Account__c,UNITY_Customer__c,UNITY_Customer__r.MH_SL_CustID__c,
                          UNITY_Account__r.ShippingStreet,UNITY_Account__r.ShippingCity,UNITY_Account__r.ShippingStateCode,UNITY_Account__r.ShippingPostalCode,UNITY_Account__r.UNITY_Bill_To_Account__r.UNITY_Tax_Exempt__c,
                          UNITY_Account__r.UNITY_Bill_To_Account__r.MH_SL_CustID__c,UNITY_Service_Charge__c,UNITY_Service_Charge_Tax__c,
                          UNITY_Business_Unit_Account__c,UNITY_Business_Unit_Account__r.UNITY_Company_Code__c,
                          UNITY_Business_Unit_Account__r.BillingStreet,UNITY_Business_Unit_Account__r.BillingCity,UNITY_Business_Unit_Account__r.BillingStateCode,UNITY_Business_Unit_Account__r.BillingPostalCode,
                          UNITY_Work_Order_Type__c FROM UNITY_Proposal__c WHERE Id IN :recordIds];
            }
        }
        //If there are work orders to get tax for...
        if(!quotes.isEmpty() || !invs.isEmpty()){
            //Begin constructing the avatax callout payload
            avataxAvalaraComServicesAlt.TaxSvcAltSecSoap taxSvc = new avataxAvalaraComServicesAlt.TaxSvcAltSecSoap();
            taxSvc.Security = new avataxAvalaraComServicesAlt.Security();
            taxSvc.Security.UsernameToken = new avataxAvalaraComServicesAlt.UsernameToken_element();
            taxSvc.Security.UsernameToken.Username = user;
            taxSvc.Security.UsernameToken.Password = pass;
            taxSvc.Profile = new avataxAvalaraComServicesAlt.Profile();
            taxSvc.Profile.Name = '1.0.0';
            taxSvc.Profile.Client = 'My Application Name,1.0';
            taxSvc.Profile.Machine = 'My Machine Name';
            for(UNITY_Proposal__c q :quotes){
                //Build the tax request for the order
                String custCode = String.isNotBlank(q.UNITY_Customer__r.MH_SL_CustID__c) ? q.UNITY_Customer__r.MH_SL_CustID__c : q.UNITY_Account__r.UNITY_Bill_To_Account__r.MH_SL_CustID__c;
                avataxAvalaraComServicesAlt.GetTaxRequest gtreq = new avataxAvalaraComServicesAlt.GetTaxRequest();
                gtreq.DocType = 'SalesOrder';
                gtreq.CompanyCode = q.UNITY_Business_Unit_Account__r.UNITY_Company_Code__c;
                gtreq.CustomerCode = custCode;
                gtreq.Discount = 0;
                gtreq.DetailLevel = 'Tax';
                gtreq.HashCode = 0;
                gtreq.ServiceMode = 'Automatic';
                gtreq.ExchangeRate = 0;
                gtreq.ExchangeRateEffDate = date.today();
                gtreq.PaymentDate = date.today();
                gtreq.ExemptionNo = (q.UNITY_Account__r.UNITY_Bill_To_Account__r.UNITY_Tax_Exempt__c) ? 'Exempt' : '';
                //Now Need to add the addresses
                //Origni Address (The Business Unity performing the work/sale)
                avataxAvalaraComServicesAlt.BaseAddress orgAddr = new avataxAvalaraComServicesAlt.BaseAddress();
                orgAddr.AddressCode = 'Origin';
                orgAddr.Line1 = q.UNITY_Business_Unit_Account__r.BillingStreet;//***BU BillingStreet***
                orgAddr.City = q.UNITY_Business_Unit_Account__r.BillingCity;//***BU BillingCity***
                orgAddr.Region = q.UNITY_Business_Unit_Account__r.BillingStateCode;//***BU BillingStateCode***
                orgAddr.PostalCode = q.UNITY_Business_Unit_Account__r.BillingPostalCode;//***BU BillingPostalCode***
                orgAddr.TaxRegionId = 0;
                avataxAvalaraComServicesAlt.BaseAddress dstAddr = new avataxAvalaraComServicesAlt.BaseAddress();
                //Destination Address (The Location Shipping Address)
                dstAddr.AddressCode = 'Destination';
                dstAddr.Line1 = q.UNITY_Account__r.ShippingStreet;//'11827 Tech Com Dr #116'; 
                dstAddr.City = q.UNITY_Account__r.ShippingCity;//'San Antonio'; 
                dstAddr.Region = q.UNITY_Account__r.ShippingStateCode;//'TX'; 
                dstAddr.PostalCode = q.UNITY_Account__r.ShippingPostalCode;//'78233'; 
                dstAddr.TaxRegionId = 0;
                //Add the addresses to the tax request
                gtreq.Addresses = new avataxAvalaraComServicesAlt.ArrayOfBaseAddress();
                gtreq.Addresses.BaseAddress = new avataxAvalaraComServicesAlt.BaseAddress[2];
                gtreq.Addresses.BaseAddress[0] = orgAddr;
                gtreq.Addresses.BaseAddress[1] = dstAddr;
                //Set the address codes on the tax request
                gtreq.OriginCode = orgAddr.AddressCode;
                gtreq.DestinationCode = dstAddr.AddressCode;
                //create quote line for service charge if it exists
                List<UNITY_Proposal_Line_Item__c> qLines = new List<UNITY_Proposal_Line_Item__c>();
                UNITY_Proposal_Line_Item__c sChargeTax = new UNITY_Proposal_Line_Item__c();
                sChargeTax.UNITY_Type__c = 'Service Fee';
                sChargeTax.UNITY_Activity_Type__c = 'Service Charge';
                sChargeTax.UNITY_Total_Price__c = q.UNITY_Service_Charge__c;
                qLines.add(sChargeTax);
                //Get the tax code for the order lines
                qLines = getTaxCodeQuote(q,qLines);
                //Now Need to add tyhe line items
                gtreq.Lines = new avataxAvalaraComServicesAlt.ArrayOfLine();
                gtreq.Lines.Line = new avataxAvalaraComServicesAlt.Line[qLines.size()];
                Map<String, UNITY_Proposal_Line_Item__c> itemsMap = new Map<String, UNITY_Proposal_Line_Item__c>();
                for(Integer i = 0; i < qLines.size(); i++){
                    //Get the order item
                    UNITY_Proposal_Line_Item__c item = qLines[i];
                    //Create the line for the tax request
                    gtreq.Lines.Line[i] = new avataxAvalaraComServicesAlt.Line();
                    gtreq.Lines.Line[i].No = 'ServiceCharge';
                    gtreq.Lines.Line[i].Amount = item.UNITY_Total_Price__c != null ? item.UNITY_Total_Price__c : 0 ;
                    gtreq.Lines.Line[i].Qty = 1;
                    gtreq.Lines.Line[i].Discounted = false;
                    gtreq.Lines.Line[i].OriginCode = 'Origin';
                    gtreq.Lines.Line[i].DestinationCode = 'Destination';
                    gtreq.Lines.Line[i].TaxCode = item.UNITY_Tax_Code__c;
                }
                gtreq.DocDate = Date.Today();
                gtreq.Commit_x=false;
                //Set the tax result
                avataxAvalaraComServicesAlt.GetTaxResult gtres = null;
                //Try to make the call to avatax
                try{
                    Decimal sChargeTaxAmount;
                    //System.debug('====== JSON Request: ' + JSON.serializePretty(gtreq));
                    gtres = taxSvc.GetTax(gtreq);
                    System.debug('====== JSON Result: ' + JSON.serializePretty(gtres));
                    if(gtres.ResultCode == 'Success'){
                        success = true;
                        totalTax = gtres.TotalTax;
                        totalTax = totalTax.setScale(2,System.RoundingMode.HALF_DOWN);
                        message = 'Result Code: '+gtres.ResultCode + '\n' +
                            'Total Tax: $' + totalTax + '\n' +  
                            'Total Amount: $' + gtres.TotalAmount + '\n' +
                            'Total Discount: $' + gtres.TotalDiscount + '\n';
                        if(!Test.isRunningTest())
                            message += 'Tax Addeses: Site/Location: ' + gtres.TaxAddresses.TaxAddress[0].Region + ', BU:  ' + gtres.TaxAddresses.TaxAddress[1].Region;
                        //system.debug('sampleresult:' + gtres.TotalTax);
                        if(gtres.TaxLines != null){
                            if(gtres.TaxLines.TaxLine != null){
                                message += '\nTax Rate: ' + gtres.TaxLines.TaxLine[0].Rate;
                                for(avataxavalaraComServicesAlt.TaxLine tl : gtres.TaxLines.TaxLine){
                                    if(tl.No == 'ServiceCharge'){
                                        sChargeTaxAmount = tl.Tax.setScale(2,System.RoundingMode.HALF_DOWN);
                                    }
                                }
                            }
                        }
                    }else{
                        success = false;
                        message =  'Result Code: '+gtres.ResultCode + '\n';
                        message += 'Summary: ' + ((gtres.Messages != null) ? gtres.Messages.Message[0].Summary : 'Not available')+'\n';
                        message += 'Details: '+((gtres.Messages != null) ? gtres.Messages.Message[0].Details: 'Not available')+'\n';
                        message += 'Refers To: '+((gtres.Messages != null) ? gtres.Messages.Message[0].RefersTo: 'Not available')+'\n';
                        message += 'Source: '+((gtres.Messages != null) ? gtres.Messages.Message[0].Source: 'Not available');
                    }
                    q.UNITY_Tax_Processed__c = true;
                    q.UNITY_Tax_Process_Result__c = message;
                    //update q;
                    if(sChargeTaxAmount != null){
                        q.UNITY_Service_Charge_Tax__c = sChargeTaxAmount;
                    }
                    update q;
                }catch(Exception ex){
                    success = false;
                    message = 'GetTax Threw an Exception: ' + ex.getmessage();
                    //System.debug('================== ' + message);
                }
            }
        }
        result = new UNITY_CallAvatax.AvataxResult(success,message,totalTax);
        System.debug('====== Result Returned: ' + JSON.serializePretty(result));
        return result;
    }

    //##############################################
    /**This method gets the tax for invoice lines
     * @param recordIds List<Id>: The quote ids
     * @param commitTax Boolean: Denotes if to post or not post the tax in avatax
     */
    //##############################################
    global static UNITY_CallAvatax.AvataxResult getTaxInvoice(List<Id> recordIds,Boolean commitTax){
        Boolean success = true;
        String message = '';
        Decimal totalTax = 0;
        UNITY_CallAvatax.AvataxResult result;
        //Get the avatax auth values
        List<Key_Value_Store__c> kvslist = new List<Key_Value_Store__c>();
        kvslist = [SELECT Id,Name,Value__c FROM Key_Value_Store__c];
        String user = '';
        String pass = '';
        for(Key_Value_Store__c kvsindex : kvslist){
            if (kvsindex.Name.toLowerCase() == 'avatax account id')
                user = kvsindex.Value__c;
            if (kvsindex.Name.toLowerCase() == 'avatax license key')
                pass = kvsindex.Value__c;
        }
        //Map to hold invoice lines by the ivoice id
        Map<Id,List<UNITY_Invoice_Line_Item__c>> iLinesMap = new Map<Id,List<UNITY_Invoice_Line_Item__c>>();
        //List to hold Invoices
        List<UNITY_Invoice__c> invs = new List<UNITY_Invoice__c>();
        //Now, Need to query order and/or quote records
        if(recordIds.size() > 0){
            
            List<UNITY_Invoice_Line_Item__c> iLines = [SELECT Id,Name,UNITY_Invoice__c,UNITY_Adjusted_Quantity__c,UNITY_Cost__c,UNITY_Discount__c,UNITY_Discount_Amount__c,UNITY_Discounted_Price__c,UNITY_Sales_Tax__c,UNITY_PO_Price__c,UNITY_Tax_Code__c,UNITY_Quantity__c,
                                                       UNITY_Total_Price__c,UNITY_Unit_Price__c ,UNITY_Type__c,UNITY_Activity_Type__c,UNITY_PO_Has_Discount__c,UNITY_Final_Discounted_Price__c
                                                       FROM UNITY_Invoice_Line_Item__c WHERE UNITY_Invoice__c IN :recordIds AND UNITY_Line_Status__c != 'Cancelled'];
            
            for(UNITY_Invoice_Line_Item__c iLine :iLines){
                if(!iLinesMap.containsKey(iLine.UNITY_Invoice__c)){
                    List<UNITY_Invoice_Line_Item__c> temp = new List<UNITY_Invoice_Line_Item__c>();
                    temp.add(iLine);
                    iLinesMap.put(iLine.UNITY_Invoice__c,temp);
                }else{
                    iLinesMap.get(iLine.UNITY_Invoice__c).add(iLine);
                }
            }
            
            invs = [SELECT Id,Name,UNITY_SL_Reference_Id__c,UNITY_Order_Type__c,UNITY_Customer__c,UNITY_Customer__r.MH_SL_CustID__c,UNITY_Customer__r.UNITY_Tax_Exempt__c,
                    UNITY_Case__r.Account.ShippingStreet,UNITY_Case__r.Account.ShippingCity,UNITY_Case__r.Account.ShippingStateCode,UNITY_Case__r.Account.ShippingPostalCode,
                    UNITY_Tax_Processed__c,UNITY_Tax_Process_Result__c,UNITY_Invoice_Date__c,UNITY_Tax_Posted__c,
                    UNITY_Case__c,UNITY_Case__r.UNITY_Business_Unit_Account__c,UNITY_Case__r.UNITY_Business_Unit_Account__r.UNITY_Company_Code__c,
                    UNITY_Case__r.UNITY_Business_Unit_Account__r.BillingStreet,UNITY_Case__r.UNITY_Business_Unit_Account__r.BillingCity,UNITY_Case__r.UNITY_Business_Unit_Account__r.BillingStateCode,
                    UNITY_Case__r.UNITY_Business_Unit_Account__r.BillingPostalCode,UNITY_Line_Item_Discounted_Price__c,UNITY_Final_Price2__c,UNITY_Discount_from_POs__c,UNITY_Service_Charge__c
                    FROM UNITY_Invoice__c WHERE Id IN :recordIds];
        }
        //If there are work orders to get tax for...
        if(invs.size() > 0){
            List<UNITY_Invoice__c> toUpdateInvs = new List<UNITY_Invoice__c>();
            List<UNITY_Invoice_Line_Item__c> toUpdateLines = new List<UNITY_Invoice_Line_Item__c>();
            //Begin constructing the avatax callout payload
            avataxAvalaraComServicesAlt.TaxSvcAltSecSoap taxSvc = new avataxAvalaraComServicesAlt.TaxSvcAltSecSoap();
            taxSvc.Security = new avataxAvalaraComServicesAlt.Security();
            taxSvc.Security.UsernameToken = new avataxAvalaraComServicesAlt.UsernameToken_element();
            taxSvc.Security.UsernameToken.Username = user;
            taxSvc.Security.UsernameToken.Password = pass;
            taxSvc.Profile = new avataxAvalaraComServicesAlt.Profile();
            taxSvc.Profile.Name = '1.0.0';
            taxSvc.Profile.Client = 'My Application Name,1.0';
            taxSvc.Profile.Machine = 'My Machine Name';
            for(UNITY_Invoice__c inv :invs){
                if(iLinesMap.containsKey(inv.Id)){
                    Decimal discount = (inv.UNITY_Line_Item_Discounted_Price__c != null && inv.UNITY_Final_Price2__c != null) ? 
                        inv.UNITY_Line_Item_Discounted_Price__c - inv.UNITY_Final_Price2__c : 0;
                    Decimal poDiscount = (inv.UNITY_Discount_from_POs__c != null && inv.UNITY_Discount_from_POs__c > 0) ? 
                        inv.UNITY_Discount_from_POs__c : 0;
                    System.debug('#####Izay: poDiscount = ' + poDiscount);
                    System.debug('#####Izay: discount = ' + discount);
                    //Build the tax request for the order
                    avataxAvalaraComServicesAlt.GetTaxRequest gtreq = new avataxAvalaraComServicesAlt.GetTaxRequest();
                    gtreq.DocType = commitTax ? 'SalesInvoice' : 'SalesOrder';
                    gtreq.DocCode = inv.UNITY_SL_Reference_Id__c;
                    gtreq.ReferenceCode = inv.Id;
                    gtreq.CompanyCode = inv.UNITY_Case__r.UNITY_Business_Unit_Account__r.UNITY_Company_Code__c;
                    gtreq.CustomerCode = inv.UNITY_Customer__r.MH_SL_CustID__c;
                    gtreq.Discount = discount + poDiscount;
                    gtreq.DetailLevel = 'Tax';
                    gtreq.HashCode = 0;
                    gtreq.ServiceMode = 'Automatic';
                    gtreq.ExchangeRate = 0;
                    gtreq.ExchangeRateEffDate = date.today();
                    gtreq.PaymentDate = date.today();
                    gtreq.ExemptionNo = (inv.UNITY_Customer__r.UNITY_Tax_Exempt__c) ? 'Exempt' : '';
                    //Now Need to add the addresses
                    //Origni Address (The Business Unity performing the work/sale)
                    avataxAvalaraComServicesAlt.BaseAddress orgAddr = new avataxAvalaraComServicesAlt.BaseAddress();
                    orgAddr.AddressCode = 'Origin';
                    orgAddr.Line1 = inv.UNITY_Case__r.UNITY_Business_Unit_Account__r.BillingStreet;//***BU BillingStreet***
                    orgAddr.City = inv.UNITY_Case__r.UNITY_Business_Unit_Account__r.BillingCity;//***BU BillingCity***
                    orgAddr.Region = inv.UNITY_Case__r.UNITY_Business_Unit_Account__r.BillingStateCode;//***BU BillingStateCode***
                    orgAddr.PostalCode = inv.UNITY_Case__r.UNITY_Business_Unit_Account__r.BillingPostalCode;//***BU BillingPostalCode***
                    orgAddr.TaxRegionId = 0;
                    avataxAvalaraComServicesAlt.BaseAddress dstAddr = new avataxAvalaraComServicesAlt.BaseAddress();
                    //Destination Address (The Location Shipping Address)
                    dstAddr.AddressCode = 'Destination';
                    dstAddr.Line1 = inv.UNITY_Case__r.Account.ShippingStreet;//'11827 Tech Com Dr #116'; 
                    dstAddr.City = inv.UNITY_Case__r.Account.ShippingCity;//'San Antonio'; 
                    dstAddr.Region = inv.UNITY_Case__r.Account.ShippingStateCode;//'TX'; 
                    dstAddr.PostalCode = inv.UNITY_Case__r.Account.ShippingPostalCode;//'78233'; 
                    dstAddr.TaxRegionId = 0;
                    //Add the addresses to the tax request
                    gtreq.Addresses = new avataxAvalaraComServicesAlt.ArrayOfBaseAddress();
                    gtreq.Addresses.BaseAddress = new avataxAvalaraComServicesAlt.BaseAddress[2];
                    gtreq.Addresses.BaseAddress[0] = orgAddr;
                    gtreq.Addresses.BaseAddress[1] = dstAddr;
                    //Set the address codes on the tax request
                    gtreq.OriginCode = orgAddr.AddressCode;
                    gtreq.DestinationCode = dstAddr.AddressCode;
                    //Get the tax code for the order lines
                    List<UNITY_Invoice_Line_Item__c> invLines = getTaxCodeInv(inv,iLinesMap.get(inv.Id));
                    //Now Need to add tyhe line items
                    gtreq.Lines = new avataxAvalaraComServicesAlt.ArrayOfLine();
                    gtreq.Lines.Line = new avataxAvalaraComServicesAlt.Line[invLines.size()];
                    Map<String, UNITY_Invoice_Line_Item__c> itemsMap = new Map<String, UNITY_Invoice_Line_Item__c>();
                    for(Integer i = 0; i < invLines.size(); i++){
                        //Get the invoice item
                        UNITY_Invoice_Line_Item__c item = invLines[i];
                        Decimal lineAmt = 0;
                        if(item.UNITY_Activity_Type__c == 'Service Charge')
                            lineAmt = (item.UNITY_Final_Discounted_Price__c != null) ? item.UNITY_Final_Discounted_Price__c : item.UNITY_Discounted_Price__c;
                        else
                            lineAmt = (item.UNITY_Discounted_Price__c != null) ? item.UNITY_Discounted_Price__c : 0;
                        //Add the item to the items map
                        itemsMap.put(item.Name,item);
                        //Create the line for the tax request
                        gtreq.Lines.Line[i] = new avataxAvalaraComServicesAlt.Line();
                        gtreq.Lines.Line[i].No = item.Name;
                        gtreq.Lines.Line[i].Amount = lineAmt;
                        gtreq.Lines.Line[i].Qty = (item.UNITY_Adjusted_Quantity__c != null) ? item.UNITY_Adjusted_Quantity__c : 0;
                        gtreq.Lines.Line[i].Discounted = ((discount > 0) || (poDiscount > 0 && item.UNITY_PO_Has_Discount__c));
                        System.debug('#####Izay: gtreq.Lines.Line[i].Discounted = ' + gtreq.Lines.Line[i].Discounted);
                        gtreq.Lines.Line[i].OriginCode = 'Origin';
                        gtreq.Lines.Line[i].DestinationCode = 'Destination';
                        gtreq.Lines.Line[i].TaxCode = item.UNITY_Tax_Code__c;
                    }
                    gtreq.DocDate = inv.UNITY_Invoice_Date__c;
                    gtreq.Commit_x = commitTax;
                    //Set the tax result
                    avataxAvalaraComServicesAlt.GetTaxResult gtres = null;
                    //Try to make the call to avatax
                    try{
                        List<UNITY_Invoice_Line_Item__c> itemsList = new List<UNITY_Invoice_Line_Item__c>();
                        gtres = taxSvc.GetTax(gtreq);
                        
                        if(gtres.ResultCode == 'Success'){
                            success = true;
                            totalTax = gtres.TotalTax;
                            totalTax = totalTax.setScale(2,System.RoundingMode.HALF_DOWN);
                            if(!Test.isRunningTest()){
                                message = 'Result Code: '+gtres.ResultCode + '\n' +
                                    'Total Tax: $' + totalTax+ '\n' + 
                                    'Total Amount: $' + gtres.TotalAmount + '\n' +
                                    'Total Discount: $' + gtres.TotalDiscount + '\n' +
                                    'Tax Addeses: Site/Location: ' + gtres.TaxAddresses.TaxAddress[0].Region + ', BU:  ' + gtres.TaxAddresses.TaxAddress[1].Region;
                            }
                            //inv.UNITY_Tax_Posted__c = commitTax;
                            //system.debug('sampleresult:' + gtres.TotalTax);
                            if(gtres.TaxLines != null){
                                if(gtres.TaxLines.TaxLine != null){
                                    message += '\nTax Rate: ' + gtres.TaxLines.TaxLine[0].Rate;
                                    for(avataxavalaraComServicesAlt.TaxLine tl : gtres.TaxLines.TaxLine){
                                        if(itemsMap.containsKey(tl.No)){
                                            itemsMap.get(tl.No).UNITY_Sales_Tax__c = tl.Tax.setScale(2,System.RoundingMode.HALF_DOWN);
                                            itemsList.add(itemsMap.get(tl.No));
                                        }
                                    }
                                }
                            }
                        }else{
                            success = false;
                            message =  'Result Code: '+gtres.ResultCode + '\n';
                            message += 'Summary: ' + ((gtres.Messages != null) ? gtres.Messages.Message[0].Summary : 'Not available')+'\n';
                            message += 'Details: '+((gtres.Messages != null) ? gtres.Messages.Message[0].Details: 'Not available')+'\n';
                            message += 'Refers To: '+((gtres.Messages != null) ? gtres.Messages.Message[0].RefersTo: 'Not available')+'\n';
                            message += 'Source: '+((gtres.Messages != null) ? gtres.Messages.Message[0].Source: 'Not available');
                        }
                        inv.UNITY_Tax_Processed__c = true;
                        inv.UNITY_Tax_Posted__c = commitTax;
                        inv.UNITY_Tax_Process_Result__c = message;
                        toUpdateInvs.add(inv);
                        toUpdateLines.addAll(itemsList);
                        //update inv;
                        //update itemsList;
                    }catch(Exception ex){
                        success = false;
                        message = 'GetTax Threw an Exception: ' + ex.getmessage();
                        //System.debug('================== ' + message);
                    }
                }
            }
            if(!toUpdateInvs.isEmpty())
                update toUpdateInvs;
            if(!toUpdateLines.isEmpty())
                update toUpdateLines;
        }
        result = new UNITY_CallAvatax.AvataxResult(success,message,totalTax);
        return result;
    }

    //##############################################
    /**This method gets the tax code for po lines
     * @param o Order: The PO
     * @param oLines List<OrderItem>: the PO Lines
     */
    //##############################################
    public static List<OrderItem> getTaxCodePO(Set<Id> recordIds){
        //List to returm OrderItems
        Map<Id,List<OrderItem>> oLinesMap = new Map<Id,List<OrderItem>>();
        List<OrderItem> oLines = [SELECT Id,OrderId,OrderItemNumber,Quantity,UnitPrice,UNITY_Cost_Plus__c,UNITY_Actual_Quantity__c,UNITY_Customer_Adjusted_Quantity__c,
                                  UNITY_Price__c,UNITY_Sales_Tax__c,UNITY_Vendor_Adjusted_Quantity__c,UNITY_Tax_Code__c,UNITY_Type__c,UNITY_Activity_Type__c,UNITY_Discounted_Price__c
                                  FROM OrderItem WHERE OrderId IN :recordIds];
        for(OrderItem oLine :oLines){
            if(!oLinesMap.containsKey(oLine.OrderId)){
                List<OrderItem> temp = new List<OrderItem>();
                temp.add(oLine);
                oLinesMap.put(oLine.OrderId,temp);
            }else{
                oLinesmap.get(oLine.OrderId).add(oLine);
            }
        }
        oLines = new List<OrderItem>();
        //Get the orders
        List<Order> orders = orderQuery( oLinesMap.keySet() );
        
        //Get the record type ids for the tax code association object
        String sRTId = [SELECT ID FROM RecordType WHERE SObjectType = 'Tax_Code_Associations__c' AND Name = 'Standard'].Id;
        String exRTId = [SELECT ID FROM RecordType WHERE SObjectType = 'Tax_Code_Associations__c' AND Name = 'Exception'].Id;
        
        //System.debug('========== orderType: ' + orderType);
        //Need to get any exception tax code for the segment (state) on the work order
        List<Tax_Code_Associations__c> exList = [SELECT Id,Name,Segment__c,Order_Type__c,Included_Activity_Types__c,Excluded_Activity_Types__c,
                                                 Included_Line_Types__c,Excluded_Line_Types__c,(SELECT Id,Name,Activity_Type__c,Tax_Code__c 
                                                 FROM Tax_Code_Exceptions__r)
                                                 FROM Tax_Code_Associations__c WHERE  RecordTypeId = :exRTId];
        //Maps to group the STANDARD tax association By Segment(state), Order Type, Line Type, and Activity Type
        //All rules are by acticvity type but they can be Segment, Order Type, and/or Line type specific
        Map<String, List<Tax_Code_Associations__c>> segmentMap = new Map<String, List<Tax_Code_Associations__c>>();
        Map<String, List<Tax_Code_Associations__c>> ordTypeMap = new Map<String, List<Tax_Code_Associations__c>>();
        Map<String, List<Tax_Code_Associations__c>> lineTypeMap = new Map<String, List<Tax_Code_Associations__c>>();
        Map<String, List<Tax_Code_Associations__c>> actTypeMap = new Map<String, List<Tax_Code_Associations__c>>();
        //Fetch all standard tax code associations
        List<Tax_Code_Associations__c> codeList = new List<Tax_Code_Associations__c>();
        codeList = [SELECT Id, Segment__c,Order_Type__c,Line_Type__c,Activity_Type__c,Tax_Code__c FROM Tax_Code_Associations__c WHERE RecordTypeId = :sRTId];
        //Put the tax code associations in their respective maps
        for(Tax_Code_Associations__c tca : codeList){
            //If the line has a segment... Put it in the segmentMap
            if(String.isNotBlank(tca.Segment__c) && tca.Segment__c != '<Any>'){
                if(!segmentMap.containsKey(tca.Segment__c)){
                    List<Tax_Code_Associations__c> temp = new List<Tax_Code_Associations__c>();
                    temp.add(tca);
                    segmentMap.put(tca.Segment__c,temp);
                }else{
                    segmentMap.get(tca.Segment__c).add(tca);
                }
                //Otherwise... If the line has an Order Type... put it in the ordTypeMap
            }else if(String.isNotBlank(tca.Order_Type__c)  && tca.Order_Type__c != '<Any>'){
                List<String> oTypes = tca.Order_Type__c.split(';');
                for(String ot :oTypes){
                    if(!ordTypeMap.containsKey(ot)){
                        List<Tax_Code_Associations__c> temp = new List<Tax_Code_Associations__c>();
                        temp.add(tca);
                        ordTypeMap.put(ot,temp);
                    }else{
                        ordTypeMap.get(ot).add(tca);
                    }
                }
                //Otherwise... If the line has an Order Type... put it in the ordTypeMap
            }else if(String.isNotBlank(tca.Line_Type__c) && tca.Line_Type__c != '<Any>'){
                if(!lineTypeMap.containsKey(tca.Line_Type__c)){
                    List<Tax_Code_Associations__c> temp = new List<Tax_Code_Associations__c>();
                    temp.add(tca);
                    lineTypeMap.put(tca.Line_Type__c,temp);
                }else{
                    lineTypeMap.get(tca.Line_Type__c).add(tca);
                }
                //Otherwise... If the line has an Order Type... put it in the ordTypeMap
            }else if(String.isNotBlank(tca.Activity_Type__c)){
                if(!actTypeMap.containsKey(tca.Activity_Type__c)){
                    List<Tax_Code_Associations__c> temp = new List<Tax_Code_Associations__c>();
                    temp.add(tca);
                    actTypeMap.put(tca.Activity_Type__c,temp);
                }else{
                    actTypeMap.get(tca.Activity_Type__c).add(tca);
                }
            }
        }
        //For each order
        for(Order o: orders){
            if(oLinesMap.containsKey(o.Id)){
                for(OrderItem line :oLinesMap.get(o.Id)){
                    line.UNITY_Tax_Code__c = null;
                }
                //Set the segment (state) from the service team on the work order
                String segment = o.Account.ShippingStateCode;//Set the segment as the state for the customer
                //System.debug('========== segment: ' + segment);
                //Set the order type
                String orderType = (String.isNotBlank(o.UNITY_Work_Order_Type__c)) ? o.UNITY_Work_Order_Type__c : '';
                //If there are exeptions for the segment (state) on the work order...
                if(exList.size() > 0){
                    //Now we need to find if the work order matches the rule. 
                    //If it does, the associated tax code exceptions are applied based on line activity type
                    //For each exception...
                    for(Tax_Code_Associations__c ex :exList){
                        Boolean isSegment = false;//Denotes if the state of the customer is the same as the segment on the exceptiojnm
                        Boolean isOType = false;//Denotes if the work order types matches the exception type
                        Boolean ltInc = false;//Denotes if the lines include any of the Included Line Types 
                        Boolean ltExc = true;//Denotes if the lines don't include any of the Excluded Line Types
                        Boolean atInc = false;//Denotes if the lines include any of the Included Activity Types
                        Boolean atExc = true;//Denotes if the lines include any of the Excluded Activity Types
                        //Boolean match = true;
                        //Check if the segment is the same
                        if(segment == ex.Segment__c){
                            isSegment = true;
                        }
                        //First, check if this rule applies to a specific order type.... 
                        if(String.isNotBlank(ex.Order_Type__c)){
                            //If it does and it matches the order type on the work order...
                            if(ex.Order_Type__c.contains(orderType))
                                isOType = true;//Set isOType to true
                            //Otherwise, if the order type is not specified...
                        }else{
                            isOType = true;//Set isOType to true
                        }
                        //If the isOType is set to true (a match or not specified)
                        if(isOType && isSegment){
                            if(o.OrderItems.size() > 0){
                                //Now, need to iterate through each line to see if the order matches the exception
                                for(OrderItem line :o.OrderItems){
                                    //Check for included line types.
                                    //If there are included line types specified....
                                    if(String.isNotBlank(ex.Included_Line_Types__c)){
                                        //If the line type matches one of the Included Line Types...
                                        if(ex.Included_Line_Types__c.contains(line.UNITY_Type__c))
                                            ltInc = true;//Set ltinc to true
                                        //Otherwise, if Included Line Types is not specified...
                                    }else{
                                        ltInc = true;//Set ltinc to true
                                    }
                                    //Check for excluded line types
                                    //If there are excluded line types specified....
                                    if(String.isNotBlank(ex.Excluded_Line_Types__c)){
                                        //If the line type matches one of the Excluded Line Types...
                                        if(ex.Excluded_Line_Types__c.contains(line.UNITY_Type__c))
                                            ltExc = false;//Set ltExc to false
                                        //Otherwise, if Excluded Line Types is not specified...
                                    }else{
                                        ltExc = true;//Set ltExc to true
                                    }
                                    //Check for included activity types
                                    //If there are included activity types specified...
                                    if(String.isNotBlank(ex.Included_Activity_Types__c)){
                                        //If the activity type matches one of the Included Activity Types...
                                        if(ex.Included_Activity_Types__c.contains(line.UNITY_Activity_Type__c))
                                            atInc = true;//Set atInc to true
                                        //Otherwise, if Included Activity Types is not specified...
                                    }else{
                                        atInc = true;//Set atInc to true
                                    }
                                    //Check for excluded activity types
                                    //If there are excluded activity types specified...
                                    if(String.isNotBlank(ex.Excluded_Activity_Types__c)){
                                        //If the activity type matches one of the Excluded Activity Types...
                                        if(ex.Excluded_Activity_Types__c.contains(line.UNITY_Activity_Type__c))
                                            atExc = false;//Set atExc to false
                                        //Otherwise, if Excluded Activity Types is not specified...
                                    }else{
                                        atExc = true;//Set atExc to true
                                    }
                                }
                                //System.debug('========== ltInc: ' + ltInc);
                                //System.debug('========== ltExc: ' + ltExc);
                                //System.debug('========== atInc: ' + atInc);
                                //System.debug('========== atExc: ' + atExc);
                                //If the work order is a match...
                                if(ltInc && ltExc && atInc && atExc){
                                    //Create a map to hold the tax code by activity type. 
                                    //This will save me a few iterations trough the lines
                                    Map<String,String> taxCodeMap = new Map<String,String>();
                                    for(Tax_Code_Exception__c exLine :ex.Tax_Code_Exceptions__r){
                                        taxCodeMap.put(exLine.Activity_Type__c, exLine.Tax_Code__c);
                                    }
                                    //Need to apply the exception tax code to the lines
                                    for(OrderItem line :o.OrderItems){
                                        if(taxCodeMap.containsKey(line.UNITY_Activity_Type__c)){
                                            //Need to set the line tax code here...
                                            line.UNITY_Tax_Code__c = taxCodeMap.get(line.UNITY_Activity_Type__c);
                                        }//End if tax code map
                                    }//End for line
                                }//End if match
                            }//End if oLines
                        }//End if isOType
                    }//End for each tax exception
                }//End if tax exceptions
                
                if(oLinesMap.containsKey(o.Id)){
                    //Denmotes if the tax code was found
                    for(OrderItem line :oLinesMap.get(o.Id)){
                        if(String.isBlank(line.UNITY_Tax_Code__c)){
                            Boolean tcFound = false;
                            String lineType = line.UNITY_Type__c;
                            String activityType = line.UNITY_Activity_Type__c;
                            
                            if(String.isNotBlank(segment)){
                                if(segmentMap.containsKey(segment)){
                                    for(Tax_Code_Associations__c tc :segmentMap.get(segment)){
                                        Boolean match = true;
                                        if(String.isNotBlank(tc.Order_Type__c)){
                                            List<String> oTypes = tc.Order_Type__c.split(';');
                                            Boolean isOT = false;
                                            for(String ot :oTypes){
                                                if(ot == orderType){
                                                    isOT = true;
                                                    break;
                                                }
                                            }
                                            if(!isOT)
                                                match = false;
                                        }
                                        if(String.isNotBlank(tc.Line_Type__c)){
                                            if(lineType != tc.Line_Type__c)
                                                match = false;
                                        }
                                        if(String.isNotBlank(tc.Activity_Type__c)){
                                            if(activityType != tc.Activity_Type__c)
                                                match = false;
                                        }
                                        if(match){
                                            line.UNITY_Tax_Code__c = tc.Tax_Code__c;
                                            tcFound = true;
                                            break;
                                            //System.debug('================= matched tax code: ' + tc);
                                        }
                                    }
                                }
                            }
                            //If the tax code wasn't found at Segment level... check rules at the Line Type level
                            if(!tcFound){
                                if(String.isNotBlank(orderType)){
                                    if(ordTypeMap.containsKey(orderType)){
                                        for(Tax_Code_Associations__c tc :ordTypeMap.get(orderType)){
                                            Boolean match = true;
                                            if(String.isNotBlank(tc.Line_Type__c)){
                                                if(lineType != tc.Line_Type__c)
                                                    match = false;
                                            }
                                            if(String.isNotBlank(tc.Activity_Type__c)){
                                                if(activityType != tc.Activity_Type__c)
                                                    match = false;
                                            }
                                            if(match){
                                                line.UNITY_Tax_Code__c = tc.Tax_Code__c;
                                                tcFound = true;
                                                break;
                                                System.debug('================= matched tax code: ' + tc);
                                            }
                                        }
                                    }
                                }
                            }
                            //If the tax code wasn't found at Order Type level... check rules at the Line Type level
                            if(!tcFound){
                                if(String.isNotBlank(lineType)){
                                    if(lineTypeMap.containsKey(lineType)){
                                        for(Tax_Code_Associations__c tc :lineTypeMap.get(lineType)){
                                            Boolean match = true;
                                            if(String.isNotBlank(tc.Activity_Type__c)){
                                                if(activityType != tc.Activity_Type__c)
                                                    match = false;
                                            }
                                            if(match){
                                                line.UNITY_Tax_Code__c = tc.Tax_Code__c;
                                                tcFound = true;
                                                break;
                                                System.debug('================= matched tax code: ' + tc);
                                            }
                                        }
                                    }
                                }
                            }
                            //If the tax code wasn't found at Line Type level... check rules at the Activity Type level
                            if(!tcFound){
                                if(String.isNotBlank(activityType)){
                                    if(actTypeMap.containsKey(activityType)){
                                        for(Tax_Code_Associations__c tc :actTypeMap.get(activityType)){
                                            line.UNITY_Tax_Code__c = tc.Tax_Code__c;
                                            tcFound = true;
                                            break;
                                            System.debug('================= matched tax code: ' + tc);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                oLines.addAll(oLinesMap.get(o.Id));
            }
        }
        return oLines;
    }

    //##############################################
    /**This method gets the tax code for po lines
     * @param o Order: The PO
     * @param oLines List<OrderItem>: the PO Lines
     */
    //##############################################
    public static List<OrderItem> getTaxCodePO(Order o, List<OrderItem> oLines){
        //List to returm OrderItems
        //List<OrderItem> oLines = new List<OrderItem>();
        //Get the orders
        /*List<Order> orders = [SELECT Id,OrderNumber,AccountId,Account.MH_SL_CustID__c,Account.BillingStreet,Account.BillingCity,Account.BillingStateCode,Account.BillingPostalCode,
                      Account.ShippingStreet,Account.ShippingCity,Account.ShippingStateCode,Account.ShippingPostalCode,Account.UNITY_Tax_Exempt__c,
                      Account.UNITY_Bill_To_Account__c,Account.UNITY_Bill_To_Account__r.BillingStreet,Account.UNITY_Bill_To_Account__r.BillingCity,
                      Account.UNITY_Bill_To_Account__r.BillingStateCode,FSO__Work_Order__c,UNITY_Business_Unit_Account__c,UNITY_Business_Unit_Account__r.UNITY_Company_Code__c,
                      UNITY_Business_Unit_Account__r.BillingStreet,UNITY_Business_Unit_Account__r.BillingCity,UNITY_Business_Unit_Account__r.BillingStateCode,UNITY_Business_Unit_Account__r.BillingPostalCode,
                      UNITY_Work_Order_Type__c,(SELECT Id,OrderItemNumber,Quantity,UnitPrice,UNITY_Cost_Plus__c,UNITY_Actual_Quantity__c,UNITY_Customer_Adjusted_Quantity__c,
                                                UNITY_Price__c,UNITY_Sales_Tax__c,UNITY_Vendor_Adjusted_Quantity__c,UNITY_Tax_Code__c,UNITY_Type__c,UNITY_Activity_Type__c FROM OrderItems) FROM Order WHERE Id IN :recordIds];
        */
        //Get the record type ids for the tax code association object
        String sRTId = [SELECT ID FROM RecordType WHERE SObjectType = 'Tax_Code_Associations__c' AND Name = 'Standard'].Id;
        String exRTId = [SELECT ID FROM RecordType WHERE SObjectType = 'Tax_Code_Associations__c' AND Name = 'Exception'].Id;
        
        //System.debug('========== orderType: ' + orderType);
        //Need to get any exception tax code for the segment (state) on the work order
        List<Tax_Code_Associations__c> exList = [SELECT Id,Name,Segment__c,Order_Type__c,Included_Activity_Types__c,Excluded_Activity_Types__c,
                                                 Included_Line_Types__c,Excluded_Line_Types__c,(SELECT Id,Name,Activity_Type__c,Tax_Code__c 
                                                 FROM Tax_Code_Exceptions__r)
                                                 FROM Tax_Code_Associations__c WHERE  RecordTypeId = :exRTId];
        //Maps to group the STANDARD tax association By Segment(state), Order Type, Line Type, and Activity Type
        //All rules are by acticvity type but they can be Segment, Order Type, and/or Line type specific
        Map<String, List<Tax_Code_Associations__c>> segmentMap = new Map<String, List<Tax_Code_Associations__c>>();
        Map<String, List<Tax_Code_Associations__c>> ordTypeMap = new Map<String, List<Tax_Code_Associations__c>>();
        Map<String, List<Tax_Code_Associations__c>> lineTypeMap = new Map<String, List<Tax_Code_Associations__c>>();
        Map<String, List<Tax_Code_Associations__c>> actTypeMap = new Map<String, List<Tax_Code_Associations__c>>();
        //Fetch all standard tax code associations
        List<Tax_Code_Associations__c> codeList = new List<Tax_Code_Associations__c>();
        codeList = [SELECT Id, Segment__c,Order_Type__c,Line_Type__c,Activity_Type__c,Tax_Code__c FROM Tax_Code_Associations__c WHERE RecordTypeId = :sRTId];
        //Put the tax code associations in their respective maps
        for(Tax_Code_Associations__c tca : codeList){
            //If the line has a segment... Put it in the segmentMap
            if(String.isNotBlank(tca.Segment__c) && tca.Segment__c != '<Any>'){
                if(!segmentMap.containsKey(tca.Segment__c)){
                    List<Tax_Code_Associations__c> temp = new List<Tax_Code_Associations__c>();
                    temp.add(tca);
                    segmentMap.put(tca.Segment__c,temp);
                }else{
                    segmentMap.get(tca.Segment__c).add(tca);
                }
                //Otherwise... If the line has an Order Type... put it in the ordTypeMap
            }else if(String.isNotBlank(tca.Order_Type__c)  && tca.Order_Type__c != '<Any>'){
                List<String> oTypes = tca.Order_Type__c.split(';');
                for(String ot :oTypes){
                    if(!ordTypeMap.containsKey(ot)){
                        List<Tax_Code_Associations__c> temp = new List<Tax_Code_Associations__c>();
                        temp.add(tca);
                        ordTypeMap.put(ot,temp);
                    }else{
                        ordTypeMap.get(ot).add(tca);
                    }
                }
                //Otherwise... If the line has an Order Type... put it in the ordTypeMap
            }else if(String.isNotBlank(tca.Line_Type__c) && tca.Line_Type__c != '<Any>'){
                if(!lineTypeMap.containsKey(tca.Line_Type__c)){
                    List<Tax_Code_Associations__c> temp = new List<Tax_Code_Associations__c>();
                    temp.add(tca);
                    lineTypeMap.put(tca.Line_Type__c,temp);
                }else{
                    lineTypeMap.get(tca.Line_Type__c).add(tca);
                }
                //Otherwise... If the line has an Order Type... put it in the ordTypeMap
            }else if(String.isNotBlank(tca.Activity_Type__c)){
                if(!actTypeMap.containsKey(tca.Activity_Type__c)){
                    List<Tax_Code_Associations__c> temp = new List<Tax_Code_Associations__c>();
                    temp.add(tca);
                    actTypeMap.put(tca.Activity_Type__c,temp);
                }else{
                    actTypeMap.get(tca.Activity_Type__c).add(tca);
                }
            }
        }
        //For each order
        if(o != null){
            if(oLines.size() > 0){
                for(OrderItem line :oLines){
                    line.UNITY_Tax_Code__c = null;
                }
                //Set the segment (state) from the service team on the work order
                String segment = o.Account.ShippingStateCode;//Set the segment as the state for the customer
                //System.debug('========== segment: ' + segment);
                //Set the order type
                String orderType = (String.isNotBlank(o.UNITY_Work_Order_Type__c)) ? o.UNITY_Work_Order_Type__c : '';
                //If there are exeptions for the segment (state) on the work order...
                if(exList.size() > 0){
                    //Now we need to find if the work order matches the rule. 
                    //If it does, the associated tax code exceptions are applied based on line activity type
                    //For each exception...
                    for(Tax_Code_Associations__c ex :exList){
                        Boolean isSegment = false;//Denotes if the state of the customer is the same as the segment on the exceptiojnm
                        Boolean isOType = false;//Denotes if the work order types matches the exception type
                        Boolean ltInc = false;//Denotes if the lines include any of the Included Line Types 
                        Boolean ltExc = true;//Denotes if the lines don't include any of the Excluded Line Types
                        Boolean atInc = false;//Denotes if the lines include any of the Included Activity Types
                        Boolean atExc = true;//Denotes if the lines include any of the Excluded Activity Types
                        //Boolean match = true;
                        //Check if the segment is the same
                        if(segment == ex.Segment__c){
                            isSegment = true;
                        }
                        //First, check if this rule applies to a specific order type.... 
                        if(String.isNotBlank(ex.Order_Type__c)){
                            //If it does and it matches the order type on the work order...
                            if(ex.Order_Type__c.contains(orderType))
                                isOType = true;//Set isOType to true
                            //Otherwise, if the order type is not specified...
                        }else{
                            isOType = true;//Set isOType to true
                        }
                        //If the isOType is set to true (a match or not specified)
                        if(isOType && isSegment){
                            if(o.OrderItems.size() > 0){
                                //Now, need to iterate through each line to see if the order matches the exception
                                for(OrderItem line :o.OrderItems){
                                    //Check for included line types.
                                    //If there are included line types specified....
                                    if(String.isNotBlank(ex.Included_Line_Types__c)){
                                        //If the line type matches one of the Included Line Types...
                                        if(ex.Included_Line_Types__c.contains(line.UNITY_Type__c))
                                            ltInc = true;//Set ltinc to true
                                        //Otherwise, if Included Line Types is not specified...
                                    }else{
                                        ltInc = true;//Set ltinc to true
                                    }
                                    //Check for excluded line types
                                    //If there are excluded line types specified....
                                    if(String.isNotBlank(ex.Excluded_Line_Types__c)){
                                        //If the line type matches one of the Excluded Line Types...
                                        if(ex.Excluded_Line_Types__c.contains(line.UNITY_Type__c))
                                            ltExc = false;//Set ltExc to false
                                        //Otherwise, if Excluded Line Types is not specified...
                                    }else{
                                        ltExc = true;//Set ltExc to true
                                    }
                                    //Check for included activity types
                                    //If there are included activity types specified...
                                    if(String.isNotBlank(ex.Included_Activity_Types__c)){
                                        //If the activity type matches one of the Included Activity Types...
                                        if(ex.Included_Activity_Types__c.contains(line.UNITY_Activity_Type__c))
                                            atInc = true;//Set atInc to true
                                        //Otherwise, if Included Activity Types is not specified...
                                    }else{
                                        atInc = true;//Set atInc to true
                                    }
                                    //Check for excluded activity types
                                    //If there are excluded activity types specified...
                                    if(String.isNotBlank(ex.Excluded_Activity_Types__c)){
                                        //If the activity type matches one of the Excluded Activity Types...
                                        if(ex.Excluded_Activity_Types__c.contains(line.UNITY_Activity_Type__c))
                                            atExc = false;//Set atExc to false
                                        //Otherwise, if Excluded Activity Types is not specified...
                                    }else{
                                        atExc = true;//Set atExc to true
                                    }
                                }
                                //System.debug('========== ltInc: ' + ltInc);
                                //System.debug('========== ltExc: ' + ltExc);
                                //System.debug('========== atInc: ' + atInc);
                                //System.debug('========== atExc: ' + atExc);
                                //If the work order is a match...
                                if(ltInc && ltExc && atInc && atExc){
                                    //Create a map to hold the tax code by activity type. 
                                    //This will save me a few iterations trough the lines
                                    Map<String,String> taxCodeMap = new Map<String,String>();
                                    for(Tax_Code_Exception__c exLine :ex.Tax_Code_Exceptions__r){
                                        taxCodeMap.put(exLine.Activity_Type__c, exLine.Tax_Code__c);
                                    }
                                    //Need to apply the exception tax code to the lines
                                    for(OrderItem line :o.OrderItems){
                                        if(taxCodeMap.containsKey(line.UNITY_Activity_Type__c)){
                                            //Need to set the line tax code here...
                                            line.UNITY_Tax_Code__c = taxCodeMap.get(line.UNITY_Activity_Type__c);
                                        }//End if tax code map
                                    }//End for line
                                }//End if match
                            }//End if oLines
                        }//End if isOType
                    }//End for each tax exception
                }//End if tax exceptions
                
                if(oLines.size() > 0){
                    //Denmotes if the tax code was found
                    for(OrderItem line :oLines){
                        if(String.isBlank(line.UNITY_Tax_Code__c)){
                            Boolean tcFound = false;
                            String lineType = line.UNITY_Type__c;
                            String activityType = line.UNITY_Activity_Type__c;
                            
                            if(String.isNotBlank(segment)){
                                if(segmentMap.containsKey(segment)){
                                    for(Tax_Code_Associations__c tc :segmentMap.get(segment)){
                                        Boolean match = true;
                                        if(String.isNotBlank(tc.Order_Type__c)){
                                            List<String> oTypes = tc.Order_Type__c.split(';');
                                            Boolean isOT = false;
                                            for(String ot :oTypes){
                                                if(ot == orderType){
                                                    isOT = true;
                                                    break;
                                                }
                                            }
                                            if(!isOT)
                                                match = false;
                                        }
                                        if(String.isNotBlank(tc.Line_Type__c)){
                                            if(lineType != tc.Line_Type__c)
                                                match = false;
                                        }
                                        if(String.isNotBlank(tc.Activity_Type__c)){
                                            if(activityType != tc.Activity_Type__c)
                                                match = false;
                                        }
                                        if(match){
                                            line.UNITY_Tax_Code__c = tc.Tax_Code__c;
                                            tcFound = true;
                                            break;
                                            //System.debug('================= matched tax code: ' + tc);
                                        }
                                    }
                                }
                            }
                            //If the tax code wasn't found at Segment level... check rules at the Line Type level
                            if(!tcFound){
                                if(String.isNotBlank(orderType)){
                                    if(ordTypeMap.containsKey(orderType)){
                                        for(Tax_Code_Associations__c tc :ordTypeMap.get(orderType)){
                                            Boolean match = true;
                                            if(String.isNotBlank(tc.Line_Type__c)){
                                                if(lineType != tc.Line_Type__c)
                                                    match = false;
                                            }
                                            if(String.isNotBlank(tc.Activity_Type__c)){
                                                if(activityType != tc.Activity_Type__c)
                                                    match = false;
                                            }
                                            if(match){
                                                line.UNITY_Tax_Code__c = tc.Tax_Code__c;
                                                tcFound = true;
                                                break;
                                                System.debug('================= matched tax code: ' + tc);
                                            }
                                        }
                                    }
                                }
                            }
                            //If the tax code wasn't found at Order Type level... check rules at the Line Type level
                            if(!tcFound){
                                if(String.isNotBlank(lineType)){
                                    if(lineTypeMap.containsKey(lineType)){
                                        for(Tax_Code_Associations__c tc :lineTypeMap.get(lineType)){
                                            Boolean match = true;
                                            if(String.isNotBlank(tc.Activity_Type__c)){
                                                if(activityType != tc.Activity_Type__c)
                                                    match = false;
                                            }
                                            if(match){
                                                line.UNITY_Tax_Code__c = tc.Tax_Code__c;
                                                tcFound = true;
                                                break;
                                                System.debug('================= matched tax code: ' + tc);
                                            }
                                        }
                                    }
                                }
                            }
                            //If the tax code wasn't found at Line Type level... check rules at the Activity Type level
                            if(!tcFound){
                                if(String.isNotBlank(activityType)){
                                    if(actTypeMap.containsKey(activityType)){
                                        for(Tax_Code_Associations__c tc :actTypeMap.get(activityType)){
                                            line.UNITY_Tax_Code__c = tc.Tax_Code__c;
                                            tcFound = true;
                                            break;
                                            System.debug('================= matched tax code: ' + tc);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                //oLines.addAll(o.OrderItems);
            }
        }
        return oLines;
    }

    //##############################################
    /**This method gets the tax code for po lines
     * @param o UNITY_Proposal__c: The Quote
     * @param oLines List<UNITY_Proposal_Line_Item__c>: the Quote Lines
     */
    //##############################################
    public static List<UNITY_Proposal_Line_Item__c> getTaxCodeQuote(UNITY_Proposal__c q, List<UNITY_Proposal_Line_Item__c> qLines){
        //Reset the tax code
        if(qLines != null){
            for(UNITY_Proposal_Line_Item__c line :qLines){
                line.UNITY_Tax_Code__c = null;
            }
        }
        //Get the record type ids for the tax code association object
        String sRTId = [SELECT ID FROM RecordType WHERE SObjectType = 'Tax_Code_Associations__c' AND Name = 'Standard'].Id;
        String exRTId = [SELECT ID FROM RecordType WHERE SObjectType = 'Tax_Code_Associations__c' AND Name = 'Exception'].Id;
        //Set the segment (state) from the service team on the work order
        String segment = q.UNITY_Account__r.ShippingStateCode;//Set the segment as the state for the customer
        //System.debug('========== segment: ' + segment);
        //Set the order type
        String orderType = (q.UNITY_Work_Order_Type__c != null) ? q.UNITY_Work_Order_Type__c : '';
        //System.debug('========== orderType: ' + orderType);
        //Need to get any exception tax code for the segment (state) on the work order
        List<Tax_Code_Associations__c> exList = [SELECT Id,Name,Segment__c,Order_Type__c,Included_Activity_Types__c,Excluded_Activity_Types__c,
                                                 Included_Line_Types__c,Excluded_Line_Types__c,(SELECT Id,Name,Activity_Type__c,Tax_Code__c 
                                                 FROM Tax_Code_Exceptions__r)
                                                 FROM Tax_Code_Associations__c WHERE Segment__c = :segment AND RecordTypeId = :exRTId];
        //If there are exeptions for the segment (state) on the work order...
        if(exList.size() > 0){
            //Now we need to find if the work order matches the rule. 
            //If it does, the associated tax code exceptions are applied based on line activity type
            //For each exception...
            for(Tax_Code_Associations__c ex :exList){
                Boolean isSegment = false;//Denotes if the state of the customer is the same as the segment on the exceptiojnm
                Boolean isOType = false;//Denotes if the work order types matches the exception type
                Boolean ltInc = false;//Denotes if the lines include any of the Included Line Types 
                Boolean ltExc = true;//Denotes if the lines don't include any of the Excluded Line Types
                Boolean atInc = false;//Denotes if the lines include any of the Included Activity Types
                Boolean atExc = true;//Denotes if the lines include any of the Excluded Activity Types
                //Boolean match = true;
                //Check if the segment is the same
                if(segment == ex.Segment__c){
                    isSegment = true;
                }
                //First, check if this rule applies to a specific order type.... 
                if(String.isNotBlank(ex.Order_Type__c)){
                    //If it does and it matches the order type on the work order...
                    if(ex.Order_Type__c.contains(orderType))
                        isOType = true;//Set isOType to true
                    //Otherwise, if the order type is not specified...
                }else{
                    isOType = true;//Set isOType to true
                }
                //If the isOType is set to true (a match or not specified)
                if(isOType && isSegment){
                    if(qLines.size() > 0){
                        //Now, need to iterate through each line to see if the order matches the exception
                        for(UNITY_Proposal_Line_Item__c line :qLines){
                            //Check for included line types.
                            //If there are included line types specified....
                            if(String.isNotBlank(ex.Included_Line_Types__c)){
                                //If the line type matches one of the Included Line Types...
                                if(ex.Included_Line_Types__c.contains(line.UNITY_Type__c))
                                    ltInc = true;//Set ltinc to true
                                //Otherwise, if Included Line Types is not specified...
                            }else{
                                ltInc = true;//Set ltinc to true
                            }
                            //Check for excluded line types
                            //If there are excluded line types specified....
                            if(String.isNotBlank(ex.Excluded_Line_Types__c)){
                                //If the line type matches one of the Excluded Line Types...
                                if(ex.Excluded_Line_Types__c.contains(line.UNITY_Type__c))
                                    ltExc = false;//Set ltExc to false
                                //Otherwise, if Excluded Line Types is not specified...
                            }else{
                                ltExc = true;//Set ltExc to true
                            }
                            //Check for included activity types
                            //If there are included activity types specified...
                            if(String.isNotBlank(ex.Included_Activity_Types__c)){
                                //If the activity type matches one of the Included Activity Types...
                                if(ex.Included_Activity_Types__c.contains(line.UNITY_Activity_Type__c))
                                    atInc = true;//Set atInc to true
                                //Otherwise, if Included Activity Types is not specified...
                            }else{
                                atInc = true;//Set atInc to true
                            }
                            //Check for excluded activity types
                            //If there are excluded activity types specified...
                            if(String.isNotBlank(ex.Excluded_Activity_Types__c)){
                                //If the activity type matches one of the Excluded Activity Types...
                                if(ex.Excluded_Activity_Types__c.contains(line.UNITY_Activity_Type__c))
                                    atExc = false;//Set atExc to false
                                //Otherwise, if Excluded Activity Types is not specified...
                            }else{
                                atExc = true;//Set atExc to true
                            }
                        }
                        //System.debug('========== ltInc: ' + ltInc);
                        //System.debug('========== ltExc: ' + ltExc);
                        //System.debug('========== atInc: ' + atInc);
                        //System.debug('========== atExc: ' + atExc);
                        //If the work order is a match...
                        if(ltInc && ltExc && atInc && atExc){
                            //Create a map to hold the tax code by activity type. 
                            //This will save me a few iterations trough the lines
                            Map<String,String> taxCodeMap = new Map<String,String>();
                            for(Tax_Code_Exception__c exLine :ex.Tax_Code_Exceptions__r){
                                taxCodeMap.put(exLine.Activity_Type__c, exLine.Tax_Code__c);
                            }
                            //Need to apply the exception tax code to the lines
                            for(UNITY_Proposal_Line_Item__c line :qLines){
                                if(taxCodeMap.containsKey(line.UNITY_Activity_Type__c)){
                                    //Need to set the line tax code here...
                                    line.UNITY_Tax_Code__c = taxCodeMap.get(line.UNITY_Activity_Type__c);
                                }//End if tax code map
                            }//End for line
                        }//End if match
                    }//End if oLines
                }//End if isOType
            }//End for each tax exception
        }//End if tax exceptions
        //Maps to group the STANDARD tax association By Segment(state), Order Type, Line Type, and Activity Type
        //All rules are by acticvity type but they can be Segment, Order Type, and/or Line type specific
        Map<String, List<Tax_Code_Associations__c>> segmentMap = new Map<String, List<Tax_Code_Associations__c>>();
        Map<String, List<Tax_Code_Associations__c>> ordTypeMap = new Map<String, List<Tax_Code_Associations__c>>();
        Map<String, List<Tax_Code_Associations__c>> lineTypeMap = new Map<String, List<Tax_Code_Associations__c>>();
        Map<String, List<Tax_Code_Associations__c>> actTypeMap = new Map<String, List<Tax_Code_Associations__c>>();
        //Fetch all standard tax code associations
        List<Tax_Code_Associations__c> codeList = new List<Tax_Code_Associations__c>();
        codeList = [SELECT Id, Segment__c,Order_Type__c,Line_Type__c,Activity_Type__c,Tax_Code__c FROM Tax_Code_Associations__c WHERE RecordTypeId = :sRTId];
        //Put the tax code associations in their respective maps
        for(Tax_Code_Associations__c tca : codeList){
            //If the line has a segment... Put it in the segmentMap
            if(String.isNotBlank(tca.Segment__c) && tca.Segment__c != '<Any>'){
                if(!segmentMap.containsKey(tca.Segment__c)){
                    List<Tax_Code_Associations__c> temp = new List<Tax_Code_Associations__c>();
                    temp.add(tca);
                    segmentMap.put(tca.Segment__c,temp);
                }else{
                    segmentMap.get(tca.Segment__c).add(tca);
                }
            //Otherwise... If the line has an Order Type... put it in the ordTypeMap
            }else if(String.isNotBlank(tca.Order_Type__c)  && tca.Order_Type__c != '<Any>'){
                List<String> oTypes = tca.Order_Type__c.split(';');
                for(String ot :oTypes){
                    if(!ordTypeMap.containsKey(ot)){
                        List<Tax_Code_Associations__c> temp = new List<Tax_Code_Associations__c>();
                        temp.add(tca);
                        ordTypeMap.put(ot,temp);
                    }else{
                        ordTypeMap.get(ot).add(tca);
                    }
                }
            //Otherwise... If the line has an Order Type... put it in the ordTypeMap
            }else if(String.isNotBlank(tca.Line_Type__c) && tca.Line_Type__c != '<Any>'){
                if(!lineTypeMap.containsKey(tca.Line_Type__c)){
                    List<Tax_Code_Associations__c> temp = new List<Tax_Code_Associations__c>();
                    temp.add(tca);
                    lineTypeMap.put(tca.Line_Type__c,temp);
                }else{
                    lineTypeMap.get(tca.Line_Type__c).add(tca);
                }
            //Otherwise... If the line has an Order Type... put it in the ordTypeMap
            }else if(String.isNotBlank(tca.Activity_Type__c)){
                if(!actTypeMap.containsKey(tca.Activity_Type__c)){
                    List<Tax_Code_Associations__c> temp = new List<Tax_Code_Associations__c>();
                    temp.add(tca);
                    actTypeMap.put(tca.Activity_Type__c,temp);
                }else{
                    actTypeMap.get(tca.Activity_Type__c).add(tca);
                }
            }
        }
        if(qLines != null){
            //Denmotes if the tax code was found
            for(UNITY_Proposal_Line_Item__c line :qLines){
                if(String.isBlank(line.UNITY_Tax_Code__c)){
                    Boolean tcFound = false;
                    String lineType = line.UNITY_Type__c;
                    String activityType = line.UNITY_Activity_Type__c;
                    
                    if(String.isNotBlank(segment)){
                        if(segmentMap.containsKey(segment)){
                            for(Tax_Code_Associations__c tc :segmentMap.get(segment)){
                                Boolean match = true;
                                if(String.isNotBlank(tc.Order_Type__c)){
                                    List<String> oTypes = tc.Order_Type__c.split(';');
                                    Boolean isOT = false;
                                    for(String ot :oTypes){
                                        if(ot == orderType){
                                            isOT = true;
                                            break;
                                        }
                                    }
                                    if(!isOT)
                                        match = false;
                                }
                                if(String.isNotBlank(tc.Line_Type__c)){
                                    if(lineType != tc.Line_Type__c)
                                        match = false;
                                }
                                if(String.isNotBlank(tc.Activity_Type__c)){
                                    if(activityType != tc.Activity_Type__c)
                                        match = false;
                                }
                                if(match){
                                    line.UNITY_Tax_Code__c = tc.Tax_Code__c;
                                    tcFound = true;
                                    break;
                                    //System.debug('================= matched tax code: ' + tc);
                                }
                            }
                        }
                    }
                    //If the tax code wasn't found at Segment level... check rules at the Line Type level
                    if(!tcFound){
                        if(String.isNotBlank(orderType)){
                            if(ordTypeMap.containsKey(orderType)){
                                for(Tax_Code_Associations__c tc :ordTypeMap.get(orderType)){
                                    Boolean match = true;
                                    if(String.isNotBlank(tc.Line_Type__c)){
                                        if(lineType != tc.Line_Type__c)
                                            match = false;
                                    }
                                    if(String.isNotBlank(tc.Activity_Type__c)){
                                        if(activityType != tc.Activity_Type__c)
                                            match = false;
                                    }
                                    if(match){
                                        line.UNITY_Tax_Code__c = tc.Tax_Code__c;
                                        tcFound = true;
                                        break;
                                        System.debug('================= matched tax code: ' + tc);
                                    }
                                }
                            }
                        }
                    }
                    //If the tax code wasn't found at Order Type level... check rules at the Line Type level
                    if(!tcFound){
                        if(String.isNotBlank(lineType)){
                            if(lineTypeMap.containsKey(lineType)){
                                for(Tax_Code_Associations__c tc :lineTypeMap.get(lineType)){
                                    Boolean match = true;
                                    if(String.isNotBlank(tc.Activity_Type__c)){
                                        if(activityType != tc.Activity_Type__c)
                                            match = false;
                                    }
                                    if(match){
                                        line.UNITY_Tax_Code__c = tc.Tax_Code__c;
                                        tcFound = true;
                                        break;
                                        System.debug('================= matched tax code: ' + tc);
                                    }
                                }
                            }
                        }
                    }
                    //If the tax code wasn't found at Line Type level... check rules at the Activity Type level
                    if(!tcFound){
                        if(String.isNotBlank(activityType)){
                            if(actTypeMap.containsKey(activityType)){
                                for(Tax_Code_Associations__c tc :actTypeMap.get(activityType)){
                                    line.UNITY_Tax_Code__c = tc.Tax_Code__c;
                                    tcFound = true;
                                    break;
                                    System.debug('================= matched tax code: ' + tc);
                                }
                            }
                        }
                    }
                }
            }
        }
        return qLines;
    }

    //##############################################
    /**This method gets the tax code for po lines
     * @param o Order: The PO
     * @param oLines List<OrderItem>: the PO Lines
     */
    //##############################################
    public static List<UNITY_Invoice_Line_Item__c> getTaxCodeInv( UNITY_Invoice__c inv, List<UNITY_Invoice_Line_Item__c> invLines ) {
        //List to returm OrderItems
        Map<Id,List<UNITY_Invoice_Line_Item__c>> invLinesMap = new Map<Id,List<UNITY_Invoice_Line_Item__c>>();
        if ( invLines == null || invLines.isEmpty() ) return new List<UNITY_Invoice_Line_Item__c>();

        for ( UNITY_Invoice_Line_Item__c invLine : invLines ) {
            if ( !invLinesMap.containsKey(invLine.UNITY_Invoice__c) ) {
                invLinesMap.put( invLine.UNITY_Invoice__c, new List<UNITY_Invoice_Line_Item__c>() );
            }
            invLinesmap.get(invLine.UNITY_Invoice__c).add( invLine );
        }

        invLines = new List<UNITY_Invoice_Line_Item__c>();
        
        //Get the record type ids for the tax code association object
        String sRTId = [SELECT ID FROM RecordType WHERE SObjectType = 'Tax_Code_Associations__c' AND Name = 'Standard'].Id;
        String exRTId = [SELECT ID FROM RecordType WHERE SObjectType = 'Tax_Code_Associations__c' AND Name = 'Exception'].Id;
        
        //Need to get any exception tax code for the segment (state) on the work order
        List<Tax_Code_Associations__c> exList = [SELECT Id,Name,Segment__c,Order_Type__c,Included_Activity_Types__c,Excluded_Activity_Types__c,
                                                 Included_Line_Types__c,Excluded_Line_Types__c,(SELECT Id,Name,Activity_Type__c,Tax_Code__c 
                                                 FROM Tax_Code_Exceptions__r)
                                                 FROM Tax_Code_Associations__c WHERE  RecordTypeId = :exRTId];
        //Maps to group the STANDARD tax association By Segment(state), Order Type, Line Type, and Activity Type
        //All rules are by acticvity type but they can be Segment, Order Type, and/or Line type specific
        Map<String, List<Tax_Code_Associations__c>> segmentMap = new Map<String, List<Tax_Code_Associations__c>>();
        Map<String, List<Tax_Code_Associations__c>> ordTypeMap = new Map<String, List<Tax_Code_Associations__c>>();
        Map<String, List<Tax_Code_Associations__c>> lineTypeMap = new Map<String, List<Tax_Code_Associations__c>>();
        Map<String, List<Tax_Code_Associations__c>> actTypeMap = new Map<String, List<Tax_Code_Associations__c>>();
        
        //Fetch all standard tax code associations
        List<Tax_Code_Associations__c> codeList = [SELECT Id, Segment__c, Order_Type__c, Line_Type__c, Activity_Type__c, Tax_Code__c FROM Tax_Code_Associations__c WHERE RecordTypeId = :sRTId];
        
        //Put the tax code associations in their respective maps
        for ( Tax_Code_Associations__c tca : codeList ) {
            //If the line has a segment... Put it in the segmentMap
            if ( String.isNotBlank(tca.Segment__c) && tca.Segment__c != '<Any>' ) {
                if ( !segmentMap.containsKey(tca.Segment__c) ) {
                    segmentMap.put( tca.Segment__c, new List<Tax_Code_Associations__c>() );
                }
                segmentMap.get(tca.Segment__c).add(tca);
                
                //Otherwise... If the line has an Order Type... put it in the ordTypeMap
            } else if ( String.isNotBlank(tca.Order_Type__c) && tca.Order_Type__c != '<Any>' ) {
                List<String> oTypes = tca.Order_Type__c.split(';');
                for ( String ot :oTypes ) {
                    if ( !ordTypeMap.containsKey(ot) ) {
                        ordTypeMap.put( ot, new List<Tax_Code_Associations__c>() );
                    }
                    ordTypeMap.get(ot).add(tca);
                }
                //Otherwise... If the line has an Order Type... put it in the ordTypeMap
            } else if ( String.isNotBlank(tca.Line_Type__c) && tca.Line_Type__c != '<Any>' ) {
                if ( !lineTypeMap.containsKey(tca.Line_Type__c) ) {
                    lineTypeMap.put( tca.Line_Type__c, new List<Tax_Code_Associations__c>() );
                }
                lineTypeMap.get(tca.Line_Type__c).add(tca);
                //Otherwise... If the line has an Order Type... put it in the ordTypeMap
            } else if ( String.isNotBlank(tca.Activity_Type__c) ) {
                if( !actTypeMap.containsKey(tca.Activity_Type__c) ){
                    actTypeMap.put( tca.Activity_Type__c, new List<Tax_Code_Associations__c>() );
                }
                actTypeMap.get(tca.Activity_Type__c).add(tca);
            }
        }

        if ( !invLinesMap.containsKey(inv.Id) ) return invLines;

        for (UNITY_Invoice_Line_Item__c line : invLinesMap.get(inv.Id) ) {
            line.UNITY_Tax_Code__c = null;
        }
        //Set the segment (state) from the service team on the work order
        String segment = inv.UNITY_Case__r.Account.ShippingStateCode;//Set the segment as the state for the customer
        //Set the order type
        String orderType = (String.isNotBlank(inv.UNITY_Order_Type__c)) ? inv.UNITY_Order_Type__c : '';
        //If there are exeptions for the segment (state) on the work order...
        if ( exList.size() > 0 ) {
            //Now we need to find if the work order matches the rule. 
            //If it does, the associated tax code exceptions are applied based on line activity type
            //For each exception...
            for ( Tax_Code_Associations__c ex :exList ) {
                Boolean isSegment = false;//Denotes if the state of the customer is the same as the segment on the exceptiojnm
                Boolean isOType = false;//Denotes if the work order types matches the exception type
                Boolean ltInc = false;//Denotes if the lines include any of the Included Line Types 
                Boolean ltExc = true;//Denotes if the lines don't include any of the Excluded Line Types
                Boolean atInc = false;//Denotes if the lines include any of the Included Activity Types
                Boolean atExc = true;//Denotes if the lines include any of the Excluded Activity Types
                //Boolean match = true;
                //Check if the segment is the same
                if ( segment == ex.Segment__c ) {
                    isSegment = true;
                }
                //First, check if this rule applies to a specific order type.... 
                if ( String.isNotBlank(ex.Order_Type__c) ) {
                    //If it does and it matches the order type on the work order...
                    if (ex.Order_Type__c.contains(orderType) )
                        isOType = true;//Set isOType to true
                    //Otherwise, if the order type is not specified...
                } else {
                    isOType = true;//Set isOType to true
                }
                //If the isOType is set to true (a match or not specified)
                if ( isOType && isSegment ) {
                    //Now, need to iterate through each line to see if the order matches the exception
                    for ( UNITY_Invoice_Line_Item__c line :invLinesMap.get(inv.Id) ) {
                        //Check for included line types.
                        //If there are included line types specified....
                        if ( String.isNotBlank(ex.Included_Line_Types__c) && String.isNotBlank(line.UNITY_Type__c) ) {
                            //If the line type matches one of the Included Line Types...
                            if ( ex.Included_Line_Types__c.contains(line.UNITY_Type__c) )
                                ltInc = true;//Set ltinc to true
                            //Otherwise, if Included Line Types is not specified...
                        } else {
                            ltInc = true;//Set ltinc to true
                        }
                        //Check for excluded line types
                        //If there are excluded line types specified....
                        if ( String.isNotBlank(ex.Excluded_Line_Types__c) && String.isNotBlank(line.UNITY_Type__c) ) {
                            //If the line type matches one of the Excluded Line Types...
                            if ( ex.Excluded_Line_Types__c.contains(line.UNITY_Type__c) )
                                ltExc = false;//Set ltExc to false
                            //Otherwise, if Excluded Line Types is not specified...
                        } else {
                            ltExc = true;//Set ltExc to true
                        }
                        //Check for included activity types
                        //If there are included activity types specified...
                        if ( String.isNotBlank(ex.Included_Activity_Types__c) && String.isNotBlank(line.UNITY_Activity_Type__c) ) {
                            //If the activity type matches one of the Included Activity Types...
                            if ( ex.Included_Activity_Types__c.contains(line.UNITY_Activity_Type__c) )
                                atInc = true;//Set atInc to true
                            //Otherwise, if Included Activity Types is not specified...
                        } else {
                            atInc = true;//Set atInc to true
                        }
                        //Check for excluded activity types
                        //If there are excluded activity types specified...
                        if ( String.isNotBlank(ex.Excluded_Activity_Types__c) && String.isNotBlank(line.UNITY_Activity_Type__c) ) {
                            //If the activity type matches one of the Excluded Activity Types...
                            if ( ex.Excluded_Activity_Types__c.contains(line.UNITY_Activity_Type__c) )
                                atExc = false;//Set atExc to false
                            //Otherwise, if Excluded Activity Types is not specified...
                        } else {
                            atExc = true;//Set atExc to true
                        }
                    }
                    //If the work order is a match...
                    if ( ltInc && ltExc && atInc && atExc ) {
                        //Create a map to hold the tax code by activity type. 
                        //This will save me a few iterations trough the lines
                        Map<String,String> taxCodeMap = new Map<String,String>();
                        for ( Tax_Code_Exception__c exLine :ex.Tax_Code_Exceptions__r ) {
                            taxCodeMap.put( exLine.Activity_Type__c, exLine.Tax_Code__c );
                        }
                        //Need to apply the exception tax code to the lines
                        for ( UNITY_Invoice_Line_Item__c line :invLinesMap.get(inv.Id) ) {
                            if ( taxCodeMap.containsKey(line.UNITY_Activity_Type__c) ) {
                                //Need to set the line tax code here...
                                line.UNITY_Tax_Code__c = taxCodeMap.get(line.UNITY_Activity_Type__c);
                            }//End if tax code map
                        }//End for line
                    }//End if match
                }//End if isOType
            }//End for each tax exception
        }//End if tax exceptions
        
        //Denmotes if the tax code was found
        for ( UNITY_Invoice_Line_Item__c line :invLinesMap.get(inv.Id) ) {
            if ( String.isBlank(line.UNITY_Tax_Code__c) ) {
                Boolean tcFound = false;
                String lineType = line.UNITY_Type__c;
                String activityType = line.UNITY_Activity_Type__c;
                
                if ( String.isNotBlank(segment) ) {
                    if ( segmentMap.containsKey(segment) ) {
                        for ( Tax_Code_Associations__c tc :segmentMap.get(segment) ) {
                            Boolean match = true;
                            if ( String.isNotBlank(tc.Order_Type__c) ) {
                                List<String> oTypes = tc.Order_Type__c.split(';');
                                Boolean isOT = false;
                                for ( String ot :oTypes) {
                                    if ( ot == orderType ) {
                                        isOT = true;
                                        break;
                                    }
                                }
                                if ( !isOT )
                                    match = false;
                            }
                            if ( String.isNotBlank(tc.Line_Type__c) ) {
                                if ( lineType != tc.Line_Type__c )
                                    match = false;
                            }
                            if ( String.isNotBlank(tc.Activity_Type__c) ) {
                                if ( activityType != tc.Activity_Type__c )
                                    match = false;
                            }
                            if ( match ) {
                                line.UNITY_Tax_Code__c = tc.Tax_Code__c;
                                tcFound = true;
                                break;
                            }
                        }
                    }
                }
                //If the tax code wasn't found at Segment level... check rules at the Line Type level
                if ( !tcFound ) {
                    if ( String.isNotBlank(orderType) ) {
                        if ( ordTypeMap.containsKey(orderType) ) {
                            for ( Tax_Code_Associations__c tc :ordTypeMap.get(orderType) ) {
                                Boolean match = true;
                                if ( String.isNotBlank(tc.Line_Type__c) ) {
                                    if ( lineType != tc.Line_Type__c )
                                      match = false;
                                }
                                if ( String.isNotBlank(tc.Activity_Type__c) ) {
                                    if ( activityType != tc.Activity_Type__c)
                                        match = false;
                                }
                                if ( match ) {
                                    line.UNITY_Tax_Code__c = tc.Tax_Code__c;
                                    tcFound = true;
                                    break;
                                }
                            }
                        }
                    }
                }
                //If the tax code wasn't found at Order Type level... check rules at the Line Type level
                if ( !tcFound ) {
                    if ( String.isNotBlank(lineType) ) {
                        if ( lineTypeMap.containsKey(lineType) ) {
                            for ( Tax_Code_Associations__c tc :lineTypeMap.get(lineType) ) {
                                Boolean match = true;
                                if ( String.isNotBlank(tc.Activity_Type__c) ) {
                                    if ( activityType != tc.Activity_Type__c )
                                        match = false;
                                }
                                if ( match ) {
                                    line.UNITY_Tax_Code__c = tc.Tax_Code__c;
                                    tcFound = true;
                                    break;
                                }
                            }
                        }
                    }
                }
                //If the tax code wasn't found at Line Type level... check rules at the Activity Type level
                if ( !tcFound ) {
                    if ( String.isNotBlank(activityType) ) {
                        if ( actTypeMap.containsKey(activityType) ) {
                            for ( Tax_Code_Associations__c tc :actTypeMap.get(activityType) ) {
                                line.UNITY_Tax_Code__c = tc.Tax_Code__c;
                                tcFound = true;
                                break;
                            }
                        }
                    }
                }
            }
        }
        invLines.addAll(invLinesMap.get(inv.Id));

        return invLines;
    }
    
    global static UNITY_CallAvatax.AvataxResult cancelTaxInvoice(List<Id> recordIds){
        Boolean success = false;
        String message = '';
        Decimal totalTax = 0;
        UNITY_CallAvatax.AvataxResult result;
        //Get the avatax auth values
        List<Key_Value_Store__c> kvslist = new List<Key_Value_Store__c>();
        kvslist = [SELECT Id,Name,Value__c FROM Key_Value_Store__c];
        String user = '';
        String pass = '';
        for(Key_Value_Store__c kvsindex : kvslist){
            if (kvsindex.Name.toLowerCase() == 'avatax account id')
                user = kvsindex.Value__c;
            if (kvsindex.Name.toLowerCase() == 'avatax license key')
                pass = kvsindex.Value__c;
        }
        //Map to hold invoice lines by the ivoice id
        Map<Id,List<UNITY_Invoice_Line_Item__c>> iLinesMap = new Map<Id,List<UNITY_Invoice_Line_Item__c>>();
        //List to hold Invoices
        List<UNITY_Invoice__c> invs = new List<UNITY_Invoice__c>();
        //Now, Need to query order and/or quote records
        if(recordIds.size() > 0){
            
            List<UNITY_Invoice_Line_Item__c> iLines = [SELECT Id,Name,UNITY_Invoice__c,UNITY_Adjusted_Quantity__c,UNITY_Cost__c,UNITY_Discount__c,UNITY_Discount_Amount__c,UNITY_Discounted_Price__c,UNITY_Sales_Tax__c,UNITY_PO_Price__c,UNITY_Tax_Code__c,UNITY_Quantity__c,
                                                       UNITY_Total_Price__c,UNITY_Unit_Price__c ,UNITY_Type__c,UNITY_Activity_Type__c
                                                       FROM UNITY_Invoice_Line_Item__c WHERE UNITY_Invoice__c IN :recordIds];
            
            for(UNITY_Invoice_Line_Item__c iLine :iLines){
                if(!iLinesMap.containsKey(iLine.UNITY_Invoice__c)){
                    List<UNITY_Invoice_Line_Item__c> temp = new List<UNITY_Invoice_Line_Item__c>();
                    temp.add(iLine);
                    iLinesMap.put(iLine.UNITY_Invoice__c,temp);
                }else{
                    iLinesMap.get(iLine.UNITY_Invoice__c).add(iLine);
                }
            }
            
            invs = [SELECT Id,Name,UNITY_SL_Reference_Id__c,UNITY_Order_Type__c,UNITY_Customer__c,UNITY_Customer__r.MH_SL_CustID__c,UNITY_Customer__r.UNITY_Tax_Exempt__c,
                    UNITY_Case__r.Account.ShippingStreet,UNITY_Case__r.Account.ShippingCity,UNITY_Case__r.Account.ShippingStateCode,UNITY_Case__r.Account.ShippingPostalCode,
                    UNITY_Tax_Processed__c,UNITY_Tax_Process_Result__c,UNITY_Invoice_Date__c,UNITY_Tax_Posted__c,
                    UNITY_Case__c,UNITY_Case__r.UNITY_Business_Unit_Account__c,UNITY_Case__r.UNITY_Business_Unit_Account__r.UNITY_Company_Code__c,
                    UNITY_Case__r.UNITY_Business_Unit_Account__r.BillingStreet,UNITY_Case__r.UNITY_Business_Unit_Account__r.BillingCity,UNITY_Case__r.UNITY_Business_Unit_Account__r.BillingStateCode,UNITY_Case__r.UNITY_Business_Unit_Account__r.BillingPostalCode
                    FROM UNITY_Invoice__c WHERE Id IN :recordIds];
        }
        //If there are work orders to get tax for...
        if(invs.size() > 0){
            //Begin constructing the avatax callout payload
            avataxAvalaraComServicesAlt.TaxSvcAltSecSoap taxSvc = new avataxAvalaraComServicesAlt.TaxSvcAltSecSoap();
            taxSvc.Security = new avataxAvalaraComServicesAlt.Security();
            taxSvc.Security.UsernameToken = new avataxAvalaraComServicesAlt.UsernameToken_element();
            taxSvc.Security.UsernameToken.Username = user;
            taxSvc.Security.UsernameToken.Password = pass;
            taxSvc.Profile = new avataxAvalaraComServicesAlt.Profile();
            taxSvc.Profile.Name = '1.0.0';
            taxSvc.Profile.Client = 'My Application Name,1.0';
            taxSvc.Profile.Machine = 'My Machine Name';
            for(UNITY_Invoice__c inv :invs){
                //Build the tax request for the order
                avataxAvalaraComServicesAlt.GetTaxRequest gtreq = new avataxAvalaraComServicesAlt.GetTaxRequest();
                gtreq.DocType = 'ReturnInvoice';
                gtreq.DocCode = inv.UNITY_SL_Reference_Id__c;
                gtreq.ReferenceCode = inv.Id;
                gtreq.CompanyCode = inv.UNITY_Case__r.UNITY_Business_Unit_Account__r.UNITY_Company_Code__c;
                gtreq.CustomerCode = inv.UNITY_Customer__r.MH_SL_CustID__c;
                gtreq.Discount = 0; 
                gtreq.DetailLevel = 'Tax';
                gtreq.HashCode = 0;
                gtreq.ServiceMode = 'Automatic';
                gtreq.ExchangeRate = 0;
                gtreq.ExchangeRateEffDate = date.today();
                gtreq.PaymentDate = date.today();
                gtreq.ExemptionNo = (inv.UNITY_Customer__r.UNITY_Tax_Exempt__c) ? 'Exempt' : '';
                //Now Need to add the addresses
                //Origni Address (The Business Unity performing the work/sale)
                avataxAvalaraComServicesAlt.BaseAddress orgAddr = new avataxAvalaraComServicesAlt.BaseAddress();
                orgAddr.AddressCode = 'Origin';
                orgAddr.Line1 = inv.UNITY_Case__r.UNITY_Business_Unit_Account__r.BillingStreet;//***BU BillingStreet***
                orgAddr.City = inv.UNITY_Case__r.UNITY_Business_Unit_Account__r.BillingCity;//***BU BillingCity***
                orgAddr.Region = inv.UNITY_Case__r.UNITY_Business_Unit_Account__r.BillingStateCode;//***BU BillingStateCode***
                orgAddr.PostalCode = inv.UNITY_Case__r.UNITY_Business_Unit_Account__r.BillingPostalCode;//***BU BillingPostalCode***
                orgAddr.TaxRegionId = 0;
                avataxAvalaraComServicesAlt.BaseAddress dstAddr = new avataxAvalaraComServicesAlt.BaseAddress();
                //Destination Address (The Location Shipping Address)
                dstAddr.AddressCode = 'Destination';
                dstAddr.Line1 = inv.UNITY_Case__r.Account.ShippingStreet;//'11827 Tech Com Dr #116'; 
                dstAddr.City = inv.UNITY_Case__r.Account.ShippingCity;//'San Antonio'; 
                dstAddr.Region = inv.UNITY_Case__r.Account.ShippingStateCode;//'TX'; 
                dstAddr.PostalCode = inv.UNITY_Case__r.Account.ShippingPostalCode;//'78233'; 
                dstAddr.TaxRegionId = 0;
                //Add the addresses to the tax request
                gtreq.Addresses = new avataxAvalaraComServicesAlt.ArrayOfBaseAddress();
                gtreq.Addresses.BaseAddress = new avataxAvalaraComServicesAlt.BaseAddress[2];
                gtreq.Addresses.BaseAddress[0] = orgAddr;
                gtreq.Addresses.BaseAddress[1] = dstAddr;
                //Set the address codes on the tax request
                gtreq.OriginCode = orgAddr.AddressCode;
                gtreq.DestinationCode = dstAddr.AddressCode;
                //Get the tax code for the order lines
                List<UNITY_Invoice_Line_Item__c> invLines = iLinesMap.get(inv.Id);
                //Now Need to add tyhe line items
                gtreq.Lines = new avataxAvalaraComServicesAlt.ArrayOfLine();
                gtreq.Lines.Line = new avataxAvalaraComServicesAlt.Line[invLines.size()];
                for(Integer i = 0; i < invLines.size(); i++){
                    //Get the order item
                    UNITY_Invoice_Line_Item__c item = invLines[i];
                    //Create the line for the tax request
                    gtreq.Lines.Line[i] = new avataxAvalaraComServicesAlt.Line();
                    gtreq.Lines.Line[i].No = item.Name;
                    gtreq.Lines.Line[i].Amount = (item.UNITY_Discounted_Price__c != null) ? (item.UNITY_Discounted_Price__c * -1) : 0;
                    gtreq.Lines.Line[i].Qty = (item.UNITY_Adjusted_Quantity__c != null) ? item.UNITY_Adjusted_Quantity__c : 0;
                    gtreq.Lines.Line[i].Discounted = (item.UNITY_Discount_Amount__c != null && item.UNITY_Discount_Amount__c > 0) ? true : false;
                    gtreq.Lines.Line[i].OriginCode = 'Origin';
                    gtreq.Lines.Line[i].DestinationCode = 'Destination';
                    gtreq.Lines.Line[i].TaxCode = item.UNITY_Tax_Code__c; 
                }
                gtreq.DocDate = inv.UNITY_Invoice_Date__c;
                gtreq.Commit_x = true;
                //Set the tax result
                avataxAvalaraComServicesAlt.GetTaxResult gtres = null;
                //Try to make the call to avatax
                try{
                    List<UNITY_Invoice_Line_Item__c> itemsList = new List<UNITY_Invoice_Line_Item__c>();
                    gtres = taxSvc.GetTax(gtreq);
                    if(gtres.ResultCode == 'Success'){
                        success = true;
                        totalTax = gtres.TotalTax;
                        if(!Test.isRunningTest()){
                            message = 'Result Code: '+gtres.ResultCode + '\n' +
                            'Total Tax: $' + gtres.TotalTax+ '\n' + 
                            'Total Amount: $' + gtres.TotalAmount + '\n' + 
                            'Tax Addeses: Site/Location: ' + gtres.TaxAddresses.TaxAddress[0].Region + ', BU:  ' + gtres.TaxAddresses.TaxAddress[1].Region;
                        }
                        inv.UNITY_Tax_Posted__c = true;
                    }else{
                        success = false;
                        message =  'Result Code: '+gtres.ResultCode + '\n';
                        message += 'Summary: ' + ((gtres.Messages != null) ? gtres.Messages.Message[0].Summary : 'Not available')+'\n';
                        message += 'Details: '+((gtres.Messages != null) ? gtres.Messages.Message[0].Details: 'Not available')+'\n';
                        message += 'Refers To: '+((gtres.Messages != null) ? gtres.Messages.Message[0].RefersTo: 'Not available')+'\n';
                        message += 'Source: '+((gtres.Messages != null) ? gtres.Messages.Message[0].Source: 'Not available');
                    }
                    inv.UNITY_Tax_Processed__c = true;
                    inv.UNITY_Tax_Process_Result__c = message;
                    update inv;
                }catch(Exception ex){
                    success = false;
                    message = 'CancelInvoiceTax Threw an Exception: ' + ex.getmessage();
                    //System.debug('================== ' + message);
                }
            } 
        }
        result = new UNITY_CallAvatax.AvataxResult(success,message,totalTax);
        return result;
    }
    
    /**Structure of the result returned by the getTax method
     * This class contains a success flag that denotes if the method completed successfully.
     * It also contains a message string that will contain any error messages encountered during the callout.
     * */
    global class AvataxResult{
        public Boolean success {get; private set;}
        public String message {get; private set;}
        public Decimal totalTax {get; private set;}
        public Map<Id,String> messageMap {get; set;}
        public Map<Id,Decimal> totalTaxMap {get; set;}
        /**Class controller
        *@param s Boolean. Success true or false.
        *@param m String. Any message.
        */
        public AvataxResult(Boolean s, String m, Decimal t){
            this.success = s;
            this.message = m;
            this.totalTax = t;
        }
    }
}