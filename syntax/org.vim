if exists("b:current_syntax")
    finish
endif

syntax clear
syntax sync fromstart

" Settings and options
let b:org_markup_conceal = exists('g:org_markup_conceal') ? g:org_markup_conceal : 1

" <state>: [<default-style>, <is-end-state>]
let b:org_todo_keys = {
            \ 'DONE': ['DONE', v:true],
            \ 'TODO': ['TODO', v:false],
            \ }

if exists('g:org_custom_todo_keys')
    for k in keys(g:org_custom_todo_keys)
        let b:org_todo_keys[k] = g:org_custom_todo_keys[k]
    endfor
endif

let b:org_todo_styles = {
            \   'DONE': ['#00bb00', 'NONE', 'inverse,bold'],
            \   'TODO': ['#ff0000', 'NONE', 'inverse,bold'],
            \ }

if exists('g:org_custom_todo_styles')
    for k in keys(g:org_custom_todo_styles)
        let b:org_todo_styles[k] = g:org_custom_todo_styles[k]
    endfor
endif

let b:org_section_meta_style = ['#93a1a1']
let b:org_section_tag_style = ['#002b36']

let b:org_priority_keys = ['A', 'B', 'C']
let b:org_priority_styles = [
            \   ['#002b36'],
            \ ]

let b:org_max_sections = 7
let b:org_section_styles = [
            \   ['#dc322f', 'NONE', 'bold'],
            \   ['#268bd2', 'NONE', 'bold'],
            \   ['#d33682', 'NONE', 'bold'],
            \   ['#2aa198', 'NONE', 'bold'],
            \   ['#859900', 'NONE', 'bold'],
            \   ['#6c71c4', 'NONE', 'bold'],
            \   ['#b58900', 'NONE', 'bold'],
            \   ['#cb4b16', 'NONE', 'bold'],
            \ ]

let b:org_title_style = ['#002b36', 'NONE', 'bold']

let b:org_markup_group_style = ['#93a1a1']

let b:org_link_style = ['#268bd2', 'NONE', 'underline']

" Style helper
function! MakeStyleString(s)
    " s = [<foregroud>, <backgroud>, <attribute>]
    return 'guifg=' . a:s[0] . ' guibg=' . get(a:s, 1, 'NONE') . ' cterm=' . get(a:s, 2, 'NONE')
endfunction

" Markup
let s:markups = [
            \   ['\*', 'Bold'],
            \   ['/', 'Italic'],
            \   ['_', 'Underline'],
            \   ['+', 'Strikethrough'],
            \ ]

let s:code_markups = ['\~', '=']

function! MarkupEnd(c, ...)
    let l:extra = (a:0 >= 1) ? '\|[*/+_]\($\|\s\|[-)}\"''.,:;!?]\)' : ''
    return '"\s\@<!' . a:c . '\($\|\s\|[-)}\"''.,:;!?]' . l:extra . '\)\@="'
endfunction

function! MarkupStart(c, ...)
    let l:extra = (a:0 >= 1) ? '\|\(^\|\s\|[-({\"'']\)[*/+_]' : ''
    return '"\(^\|\s\|[-({\"'']' . l:extra . '\)\@<=' . a:c . '[^ ]"' . 'rs=e-1'
endfunction

let s:concealends = b:org_markup_conceal ? ' concealends' : ''

for m in s:markups
    execute 'syntax region org' . m[1] . ' matchgroup=org' . m[1] . 'Group'
            \ . ' start=' . MarkupStart(m[0])
            \ . ' end=' . MarkupEnd(m[0])
            \ . ' oneline'
            \ . ' keepend'
            \ . s:concealends
            \ . ' contains=orgMacroReplacement,orgCode,orgLink'
    execute 'hi org' . m[1] . ' cterm=' . tolower(m[1])
    execute 'hi link org' . m[1] . ' org' . m[1]

    execute 'hi org' . m[1] . 'Group ' . MakeStyleString(b:org_markup_group_style)
    execute 'hi link org' . m[1] . 'Group org' . m[1] . 'Group'
endfor

for m in s:code_markups
    execute 'syntax region orgCode matchgroup=orgCodeGroup'
                \ . ' start=' . MarkupStart(m, v:true)
                \ . ' end=' . MarkupEnd(m, v:true)
                \ . ' oneline'
                \ . ' keepend'
                \ . s:concealends
endfor

execute 'hi orgCodeGroup ' . MakeStyleString(b:org_markup_group_style)
execute 'hi link orgCodeGroup orgCodeGroup'

execute 'syntax cluster orgMarkups contains=' . join(map(s:markups, '"org" . v:val[1]'), ',')

syntax cluster orgContained contains=orgMacroReplacement,orgCode,orgLink,@orgMarkups

" Headings
function! FindAndCall(regex, func_name)
    execute 'silent keeppatterns %s/' . a:regex . '/\=' . a:func_name. '(submatch(0))/gne'
endfunction

