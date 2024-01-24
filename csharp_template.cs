using System;

public class MyClass
{
    public void MyMethod()
    {
        Console.WriteLine("MyMethod in MyClass");
    }
}

public class AnotherClass
{
    public void AnotherMethod()
    {
        Console.WriteLine("AnotherMethod in AnotherClass");

        // Creating an instance of MyClass
        MyClass myInstance = new MyClass();

        // Calling the MyMethod of MyClass
        myInstance.MyMethod();
    }
}

class Program
{
    static void Main()
    {
        AnotherClass anotherInstance = new AnotherClass();

        // Calling the AnotherMethod of AnotherClass
        anotherInstance.AnotherMethod();
    }
}
