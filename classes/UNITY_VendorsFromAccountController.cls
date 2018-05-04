/*
*   @programer:    Samuel Astol
*   @description:  UNITY_availableVendorsAccount controller 
*   @date:         12/09/2015             
*/

public class UNITY_VendorsFromAccountController {

    // context account id   
    private Id onAccountId{get;set;}
    
    // context account  
    private Account onAccount{get;set;}

    // list of vendors which cover the location and are preferred by the customer or are not marked as do not use in the account record
    private list<UNITY_wrapperVendorByTrade> totalList{get;set;}
    
    
    // list of vendors filtered and been displayed to the user
    public list<UNITY_wrapperVendorByTrade> vendors{get;set;}
    
    // trade filter 
    public String tradeFilter{get;set;}
    
    // record type filter 
    public String recordTypeFilter{get;set;}
    
    // list of trades options for the dropdown 
    public Map<String,String> tradeOptions{get;set;}
    
    public List<id> trades{get;set;}
    
    public boolean notVendorsAtLocation{get;set;}
    
    public UNITY_VendorsFromAccountController(ApexPages.StandardController stdController ){
        
        recordTypeFilter = 'SR';
        
        onAccount = null; 
        
        trades = new List<id>();
        List<id> aux_trades = new List<id>();
        
        tradeOptions = new Map<String,String>();
        
        vendors = new list<UNITY_wrapperVendorByTrade>();
        
        onAccountId = stdController.getId();
        
        notVendorsAtLocation = false;
        
        // right now we are allowing End user Account in the CA, MX and US
        list<Account> aux_accountList = new list<Account>([SELECT id, ShippingPostalCode , ShippingCountryCode   
                                                           FROM  Account 
                                                           WHERE id = :onAccountId AND ShippingCountryCode IN :UNITY_Constants.allowVendorCountries]);
        
        
        if(aux_accountList.size()==1) onAccount = aux_accountList.get(0);
        
        String locationKey = '';
        
        String firstTrade = null;
        
        if(onAccount != null){
            
            getVendors(false);
            
            if(totalList != null){
                
                for(UNITY_wrapperVendorByTrade vendor :totalList){
                    
                    if(firstTrade==null)firstTrade = vendor.tradeId; else if(tradeOptions.get(vendor.tradeId)==null)aux_trades.add(vendor.tradeId);
                    tradeOptions.put(vendor.tradeId,vendor.tradeName);
                                        
                }
            
            }
                
        }
        
        trades.add(firstTrade);
        trades.addAll(aux_trades);
        tradeFilter = firstTrade ;
        
        vendors = UNITY_Vendor_Utils.wrapperVendorByTradeFilter(totalList, recordTypeFilter, tradeFilter,null,null);
        
    }
    
    /*
     *   @programer:    Samuel Astol
     *   @description:  fiter vendors by trade
     *   @date:         12/09/2015            
     */
    public void filterByTrade(){
        
        vendors = UNITY_Vendor_Utils.wrapperVendorByTradeFilter(totalList, recordTypeFilter, tradeFilter,null,null);
        
    } 
    
    /*
     *   @programer:    Samuel Astol
     *   @description:  fiter vendors by record type
     *   @date:         12/09/2015            
     */
    public void filterByRecordType(){
        
        vendors = UNITY_Vendor_Utils.wrapperVendorByTradeFilter(totalList, recordTypeFilter, tradeFilter,null,null);
        
    } 
    

    /*
    *   @programer:    Samuel Astol
    *   @description:  get all vendors at the location 
    *   @date:         12/14/2015             
    */
    public void getVendors(boolean justAssignmentVendor){
        
        //Map< id, list<UNITY_wrapperVendorByTrade>> aux_map =  UNITY_Vendor_Utils.getVendorsSpecific(new list<id>{onAccountId}, justAssignmentVendor);
        Map< id, list<UNITY_wrapperVendorByTrade>> aux_map =  UNITY_Vendor_Utils.getVendorsSpecific(new list<id>{onAccountId}, Account.getSObjectType(), null, false, false );    
        if(aux_map.get(onAccountId) != null){
            
            totalList = aux_map.get(onAccountId);
            if(totalList.size()==0){
                notVendorsAtLocation = true;
            }
        }else{
            notVendorsAtLocation = true;
        }
         
    }
    
    
    
}