" Version:      1.0.0
" Last Change:  2026.03.27

if exists('g:loaded_gutentags_syntax') | finish | endif
let g:loaded_gutentags_syntax = "1"

" Place the syntax file in /tmp.
" This will reduce the load on the SSD and speed up the performance.
" You can set this variable in your .vimrc file
if !exist('g:GS_place_syntax_in_tmp')
    let g:GS_place_syntax_in_tmp = "0"
endif

" Default vim syntax file. Located at the root of your project
" You can set this variable in your .vimrc file
if !exists('g:GS_local_syntax_file')
    let g:GS_local_syntax_file = '__local_syntax.vim'
endif

highlight default link MyCustomCType Type
highlight default link MyCustomCMacro PreProc


augroup GutenSyntaxCleanup
    autocmd!
    autocmd VimLeave * call s:CleanupTmpDir()
augroup END

function! s:CleanupTmpDir() abort
    if exists('g:syntax_tmp_dir') && isdirectory(g:syntax_tmp_dir)
        call job_start(['rm', '-rf', g:syntax_tmp_dir])
    endif
endfunction
