public with sharing class  MSPFS_NewQuoteItemContExt {


    public UNITY_Proposal__c newQuote { get; private set; }
    public List<QuoteItemWrapper> quoteLines {get; set;}

    public Boolean hasError { get; private set; }
    public Boolean finalize { get; set; }
    public Boolean saveComplete { get; private set; }
    public Boolean canEdit { get; private set; }

    public String saveResult { get; private set; }
    public String message { get; private set; }


    private String businessUnit = '';
    private String quoteType = '';


    public MSPFS_NewQuoteItemContExt( ApexPages.StandardController stdController ) {
        
        newQuote = quoteQuery( stdController.getRecord().Id );

        businessUnit = newQuote.UNITY_Business_Unit__c;
        quoteType = newQuote.UNITY_Work_Order_Type__c;

        saveResult = '';
        message = '';
        hasError = false;
        finalize = false;
        saveComplete = false;
        canEdit = true;
        
        Set<String> statusToNotModify = new Set<String> { UNITY_Constants.QT_STATUS_CUSTOMER_APPROVED, 
                                                            UNITY_Constants.QT_STATUS_PENDING_MANAGER_APPROVAL, 
                                                            UNITY_Constants.QT_STATUS_MANAGER_APPROVED, 
                                                            UNITY_Constants.QT_STATUS_PENDING_CUSTOMER_REVIEW, 
                                                            UNITY_Constants.QT_STATUS_QUOTE_FINALIZED 
        };

        if ( statusToNotModify.contains( newQuote.UNITY_Proposal_Status__c ) ) {
            hasError = true;
            message = 'This Quote cannot be modified.';
            canEdit = false;
            Apexpages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, 'Error: ' + message ) );
        }

        List<UNITY_Proposal_Line_Item__c> oldLines = quoteLineItemQuery( newQuote.Id );

        quoteLines = new List<QuoteItemWrapper>();
        if ( !oldLines.isEmpty() ) {
            for ( UNITY_Proposal_Line_Item__c line : oldLines ) {
                Integer index = quoteLines.size();
                QuoteItemWrapper wrapper = new QuoteItemWrapper( line, businessUnit, quoteType, index );
                quoteLines.add(wrapper);
            }
        }
    }

    private static UNITY_Proposal__c quoteQuery( Id quoteId ) {
        return [SELECT Id, Name, UNITY_Proposal_Status__c, UNITY_Total_Cost__c, UNITY_Business_Unit__c, UNITY_Final_Price__c, UNITY_Work_Order_Type__c 
                FROM UNITY_Proposal__c WHERE Id =: quoteId];
    }

    private static List<UNITY_Proposal_Line_Item__c> quoteLineItemQuery( Id quoteId ) {
        return [SELECT Id, Name, UNITY_Proposal__c, UNITY_Quantity__c, UNITY_Activity_Type__c, UNITY_Cost__c, UNITY_Is_Vendor_Supply__c, UNITY_Total_Cost__c, 
                    UNITY_Type__c, UNITY_Asset__c, UNITY_Vendor_Holiday_Multiplier__c, UNITY_Vendor_OT_Multiplier__c, UNITY_Unit_Price__c, 

                    UNITY_Product__c,
                    UNITY_Product__r.Name, 
                    UNITY_Product__r.ProductCode, 
                    UNITY_Product__r.UNITY_Product_Type__c, 

                    UNITY_Part_Location__c,
                    UNITY_Part_Location__r.Name,

                    UNITY_Part_Source__c,
                    UNITY_Part_Source__r.UNITY_Miner_Regional_Office__c

                FROM UNITY_Proposal_Line_Item__c 
                WHERE UNITY_Proposal__c = :quoteId 
                ORDER BY Name ASC];
    }
