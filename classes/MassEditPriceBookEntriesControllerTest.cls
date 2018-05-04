/*************************************************************************************************
Class     :  MassEditPriceBookEntriesControllerTest.cls
Developer :  mickey@vertiba.com
Created   :  January 29, 2015
Modified  :  January 30, 2015
Objective :  This class provides methods to yrdy MassEditPriceBookEntriesController.cls

*************************************************************************************************/

@isTest ( seealldata = false )
private with sharing class MassEditPriceBookEntriesControllerTest
{
    //  static variables declared in alphabetical order
    static User                               administrator    = null;
    static MassEditPriceBookEntriesController controller       = null;
    static Pricebook2                         pricebook        = null;
    static List <PricebookEntry>              pricebookEntries = new List <PricebookEntry> ();
    static PricebookEntry                     pricebookEntry   = null;
    static Product2                           product          = null;
    static MassEditPriceBookEntriesController.ProductWrapper
                                              selectedProduct  = null;

    //  static constants declared in alphabetical order
    static final String MISSING_COST_OR_PRICE = 'One or more of the selected '
                                               + 'products does not have both '
                                               + 'a [Cost] and a [List Price].';
    static final Id     STANDARD_PRICEBOOK_ID  = System.Test.getStandardPricebookId ();

    static
    {
        administrator = TestingUtility.instantiateSystemAdministrator ();

        System.runAs (administrator)
        {
            pricebook = TestingUtility.instantiatePricebook ('Custom Price Book');

            insert pricebook;

            product = TestingUtility.instantiateProduct
                    ( 'Vertiba Test Product'
                    , 65.0
                    );

            insert product;

            pricebookEntry = TestingUtility.instantiatePricebookEntry
                           ( STANDARD_PRICEBOOK_ID
                           , product.Id
                           , 65.0
                           , 100.0
                           );

            insert pricebookEntry;

            pricebookEntries = [
                                 select

                                        cost__c
                                      , pricebook2.name
                                      , product2.name
                                      , unitprice

                                   from pricebookentry

                                  where id = : pricebookEntry.Id
                               ];

            System.assertEquals (1, pricebookEntries.size ());
            System.assertEquals (STANDARD_PRICEBOOK_ID, pricebookEntries [0].Pricebook2Id);
            System.assertEquals (product.Id, pricebookEntries [0].Product2Id);
            System.assertEquals ( 65, pricebookEntries [0].Cost__c);
            System.assertEquals (100, pricebookEntries [0].UnitPrice);

            controller = new MassEditPriceBookEntriesController ();

            controller.searchString      = 'Vertiba Test Product';
            controller.selectedPricebook = pricebook.Id;

            controller.search ();

            System.assertEquals ('Vertiba Test Product'
                                , controller.productWrappers[0].name);

            controller.setAllProductsSelected ();

            controller.goToUpsertPage ();

        }   //  administrator-executed code

    }   //  block common to all test methods

    //  private methods listed in alphabetical order
    private static testMethod void testUpsertCustomPricebookEntry ()
    {
        try
        {
            System.assertEquals (1, controller.selectedProducts.size ());

            selectedProduct = controller.selectedProducts [0];

            System.assertEquals ('Vertiba Test Product', selectedProduct.name);
            System.assertEquals ( 65, selectedProduct.standardCost);
            System.assertEquals (100, selectedProduct.standardPrice);

            controller.changeToCustomCost = 7.35;

            controller.updateCustomCosts ();

            System.assertEquals (69.7775, selectedProduct.customCost);
            System.assertEquals (   null, selectedProduct.customPrice);

            controller.save ();

        }   //  try

        catch ( Exception e )
        {
            System.assertEquals (MISSING_COST_OR_PRICE, e.getMessage ());

        }   //  catch

        controller.changeToCustomPrice = 5.8;

        controller.updateCustomPrices ();

        System.assertEquals ( 69.7775, selectedProduct.customCost);
        System.assertEquals (105.8000, selectedProduct.customPrice);

        controller.save ();

        pricebookEntries = [
                               select

                                      cost__c
                                    , product2.name
                                    , unitprice

                                 from pricebookentry

                             order by pricebook2.name
                           ];

        System.assertEquals (       2, pricebookEntries.size ());
        System.assertEquals ( 69.7775, pricebookEntries [0].Cost__c);
        System.assertEquals (105.8000, pricebookEntries [0].UnitPrice);

        controller.getActivePricebooks ();

        controller.searchString      = 'Vertiba Test Product';
        controller.selectedPricebook = pricebook.Id;

        controller.search ();

        System.assertEquals ('Vertiba Test Product'
                            , controller.productWrappers [0].name);

        controller.setAllProductsSelected ();

        controller.goToUpsertPage ();

        controller.cancel ();

        controller.searchString      = 'Vertiba Test Product';
        controller.selectedPricebook = pricebook.Id;

        controller.search ();

        controller.setAllProductsSelected ();

        controller.goToUpsertPage ();

        selectedProduct = controller.selectedProducts [0];

        System.assertEquals (       1, controller.selectedProducts.size ());
        System.assertEquals ( 69.7775, selectedProduct.customCost);
        System.assertEquals (105.8000, selectedProduct.customPrice);

        selectedProduct.customCost  = 75;
        selectedProduct.customPrice = 140;

        controller.save ();

        pricebookEntries = [
                               select

                                      cost__c
                                    , product2.name
                                    , unitprice

                                 from pricebookentry

                             order by pricebook2.name
                           ];

        System.assertEquals (       2, pricebookEntries.size ());
        System.assertEquals ( 75, pricebookEntries [0].Cost__c);
        System.assertEquals (140, pricebookEntries [0].UnitPrice);

    }   //  testUpsertCustomPricebookEntry ()

}