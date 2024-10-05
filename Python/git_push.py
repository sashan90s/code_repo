
import subprocess
import sys
#setting a variable and then converting it into an argument to pass
msg1 = sys.argv[1]

#defining the function that takes a command/script to execute on powershell
#replacing the try and exception with if...else... to give us message if the command 
def grun_shell(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    print(result.check_returncode)
    subprocess.check_output
    if result.returncode == 0:
        print("Command executed successfully.", result.stdout)
    else:
        print("Command execution failed", result.stderr)

def git(msg):
    cmd1 = "git add --all"
    cmd2 = f"git commit -m {msg}"
    cmd3 = f"git push"

    grun_shell(cmd1)
    grun_shell(cmd2)
    grun_shell(cmd3)

git(msg1)

#python git_push.py "test1"
