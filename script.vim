" TODO retrieve the filetype
" TODO retrieve the project definition file
" TODO if not exist abort

python3 << EOF
import vim
import os
import sys
# script directory
current_directory = vim.eval("expand( '<sfile>:p:h' )")
# additional search path for modules
sys.path.append(current_directory)

from lsp import IDE_LSPClient
client = None
EOF

function! Initialize()
    py3 client = IDE_LSPClient()
    py3 client.initialize()
endfunction

function! Goto_definition()
    py3 client.textDocument_definition()
endfunction

function! Goto_reference()
    py3 client.textDocument_references()
endfunction

function! Document_didOpen()
    py3 if client is not None: client.textDocument_didOpen()
endfunction


autocmd BufRead * call Document_didOpen()

" if !exists("g:id")
"     let g:id = 0
" endif

" function! Open_channel()
"   if !exists("g:channel") || ch_status(g:channel) == "closed"
"     " open a channel
"     let g:channel = ch_open('localhost:8888')
"   endif
"   echo ch_status(g:channel)
" endfunction

" function! DocumentUri()
"   return expand('%:p')
" endfunction

" function! TextDocumentIdentifier()
"   return {"uri": DocumentUri()}
" endfunction

" function! Position()
"   " position tuple
"   let pos = getcurpos()
"   " current row
"   let row = pos[1]
"   " current column
"   let col = pos[2]
"   return {"line":row, "character":col}
" endfunction

" function! TextDocumentPositionParams()
"   let _textDocument = TextDocumentIdentifier()
"   let _position = Position()
"   return {"textDocument": _textDocument, "position":_position}
" endfunction

" func! Handler(channel, msg)
"     echo a:msg["method"]
" endfunc

" function! Send_request(method, params, handler)
"   let g:id += 1
"   let _request = {"jsonrpc":"2.0", "id":g:id, "method":a:method, "params":a:params}
"   call ch_sendexpr(g:channel, _request, {'callback': a:handler})
" endfunction

" function! Get_command()
"   " compile commands
"   " TODO must be defined
"   let g:compile_commands = ""
"   " filename
"   let file = expand("%:p")
"   let pos = getcurpos()
"   " current row
"   let row = pos[1]
"   " current column
"   let col = pos[2]
"   let cmd = "icscope --cc ".g:compile_commands." -f ".file." -l ".row." -o ".col
"   return cmd
" endfunction

" function! Goto_definition()
"   let _method = "textDocument/definition"
"   let _params = TextDocumentPositionParams()
" "  call Send_request(_method, _params, "Handler")
" "  TODO remove. just for test
"   let cmd = Get_command()." -g"
"   echo cmd
"   return
"   let output = json_decode(system(cmd))
"   let filename = output["file"]
"   silent! execute "tabedit ".filename
"   let row = output["line"]
"   let col = output["col"]
"   call setpos('.', [0, row, col, 0])
" endfunction


" " TODO load this script for appropriate filetype
" "py3f vim_lsp.py

" call Open_channel()
" command! GotoDefinition call Goto_definition()
