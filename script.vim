" ########################################
" TODO retrieve the filetype
" TODO retrieve the project definition file
" TODO if not exist abort
"
python3 << EOF
import vim
import os
import sys
# script directory
current_directory = vim.eval("expand( '<sfile>:p:h' )")
# additional search path for modules
sys.path.append(current_directory)

from lsp import IDE_LSPClient
import lsp
client = None
EOF

let g:channel=ch_open('localhost:3338', {'mode':'raw'})
let id=1

function! Handle_response_async(channel, msg)
    " echo "from the handler ".a:msg
    echo "log from the handler"
endfunction

function! Handle_response(msg, method)
    let ret = py3eval("lsp.handle_response('".a:msg."','".a:method."')")
    " py should return a list
    " if list size ==1 goto file else fzf print files
    " let file_to_open = fzf#run({'source':["file1","file2"]})
endfunction

function! Initialize()
    let arg=py3eval("lsp.initialize()")
    " asynchornous
    " call ch_sendraw(g:channel, arg, {'callback':"Response_handler"})
    let response = ch_evalraw(g:channel, arg)
    call Handle_response(response, "initialize")
endfunction

function! Definition()
    let value=py3eval("lsp.textDocument_definition()")
    let response = ch_evalraw(g:channel, value)
    call Handle_response(response, "definition")
endfunction

function! References()
    let value=py3eval("lsp.textDocument_references()")
    let response = ch_evalraw(g:channel, value)
    call Handle_response(response, "references")
endfunction

function! File()
    let value=py3eval("lsp.textDocument_file()")
    let response = ch_evalraw(g:channel, value)
    call Handle_response(response, "file")
endfunction

function! Switch_header_source()
    let value=py3eval("lsp.textDocument_switch_header_source()")
    let response = ch_evalraw(g:channel, value)
    call Handle_response(response, "switch_header_source")
endfunction

let g:dico=[{'word':"helloWorld", 'menu':"simple word", 'info':"This is how engish people say hello", 'kind':"v", 'dup':1}, {'word':"helloWorlD", 'info':""}]
function! Complete_cpp(findstart, base)
    if a:findstart
        "locate the start of the word"
        let line = getline('.')
        let start = col('.') - 1
        while start > 0 && line[start - 1] =~ '\a'
            let start -= 1
        endwhile
        return start
    else
        "find match with a:base"
        for m in split("hello Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec")
            if m =~ '^' . a:base
                for el in g:dico
                    call complete_add(el)
                endfor
            endif
            if complete_check()
                break
            endif
        endfor
        return []
    endif
endfunction

" use CTRL-X CTRL-U to trigger the completion
" set completefunc=Complete_cpp
" use CTRL-X CTRL-O to trigger the completion
set omnifunc=Complete_cpp

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
