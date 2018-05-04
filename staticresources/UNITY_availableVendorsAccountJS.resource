


(function(w) {

    var availableVendorsAtLocationOverrideVal = false;

    w.UNITY = (typeof UNITY == "undefined") ? w.UNITY = {} : w.UNITY;

    w.UNITY.availableVendorsAtLocation = (typeof w.UNITY.availableVendorsAccount == "undefined") ? availableVendorsAtLocationOverrideVal = true : w.UNITY.availableVendorsAtLocation;


    if (availableVendorsAtLocationOverrideVal && (document.getElementById('UNITYAvailableVendorsAccount') != null)) {

        w.UNITY.availableVendorsAtLocation = (function() {

            var factory = {};
			
            var activateFilters = function (){
                
                if($('.unity-no-vendors-available').length == 0){
                    
                    $('.unity-filter').removeAttr('disabled');
                }
            }
            
            factory.finish = function() {
                
                var $elem = $(this);
                
                $('#unity-loading-container').trigger('unity-end-load');
            }

            var addEvents = function() {
				
               
                $(document).on('click', '.unity-link-to-vendor', function() {
                    
                    var $elem = $(this);

                    var $parentRow = $elem.parents('tr').first();

                    var vendorId = $parentRow.data('id');
                    
                    UNITY.utils.openURL('/'+vendorId, '', true);
                });

                $(document).on('change', '#unityTradeFilter', function() {

                    var $elem = $(this);

                    $('.unity-table tbody tr').hide();

                    $('#unity-loading-container').trigger('unity-start-load');

                    fiterByTradeJS($elem.val());

                });

                $(document).on('change', '#unityRecordTypeFilter', function() {

                    var $elem = $(this);

                    $('.unity-table tbody tr').hide();

                    $('#unity-loading-container').trigger('unity-start-load');

                    fiterByRecordTypeJS($elem.val());

                });

                $(document).on('click', '.unity-edit-preference', function() {

                    var $elem = $(this);

                    var $parentRow = $elem.parents('tr').first();

                    var vendorId = $parentRow.data('id');

                    //UNITY.utils.openURL('/apex/UNITY_customerPreferenceOnVendor?customerId=' + UNITY.utils.$_GET('id') + '&vendorId=' + vendorId, 'Customer Preference', true);
                    UNITY.utils.openURL('/apex/UNITY_VendorRanking?customerId=' + UNITY.utils.$_GET('id') + '&vendorId=' + vendorId + '&tradeId='+$('#unityTradeFilter').val() , 'Customer Preference', true);

                });


            }
			

            factory.init = function() {

                addEvents();
                activateFilters();

            }

            return factory;

        }());

    }

}(window));

$(document).ready(function() {

    var options = {
        containerIdLoadingIMG: 'unity-loading-container'
    };

    UNITY.utils.init(options);
    svg4everybody();
    UNITY.availableVendorsAtLocation.init();

});
