if exists("b:did_ftplugin")
    finish
endif

let b:did_ftplugin = 1

setlocal comments=nb:#\ ,
setlocal commentstring=#\ %s
setlocal conceallevel=2
setlocal formatlistpat=^\\s*\\([-+]\\\|\ \\*\\\|\\d\\+[.)]\\)\\s\\+
setlocal formatoptions=tcron
setlocal iskeyword+=-
setlocal nowrap
setlocal textwidth=77

command OrgExport call OrgExportHTML()

command OrgFmtTable     call OrgCommand('FmtTable')
command OrgFmtAllTables call OrgCommand('FmtAllTables')
command OrgUpDblock     call OrgCommand('UpDblock')
command OrgUpAllDblocks call OrgCommand('UpAllDblocks')
command OrgUpTable      call OrgCommand('UpTable')
command OrgUpAllTables  call OrgCommand('UpAllTables')
command OrgUpAll        call OrgCommand('UpAll')

if ! exists('g:org_path_to_emacs_el')
    let g:org_path_to_emacs_el = '~/.emacs'
endif

let s:org_emacs_cmd = 'emacs --batch --load ' . shellescape(g:org_path_to_emacs_el)

function! OrgEchoError(msg)
    echohl WarningMsg | echo a:msg | echohl None
endfunction

function! OrgExportHTML()
    let l:cmd = [
                \   s:org_emacs_cmd,
                \   '--file', expand('%'),
                \   '--funcall', 'org-html-export-to-html'
                \ ]

    let l:out = system(join(l:cmd))

    if v:shell_error != 0
        echoerr l:out
    endif
endfunction

let s:org_progs = {
            \   'FmtTable':     '(org-table-align)',
            \   'FmtAllTables': '(org-table-map-tables ''org-table-align)',
            \   'UpDblock':     '(org-dblock-update)',
            \   'UpAllDblocks': '(org-update-all-dblocks)',
            \   'UpTable':      '(org-table-iterate)',
            \   'UpAllTables':  '(org-table-iterate-buffer-tables)',
            \   'UpAll': [
            \       '(org-update-all-dblocks)',
            \       '(org-table-iterate-buffer-tables)',
            \       '(org-table-map-tables ''org-table-align)',
            \   ],
            \ }

function! OrgMakeProgn(prog)
    if type(a:prog) == v:t_list
        let l:prog = join(a:prog, ' ')
    else
        let l:prog = a:prog
    endif

    return shellescape('(progn ' . l:prog . ' (save-buffer))')
endfunction

function! OrgCommand(cmd)
    " Which elist program to use
    let l:prog = s:org_progs[a:cmd]

    " Save some view state
    let l:view = winsaveview()

    " Save undo history
    let l:undo_file = tempname()
    execute 'wundo! ' . l:undo_file

    " Write contents of current unsaved buffer into temporary file
    let l:tmp_file = tempname() . '.org'
    call writefile(getline(1, '$'), l:tmp_file)

    " Call orgformat on temporary file
    let l:line = l:view['lnum']
    let l:col = l:view['col'] + 1

    let l:cmd = [
                \   s:org_emacs_cmd,
                \   '+' . l:line,
                \   '--file', l:tmp_file,
                \   '--eval', OrgMakeProgn(l:prog)
                \ ]

    let l:out = system(join(l:cmd, ' '))

    " Get result
    if v:shell_error == 0
        " Replace current file with temporary file and reload it
        call rename(l:tmp_file, expand('%'))
        silent edit!

        " Restore undo history
        silent! execute 'rundo ' . l:undo_file

        " Restore some view state
        call winrestview(l:view)
    else
        call OrgEchoError(l:out)
    endif

    " Delete undo file
    call delete(l:undo_file)
endfunction
