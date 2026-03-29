" Version:      1.0.1
" Last Change:  future

if exists('g:loaded_gutensyntax') | finish | endif
let g:loaded_gutensyntax = "1"

" Place the syntax file in /tmp.
" This will reduce the load on the SSD and speed up the performance.
" You can set this variable in your .vimrc file

" Replace with a safer method with checking the type
" of the variable's contents
if !exists('g:gutensyntax_use_tmp')
    let g:gutensyntax_use_tmp = 1
elseif type(g:gutensyntax_use_tmp) != 0
    let g:gutensyntax_use_tmp = 1
endif

" Create uniq tmp dir if you use /tmp
if g:gutensyntax_use_tmp == 1
    let g:gs_syntax_tmp_dir = '/tmp/vim-gutensyntax-' . getpid()
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
                let g:gs_tag_collision = printf("GutenSyntax: Tag collision! Character '%s' is defined in both '%s' and '%s'.", 
                    \ l:char, l:seen_tags[l:char], l:group_name)
                return 0
            endif
            let l:seen_tags[l:char] = l:group_name
        endfor

        " 3. Apply Highlighting
        if !empty(l:group_name) && !empty(l:link_target)
            execute printf('highlight default link %s %s', l:group_name, l:link_target)
        endif
    endfor
    return 1
endfunction

if !s:InitializeGutenSyntax()
    let g:gs_syntax_error = 1
else
    let g:gs_syntax_error = 0
endif

augroup GutenSyntaxCleanup
    autocmd!
    autocmd VimLeave * call s:CleanupTmpDir()
augroup END

function! s:CleanupTmpDir() abort
    if g:gutensyntax_use_tmp != 1
        return
    endif
    
    if exists('g:gs_syntax_tmp_dir') && isdirectory(g:gs_syntax_tmp_dir)
        call delete(g:gs_syntax_tmp_dir, 'rf')
    endif
endfunction
