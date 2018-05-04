<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>UNITY_Activate_Miner_Product</fullName>
        <description>Activates miner product if status is set to active</description>
        <field>IsActive</field>
        <literalValue>1</literalValue>
        <name>Activate Miner Product</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_Cost_to_SMAX_Cost</fullName>
        <field>SVMXC__Product_Cost__c</field>
        <formula>UNITY_Product_Cost__c</formula>
        <name>UNITY Cost to SMAX Cost</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_Deactivate_Miner_Product</fullName>
        <description>Deactivates miner product if status is set to inactive.</description>
        <field>IsActive</field>
        <literalValue>0</literalValue>
        <name>Deactivate Miner Product</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_Moving_Average_Cost_Defaults</fullName>
        <description>Moving average cost defaults to the initial cost of part</description>
        <field>UNITY_Moving_Average_Cost__c</field>
        <formula>IF( ISNEW() , UNITY_Product_Cost__c, UNITY_Moving_Average_Cost__c )</formula>
        <name>Moving Average Cost Defaults</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>UNITY Activate Miner Product</fullName>
        <actions>
            <name>UNITY_Activate_Miner_Product</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Sets the active checkbox on the Miner recordtype product to true if status is active</description>
        <formula>RecordType.DeveloperName = &apos;UNITY_Miner&apos; &amp;&amp;  TEXT(UNITY_Status__c) = &apos;Active&apos;</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>UNITY Cost to SMAX Cost</fullName>
        <actions>
            <name>UNITY_Cost_to_SMAX_Cost</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Product2.SVMXC__Product_Cost__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Product2.UNITY_Product_Cost__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Populate the SMAX Cost from the UNITY Cost field if UNITY Cost is populated and SMAX Cost is blank</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>UNITY Deactivate Miner Product</fullName>
        <actions>
            <name>UNITY_Deactivate_Miner_Product</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Sets the active checkbox on the Miner recordtype product to false if status is inactive.</description>
        <formula>RecordType.DeveloperName = &apos;UNITY_Miner&apos; &amp;&amp; NOT(TEXT(UNITY_Status__c) = &apos;Active&apos;)</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
