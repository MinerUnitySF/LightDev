public with sharing class FundingLeaseController extends genesis.ApplicationWizardBaseClass{
    
    public boolean showUploadPanelGrid {set; get;}
    public genesis__Applications__c application {get; set;} 
    public String apiSessionId {get;set;} 
    public boolean invoiceShow  {get;set;} 
    public integer discountRate {get;set;}
    private static Decimal ROUND_FACTOR = Decimal.valueOf('0.01');
     
    public FundingLeaseController (ApexPages.StandardController controller) {
        super(controller);
        this.application = (genesis__Applications__c)controller.getRecord();
         showUploadPanelGrid = false;
         genDocument();
    }
  
    public PageReference genDocument(){
        System.debug('--'+application);
        application = [Select Name
                         , genesis__Payment_Amount__c
                         , genesis__Account__c
                         , genesis__Loan_Amount__c
                         , genesis__Term__c
                         , genesis__Interest_Rate__c 
                         , genesis__Financed_Amount__c
                         , Assigned_To__c 
                         , Discount_Rate__c
                         , genesis__Assigned_To__c,
                         Present_Value__c
                         
                         from genesis__Applications__c 
                         where Id =: application.Id];
        apiSessionId = UserInfo.getSessionID();
        String Url =  '/apex/lawsuitDetail?sessionId=' + apiSessionId+ '&eid='+ this.application.Id;
        system.debug(Url);
        Pagereference pageRef = new Pagereference(Url);
        invoiceShow  = false; 
        return pageRef.setRedirect(true);
    }
    public Decimal generatePV() {
        system.debug('Generating PV');
      /*  if(!validate())
            return null;*/
     Decimal pv =   calculateNetPresentValue(application,0,365,true) ;
     system.debug('pv------------'+pv);  
       Decimal sample;     
       return sample;    
    }  
    private boolean validate(){
        invoiceShow = true;
        return true;
    }
    
    public void saveApp(){
        try{
            update this.application;
        }catch(Exception e){
            createMessage(ApexPages.Severity.ERROR,'Some exception has occured.' + e.getMessage());
            return ;
        }
        createMessage(ApexPages.Severity.CONFIRM,'Application saved');
        
    }
    
    private void createMessage(ApexPages.severity severity, String message) {
        ApexPages.getMessages().clear();
        ApexPages.addmessage(new ApexPages.message(severity, message));
    }
    
    /*
    //@ Below Parameters must be passed
    //@ Rate
    //@ paymentAmount
    //@ term    
    public static Decimal calculatePresentValue(Lending_Calculator__c calc,
                                        Integer accrualBase,
                                        Integer daysInYear,
                                        Boolean intOnlyPmts){
                                        
       Integer accrualBase 
       Integer daysInYear
       Integer intOnlyPmts
       Integer term = 12;
       Decimal yearFactor = getYearFactor(calc);
       Decimal loanAmount = 0;
       Decimal paymentAmount = 1694; //application.genesis__Payment_Amount__c; //calc.payment_amount__c;
       Decimal minFinancedAmount = 0;
       Decimal maxFinancedAmount = 0;
       Decimal loanBalance = 0;
       Decimal loanBalance1  = 0;
       Decimal loanBalance2  = 0;
       Decimal loanBalance3  = 0;           
       Decimal newValue =0;
       //system.debug(logginglevel.error,'start of calculateNetPresentValue Rate '+calc.rate__c);

       Decimal totalReceivable =  paymentAmount * term;
       
       Decimal Rate = (calc.rate__c * yearFactor)/100;
       
       //system.debug(logginglevel.error,'totalReceivable :'+totalReceivable+' Rate: '+Rate);
       
       decimal exponential = (1+Rate).pow(term);
        
       minFinancedAmount =  totalReceivable/(1+ (Rate *term) );
       
       //I just did this because if calc.financed_amount__c is not passed then I need to derive the max Financed amount
       if (calc.financed_amount__c != null){
            maxFinancedAmount = calc.financed_amount__c;
       }else{
            if (Rate >0){
                maxFinancedAmount  = (minFinancedAmount * (Rate/(1-(1/exponential))) * term);
            }else{
                maxFinancedAmount = totalReceivable;
            }   
       }
       
        
       //system.debug(logginglevel.error,'minFinancedAmount: '+minFinancedAmount+' maxFinancedAmount:'+maxFinancedAmount);                      
        calc.Loan_Amount__c = minFinancedAmount;
        
        loanBalance = alloc(calc, calc.payment_amount__c,accrualBase,daysInYear,intOnlyPmts,0);
       
        
        
        //system.debug(logginglevel.error,'Prin Balance after allocation (WithMinfinanced) : '+loanBalance+' Int Rate:'+calc.rate__c+' Loan Amount '+calc.Loan_Amount__c);
        loanBalance1 = loanBalance;                                 
        if ((loanBalance1>0)
             && (loanBalance1<ROUND_FACTOR)){
          newValue = minFinancedAmount;
        }else{
            calc.Loan_Amount__c  =   maxFinancedAmount;
            loanBalance = alloc(calc, calc.payment_amount__c,accrualBase,daysInYear,intOnlyPmts,0);
            //system.debug(logginglevel.error,'Prin Balance after allocation (WithMaxFin) : '+loanBalance+' Int Rate:'+calc.rate__c+' Loan Amount '+calc.Loan_Amount__c);
            loanBalance2 = loanBalance;
            if ((loanBalance2>0) && (loanBalance2<ROUND_FACTOR)){
                newValue = maxFinancedAmount;
            }else{
                if ((loanBalance1.abs()) < (loanBalance2.abs())){
                    newValue = minFinancedAmount;
                    minFinancedAmount = maxFinancedAmount;
                    maxFinancedAmount = newValue;
                    loanBalance3 = loanBalance1;
                    loanBalance1 = loanBalance2;
                    loanBalance2 = loanBalance3;
                }
                Integer count = 1;
                while (count < 100){
                //system.debug(logginglevel.error,'Min Fin Amt : '+ minFinancedAmount + ', Max Fin Amt  : '+maxFinancedAmount + ', Bal Amt1  : '+loanBalance1 + ', Bal Amt2  : '+loanBalance2+' Loan Amount '+calc.Loan_Amount__c);
               
                    if ((loanBalance1 - loanBalance2 ) == 0){
                        newValue = (minFinancedAmount - (loanBalance1 * (minFinancedAmount-maxFinancedAmount)/1));
                    }else{
                        newValue = (minFinancedAmount - (loanBalance1 * (minFinancedAmount-maxFinancedAmount)/(loanBalance1-loanBalance2)));
                    }
                
                    calc.Loan_Amount__c = newValue;
                    //system.debug(logginglevel.error,'Loan_Amount__c :'+calc.Loan_Amount__c);
                    loanBalance = alloc(calc, calc.payment_amount__c,accrualBase,daysInYear,intOnlyPmts,0);
                    //system.debug(logginglevel.error,'Prin Balance after allocation Loop Count'+ count + ' : '+loanBalance + 'calc.Loan_Amount__c: '+calc.Loan_Amount__c);
                    loanBalance3 = loanBalance;                             
                    if ((math.abs(loanBalance3) <= Decimal.valueOf('0.001'))
                       ||((loanBalance1 == loanBalance2) && (loanBalance3 == loanBalance2))
                       ||(count>99)){
                            break;
                     }
                    
              
                    maxFinancedAmount = minFinancedAmount;
                    minFinancedAmount = newValue;
                    loanBalance2 = loanBalance1;
                    loanBalance1 = loanBalance3;      
                    count++;

                  }
                                   
               } 
            }
        calc.Financed_Amount__c = newValue;
        //system.debug(logginglevel.error,'Final NPV :'+newValue);
        return calc.Financed_Amount__c;
    
    
    }
    
    */
    
    public static Decimal calculateNetPresentValue(genesis__Applications__c calc,
                                        Integer accrualBase,
                                        Integer daysInYear,
                                        Boolean intOnlyPmts){
       Decimal yearFactor = 0.0833333333333333;//1/12
       Decimal loanAmount = 0;
       Decimal paymentAmount = calc.genesis__payment_amount__c;
       Decimal minFinancedAmount = 0;
       Decimal maxFinancedAmount = 0;
       Decimal loanBalance = 0;
       Decimal loanBalance1  = 0;
       Decimal loanBalance2  = 0;
       Decimal loanBalance3  = 0;           
       Decimal newValue =0;
       //system.debug(logginglevel.error,'start of calculateNetPresentValue Rate '+calc.genesis__Interest_Rate__c);

       Decimal totalReceivable =  paymentAmount * calc.genesis__term__c;
       system.debug('interestRate----'+calc.genesis__Interest_Rate__c);
       Decimal Rate = (calc.genesis__Interest_Rate__c * yearFactor)/100;
       
       //system.debug(logginglevel.error,'totalReceivable :'+totalReceivable+' Rate: '+Rate);
       
       decimal exponential = (1+Rate).pow((Integer)calc.genesis__term__c);
        
       minFinancedAmount =  totalReceivable/(1+ (Rate *calc.genesis__Term__c) );
       
       //I just did this because if calc.genesis__financed_amount__c is not passed then I need to derive the max Financed amount
       if (calc.genesis__financed_amount__c != null){
            maxFinancedAmount = calc.genesis__financed_amount__c;
       }else{
            if (Rate >0){
                maxFinancedAmount  = (minFinancedAmount * (Rate/(1-(1/exponential))) * calc.genesis__Term__c);
            }else{
                maxFinancedAmount = totalReceivable;
            }   
       }
       
        
       //system.debug(logginglevel.error,'minFinancedAmount: '+minFinancedAmount+' maxFinancedAmount:'+maxFinancedAmount);                      
        calc.genesis__Loan_Amount__c = minFinancedAmount;
        
      //  loanBalance = alloc(calc, calc.genesis__payment_amount__c,        
        //system.debug(logginglevel.error,'Prin Balance after allocation (WithMinfinanced) : '+loanBalance+' Int Rate:'+calc.genesis__Interest_Rate__c+' Loan Amount '+calc.genesis__Loan_Amount__c);
      //  loanBalance1 = loanBalance;                                 
       // if ((loanBalance1>0)
        //     && (loanBalance1<ROUND_FACTOR)){
          newValue = minFinancedAmount;
       /* }else{
            calc.genesis__Loan_Amount__c  =   maxFinancedAmount;
            loanBalance = alloc(calc, calc.genesis__payment_amount__c,accrualBase,daysInYear,intOnlyPmts,0);
            //system.debug(logginglevel.error,'Prin Balance after allocation (WithMaxFin) : '+loanBalance+' Int Rate:'+calc.genesis__Interest_Rate__c+' Loan Amount '+calc.genesis__Loan_Amount__c);
            loanBalance2 = loanBalance;
            if ((loanBalance2>0) && (loanBalance2<ROUND_FACTOR)){
                newValue = maxFinancedAmount;
            }else{
                if ((loanBalance1.abs()) < (loanBalance2.abs())){
                    newValue = minFinancedAmount;
                    minFinancedAmount = maxFinancedAmount;
                    maxFinancedAmount = newValue;
                    loanBalance3 = loanBalance1;
                    loanBalance1 = loanBalance2;
                    loanBalance2 = loanBalance3;
                }
                Integer count = 1;
                while (count < 100){
                //system.debug(logginglevel.error,'Min Fin Amt : '+ minFinancedAmount + ', Max Fin Amt  : '+maxFinancedAmount + ', Bal Amt1  : '+loanBalance1 + ', Bal Amt2  : '+loanBalance2+' Loan Amount '+calc.genesis__Loan_Amount__c);
               
                    if ((loanBalance1 - loanBalance2 ) == 0){
                        newValue = (minFinancedAmount - (loanBalance1 * (minFinancedAmount-maxFinancedAmount)/1));
                    }else{
                        newValue = (minFinancedAmount - (loanBalance1 * (minFinancedAmount-maxFinancedAmount)/(loanBalance1-loanBalance2)));
                    }
                
                    calc.genesis__Loan_Amount__c = newValue;
                    //system.debug(logginglevel.error,'Loan_Amount__c :'+calc.genesis__Loan_Amount__c);
                    loanBalance = alloc(calc, calc.genesis__payment_amount__c,accrualBase,daysInYear,intOnlyPmts,0);
                    //system.debug(logginglevel.error,'Prin Balance after allocation Loop Count'+ count + ' : '+loanBalance + 'calc.genesis__Loan_Amount__c: '+calc.genesis__Loan_Amount__c);
                    loanBalance3 = loanBalance;                             
                    if ((math.abs(loanBalance3) <= Decimal.valueOf('0.001'))
                       ||((loanBalance1 == loanBalance2) && (loanBalance3 == loanBalance2))
                       ||(count>99)){
                            break;
                     }
                    
              
                    maxFinancedAmount = minFinancedAmount;
                    minFinancedAmount = newValue;
                    loanBalance2 = loanBalance1;
                    loanBalance1 = loanBalance3;      
                    count++;

                  }
                                   
               } 
            }*/
        calc.genesis__Financed_Amount__c = newValue;
        //system.debug(logginglevel.error,'Final NPV :'+newValue);
        return calc.genesis__Financed_Amount__c;
    
    
    }  
 
}