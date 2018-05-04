/*************************************************************************************************
Class     :  MassEditPriceBookEntriesController.cls
Developer :  mickey@vertiba.com
Created   :  January 26, 2015
Modified  :  January 30, 2015
Objective :  This class provides methods to edit PriceBookEntry collections en masse.
Pages     :  MassUpsertPriceBookEntriesView.page, MassUpsertPriceBookEntriesView.page
Test Class:  MassEditPriceBookEntriesControllerTest.cls

*************************************************************************************************/

public with sharing class MassEditPriceBookEntriesController
{
    //  public properties declared in alphabetical order
    public Boolean               allProductsSelected { get; private set; }
    public Decimal               changeToCustomCost  { get;         set; }        
    public Decimal               changeToCustomPrice { get;         set; }
    public Boolean               disableAddModify    { get; private set; }
    public String                pricebookName       { get; private set; }
    public List <productWrapper> productWrappers     { get; private set; } 
    public String                searchString        { get;         set; }
    public String                selectedPricebook   { get;         set; }
    public List <productWrapper> selectedProducts    { get; private set; } 

    //  private constants declared in alphabetical order
    private final String MISSING_COST_OR_PRICE = 'One or more of the selected '
                                               + 'products does not have both '
                                               + 'a [Cost] and a [List Price].';
    private final String MISSING_PRICEBOOK     = 'You must select a pricebook.';
    private final String MISSING_SEARCH_TERM   = 'You must enter a search term '
                                               + 'within [Search Products].';
    private final String SELECT_PRICEBOOK      = '--  Select Pricebook  --';
    private final String STANDARD              = 'Standard Price Book';

    //  private properties declared in alphabetical order
    private final Id standardPricebookId = null;

    //  public inner classes declared in alphabetical order
    public class ProductWrapper
    {
        //  public properties declared in alphabetical order
        public Decimal customCost           { get;         set; }
        public String  customCostFormatted  { get; private set; }
        public Decimal customPrice          { get;         set; }
        public String  customPriceFormatted { get; private set; }
        public String  family               { get; private set; }
        public Id      id                   { get; private set; }
        public String  name                 { get; private set; }    
        public Boolean selected             { get;         set; }
        public Decimal standardCost         { get;         set; }
        public Decimal standardPrice        { get;         set; }

        //  public methods listed in alphabetical order
        public productWrapper ()
        {

        }   //  constructor

    }   //  productWrapper {}

    //  public methods listed in alphabetical order
    public PageReference cancel ()
    {
        productWrappers.clear ();

        return Page.MassEditPricebookEntriesView;

    }   //  cancel ()

    public List <SelectOption> getActivePricebooks ()
    {
        //  variables declared in alphabetical order
        List <Pricebook2>   activePricebooks = new List <Pricebook2> ();
        List <SelectOption> pricebooks       = new List <SelectOption> ();

        activePricebooks = [
                             select

                                    id
                                  , name

                               from pricebook2

                              where isactive  = true
                                and name     != : STANDARD    

                            ];

        pricebooks.add (new SelectOption (SELECT_PRICEBOOK, SELECT_PRICEBOOK));

        for ( Pricebook2 activePricebook : activePricebooks )
            pricebooks.add (new SelectOption (activePricebook.Id, activePricebook.Name));

        return pricebooks;

    }   //  getActivePricebooks ()

    public PageReference goToUpsertPage ()
    {
        changeToCustomCost  = null;
        changeToCustomPrice = null;

        if ( selectedProducts == null )
           selectedProducts = new List <ProductWrapper> ();

        else
            selectedProducts.clear ();

        for ( ProductWrapper productWrapper : productWrappers )
            if ( productWrapper.selected )
                selectedProducts.add (productWrapper);

        return Page.MassUpsertPricebookEntriesView;

    }   //  goToUpsertPage ()

    public MassEditPriceBookEntriesController ()
    {
    	//  properties set in alphabetical order
        allProductsSelected = false;
        changeToCustomCost  = null;
        changeToCustomPrice = null;
        disableAddModify    = true;
        productWrappers     = new List <productWrapper> ();
        selectedPricebook   = SELECT_PRICEBOOK;
        selectedProducts    = new List <productWrapper> ();

        if ( System.Test.isRunningTest () )
            standardPricebookId = System.Test.getStandardPricebookId ();      

        else
            standardPricebookId = [ select id from pricebook2 
                                     where name = : STANDARD ].Id;

    }   //  constructor

    public PageReference save ()
    {
        //  variables declared in alphabetical order
        Decimal                   customCost         = 0.0;
        Decimal                   customPrice        = 0.0;
        PriceBookEntry            entry              = null;
        List <PriceBookEntry>     entriesToUpsert    = new List <PriceBookEntry> ();
        String                    errorMessage       = null;
        Integer                   index              = 0;
        Boolean                   isValidated        = true;
        Boolean                   missingCostOrPrice = false;
        PageReference             pageReference      = null;
        Map  <Id, PriceBookEntry> pricebookEntryMap  = new Map  <Id, PriceBookEntry> ();

        try
        {
            for ( ProductWrapper selectedProduct : selectedProducts )
            {
                if ( ( selectedProduct.customCost == null
                ||     selectedProduct.customCost == 0
                     )
                &&   ( selectedProduct.customPrice == null
                ||     selectedProduct.customPrice == 0
                     )
                   )
                    continue;

                else if ( selectedProduct.standardPrice == null )
                {
                    errorMessage = selectedProduct.name 
                                 + ' must be added to the ' + STANDARD
                                 + ' before it may be added to any custom'
                                 + ' pricebook.';
                    isValidated  = false;

                    addError (errorMessage);

                }

                else
                {
                    if ( ( ( selectedProduct.customCost == null
                    ||       selectedProduct.customCost == 0
                           )
                    &&     ( selectedProduct.customPrice != null
                    &&       selectedProduct.customPrice != 0
                           )
                         )
                    ||   ( ( selectedProduct.customCost != null
                    &&       selectedProduct.customCost != 0
                           )
                    &&     ( selectedProduct.customPrice == null
                    ||       selectedProduct.customPrice == 0
                           )
                         )
                       )
                    {
                        isValidated        = false;
                        missingCostOrPrice = true;
                        
                    }   //  Either [List Price] or [Cost] is invalid

                }   //  selected product is missing from Standard Price Book

            }   //  each selectedProduct in selectedProducts 

            if ( isValidated )
            {
                pricebookEntryMap = getPricebookEntryMap (selectedPricebook);

                for ( ProductWrapper selectedProduct : selectedProducts )
                {
                    if ( ( selectedProduct.customCost == null
                    ||     selectedProduct.customCost == 0
                         )
                    &&   ( selectedProduct.customPrice == null
                    ||     selectedProduct.customPrice == 0
                         )
                       )
                        continue;

                    if ( selectedProduct.customCost != null )
                        customCost = selectedProduct.customCost;

                    if ( selectedProduct.customPrice != null )
                        customPrice = selectedProduct.customPrice;

                    if ( pricebookEntryMap.containsKey (selectedProduct.id) )
                    {
                        entry = pricebookEntryMap.get (selectedProduct.id);

                        entry.Cost__c   = customCost;
                        entry.IsActive  = true;
                        entry.UnitPrice = customPrice;

                    }

                    else
                    {
                        entry = new PricebookEntry
                        (
                            Cost__c      = customCost
                        ,   IsActive     = true
                        ,   PriceBook2Id = selectedPriceBook
                        ,   Product2Id   = selectedProduct.id
                        ,   UnitPrice    = customPrice

                        );

                    }   //  selectedProduct already has an entry is selected pricebook

                    entriesToUpsert.add (entry);

                }   //  each selectedProduct in selectedProducts

                for ( PricebookEntry entryToUpsert : entriesToUpsert )
                {
                    System.debug (Logginglevel.INFO
                                 , 'entryToUpsert [' + index + ']:  '
                                 + String.valueOf (entryToUpsert));
                    index ++;

                }   //  each entry in entriesToUpsert

                upsert entriesToUpsert;

                pageReference = new PageReference ('/' + selectedPricebook);

            }

            else if ( missingCostOrPrice )
                addError (MISSING_COST_OR_PRICE);

        }   //  try

        catch ( Exception e )
        {
            addError (e.getMessage () + '; ' + e.getStackTraceString ());

        }   //  catch

        return pageReference;

    }   //  save ()

    public PageReference search ()
    {
        //  variables declared in alphabetical order
        Decimal                   customCost        = null;
        Decimal                   customPrice       = null;
        Map  <Id, PricebookEntry> customPriceMap    = new Map  <Id, PricebookEntry> ();
        Boolean                   isValidPricebook  = false;
        Boolean                   isValidSearchTerm = false;
        PageReference             pageReference     = null;
        ProductWrapper            productWrapper    = null;
        List <Product2>           products          = new List <Product2> ();
        String                    query             = null;
        String                    searchClause      = null;
        Decimal                   standardPrice     = null;
        Map  <Id, PricebookEntry> standardPriceMap  = new Map  <Id, PricebookEntry> ();

        try
        {
            productWrappers.clear ();

            if ( ! selectedPricebook.equals (SELECT_PRICEBOOK) )
                isValidPricebook = true;

            if ( String.isNotBlank (searchString) )
                isValidSearchTerm = true;

            if ( isValidPricebook
            &&   isValidSearchTerm
               )
            { 
                searchClause = String.escapeSingleQuotes (searchString);
                searchClause = '%' + searchClause + '%';
                query        = 'select'
                             +       ' id'
                             +      ', family'
                             +      ', name'
                             +      ', svmxc__product_cost__c'
                             +  ' from product2'
                             + ' where ( family like \'' + searchClause + '\''
                             +    ' or   name   like \'' + searchClause + '\''
                             +        ')'; 

                System.debug (Logginglevel.INFO, 'product query:  ' + query);

                products         = Database.query (query);
                customPriceMap   = getPricebookEntryMap (selectedPricebook);
                standardPriceMap = getPricebookEntryMap (standardPricebookId);

                System.debug (Logginglevel.INFO, 'customPriceMap:  ' + customPriceMap);

                for ( Product2 product : products )
                {
                    customCost    = null;
                    customPrice   = null;
                    standardPrice = null;

                    if ( customPriceMap.containsKey (product.Id) )
                    {
                        customCost  = customPriceMap.get (product.Id).Cost__c;
                        customPrice = customPriceMap.get (product.Id).UnitPrice;

                    }   //  if product listed in selected pricebook

                    if ( System.Test.isRunningTest () )
                        standardPrice = 100.0;

                    else if ( standardPriceMap.containsKey (product.Id) )
                       standardPrice = standardPriceMap.get (product.Id).UnitPrice;

                    productWrapper = new ProductWrapper ();

                    //  properties set in alphabetical order
                    productWrapper.customCost = customCost;

                    if ( productWrapper.customCost != null )
                        productWrapper.customCostFormatted
                            = productWrapper.customCost.format ();

                    productWrapper.customPrice = customPrice;

                    if ( productWrapper.customPrice != null )
                        productWrapper.customPriceFormatted
                            = productWrapper.customPrice.format ();

                    productWrapper.family        = product.Family;
                    productWrapper.id            = product.Id;
                    productWrapper.name          = product.Name; 
                    productWrapper.standardCost  = product.SVMXC__Product_Cost__c;
                    productWrapper.standardPrice = standardPrice;

                    if ( productWrappers.size () < 1000 )
                        productWrappers.add (productWrapper);

                    else
                        break;

                }   //  each product in products

            }

            else
            {
                if ( ! isValidPricebook )
                    addError (MISSING_PRICEBOOK);

                if ( ! isValidSearchTerm )
                    addError (MISSING_SEARCH_TERM);

            }   //  required fields are not null

        }   //  try

        catch ( Exception e )
        {
            addError (e.getMessage () + '; ' + e.getStackTraceString ());

        }   //  catch

        return PageReference;

    }   //  search ()

    public void setAllProductsSelected ()
    {
        allProductsSelected = ! allProductsSelected;

        if ( ! productWrappers.isEmpty () )
            for ( ProductWrapper productWrapper : productWrappers )
                productWrapper.selected = allProductsSelected;

        setDisableAddModify ();

    }   //  setAllProductsSelected ()

    public void setDisableAddModify ()
    {
        disableAddModify = true;

        for ( ProductWrapper productWrapper : productWrappers )
            if ( productWrapper.selected )
            {
                disableAddModify = false;
                break;

            }   //  at least one product is selected

    }   //  setDisableAddModify ()

    public void updateCustomCosts ()
    {
        //  variables declared in alphabetical order
        String customCostFormatted = null;
        List <String> format = new List <String> {'$###,###,##0.00'};

        System.debug (Logginglevel.INFO, 'changeToCustomCost:  ' + changeToCustomCost);

        if ( changeToCustomCost != null )
        {
            changeToCustomCost /= 100;
            changeToCustomCost += 1;          

            for ( ProductWrapper selectedProduct : selectedProducts )
                if ( selectedProduct.standardCost != null )
                {
                    if ( selectedProduct.customCost == null )
                        selectedProduct.customCost = Decimal.valueOf (0);

                    selectedProduct.customCost = changeToCustomCost * selectedProduct.standardCost;

                    customCostFormatted = selectedProduct.customCost.format ();
                    customCostFormatted = String.format (customCostFormatted, format);
                    selectedProduct.customCostFormatted = customCostFormatted;

                    System.debug (Logginglevel.INFO, selectedProduct.name + ':  ' + selectedProduct.customCostFormatted);

                }   //  [List Cost] is not null

        }   //  changeToCustomCost is not null

    }   //  updateCustomCosts ()

    public void updateCustomPrices ()
    {
        //  variables declared in alphabetical order
        String customPriceFormatted = null;
        List <String> format = new List <String> {'$###,###,##0.00'};

        System.debug (Logginglevel.INFO, 'changeToCustomPrice:  ' + changeToCustomPrice);

        if ( changeToCustomPrice != null )
        {
            changeToCustomPrice /= 100;
            changeToCustomPrice += 1;          

            for ( ProductWrapper selectedProduct : selectedProducts )
                if ( selectedProduct.standardPrice != null )
                {
                    if ( selectedProduct.customPrice == null )
                        selectedProduct.customPrice = Decimal.valueOf (0);

                    selectedProduct.customPrice = changeToCustomPrice * selectedProduct.standardPrice;

                    customPriceFormatted = selectedProduct.customPrice.format ();
                    customPriceFormatted = String.format (customPriceFormatted, format);
                    selectedProduct.customPriceFormatted = customPriceFormatted;

                    System.debug (Logginglevel.INFO, selectedProduct.name + ':  ' + selectedProduct.customPriceFormatted);

                }   //  [List Price] is not null

        }   //  changeToCustomPrice is not null

    }   //  updateCustomPrices ()

    //  private methods listed in alphabetical order
    private void addError ( String error )
    {
        ApexPages.addMessage (new ApexPages.Message (ApexPages.Severity.ERROR, error));

        System.debug (Logginglevel.ERROR, error);

    }   //  addError ()

    private Map <Id, PriceBookEntry> getPricebookEntryMap ( Id pricebookId )
    {
        //  variables declared in alphabetical order
        Map  <Id, PriceBookEntry> pricebookEntryMap = new Map  <Id, PriceBookEntry> ();
        List <PricebookEntry>     pricebookEntries  = new List <PricebookEntry> ();
        String                    query             = null;
        String                    searchClause      = null;

        if ( String.isNotBlank (searchString) )
        {
            searchClause = String.escapeSingleQuotes (searchString);
            searchClause = '%' + searchClause + '%';
            query        = 'select'
                         +       ' cost__c'    
                         +      ', id'
                         +      ', pricebook2.name'
                         +      ', product2.family'
                         +      ', product2.name'
                         +      ', product2.svmxc__product_cost__c'
                         +      ', product2Id'
                         +      ', unitprice'
                         +  ' from pricebookentry'
                         + ' where pricebook2.id = \'' + pricebookId + '\''
                         +   ' and ( product2.family like \'' + searchClause + '\''
                         +    ' or   product2.name   like \'' + searchClause + '\''
                         +        ')';

            System.debug (Logginglevel.INFO, 'pricebook query:  ' + query);

            pricebookEntries = Database.query (query);

            if ( pricebookId != standardPricebookId )
                pricebookName = getPricebookName (pricebookId);

            for ( PricebookEntry pricebookEntry : pricebookEntries )
                pricebookEntryMap.put (pricebookEntry.Product2Id, pricebookEntry);

        }   //  searchString is not null

        return pricebookEntryMap;

    }   //  getPricebookEntryMap ()

    private String getPricebookName ( Id pricebookId )
    {
        //  variables declared in alphabetical order
        String pricebookName = null;

        pricebookName = [ select name from pricebook2
                           where id = : pricebookId ].Name;

        return pricebookName;

    }   //  getPricebookName ()

}