<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>UNITY_Update_Score_PM</fullName>
        <field>Score_PM__c</field>
        <formula>if( ISNULL(UNITY_Score_Factor_WO_1_PM__c), 0, (UNITY_Score_Factor_WO_1_PM__c * 0.13) ) + 
if( ISNULL(UNITY_Score_Factor_WO_2_PM__c), 0, (UNITY_Score_Factor_WO_2_PM__c * 0.13) ) + 
if( ISNULL(UNITY_Score_Factor_WO_3_PM__c), 0, (UNITY_Score_Factor_WO_3_PM__c * 0.20) ) + 
if( ISNULL(UNITY_Score_Factor_WO_4_PM__c), 0, (UNITY_Score_Factor_WO_4_PM__c * 0.13) ) + 
if( ISNULL(UNITY_Score_Factor_WO_5_PM__c), 0, (UNITY_Score_Factor_WO_5_PM__c * 0.13) ) + 
if( ISNULL(UNITY_Score_Factor_VA_1_PM__c), 0, (UNITY_Score_Factor_VA_1_PM__c * 0.13) ) + 
if( ISNULL(UNITY_Score_Factor_VA_2_PM__c), 0, (UNITY_Score_Factor_VA_2_PM__c * 0.13) )</formula>
        <name>Update Score PM</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_Update_Score_Project</fullName>
        <field>Score_Project__c</field>
        <formula>if( ISNULL(UNITY_Score_Factor_WO_1_Project__c), 0, (UNITY_Score_Factor_WO_1_Project__c * 0.13) ) + 
if( ISNULL(UNITY_Score_Factor_WO_2_Project__c), 0, (UNITY_Score_Factor_WO_2_Project__c * 0.13) ) + 
if( ISNULL(UNITY_Score_Factor_WO_3_Project__c), 0, (UNITY_Score_Factor_WO_3_Project__c * 0.20) ) + 
if( ISNULL(UNITY_Score_Factor_WO_4_Project__c), 0, (UNITY_Score_Factor_WO_4_Project__c * 0.13) ) + 
if( ISNULL(UNITY_Score_Factor_WO_5_Project__c), 0, (UNITY_Score_Factor_WO_5_Project__c * 0.13) ) + 
if( ISNULL(UNITY_Score_Factor_VA_1_Project__c), 0, (UNITY_Score_Factor_VA_1_Project__c * 0.13) ) + 
if( ISNULL(UNITY_Score_Factor_VA_2_Project__c), 0, (UNITY_Score_Factor_VA_2_Project__c * 0.13) )</formula>
        <name>Update Score Project</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_Update_Score_SR</fullName>
        <description>Update Score SR</description>
        <field>Score_SR__c</field>
        <formula>if( ISNULL(UNITY_Score_Factor_WO_1_SR__c), 0, (UNITY_Score_Factor_WO_1_SR__c * 0.13) ) + 
if( ISNULL(UNITY_Score_Factor_WO_2_SR__c), 0, (UNITY_Score_Factor_WO_2_SR__c * 0.13) ) + 
if( ISNULL(UNITY_Score_Factor_WO_3_SR__c), 0, (UNITY_Score_Factor_WO_3_SR__c * 0.20) ) + 
if( ISNULL(UNITY_Score_Factor_WO_4_SR__c), 0, (UNITY_Score_Factor_WO_4_SR__c * 0.13) ) + 
if( ISNULL(UNITY_Score_Factor_WO_5_SR__c), 0, (UNITY_Score_Factor_WO_5_SR__c * 0.13) ) + 
if( ISNULL(UNITY_Score_Factor_VA_1_SR__c), 0, (UNITY_Score_Factor_VA_1_SR__c * 0.13) ) + 
if( ISNULL(UNITY_Score_Factor_VA_2_SR__c), 0, (UNITY_Score_Factor_VA_2_SR__c * 0.13) )</formula>
        <name>Update Score SR</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UNITY_Update_Score_SS</fullName>
        <field>Score_SS__c</field>
        <formula>if( ISNULL(UNITY_Score_Factor_WO_1_SS__c), 0, (UNITY_Score_Factor_WO_1_SS__c * 0.13) ) + 
if( ISNULL(UNITY_Score_Factor_WO_2_SS__c), 0, (UNITY_Score_Factor_WO_2_SS__c * 0.13) ) + 
if( ISNULL(UNITY_Score_Factor_WO_3_SS__c), 0, (UNITY_Score_Factor_WO_3_SS__c * 0.20) ) + 
if( ISNULL(UNITY_Score_Factor_WO_4_SS__c), 0, (UNITY_Score_Factor_WO_4_SS__c * 0.13) ) + 
if( ISNULL(UNITY_Score_Factor_WO_5_SS__c), 0, (UNITY_Score_Factor_WO_5_SS__c * 0.13) ) + 
if( ISNULL(UNITY_Score_Factor_VA_1_SS__c), 0, (UNITY_Score_Factor_VA_1_SS__c * 0.13) ) + 
if( ISNULL(UNITY_Score_Factor_VA_2_SS__c), 0, (UNITY_Score_Factor_VA_2_SS__c * 0.13) )</formula>
        <name>Update Score SS</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>UNITY_Calc_Overall_Score</fullName>
        <actions>
            <name>UNITY_Update_Score_PM</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>UNITY_Update_Score_Project</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>UNITY_Update_Score_SR</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>UNITY_Update_Score_SS</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Workflow rule on VendorTrade record that monitor change of Vendor.UNITY_LastScored_WO, UNITY_LastScored_VA, UNITY_LastScored_Warranty Field to calculate overall score W-000631</description>
        <formula>OR (  ISCHANGED( UNITY_LastScored_WO__c ) ,  ISCHANGED( UNITY_LastScored_VA__c ) ,  ISCHANGED( UNITY_LastScored_WA__c )  )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
