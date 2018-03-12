" Vim filetype plugin.
" Language:	todolist
" Maintainer:	Barry Arthur <barry.arthur@gmail.com>
" License:	Vim License (see :help license)
" Location:	ftplugin/todolist.vim
" Website:	https://github.com/dahu/todolist
"
" See todolist.txt for help.  This can be accessed by doing:
"
" :helptags ~/.vim/doc
" :help todolist

" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
  finish
endif

" Don't load another filetype plugin for this buffer
let b:did_ftplugin = 1

" Allow use of line continuation.
let s:save_cpo = &cpo
set cpo&vim

" Restore things when changing filetype.
let b:undo_ftplugin = "setl fo< com< ofu<"

" Configure the matchit plugin.
let b:match_words = &matchpairs
let b:match_skip = 's:comment\|string\|character'
"let b:match_ignorecase = 1

" Set 'formatoptions' to break comment lines but not other lines,
" and insert the comment leader when hitting <CR> or using "o".
setlocal fo-=t fo+=croql

" Set completion with CTRL-X CTRL-O to autoloaded function.
"if exists('&ofu')
"  setlocal ofu=todolistcomplete#Complete
"endif

" Set 'comments'.
"setlocal comments&

" Teardown:{{{1
"reset &cpo back to users setting
let &cpo = s:save_cpo

" Template From: https://github.com/dahu/Area-41/
" vim: set sw=2 sts=2 et fdm=marker:
