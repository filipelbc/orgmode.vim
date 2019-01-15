if exists("b:did_ftplugin")
    finish
endif

let b:did_ftplugin = 1

setlocal comments=nb:#\ ,
setlocal commentstring=#\ %s
setlocal conceallevel=2
setlocal foldmethod=syntax
setlocal foldminlines=2
setlocal foldtext=getline(v:foldstart).\'...\'
setlocal formatlistpat=^\\s*\\([-+]\\\|\s\\*\\\|\\d\\+[.)]\\)\\s\\+
setlocal formatoptions=ronq
setlocal iskeyword+=-
setlocal nowrap
setlocal textwidth=77

" cmd, use_leader, keys
let s:org_default_maps = [
            \   ['OrgGuessCommand',  v:true,  'cc'],
            \   ['OrgExportToHTML',  v:true,  'eh'],
            \   ['OrgMoveColRight',  v:true,  'cl'],
            \   ['OrgMoveColLeft',   v:true,  'ch'],
            \   ['OrgDelCol',        v:true,  'cd'],
            \   ['OrgAddCol',        v:true,  'ca'],
            \   ['OrgFmtTable',      v:true,  'tt'],
            \   ['OrgJumpCellRight', v:false, '<tab>'],
            \   ['OrgJumpCellLeft',  v:false, '<s-tab>'],
            \ ]

function! OrgDeclareNewMap(cmd, use_leader, keys)
    execute 'nnoremap <buffer> <Plug>' . a:cmd . ' :' . a:cmd . '<CR>'
    if !hasmapto('<Plug>' . a:cmd) && !exists("g:no_org_default_maps")
        execute 'nmap <buffer> ' . (a:use_leader ? g:org_map_leader : '') . a:keys . ' <Plug>' . a:cmd
    endif
endfunction

if !exists("g:no_plugin_maps") && !exists("g:no_org_maps")
    if !exists('g:org_map_leader')
        let g:org_map_leader = '<leader>'
    endif

    for [c, l, k] in s:org_default_maps
        call OrgDeclareNewMap(c, l, k)
    endfor
endif

if !exists('g:org_path_to_emacs_el')
    let g:org_path_to_emacs_el = '~/.emacs'
endif

if !exists('g:org_emacs_executable')
    let g:org_emacs_executable = 'emacs'
endif

let s:org_emacs_cmd = g:org_emacs_executable . ' --batch --load ' . shellescape(g:org_path_to_emacs_el)

let s:org_emacs_progs = {
            \   'FmtTable':          '(org-table-align)',
            \   'FmtAllTables':      "(org-table-map-tables 'org-table-align)",
            \   'UpDblock':          '(org-dblock-update)',
            \   'UpAllDblocks':      '(org-update-all-dblocks)',
            \   'ExecuteSrcBlock': {
            \       'prog': [
            \           '(org-babel-execute-maybe)',
            \           '(let ((errbuf (get-buffer "*Org-Babel Error Output*")))',
            \           '   (if errbuf',
            \           '       (with-current-buffer errbuf',
            \           '           (message (buffer-string)))))',
            \       ],
            \       'babel-error': 1,
            \   },
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
            \ '^\s*#+BEGIN:':         'UpDblock',
            \ '^\s*#+TBLFM:':         'ApplyTableFormula',
            \ '^\s*|':                'UpTable',
            \ '^\s*#+BEGIN_SRC \k\+': 'ExecuteSrcBlock',
            \ '^\s*#+CALL: \k\+':     'ExecuteSrcBlock',
            \ }

for k in keys(s:org_emacs_progs)
    execute 'command! Org' . k . " call OrgCommand('" . k . "')"
endfor

command! OrgExportToHTML call OrgExportToHTML()
command! OrgGuessCommand call OrgGuessCommand()

let s:org_emacs_status = 0
let s:org_emacs_version = ''
let s:org_emacs_orgmode_version = ''
let s:org_emacs_output_offset = 0

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

    let l:cur_pos = getcurpos()
    execute 'g/' . l:pat . '/call OrgCloseSectionFold()'
    call setpos('.', l:cur_pos)
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

    let s:org_emacs_output_offset = len(l:out) - 1

    if v:shell_error == 0 && l:out[-1] =~ '^Org mode version \d\+\.\d\+'
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
    if !OrgAreEmacsOrgAvailable()
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
    if !OrgAreEmacsOrgAvailable()
        return
    endif

    " Which program to use
    let l:prog = s:org_emacs_progs[a:cmd]

    " Save some view state
    let l:view = winsaveview()

    " Write contents of current unsaved buffer into a temporary file.
    " Manage the temporary directory in order to be able to recover generated
    " files.
    let l:tmp_dir = tempname()
    call mkdir(l:tmp_dir, 'p')

    let l:tmp_file = l:tmp_dir . '/' . expand('%:t')
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
                let l:cur_pos = getcurpos()
                let l:cur_pos[1] = str2nr(l:line)
                let l:cur_pos[2] = str2nr(l:col) + 1
                call setpos('.', l:cur_pos)
            endif
        endif

        " Show babel error
        if type(l:prog) == v:t_dict && has_key(l:prog, 'babel-error')
                    \ && l:out[s:org_emacs_output_offset+1] != 'Code block evaluation complete.'
            echo join(l:out[s:org_emacs_output_offset+3:], "\n")
        endif

        " Recover generated files
        call system('cp $(ls ' . l:tmp_dir . '/* | grep -v ' . expand('%:t') . ') ' . expand('%:p:h'))
    else
        call OrgEchoError(join(l:out, "\n"))
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

function! OrgJumpToNextCell(right)
    let l:line = getline('.')

    " the line is a table row
    if l:line =~? '^\s*|\([^-]\|$\)'
        let l:c0 = getcurpos()

        if a:right
            normal! f|
        else
            normal! F|

            " we did not start at a column separator
            if l:line !~? '\%' . l:c0[2] . 'c|'
                let l:c1 = getcurpos()

                " cursor changed position
                if l:c0[2] != l:c1[2]
                    normal! F|
                endif
            endif
        endif

        let l:c1 = getcurpos()

        " cursor changed position
        " and
        " we did not end up in an empty cell
        if l:c0[2] != l:c1[2] && l:line !~? ('\%' . l:c1[2] . 'c|\s*\(|\|$\)')
            normal! w
        endif
    endif
endfunction

for [n, d] in [['Right', v:true], ['Left', v:false]]
    execute 'command! OrgJumpCell' . n . " call OrgJumpToNextCell(" . d . ")"
endfor
