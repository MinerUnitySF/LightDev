/**This class serves as unit test for the BatchBudgetUpdate class
***@Developer: Izay Ramos-Irizarry
***@Date:      8/1/2015
***@Version:   1.0
*/
@isTest(SeeAllData=true)
public class BatchBudgetUpdate_UT {
    
    public static TestMethod void test1(){
        //Get budget Record Types
        List<RecordType> budgetRecTypes = [SELECT Id FROM RecordType WHERE SObjectType = 'Budget__c'];
        //Need a super center
        Super_Center__c sc = new Super_Center__c();
        sc.Name = 'Miner-Central Texas';
        sc.Super_Center__c = 'Miner-Central Texas';
        insert sc;
        //Need a segment
        Segment__c seg = new Segment__c();
        seg.Super_Center__c = sc.Id;
        seg.Name = 'San Antonio';
        seg.Segment_Name__c = 'San Antonio';
        insert seg;
        //Need three budget record for the super center for the past three months
        //Need start and end date for the budget
        Date startOfMonth = Date.today().toStartOfMonth();
        Date endOfMonth = startOfMonth.addMonths(1).toStartOfMonth() - 1;
        //The first budget
        Budget__c b1 = new Budget__c();
        b1.Name = 'This Month';
        b1.Active__c = true;
        b1.Start_Date__c = startOfMonth;
        b1.End_Date__c = endOfMonth;
        b1.Super_Center__c = sc.Id;
        b1.Equipment_Revenue_Target__c = 0; 
        b1.Service_Average_Call_Revenue__c = 0; 
        b1.Service_Gross_Target__c = 0;
        b1.Service_Revenue_Target__c = 0;
        b1.RecordTypeId = budgetRecTypes[0].Id;
        b1.Segment__c = seg.Id;
        insert b1;
        //Need to change start and end date for new budget
        startOfMonth = startOfMonth.addMonths(-1);
        endOfMonth = startOfMonth.addMonths(1).toStartOfMonth() - 1;
        //The second budget
        Budget__c b2 = new Budget__c();
        b2.Name = 'Last Month';
        b2.Active__c = true;
        b2.Start_Date__c = startOfMonth;
        b2.End_Date__c = endOfMonth;
        b2.Super_Center__c = sc.Id;
        b2.Segment__c = seg.Id;
        b2.Equipment_Revenue_Target__c = 0; 
        b2.Service_Average_Call_Revenue__c = 0; 
        b2.Service_Gross_Target__c = 0;
        b2.Service_Revenue_Target__c = 0;
        b2.RecordTypeId = budgetRecTypes[1].Id;
        insert b2;
        //Need to change start and end date for the new budget
        startOfMonth = startOfMonth.addMonths(-1);
        endOfMonth = startOfMonth.addMonths(1).toStartOfMonth() - 1;
        //the third budget
        Budget__c b3 = new Budget__c();
        b3.Name = 'Month Before Last';
        b3.Active__c = true;
        b3.Start_Date__c = startOfMonth;
        b3.End_Date__c = endOfMonth;
        b3.Super_Center__c = sc.Id;
        b3.Segment__c = seg.Id;
        b3.Equipment_Revenue_Target__c = 0; 
        b3.Service_Average_Call_Revenue__c = 0; 
        b3.Service_Gross_Target__c = 0;
        b3.Service_Revenue_Target__c = 0;
        insert b3;
        Test.startTest();
        BatchBudgetUpdate b = new BatchBudgetUpdate();
        b.query = 'SELECT Id,Name,Service_Revenue_Actual__c,Service_Gross_Actual__c,Period_Month__c,Period_Year__c,End_Date__c,Start_Date__c,Active__c,Equipment_Gross_Actual__c,Equipment_Revenue_Actual__c,' +
                'Equipment_Call_Volume_Actual__c,Equipment_Scheduled_Call_Volume_Actual__c,Equipment_Invoiced_Call_Volume_Actual__c,Service_Gross_Profit_Opportunity_Dollars__c,'+
                'Service_Revenue_Opportunity_Dollars__c,Equipment_Revenue_Opportunity_Dollars__c,Equipment_Gross_Profit_Opportunity__c,'+
                'Service_Call_Volume_Actual__c,Service_Scheduled_Call_Volume_Actual__c,Service_Invoiced_Call_Volume_Actual__c,Super_Center__c,Super_Center__r.Name,' +
                'Super_Center__r.Super_Center__c,Super_Center__r.Segment__c,Segment__c,Segment__r.Segment_Name__c,RecordTypeId' +
                ' FROM Budget__c WHERE (Start_Date__c >= LAST_YEAR AND End_Date__c <= THIS_YEAR) AND Active__c = TRUE' +
                ' ORDER BY CreatedDate DESC, Super_Center__r.Name DESC, Start_Date__c ASC LIMIT 3';
        Database.executeBatch(b);
        Test.stopTest();
    }
    
    public static TestMethod void test3(){
        BatchBudgetUpdate_Scheduler scheduler = new BatchBudgetUpdate_Scheduler();
        scheduler.b.query = 'SELECT Id,Name,Service_Revenue_Actual__c,Service_Gross_Actual__c,Period_Month__c,Period_Year__c,End_Date__c,Start_Date__c,Active__c,Equipment_Gross_Actual__c,Equipment_Revenue_Actual__c,' +
                'Equipment_Call_Volume_Actual__c,Equipment_Scheduled_Call_Volume_Actual__c,Equipment_Invoiced_Call_Volume_Actual__c,Service_Gross_Profit_Opportunity_Dollars__c,'+
                'Service_Revenue_Opportunity_Dollars__c,Equipment_Revenue_Opportunity_Dollars__c,Equipment_Gross_Profit_Opportunity__c,'+
                'Service_Call_Volume_Actual__c,Service_Scheduled_Call_Volume_Actual__c,Service_Invoiced_Call_Volume_Actual__c,Super_Center__c,Super_Center__r.Name,' +
                'Super_Center__r.Super_Center__c,Super_Center__r.Segment__c,Segment__c,Segment__r.Segment_Name__c,RecordTypeId' +
                ' FROM Budget__c WHERE (Start_Date__c >= LAST_YEAR AND End_Date__c <= THIS_YEAR) AND Active__c = TRUE' +
                ' ORDER BY Super_Center__r.Name DESC, Start_Date__c ASC LIMIT 3';
        String sch = '20 30 8 10 2 ?';
        Test.startTest();
        String jobID = system.schedule('Service Report Tracker Job', sch, scheduler);
        Test.stopTest();
    }
    
}