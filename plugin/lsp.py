import socket
import json
import os
import vim

class IDE_LSPClient:
    def __init__(self):
        # self.lsp_client = LSPClient()
        pass

    def DocumentUri(self):
        path = vim.eval("expand('%:p')")
        path = path.replace("home_raid1", "home")
        return path

    def Position(self):
        (line, character) = vim.current.window.cursor
        return {"line":line,"character":character+1}

    def initialize(self):
        method = "initialize"
        rootUri = os.getcwd()
        options = os.path.join(os.getcwd(), "config.json")

        params = {"processId": os.getpid(), "rootUri": rootUri, "initializationOptions":
                options, "capabilities": "", "trace": "off"}
        # self.lsp_client.send(method, params)
        send(request(method, params))

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

def DocumentUri():
    path = vim.eval("expand('%:p')")
    return path

def Position():
    (line, character) = vim.current.window.cursor
    return {"line":line,"character":character+1}

def initialize():
    method = "initialize"
    rootUri = os.getcwd()
    options = os.path.join(os.getcwd(), "config.json")

    params = {"processId": os.getpid(), "rootUri": rootUri, "initializationOptions":
            options, "capabilities": "", "trace": "off"}
    return request(method, params)

def textDocument_definition():
    method = "textDocument/definition"
    uri = DocumentUri()

    position = Position()
    textDocumentIdentifier = {"uri": uri}
    params = {"textDocument": textDocumentIdentifier, "position": position}
    return request(method, params)

def textDocument_references():
    method = "textDocument/references"
    uri = DocumentUri()

    position = Position()
    textDocumentIdentifier = {"uri": uri}
    context = {"includeDeclaration": True}
    params = {"textDocument": textDocumentIdentifier, "position": position,
            "context": context}
    return request(method, params)

def textDocument_completion():
    method = "textDocument/completion"
    uri = DocumentUri()

    position = Position()
    textDocumentIdentifier = {"uri": uri}
    params = {"textDocument": textDocumentIdentifier, "position": position,
            "context": ""}
    return request(method, params)

def textDocumentItem(method):
    uri = DocumentUri()
    position = Position()
    textDocumentIdentifier = {"uri": uri}
    params = {"textDocument": textDocumentIdentifier, "position": position}
    return request(method, params)


def textDocument_file():
    method = "textDocument/file"
    return textDocumentItem(method)

def textDocument_switch_header_source():
    method = "textDocument/switch_header_source"
    return textDocumentItem(method)

def textDocument_did_open():
    method = "textDocument/didOpen"
    return textDocumentItem(method)

def textDocument_did_close():
    method = "textDocument/didClose"
    uri = DocumentUri()
    textDocumentIdentifier = {"uri": uri}
    params = {"textDocument": textDocumentIdentifier}
    return request(method, params)

def textDocument_did_change():
    method = "textDocument/didChange"
    uri = DocumentUri()

    textDocumentIdentifier = {"uri": uri, "version":1}
    text = " ".join(vim.current.buffer)
    TextDocumentContentChangeEvent = {"text": R"{}".format(text)}
    params = {"textDocument": textDocumentIdentifier, "contentChanges":
            TextDocumentContentChangeEvent}
    return request(method, params)

def textDocument_did_save():
    method = "textDocument/didSave"
    uri = DocumentUri()

    position = Position()
    textDocumentIdentifier = {"uri": uri}
    params = {"textDocument": textDocumentIdentifier, "text": ""}
    return request(method, params)

def completion_items(completion_items):
    items =[]
    for completion_item in completion_items:
        word = completion_item["label"]
        items.append({"word": word})
    return items

def handle_response(response, method):
    if method == "initialize":
        return True
    elif method == "completion":
        try:
            message = json.loads(response)
            result = message["result"]
            if len(result) == 0:
                return True
            return completion_items(result)
        except json.decoder.JSONDecodeError as e:
            print("json decoding error")
            print(response)
            return False
    else:
        try:
            message = json.loads(response)
            result = message["result"]
            if len(result) == 0:
                return True
            files=[]
            index = 1
            for res in result:
                uri = res["uri"]
                line = res["range"]["start"]["line"]
                character = res["range"]["start"]["character"]
                files.append("{}  : {}:{}".format(index, uri, line))
                index = index+1
            source = "'source':{}".format(files)
            command = "fzf#run({%s})" %source
            value = vim.eval(command)[0]
            index = int(value.split(':')[0])
            res = result[index-1]
            uri = res["uri"]
            line = res["range"]["start"]["line"]
            character = res["range"]["start"]["character"]
            goto(uri, line, character)
        except json.decoder.JSONDecodeError as e:
            print("json decoding error")
            print(response)
            return False
    return True

def request(method, params):
    request = {"jsonrpc":"2.0", "id":1, "method":method, "params":params}
    # convert to json
    request = json.dumps(request)
    # add header part
    request = "Content-Length: {}\r\n\r\n{}".format(len(request), request)
    return request

def send(req):
    vim.command("""call ch_sendraw(channel, '{}',
            {'callback':'Response_handler'})""".format(req))

def file_buffer(filename):
    # lookup in the buffer
    for buf in vim.buffers:
        if filename == buf.name and buf.valid:
            return buf
    return None

def goto(uri, line, character):
    if not uri: return
    current_document = vim.eval("expand('%h')")
    if not os.path.samefile(current_document,uri):
        vim.command(":edit {}".format(uri))
        # idx = file_buffer(uri)
        # if idx:
        #     vim.command(":tabnext {}".format(idx.number))
        # else: vim.command(":edit {}".format(uri))
    vim.current.window.cursor = (line, character-1)

def message_error(message):
    try:
        error = message["error"]
        if error is not None or len(error) == 0:
            return True
        return False
    except :
        pass

def handler(data, method):
    if not data: return

    try:
        message = json.loads(data)
        id = message["id"]

        if message_error(message):
            err = message["error"]
            print("{}:{}".format(error["code"], error["message"]))
        else:
            if method == "initialize":
                message = message["result"]
                # TODO initialize server parameter
                return
            if method == "textDocument/didOpen":
                return

            uri = message["uri"]
            line = message["range"]["start"]["line"]
            character = message["range"]["start"]["character"]
            goto(uri, line, character)

    except json.decoder.JSONDecodeError as e:
        print("json decoding error")
        print(data)

class LSPClient():
    def __init__(self, address="localhost", port=3338):
        self.id = 1
        self.message = None
        self.address = address
        self.port = port
        self.method_request_sent = {}

    def connect(self):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.connect((self.address, self.port))
            while True:
                message = yield self.message
                # print(message)
                sock.sendall(bytes(message, "utf-8"));
                self.method_request_sent[self.id] = self._method
                data = sock.recv(1024)
                handler(data.decode("utf8"), self.method_request_sent[self.id])
                self.id = self.id+1

    def build_request(self, method, params):
        request = {"jsonrpc":"2.0", "id":self.id, "method":method, "params":params}
        # convert to json
        request = json.dumps(request)
        # add header part
        request = "Content-Length: {}\r\n\r\n{}".format(len(request), request)
        return request

    def send(self, method, params):
        try:
            self.coro = self.connect()
            next(self.coro)
            message = self.build_request(method, params)
            self._method = method
            self.coro.send(message)
        except ConnectionRefusedError:
            print("Connection refused error")

if __name__ == "__main__":
    ide = IDE_LSPClient()
    ide.initialize()
    ide.textDocument_definition()
    ide.textDocument_references()
