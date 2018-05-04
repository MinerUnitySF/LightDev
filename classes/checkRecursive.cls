public with sharing class checkRecursive {

	private static boolean run = true;
	private static boolean run2 = true;
    private static boolean run3 = true;
	
    public static boolean runOnce(){
    	if(run){
     		run=false;
     		return true;
    	}else{
        	return run;
    	}
    }
    
    public static boolean runOnce2(){
    	if(run2){
     		run2=false;
     		return true;
    	}else{
        	return run2;
    	}
    }

    public static boolean runOnce3(){
    	if(run3){
     		run3=false;
     		return true;
    	}else{
        	return run3;
    	}
    }
}