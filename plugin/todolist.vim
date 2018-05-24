function! s:parse_attributes(...)
  let attributes = {}
  for arg in a:000
    if !empty(arg)
      if arg =~ '[=:]'
        let [attr, val] = split(arg, '[=:]')
        call extend(attributes, {attr : val})
      endif
    endif
  endfor
  return attributes
endfunction

function! TodoParse(first_line, last_line, ...)
  " echo a:first_line . ' ' . a:last_line . ' ' . string(a:000)
  let items = todolist#parse(getline(a:first_line, a:last_line))
  if ! empty(items)
    let attributes = call('s:parse_attributes', a:000)
    let l = todolist#new(attributes)
    call l.add_nodes(items)
    call l.calculate_completion()
    return l
  else
    return {}
  endif
endfunction

function! TodoFormat(...) range
  let l = call('TodoParse', extend([a:firstline, a:lastline], a:000))
  if l != {}
    call append(a:lastline, l.render())
    silent exe a:firstline . ',' . a:lastline . 'd'
  endif
endfunction

function! TodoGraph(...) range
  let l = call('TodoParse', extend([a:firstline, a:lastline], a:000))
  if l != {}
    enew
    call setline(1, l.graph(bufname('#')))
  endif
endfunction


function! TodoFormatDefaults(...)
  let attributes = call('s:parse_attributes', a:000)
  call todolist#set_attribute_defaults(attributes)
endfunction

nnoremap <leader>lf vip:TodoFormat<cr>
command! -range -bar -nargs=* -complete=customlist,todolist#command_complete TodoFormat <line1>,<line2> call TodoFormat(<f-args>)
command!        -bar -nargs=* -complete=customlist,todolist#command_complete TodoFormatDefaults call TodoFormatDefaults(<f-args>)

