

/*
 * REQUIRED :   JQuery, UNITY_Utils.js
 * 
 */
(function(w) {

    var availableVendorsWOOverrideVal = false;

    w.UNITY = (typeof UNITY == "undefined") ? w.UNITY = {} : w.UNITY;

    w.UNITY.availableVendorsWO = (typeof w.UNITY.availableVendorsWO == "undefined") ? availableVendorsWOOverrideVal = true : w.UNITY.availableVendorsWO;


    if (availableVendorsWOOverrideVal && (document.getElementById('UNITYAvailableVendorsWO') != null)) {

        w.UNITY.availableVendorsWO = (function() {

            var factory = {};
			
            factory.CONSTANTS = {
                TIMEOUT_AFTER_ASSIGN : 3000,
                SUB_TAB_ID : null
            };
            
            factory.cache = {};
            
            factory.finish = function() {
                $('#unity-loading-container').trigger('unity-end-load');
            }
            
            factory.finishReviewPO = function() {
               var $elem = $('#'+factory.cache.reviewPOvendorId);
               if((typeof $elem.data('po') == 'string') && ($elem.data('po').length>=15))UNITY.utils.openURL('/'+$elem.data('po'), '', true); 
            }
            
            factory.finishGetWarning = function() {
               var $elem = $('#warningMessageDiv');
               if($elem.text().length>0)
                   UNITY.utils.openModal(
                            			'.unity-modal-container',
                                        'Confirm Assignment', 
                                        '<p>Vendor Assignment Warning: '+$elem.text()+'. If you want to proceed please click "Confirm" button. </p>',
                                        {vendorId:factory.cache.vendorToAssignId}, 
                                        function(modal){ assignVendorJS(); UNITY.utils.closeModal('.unity-modal-container');} , 
                                        function(){
                                             UNITY.utils.closeModal('.unity-modal-container');
                                             resetAssignmentCol(); });
                else assignVendorJS();
                
                $elem.empty();
                factory.cache.vendorToAssignId = null;
            }
            
            factory.finishAssignment = function() {

                var $elem = $('#isVendorAssigned');
                var isVendorAssigned = $elem.data('isvendorassigned');
                
                if( (typeof  sforce == 'object') && sforce.console.isInConsole()){
                    setTimeout(function(){
                        var primatyTabId  = UNITY.utils.$_GET('primatyTabId');
                        var woSubTabId    = UNITY.utils.$_GET('subTabId');
                        var woName        = UNITY.utils.$_GET('woname');
                        
                        if(isVendorAssigned && (typeof primatyTabId =='string')&& (primatyTabId.length > 0)){
                            sforce.console.refreshSubtabById(woSubTabId, true, function(a){
                                //console.log(a);
                                sforce.console.closeTab(UNITY.availableVendorsWO.CONSTANTS.SUB_TAB_ID);
                            }, true);
                        }else{
                            resetAssignmentCol();
                        }
                    }, factory.CONSTANTS.TIMEOUT_AFTER_ASSIGN);
                }
            }
            
            factory.assignedCallback = function() {
                
                UNITY.utils.handleMSG('UNITYAvailableVendorsWO','slds-theme--success','Vendor Assigned.');
                $('.unity-assign-btn').remove();
                
                if( (typeof  sforce == 'object') && sforce.console.isInConsole()){
                    window.top.location='/console'; 
                }
                
            }
            
            var resetAssignmentCol = function() {
                $('.unity-assign-btn').prop('disabled','');
                $('.unity-assign-btn').parent().show();
                $('.unity-assign-vendor-td').find('.unity-loading-icon').remove();
            }
            
            var activeSpinner = function(elem, parentElem) {
                var $elem   = $(elem);
                var $parent = $elem.parents(parentElem).first();
                //console.log($parent);
                $parent.children().hide();
				$elem.trigger('unity-start-working',$parent);
            }

            var getTabId = function() {
                if(sforce.console.isInConsole()){
                    sforce.console.getFocusedSubtabId(function(result) {
                          var subTabId = result.id;
                          factory.CONSTANTS.SUB_TAB_ID = subTabId;
                     });
                }
            }
            
            var addEvents = function() {
				
                $(document).on('click', '.unity-link-to-vendor', function() {
                    var $elem = $(this);
                    var $parentRow = $elem.parents('tr').first();
                    var vendorId = $parentRow.data('id');
                    UNITY.utils.openURL('/'+vendorId, '', true);
                });
                
                $(document).on('click', '.unity-review-po', function() {
                    console.debug('<>');
                    var $elem = $(this);
                    var $parentRow = $elem.parents('tr').first();
                    var vendorId = $parentRow.data('id');
                    var poId = $parentRow.data('po');
                    factory.cache.reviewPOvendorId = vendorId;
                    
                    if((typeof  poId == 'string') && (poId.length >= 15))
                        UNITY.utils.openURL('/'+poId, '', true);
                    else{
                        activeSpinner(this,'td');
                        reviewPOJS(vendorId);
                    }
                       
                });
                
                
                $(document).on('click', '#unityApplyFilter', function() {
                    
                    var locationKey  = $('#unityLocationKeyFilter').val();
                    var requestType  = $('#unityRecordTypeFilter').val();
                    var trade        = $('#unityTradeFilter').val();
                    var vandorStatus = $('#unityAccountVendorStatusFilter').val();
                    
                    $('.unity-table tbody tr').hide();
                    $('.unity-no-vendors-available').remove();
					
                    $('#unity-loading-container').trigger('unity-start-load');
                    
                    unity_applyFilterJS(locationKey,requestType,trade,vandorStatus);
                    
                });
                
                $(document).on('click', '.unity-edit-preference', function() {

                    var $elem = $(this);
                    var $parentRow = $elem.parents('tr').first();
                    var vendorId = $parentRow.data('id');
                    UNITY.utils.openURL('/apex/UNITY_customerPreferenceOnVendor?customerId=' + UNITY.utils.$_GET('id') + '&vendorId=' + vendorId, 'Assign Vendor', true);

                });
                
                 $(document).on('click','#unityShowAllVendors',function(){
               
                   var $elem  = $(this);
                   $elem.text('Refresh');
                   $('.unity-table tbody tr').hide();
                   $('#unity-loading-container').trigger('unity-start-load');
                   showAllVendorsJS();
               });
                
                $(document).on('click','.unity-assign-btn',function(){
                    var $elem = $(this);
                 
                    var $row = $elem.parents('tr').first();
                    factory.cache.vendorToAssignId = $row.data('id');
                    unity_getVendorAssignmentWarningJS($row.data('id'));
                    
                    activeSpinner(this, 'td');
                    $('.unity-assign-btn').prop('disabled','disabled');
                });
            }
            
            factory.init = function() {
                addEvents();
                getTabId();
            }

            return factory;
        }());
    }

}(window));

$(document).ready(function() {

    var options = {
        containerIdLoadingIMG: 'unity-loading-container',
        entities: ['WorkOrder','UNITY_Vendor_Preference__c']
    };

    UNITY.utils.init(options);
    svg4everybody();
    UNITY.availableVendorsWO.init();

});
