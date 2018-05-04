<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>SFPS_FS_UnableToFinish_Reset</fullName>
        <field>FSO__UnableToFinish__c</field>
        <literalValue>0</literalValue>
        <name>SFPS FS Unable to Finish Reset</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>SFPS_FS_UnableToFinish_Reset</fullName>
        <actions>
            <name>SFPS_FS_UnableToFinish_Reset</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>WorkOrderLineItem.FSO__IsCompleted__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
