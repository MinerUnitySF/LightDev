<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Notify_Miner_Corp_of_new_lead</fullName>
        <description>Notify Miner Corp of new lead</description>
        <protected>false</protected>
        <recipients>
            <recipient>rupton@minercorp.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>SalesCloud_Emails/Lead_Transferred_to_Miner_Corp</template>
    </alerts>
    <fieldUpdates>
        <fullName>Business_Unit_Miner_Corp</fullName>
        <field>Business_Unit__c</field>
        <literalValue>Miner Corp</literalValue>
        <name>Business Unit Miner Corp</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Combine_to_Description</fullName>
        <description>Combine Pardot Comments to Description</description>
        <field>Description</field>
        <formula>IF(
  Description != NULL,
  Description &amp;  BR() &amp; pi__comments__c,
  pi__comments__c
)</formula>
        <name>Combine to Description</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Lead_Status_to_Transferred</fullName>
        <description>Will set lead status to transferred for leads sent to Miner Corp</description>
        <field>Status</field>
        <literalValue>Transferred</literalValue>
        <name>Set Lead Status to Transferred</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Queue_to_Miner_Corp</fullName>
        <description>This will set the owner to the Miner Corp Queue to remove from public view, but not remove the lead. This will allow reporting on leads sent from Miner National to Miner Corp</description>
        <field>OwnerId</field>
        <lookupValue>Miner_Corp_Leads_Queue</lookupValue>
        <lookupValueType>Queue</lookupValueType>
        <name>Set Queue to Miner Corp</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Invoca Business Unit</fullName>
        <actions>
            <name>Business_Unit_Miner_Corp</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>User.LastName</field>
            <operation>equals</operation>
            <value>Admin</value>
        </criteriaItems>
        <criteriaItems>
            <field>User.FirstName</field>
            <operation>equals</operation>
            <value>Invoca</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Lead Combined Description</fullName>
        <actions>
            <name>Combine_to_Description</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>Combines the Pardot Description with the standard Description field on the lead</description>
        <formula>pi__comments__c != NULL</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Lead Transferred to Miner Corp</fullName>
        <actions>
            <name>Notify_Miner_Corp_of_new_lead</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Set_Lead_Status_to_Transferred</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Set_Queue_to_Miner_Corp</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Lead.Business_Unit__c</field>
            <operation>equals</operation>
            <value>Miner Corp</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
