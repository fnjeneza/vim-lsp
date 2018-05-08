
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
# additional search path for modules
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
        echo "Channel alreay connected to server"
    endif
endfunction

function! Handle_response(msg, method)
    let ret = py3eval("lsp.handle_response('".a:msg."','".a:method."')")
    " py should return a list
    " if list size ==1 goto file else fzf print files
    " let file_to_open = fzf#run({'source':["file1","file2"]})
endfunction

function! Handle_response_async(channel, msg)
    let s:completion_items = py3eval("lsp.handle_response('".a:msg."','completion')")
    " simulate key stroke in insert mode
    call feedkeys("i\<C-x>\<C-o>", 'n')
endfunction

function! s:Initialize()
    if (!s:Connected())
        return
    endif

    let arg=py3eval("lsp.initialize()")
    " asynchornous
    " call ch_sendraw(s:channel, arg, {'callback':"Response_handler"})
    let response = ch_evalraw(s:channel, arg)
    call Handle_response(response, "initialize")
    let s:initialized=1
endfunction

function s:Definition()
    let value=py3eval("lsp.textDocument_definition()")
    let response = ch_evalraw(s:channel, value)
    call Handle_response(response, "definition")
endfunction

function s:References()
    let value=py3eval("lsp.textDocument_references()")
    let response = ch_evalraw(s:channel, value)
    call Handle_response(response, "references")
endfunction

function s:File()
    let value=py3eval("lsp.textDocument_file()")
    let response = ch_evalraw(s:channel, value)
    call Handle_response(response, "file")
endfunction

function s:Switch_header_source()
    let value=py3eval("lsp.textDocument_switch_header_source()")
    let response = ch_evalraw(s:channel, value)
    call Handle_response(response, "switch_header_source")
endfunction

function s:Completion()
    let value=py3eval("lsp.textDocument_completion()")
    " we use sendraw because the response can take a time
    call ch_sendraw(s:channel, value, {'callback':"Handle_response_async"})
endfunction

function s:DidSave()
    " TODO the check is temporary the plugin shall be launched only for cpp
    if &filetype=="cpp"
        let value=py3eval("lsp.textDocument_did_save()")
        call ch_sendraw(s:channel, value)
        " There is nothing to handle on save
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
        " call Completion()
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
    command -nargs=0 ToggleHeaderAndSource :call s:Switch_header_source()
endif

if !exists(":Completion")
    " let save_ei = &eventignore
    " set eventignore=BufWritePre
    command -nargs=0 Completion :call s:Completion()
    " let &eventignore = save_ei
endif

if !exists(":Reconnect")
    command -nargs=0 Reconnect :call s:Reconnect()
endif

if !exists(":GotoFile")
    command -nargs=0 GotoFile :call s:File()
endif

if !exists(":References")
    command -nargs=0 References :call s:References()
endif

if !exists(":Definition")
    command -nargs=0 Definition :call s:Definition()
endif

au BufNewFile,BufRead * call s:OnFileRead()

autocmd BufWritePre * call s:DidSave()

" connect when entering the script
call s:Connect()
" Initialize the client with the server
call s:Initialize()


let &cpo = s:save_cpo
