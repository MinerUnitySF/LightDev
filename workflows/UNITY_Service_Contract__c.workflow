<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>UNITY_BU_Craft_SC_ID_Active</fullName>
        <field>UNITY_BU_Craft_SC_ID__c</field>
        <formula>IF(INCLUDES( UNITY_Business_Unit__c , &quot;Craft&quot;), CASESAFEID(UNITY_Account__c) + CASESAFEID(UNITY_End_Customer__c) + RecordType.Name + &quot;Craft&quot;, NULL)</formula>
        <name>UNITY BU Craft SC ID Active</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_BU_Craft_SC_ID_Inactive</fullName>
        <field>UNITY_BU_Craft_SC_ID__c</field>
        <name>UNITY BU Craft SC ID Inactive</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_BU_MNS_SC_ID_Active</fullName>
        <field>UNITY_BU_MNS_SC_ID__c</field>
        <formula>IF(INCLUDES( UNITY_Business_Unit__c , &quot;MNS&quot;), CASESAFEID(UNITY_Account__c) + CASESAFEID(UNITY_End_Customer__c) + RecordType.Name + &quot;MNS&quot;, NULL)</formula>
        <name>UNITY BU MNS SC ID Active</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_BU_MNS_SC_ID_Inactive</fullName>
        <field>UNITY_BU_MNS_SC_ID__c</field>
        <name>UNITY BU MNS SC ID Inactive</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_BU_MSP_SC_ID_Active</fullName>
        <field>UNITY_BU_MSP_SC_ID__c</field>
        <formula>IF(INCLUDES( UNITY_Business_Unit__c , &quot;MSP Atlanta&quot;), CASESAFEID(UNITY_Account__c) + CASESAFEID(UNITY_End_Customer__c) + RecordType.Name + &quot;MSP&quot;,

IF(INCLUDES( UNITY_Business_Unit__c , &quot;MSP Dallas&quot;), CASESAFEID(UNITY_Account__c) + CASESAFEID(UNITY_End_Customer__c) + RecordType.Name + &quot;MSP&quot;,

IF(INCLUDES( UNITY_Business_Unit__c , &quot;MSP El Paso&quot;), CASESAFEID(UNITY_Account__c) + CASESAFEID(UNITY_End_Customer__c) + RecordType.Name + &quot;MSP&quot;,

IF(INCLUDES( UNITY_Business_Unit__c , &quot;MSP Houston&quot;), CASESAFEID(UNITY_Account__c) + CASESAFEID(UNITY_End_Customer__c) + RecordType.Name + &quot;MSP&quot;,

IF(INCLUDES( UNITY_Business_Unit__c , &quot;MSP Jacksonville&quot;), CASESAFEID(UNITY_Account__c) + CASESAFEID(UNITY_End_Customer__c) + RecordType.Name + &quot;MSP&quot;,

IF(INCLUDES( UNITY_Business_Unit__c , &quot;MSP Memphis&quot;), CASESAFEID(UNITY_Account__c) + CASESAFEID(UNITY_End_Customer__c) + RecordType.Name + &quot;MSP&quot;,

IF(INCLUDES( UNITY_Business_Unit__c , &quot;MSP Miami&quot;), CASESAFEID(UNITY_Account__c) + CASESAFEID(UNITY_End_Customer__c) + RecordType.Name + &quot;MSP&quot;,

IF(INCLUDES( UNITY_Business_Unit__c , &quot;MSP Nashville&quot;), CASESAFEID(UNITY_Account__c) + CASESAFEID(UNITY_End_Customer__c) + RecordType.Name + &quot;MSP&quot;,

IF(INCLUDES( UNITY_Business_Unit__c , &quot;MSP New Orleans&quot;), CASESAFEID(UNITY_Account__c) + CASESAFEID(UNITY_End_Customer__c) + RecordType.Name + &quot;MSP&quot;,

IF(INCLUDES( UNITY_Business_Unit__c , &quot;MSP Orlando&quot;), CASESAFEID(UNITY_Account__c) + CASESAFEID(UNITY_End_Customer__c) + RecordType.Name + &quot;MSP&quot;,

IF(INCLUDES( UNITY_Business_Unit__c , &quot;MSP Phoenix&quot;), CASESAFEID(UNITY_Account__c) + CASESAFEID(UNITY_End_Customer__c) + RecordType.Name + &quot;MSP&quot;,

IF(INCLUDES( UNITY_Business_Unit__c , &quot;MSP San Antonio&quot;), CASESAFEID(UNITY_Account__c) + CASESAFEID(UNITY_End_Customer__c) + RecordType.Name + &quot;MSP&quot;,

IF(INCLUDES( UNITY_Business_Unit__c , &quot;MSP Tampa&quot;), CASESAFEID(UNITY_Account__c) + CASESAFEID(UNITY_End_Customer__c) + RecordType.Name + &quot;MSP&quot;,

NULL
)))))))))))))</formula>
        <name>UNITY BU MSP SC ID Active</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_BU_MSP_SC_ID_Inactive</fullName>
        <field>UNITY_BU_MSP_SC_ID__c</field>
        <name>UNITY BU MSP SC ID Inactive</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_BU_NSBS_SC_ID_Active</fullName>
        <field>UNITY_BU_NSBS_SC_ID__c</field>
        <formula>IF(INCLUDES( UNITY_Business_Unit__c , &quot;NSBS&quot;), CASESAFEID(UNITY_Account__c) + CASESAFEID(UNITY_End_Customer__c) + RecordType.Name + &quot;NSBS&quot;, NULL)</formula>
        <name>UNITY BU NSBS SC ID Active</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_BU_NSBS_SC_ID_Inactive</fullName>
        <field>UNITY_BU_NSBS_SC_ID__c</field>
        <name>UNITY BU NSBS SC ID Inactive</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>UNITY_Service_Contract_ID_SetNull</fullName>
        <actions>
            <name>UNITY_BU_Craft_SC_ID_Inactive</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>UNITY_BU_MNS_SC_ID_Inactive</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>UNITY_BU_MSP_SC_ID_Inactive</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>UNITY_BU_NSBS_SC_ID_Inactive</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>UNITY_Service_Contract__c.UNITY_IS_Active__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <description>Set Active Service Contract External ID to NULL when Service Contract is set to Inactive</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>UNITY_Service_Contract_ID_Update</fullName>
        <actions>
            <name>UNITY_BU_Craft_SC_ID_Active</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>UNITY_BU_MNS_SC_ID_Active</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>UNITY_BU_MSP_SC_ID_Active</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>UNITY_BU_NSBS_SC_ID_Active</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>UNITY_Service_Contract__c.UNITY_IS_Active__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <description>Populate Service Contract External ID when Active checkbox is set to &apos;Active&apos;</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
