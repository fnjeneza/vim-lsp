" ########################################
" TODO retrieve the filetype
" TODO retrieve the project definition file
" TODO if not exist abort
"

let s:save_cpo=&cpo
set cpo&vim

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

let g:completion_items=[]
let g:channel=ch_open('localhost:3338', {'mode':'raw'})
let id=1

function! Handle_response(msg, method)
    let ret = py3eval("lsp.handle_response('".a:msg."','".a:method."')")
    " py should return a list
    " if list size ==1 goto file else fzf print files
    " let file_to_open = fzf#run({'source':["file1","file2"]})
endfunction

function! Handle_response_async(channel, msg)
    let g:completion_items = py3eval("lsp.handle_response('".a:msg."','completion')")
    " simulate key stroke in insert mode
    call feedkeys("i\<C-x>\<C-o>", 'n')
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

function! Completion()
    let value=py3eval("lsp.textDocument_completion()")
    call ch_sendraw(g:channel, value, {'callback':"Handle_response_async"})
endfunction

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
        " call Completion()
        for item in g:completion_items
            call complete_add(item)

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

let &cpo = s:save_cpo
