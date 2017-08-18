" TODO retrieve the filetype
" TODO retrieve the project definition file
" TODO if not exist abort

if !exists("g:id")
    let g:id = 0
endif

function! Open_channel()
  if !exists("g:channel") || ch_status(g:channel) == "closed"
    " open a channel
    let g:channel = ch_open('localhost:8888')
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

func! Handler(channel, msg)
    echo a:msg["method"]
endfunc

function! Send_request(method, params)
  let g:id += 1
  let _request = {"jsonrpc":"2.0", "id":g:id, "method":a:method, "params":a:params}
  call ch_sendexpr(g:channel, _request, {'callback': 'Handler'})
endfunction

function! Goto_definition()
  let _method = "textDocument/definition"
  let _params = TextDocumentPositionParams()
  call Send_request(_method, _params)
endfunction


" TODO load this script for appropriate filetype
"py3f vim_lsp.py

call Open_channel()
"command! GotoDefinition python3 goto_definition()
command! GotoDefinition call Goto_definition()
