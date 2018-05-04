<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Invoice_Date_Invoiced</fullName>
        <description>Update date invoiced on an invoice from the SL Invoice Date field on a work order for back-billing purposes</description>
        <field>Date_Invoiced__c</field>
        <formula>IF( ISBLANK(Work_Order__r.SL_Invoice_Date__c) ,   TODAY()   , Work_Order__r.SL_Invoice_Date__c)</formula>
        <name>Invoice Date Invoiced</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Invoice_Date_Set_c</fullName>
        <description>This sets Invoiced Date to date invoice is created</description>
        <field>Date_Invoiced__c</field>
        <formula>CreatedDate</formula>
        <name>Invoice Date Set</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Invoice_Location_Address</fullName>
        <description>Updates location address on master invoice record</description>
        <field>Location_Address_c__c</field>
        <formula>Location__r.SVMXC__Street__c</formula>
        <name>Invoice Location Address</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Invoice_Location_City</fullName>
        <description>Update location city on master invoice record</description>
        <field>Location_City_c__c</field>
        <formula>Location__r.SVMXC__City__c</formula>
        <name>Invoice Location City</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Invoice_Location_State</fullName>
        <description>Updates location state on master invoice record</description>
        <field>Location_State_c__c</field>
        <formula>Location__r.SVMXC__State__c</formula>
        <name>Invoice Location State</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Invoice_Location_Zip</fullName>
        <description>Update location zip on master invoice record</description>
        <field>Location_Zip_c__c</field>
        <formula>Location__r.SVMXC__Zip__c</formula>
        <name>Invoice Location Zip</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Invoice_Read_Only</fullName>
        <description>Switch the record type to Invoice Read Only when the status is set to In-Batch</description>
        <field>RecordTypeId</field>
        <lookupValue>MH_Read_Only</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Invoice Read Only</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Invoice_Recommended_ic</fullName>
        <description>Update recommended service on the Invoice header</description>
        <field>Recommended_Service__c</field>
        <formula>Work_Order__r.Recommended_Service__c</formula>
        <name>Invoice Recommended</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Invoice_SP_Work_ic</fullName>
        <description>Update SP Work Performed on the Invoice header</description>
        <field>SP_Work_Performed_c__c</field>
        <formula>Work_Order__r.SVMXC__Work_Performed__c</formula>
        <name>Invoice SP Work</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Invoice_is_Void</fullName>
        <field>Status__c</field>
        <literalValue>Void</literalValue>
        <name>Invoice is Void</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Post_To_Period</fullName>
        <description>Update Post To Period field with a date formula from SL Invoiced Date field. Used for summary invoicing purposes</description>
        <field>Post_to_Period__c</field>
        <formula>CASE(TEXT(MONTH( SL_Invoice_Date_c__c )) 
,&apos;1&apos;,&apos;01&apos;, 
&apos;2&apos;,&apos;02&apos;, 
&apos;3&apos;,&apos;03&apos;, 
&apos;4&apos;,&apos;04&apos;, 
&apos;5&apos;,&apos;05&apos;, 
&apos;6&apos;,&apos;06&apos;, 
&apos;7&apos;,&apos;07&apos;, 
&apos;8&apos;,&apos;08&apos;, 
&apos;9&apos;,&apos;09&apos;, 
TEXT(MONTH( SL_Invoice_Date_c__c ))) 

&amp; &quot;-&quot; &amp; TEXT(YEAR( SL_Invoice_Date_c__c )) 

