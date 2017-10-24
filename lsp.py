import socket
import json
import os
import vim

class IDE_LSPClient:
    def __init__(self):
        self.lsp_client = LSPClient()

    def DocumentUri(self):
        return vim.eval("expand('%:p')")

    def Position(self):
        (line, character) = vim.current.window.cursor
        return {"line":line,"character":character+1}

    def initialize(self):
        method = "initialize"
        rootUri = os.getcwd()
        options = os.path.join(os.getcwd(), "config.json")

        params = {"processId": os.getpid(), "rootUri": rootUri, "initializationOptions":
                options, "capabilities": "", "trace": "off"}
        self.lsp_client.send(method, params)

    def textDocument_references(self):
        method = "textDocument/references"
        uri = self.DocumentUri()

        position = self.Position()
        textDocumentIdentifier = {"uri": uri}
        context = {"includeDeclaration": True}
        params = {"textDocument": textDocumentIdentifier, "position": position,
                "context": context}
        self.lsp_client.send(method, params)

    def textDocument_definition(self):
        method = "textDocument/definition"
        uri = self.DocumentUri()

        position = self.Position()
        textDocumentIdentifier = {"uri": uri}
        params = {"textDocument": textDocumentIdentifier, "position": position}
        self.lsp_client.send(method, params)


def file_buffer(filename):
    # lookup in the buffer
    for buf in vim.buffers:
        if filename == buf.name and buf.valid:
            return buf
    return None

def goto(uri, line, character):
    if not uri: return
    current_document = vim.eval("expand('%:p')")
    if os.path.abspath(current_document) != os.path.abspath(uri):
        idx = file_buffer(uri)
        if idx:
            vim.command(":tabnext {}".format(idx.number))
        else: vim.command(":tabedit {}".format(uri))
    vim.current.window.cursor = (line, character-1)


def handler(data):
    if not data: return

    try:
        message = json.loads(data)
        uri = message["uri"]
        line = message["range"]["start"]["line"]
        character = message["range"]["start"]["character"]
        goto(uri, line, character)
    except json.decoder.JSONDecodeError as e:
        print(data)

class LSPClient():
    def __init__(self, address="localhost", port=3338):
        self.id = 1
        self.message = None
        self.address = address
        self.port = port

    def connect(self):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.connect((self.address, self.port))
            while True:
                message = yield self.message
                print(message)
                sock.sendall(bytes(message, "utf-8"));
                data = sock.recv(1024)
                handler(data.decode("utf8"))
                self.id = self.id+1

    def build_request(self, method, params):
        request = {"jsonrpc":"2.0", "id":self.id, "method":method, "params":params}
        # convert to json
        request = json.dumps(request)
        # add header part
        request = "Content-Length: {}\r\n\r\n{}".format(len(request), request)
        return request

    def send(self, method, params):
        self.coro = self.connect()
        next(self.coro)
        message = self.build_request(method, params)
        self.coro.send(message)

if __name__ == "__main__":
    ide = IDE_LSPClient()
    ide.initialize()
    ide.textDocument_definition()
    ide.textDocument_references()