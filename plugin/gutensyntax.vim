" Version:      1.0.1
" Last Change:  future

if exists('g:loaded_gutensyntax') | finish | endif
let g:loaded_gutensyntax = 1

" list of errors that occurred during initialization
let g:gs_err_list = []
" Error flag
let g:gs_err_flag = 0

if !exists('g:gutensyntax_enable')
    let g:gutensyntax_enable = 0
    finish
elseif type(g:gutensyntax_enable) != v:t_number
    let s:err_msg = printf("GutenSyntax: g:gutensyntax_enable may be a 0 or 1, now is: '%s'", g:gutensyntax_enable)
    call add(g:gs_err_list, s:err_msg)
    let g:gs_err_flag = 1
endif

" Place the syntax file in /tmp.
" This will reduce the load on the SSD and speed up the performance.
" You can set this variable in your .vimrc file

" Replace with a safer method with checking the type
" of the variable's contents
if !exists('g:gutensyntax_use_tmp')
    let g:gutensyntax_use_tmp = 1 " Default value
elseif type(g:gutensyntax_use_tmp) != 0
    let s:err_msg = printf("GuteSyntax: g:gutensyntax_use_tmp may be 0 or 1, now is: %s", g:gutensyntax_use_tmp)
    call add(g:gs_err_list, s:err_msg)
    let g:gs_err_flag = 1
    let g:gutensyntax_use_tmp = 0
endif

" Create uniq tmp dir if you use /tmp
if g:gutensyntax_use_tmp == 1 && g:gutensyntax_enable == 1
    let g:gs_syntax_tmp_dir = '/tmp/vim-gutensyntax-' . getpid()
    if !isdirectory(g:gs_syntax_tmp_dir)
        call mkdir(g:gs_syntax_tmp_dir, "p", 0700)
    endif
endif

" Set Default Configuration if not defined in .vimrc
if !exists('g:gutensyntax_syntax_defs') && g:gutensyntax_enable == 1
    let g:gutensyntax_syntax_defs = [
        \ ['MyCustomCType',  'tsgu', 'Type'],
        \ ['MyCustomCMacro', 'de',   'PreProc'],
        \ ['MyCustomCFunc',  'f',    'Function']
    \ ]
endif

" Validate and Apply Highlight Links
function! s:InitializeGutenSyntax() abort
    if g:gutensyntax_enable != 1
        return 1
    endif
    let l:seen_tags = {}

    for l:def in g:gutensyntax_syntax_defs
        " Structural Validation
        if type(l:def) != v:t_list || len(l:def) != 3
            let s:err_msg = printf("GutenSyntax: Invalid definition in g:gutensyntax_syntax_defs\n Expected [GroupName, Tags, LinkGroup]")
            call add(g:gs_err_list, s:err_msg)
            let g:gs_err_flag = 1
            return 0
        endif

        let l:group_name = l:def[0]
        let l:tags       = l:def[1]
        let l:link_target = l:def[2]

        " Collision Check for Tags
        for i in range(len(l:tags))
            let l:char = l:tags[i]
            if has_key(l:seen_tags, l:char)
                let s:err_msg = printf("GutenSyntax: Tag collision! Character '%s' is defined in both '%s' and '%s'.", 
                    \ l:char, l:seen_tags[l:char], l:group_name)
                call add(g:gs_err_list, s:err_msg)
                let g:gs_err_flag = 1
                return 0
            endif
            let l:seen_tags[l:char] = l:group_name
        endfor

        " Apply Highlighting
        if !empty(l:group_name) && !empty(l:link_target)
            execute printf('highlight default link %s %s', l:group_name, l:link_target)
        endif
    endfor
    return 1
endfunction

call s:InitializeGutenSyntax()

augroup GutenSyntaxCleanup
    autocmd!
    autocmd VimLeave * call s:CleanupTmpDir()
augroup END

function! s:CleanupTmpDir() abort
    if g:gutensyntax_use_tmp != 1 || g:gutensyntax_enable != 1
        return
    endif
    
    if exists('g:gs_syntax_tmp_dir') && isdirectory(g:gs_syntax_tmp_dir)
        call delete(g:gs_syntax_tmp_dir, 'rf')
    endif
endfunction
