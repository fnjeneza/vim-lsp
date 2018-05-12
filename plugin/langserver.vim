
let s:save_cpo=&cpo
set cpo&vim

if exists("g:loaded_langserver")
    finish
endif
let g:loaded_langserver=1
"cpp langserver
let g:cpp_langserver='localhost:3338'
let s:completion_items=[]
let id=1
" Initialized flag
let s:initialized=0


python3 << EOF
import vim
import os
import sys
# script directory
current_directory = vim.eval("expand( '<sfile>:p:h' )")
#additional search path for modules
sys.path.append(current_directory)

from lsp import IDE_LSPClient
import lsp
client = None
EOF

function s:Connect()
    " connect to the server
    let s:channel=ch_open(g:cpp_langserver, {'mode':'raw'})
endfunction

" Check that the channel is connected to a server
function! s:Connected()
    return ch_status(s:channel) == "open"
endfunction

function s:Reconnect()
    if ch_status(s:channel) != "open"
        call s:Connect()
        call s:Initialize()
    else
        echo "Channel already connected to server"
    endif
endfunction

function! Handle_response(msg, method)
    let ret = py3eval("lsp.handle_response('".a:msg."','".a:method."')")
    " py should return a list
    " if list size ==1 goto file else fzf print files
    " let file_to_open = fzf#run({'source':["file1","file2"]})
endfunction

function s:TextDocument(method)
    if (!s:Connected())
        return
    endif
    if &filetype!="cpp"
        return
    endif
    let value=py3eval("lsp.textDocument_".a:method."()")
    let response = ch_evalraw(s:channel, value)
    let ret = py3eval("lsp.handle_response('".response."','".a:method."')")
endfunction

function s:ATextDocument(method)
    if (!s:Connected())
        return
    endif
    if &filetype!="cpp"
        return
    endif
    let value=py3eval("lsp.textDocument_".a:method."()")
    call ch_sendraw(s:channel, value)
    " call py3eval("lsp.handle_response('".response."','".a:method."')")
endfunction

function! s:Initialize()
    call s:TextDocument("initialize")
    let s:initialized=1
endfunction

" Synchronous completion method
function s:CompletionSync()
    " send a command if file did change
    s:DidChange()
    let value=py3eval("lsp.textDocument_completion()")
    " send the request
    let _ = ch_evalraw(s:channel, value)
    " handle the response
    let response = ch_read(s:channel)
    let s:completion_items = py3eval("lsp.handle_response('".response."','completion')")
endfunction

function s:DidChange()
    " not modified
    if !&modified
        return
    endif
    if &filetype=="cpp"
        let value=py3eval("lsp.textDocument_did_change()")
        call ch_sendraw(s:channel, value)
    endif
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
        call s:CompletionSync()
        for item in s:completion_items
            call complete_add(item)

            if complete_check()
                break
            endif
        endfor
        return []
    endif
endfunction

function s:OnFileRead()
    if &filetype=="cpp"
        " use CTRL-X CTRL-U to trigger the completion
        " set completefunc=Complete_cpp
        " use CTRL-X CTRL-O to trigger the completion
        set omnifunc=Complete_cpp
    endif
endfunction

if !exists(":Toggle_header_and_source")
    command -nargs=0 ToggleHeaderAndSource :call s:TextDocument("switch_header_source")
endif

if !exists(":Reconnect")
    command -nargs=0 Reconnect :call s:Reconnect()
endif

if !exists(":GotoFile")
    command -nargs=0 GotoFile :call s:TextDocument("file")
endif

if !exists(":References")
    command -nargs=0 References :call s:TextDocument("references")
endif

if !exists(":Definition")
    command -nargs=0 Definition :call s:TextDocument("definition")
endif

autocmd BufNewFile,BufRead * call s:OnFileRead()

autocmd BufEnter * call s:ATextDocument("did_open")
autocmd BufLeave * call s:ATextDocument("did_close")
autocmd BufWritePre * call s:ATextDocument("did_save")

" connect when entering the script
call s:Connect()
" Initialize the client with the server
call s:Initialize()

let &cpo = s:save_cpo
