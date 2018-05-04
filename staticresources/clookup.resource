(function(){
    
    var $j = jQuery.noConflict();
    
    String.prototype.replaceAll = function(search, replacement){
        var target = this;
        return target.replace(new RegExp(search, 'g'), replacement);
    };
    
    console.log('in function...');
    window.cLOOKUP = (typeof window.cLOOKUP == "undefined") ? {} : window.cLOOKUP;
    
    if(typeof window.cLOOKUP.factory == "undefined"){
        
        var factory = {};
        
        factory.lookupArr = [];
        factory.showResult = function(field){
            field.resultWrapper.show();
        }
        factory.hideResult = function(field){
            field.resultWrapper.hide();
        }
        factory.setResult = function(field,result){
            field.resultDiv.html(result);
        }
        factory.clearResult = function(field){
            field.resultDiv.html('<table class="search-result"><tr><td>No Results to Display</td></tr></table>');
        }
        factory.showLoading = function(field){
            field.loading.show();
        }
        factory.hideLoading = function(field){
            field.loading.hide();
        }
        factory.doSearch = function doSearch(f,s){
            var args = [];
            args.push(f.config.obj);
            args.push(f.config.returning);
            args.push(f.config.where);
            args.push(f.config.like);
            console.log('in doSearch(s)');
            factory.showLoading(f);
            factory.showResult(f);
            CustomLookupController.doSearch(s,args,function(result,event){
                var sres = '';
                if(event.status){
                    var labelStr = f.config.labels;
                    labelStr = labelStr.replaceAll('\'','"');
                    console.log(labelStr);
                    labels = JSON.parse(labelStr);
                    var labelsLength = 0;
                    if(result != null && result.length > 0){
                        sres = '<table class="search-result"><tr>'
                        for (var prop in labels) {
                            if (labels.hasOwnProperty(prop)) {
                                sres += '<th>'+labels[prop]+'</th>';
                                labelsLength++;
                            }
                        }
                        sres += '</tr>';
                        var limit = result.length > 200 ? 200 : result.length;
                        labelsLength = (labelsLength != 0) ? labelsLength : 1;
                        if(limit < result.length){
                            sres += '<tr><td colspan="'+labelsLength+'" style="text-align:center;font-weight:bold;background-color:#fff4b3">The search resturned more items than shown. Please refine your search. Returned Records: '+result.length+'</td></tr>';
                        }else{
                            sres += '<tr><td colspan="'+labelsLength+'" style="text-align:center;font-weight:bold;">Returned Records: '+result.length+'</td></tr>';
                        }
                        for(var i = 0; i < limit; i++){
                            sres += '<tr class="elem" data-lineid="'+result[i].Id+'" data-fid="'+f.config.fid+'" data-hfid="'+f.config.hfid+'">';
                            for(var prop in labels){
                                if(labels.hasOwnProperty(prop)){
                                    var myVal = result[i][prop];
                                    if(myVal == null && typeof myVal == 'undefined'){
                                        myVal = '';
                                    }else{
                                        var d = moment(myVal);
                                        if(d != null && d.isValid()){
                                            myVal = d.format('M/D/YYYY'); 	   
                                        }else{
                                            myVal = (myVal == false)?'No':((myVal == true)?'Yes':myVal);
                                        }
                                    }
                                    sres += '<td>'+myVal+'</td>';
                                }
                            }
                            sres += '</tr>';     
                        }
                        result = null;
                        factory.setResult(f,sres);
                        factory.showResult(f);
                        factory.hideLoading(f);
                    }else{
                        factory.clearResult(f);
                        factory.hideLoading(f);
                    }
                }else{
                    factory.clearResult(f);
                    factory.hideLoading(f);
                }
            },{escape:false});
        }
        
        cLOOKUP.factory = factory;
    }
    
    if(typeof window.Field == "undefined"){
        console.log('no w.Field defined... defining...');
        window.Field = function Field(){
            var thisField = this;
            var CONSTANT = {
                RW_CLASS:'.result-wrapper-',
                RD_CLASS:'.result-div-',
                LOADING_CLASS:'.loading-'
            };
            this.config = {
                fid:'',
                hfid:'',
                obj:'',
                returning:'',
                where:'',
                like:'',
                labels:""
            };
            this.resultWrapper;
            this.resultDiv;
            this.loading;
            this.field;
            this.setField = function(){
                if(thisField.field == null)
                	thisField.field = $j('[data-id="'+thisField.config.fid+'"]');
                thisField.field.val(thisField.values.selVal);
                thisField.field.attr("data-id",thisField.values.selId);
            }
            this.hfield;
            this.setHfield = function(){
                if(thisField.hfield == null)
                	thisField.hfield = $j('[data-id="'+thisField.config.hfid+'"]');
                thisField.hfield.val(thisField.values.selId);
                thisField.hfield.trigger("change");
            }
            this.typingTimer;
            this.doneTypingInterval = 1000;
            this.values = {
                selVal:'',
                selId:'',
                isChanged:false
            };
            this.init = function(){
                thisField.resultWrapper =  $j(CONSTANT.RW_CLASS+thisField.config.fid);
                thisField.resultDiv = $j(CONSTANT.RD_CLASS+thisField.config.fid);
                thisField.loading = $j(CONSTANT.LOADING_CLASS+thisField.config.fid);
                
                thisField.field = $j('#'+thisField.config.fid);
                thisField.field.val(thisField.values.selVal);
                thisField.field.attr('data-id',thisField.values.selId);
                
                thisField.setHfield();
                
                thisField.field.keypress(function(e){
                    var keynum = 0;
                    if(window.event){
                        keynum = window.event.keyCode;
                    }else if (e.which){
                        keynum = e.which;
                    }
                    // Here we check whether the Enter button was pressed
                    if(keynum == 13){
                        e.preventDefault();
                    }
                    var thisNode = $j(this);
                    if(thisField.typingTimer != null)
                        clearTimeout(thisField.typingTimer);
                    thisField.typingTimer = setTimeout(function(){
                        var val = thisNode.val().trim();
                        console.log('done typing...');
                        console.log('the size of my search string is: ' + val.length);
                        if(val.length >= 3){
                            console.log('the size of my search string is 3 characters long or more. doing search now...');
                            window.cLOOKUP.factory.doSearch(thisField,val);
                        }
                    }, thisField.doneTypingInterval);
                });
                thisField.field.change(function(){
                    var val = $j(this).val();
                    if(val == null || val == ''){
                        thisField.field.trigger("setValue",['','',true]);
                    }else{
                        thisField.setField();
                    }
                });
                thisField.field.on("setValue",function(event,val,id,changed){
                    thisField.values.selVal = val;
                    thisField.values.selId = id;
                    thisField.values.isChanged = changed;
                    thisField.setField();
                    if(changed){
                        thisField.setHfield();
                    }
                });
            }
            this.runOnChange;
        }
        console.log('window.Field has been defined... ready to instantiate.');
    }
    
    $j(document).click(function(e){
        e.stopPropagation();
        for(var i = 0; i < window.cLOOKUP.factory.lookupArr.length; i++){
            window.cLOOKUP.factory.hideResult(window.cLOOKUP.factory.lookupArr[i]);
            window.cLOOKUP.factory.clearResult(window.cLOOKUP.factory.lookupArr[i]);
        }
    });
    
    $j(document).on("click",".elem",function(){
        var id = $j(this).attr("data-lineid");
        var value = $j(this).find("td:eq(0)").text();
        var fid = $j(this).attr("data-fid");
        var hfid = $j(this).attr("data-hfid");
        
        var theField = $j('#'+fid);
        theField.trigger("setValue",[value,id,true]);
        
        console.log('Selected a value...: id: '+id+', value: '+value)
    });
    
})();