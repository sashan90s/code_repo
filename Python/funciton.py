
# we will see how to use function inside a function
# in python

def new_func(age, name):
    def fn_test(name):
        print(f"my name {name}, and my age is {age}")

    mesg = fn_test(name)
    return mesg

new_func(12, "sihan")