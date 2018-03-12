" Vim library for short description
" Maintainer:   Barry Arthur <barry.arthur@gmail.com>
" License:      Vim License (see :help license)
" Location:     autoload/todolist.vim
" Website:      https://github.com/dahu/todolist
"
" See todolist.txt for help.  This can be accessed by doing:
"
" :helptags ~/.vim/doc
" :help todolist

" Vimscript Setup: {{{1
" Allow use of line continuation.
let s:save_cpo = &cpo
set cpo&vim

" load guard
"if exists("g:loaded_lib_todolist")
"      \ || v:version < 700
"      \ || &compatible
"  let &cpo = s:save_cpo
"  finish
"endif
let g:loaded_lib_todolist = 1

" Vim Script Information Function: {{{1
function! todolist#info()
  let info = {}
  let info.name = 'todolist'
  let info.version = 1.0
  let info.description = 'Simple todo-list manipulator.'
  let info.dependencies = []
  return info
endfunction

" Library Interface: {{{1

" Attributes
" * missing : [default=ignore, fill, collapse]
" -> ignore   : Don't render missing nodes (rendered result resembles original source)
" -> fill     : Render missing nodes (TODO: default missing text as another attribute)
" -> collapse : Don't render missing nodes and collapse children to commence at missing node's depth.
"
" * completion : [default=fractional, percentage]

" Completions
" Fractional completions where n==m (e.g. [2/2]) are converted into [x]
" Percentage completions of 100% are converted into [x]
"

let s:attribute_validators = {
      \  'missing'    : ['ignore', 'fill', 'collapse']
      \, 'completion' : ['fractional', 'percentage']
      \}

let s:attribute_defaults = {
      \  'missing'    : 'ignore'
      \, 'completion' : 'fractional'
      \}

function! s:validate_attributes(attributes)
  for [attribute, valid_options] in items(s:attribute_validators)
    if has_key(a:attributes, attribute) && index(valid_options, a:attributes[attribute], 0, 1) == -1
      echoerr 'Unknown ' . attribute . ' value: "' . a:attributes[attribute] . '"'
    endif
  endfor
endfunction

function! todolist#set_attribute_defaults(attributes) abort
  call s:validate_attributes(a:attributes)
  call extend(s:attribute_defaults, a:attributes)
endfunction

function! todolist#command_complete(ArgLead, CmdLine, CursorPos)
  let list = []
  if a:ArgLead =~? '\m\%(^\s*\||\s*\)\w*$'
    " Completion for attribute names
    let list = filter(keys(copy(s:attribute_validators)), 'v:val =~# a:ArgLead')
  elseif a:ArgLead =~? '\m\%(^\s*\||\s*\)\w\+[=:]\w*$'
    " Completion for attribute values
    let attribute = matchstr(a:ArgLead, '\w\+\ze[=:]')
    let value = matchstr(a:ArgLead, '\w\+[=:]\zs\w*')
    let list = map(filter(copy(s:attribute_validators[attribute]), 'v:val =~# value'), 'attribute . "=" . v:val')
  else
    " debug
    echo '-> ' . a:CmdLine[: a:CursorPos ]
    echoerr '=> ' . a:ArgLead . '<='
  endif
  " Return non-empty items.
  return filter(list, 'v:val !~ ''^\s*$''')
endfunction

function! todolist#new(...) abort
  if a:0 && ! empty(a:1)
    call s:validate_attributes(a:1)
  endif
  let todo = {}
  let todo.root = todolist#node#new(0, 0, '')
  let todo.attributes = extend(copy(s:attribute_defaults), a:0 ? a:1 : {})

  func! todo.add_node(parent, node) abort
    let a:node.parent = a:parent
    call add(a:parent.children, a:node)
    return a:node
  endfunc

  func! todo.add_nodes(nodes) abort
    let parents = []
    let previous = self.root
    for node in deepcopy(a:nodes)
      if node.level == previous.level
        let previous = self.add_node(previous.parent, node)
      elseif node.level > previous.level
        let level = previous.level + 1
        if self.attributes.missing != 'collapse'
          while level < node.level
            let previous = self.add_node(previous, todolist#node#new(level, node.completed, '', {'missing' : v:true}))
            call add(parents, previous.parent)
            let level += 1
          endwhile
        endif
        let node.level = level
        let previous = self.add_node(previous, node)
        call add(parents, previous.parent)
      else
        let parent = parents[node.level-1]
        let parents = parents[0:node.level-1]
        let previous = self.add_node(parent, node)
      endif
    endfor
    return self
  endfunc

  func! todo.render() abort
    return self.traverse_nodes('inorder', self.render_node)
  endfunc

  func! todo.render_node(node) abort
    call add(self.result, repeat('*', self.depth) . ' [' . a:node.completed . ']' . (len(a:node.text) ? ' ' . a:node.text : ''))
  endfunc

  func! todo.calculate_completion() abort
    return self.traverse_nodes('depthfirst', self.calculate_node_completion)
  endfunc

  func! todo.calculate_node_completion(node) abort
    let node = a:node
    if ! empty(node.children)
      let m = len(node.children)
      let n = len(filter(copy(node.children), 'v:val.completed == "x"'))
      if n == m
        let node.completed = 'x'
      else
        if self.attributes.completion == 'fractional'
          let node.completed = n . '/' . m
        else
          let node.completed = float2nr(((n * 1.0) / m) * 100) . ' %'
        endif
      endif
    endif
  endfunc

  func! todo.traverse_node(node, method, action) abort
    let skip = (a:node.attributes.missing && self.attributes.missing == 'ignore')
    let self.depth += 1
    if a:method == 'inorder' && !skip
      call call(a:action, [a:node])
    endif
    for child in a:node.children
      call self.traverse_node(child, a:method, a:action)
    endfor
    if a:method == 'depthfirst' && !skip
      call call(a:action, [a:node])
    endif
    let self.depth -= 1
  endfunc

  func! todo.traverse_nodes(method, action) abort
    let self.depth = 0
    let self.result = []
    for child in self.root.children
      call self.traverse_node(child, a:method, a:action)
    endfor
    return self.result
  endfunc

  return todo
endfunction

function! todolist#parse(lines) abort
  let lines = type(a:lines) == type('') ? split(a:lines, "\n") : a:lines
  let nodes = []
  for line in lines
    let [depth, completion, text] = ['', '', '']
    if line =~ '^\*\+\s\+\['
      let [all, depth, completion, text ;rest] = matchlist(line, '^\(\*\+\)\s\+\[\([^\]]*\)\]\s*\(.*\)')
    else
      let [all, depth, text ;rest] = matchlist(line, '^\(\*\+\)\s\+\(.*\)')
    endif
    if completion =~ '^\s*$'
      let completion = ' '
    endif
    call add(nodes, todolist#node#new(len(depth), completion, text))
  endfor
  return nodes
endfunction

" Teardown:{{{1
"reset &cpo back to users setting
let &cpo = s:save_cpo

" Template From: https://github.com/dahu/Area-41/
" vim: set sw=2 sts=2 et fdm=marker:
