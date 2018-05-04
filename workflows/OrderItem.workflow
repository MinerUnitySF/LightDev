<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>MSPFS_Set_MSP_Price</fullName>
        <description>Sets the MSP Price field from the UNITY Cost</description>
        <field>MSPFS_MSP_Price__c</field>
        <formula>UNITY_Cost__c</formula>
        <name>MSPFS_Set MSP Price</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Re_Set_Parts_Delivered</fullName>
        <description>Re-Set the Parts Delivered flag on the POLI to false</description>
        <field>UNITY_Part_Delivered__c</field>
        <literalValue>0</literalValue>
        <name>Re-Set Parts Delivered</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Parts_Delivered</fullName>
        <description>Sets the parts delivered field to true</description>
        <field>UNITY_Part_Delivered__c</field>
        <literalValue>1</literalValue>
        <name>Set Parts Delivered</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_Set_Shipment_Received_Stocking</fullName>
        <field>UNITY_Shipment_Received__c</field>
        <literalValue>1</literalValue>
        <name>UNITY Set Shipment Received Stocking</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>MSPFS_Set MSP Price from Cost</fullName>
        <actions>
            <name>MSPFS_Set_MSP_Price</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Sets the MSP Price from the Cost field is it is greater than $0</description>
        <formula>AND( Order.FSO__WorkOrder__r.MSPFS_Intercompany_Transfer__c, NOT(ISBLANK(UNITY_Cost__c)), UNITY_Is_Vendor_Supply__c, UNITY_Cost__c &gt; 0, NOT(CONTAINS(TEXT(UNITY_Activity_Type__c),&quot;Labor&quot;)), NOT(CONTAINS(TEXT(UNITY_Activity_Type__c),&quot;Travel&quot;))  )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>UNITY Re-Set Parts Delivered</fullName>
        <actions>
            <name>Re_Set_Parts_Delivered</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <booleanFilter>(1 AND 2 AND 3) OR (1 AND 2 AND 4 AND 5)</booleanFilter>
        <criteriaItems>
            <field>OrderItem.UNITY_Activity_Type__c</field>
            <operation>contains</operation>
            <value>Part</value>
        </criteriaItems>
        <criteriaItems>
            <field>OrderItem.UNITY_Actual_Ship_Date__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Order.RecordTypeId</field>
            <operation>equals</operation>
            <value>Parts Sourcing Purchase Order</value>
        </criteriaItems>
        <criteriaItems>
            <field>OrderItem.UNITY_Is_Vendor_Supply__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Order.RecordTypeId</field>
            <operation>equals</operation>
            <value>Purchase Order</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>UNITY Set Parts Delivered</fullName>
        <actions>
            <name>Set_Parts_Delivered</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <booleanFilter>(1 AND 2 AND 3 AND 6) OR (1 AND 2 AND 4 AND 5 AND 6)</booleanFilter>
        <criteriaItems>
            <field>OrderItem.UNITY_Activity_Type__c</field>
            <operation>contains</operation>
            <value>Parts</value>
        </criteriaItems>
        <criteriaItems>
            <field>OrderItem.UNITY_Actual_Ship_Date__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Order.RecordTypeId</field>
            <operation>equals</operation>
            <value>Parts Sourcing Purchase Order</value>
        </criteriaItems>
        <criteriaItems>
            <field>Order.RecordTypeId</field>
            <operation>equals</operation>
            <value>Purchase Order</value>
        </criteriaItems>
        <criteriaItems>
            <field>OrderItem.UNITY_Is_Vendor_Supply__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>OrderItem.UNITY_Actual_Quantity__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Sets the parts delivered checkbox to true when the actual arrival date is entered on Parts Souring POs</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>UNITY Set Received Stocking</fullName>
        <actions>
            <name>UNITY_Set_Shipment_Received_Stocking</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>OrderItem.UNITY_Actual_Ship_Date__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>OrderItem.UNITY_Actual_Quantity__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Order.RecordTypeId</field>
            <operation>equals</operation>
            <value>Stocking Purchase Order</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
