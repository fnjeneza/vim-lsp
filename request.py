
import socket
import json
import os
from params import *

def initialize():
    rootUri = os.path.join("/tmp/cpp-lsp/flatbuffers", "build")
    options = os.path.join(os.getcwd(), "config.json")
    params = {"processId": os.getpid(), "rootUri": rootUri,
            "initializationOptions": options, "capabilities":"", "trace":"off"}
    request = {"method": "initialize", "params":params}
    request_message(request)


# TODO implement this as wrapper
def request_message(params):
    request = {"jsonrpc": "2.0", "id": id}
    request.update(params)
    request = json.dumps(request)

    data = "Content-Length: {}\r\n\r\n{}".format(len(request), request)
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.connect(("localhost", 3338))
        sock.sendall(bytes(data, "utf-8"))
        resp = sock.recv(1024)
        print(repr(resp))

def textDocument_definition():
    request = {"method": "textDocument/definition",
            "params": TextDocumentPositionParams()}
    return request_message(request)

def request(method):
    # call appropriate method which will build its own argument.
    # the response is handled asynchornously
    pass

if __name__ == "__main__":
    initialize()
