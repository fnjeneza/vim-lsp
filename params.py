import vim

def DocumentUri():
    return vim.eval("expand('%:p')")

def Position():
    """Position in a text document expressed as zero-based line and zero-based
    character offset."""

    (line, character) = vim.current.window.cursor
    return {"line": line, "character":character}

def TextDocumentIdentifier():
    """ TextDocument are identified using URI"""

    return {"uri": DocumentUri()}

def TextDocumentPositionParams():
    """A parameter literal used in requests to pass a text document and a
    position inside that document"""

    return {"textDocument": TextDocumentIdentifier(), "position": Position()}


if __name__ == '__main__':
    print(TextDocumentPositionParams())
