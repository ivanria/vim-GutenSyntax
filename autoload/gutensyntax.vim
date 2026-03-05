
" This function is called from a file ~/.vim/autoload/gutentags/ctags.vim
" from function gutentags#ctags#on_job_exit()
function! gutensyntax#UpdateSyntaxFromTags(src_tags_file, path) abort
    let l:syntax_file = g:local_syntax_file
    let l:tag_file_size = getfsize(a:src_tags_file)
    if l:tag_file_size == -1
        call gutentags#trace("Syntax: tags_file " . a:src_tags_file . " not found")
        return
    elseif l:tag_file_size == 0 && !isdirectory(a:src_tags_file)
        call gutentags#trace("Syntax: tags_file " . a:src_tags_file . " null sized")
	return
    endif

    let l:full_path_syn_file = a:path . '/' . l:syntax_file
    let g:glob_syntax_file = l:full_path_syn_file
        
    let l:cmd = 'set -o pipefail; sed -En "s/^([^\t]+)[[:space:]].*[[:space:]][tsgu]([[:space:]]|$).*$/syntax keyword MyCustomType \1/p ; s/^([^\t]+)[[:space:]].*[[:space:]][de]([[:space:]]|$).*$/syntax keyword MyCustomMacro \1/p" ' . a:src_tags_file . ' | sort -u > ' . l:full_path_syn_file
        
    call job_start(['/bin/sh', '-c', l:cmd], { 
        \'exit_cb': 'gutensyntax#SyntaxUpdateCB',
        \'out_cb': 'gutentags#default_stdout_cb',
        \'err_cb': 'gutentags#default_stderr_cb',
        \'stoponexit': 'term'
	\})

endfunction

" Callback from job_start functiin (job is pid of process, status is number
" returned from pipe l:cmd = 'set -o pipefail; sed -En ... | sort -u > ...
function! gutensyntax#SyntaxUpdateCB(job, status) abort
    if a:status != 0
        call gutentags#trace("Syntax: [SKIP/ERROR] code: " . a:status)
        return a:status
    endif	
    if a:status == 0 && getfsize(g:glob_syntax_file) > 0
        if empty(expand("%"))
            call gutentags#trace("Syntax: skip update (buffer empty)")
	    return 0
	else
            execute 'silent! source ' . g:glob_syntax_file
            highlight link MyCustomType Type
            highlight link MyCustomMacro PreProc
            call gutentags#trace("Syntax: updated from " . g:glob_syntax_file)
	    call gutentags#trace("Syntax: it worked well!!!")
	    return 0
        endif
    elseif getfsize(g:glob_syntax_file) == 0 && !isdirectory(g:glob_syntax_file)
        call gutentags#trace("Syntax: nothing to highlight, file is null")
	return 0
    endif
endfunction