/*TEXT(MONTH( SL_Invoice_Date_c__c )) &amp; &quot;-&quot; &amp; TEXT(YEAR( SL_Invoice_Date_c__c ))*/</formula>
        <name>Post To Period</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>SL_Invoice_Date_Update</fullName>
        <description>Update SL Invoice Date on invoice record from corresponding field on work order</description>
        <field>SL_Invoice_Date_c__c</field>
        <formula>IF( ISBLANK(Work_Order__r.SL_Invoice_Date__c) ,  TODAY() , Work_Order__r.SL_Invoice_Date__c)</formula>
        <name>SL Invoice Date Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Service_Team_City</fullName>
        <description>Service Team city update on Invoice</description>
        <field>Service_Team_City_ic__c</field>
        <formula>Work_Order__r.SVMXC__Service_Group__r.SVMXC__City__c</formula>
        <name>Service Team City</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Service_Team_Fax_id</fullName>
        <description>Update Service Team fax number on invoice master detail</description>
        <field>Service_Team_Fax_id__c</field>
        <formula>Work_Order__r.SVMXC__Service_Group__r.Fax_c__c</formula>
        <name>Service Team Fax</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Service_Team_Legal</fullName>
        <description>Update legal entity name on Invoice for output use</description>
        <field>Service_Team_Legal_Name__c</field>
        <formula>Work_Order__r.SVMXC__Service_Group__r.Company_Legal_Name__c</formula>
        <name>Service Team Legal</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Service_Team_Name</fullName>
        <description>Service Team name on Invoice</description>
        <field>Service_Team_ic__c</field>
        <formula>Work_Order__r.SVMXC__Service_Group__r.Name</formula>
        <name>Service Team Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Service_Team_Phone_id</fullName>
        <description>Update Service Team phone number</description>
        <field>Service_Team_Phone_id__c</field>
        <formula>Work_Order__r.SVMXC__Service_Group__r.SVMXC__Phone__c</formula>
        <name>Service Team Phone</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Service_Team_State</fullName>
        <description>Service Team state on Invoice</description>
        <field>Service_Team_State_ic__c</field>
        <formula>Work_Order__r.SVMXC__Service_Group__r.SVMXC__State__c</formula>
        <name>Service Team State</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Service_Team_Zip</fullName>
        <description>Service Team zip on Invoice</description>
        <field>Service_Team_Zip_ic__c</field>
        <formula>Work_Order__r.SVMXC__Service_Group__r.SVMXC__Zip__c</formula>
        <name>Service Team Zip</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Service_Team_c</fullName>
        <description>Service Team address set on Invoice</description>
        <field>Service_Team_Address_ic__c</field>
        <formula>Work_Order__r.SVMXC__Service_Group__r.SVMXC__Street__c</formula>
        <name>Service Team Address</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Invoice_Billed_Date</fullName>
        <description>Sets the invoice date field to today&apos;s date</description>
        <field>Date_Invoiced__c</field>
        <formula>Today()</formula>
        <name>Set Invoice Billed Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Invoice_Date</fullName>
        <description>Default Invoice Date to date created</description>
        <field>Date_Invoiced__c</field>
        <formula>Today()</formula>
        <name>Set Invoice Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Status_Integrated</fullName>
        <field>Status__c</field>
        <literalValue>Billed</literalValue>
        <name>Status = Billed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Customer_PO</fullName>
        <field>Customer_P_O__c</field>
        <formula>Work_Order__r.Customer_P_O__c</formula>
        <name>Update Customer PO</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Inv_Sales_Tax</fullName>
        <description>Update sales tax</description>
        <field>Sales_Tax__c</field>
        <formula>Work_Order__r.Sales_Tax_Total__c</formula>
        <name>Update Inv Sales Tax</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Inv_Sub_total</fullName>
        <description>Updates sub-total on Invoice</description>
        <field>Invoice_Details_Sub_Total__c</field>
        <formula>Work_Order__r.Work_Detail_Count__c</formula>
        <name>Update Inv Sub-total</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Inv_Total</fullName>
        <description>Update invoice total</description>
        <field>Invoice_Total__c</field>
        <formula>Invoice_Details_Sub_Total__c + Sales_Tax__c</formula>
        <name>Update Inv Total</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Invoice_Sub_total_c</fullName>
        <description>This will update the field for Invoice Sub-total to sum all invoice details</description>
        <field>Invoice_Details_Sub_Total__c</field>
        <formula>Invoice_Total_Rollup__c</formula>
        <name>Update Invoice Sub-total</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Invoice_Terms</fullName>
        <field>Invoice_Terms_c__c</field>
        <formula>Account__r.MH_Terms__c</formula>
        <name>Update Invoice Terms</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Invoice_Total_c</fullName>
        <field>Invoice_Total__c</field>
        <formula>Invoice_Total_Rollup__c + Sales_Tax__c</formula>
        <name>Update Invoice Total</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Complete Invoice Items</fullName>
        <actions>
            <name>Invoice_Location_Address</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Invoice_Location_City</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Invoice_Location_State</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Invoice_Location_Zip</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Post_To_Period</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>SL_Invoice_Date_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Customer_PO</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>MH_Invoice__c.Status__c</field>
            <operation>equals</operation>
            <value>Not Billed,In-Batch,Billed,Void,Under Review</value>
        </criteriaItems>
        <description>Completes multiple levels of Invoice details</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Date Update</fullName>
        <actions>
            <name>Invoice_Date_Invoiced</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>MH_Invoice__c.Status__c</field>
            <operation>equals</operation>
            <value>Not Billed,In-Batch,Billed,Void,Under Review</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Invoice Billed</fullName>
        <actions>
            <name>Status_Integrated</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>MH_Invoice__c.SL_Status__c</field>
            <operation>equals</operation>
            <value>B</value>
        </criteriaItems>
        <description>If SL Status is returned &quot;B&quot;, update Status to Billed.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Invoice Integrated</fullName>
        <actions>
            <name>Status_Integrated</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>MH_Invoice__c.SL_Invoice_ID__c</field>
            <operation>notEqual</operation>
            <value></value>
        </criteriaItems>
        <description>When invoice details are received from SL, update Status to Integrated.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Invoice Integrated - Read Only</fullName>
        <actions>
            <name>Invoice_Read_Only</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>MH_Invoice__c.Status__c</field>
            <operation>equals</operation>
            <value>In-Batch,Billed</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Invoice Recommended Service Update</fullName>
        <active>false</active>
        <criteriaItems>
            <field>MH_Invoice__c.Status__c</field>
            <operation>equals</operation>
            <value>Not Billed,In-Batch,Billed,Void,Under Review</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Invoice Updates</fullName>
        <actions>
            <name>Invoice_Recommended_ic</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Invoice_SP_Work_ic</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>MH_Invoice__c.Status__c</field>
            <operation>equals</operation>
            <value>Not Billed,In-Batch,Billed</value>
        </criteriaItems>
        <description>Update information on the Invoice</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set Invoice Date</fullName>
        <actions>
            <name>Set_Invoice_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Default invoice create date</description>
        <formula>ISNULL(CreatedDate)</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Set Invoiced Date</fullName>
        <actions>
            <name>Set_Invoice_Billed_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>MH_Invoice__c.Status__c</field>
            <operation>equals</operation>
            <value>Billed</value>
        </criteriaItems>
        <description>Sets the invoiced date field to the current date when the invoice status is set to &quot;billed&quot;</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Update Invoice Totals</fullName>
        <actions>
            <name>Update_Inv_Sales_Tax</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Inv_Sub_total</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Inv_Total</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>MH_Invoice__c.Call_Type__c</field>
            <operation>equals</operation>
            <value>AMS,EXT,GMC,NMS,TFS,SPSC</value>
        </criteriaItems>
        <description>Updates the Summary Roll-up, Sales Tax and Invoice Total</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Update Service Team on Invoice</fullName>
        <actions>
            <name>Service_Team_City</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Service_Team_Fax_id</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Service_Team_Legal</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Service_Team_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Service_Team_Phone_id</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Service_Team_State</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Service_Team_Zip</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Service_Team_c</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Invoice_Terms</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>MH_Invoice__c.Call_Type__c</field>
            <operation>equals</operation>
            <value>SPSC,TFS,EXT,GMC,NMS</value>
        </criteriaItems>
        <description>This work flow will update Service Team information on the Invoice Summary record</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Void Invoice</fullName>
        <actions>
            <name>Invoice_is_Void</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>MH_Invoice__c.SL_Status__c</field>
            <operation>equals</operation>
            <value>R</value>
        </criteriaItems>
        <description>If SL Status returns with &quot;R&quot;, Invoice is void.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
