global class MSPFS_IntercompanyBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        //MyBatchClass b = new MyBatchClass();
        //database.executebatch(b);
        MSPFS_IntercompanyProcessingBatch b = new MSPFS_IntercompanyProcessingBatch();
        database.executeBatch(b,1);
    }
}