function! RegisterTodoKeys(match)
    let l:t = ["TODO", v:false]
    for k in split(a:match)
        if k ==# "|"
            let l:t = ["DONE", v:true]
        else
            let b:org_todo_keys[k] = l:t
        endif
    endfor
endfunction

function! RegisterPriorityKeys(match)
    let b:org_priority_keys = split(a:match)
endfunction

call FindAndCall("^\s*#+TODO:\\s*\\zs.*", 'RegisterTodoKeys')
call FindAndCall("^\s*#+PRIORITIES:\\s*\\zs.*", 'RegisterPriorityKeys')

for k in keys(b:org_todo_styles)
    execute 'hi orgTodoStyle_' . k . ' ' . MakeStyleString(b:org_todo_styles[k])
endfor

for i in range(len(b:org_priority_keys))
    let l = len(b:org_priority_styles)
    execute 'hi orgPriorityStyle_' . i . ' ' . MakeStyleString(b:org_priority_styles[i % l])
endfor

for k in keys(b:org_todo_keys)
    if has_key(b:org_todo_styles, k)
        let s:s = k
    else
        let s:s = b:org_todo_keys[k][0]
    endif
    execute 'syntax keyword orgTodoKey_' . k . ' contained ' . k
    execute 'hi link orgTodoKey_' . k . ' orgTodoStyle_' . s:s
endfor

for i in range(len(b:org_priority_keys))
    let s:k = b:org_priority_keys[i]
    execute 'syntax keyword orgPriorityKey_' . s:k . ' contained ' . s:k
    execute 'hi link orgPriorityKey_' . s:k . ' orgpriorityStyle_' . i
endfor

execute 'syntax cluster orgTodoKeys contains=' . join(map(keys(b:org_todo_keys), "'orgTodoKey_' . v:val"), ',')
execute 'syntax cluster orgPriorityKeys contains=' . join(map(b:org_priority_keys, "'orgPriorityKey_' . v:val"), ',')

syntax match orgPriority contained " \zs\[#\a\+\] " contains=@orgPriorityKeys

execute 'syntax match orgSectionMeta contained "\(COMMENT \+\)\=\(\(' . join(keys(b:org_todo_keys), '\|') . '\) \+\)\=\(\[#\a\+\] \+\)\=" contains=@orgTodoKeys,orgPriority'
syntax match orgSectionStars contained "^\*\+ \+" nextgroup=orgSectionMeta transparent contains=NONE

syntax match orgSectionTag contained "[a-zA-Z0-9]\+"
syntax match orgSectionTags contained "\s\+:\([a-zA-Z0-9]*:\)\+$" contains=orgSectionTag

for i in range(b:org_max_sections)
    execute 'syntax match orgSection' . i . ' "^\*\{' . (i + 1) . '} .*" contains=orgSectionStars,orgSectionTags,@orgContained nextgroup=orgProperties skipnl'

    execute 'hi orgSectionStyle' . i . ' ' . MakeStyleString(b:org_section_styles[i])
    execute 'hi link orgSection' . i . ' orgSectionStyle' . i

    execute 'syntax region orgFold' . i . ' start="^\*\{' . (i + 1) . '} " end="\ze\n\*\{' . (i + 1) . '} " fold transparent keepend'
endfor

" From now on, ignore case
syntax case ignore

" Lists
syntax match orgOrderedList "^\s*\zs\d\+[.)]\ze "

syntax match orgUnorderedList "^\s*\zs\([-+]\| \*\)\ze "

syntax match orgDescriptionListName contained "[-+*] \zs.*\ze ::"
syntax match orgDescriptionList "^\s*\zs\([-+]\| \*\) .\{-} ::\($\| \)" contains=orgDescriptionListName

syntax cluster orgLists contains=orgOrderedList,orgUnorderedList,orgDescriptionList

" Comment
syntax match orgComment "^\s*#\s.*"

" Config
syntax match orgConfigValue contained ".*$" contains=@orgContained
syntax match orgConfig "^\s*#+\k\+:" nextgroup=orgConfigValue skipwhite

syntax match orgTitleValue contained ".*$" contains=orgMacroReplacement
syntax match orgTitle "^\s*#+TITLE:" nextgroup=orgTitleValue skipwhite

" Macros
syntax match orgMacroArgNum contained "\$\d"
syntax match orgMacroValue contained ".*" contains=orgMacroArgNum
syntax match orgMacroName contained "^\s*#+MACRO:\s\+\zs\k\+\ze\s\+" nextgroup=orgMacroValue
syntax match orgMacroDefinition "^\s*#+MACRO:\s\+\k\+\s\+.*" contains=orgMacroName
syntax match orgMacroReplacement "{\{3}.\{-}}\{3}"

hi link orgMacroArgNum Type
hi link orgMacroValue Constant
hi link orgMacroName Special
hi link orgMacroDefinition Statement

" Tables
syntax cluster orgCellContains contains=orgTableColDel,@orgContained

