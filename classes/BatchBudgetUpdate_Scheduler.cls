/**This class is used to schedule the BatchBudgetUpdate class
***@Developer: Izay Ramos-Irizarry
***@Date:      7/1/2015
***@Version:   1.0
*/
global class BatchBudgetUpdate_Scheduler implements Schedulable{
    public BatchBudgetUpdate b = new BatchBudgetUpdate();
    global void execute(SchedulableContext sc) {
        Database.executeBatch(this.b, 6);
    }
}