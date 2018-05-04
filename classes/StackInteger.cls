//Class: StackInteger
//Description: Stores elements in LIFO style(Last In First Out

public class StackInteger {
     private List<Integer> stack {get;set;}
    
      public StackInteger() {
          stack = new List<Integer>();
        }
        
        
        //Inserts an item at the top of the stack.
        public void push(Integer item) {
            if ( stack.size()< 100)
        	  stack.add(item);
        }

        //Removes and returns items from the top of the stack.
        public Integer pop() {
            if (!isEmpty()){
        	  return stack.remove(size() -1);
            }
            else
                return null;
        }
        
        //Returns the top item from the stack.
        public Integer peek() {
        if (!isEmpty())
        	return stack.get(size() - 1);
        else
        	return null;
        }        
    
        //Return true if stack is empty
        public Boolean isEmpty() {
        	return (stack.size() == 0);
        }
        
        //Return size of the stack
        public Integer size() {
        	return stack.size();
        }
}