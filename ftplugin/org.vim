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
