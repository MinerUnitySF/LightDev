<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Account_Notify_on_Active_Customer_Email</fullName>
        <description>Account Notify on Active Customer Email</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Account_Active_Customer</template>
    </alerts>
    <alerts>
        <fullName>Credit_Hold_Notification</fullName>
        <description>Credit Hold Notification</description>
        <protected>false</protected>
        <recipients>
            <recipient>owner@minercorp.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/SUPPORTSelfServiceNewCommentNotificationSAMPLE</template>
    </alerts>
    <alerts>
        <fullName>Prospect_Account_Declined_Alert</fullName>
        <description>Prospect Account Declined Alert</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Prospect_Conversion_Declined</template>
    </alerts>
    <fieldUpdates>
        <fullName>Account_Business_Unit_c</fullName>
        <description>Set Business Unit to that of User when Account is created</description>
        <field>Business_Unit__c</field>
        <literalValue>Miner Corp</literalValue>
        <name>Account Business Unit</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Account_Default_BU_to_FLEXX</fullName>
        <description>Vertiba 04/07/2014 - Created to default the Business Unit on Accounts for FLEXX Users</description>
        <field>Business_Unit__c</field>
        <literalValue>Flexx</literalValue>
        <name>Account:Default BU to FLEXX</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Account_to_Active</fullName>
        <description>Change the account status to Active</description>
        <field>Account_Status__c</field>
        <literalValue>Active</literalValue>
        <name>Account to Active</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Credit_Check</fullName>
        <description>This event checks the Check Hold checkbox</description>
        <field>MH_Credit_Hold__c</field>
        <literalValue>1</literalValue>
        <name>Credit Check</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Credit_Hold</fullName>
        <description>Credit hold is true if Credit Rule is &quot;H&quot; or &quot;X&quot; (values assigned in SL)</description>
        <field>MH_Credit_Hold__c</field>
        <literalValue>1</literalValue>
        <name>Credit Hold</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Customer_Account_RT</fullName>
        <description>Update the account record type to customer</description>
        <field>RecordTypeId</field>
        <lookupValue>Customer_Account</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Customer Account RT</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Deactivate_Credit_Hold</fullName>
        <field>MH_Credit_Hold__c</field>
        <literalValue>0</literalValue>
        <name>Deactivate Credit Hold</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Flag_as_Ready_to_Convert</fullName>
        <description>Flag the account upon approval</description>
        <field>Ready_to_Convert__c</field>
        <literalValue>1</literalValue>
        <name>Flag as Ready to Convert</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>SL_Customer_ID_for_Residential</fullName>
        <description>Set the SL Customer ID for residential accounts</description>
        <field>MH_SL_CustID__c</field>
        <formula>&quot;1033945&quot;</formula>
        <name>SL Customer ID for Residential</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Account_record_Type_to_Customer</fullName>
        <description>Sets the account record type to customer</description>
        <field>RecordTypeId</field>
        <lookupValue>Customer_Account</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Set Account record Type to Customer</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Account_to_Active</fullName>
        <description>Sets the account status to Active</description>
        <field>Account_Status__c</field>
        <literalValue>Active</literalValue>
        <name>Set Account to Active</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Business_Unit_Miner</fullName>
        <field>Business_Unit__c</field>
        <literalValue>Miner Corp</literalValue>
        <name>Set Business Unit = Miner</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Business_Unit_Miner_BDC</fullName>
        <description>Sets Account Business Unit to Miner</description>
        <field>Business_Unit__c</field>
        <literalValue>Miner Corp</literalValue>
        <name>Set Business Unit = Miner</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Business_Unit_NMS</fullName>
        <field>Business_Unit__c</field>
        <literalValue>National Maintenance Services</literalValue>
        <name>Set Business Unit = NMS</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Business_Unit_TFS</fullName>
        <field>Business_Unit__c</field>
        <literalValue>Total Fleet Solution</literalValue>
        <name>Set Business Unit = TFS</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_SL_Cust_ID_for_Residential</fullName>
        <description>Sets the SL Customer ID field with the residential accounts SL Customer ID (1033945)</description>
        <field>MH_SL_CustID__c</field>
        <formula>&quot;1033945&quot;</formula>
        <name>Set SL Cust ID for Residential</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_Clear_DNU_Flagged_Date</fullName>
        <field>UNITY_Do_Not_Use_Flagged_Date__c</field>
        <name>Clear DNU Flagged Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_Clear_DNU_Reason</fullName>
        <field>UNITY_Do_Not_Use_Reason__c</field>
        <name>Clear DNU Reason</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_MinerUniqueBU</fullName>
        <field>BU_Unique_Field__c</field>
        <formula>TEXT( UNITY_Business_Unit__c )</formula>
        <name>UNITY_MinerUniqueBU</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_Miner_Regional_Office_Flag</fullName>
        <description>Set Miner Regional Office flag to true when record type = Miner</description>
        <field>UNITY_Miner_Regional_Office__c</field>
        <literalValue>1</literalValue>
        <name>UNITY_Miner_Regional_Office_Flag</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_Populate_Do_Not_Use_Date</fullName>
        <description>Populate Do Not Use Date on Account when DNU checkbox is true</description>
        <field>UNITY_Do_Not_Use_Flagged_Date__c</field>
        <formula>NOW()</formula>
        <name>Populate Do Not Use Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_Set_SLCompanyId</fullName>
        <description>Set the SLCompany Id to 01</description>
        <field>SL_Company_ID__c</field>
        <formula>&quot;01&quot;</formula>
        <name>UNITY_Set_SLCompanyId</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Account Business Unit</fullName>
        <actions>
            <name>Account_Business_Unit_c</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>User.Business_Unit__c</field>
            <operation>equals</operation>
            <value>Miner Corp</value>
        </criteriaItems>
        <description>Sets the Business Unit to that of the user for Account</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Account Notify on Active Customer</fullName>
        <actions>
            <name>Account_Notify_on_Active_Customer_Email</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <description>Notify account owner when the account has been successfully converted to an Active Customer</description>
        <formula>AND(  RecordType.Name == &apos;Customer Account&apos;, ISPICKVAL(Account_Status__c, &apos;Active&apos;), NOT(ISBLANK(MH_SL_CustID__c )) )</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Account%3ADefault BU to FLEXX</fullName>
        <actions>
            <name>Account_Default_BU_to_FLEXX</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Vertiba 04/07/2014 - Created to default the Business Unit on Accounts for FLEXX Users</description>
        <formula>IF( CONTAINS($Profile.Name,&quot;FLEXX&quot;),  true,  false )</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Convert Residential</fullName>
        <actions>
            <name>Account_to_Active</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Customer_Account_RT</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>SL_Customer_ID_for_Residential</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.RecordTypeId</field>
            <operation>equals</operation>
            <value>Prospect Accounts</value>
        </criteriaItems>
        <criteriaItems>
            <field>Account.Residential__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Account.Ready_to_Convert__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <description>Converts the residential account to active customer and assigns the residential SL Customer ID</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Credit Hold</fullName>
        <actions>
            <name>Credit_Hold</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Credit hold on accounts.  Set by Credit Rule in SL.</description>
        <formula>IF((( UPPER(Credit_Rule__c) = &quot;H&quot; )|| (UPPER(Credit_Rule__c) = &quot;X&quot;)), TRUE, FALSE)</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Credit Hold Activate</fullName>
        <actions>
            <name>Credit_Hold_Notification</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Credit_Check</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>This trigger will check the Credit Hold checkbox if the correct criteria are met</description>
        <formula>AND( RecordType.DeveloperName = &apos;Customer_Account&apos;, ( 0.75 * MH_Credit_Limit__c )&lt;= MH_Current_Balance__c)</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Deactivate Credit Hold</fullName>
        <actions>
            <name>Deactivate_Credit_Hold</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>(UPPER(Credit_Rule__c) = &quot;A&quot; )
