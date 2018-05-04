<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Lease_Inactivate</fullName>
        <description>Toggles any open leases to inactive status if the IP is made to be Inactive</description>
        <field>Active_Lease__c</field>
        <literalValue>0</literalValue>
        <name>Lease Inactivate</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Lease Inactivate</fullName>
        <actions>
            <name>Lease_Inactivate</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lease_Information__c.IP_Active__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <description>Toggles any open leases to inactive status if the IP is made to be Inactive</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