/*
        
        UNITY_Location_AvailableQuantity__c, UNITY_Location_QOH_LastChecked__c, UNITY_Location_OOS__c, PricebookEntryId,   
*/

    public void addItem() {
        UNITY_Proposal_Line_Item__c newItem = new UNITY_Proposal_Line_Item__c(
            UNITY_Proposal__c = this.newQuote.Id,
            UNITY_Unit_Price__c = 0
        );
        Integer index = quoteLines.size();
        QuoteItemWrapper wrapper = new QuoteItemWrapper( newItem, this.businessUnit, this.quoteType, index );
        this.quoteLines.add( wrapper );
    }

    public void deleteSel() {
        this.hasError = false;
        this.message = '';
        SavePoint sp = Database.setSavepoint();
        List<UNITY_Proposal_Line_Item__c> toDelete = new List<UNITY_Proposal_Line_Item__c>();
        List<QuoteItemWrapper> newLines = new List<QuoteItemWrapper>();
        for ( QuoteItemWrapper line : quoteLines ) {
            if ( line.sel ) {
                if ( line.item != null ) {
                    if ( String.isNotBlank( line.item.Id ) )
                        toDelete.add( line.item );
                }
            } else {
                newLines.add( line );
            }
        }
        try {
            if ( !toDelete.isEmpty() ) {
                delete toDelete;
                this.newQuote = quoteQuery( this.newQuote.Id );
            }
            this.quoteLines = newLines;
            Integer i = 0;
            for ( QuoteItemWrapper line : quoteLines ) {
                line.index = i;
                i++;
            }
        } catch ( Exception e ) {
            this.hasError = true;
            this.message = e.getMessage();
            Apexpages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, 'Error: ' + message ) );
            Database.rollback( sp );
        }
    }

    public void validateLines(){
        if ( !this.quoteLines.isEmpty() ) {
            List<QuoteItemWrapper> newLines = new List<QuoteItemWrapper>();
            for ( QuoteItemWrapper line : quoteLines ) {
                if ( String.isNotBlank(line.item.UNITY_Product__c) ) {
                    if ( String.isBlank(line.item.UNITY_Type__c) ) {
                        line.item.UNITY_Type__c.addError('This field is required');
                        this.hasError = true;
                    }
                    if ( String.isBlank(line.item.UNITY_Activity_Type__c) ) {
                        line.item.UNITY_Activity_Type__c.addError('This field is required');
                        this.hasError = true;
                    }
                    if ( line.item.UNITY_Quantity__c == null || line.item.UNITY_Quantity__c == 0 ) {
                        line.item.UNITY_Quantity__c.addError('This field is required');
                        this.hasError = true;
                    }
                    if ( line.item.UNITY_Is_Vendor_Supply__c && 
                      ( line.item.UNITY_Activity_Type__c.indexOf('Labor') == -1 && line.item.UNITY_Activity_Type__c.indexOf('Travel') == -1 ) &&
                      ( line.item.UNITY_Cost__c == null ) ) {
                          line.item.UNITY_Cost__c.addError('This field is required');
                          this.hasError = true;
                    }
                    if ( line.isMinerSource && line.item.UNITY_Part_Location__c == null ) {
                        line.item.UNITY_Part_Location__c.addError('This field is required when the Part Source is a Bueiness Unit');
                        this.hasError = true;
                    }
                    if ( !this.hasError )
                        newLines.add(line);
                }
            }
            if ( !hasError )
                this.quoteLines = newLines;
        }
    }

    public PageReference doQuickSave() {
        PageReference pr;
        this.saveResult = '';
        this.saveComplete = false;
        this.hasError = false;
        this.message = '';
        SavePoint sp = Database.setSavepoint();
        if ( !this.canEdit ) {
            pr = new PageReference( '/' + this.newQuote.Id );
            pr.setRedirect( true );
            return pr;
        }
        try {
            validateLines();
            if ( !this.hasError ) {
                Set<Id> itemIds = new Set<Id>();
                List<UNITY_Proposal_Line_Item__c> toInsert = new List<UNITY_Proposal_Line_Item__c>();
                List<UNITY_Proposal_Line_Item__c> toUpdate = new List<UNITY_Proposal_Line_Item__c>();
                for ( QuoteItemWrapper line : quoteLines ) {
                    system.debug(' ### line: '+line);
                    if ( String.isBlank( line.item.Id ) ) {
                        toInsert.add( line.item );
                    } else {
                        toUpdate.add( line.item );
                        itemIds.add( line.item.Id );
                    }
                }
                if ( !toInsert.isEmpty() ) {
                    insert toInsert;
                    for ( UNITY_Proposal_Line_Item__c item :toInsert ) {
                        itemIds.add( item.Id );
                    }
                }
                if ( !toUpdate.isEmpty() ) {
                    update toUpdate;
                }

                this.newQuote = quoteQuery( newQuote.Id );
                this.quoteLines = new List<QuoteItemWrapper>();
                List<UNITY_Proposal_Line_Item__c> oldLines = quoteLineItemQuery( newQuote.Id );

                if ( !oldLines.isEmpty() ) {
                    Integer i = 0;
                    for ( UNITY_Proposal_Line_Item__c line : oldLines ) {
                        QuoteItemWrapper wrapper = new QuoteItemWrapper( line, this.businessUnit, this.quoteType, i );
                        quoteLines.add( wrapper );
                        i++;
                    }
                }
            } else {
                return null;
            }
        } catch( Exception e ) {
            this.hasError = true;
            this.message = e.getMessage();
            if ( e.getTypeName() == 'System.DmlException' ) {
                this.message = e.getDMLMessage( 0 );
                if ( !ApexPages.hasMessages() )
                    Apexpages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, 'Error: ' + message ) );
            } else {
                Apexpages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, 'Error: ' + message ) );
            }
            Database.rollback( sp );
        }
        return null;
    }

    public PageReference doSave() {
        PageReference pr;
        this.saveResult = '';
        this.saveComplete = false;
        this.hasError = false;
        this.message = '';
        SavePoint sp = Database.setSavepoint();
        if ( !this.canEdit ) {
            pr = new PageReference( '/' + this.newQuote.Id );
            pr.setRedirect( true );
            return pr;
        }
        try {
            validateLines();
            if ( !this.hasError ) {
                List<UNITY_Proposal_Line_Item__c> toInsert = new List<UNITY_Proposal_Line_Item__c>();
                List<UNITY_Proposal_Line_Item__c> toUpdate = new List<UNITY_Proposal_Line_Item__c>();
                for ( QuoteItemWrapper line : quoteLines ) {
                    system.debug(' ### line: '+line);
                    if ( String.isBlank( line.item.Id ) ) {
                        toInsert.add( line.item );
                    } else {
                        toUpdate.add( line.item );
                    }
                }
                if ( !toInsert.isEmpty() ) {
                    insert toInsert;
                }
                if ( !toUpdate.isEmpty() ) {
                    update toUpdate;
                }
                if ( this.finalize ) {
                    this.newQuote.UNITY_Proposal_Status__c = 'Final';
                    update this.newQuote;
                }
                this.saveComplete = true;
            } else {
                return null;
            }
        } catch( Exception e ) {
            this.hasError = true;
            this.message = e.getMessage();
            Database.rollback( sp );
            if ( e.getTypeName() == 'System.DmlException' ) {
                this.message = e.getDMLMessage( 0 );
                if ( !ApexPages.hasMessages() )
                    Apexpages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, 'Error: ' + message ) );
            }else{
                Apexpages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, 'Error: ' + message ) );
            }
        }
        return null;
    }

    public void onProductChange(){
        Integer i = Integer.valueOf( ApexHelper.getParam('index') );
        String value = ApexHelper.getParam('myValue');
        for ( QuoteItemWrapper line : quoteLines ) {
            if ( line.index == i ) {
                line.item.UNITY_Product__c = ( value != null && value != '' ) ? value : null;
                line.onProductChange();
                break;
            }
        }
    }


    public class QuoteItemWrapper {

        public UNITY_Proposal_Line_Item__c item { get; set; }
        //public PriceBookEntry pbe {get; set;}
        public Boolean sel { get; set; }
        public Boolean isMinerSource { get; private set; }
        public Boolean inStock {get; private set;}
        public Decimal inStockQty {get; private set;}
        public DateTime inStockLastMod {get; private set;}
        public Boolean hasError { get; set; }
        private String businessUnit { get; set; }
        private String quoteType { get; set; }
        public Integer index { get; set; }

        public QuoteItemWrapper( UNITY_Proposal_Line_Item__c quoteLine, String bu, String qt, Integer i ) {
            this.item = quoteLine;
            this.sel = false;
            this.hasError = false;
            this.businessUnit = bu;
            this.quoteType = qt;
            this.index = i;

            this.isMinerSource = quoteLine.UNITY_Part_Source__r.UNITY_Miner_Regional_Office__c;
            this.inStock = true; //quoteLine.UNITY_Location_OOS__c;
            this.inStockQty = 1; //quoteLine.UNITY_Location_AvailableQuantity__c;
            this.inStockLastMod = system.today(); //quoteLine.UNITY_Location_QOH_LastChecked__c;
        }

        public void onProductChange() {
            if ( String.isNotBlank(this.item.UNITY_Product__c) ) {
                Product2 selectedProduct = [SELECT Id, Name, ProductCode, UNITY_Product_Type__c FROM Product2 WHERE Id =: this.item.UNITY_Product__c];
                this.item.UNITY_Product__c = selectedProduct.Id;
                this.item.UNITY_Product__r = selectedProduct;
                system.debug('this.item.UNITY_Product__c: '+this.item.UNITY_Product__c);
                if ( String.isNotBlank(this.item.UNITY_Product__r.UNITY_Product_Type__c) ) {
                    if((this.businessUnit == 'MNS' || this.businessUnit == 'NSBS') && this.item.UNITY_Product__r.UNITY_Product_Type__c.contains('Labor')){
                        this.item.UNITY_Type__c = 'Vendor Services';
                        this.item.UNITY_Activity_Type__c = 'Vendor Standard Labor';
                        this.item.UNITY_Is_Vendor_Supply__c = true;
                        this.item.UNITY_Part_Source__c = null;
                        onPartSourceChange();
                    }else if(this.item.UNITY_Product__r.UNITY_Product_Type__c.contains('Labor') ){
                        if(this.quoteType == 'Project')
                            this.item.UNITY_Type__c = 'Labor - Installation';
                        else 
                            this.item.UNITY_Type__c = 'Labor - Service';
                        if(this.quoteType == 'PM')
                            this.item.UNITY_Activity_Type__c = 'Preventative Maintenance';
                        else
                            this.item.UNITY_Activity_Type__c = 'Standard Labor';
                        this.item.UNITY_Part_Source__c = null;
                        onPartSourceChange();
                    }else if((this.businessUnit == 'MNS' || this.businessUnit == 'NSBS') && this.item.UNITY_Product__r.UNITY_Product_Type__c.contains('Travel')){
                        this.item.UNITY_Type__c = 'Vendor Services';
                        this.item.UNITY_Activity_Type__c = 'Vendor Standard Travel';
                        this.item.UNITY_Is_Vendor_Supply__c = true;
                        this.item.UNITY_Part_Source__c = null;
                        onPartSourceChange();
                    }else if(this.item.UNITY_Product__r.UNITY_Product_Type__c.contains('Travel')){
                        this.item.UNITY_Type__c = 'Travel';
                        this.item.UNITY_Activity_Type__c = 'Travel';
                        this.item.UNITY_Part_Source__c = null;
                        onPartSourceChange();
                    }else if(this.item.UNITY_Product__r.UNITY_Product_Type__c.contains('Part')){
                        this.item.UNITY_Type__c = 'Parts';
                        if(this.quoteType == 'Service' || this.quoteType == 'PM')
                            this.item.UNITY_Activity_Type__c = 'Parts - Service and Remodel';
                        else if(this.quoteType == 'Project')
                            this.item.UNITY_Activity_Type__c = 'Parts - New Construction';
                    }else if(this.item.UNITY_Product__r.UNITY_Product_Type__c.contains('Freight')){
                        this.item.UNITY_Type__c = 'Parts';
                        if(this.quoteType == 'Service' || this.quoteType == 'PM')
                            this.item.UNITY_Activity_Type__c = 'Freight - Service and Remodel';
                        else if(this.quoteType == 'Project')
                            this.item.UNITY_Activity_Type__c = 'Freight - New Construction';
                        this.item.UNITY_Part_Location__c = null;
                        onStockLocationChange();
                    }
                }
            } else {
                this.item.UNITY_Product__c = null;
                this.item.UNITY_Type__c = null;
                this.item.UNITY_Activity_Type__c = null;
                this.item.UNITY_Is_Vendor_Supply__c = false;
                this.item.UNITY_Part_Source__c = null;
                onPartSourceChange();
            }
        }

        public void onCostQtyChange(){
            if ( this.item.UNITY_Quantity__c != null && this.item.UNITY_Cost__c != null ) {
                this.item.UNITY_Total_Cost__c = ( this.item.UNITY_Cost__c * this.item.UNITY_Quantity__c );
            } else {
                this.item.UNITY_Total_Cost__c = null;
            }
        }

        public void onVendorSupplyChange(){
            if ( String.isNotBlank(this.item.UNITY_Product__r.UNITY_Product_Type__c) ) {
                if ( this.item.UNITY_Product__r.UNITY_Product_Type__c.contains('Part') && this.item.UNITY_Is_Vendor_Supply__c ) {
                    this.item.UNITY_Type__c = 'Vendor Services';
                } else if ( this.item.UNITY_Product__r.UNITY_Product_Type__c.contains('Part') ) {
                    this.item.UNITY_Type__c = 'Parts';
                } else if ( this.item.UNITY_Product__r.UNITY_Product_Type__c.contains('Freight') && this.item.UNITY_Is_Vendor_Supply__c ) {
                    this.item.UNITY_Type__c = 'Vendor Services';
                } else if ( this.item.UNITY_Product__r.UNITY_Product_Type__c.contains('Freight') ) {
                    this.item.UNITY_Type__c = 'Parts';
                } else if ( this.item.UNITY_Product__r.UNITY_Product_Type__c.contains('Labor') && this.item.UNITY_Is_Vendor_Supply__c ) {
                    this.item.UNITY_Type__c = 'Vendor Services';
                } else if ( this.item.UNITY_Product__r.UNITY_Product_Type__c.contains('Labor') ) {
                    if ( this.quoteType == 'Service'){
                        this.item.UNITY_Type__c = 'Labor - Service';
                    } else {
                        this.item.UNITY_Type__c = 'Labor - Installation';
                    }
                } else if ( this.item.UNITY_Product__r.UNITY_Product_Type__c.contains('Travel') && this.item.UNITY_Is_Vendor_Supply__c) {
                    this.item.UNITY_Type__c = 'Vendor Services';
                } else if ( this.item.UNITY_Product__r.UNITY_Product_Type__c.contains('Travel') ) {
                    this.item.UNITY_Type__c = 'Travel';
                }
            }
            if ( this.item.UNITY_Is_Vendor_Supply__c ) {
                this.item.UNITY_Part_Source__c = null;
                onPartSourceChange();
            }
        }
        
        public void onPartSourceChange(){
            if ( String.isNotBlank(this.item.UNITY_Part_Source__c) ) {
                Account a = [SELECT Id, Name, UNITY_Miner_Regional_Office__c FROM Account WHERE Id = : this.item.UNITY_Part_Source__c LIMIT 1];

                if ( a.UNITY_Miner_Regional_Office__c ) {
                    this.isMinerSource = true;
                    List<FSO__Location__c> stockLocs = [SELECT Id,Name,FSO__Account__c FROM FSO__Location__c WHERE FSO__Account__c = : a.Id];

                    if ( !stockLocs.isEmpty() ) {

                        if ( stockLocs.size() == 1 ) {
                            this.item.UNITY_Part_Location__c = stockLocs[0].Id;
                            onStockLocationChange();
                        } else {
                            //What to to if there are many stock locations available???
                        }
                    } else {
                        this.item.UNITY_Part_Location__c = null;
                        onStockLocationChange();
                    }
                } else {
                    this.item.UNITY_Part_Location__c = null;
                    this.isMinerSource = false;
                    onStockLocationChange();
                }
            } else {
                this.item.UNITY_Part_Location__c = null;
                this.isMinerSource = false;
                onStockLocationChange();
            }
        }
        
        public void onStockLocationChange(){
            if ( String.isNotBlank( this.item.UNITY_Part_Location__c ) && String.isNotBlank( this.item.UNITY_Product__c ) ) {
                String locId = this.item.UNITY_Part_Location__c;
                String prodId = this.item.UNITY_Product__c;
                List<FSO__LocationStock__c> lockStock = new List<FSO__LocationStock__c>();
                lockStock = [SELECT Id,Name,FSO__Quantity__c,FSO__Location__c,FSO__Product__c,LastModifiedDate,UNITY_Min__c FROM FSO__LocationStock__c WHERE FSO__Location__c = :locId AND FSO__Product__c = :prodId LIMIT 1];
                if ( lockStock.size() > 0 ) {
                    this.inStockQty = lockStock[0].FSO__Quantity__c;
                    this.inStockLastMod = lockStock[0].LastModifiedDate;
                    this.inStock = (lockStock[0].FSO__Quantity__c > 0);
                } else {
                    this.inStockQty = 0;
                    this.inStockLastMod = null;
                    this.inStock = false;
                }
            } else {
                this.inStockQty = null;
                this.inStockLastMod = null;
                this.inStock = false;
            }
        }
    }



}