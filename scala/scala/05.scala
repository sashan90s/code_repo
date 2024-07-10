import scala.util.Random
@main def dataApp() =
  val x:Int = Random.nextInt(5)
  
  x match
      case 1 => println("One")
      case 2 => println("Two")
      case 3 => println("Three")
      case 4 => println("Four")
      case 5 => println("Five")
