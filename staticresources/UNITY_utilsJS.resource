"use strict";


/*
 *  REQUIRED : JQuery
 *  NOTE :     generate a help object handle common events and issues with visualforce pages
 *             Object generated UNITY.utils 
 *             UNITY.utils attr : 
 *    									- CONSTANTS ( object )
 *    									- $_GET     ( Function )
  *    									- closeModal( Function )
 *   									- openModal ( Function )
 *    									- appendSVG ( Function )
 *    									- openURL   ( Function )
 * 										- addSVGIcons ( Function )
 * 										- addEvents   ( Function )
 *   									- getDescribeObjects ( Function )
 *
 * 
 */
(function(w){
    
    w.UNITY = (typeof w.UNITY == "undefined") ? {} : w.UNITY ;
    
    if(typeof w.UNITY.utils != "undefined") return undefined;
    
    w.UNITY.utils = (function(){
        
        var factory = {};
        
        factory.describeObject = {};
        
        factory.CONSTANTS = (function(){
            
            var todayTime = Date.now();
            
            var factory = {};
            
            factory.ROOT_STATIC_RESOURCE = '/resource/'+todayTime+'/';
            
            factory.PATH_LDS = 'UNITY_LightningDesignSystemV12';
            
            factory.LOADING_GIF = '<img  class="unity-loading-icon" src="/resource/'+todayTime+'/UNITY_loadingGif" higth="20" width="20"/>'; 
            
            factory.SVG_UTILITY_ICON_HTML = '<svg aria-hidden="true" class="slds-icon">'+
                                                '<use xlink:href=""></use>'+
                                            '</svg>'; 
            
            factory.POPOVER_HTML = 			'<div class="slds-popover slds-nubbin--top" role="dialog">'+
                                              '<div class="slds-popover__header"></div>'+
                                              '<div class="slds-popover__body"></div>'+
                                            '</div>';
            
            factory.CHEVRONDOWN_HTML = '<svg aria-hidden="true" class="slds-icon">'+
                                         '<use xlink:href="'+factory.ROOT_STATIC_RESOURCE+factory.PATH_LDS+'/assets/icons/utility-sprite/svg/symbols.svg#chevrondown"></use>'+
                                       '</svg>'; 
            
            factory.CHEVRONUP_HTML =  '<svg aria-hidden="true" class="slds-icon">'+
                                         '<use xlink:href="'+factory.ROOT_STATIC_RESOURCE+factory.PATH_LDS+'/assets/icons/utility-sprite/svg/symbols.svg#chevronup"></use>'+
                                       '</svg>'; 
            
            factory.NOTIFICATION =   '<div class="slds-notify-container">'+
                                        '<div id="notificationA" class=" slds-notify slds-notify--alert slds-theme--inverse-text slds-theme--alert-texture" role="alert">'+
                                            '<span class="slds-assistive-text">Error</span>'+
                                            '<button type="button" class="closeNotification slds-button slds-button--icon-inverse slds-notify__close">'+
                                                '<svg aria-hidden="true" class="slds-button__icon">'+
                                                '<use xlink:href="'+factory.ROOT_STATIC_RESOURCE+factory.PATH_LDS+'/assets/icons/action-sprite/svg/symbols.svg#close"></use>'+
                                                '</svg>'+
                                                '<span class="slds-assistive-text">Close</span>'+
                                            '</button>'+
                                            '<h2 id="messagesText">Base System Alert</h2>'+
                                        '</div>'+
                                    '</div>';
            
            return factory;
            
        })();
        
        /*
         * PARAM  : name URL query variable 
         * RETURN : value of the variable pass in 
         */
        factory.$_GET = function(param) {
                var vars = {};
                window.location.href.replace( 
                    /[?&]+([^=&]+)=?([^&]*)?/gi, // regexp
                    function( m, key, value ) { // callback
                        vars[key] = value !== undefined ? value : '';
                    }
                );
            
                if ( param ) {
                    return vars[param] ? vars[param] : null;	
                }
                return vars;
        }
        
        /*
         * PARAM 1 : id of element to append the notification
         * PARAM 2 : style class to apply 
         * PARAM 3 : message 
         */
        factory.handleMSG = function (whereToAppendid,classToApply , msg){

                var $notificationElement = $(UNITY.utils.CONSTANTS.NOTIFICATION);
                $notificationElement.find('#notificationA').addClass(classToApply);
                $notificationElement.find('#messagesText').text(msg);
                $('#'+whereToAppendid).append($notificationElement);
    
        }
        
        factory.removeElement = function (elem){
            $(elem).remove();    
        }
        
        factory.closeModal = function (elem){
            $(elem).hide();
        }
        
        /*
         * PARAM 1 : modale html to use 
         * PARAM 2 : modal title 
         * PARAM 3 : modal body  
         * PARAM 4 : details  
         * PARAM 5 : confirm function  
         * PARAM 6 : cancel  function  
         */
        factory.openModal = function (modal,title,body,data,confirm,cancel){
            
            var $modal = $(modal);
            var modal = {};
            
            $modal.find('.unity-title').empty();
            $modal.find('.unity-body').empty();
            
            if( (data != null)&&(typeof data == "object") ){
                $.extend( modal , data);
            }
            
            if(typeof body == "string" ){
                $modal.find('.unity-title').append(title);
            }
            
            if(typeof body == "string" ){
                $modal.find('.unity-body').append(body);
            }
            
            if(typeof confirm == "function" ){
                 $modal.find('.unity-confirm-btn').on('click',function(){
                    confirm(modal);
                });
            }
            
            if(typeof cancel == "function" ){
                $modal.find('.unity-cancel-btn').on('click',function(){
                    cancel();
                });
            }
           
            $modal.show();
        }
        
        /*
         * PARAM 1 : url to open 
         * PARAM 2 : new tab title 
         * PARAM 3 : open in new window 
         * NOTE  :  this function takes care of the service console context
         */
        factory.openURL = function (url,title, isNewWindow){
               
            if(isNewWindow){
                if ((typeof sforce == 'object' ) && sforce.console.isInConsole()) { 
                    sforce.console.getFocusedPrimaryTabId(function(primatyTab){
                        sforce.console.openSubtab(primatyTab.id, url, true, title, null, function(){}); 
                    }); 
                }else{
                    window.open(url,'_blank'); 
                }
            }else{
                if ((typeof sforce == 'object' )&& sforce.console.isInConsole()) { 
                    sforce.console.getEnclosingPrimaryTabId(function(primatyTab){ 
                        sforce.console.openPrimaryTab(primatyTab.id, url, true, title);
                    });
                }else{
                    window.location = url;
                }
            }
        }
        
        factory.close = function(){
            if ((typeof sforce == 'object' )&& sforce.console.isInConsole()) { 
                sforce.console.getEnclosingTabId(function(result){
                    var tabId = result.id;
                    sforce.console.closeTab(tabId);
                });
            }
        }
        
        factory.refreshSubTabsByPrimaryTabId = function(primaryTabId){
            if ((typeof primaryTabId == 'string' )&& (primaryTabId.length > 0)) { 
                sforce.console.getSubtabIds( primaryTabId, function(result){
                    console.log(result);
                    if(result.success && (result.ids.length>0)){
                        for(var i = 0 ; i < result.ids.length; i++){
                            if(result.ids[i] == primaryTabId) sforce.console.refreshSubtabById(result.ids[i],true);
                            else sforce.console.refreshSubtabById(result.ids[i], false);                             
                        }
                    }
                });
            }else{
                sforce.console.getFocusedPrimaryTabId(function(primatyTab){ 
                     sforce.console.getSubtabIds( primatyTab.id, function(result){
                        console.log(result);
                        if(result.success && (result.ids.length>0)){
                            for(var i = 0 ; i < result.ids.length; i++){
                                sforce.console.refreshSubtabById(result.ids[i], false);                             
                            }
                        }
                	});
                }); 
            }
        }
        
        /*
         * NOTE  :  This function go for each .unity-append-svg element and append within the elemnt the SVG icons
         *           
         */
        factory.addSVGIcons = function (detils ){
            jQuery.extend( UNITY.utils.CONSTANTS , detils );
            
            $('.unity-append-svg').each(function(index, elem){
                
                var $elem =  $(elem);
                var path  = $elem.data('href');
                var classes = $elem.data('class');
                
                var $svg = $(UNITY.utils.CONSTANTS.SVG_UTILITY_ICON_HTML);
                console.log(classes);
               
                
                $svg.find('use').attr('xlink:href',UNITY.utils.CONSTANTS.ROOT_STATIC_RESOURCE+UNITY.utils.CONSTANTS.PATH_LDS+path);
                
                $elem.append($svg);
                
                $svg.attr('class',$svg.attr('class') + ' '+classes);
            });
                 
        }
        
        factory.appendSVG = function (name){
               
            if(typeof name == 'string'){
                
                var nameNormalized = name.toUpperCase()+'_HTML';
                
                if(typeof UNITY.utils.CONSTANTS[nameNormalized] == 'string'){
                    $('.'+name).append(UNITY.utils.CONSTANTS[nameNormalized]);
                }
                 
            } 
                 
        }
        
        /*
         * NOTE  :  remove loading icons 
         *           
         */
        factory.endLoadingProcess = function (elemId){
               
               UNITY.utils.removeElement(elemId);
               
               $('#unity-loading-container').removeClass('unity-loading-active');
               
        }
        
        factory.setupElements = function (details){
            
            var useDetails = true;
            
            if(typeof details == 'undefined') useDetails =false ; 
            
            if( useDetails &&  (typeof details.containerIdLoadingIMG == 'string') && (details.containerIdLoadingIMG != '') ){
            	$('#'+details.containerIdLoadingIMG).hide();
                $('#'+details.containerIdLoadingIMG).append(factory.CONSTANTS.LOADING_GIF);
            }
            
            $('.unity-input').each(function(index, elem){
                
                var $elem = $(elem);
                if($elem.data('disabled')){
                    $elem.prop('disabled',true);
                }
                
            });
        }
        
        factory.addEvents = function (){
            
            var containerIdLoadingIcon = '#'+$('.unity-loading-icon').parent().attr('id');
            
            $(document).on('click','.closeNotification',function(){
                    
                   $('.slds-notify-container').remove();
                    
            });
            
            $(document).on('unity-end-load',containerIdLoadingIcon,function(){
                    
                   $('.unity-loading-icon').parent().hide();
                    
            });
            
            
            
            $(document).on('unity-start-load',containerIdLoadingIcon,function(){
                   
                   $('.unity-loading-icon').parent().show();
                    
            });
            
            $(document).on('unity-start-working',function(event, elem,b,c){
              
                $(elem).append(UNITY.utils.CONSTANTS.LOADING_GIF);
                    
            });
            
            $(document).on('mouseover','.unity-popover',function(){
                  
                var $elem = $(this);
                var $popovers = $elem.find('.slds-popover');
                
                if($elem.data('popover') != ''){
                    if($popovers.length == 0 ){
                      
                      $popovers = $(factory.CONSTANTS.POPOVER_HTML);
                      $popovers.css('position','absolute');
                      $popovers.find('.slds-popover__body').append($elem.data('popover'));
                      //$popovers.hide();
                      $elem.append($popovers);
                      
                    }
                    $popovers.show();  
                }
                
            });
            
            $(document).on('mouseleave','.unity-popover',function(){
                  
                  var $elem = $(this);
                  $elem.find('.slds-popover').hide();  
            });
            factory.activateLinks();
        }
        factory.activateLinks = function(){
        	 $(document).on('click','.unity-link',function(){
                   
                var $elem  = $(this);
                var href   = $elem.data('href');
                var values = href.split('|');
                var url    = '';
                var param  = '';
                url = values[0];
                if(values.length == 2){
                    param = values[1].trim();
                    param = (param == 'true');
                }
                if(url!='')UNITY.utils.openURL(url, '', param);
                 
            });
        
        }
            
        factory.getDescribeObjects = function (details){
            if((typeof details  == 'object' )&& Array.isArray(details.entities ) ){
                for(var i = details.entities.length - 1; i >= 0; i--){
                    if(SObjectModel.hasOwnProperty(details.entities[i])){
                    	var obj = new SObjectModel[details.entities[i]]();
                        obj.describe(function(error, data) {
                            if(error){
                                console.log(error.message);
                            }else{
                                factory.describeObject[data.name] = data;
                                factory.describeObject[data.name].fieldList = data.fields;
                                var list = data.fields;
                                factory.describeObject[data.name].fields = {};
                                for (var i = list.length - 1; i >= 0; i--) {
                                    var field = list[i];
                                    factory.describeObject[data.name].fields[field.name] = field;
                                };
                            }
                        });
                        
                    }else{
                        console.log('### NOT PROPERTY '+details.entities[i]);
                    }    
                }
            }
            
        }
        
        
        factory.init = function (details){
            
            factory.setupElements(details);
            
			factory.addEvents();
            
            factory.getDescribeObjects(details);
            
            factory.addSVGIcons(details);
            
            
        }
        
        return factory;
        
    })();
    
    
    
})(window);