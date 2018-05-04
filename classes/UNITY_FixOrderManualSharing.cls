public class UNITY_FixOrderManualSharing  implements Database.Batchable<SObject> {
    
    public Database.QueryLocator start(Database.BatchableContext context) {
         return Database.getQueryLocator([
              SELECT Id FROM Account where UNITY_Has_Community_Member__c = true ]);
    }
    
    public void execute(Database.BatchableContext context, List<Account> scope) {
        Set <ID> accID = new Set<ID>();
        for (Account acc : scope){
            accID.add(acc.ID);
        }
        
        List<Order> orderList = new List<Order>([SELECT Id, UNITY_Vendor__c 
                         FROM Order 
                         WHERE  UNITY_Vendor__c = :accID
                         AND Status in ('Final','Accepted','Completed','Parts Being Delivered','Ready to Ship','Parts Order Required')
                           AND RecordTypeId in (Select Id From RecordType where sobjecttype = 'Order' and name in ('Purchase Order', 'Parts Sourcing Purchase Order'))]);
    
        List<UserRole> userRoles = [SELECT Id FROM UserRole WHERE PortalAccountId IN :accID];
        system.debug('>>>  neli userRoles >>>' + userRoles);
        
        List<Group> vendorGroup = [SELECT Id FROM Group WHERE RelatedID IN  :userRoles AND Type = 'RoleAndSubordinates'];
        
        List<OrderShare> orderShares = [SELECT ID, OrderId, OrderAccessLevel, RowCause, UserOrGroupId   
        		FROM OrderShare  
        		WHERE  OrderId IN:orderList 
        		     AND RowCause  = 'Manual' 
        		        AND  UserOrGroupId IN:vendorGroup ]; 
        			
        	
        Map<ID, OrderShare> orderShareIDs = new Map<ID, OrderShare>();
        
        system.debug('>>>  neli orderList >>>' + orderList);
        for (OrderShare ord : orderShares ){
            orderShareIDs.put(ord.OrderId, ord);
        }
        
        Map <ID, List<Order>> orderToShare = new Map<ID, List<Order>>();
        
        for (Order o : orderList){
           List<Order> temp = new List<Order>();
           
           if (!orderShareIDs.containsKey(o.ID)){
              
               if(!orderToShare.containsKey(o.UNITY_Vendor__c)){
                   temp.add(o);
                   orderToShare.put(o.UNITY_Vendor__c, temp);
                   system.debug('>>> vendor >>' + o.UNITY_Vendor__c);
                   system.debug('>>>  order >>>' + temp);
               }
               else{
                   temp = orderToShare.get(o.UNITY_Vendor__c);
                   temp.add(o);
                   orderToShare.put(o.UNITY_Vendor__c, temp); 
                   system.debug('**** vendor ****' + o.UNITY_Vendor__c);
                   system.debug('****  order ****' + temp);
               }
           }
        }
       //===========================================================================================
       for (Id vID : orderToShare.keySet()){
          List<Order> ol = new List<Order>();
           ol = orderToShare.get(vID);
           system.debug('**** order list ***' + ol.size()); 
           AddOrderManualShare (vID, ol);
       }
			 
    }
    
     private  static void AddOrderManualShare(ID vendorAccID, List<Order> orderList){
           
            UserRole userRole = [SELECT Id, PortalAccountId FROM UserRole WHERE PortalAccountId = :vendorAccID];
           
            Group vGroup = [SELECT Id, RelatedID FROM Group WHERE RelatedID = :userRole.Id AND Type = 'RoleAndSubordinates'];
            
            List<OrderShare> shareToInsert = new List<OrderShare>();
            for (Order o:orderList){
              OrderShare os = new OrderShare();
                os.OrderId = o.Id;
                os.OrderAccessLevel = 'Read';
                os.RowCause = Schema.OrderShare.RowCause.Manual;
                os.UserOrGroupId = vGroup.ID;
                shareToInsert.add(os);
                system.debug('&&&&& share &&& ' + os);
                
            }
            
            system.debug('$$$$ sieze to update $$$ ' + shareToInsert.size());
            
            if (shareToInsert.size() > 0)
                 insert shareToInsert;
     }
    
     public void finish(Database.BatchableContext context) {
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}