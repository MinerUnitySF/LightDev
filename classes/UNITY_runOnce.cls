public class UNITY_runOnce{
    public static Boolean firstRun = false;   
    public static Boolean run(){
        if(!firstRun){
            firstRun = true;
            return firstRun;
        }
        return false;
    }
}