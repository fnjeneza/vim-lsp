" TODO retrieve the filetype
" TODO retrieve the project definition file
" TODO if not exist abort

let g:id = 0
function! Open_channel()
  if ch_status(g:channel) == "closed"
    " open a channel
    let g:channel = ch_open('localhost:8765')
  endif
  echo ch_status(g:channel)
endfunction

function! DocumentUri()
  return expand('%:p')
endfunction

function! TextDocumentIdentifier()
  return {"uri": DocumentUri()}
endfunction

function! Position()
  " position tuple
  let pos = getcurpos()
  " current row
  let row = pos[1]
  " current column
  let col = pos[2]
  return {"line":row, "character":col}
endfunction

function! TextDocumentPositionParams()
  let _textDocument = TextDocumentIdentifier()
  let _position = Position()
  return {"textDocument": _textDocument, "position":_position}
endfunction

function! Send_request(method, params)
  let g:id += 1
  let _request = {"jsonrpc":"2.0", "id":g:id, "method":a:method, "params":a:params}
  echo ch_evalexpr(g:channel, _request)
endfunction

function! Goto_definition()
  let _method = "textDocument/definition"
  let _params = TextDocumentPositionParams()
  call Send_request(_method, _params)
  let _request = {"method":_method, "params":_params}
endfunction


" TODO load this script for appropriate filetype
"py3f vim_lsp.py

call Open_channel()
"command! GotoDefinition python3 goto_definition()
command! GotoDefinition call Goto_definition()