syntax match orgTableColDel "|" contained

syntax match orgTableCell "|[^|]*" contained contains=@orgCellContains transparent
syntax match orgTableHeaderCell "|[^|]*" contained contains=@orgCellContains

syntax match orgTableRow "^\s*|.*" contains=orgTableHeader,orgTableCell transparent
syntax match orgTableLine "^\s*|-\+\(+-\+\)*\(|\)\=\s*$"
syntax match orgTableHeader "\(^\s*[^|]*\n\s*\)\@<=|[^-].*\n\ze\s*|-" contains=orgTableHeaderCell transparent

syntax cluster orgTableContained contains=orgTableRow,orgTableLine,orgTableHeader

hi link orgTableColDel Type
hi link orgTableLine Type
hi link orgTableHeaderCell orgBold

" Links
syntax match orgLinkBorder contained "\[\[\|\]\[\|\]\]" conceal
syntax match orgLinkURL contained "\[\[[^]]\{-}\]\[" conceal contains=orgLinkBorder

syntax match orgLink "\[\[.\{-}\]\]" contains=orgLinkBorder,orgLinkURL

execute 'hi orgLink ' . MakeStyleString(b:org_link_style)
hi link orgLink orgLink
hi link orgLinkBorder Special
hi link orgLinkURL Type

" Properties
syntax region orgProperties contained matchgroup=orgPropertiesGroup start="^\s*:PROPERTIES:\s*$" end="^\s*:END:\s*$" keepend fold contains=orgProperty
syntax match orgPropertyValue contained ".*$" contains=@orgContained
syntax match orgPropertyName contained "^\s*\zs:\k\++\=:" nextgroup=orgPropertyValue skipwhite
syntax match orgProperty contained "^\s*:\k\++\=:.*$" transparent contains=orgPropertyName

" Blocks
syntax region orgBlockDyn matchgroup=orgBlockGroup start="^\s*#+BEGIN:\( .*\)\=$" end="^\s*#+END:\s*$" keepend fold contains=@orgTableContained
syntax region orgBlockGeneric matchgroup=orgBlockGroup start="^\s*#+BEGIN_\z\([^ ]\+\)\( .*\)\=$" end="^\s*#+END_\z1\s*$" keepend fold
syntax region orgBlockComment matchgroup=orgComment start="^\s*#+BEGIN_COMMENT\( .*\)\=$" end="^\s*#+END_COMMENT\s*$" keepend fold

syntax region orgBlockExport  matchgroup=orgBlockGroup start="^\s*#+BEGIN_EXPORT\( .*\)\=$"  end="^\s*#+END_EXPORT\s*$"  keepend fold
syntax region orgBlockExample matchgroup=orgBlockGroup start="^\s*#+BEGIN_EXAMPLE\( .*\)\=$" end="^\s*#+END_EXAMPLE\s*$" keepend fold
syntax region orgBlockQuote   matchgroup=orgBlockGroup start="^\s*#+BEGIN_QUOTE\( .*\)\=$"   end="^\s*#+END_QUOTE\s*$"   keepend fold contains=@orgContained,@orgLists
syntax region orgBlockCenter  matchgroup=orgBlockGroup start="^\s*#+BEGIN_CENTER\( .*\)\=$"  end="^\s*#+END_CENTER\s*$"  keepend fold contains=@orgContained,@orgLists
syntax region orgBlockVerse   matchgroup=orgBlockGroup start="^\s*#+BEGIN_VERSE\( .*\)\=$"   end="^\s*#+END_VERSE\s*$"   keepend fold contains=@orgContained

syntax region orgBlockSrc matchgroup=orgBlockGroup start="^\s*#+BEGIN_SRC\( .*\)\=$" end="^\s*#+END_SRC\s*$" keepend fold

" Colors
execute 'hi orgSectionMeta ' . MakeStyleString(b:org_section_meta_style)
execute 'hi orgSectionTag ' . MakeStyleString(b:org_section_tag_style)
hi link orgSectionMeta orgSectionMeta
hi link orgPriority orgSectionMeta
hi link orgSectionTags orgSectionMeta

hi link orgComment Comment
hi link orgBlockComment Comment

hi link orgConfig Statement
hi link orgConfigValue String

execute 'hi orgTitleValueStyle ' . MakeStyleString(b:org_title_style)
hi link orgTitle Statement
hi link orgTitleValue orgTitleValueStyle

hi link orgOrderedList Special

hi link orgDescriptionListName Type
hi link orgDescriptionList Special

hi link orgUnorderedList Special

hi link orgMacroReplacement Special

hi link orgCode String

hi link orgPropertiesGroup PreProc
hi link orgPropertyValue Constant
hi link orgPropertyName Statement

hi link orgBlockDyn String
hi link orgBlockSrc String
hi link orgBlockGroup Identifier

hi link orgBlockGeneric String
hi link orgBlockExport String
hi link orgBlockExample String

let b:current_syntax = 'org'
