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
elseif type(g:gutensyntax_use_tmp) != v:t_number
    let s:err_msg = printf("GuteSyntax: g:gutensyntax_use_tmp may be 0 or 1, now is: %s", g:gutensyntax_use_tmp)
    call add(g:gs_err_list, s:err_msg)
    let g:gs_err_flag = 1
    let g:gutensyntax_use_tmp = 0
endif

let g:gs_tmp_was_created = 0

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
    let l:seen_groups = {}
    let l:valid_kinds = 'fvdstugempxzicnk' " Valid C/C++ tags from ctags

    for l:def in g:gutensyntax_syntax_defs
        " Structural Validation
        if type(l:def) != v:t_list || len(l:def) != 3
            let s:err_msg = printf("GutenSyntax: Invalid definition in g:gutensyntax_syntax_defs\n Expected [GroupName, Tags, LinkGroup]")
            call add(g:gs_err_list, s:err_msg)
            let g:gs_err_flag = 1
        endif

        let [l:group_name, l:tags, l:link] = l:def

        " Check group name collision
        if has_key(l:seen_groups, l:group_name)
            let s:err_msg = printf("GutenSyntax: Duplicate Group Name '%s'!", l:group_name)
            call add(g:gs_err_list, s:err_msg)
            let g:gs_err_flag = 1
        endif
        let l:seen_groups[l:group_name] = 1

        " Collision Check for Tags
        for i in range(len(l:tags))
            let l:char = l:tags[i]

            " Check valid tag
            if stridx(l:valid_kinds, l:char) == -1
                let s:err_msg = printf("GutenSyntax: Invalid Ctags tag '%s' in group '%s'.", l:char, l:group_name)
                call add(g:gs_err_list, s:err_msg)
                let g:gs_err_flag = 1
            endif

            " Check for tag collision
            if has_key(l:seen_tags, l:char)
                let s:err_msg = printf("GutenSyntax: Tag collision! Character '%s' is defined in both '%s' and '%s'.", 
                    \ l:char, l:seen_tags[l:char], l:group_name)
                call add(g:gs_err_list, s:err_msg)
                let g:gs_err_flag = 1
            endif
            let l:seen_tags[l:char] = l:group_name
        endfor

        if g:gs_err_flag == 1
            return
        endif

        " Apply Highlighting
        if !empty(l:group_name) && !empty(l:link)
            execute printf('highlight default link %s %s', l:group_name, l:link)
        endif
    endfor
    return
endfunction

call s:InitializeGutenSyntax()

augroup GutenSyntaxCleanup
    autocmd!
    autocmd VimLeave * call s:CleanupTmpDir()
augroup END

function! s:CleanupTmpDir() abort
    " If we are not in the project
    if !exists('g:gs_syntax_base_dir')
        return
    endif

    if !isdirectory(g:gs_syntax_base_dir)
        echoerr "GutenSyntax: " . g:gs_syntax_base_dir . " is not directory"
        return
    endif

    " Remoove itself pid file
    if exists('g:gs_pid_file') && filereadable(g:gs_pid_file)
        call delete(g:gs_pid_file)
    endif

    " Check if exist another placeholder file in directory
    let l:remaining_files = globpath(g:gs_syntax_base_dir, '*.pid', 0, 1)
    let l:active_others = 0

    for l:file in l:remaining_files
        if l:file =~ '^\d\+\.pid$'
            let l:other_pid = fnamemodify(l:file, ':t:r')
            " If the process still exists
            if isdirectory('/proc/' . l:other_pid)
                let l:active_others += 1
            else
                " The process does not exist
                call delete(l:file)
            endif
        else
            continue
        endif
    endfor

    " If we are tha LAST session
    if l:active_others == 0
        if g:gutensyntax_use_tmp == 1
            if g:gs_syntax_base_dir =~ 'vim-gutentags' && g:gs_syntax_base_dir != '/'
                call delete(g:gs_syntax_base_dir, 'rf')
            endif
        else " We are not in tmp
            let l:syntax_files = globpath(g:gs_syntax_base_dir, '*.vim', 0, 1)
            for l:sfile in l:syntax_files
                for l:def in g:gutensyntax_syntax_defs
                    if fnamemodify(l:sfile, ':t:r') == l:def[0]
                        call delete(l:sfile)
                    endif
                endfor
            endfor
        endif
    endif
endfunction
