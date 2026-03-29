" Version:      1.0.1
" Last Change:  future

if exists('g:loaded_gutensyntax') | finish | endif
let g:loaded_gutensyntax = "1"

" Place the syntax file in /tmp.
" This will reduce the load on the SSD and speed up the performance.
" You can set this variable in your .vimrc file

" Replace with a safer method with checking the type
" of the variable's contents
let g:gutensyntax_use_tmp = get(g:, 'gutensyntax_use_tmp', 1)
if type(g:gutensyntax_use_tmp) != 0
    let g:gutensyntax_use_tmp = 1
endif

" Create uniq tmp dir if you use /tmp
if g:gutensyntax_use_tmp == 1
    let g:gs_syntax_tmp_dir = '/tmp/vim-' . rand(srand(l:seed))
    if !isdirectory(g:gs_syntax_tmp_dir)
        call mkdir(g:gs_syntax_tmp_dir, "p", 0700)
    endif
endif

" Set Default Configuration if not defined in .vimrc
if !exists('g:gutensyntax_syntax_defs')
    let g:gutensyntax_syntax_defs = [
        \ ['MyCustomCType',  'tsgu', 'Type'],
        \ ['MyCustomCMacro', 'de',   'PreProc'],
        \ ['MyCustomCFunc',  'f',    'Function']
    \ ]
endif

" Validate and Apply Highlight Links
function! s:InitializeGutenSyntax() abort
    let l:seen_tags = {}

    for l:def in g:gutensyntax_syntax_defs
        " Structural Validation
        if type(l:def) != v:t_list || len(l:def) != 3
            echoerr "GutenSyntax: Invalid definition format. Expected [GroupName, Tags, LinkGroup]"
            continue
        endif

        let l:group_name = l:def[0]
        let l:tags       = l:def[1]
        let l:link_target = l:def[2]

        " Collision Check for Tags
        for i in range(len(l:tags))
            let l:char = l:tags[i]
            if has_key(l:seen_tags, l:char)
                echoerr printf("GutenSyntax: Tag collision! Character '%s' is defined in both '%s' and '%s'.", 
                    \ l:char, l:seen_tags[l:char], l:group_name)
                return  " Stop initialization if tags overlap
            endif
            let l:seen_tags[l:char] = l:group_name
        endfor

        " 3. Apply Highlighting
        if !empty(l:group_name) && !empty(l:link_target)
            execute printf('highlight default link %s %s', l:group_name, l:link_target)
        endif
    endfor
endfunction

augroup GutenSyntaxCleanup
    autocmd!
    autocmd VimLeave * call s:CleanupTmpDir()
augroup END

function! s:CleanupTmpDir() abort
    if g:gutensyntax_use_tmp != 1
        finish
    endif
    if exists('g:gs_syntax_tmp_dir') && isdirectory(g:gs_syntax_tmp_dir)
        call job_start(['rm', '-rf', g:gs_syntax_tmp_dir])
    endif
endfunction
