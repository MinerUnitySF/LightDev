/*********************************************************************************************
Class    :  TestingUtility.cls
Developer:  mickey@vertibal.com
Created  :  January 29, 2015
Modified :  January 30, 2015
Objective:  This class provides methods to service other test classes.

*********************************************************************************************/

@isTest ( seealldata = false )
public with sharing class TestingUtility
{
    //  public constants declared in alphabetical order
    public static final Id SYSTEM_ADMINISTRATOR_PROFILE_ID =
            [ select id from profile
               where name = 'System Administrator' ].Id;

    //  public methods listed in alphabetical order
    public static Pricebook2 instantiatePricebook
    ( String name )
    {
        //  variables declared in alphabetical order
        Pricebook2 pricebook = new Pricebook2
        (
            IsActive = true
        ,   Name     = name

        );

        return pricebook;

    }   //  instantiatePricebook ()

    public static PricebookEntry instantiatePricebookEntry
    ( Id      pricebookId
    , Id      productId
    , Decimal cost
    , Decimal price
    )
    {
        //  variables declared in alphabetical order
        PricebookEntry pricebookEntry = new PricebookEntry
        (
            Cost__c      = cost
        ,   IsActive     = true
        ,   Pricebook2Id = pricebookId
        ,   Product2Id   = productId
        ,   UnitPrice    = price

        );

        return pricebookEntry;

    }   //  instantiatePricebookEntry ()

    public static Product2 instantiateProduct
    ( String  name
    , Decimal standardCost
    )
    {
        //  variables declared in alphabetical order
        Product2 product = new Product2
        (
            Name = name,
            ProductCode = name+'-Test-123456',
            Make1__c = 'TestMake',
            Model__c = 'TestModel',
            Broad__c = 'Door',
            Group__c = 'High Speed',
            Type__c = 'Electrical',
            Family = 'Equipment',
            SVMXC__Product_Line__c = 'Equipment',
            IsActive = true,
            Description = 'Installed Product Test Product',
            SVMXC__Product_Cost__c = standardCost,
            SVMXC__Inherit_Parent_Warranty__c = true,
            UNITY_Status__c = 'Active',
            UNITY_Product_Cost__c = 0,
            UNITY_Unit_Of_Measure__c = 'Each'

        );

        return product;

    }   //  instantiateProduct ()

    public static User instantiateSystemAdministrator ()
    {
        return instantiateUser ('sysadmin', 'System', 'Admin', SYSTEM_ADMINISTRATOR_PROFILE_ID);

    }   //  instantiateSystemAdministrator ()

    //  private methods listed alphabetically
    private static User instantiateUser
    ( String alias
    , String firstName
    , String lastName
    , Id     profileId
    )
    {
        User user = new User
        (   //  fields set in alphabetical order
            Alias             = alias
        ,   Email             = alias + '@xxxzzz.com'
        ,   EmailEncodingKey  = 'ISO-8859-1'
        ,   FirstName         = firstName
        ,   LanguageLocaleKey = 'en_US'
        ,   LastName          = lastName
        ,   LocaleSidKey      = 'en_US'
        ,   ProfileId         = profileId
        ,   UserRoleId        = null
        ,   TimeZoneSidKey    = 'America/Chicago'
        ,   Username          = alias + '@xxxzzz.com'

        );

        return user;

    }   //  instantiateUser ()

}