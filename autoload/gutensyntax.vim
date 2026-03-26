
" This function is called from a file ~/.vim/autoload/gutentags/ctags.vim
" from function gutentags#ctags#on_job_exit()
function! gutensyntax#UpdateSyntaxFromTags(src_tags_file, path) abort
    let l:syntax_file = g:local_syntax_file
    let l:tag_file_size = getfsize(a:src_tags_file)
    if l:tag_file_size == -1
        call gutentags#trace("GutenSyntax: tags_file " . a:src_tags_file . " not found")
        return
    elseif l:tag_file_size == 0 && !isdirectory(a:src_tags_file)
        call gutentags#trace("GutenSyntax: tags_file " . a:src_tags_file . " null sized")
	return
    endif

    let l:full_path_syn_file = a:path . '/' . l:syntax_file
    let g:glob_syntax_file = l:full_path_syn_file
    call gutentags#trace("GutenSyntax: generate syntax file: " . l:syntax_file)
        
    let l:cmd = 'export LC_ALL=C ; echo "syntax clear MyCustomCType" > ' . l:full_path_syn_file . ' ; echo "syntax clear MyCustomCMacro" >> ' . l:full_path_syn_file . ' ; set -o pipefail; sed -En "s/^([^\t]+)[[:space:]].*[[:space:]][tsgu]([[:space:]]|$).*$/syntax keyword MyCustomCType \1/p ; s/^([^\t]+)[[:space:]].*[[:space:]][de]([[:space:]]|$).*$/syntax keyword MyCustomCMacro \1/p" ' . a:src_tags_file . ' | sort -u >> ' . l:full_path_syn_file
        
    call job_start(['/bin/sh', '-c', l:cmd], { 
        \'exit_cb': 'gutensyntax#SyntaxUpdateCB',
        \'out_cb': 'gutentags#default_stdout_cb',
        \'err_cb': 'gutentags#default_stderr_cb',
        \'stoponexit': 'term'
	\})

endfunction

"function! gutensyntax#BackupTagsFile(tags_file) abort
    "let l:back_file = a:tags_file . '.old'
    "let l:tags_file_size = getfsize(a:tags_file)
    "if l:tags_file_size == 0 && !isdirectory(a:tags_file)
        "call system('cp ' . shellescape(a:tags_file) . ' ' . shellescape(l:back_file))
        "call gutentags#trace("GutenSyntax: tags file: " . a:tags_file . " is null size")
    "elseif l:tags_file_size == -1
        "call gutentags#trace("GutenSyntax: tags file: " . a:tags_file . " not found")
        "return
    "else
        "call system('cp ' . shellescape(a:tags_file) . ' ' . shellescape(l:back_file))
    "endif
    "call gutentags#trace("GutenSyntax: move" . a:tags_file . " to: " . l:back_file . "!!!!")
"endfunction

" Callback from job_start functiin (job is pid of process, status is number
" returned from pipe l:cmd = 'set -o pipefail; sed -En ... | sort -u > ...
function! gutensyntax#SyntaxUpdateCB(job, status) abort
    if a:status != 0
        call gutentags#trace("GutenSyntax: [SKIP/ERROR] code: " . a:status)
        return a:status
    endif	
    if a:status == 0 && getfsize(g:glob_syntax_file) > 0
        if empty(expand("%"))
	    return 1
	else
            for l:win in getwininfo()
                " win_execute доступен в Vim 8.1.1418+ и Vim 9
                call win_execute(l:win.winid, 'if gutensyntax#IsFileInProject() | call gutensyntax#GutenColorApply() | endif')
            endfor
            call gutentags#trace("GutenSyntax: silent update via win_execute done")
	    return 1
        endif
    elseif getfsize(g:glob_syntax_file) == 0 && !isdirectory(g:glob_syntax_file)
        call gutentags#trace("GutenSyntax: nothing to highlight, file is null")
	return 1
    endif
endfunction


function! gutensyntax#IsFileInProject() abort
    if !exists('b:gutentags_root') || empty(b:gutentags_root)
        return 0
    endif

    if !exists('g:glob_syntax_file') || empty(g:glob_syntax_file)
        return 0
    endif

    let l:syn_f_size = getfsize(g:glob_syntax_file)
    if l:syn_f_size == 0 && !isdirectory(g:glob_syntax_file)
        call gutentags#trace("GutenSyntax: nothing to highlight, file is null")
        return 0
    elseif l:syn_f_size == -1
        call gutentags#trace("GutenSyntax: Syntax file: " . g:glob_syntax_file . " not found")
        return 0
    endif

    return 1 
endfunction


function! gutensyntax#GutenColorApply() abort
    if empty(expand('%'))
        call gutentags#trace("GutenSyntax: skip update (buffer empty)")
        return 1
    endif
    execute 'silent! source ' . g:glob_syntax_file
    call gutentags#trace("GutenSyntax: updated from " . g:glob_syntax_file)
endfunction


            "let l:current_win = win_getid()
	    "let l:current_tab = tabpagenr()
	    "noautocmd tabdo windo execute 'if gutensyntax#IsFileInProject() | call gutensyntax#GutenColorApply() | endif'
	    "execute 'tabnext ' . l:current_tab
            "call win_gotoid(l:current_win)
	    "call gutentags#trace("GutenSyntax: it worked well!!!")
