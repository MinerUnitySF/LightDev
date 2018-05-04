/*
 *   @programer:    Samuel Astol
 *   @description:  Pull hierarchical template data from Template Configuration.
 *   @date:         11/23/2015            
 */
 
 
public class UNITY_TemplateConfig {
    
}
/*    
    
        private Map<String, Schema.SObjectType> globalDescribe{get;set;}
        
        private id standardPriceBookId{get;set;}
    
        // < parent template record id , SObjects to create, children of the parent Template   >
        private Map< id, list<SObject> > recordDependent{get;set;}
        
        // store all templates used in the trigger  < template id , template config object >
        private Map< id , UNITY_Template_Configuration__c > templates{get;set;}
        
        // map to relate parent template to children,  < parent template id , children templates records >
        private Map< id , list<UNITY_Template_Configuration__c> > templateTree{get;set;}
        
        // list to insert 
        list< SObject >  toInsert{get;set;}
        
        
        // key   : order Id
        // value : Pricebook2Id related
        Map< id, id >  order_pricebook;
    
        // key   : Pricebook Id 
        // value : Map --> key : product id , value : priceBookentry
        private Map< String , Map<id,PricebookEntry> >  priceBook_groups{get;set;}
    
        public UNITY_TemplateConfig(){
            
            globalDescribe  = Schema.getGlobalDescribe();
            recordDependent = new Map< id, list<SObject> >();
            templateTree    = new Map< id , list<UNITY_Template_Configuration__c> >();
            toInsert        =  new list< SObject >();
            priceBook_groups = new Map< String,  Map<id,PricebookEntry> >();    
            order_pricebook = new Map<id, id>();
            
            if(Test.isRunningTest()){
                standardPriceBookId = Test.getStandardPricebookId();
            }else{
                standardPriceBookId = [SELECT id FROM Pricebook2 WHERE Name = 'Standard Price Book'].id;
            }
            
        }
        
        public void handleTemplates( Map<id, id> recordTemplateMap ){
            
             
            Set<id> aux_orderIds = new Set<id>();
            
            
            // store the template names  involved in the trigger 
            Set<String>  templatesNames = new Set<String>();
            
            Set<id>  productsIds = new Set<id>();
            
            // template parent related to the SObject to create 
            Map< id, list<SObject>>  template_SObjects = new Map<id, list<SObject>>();
            
            // template parent related to the SObject to create 
            Map< id, list<id> >  reverse_parentT_childrenT = new Map< id, list<id> >();
            
            Map<Schema.SObjectType , list<SObject> > aux_orderBySobjectType = new Map<Schema.SObjectType , list<SObject> >();
            
            for(id sobjectId :recordTemplateMap.keySet()){
                
                // get Order id and query for the Price book Related 
                if( sobjectId.getSobjectType().getDescribe().getName() == 'Order' ){
                     aux_orderIds.add(sobjectId);
                } 
                
            }
            
            Map< id , Order > ordersMap = new Map< id , Order >([SELECT id, Pricebook2Id FROM Order WHERE id IN :aux_orderIds ]);
            
            for(id sobjectId :ordersMap.keySet()){
                
                if( ordersMap.get(sobjectId).Pricebook2Id != null ){
                     order_pricebook.put( sobjectId , ordersMap.get(sobjectId).Pricebook2Id );
                }
               
            }
            

            
            // query for template names 
            Map<id, UNITY_Template_Configuration__c> parentTemplates = new Map<id, UNITY_Template_Configuration__c> ([ SELECT  id, Name
                                                                                                                     FROM  UNITY_Template_Configuration__c 
                                                                                                                     WHERE id IN :recordTemplateMap.values()]);
            
            // Capturing names 
            for(UNITY_Template_Configuration__c onT :parentTemplates.values()){
                
                templatesNames.add(onT.Name);
                   
            }   
            
            // query for templates records with equal names 
            templates = new Map<  id , UNITY_Template_Configuration__c > ([   SELECT  id, Name ,
                                                                                     UNITY_Level_Number__c ,
                                                                                     UNITY_Node_Type__c ,
                                                                                     UNITY_Node_Value__c ,
                                                                                     UNITY_Part_Lookup__c ,
                                                                                     UNITY_Target_Object__c ,
                                                                                     UNITY_Target_Object_Record_Type__c ,
                                                                                     UNITY_Template_Parent__c
                                                                              FROM UNITY_Template_Configuration__c 
                                                                              WHERE Name IN :templatesNames  ]);
            
            // group template by parent templates
            for(id templateId :templates.keySet()){ 
                
                UNITY_Template_Configuration__c onTemplate = templates.get(templateId);
                
                if (onTemplate.UNITY_Template_Parent__c != null ){
                    
                    if(templateTree.get(onTemplate.UNITY_Template_Parent__c) == null){
                        
                        templateTree.put( onTemplate.UNITY_Template_Parent__c , new list<SObject>() );
                        
                    }
                    
                    templateTree.get(onTemplate.UNITY_Template_Parent__c).add( onTemplate );
                    
                    if(onTemplate.UNITY_Part_Lookup__c != null){
                        productsIds.add(onTemplate.UNITY_Part_Lookup__c);
                    }
                    
                }

            }
            
            Map< id , PricebookEntry > aux_productPriceEntry = new Map< id , PricebookEntry >([SELECT id,  Product2Id, UnitPrice,Pricebook2Id   FROM PricebookEntry WHERE (Product2Id IN : productsIds) ]);
            
            // group by price book
            
            for(PricebookEntry onPriceBookentry :aux_productPriceEntry.values()){
                
                if( priceBook_groups.get(onPriceBookentry.Pricebook2Id) == null ){
                     priceBook_groups.put(onPriceBookentry.Pricebook2Id, new Map<id, PricebookEntry>());
                }
                
                priceBook_groups.get(onPriceBookentry.Pricebook2Id).put(onPriceBookentry.Product2Id ,onPriceBookentry);
                
            }

            
            // get the templates label 2 to create 
            for( id sobjectId :recordTemplateMap.KeySet() ){
                
                id parentTId = recordTemplateMap.get(sobjectId);
                
                list<UNITY_Template_Configuration__c> childrenT = templateTree.get(parentTId);
                
                for(UNITY_Template_Configuration__c childT :childrenT){
                    
                    SObject so = updateLists( childT, sobjectId );
                    
                    if(so != null){
                          
                                                  
                          if(template_SObjects.get(childT.id) == null){
                              template_SObjects.put(childT.id, new list<SObject>());
                          }
                            
                          if(aux_orderBySobjectType.get(so.getSObjectType()) == null){
                              aux_orderBySobjectType.put(so.getSObjectType() , new list<SObject>());
                          }
                                    
                          aux_orderBySobjectType.get(so.getSObjectType()).add(so);
                                
                          template_SObjects.get(childT.id).add(so);
                                
                     }
                    
                }
                
            }
            
            for(Schema.SObjectType SObjectType :aux_orderBySobjectType.keySet()){
                
                toInsert.addAll(aux_orderBySobjectType.get(SObjectType));
                
            }
            
                        
            // insert records while we have to 
            while(toInsert.size()>0){
               
                system.debug('###% toInsert');
                system.debug(toInsert);
                insert toInsert;
                // reset the list to insert 
                toInsert = new list< SObject >();
                
                Map<id , list<SObject> > aux_template_SObjects = new  Map<id , list<SObject> >();
                
                aux_orderBySobjectType = new  Map<Schema.SObjectType , list<SObject> >();
                
                // iter by the template id
                for(id parentTId :template_SObjects.KeySet()){
                    // iter by the sobjects created by the template record
                    for(SObject onParentSObject :template_SObjects.get(parentTId)){
                        // check if the template has children
                        if(templateTree.get(parentTId) != null){
                            // iter for all the child templates 
                            for(UNITY_Template_Configuration__c childT :templateTree.get(parentTId)){
                                
                                SObject childSObject = updateLists( childT, onParentSObject.Id );
                        
                                if(childSObject != null){
                                    
                                    if(aux_template_SObjects.get(childT.id) == null){
                                        aux_template_SObjects.put(childT.id, new list<SObject>());
                                    }
                                    
                                    if(aux_orderBySobjectType.get(childSObject.getSObjectType()) == null){
                                        aux_orderBySobjectType.put(childSObject.getSObjectType() , new list<SObject>());
                                    }
                                    
                                    aux_orderBySobjectType.get(childSObject.getSObjectType()).add(childSObject);
                                    aux_template_SObjects.get(childT.id).add(childSObject);
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
                for(Schema.SObjectType SObjectType :aux_orderBySobjectType.keySet()){
                    toInsert.addAll(aux_orderBySobjectType.get(SObjectType));
                }
                
                template_SObjects = aux_template_SObjects;
                
            }
            
        }
*/        
        /*
         *   @method  :   updateLists
         *   @param 1 :   One record of UNITY_Template_Configuration__c from where we create a SObject 
         *   @param 2 :   Id of the parent record
         *   @date:       11/23/2015              
         */
