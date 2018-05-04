public class UNITY_OrdersController{
    public List<Order>orders {get; set;}
    public List<OrderWrapper> ordersList {get;set;}
    public ID workOrderId {get; set;}
    //public String createdDate {get;set;}
    public Order currentOrder {get;set;}
    public CurrentOrderWrapper cOrderWrapper {get;set;}
    //public String currentOrdeCreatedDate {get;set;}
    public ID assignedVendorId;
        public ID getAssignedVendorId(){
            return assignedVendorId;
        }
        public void setAssignedVendorId(ID s){
            assignedVendorId = s;
            UNITY_OrdersController();
    }
    public void UNITY_OrdersController(){
        try{
            WorkOrder wo = [SELECT UNITY_Current_PO__r.Id FROM WorkOrder WHERE Id = :workOrderId][0];
            //Id currentOrderId = wo.UNITY_Current_PO__c.Id;

            if (wo.UNITY_Current_PO__r.Id != null)
            {
                currentOrder = [SELECT RecordTypeId, OrderNumber,TotalAmount,UNITY_Total_Cost__c,CreatedDate,UNITY_NTE__c
                                FROM Order WHERE Id = :wo.UNITY_Current_PO__r.Id];
                cOrderWrapper =new CurrentOrderWrapper(currentOrder,currentOrder.CreatedDate);
            }
            else
            {
                currentOrder = null;
                cOrderWrapper = null;
            }


        ordersList=new List<OrderWrapper>();

        if (currentOrder != null)
        {
            orders =[SELECT OrderNumber,TotalAmount,UNITY_Total_Cost__c,CreatedDate,UNITY_NTE__c
                 FROM ORDER
                 WHERE FSO__WorkOrder__c=:workOrderId
                 AND UNITY_Vendor__c =:assignedVendorId             
                 AND Id != :currentOrder.Id 
                 AND RecordTypeId = :currentOrder.RecordTypeId 
                 AND Status in ('Final', 'Accepted')
                 Order By CreatedDate Desc];

            for(Order o : orders){
                OrderWrapper ow =new OrderWrapper(o,o.CreatedDate);
                ordersList.add(ow);
            }
        }

        }catch(Exception e){
            System.Debug(e);
        }
    }
    class OrderWrapper{
        public Order orderRecord {get;set;}
        public String CreatedDate {get;set;}
        //public OrderWrapper(){}
        public OrderWrapper(Order o,DateTime cd){
            orderRecord=o;
            //CreatedDate = UNITY_Utils.getDateTime(cd,'MM/dd/yyyy HH:mm:ss','CST').get('full').substringBefore(' ');
            CreatedDate = UNITY_Utils.getDateTime(cd,'MM/dd/yyyy HH:mm:ss','CST').formatDate;

        }
    }
    class CurrentOrderWrapper{
        public Order currentOrderRecord {get;set;}
        public String CreatedDate {get;set;}
        public CurrentOrderWrapper(Order o,DateTime cd){
            currentOrderRecord=o;
            CreatedDate = UNITY_Utils.getDateTime(cd,'MM/dd/yyyy HH:mm:ss','CST').formatDate;
        }
    }
}