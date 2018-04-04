if exists("b:did_ftplugin")
    finish
endif

let b:did_ftplugin = 1

setlocal comments=nb:#\ ,
setlocal commentstring=#\ %s
setlocal conceallevel=2
setlocal formatlistpat=^\\s*\\([-+]\\\|\s\\*\\\|\\d\\+[.)]\\)\\s\\+
setlocal formatoptions=ronq
setlocal iskeyword+=-
setlocal nowrap
setlocal textwidth=77
setlocal foldmethod=syntax
setlocal foldminlines=2
setlocal foldtext=getline(v:foldstart)

command! OrgExport call OrgExportToHTML()
command! OrgGuessCommand call OrgGuessCommand()

if !exists("g:no_plugin_maps") && !exists("g:no_org_maps")
    if !hasmapto('<Plug>OrgGuessCommand')
        nmap <buffer> cc <Plug>OrgGuessCommand
    endif
    nnoremap <buffer> <Plug>OrgGuessCommand :OrgGuessCommand<CR>
endif

if ! exists('g:org_path_to_emacs_el')
    let g:org_path_to_emacs_el = '~/.emacs'
endif

if ! exists('g:org_emacs_executable')
    let g:org_emacs_executable = 'emacs'
endif

let s:org_emacs_cmd = g:org_emacs_executable . ' --batch --load ' . shellescape(g:org_path_to_emacs_el)

let s:org_progs = {
            \   'FmtTable':          '(org-table-align)',
            \   'FmtAllTables':      "(org-table-map-tables 'org-table-align)",
            \   'UpDblock':          '(org-dblock-update)',
            \   'UpAllDblocks':      '(org-update-all-dblocks)',
            \   'ExecuteSrcBlock':   '(org-babel-execute-maybe)',
            \   'UpTable':           '(org-table-iterate)',
            \   'UpAllTables':       '(org-table-iterate-buffer-tables)',
            \   'ApplyTableFormula': "(require 'org-table) (org-table-calc-current-TBLFM)",
            \   'UpAll': [
            \       '(org-update-all-dblocks)',
            \       '(org-table-iterate-buffer-tables)',
            \       "(org-table-map-tables 'org-table-align)",
            \   ],
            \   'MoveColRight': {
            \       'prog': '(org-table-move-column-right)',
            \       'cursor': 'col',
            \   },
            \   'MoveColLeft': {
            \       'prog': '(org-table-move-column-left)',
            \       'cursor': 'col',
            \   },
            \   'DelCol': {
            \       'prog': '(org-table-delete-column)',
            \       'cursor': 'col',
            \   },
            \   'AddCol': {
            \       'prog': '(org-table-insert-column)',
            \       'cursor': 'col',
            \   },
            \ }

let s:org_prog_guesses = {
            \ '^\s*#+BEGIN:': 'UpDblock',
            \ '^\s*#+TBLFM:': 'ApplyTableFormula',
            \ '^\s*|':        'UpTable'
            \ }

for k in keys(s:org_progs)
    execute 'command! Org' . k . " call OrgCommand('" . k . "')"
endfor

let s:org_emacs_status = 0
let s:org_emacs_version = ''
let s:org_emacs_orgmode_version = ''

function! OrgCloseSectionFold()
    if getline('.') =~? ('^\*\{' . foldlevel('.') . '} ')
        foldclose
    endif
endfunction

function! OrgCloseSectionFolds()
    let l:items = []

    if g:org_start_with_closed_sections =~# 'endstate'
        for k in keys(b:org_todo_keys)
            if b:org_todo_keys[k][1]
                let l:items += [k]
            endif
        endfor
    endif

    if g:org_start_with_closed_sections =~# 'comment'
        let l:items += ['COMMENT']
    endif

    if empty(l:items)
        let l:pat = '^\*\+\s\+'
    else
        let l:pat = '^\*\+\s\+\(' . join(l:items, '\|') . '\)\s'
    endif

    execute 'normal! g/' . l:pat . '/call OrgCloseSectionFold()'
endfunction

if exists('g:org_start_with_closed_sections')
    autocmd BufWinEnter *.org call OrgCloseSectionFolds()
endif

function! OrgEchoError(msg)
    echohl WarningMsg | echo a:msg | echohl None
endfunction

