<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>UNITY_Active_Date</fullName>
        <description>Populate Active Date when asset is marked as active</description>
        <field>UNITY_Active_Date__c</field>
        <formula>TODAY()</formula>
        <name>UNITY Active Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_Inactive_Date</fullName>
        <description>Inactive Date is populated with assets is marked as inactive</description>
        <field>UNITY_Inactive_Date__c</field>
        <formula>TODAY()</formula>
        <name>UNITY Inactive Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_Retired_Date</fullName>
        <description>Set Retired Date when Is Retired? is checked</description>
        <field>UNITY_Retired_Date__c</field>
        <formula>TODAY()</formula>
        <name>UNITY Retired Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_Set_Initial_Active_Date</fullName>
        <description>Set the initial active date</description>
        <field>UNITY_Initial_Active_Date__c</field>
        <formula>TODAY()</formula>
        <name>UNITY Set Initial Active Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_Set_Retired_Date_To_Null</fullName>
        <description>Set Retired Date to Null if Is Retired? is unchecked</description>
        <field>UNITY_Retired_Date__c</field>
        <name>UNITY Set Retired Date To Null</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>UNITY_Active_Date</fullName>
        <actions>
            <name>UNITY_Active_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Asset.UNITY_Active__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <description>Populate Active Date when asset is marked as active</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>UNITY_Inactive_Date</fullName>
        <actions>
            <name>UNITY_Inactive_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Asset.UNITY_Active__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Asset.UNITY_Is_Retired__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <description>Inactive Date is populated when assets is marked as inactive</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>UNITY_Retired_Date</fullName>
        <actions>
            <name>UNITY_Retired_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Asset.UNITY_Is_Retired__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <description>Populate Retired Date when Is Retired? is checked</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>UNITY_Set_Initial_Active_Date</fullName>
        <actions>
            <name>UNITY_Set_Initial_Active_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Asset.UNITY_Active__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <description>Set initial active date for lifecycle of asset</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>UNITY_Set_Retired_Date_To_Null</fullName>
        <actions>
            <name>UNITY_Set_Retired_Date_To_Null</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Asset.UNITY_Is_Retired__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