|| 
(UPPER(Credit_Rule__c) = &quot;B&quot;)
||
(UPPER(Credit_Rule__c) = &quot;N&quot;)</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>E-fax Requirement</fullName>
        <active>false</active>
        <criteriaItems>
            <field>Account.Account_Status__c</field>
            <operation>equals</operation>
            <value>Prospect</value>
        </criteriaItems>
        <description>Require that an e-mail or fax is required to save an Account</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Set Business Unit %3D Miner</fullName>
        <actions>
            <name>Set_Business_Unit_Miner</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>User.ProfileId</field>
            <operation>contains</operation>
            <value>MinerCorp</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Set Business Unit %3D Miner for BDC</fullName>
        <actions>
            <name>Set_Business_Unit_Miner_BDC</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>User.ProfileId</field>
            <operation>contains</operation>
            <value>Business</value>
        </criteriaItems>
        <description>BDC Users have the MH Service Coordinator profile, need to set BU to Miner.</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Set Business Unit %3D NMS</fullName>
        <actions>
            <name>Account_Business_Unit_c</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Set_Business_Unit_NMS</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>User.ProfileId</field>
            <operation>contains</operation>
            <value>NMS</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Set Business Unit %3D TFS</fullName>
        <actions>
            <name>Flag_as_Ready_to_Convert</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Set_Business_Unit_TFS</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>User.ProfileId</field>
            <operation>contains</operation>
            <value>TFS</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>UNITY_DNU_Flagged_Date</fullName>
        <actions>
            <name>UNITY_Populate_Do_Not_Use_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.UNITY_Do_Not_Use__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>UNITY_DNU_Flagged_DateClear</fullName>
        <actions>
            <name>UNITY_Clear_DNU_Flagged_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>UNITY_Clear_DNU_Reason</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.UNITY_Do_Not_Use__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>UNITY_Hours_of_Operation</fullName>
        <active>true</active>
        <criteriaItems>
            <field>Account.RecordTypeId</field>
            <operation>equals</operation>
            <value>Customer,Vendor,Miner</value>
        </criteriaItems>
        <description>Update Vendor/Customer hours of operation summary</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>UNITY_MinerUniqueBu</fullName>
        <actions>
            <name>UNITY_MinerUniqueBU</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.RecordTypeId</field>
            <operation>equals</operation>
            <value>Miner</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>UNITY_Miner_Regional_Office_Flag</fullName>
        <actions>
            <name>UNITY_Miner_Regional_Office_Flag</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.RecordTypeId</field>
            <operation>equals</operation>
            <value>Miner</value>
        </criteriaItems>
        <description>Flag field when Account record type = Miner</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>UNITY_Set_SLCompanyId</fullName>
        <actions>
            <name>UNITY_Set_SLCompanyId</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.RecordTypeId</field>
            <operation>equals</operation>
            <value>Customer,Vendor</value>
        </criteriaItems>
        <description>Set the company Id field on Vendors and Customers to 01</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
