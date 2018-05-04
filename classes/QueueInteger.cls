//Class: QueueInteger
//Description: Stores elements in FIFO style (First In First Out)

public class QueueInteger {
     private List<Integer> queue {get;set;}
    
      public QueueInteger() {
          queue = new List<Integer>();
        }
        
        
        //Adds an item into the queue.
        public void enqueue(Integer item) {
            if ( queue.size()< 100)
        	  queue.add(item);
        }

        //Removes and returns an item from the beginning of the queue.
        public Integer dequeue() {
            if (!isEmpty()){
        	  return queue.remove(0);
            }
            else
                return null;
        }
        
        //Returns an first item from the queue
        public Integer peek() {
        if (!isEmpty())
        	return queue.get(size() - 1);
        else
        	return null;
        }        
    
        //Return true if queue is empty
        public Boolean isEmpty() {
        	return (queue.size() == 0);
        }
        
        //Return size of the queue
        public Integer size() {
        	return queue.size();
        }
}