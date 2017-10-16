
import sys
import os
sys.path.append(os.getcwd())

import json
import vim
from params import *

def open_channel():
    status = vim.eval("ch_status(g:channel)")
    if status != "open":
        # open the channel
        vim.command("let g:channel = ch_open('localhost:3338', {'mode':'raw'})")

# TODO implement this as wrapper
def request_message(params):
    request = {"jsonrpc": "2.0", "id": "g:id"}
    request.update(params)
    request = json.dumps(request)

    data = "Content-Length: {}\r\n\r\n{}".format(len(request), request)
    return data

def textDocument_definition():
    request = {"method": "textDocument/definition",
            "params": TextDocumentPositionParams()}
    return request_message(request)

def request(method):
    # call appropriate method which will build its own argument.
    # the response is handled asynchornously
    pass

def initialize():
    pass

if __name__ == "__main__":
    # goto_definition()
    open_channel()
    goto_definition()