function! OrgCheckEmacsOrgAvailability()
    let l:out = systemlist(s:org_emacs_cmd . ' --version')

    if v:shell_error == 0
        let s:org_emacs_version = l:out[0]
        echomsg s:org_emacs_version
    else
        let s:org_emacs_status = -1
    endif

    let l:out = systemlist(s:org_emacs_cmd . ' --funcall org-version')

    if v:shell_error == 0 && l:out[-1] =~ '^Org mode version \d\+\.\d\+\.\d\+'
        let s:org_emacs_orgmode_version = l:out[-1]
        echomsg s:org_emacs_orgmode_version
    else
        let s:org_emacs_status = -2
    endif

    if s:org_emacs_status == 0
        let s:org_emacs_status = 1
    endif
endfunction

function! OrgAreEmacsOrgAvailable()
    if s:org_emacs_status == 0
        call OrgCheckEmacsOrgAvailability()
    endif

    if s:org_emacs_status == -1
        call OrgEchoError('Emacs not available')
    elseif s:org_emacs_status == -2
        call OrgEchoError('Orgmode not available')
    endif

    return s:org_emacs_status == 1
endfunction

function! OrgExportToHTML()
    if ! OrgAreEmacsOrgAvailable()
        return
    endif

    let l:cmd = [
                \   s:org_emacs_cmd,
                \   '--file', expand('%'),
                \   '--funcall', 'org-html-export-to-html'
                \ ]

    let l:out = system(join(l:cmd))

    if v:shell_error != 0
        call OrgEchoError(l:out)
    endif
endfunction

function! OrgMakeProgn(prog)
    " Support the different kinds of way to define a program (string, list,
    " dictionary)
    let l:prog = type(a:prog) == v:t_dict ? a:prog['prog'] : a:prog

    let l:prog = (type(l:prog) == v:t_list ? join(l:prog, ' ') : l:prog)

    " If a dictionary, check if asking for cursor
    if type(a:prog) == v:t_dict && has_key(a:prog, 'cursor')
        let l:prog .= ' (message "Col %s" (current-column)) (what-line)'
    endif

    " Besides executing the program, it also prints the current cursor column
    " and line, then saves the file
    return shellescape('(progn ' . l:prog . ' (save-buffer))')
endfunction

function! OrgCommand(cmd)
    if ! OrgAreEmacsOrgAvailable()
        return
    endif

    " Which program to use
    let l:prog = s:org_progs[a:cmd]

    " Save some view state
    let l:view = winsaveview()

    " Write contents of current unsaved buffer into temporary file
    let l:tmp_file = tempname() . '.org'
    call writefile(getline(1, '$'), l:tmp_file)

    " Call orgformat on temporary file
    let l:line = l:view['lnum']
    let l:col = l:view['col'] + 1

    let l:cmd = [
                \   s:org_emacs_cmd,
                \   '+' . l:line . ':' . l:col,
                \   '--file', l:tmp_file,
                \   '--eval', OrgMakeProgn(l:prog)
                \ ]

    let l:out = systemlist(join(l:cmd, ' '))

    " Get result
    if v:shell_error == 0
        " Replace buffer contents
        "   Deletes the whole content of the buffer, appends the new content,
        "   then deletes the remaining empty line. The 'normal! a \b' line is
        "   a hack to avoid changing the cursor position when undoing the
        "   change.
        silent execute 'normal! a \b'
        silent %delete
        silent call append(0, readfile(l:tmp_file))
        silent delete

        " Restore some view state
        call winrestview(l:view)

        " Restore cursor position
        if type(l:prog) == v:t_dict && has_key(l:prog, 'cursor')
            let l:col = matchstr(l:out[-2], '^Col \zs\d\+$')
            let l:line = matchstr(l:out[-1], '^Line \zs\d\+$')

            if l:col != '' && l:line != ''
                let l:cur_pos = getpos('.')
                let l:cur_pos[1] = str2nr(l:line)
                let l:cur_pos[2] = str2nr(l:col) + 1
                call setpos('.', l:cur_pos)
            endif
        endif
    else
        call OrgEchoError(join(l:out, '\n'))
    endif
endfunction

function! OrgGuessCommand()
    let l:line = getline('.')
    for k in keys(s:org_prog_guesses)
        if l:line =~? k
            echo 'Org' . s:org_prog_guesses[k]
            call OrgCommand(s:org_prog_guesses[k])
        endif
    endfor
endfunction
