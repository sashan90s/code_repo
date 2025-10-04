class Classroom:
    def __init__(self,bookname, pencolor):
        self.book= bookname
        self.pencolor= pencolor
    
    def read(self):
        print(f"Reading the book {self.book}")
    
    def write(self):
        print(f"Writing with pen of color {self.pencolor}")


Student1 = Classroom("fundamentals of maths", "red")

Student1.write()

Student2 = Classroom("fundamentals of physics", "blue")
Student2.read()

