/*
 * @programer : Samuel Astol
 * @date :      12/23/2015
 * @note :      Add a new property call "customerPreferenceOnVendor" to the UNITY namespace
 *              and help to set the customer preferences on a given vendor.
 * @required : Remote Apex PROXY to the controller 
 * @required : Remote Object PROXY to UNITY_Vendor_Preference__c
 * @required : Remote Object PROXY to UNITY_Vendor_Preference_By_Trade__c
 * @required : Jquery 
 */

(function(w){
    
    var customerPreferenceOverrideVal = false;
    
    var controller = {};
    
    if(typeof UNITY_customerPreferenceOnVendorCtrl  == "undefined"){
        console.log('REQUIRED UNITY_customerPreferenceOnVendorCtrl PROXY');
        return undefined;
    }else{
        controller = UNITY_customerPreferenceOnVendorCtrl;
    }
    
    w.UNITY = ( typeof UNITY == "undefined" ) ? w.UNITY = {}  : w.UNITY ;
    
    w.UNITY.customerPreferenceOnVendor = ( typeof w.UNITY.customerPreferenceOnVendor == "undefined" ) ? customerPreferenceOverrideVal = true : w.UNITY.customerPreferenceOnVendor ;
    
    
    if( customerPreferenceOverrideVal && (document.getElementById('UNITYPreferenceContainer') !=  null) ){
        
        w.UNITY.customerPreferenceOnVendor = (function(){
            
            var factory = {};
            var oldVendors = {};
            var newVendors = {};
            var oldTrades  = {};
            var newTrades  = {};
            
            var isTradesPreferenceProcessError  = false;
            
            var addEvents = function (){};
            
            var updateRanking = function ($goUp , $goDown){
                
                var oldRanking = $goUp.data('ranking');
                
                $goUp.data('ranking',$goDown.data('ranking'));
                newVendors[$goUp.data('id')].ranking = $goDown.data('ranking');
                
                $goDown.data('ranking',oldRanking);
                newVendors[$goDown.data('id')].ranking = oldRanking;
				
                //$goUp.find('.unity-ranking').text($goUp.data('ranking') );
                //$goDown.find('.unity-ranking').text($goDown.data('ranking') );
                
            }
            
            var calculateRanking = function (){
                
                $('.unity-vendor-td').each(function(index,elem){
                    
                    var $elem = $(elem);
                    
                    if($elem.data('type') == 'Preferred'){
                        $elem.data('ranking',index+1);
                        if( typeof newVendors[$elem.data('id')] ==  'object'){
                            newVendors[$elem.data('id')].ranking = index+1;
                        }
                    }
                    
                });
                
            }
            
            var captureVendors = function (){
                
                $('.unity-vendor-td').each(function(index , elem){
                    
                    $elem = $(elem);
                    
                    var id      = $elem.data('id');
                    var ranking = $elem.data('ranking');
                    var type    = $elem.data('type');
                    var vpid    = ($elem.data('vpid')=='') ? null : $elem.data('vpid');
                    
                    if(vpid == null){
                        $elem.find('.unity-delete-preferences-btn').attr('disabled','disabled');
                    }else{
                        $elem.find('.unity-delete-preferences-btn').removeAttr('disabled');
                    }
                    
                    oldVendors[id] = {id : id, ranking : ranking, preferenceType : type, preferenceId :vpid}
                    
                    newVendors[id] = {id : id, ranking : ranking, preferenceType : type, preferenceId :vpid}
                    
                });
                
            }
            
            var captureTrades = function (){
                
                $('.unity-trade-checkbox').each(function(index , elem){
                    
                    $elem = $(elem);
                    
                    var id   = $elem.data('id');
                    var tpid = $elem.data('tpid');
                    var isPreferred = false;
                    
                    if(tpid != ''){ 
                        $elem.prop('checked', true);
                        isPreferred = true;
                    }else{
                        tpid = null;
                        $elem.prop('checked', false);
                    }
                    
                    
                    newTrades[id] = {id : id, isPreferred : isPreferred, tradePreferenceId:tpid}
                    
                    oldTrades[id] = {id : id, isPreferred : isPreferred, tradePreferenceId:tpid}
                    
                });
                
            }
            
            factory.context = {};
            
            factory.context.customerId = UNITY.utils.$_GET('customerId');
            factory.context.vendorId   = UNITY.utils.$_GET('vendorId');
            
            factory.getVendor = function (vendorId){
                
                return newVendors[vendorId];
                
            }
            
            factory.getTrade = function (tradeId){
                
                return newTrades[tradeId];
                
            }
            
            factory.addEvents = function (){
                
                $(document).on('click','.unity-move-up',function(){
                    
                    var $elem = $(this);
                    factory.moveUp($elem);
                    
                });
                
                $(document).on('click','.unity-move-down',function(){
                    
                    var $elem = $(this);
                    factory.moveDown($elem);
                    
                });
                
                $(document).on('change','.unity-trade-checkbox',function(){
                    
                    var $elem = $(this);
                    var id = $elem.data('id');
                    var isPreferred = $elem.is(":checked");
                    newTrades[id].isPreferred = isPreferred;
                    
                });
                
                $(document).on('change','.unity-preference-select',function(){
                    
                    var $elem = $(this);
                    var $parentTd = $elem.parents('tr').first();
                    var value = $elem.val();
                    factory.changePreferenceType(value,$parentTd.data('id'));
                    
                });
                
                $(document).on('click','.unity-save-btn',function(){
                    
                    factory.save();
                    
                });
                
                $(document).on('click','.unity-link-to-vendor',function(){
                    
                    var $elem = $(this);

                    var $parentRow = $elem.parents('tr').first();

                    var vendorId = $parentRow.data('id');
                    
                    UNITY.utils.openURL('/'+vendorId, '', true);
                    
                });
                
                /*$('#UNITYPreferenceContainer').on('unity-upsert-vendor-preference',function(){
                       factory.moveDown($elem);
                });*/
                
                $(document).on('click','.unity-delete-preferences-btn',function(){
                    
                    var $elem = $(this);
                    var $row  = $elem.parents('tr').first();
                    
                    
                    factory.deletePreferencesOnVendor($row.data('id'),$row.data('vpid'));
                    
                    
                });
                
            }
            
            factory.getVedorsPreferenceToUpsert =  function(){
            	
                var vendorPreferenceToUpsert = [];
                
                for(var id in newVendors){
                    if((newVendors[id].ranking != oldVendors[id].ranking) || (newVendors[id].preferenceId == null) || (newVendors[id].preferenceType != oldVendors[id].preferenceType)){
                        vendorPreferenceToUpsert.push(newVendors[id]);
                        if(newVendors[id].preferenceType == 'DO NOT USE') newVendors[id].ranking= 0;
                    }
                }
                
                return vendorPreferenceToUpsert;
                
            }
            
            factory.getTredesPreferenceToDelete =  function(isUpdateDOM){
            	
                var tradePreferenceToDelete = [];
                
                for(var id in newTrades){
                    if(newTrades[id].isPreferred != oldTrades[id].isPreferred){
                        
                        if(!newTrades[id].isPreferred && (newTrades[id].tradePreferenceId != null)){
                            tradePreferenceToDelete.push(newTrades[id].tradePreferenceId);
                        }
                        
                    }
                }
                
                return tradePreferenceToDelete;
                
            }
            
            factory.getTredesPreferenceToCreate =  function(){
            	
                var tradePreferenceToCreate = [];
                
                for(var id in newTrades){
                    if(newTrades[id].isPreferred != oldTrades[id].isPreferred){
                        
                        if(newTrades[id].isPreferred && (newTrades[id].tradePreferenceId == null)){
                            tradePreferenceToCreate.push(newTrades[id].id);
                        }
                        
                    }
                }
                
                return tradePreferenceToCreate;
                
            }
            
            factory.save =  function(){
                
                if((factory.context.vendorId != null)&&(factory.context.customerId != null)){
                    
                    calculateRanking();
                    
                    var vendorPreferenceToUpsert = factory.getVedorsPreferenceToUpsert();
                    var tradePreferenceToDelete  = [];
                    var tradePreferenceToCreate  = [];
                    
                    var $vendor =  $('.unity-editing-vendor').first();
                    var vendor  =  newVendors[$vendor.data('id')];
                    
                    if(vendorPreferenceToUpsert.length>0){
                        
                        factory.upsertVendorsPreference(vendorPreferenceToUpsert);
                        
                    }else {
                        
                        var tradePreferenceToDelete  = factory.getTredesPreferenceToDelete();
                        
                        factory.deleteTradePreference(tradePreferenceToDelete);
                        
                    }
                
               }
                
            }
            
            factory.deleteTradePreference = function (tradePreferenceToDelete){
                
                 if( (tradePreferenceToDelete.length >0) ){
                     
                        var tp_aux = new SObjectModel.VendorPreferenceByTrade();
                     
                        tp_aux.del(tradePreferenceToDelete,function(error,result){
                            if(error){
                                UNITY.utils.handleMSG('UNITYPreferenceContainer','slds-theme--error',error.message );
                            }else{
                                
                                $('.unity-trade-checkbox').each(function(index , elem){
                    
                                    $elem = $(elem);
                                    
                                    if(!$elem.prop('checked')){ 
                                        $elem.data('tpid','');
                                    }
                                    
                                });
                                
                                
                                captureTrades();
                                
                                var tradePreferenceToCreate  = factory.getTredesPreferenceToCreate();
                                
                                if(tradePreferenceToCreate.length >0)factory.createTredePreferences(tradePreferenceToCreate);
                                else UNITY.utils.handleMSG('UNITYPreferenceContainer','slds-theme--success','Customer Preference By Trade Updated.'); 
                            }
                        });
                    
                 }else{
                     var tradePreferenceToCreate  = factory.getTredesPreferenceToCreate();
                     factory.createTredePreferences(tradePreferenceToCreate);
                 }
            }
             
            factory.upsertVendorsPreference = function (vendorPreferenceToUpsert){
                
                controller.upsertVendorPreference(vendorPreferenceToUpsert, 
                                                    factory.context.customerId,
                                                    factory.context.vendorId,
                        // tpid = trade preference id 
                        function(vpid ,info ){
                            
                            if(info.status && (vpid!=null)){
                                
                                $('#'+factory.context.vendorId).data('vpid',vpid);
                                
                                if(newVendors[factory.context.vendorId].preferenceType == 'DO NOT USE'){
                                    $('#'+factory.context.vendorId).find('td').last().empty();
                                    $('#'+factory.context.vendorId+' .unity-preference').text(newVendors[factory.context.vendorId].preferenceType);
                                    $('.unity-preference-table tbody').append($('#'+factory.context.vendorId));
                                    $('.unity-save-btn').remove();
                                }
                                
                                captureVendors();
                                
                                var tradePreferenceToDelete  = factory.getTredesPreferenceToDelete();
                                
                                factory.deleteTradePreference(tradePreferenceToDelete);
                                
                            }else if(!info.status){
                                UNITY.utils.handleMSG('UNITYPreferenceContainer','slds-theme--error',info.message); 
                            }else{
                                UNITY.utils.handleMSG('UNITYPreferenceContainer','slds-theme--error','Not returned related Vendor Preference Id. Contact yout Admin.'); 
                            }
                            
                    });
                
            }
            
            factory.deletePreferencesOnVendor = function (vendorId,vendorP){
                
                console.log('###--> '+vendorId,factory.context.customerId,vendorP);
                
                controller.deletePreferencesOnVendor(factory.context.customerId,
                                                     vendorId, vendorP,
                                                     
                        function(vid,info ){
                            
                            if(info.status){
                                
                                $('#'+vid).remove();
                                
                                UNITY.utils.handleMSG('UNITYPreferenceContainer','slds-theme--success','Customer Preference on Vendor deleted.'); 
                                
                                captureVendors();
                                
                                if(vid == factory.context.vendorId){
                                    
                                    factory.context.vendorId = null;
                                    
                                    $('.unity-save-btn').remove();
                                    
                                    $('.unity-trade-checkbox').each(function(index , elem){
                        
                                        $elem = $(elem);
                                        
                                        $elem.data('tpid','');
                                        
                                    });
                                    
                                    captureTrades();
                                }
                                
                                
                                
                            }else if(!info.status){
                                UNITY.utils.handleMSG('UNITYPreferenceContainer','slds-theme--error',info.message); 
                            }
                            
                    });
                
                
            }
            
            factory.createTredePreferences = function(trades){
                
                if((trades.length >0) && (newVendors[factory.context.vendorId].preferenceId != null)){
                    
                    controller.createTradesPreference(trades, 
                                                        factory.context.customerId,
                                                        factory.context.vendorId, 
                                                        newVendors[factory.context.vendorId].preferenceId,
                        function(data,info){
                            
                            if(info.status){
                               for(var id in data){
                                   
                                   $('#'+id).data('tpid',data[id]);
                               }
                                
                               captureTrades();
                                
                               UNITY.utils.handleMSG('UNITYPreferenceContainer','slds-theme--success','Customer Preference By Trade Updated.'); 
                            }else{
                               UNITY.utils.handleMSG('UNITYPreferenceContainer','slds-theme--error',info.message); 
                            }
                            
                     });
                }else{
                    UNITY.utils.handleMSG('UNITYPreferenceContainer','slds-theme--success','Customer Preference By Trade Updated.'); 
                }
            
            }
            
            
            factory.moveUp =  function($elem){
                
                var $vendorUpRow   = $elem.parents('tr').first();
                var vendorUp       = newVendors[$vendorUpRow.data('id')];
                var $vendorDownRow = $vendorUpRow.prev();
                if($vendorDownRow.length > 0){
                   $vendorUpRow.insertBefore( $vendorDownRow );
                   updateRanking($vendorUpRow,$vendorDownRow);
                }
                
            }
            
            factory.moveDown =  function($elem){
                
                var $vendorDownRow = $elem.parents('tr').first();
                var vendorDown     = newVendors[$vendorDownRow.data('id')];
                var $vendorUpRow = $vendorDownRow.next();
                if($vendorUpRow.data('type')=='Preferred'){
                    $vendorDownRow.insertAfter( $vendorUpRow );
                    updateRanking($vendorUpRow,$vendorDownRow);
                }
                
            }
                     
            factory.init =  function(){
                
		        captureVendors();
                captureTrades();
                UNITY.utils.appendSVG('chevronup');
                UNITY.utils.appendSVG('chevrondown');
                factory.addEvents();
                
            }
            
            factory.changePreferenceType =  function(value, vId){
                
                if( typeof newVendors[vId] == 'object'){
                    newVendors[vId].preferenceType = value;
                }
                
            }
                
            return factory;
    
    	})();
    
        
    }
    
})(window);

$( document ).ready(function(){
    var options = {
        entities: ['UNITY_Vendor_Preference__c','UNITY_Vendor_Preference_By_Trade__c']
    };
    UNITY.utils.init(options);
    svg4everybody();
    UNITY.customerPreferenceOnVendor.init();
    
});