/*
        private SObject updateLists(UNITY_Template_Configuration__c onTemplate ,  id lookupId){
               
            SObject obj   = null;
            
            // check if exist SObjet type in the fglobal describe map 
            if(globalDescribe.get(onTemplate.UNITY_Target_Object__c) != null){
                        
                 Schema.SObjectType  objectType  = globalDescribe.get(onTemplate.UNITY_Target_Object__c);    
                      
                // Instance the top parent record to create 
                obj = objectType.newSObject();
                
                if(UNITY_Utils.getRecordType(globalDescribe.get(onTemplate.UNITY_Target_Object__c), onTemplate.UNITY_Target_Object_Record_Type__c ) != null){
                    obj.put('RecordTypeId', UNITY_Utils.getRecordType(globalDescribe.get(onTemplate.UNITY_Target_Object__c), onTemplate.UNITY_Target_Object_Record_Type__c ) );
                }
                
                
                if( (onTemplate.UNITY_Node_Type__c != null) && (onTemplate.UNITY_Node_Value__c != null) ){
                    obj.put(onTemplate.UNITY_Node_Type__c, onTemplate.UNITY_Node_Value__c);
                }
                
                if(lookupId != null){
                    
                    if( lookupId.getSobjectType().getDescribe().getName() == 'Case'){
                        
                        if(onTemplate.UNITY_Target_Object__c == 'Case'){
                            obj.put('ParentId', lookupId);    
                        }else if(onTemplate.UNITY_Target_Object__c == 'WorkOrder'){
                            obj.put('CaseId', lookupId);    
                        }else if(onTemplate.UNITY_Target_Object__c == 'Task'){
                            obj.put('WhatId', lookupId);    
                        }
                        
                    }else if( lookupId.getSobjectType().getDescribe().getName() == 'Order'){
                        
                        if(onTemplate.UNITY_Target_Object__c == 'OrderItem'){
                            
                            obj.put('OrderId', lookupId);
                            obj.put('Quantity', 1);
                            
                                
                            // check if the assigned product has a priceBookEntry for the Order priceBook related 
                            if( (onTemplate.UNITY_Part_Lookup__c != null) && 
                                (order_pricebook.get(lookupId) != null) && 
                                (priceBook_groups.get(order_pricebook.get(lookupId)) != null) && 
                                (priceBook_groups.get(order_pricebook.get(lookupId)).get(onTemplate.UNITY_Part_Lookup__c) != null) ){
                               
                               obj.put('UnitPrice', priceBook_groups.get(order_pricebook.get(lookupId)).get(onTemplate.UNITY_Part_Lookup__c).UnitPrice );     
                               obj.put('PricebookEntryId', priceBook_groups.get(order_pricebook.get(lookupId)).get(onTemplate.UNITY_Part_Lookup__c).id );     
                             
                            // check if the Order does not have a PriceBook related 
                            }else if( (onTemplate.UNITY_Part_Lookup__c != null) && (order_pricebook.get(lookupId) == null) ){
                                
                                obj.put('UnitPrice', priceBook_groups.get(standardPriceBookId).get(onTemplate.UNITY_Part_Lookup__c).UnitPrice );     
                                obj.put('PricebookEntryId', priceBook_groups.get(standardPriceBookId).get(onTemplate.UNITY_Part_Lookup__c).id );     

                            // throw an error if they try to relate the OrderItem to a product that the parent Order related PriceBook has not a priceBookEntry for the product  
                            }else if( (onTemplate.UNITY_Part_Lookup__c != null) && (order_pricebook.get(lookupId) != null) && (priceBook_groups.get(order_pricebook.get(lookupId))  == null)  ){
                                 
                                throw new TemplateException('Error : The Order Product that you want to create isn\'t included in to the Order PriceBook related.');
                                
                            }
                            
                        }
                        
                    }else if(lookupId.getSobjectType() == UNITY_Proposal__c.getSobjectType()){
                         
                        if(onTemplate.UNITY_Target_Object__c == 'UNITY_Proposal_Line_Item__c'){
                             obj.put( 'UNITY_Quantity__c', 1 );
                             obj.put( 'UNITY_Product__c' , onTemplate.UNITY_Part_Lookup__c );
                             obj.put( 'UNITY_Proposal__c', lookupId );
                        }
                        
                    }else{
                        obj.put(lookupId.getSobjectType().getDescribe().getName(), lookupId);    
                    }
                    
                }
                        
             }
            
             return obj;
        }
        
        private class TemplateException extends Exception {}

}

*/