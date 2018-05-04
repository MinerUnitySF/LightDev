<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Idle_Opportunity_Notification_MIner</fullName>
        <description>Idle Opportunity Notification - MIner</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <recipients>
            <recipient>rupton@minercorp.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>SalesCloud_Emails/Idle_Opportunity_Notification</template>
    </alerts>
    <alerts>
        <fullName>Idle_Opportunity_Notification_TFS</fullName>
        <description>Idle Opportunity Notification - TFS</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <recipients>
            <recipient>tryder@tfsglobal.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>SalesCloud_Emails/Idle_Opportunity_Notification</template>
    </alerts>
    <alerts>
        <fullName>Opportunity_Close_Date_change_to_future_date_Miner</fullName>
        <description>Opportunity Close Date change to future date - Miner</description>
        <protected>false</protected>
        <recipients>
            <recipient>rupton@minercorp.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>SalesCloud_Emails/Oppportunity_Close_Date_changed</template>
    </alerts>
    <alerts>
        <fullName>Opportunity_Close_Date_change_to_future_date_TFS</fullName>
        <description>Opportunity Close Date change to future date - TFS</description>
        <protected>false</protected>
        <recipients>
            <recipient>tryder@tfsglobal.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>SalesCloud_Emails/Oppportunity_Close_Date_changed</template>
    </alerts>
    <alerts>
        <fullName>Opportunity_Flexx_Won_Oppty</fullName>
        <ccEmails>flexxteam@flexxrl.com</ccEmails>
        <description>Opportunity: Flexx Won Oppty</description>
        <protected>false</protected>
        <senderType>CurrentUser</senderType>
        <template>SalesCloud_Emails/FLEXX_Won_Oppty</template>
    </alerts>
    <alerts>
        <fullName>Opportunity_Past_Close_Date_Email_alert_MINER</fullName>
        <description>Opportunity Past Close Date Email alert - MINER</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <recipients>
            <recipient>rupton@minercorp.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>SalesCloud_Emails/Opportunity_Past_Closed_Date</template>
    </alerts>
    <alerts>
        <fullName>Opportunity_Past_Close_Date_Email_alert_TFS</fullName>
        <description>Opportunity Past Close Date Email alert - TFS</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <recipients>
            <recipient>tryder@tfsglobal.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>SalesCloud_Emails/Opportunity_Past_Closed_Date</template>
    </alerts>
    <fieldUpdates>
        <fullName>Flag_GC_Selection_box_as_true</fullName>
        <field>GC_Selection_Opportunity__c</field>
        <literalValue>1</literalValue>
        <name>Flag GC Selection box as true</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Clear_At_Risk</fullName>
        <description>Clears the At Risk and At Risk checkbox</description>
        <field>At_Risk__c</field>
        <literalValue>0</literalValue>
        <name>Opportunity - Clear At Risk</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Clear_At_Risk_Send_Email</fullName>
        <description>Clears the at risk send email field</description>
        <field>At_Risk_Send_Email__c</field>
        <literalValue>0</literalValue>
        <name>Opportunity - Clear At Risk Send Email</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Flag_At_Risk</fullName>
        <description>This field update flags an Opportunity as At Risk</description>
        <field>At_Risk__c</field>
        <literalValue>1</literalValue>
        <name>Opportunity - Flag At Risk</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Flag_Send_At_Risk_Email</fullName>
        <description>Will flag opportunity field At Risk Send Email? To TRUE. Once the trigger sends the email, it will uncheck this for the next time cycle</description>
        <field>At_Risk_Send_Email__c</field>
        <literalValue>1</literalValue>
        <name>Opportunity - Flag Send At Risk Email</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Stage_Change_Time_Stamp</fullName>
        <description>Changes the Stage_Change_Time_Stamp field to be Now(). This should be fired only when the Opportunity StageName field is changed.</description>
        <field>Stage_Change_Time_Stamp__c</field>
        <formula>NOW()</formula>
        <name>Opportunity - Stage Change Time Stamp</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Update_Status</fullName>
        <description>Update the status field to closed</description>
        <field>Status__c</field>
        <literalValue>Closed</literalValue>
        <name>Opportunity Update Status</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Send_Close_Date_Email_FALSE</fullName>
        <field>Send_Close_Date_Email__c</field>
        <literalValue>0</literalValue>
        <name>Send Close Date Email - FALSE</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Actual_Closed_Date</fullName>
        <field>Actual_Closed_Date__c</field>
        <formula>TODAY()</formula>
        <name>Set Actual Closed Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Opportunity_Record_Type_Readonly</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Read_Only</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Set Opportunity Record Type - Readonly</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Uncheck_Opportunity_Pending_Flag</fullName>
        <description>When opportunity is closed, the associated account opportunity pending flag is unchecked.</description>
        <field>Opportunity_Pending__c</field>
        <literalValue>0</literalValue>
        <name>Uncheck Opportunity Pending Flag</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <targetObject>AccountId</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>copy_custom_Amount_to_Standard_Amount</fullName>
        <field>Amount</field>
        <formula>Amount__c</formula>
        <name>copy custom Amount to Standard Amount</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Everytime an Opp is edited</fullName>
        <actions>
            <name>copy_custom_Amount_to_Standard_Amount</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.IsClosed</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.RecordTypeId</field>
            <operation>notEqual</operation>
            <value>Short Term Rental,Term Deals,Miner Corp Opportunities,Read-Only</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Flag GC Selection Opp</fullName>
        <actions>
            <name>Flag_GC_Selection_box_as_true</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.RecordTypeId</field>
            <operation>equals</operation>
            <value>Miner Corp/BDC Opportunities</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>equals</operation>
            <value>GC Selection</value>
        </criteriaItems>
        <description>Created by Vertiba to flag the GC Opp checkbox if opp reaches GC Selection Stage.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Opportunity -  1 day -At Risk Alert</fullName>
        <active>true</active>
        <description>This marks an Opportunity as High Risk depending on the Opportunity stage, sale cycle, and how much time has passed</description>
        <formula>TEXT(StageName) = &apos;Discovery&apos; &amp;&amp; (TEXT(Sales_Cycle__c) = &apos;&lt; 30&apos; || TEXT(Sales_Cycle__c) = &apos;30 - 60&apos;)</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Flag_At_Risk</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Opportunity_Flag_Send_At_Risk_Email</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Opportunity.Stage_Change_Time_Stamp__c</offsetFromField>
            <timeLength>2</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Flag_At_Risk</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Opportunity_Flag_Send_At_Risk_Email</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Opportunity.Stage_Change_Time_Stamp__c</offsetFromField>
            <timeLength>24</timeLength>
            <workflowTimeTriggerUnit>Hours</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Flag_At_Risk</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Opportunity_Flag_Send_At_Risk_Email</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Opportunity.Stage_Change_Time_Stamp__c</offsetFromField>
            <timeLength>3</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Opportunity -  14 day -At Risk Alert</fullName>
        <active>true</active>
        <description>This marks an Opportunity as High Risk depending on the Opportunity stage, sale cycle, and how much time has passed</description>
        <formula>TEXT(StageName) = &apos;Solutions Design&apos; &amp;&amp; TEXT(Sales_Cycle__c) = &apos;90+&apos;</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Flag_At_Risk</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Opportunity_Flag_Send_At_Risk_Email</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Opportunity.Stage_Change_Time_Stamp__c</offsetFromField>
            <timeLength>15</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Flag_At_Risk</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Opportunity_Flag_Send_At_Risk_Email</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Opportunity.Stage_Change_Time_Stamp__c</offsetFromField>
            <timeLength>16</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Flag_At_Risk</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Opportunity_Flag_Send_At_Risk_Email</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Opportunity.Stage_Change_Time_Stamp__c</offsetFromField>
            <timeLength>14</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Opportunity -  2 day -At Risk Alert</fullName>
        <active>true</active>
        <description>This marks an Opportunity as High Risk depending on the Opportunity stage, sale cycle, and how much time has passed</description>
        <formula>TEXT(StageName) = &apos;Discovery&apos; &amp;&amp; TEXT(Sales_Cycle__c) = &apos;60 - 90&apos;</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Flag_At_Risk</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Opportunity_Flag_Send_At_Risk_Email</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Opportunity.Stage_Change_Time_Stamp__c</offsetFromField>
            <timeLength>4</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Flag_At_Risk</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Opportunity_Flag_Send_At_Risk_Email</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Opportunity.Stage_Change_Time_Stamp__c</offsetFromField>
            <timeLength>3</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Flag_At_Risk</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Opportunity_Flag_Send_At_Risk_Email</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Opportunity.Stage_Change_Time_Stamp__c</offsetFromField>
            <timeLength>2</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Opportunity -  3 day -At Risk Alert</fullName>
        <active>true</active>
        <description>This marks an Opportunity as High Risk depending on the Opportunity stage, sale cycle, and how much time has passed</description>
        <formula>(TEXT(StageName) = &apos;Discovery&apos; &amp;&amp; TEXT(Sales_Cycle__c) = &apos;90+&apos;) || (TEXT(StageName) = &apos;Solutions Design&apos; &amp;&amp; TEXT(Sales_Cycle__c) = &apos;&lt; 30&apos;)</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Flag_At_Risk</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Opportunity_Flag_Send_At_Risk_Email</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Opportunity.Stage_Change_Time_Stamp__c</offsetFromField>
            <timeLength>3</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Flag_At_Risk</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Opportunity_Flag_Send_At_Risk_Email</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Opportunity.Stage_Change_Time_Stamp__c</offsetFromField>
            <timeLength>4</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Flag_At_Risk</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Opportunity_Flag_Send_At_Risk_Email</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Opportunity.Stage_Change_Time_Stamp__c</offsetFromField>
            <timeLength>5</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Opportunity -  6 day -At Risk Alert</fullName>
        <active>true</active>
        <description>This marks an Opportunity as High Risk depending on the Opportunity stage, sale cycle, and how much time has passed</description>
        <formula>TEXT(StageName) = &apos;Solutions Design&apos; &amp;&amp; TEXT(Sales_Cycle__c) = &apos;30 - 60&apos;</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Flag_At_Risk</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Opportunity_Flag_Send_At_Risk_Email</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Opportunity.Stage_Change_Time_Stamp__c</offsetFromField>
            <timeLength>6</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Flag_At_Risk</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Opportunity_Flag_Send_At_Risk_Email</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Opportunity.Stage_Change_Time_Stamp__c</offsetFromField>
            <timeLength>7</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Flag_At_Risk</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Opportunity_Flag_Send_At_Risk_Email</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Opportunity.Stage_Change_Time_Stamp__c</offsetFromField>
            <timeLength>8</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Opportunity -  9 day -At Risk Alert</fullName>
        <active>true</active>
        <description>This marks an Opportunity as High Risk depending on the Opportunity stage, sale cycle, and how much time has passed</description>
        <formula>TEXT(StageName) = &apos;Solutions Design&apos; &amp;&amp; TEXT(Sales_Cycle__c) = &apos;60 - 90&apos;</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Flag_At_Risk</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Opportunity_Flag_Send_At_Risk_Email</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Opportunity.Stage_Change_Time_Stamp__c</offsetFromField>
            <timeLength>11</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Flag_At_Risk</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Opportunity_Flag_Send_At_Risk_Email</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Opportunity.Stage_Change_Time_Stamp__c</offsetFromField>
            <timeLength>9</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Flag_At_Risk</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Opportunity_Flag_Send_At_Risk_Email</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Opportunity.Stage_Change_Time_Stamp__c</offsetFromField>
            <timeLength>10</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Opportunity - Stage or Cycle Change Time Stamp</fullName>
        <actions>
            <name>Opportunity_Clear_At_Risk</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Opportunity_Clear_At_Risk_Send_Email</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Opportunity_Stage_Change_Time_Stamp</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>This will stamp the date/time the Stage on an Opportunity was changed to a specific custom field.</description>
        <formula>ISCHANGED(StageName) || ISCHANGED(Sales_Cycle__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Opportunity Closed</fullName>
        <actions>
            <name>Opportunity_Update_Status</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>equals</operation>
            <value>Closed Won,Closed Lost</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.RecordTypeId</field>
            <operation>equals</operation>
            <value>Miner Corp/BDC Opportunities</value>
        </criteriaItems>
        <description>Update the opportunity status when the opportunity stage is set to Closed Won or Closed Lost</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Opportunity Closed Uncheck Pending Flag on Account</fullName>
        <actions>
            <name>Uncheck_Opportunity_Pending_Flag</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>equals</operation>
            <value>,Closed Won,Closed Lost,Delivered,Funded</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.RecordTypeId</field>
            <operation>equals</operation>
            <value>Miner Corp/BDC Opportunities,Short Term Rental,Term Deals,NMS Opportunities</value>
        </criteriaItems>
        <description>When an opportunity is closed for MinerCorp, the Opportunity Pending flag becomes unchecked which will trigger the account to download to the ERP.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Opportunity Closed Won</fullName>
        <actions>
            <name>Set_Actual_Closed_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Set_Opportunity_Record_Type_Readonly</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>equals</operation>
            <value>Closed Won</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.RecordTypeId</field>
            <operation>notEqual</operation>
            <value>Miner Corp/BDC Opportunities,Short Term Rental,Term Deals</value>
        </criteriaItems>
        <description>used to change change record type to read only and set actual closed date</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Opportunity Past Closed Date - Miner</fullName>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>notEqual</operation>
            <value>Closed Won,Closed Lost,Disengage</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Business_Unit__c</field>
            <operation>equals</operation>
            <value>Miner National</value>
        </criteriaItems>
        <description>Workflow to alert on Open Opportunities that have past their close date</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Past_Close_Date_Email_alert_MINER</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>Opportunity.CloseDate</offsetFromField>
            <timeLength>1</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Opportunity Past Closed Date - TFS</fullName>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>notEqual</operation>
            <value>Closed Won,Closed Lost,Disengage</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Business_Unit__c</field>
            <operation>equals</operation>
            <value>Total Fleet Solution</value>
        </criteriaItems>
        <description>Workflow to alert on Open Opportunities that have past their close date</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Past_Close_Date_Email_alert_TFS</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>Opportunity.CloseDate</offsetFromField>
            <timeLength>1</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Opportunity%3A Flexx Won Oppty</fullName>
        <actions>
            <name>Opportunity_Flexx_Won_Oppty</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.RecordTypeId</field>
            <operation>equals</operation>
            <value>Term Deals,Short Term Rental</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>equals</operation>
            <value>Closed Won</value>
        </criteriaItems>
        <description>Vertiba 04/03/2014 - Created for FLEXX  to send an email when an oppty is won</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Oppportunity Close Date changed - Miner</fullName>
        <actions>
            <name>Opportunity_Close_Date_change_to_future_date_Miner</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Send_Close_Date_Email_FALSE</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.Send_Close_Date_Email__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Business_Unit__c</field>
            <operation>equals</operation>
            <value>Miner National</value>
        </criteriaItems>
        <description>Will check if Send Closed Email is true. This set by a trigger that will check tosee if close date is moved into the future.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Oppportunity Close Date changed - TFS</fullName>
        <actions>
            <name>Opportunity_Close_Date_change_to_future_date_TFS</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Send_Close_Date_Email_FALSE</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.Send_Close_Date_Email__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Business_Unit__c</field>
            <operation>equals</operation>
            <value>Total Fleet Solution</value>
        </criteriaItems>
        <description>Will check if Send Closed Email is true. This set by a trigger that will check tosee if close date is moved into the future.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>opportunity with no activity - Miner</fullName>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>notEqual</operation>
            <value>Closed Won,Closed Lost,Disengage</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Business_Unit__c</field>
            <operation>equals</operation>
            <value>Miner National</value>
        </criteriaItems>
        <description>Workflow Rule to alert on an Opportunity that has become Idle</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Idle_Opportunity_Notification_MIner</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>Opportunity.LastModifiedDate</offsetFromField>
            <timeLength>14</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>opportunity with no activity - TFS</fullName>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>notEqual</operation>
            <value>Closed Won,Closed Lost,Disengage</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Business_Unit__c</field>
            <operation>equals</operation>
            <value>Total Fleet Solution</value>
        </criteriaItems>
        <description>Workflow Rule to alert on an Opportunity that has become Idle</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Idle_Opportunity_Notification_TFS</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>Opportunity.LastModifiedDate</offsetFromField>
            <timeLength>14</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
</Workflow>
