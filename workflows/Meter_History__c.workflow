<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_WO_Meter_Date</fullName>
        <field>Reading_Date__c</field>
        <formula>Work_Order__r.TFS_Service_Date__c</formula>
        <name>Update WO Meter Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Update WO Meter Date</fullName>
        <actions>
            <name>Update_WO_Meter_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Meter_History__c.Description__c</field>
            <operation>equals</operation>
            <value>Meter Reading From Work Order</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
