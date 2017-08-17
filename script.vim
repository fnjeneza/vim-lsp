" TODO retrieve the filetype
" TODO retrieve the project definition file
" TODO if not exist abort

" TODO load this script for appropriate filetype
py3f ~/vim_lsp.py

function! g:Goto_def()
    py3 goto_definition()
endfunction

command! -bar GotoDef call g:Goto_def()
