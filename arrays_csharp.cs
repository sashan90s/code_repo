// insert at the end of an aray

using System;

namespace MyApplication
{
  class Program
  {
    static void Main()
    { // Inserting at the end of an Array
    	int[] intArray = new int[6];
        // Make a variable to store the length because .length is based off capacity
        // and does not keep track of actual indexing
        int length = 0;
        
        // This adds data to for us
        for (int i = 0; i < 3; i++)
        {
        	intArray[length] = i; 
            length++;
            //Console.WriteLine(intArray[length]);
        }
        
        intArray[length] = 8;
        length++;
        
        // below line of code is not working for some reason and I do not know why
        Console.WriteLine(intArray[length]);
    }
  }
}

