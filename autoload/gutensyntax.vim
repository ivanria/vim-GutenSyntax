
" This function is called from a file ~/.vim/autoload/gutentags/ctags.vim
" from function gutentags#ctags#on_job_exit()
function! gutensyntax#UpdateSyntaxFromTags(src_tags_file, path) abort
    if g:gs_err_flag == 1
        for l:msg in g:gs_err_list
            call gutentags#error(l:msg)
        endfor
        return
    endif

    if g:gutensyntax_enable != 1
        return
    endif

    " Create uniq tmp dir if you use /tmp
    if g:gs_tmp_was_created != 1 && g:gutensyntax_use_tmp == 1
        let l:hash = sha256(a:path)[0:12]
        let g:gs_syntax_base_dir = '/tmp/vim-gutensyntax-' . l:hash
        if !isdirectory(g:gs_syntax_base_dir)
            call mkdir(g:gs_syntax_base_dir, "p", 0700)
            let g:gs_tmp_was_created = 1
        else
            let g:gs_tmp_was_created = 1
        endif
    elseif g:gutensyntax_use_tmp == 0
        let g:gs_syntax_base_dir = a:path
        let g:gs_tmp_was_created = 1
    endif


    if !exists('g:gs_pid_file')
        let g:gs_pid_file = g:gs_syntax_base_dir . '/' . getpid() . '.pid'
        if !filereadable(g:gs_pid_file)
            call writefile([], g:gs_pid_file)
        endif
    endif

    let l:exec_list = []

    for l:def in g:gutensyntax_syntax_defs
        let [l:group, l:tags, l:file_name] = l:def
        "let l:group = l:def[0]
        "let l:tags = l:def[1]
        "let l:link = l:def[2]

        let l:filename = printf('%s/%s.vim', g:gs_syntax_base_dir, l:group)

        call add(l:exec_list, [l:group, l:tags, l:filename])
    endfor

    " Launch jobs
    for l:item in l:exec_list
        let [l:grp, l:tg, l:fname] = l:item

        " Build specific shell command for group
        let l:cmd = printf('export LC_ALL=C; echo "syntax clear %s" > %s ; sed -En "s/^([^\t]+)[[:space:]].*[[:space:]][%s]([[:space:]]|$).*$/syntax keyword %s \1/p" %s | sort -u >> %s',
            \ l:grp, l:fname, l:tg, l:grp, a:src_tags_file, l:fname)

        " Start the job and pass the filename to the callback
        call job_start(['/bin/sh', '-c', l:cmd], {
            \ 'exit_cb':{job, status -> gutensyntax#SyntaxUpdateCB(l:fname, status)},
            \ 'out_cb': 'gutentags#default_stdout_cb',
            \ 'err_cb': 'gutentags#default_stderr_cb',
            \ 'stoponexit': 'term'
        \})
    endfor
endfunction


" Callback from job_start functiin (job is pid of process, status is number
" returned from pipe l:cmd = 'set -o pipefail; sed -En ... | sort -u > ...
function! gutensyntax#SyntaxUpdateCB(syn_file, status) abort
    if a:status != 0
        call gutentags#trace("GutenSyntax: [SKIP/ERROR] code: " . a:status)
        return a:status
    endif	
    if a:status == 0 && getfsize(a:syn_file) > 0
        if empty(expand("%"))
	    return 1
	else
            for l:win in getwininfo()
                " win_execute доступен в Vim 8.1.1418+ и Vim 9
                call win_execute(l:win.winid, 'if gutensyntax#IsFileInProject(a:syn_file) | call gutensyntax#GutenColorApply(a:syn_file) | endif')
            endfor
            call gutentags#trace("GutenSyntax: silent update via win_execute done")
	    return 1
        endif
    elseif getfsize(g:glob_syntax_file) == 0 && !isdirectory(g:glob_syntax_file)
        call gutentags#trace("GutenSyntax: nothing to highlight, file is null")
	return 1
    endif
endfunction


function! gutensyntax#IsFileInProject(syn_file) abort
    if !exists('b:gutentags_root') || empty(b:gutentags_root)
        return 0
    endif

    if empty(a:syn_file)
        return 0
    endif

    let l:syn_f_size = getfsize(a:syn_file)
    if l:syn_f_size == 0 && !isdirectory(a:syn_file)
        call gutentags#trace("GutenSyntax: nothing to highlight, file is null")
        return 0
    elseif l:syn_f_size == -1
        call gutentags#trace("GutenSyntax: Syntax file: " . a:syn_file . " not found")
        return 0
    endif

    return 1 
endfunction


function! gutensyntax#GutenColorApply(syn_file) abort
    if empty(expand('%'))
        call gutentags#trace("GutenSyntax: skip update (buffer empty)")
        return 1
    endif
    execute 'silent! source ' . a:syn_file
    call gutentags#trace("GutenSyntax: updated from " . a:syn_file)
endfunction


