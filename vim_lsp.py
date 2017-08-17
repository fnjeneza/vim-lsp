import vim
#TODO initialze the client first according to the language and project
#TODO how to identify a project maybe create a vim.project file
#TODO each project has a root path, or use a file.pro
# run command,
# test command

def _open(filepath, row, col):
    # goto to line
    #vim.command('{}l'.format(line))
    vim.command(":edit {}".format(filepath))
    w = vim.current.window
    # move the cursor
    w.cursor = (row, col)

def goto_definition():
    print("go to definition function")
    # TODO retrieve the filepath, row and col
    # TODO send the command to server
    # TODO handle the resporse asynchronously

def goto_reference():
    print("go to reference function")
