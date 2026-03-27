" Version:      1.0.0
" Last Change:  2026.03.27

if exists('g:loaded_gutentags_syntax') | finish | endif
let g:loaded_gutentags_syntax = 1

" Default vim syntax file. Located at the root of your project
" You can set the syntax file name in g:local_syntax_file variable in .vimrc
if !exists('g:local_syntax_file')
    let g:local_syntax_file = '__local_syntax.vim'
endif

highlight default link MyCustomCType Type
highlight default link MyCustomCMacro PreProc


