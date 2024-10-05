
import subprocess


def grun_shell(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)

    if result.returncode == 0:
        print("Command executed successfully.", result.stdout)
    else:
        print("Command execution failed", result.stderr)

def git(msg, branch):
    cmd1 = "git add --all"
    cmd2 = f"git commit -m {msg}"
    cmd3 = f"git push {branch}"

    grun_shell(cmd1)
    grun_shell(cmd2)
    grun_shell(cmd3)
    
git('test', 'main')

