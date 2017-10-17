
import socket
import json
import os
# from params import *

class Client(object):

    def __init__(self):
        self.id = 0 # request ID
        self.connect()
        self.initialize()

    def connect(self):
        try:
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.sock.connect(("localhost", 3338))
        except ConnectionRefusedError:
            print("Connection Refused, no server available")

    def reconnect(self):
        self.connect()

    def send(self, method, params):
        request_message = {"jsonrpc":"2.0", "id":self.id, "method":method,
                "params":params}
        request_message = json.dumps(request_message)
        data = "Content-Length: {}\r\n\r\n{}".format(len(request_message),
                request_message)
        try:
            self.sock.sendall(bytes(data, "utf-8"))
            resp = self.sock.recv(1024)
            print(repr(resp))
        except BrokenPipeError:
            self.reconnect()

        self.id += 1

    def initialize(self):
        rootUri = os.path.join("/tmp/cpp-lsp/flatbuffers", "build")
        options = os.path.join(os.getcwd(), "config.json")
        if not os.path.exists(rootUri) or not os.path.exists(options):
            print("one or both necessary files does not exist")
            print(rootUri)
            print(options)
            return

        params = {"processId": os.getpid(), "rootUri": rootUri,
                "initializationOptions": options, "capabilities":"", "trace":"off"}
        self.send("initialize", params)

    def textDocument_definition(self):
        print("hello")


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
