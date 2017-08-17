" TODO retrieve the filetype
" TODO retrieve the project definition file
" TODO if not exist abort

" TODO load this script for appropriate filetype
py3f vim_lsp.py

command! GotoDefinition python3 goto_definition()
