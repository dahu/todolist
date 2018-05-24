" Vim library for short description
" Maintainer:	Barry Arthur <barry.arthur@gmail.com>
" License:	Vim License (see :help license)
" Location:	autoload/node/node.vim
" Website:	https://github.com/dahu/node
"
" See node.txt for help.  This can be accessed by doing:
"
" :helptags ~/.vim/doc
" :help node

" Vimscript Setup: {{{1
" Allow use of line continuation.
let s:save_cpo = &cpo
set cpo&vim

" load guard
" uncomment after plugin development
" Remove the conditions you do not need, they are there just as an example.
"if exists("g:loaded_lib_node")
"      \ || v:version < 700
"      \ || v:version == 703 && !has('patch338')
"      \ || &compatible
"  let &cpo = s:save_cpo
"  finish
"endif
"let g:loaded_lib_node = 1

let s:node_id = 1
" Library Interface: {{{1
function! todolist#node#new(level, completed, text, ...)
  let s:node_id += 1
  let node = {}
  let node.parent = node
  let node.id = s:node_id
  let node.level = a:level
  let node.completed = a:completed
  let node.text = a:text
  let node.attributes = extend({'missing' : v:false}, a:0 ? a:1 : {})
  let node.children = []
  return node
endfunction

" Teardown:{{{1
"reset &cpo back to users setting
let &cpo = s:save_cpo

" Template From: https://github.com/dahu/Area-41/
" vim: set sw=2 sts=2 et fdm=marker:
