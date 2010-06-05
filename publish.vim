" Vim plug-in
" Maintainer: Peter Odding <peter@peterodding.com>
" Last Change: June 5, 2010
" URL: http://peterodding.com/code/vim/publish
" License: MIT
" Version: 1.5

" Support for automatic update using the GLVS plug-in.
" GetLatestVimScripts: 2252 1 :AutoInstall: publish.zip

" Don't source the plug-in when its already been loaded or &compatible is set.
if &cp || exists('g:loaded_publish')
  finish
endif

if !exists('g:publish_omit_dothtml')
  let g:publish_omit_dothtml = 0
endif

if !exists('g:publish_plaintext')
  let g:publish_plaintext = 0
endif

function! Publish(source, target, files) abort
  call s:Message("Preparing to publish file%s ..", len(a:files) == 1 ? '' : 's')
  let s:files_to_publish = publish#resolve_files(a:source, a:files)
  let s:tags_to_publish = publish#find_tags(s:files_to_publish)
  if s:tags_to_publish != {}
    let tags_to_links_command = publish#create_subst_cmd(s:tags_to_publish)
  endif
  call publish#prep_env(1)
  for pathname in a:files
    let source_path = xolox#path#merge(a:source, pathname)
    let suffix = g:publish_omit_dothtml ? '' : '.html'
    let target_path = xolox#path#merge(a:target, pathname . suffix)
    call s:Message("Publishing %s", string(pathname))
    if !publish#create_dirs(target_path)
      return
    endif
    " Save the pathname of the directory containing the source file in a
    " script-local variable so that s:ConvertTagToLink() has access to it.
    let given_source = s:FindOriginalPath(source_path)
    let s:current_source_directory = fnamemodify(given_source, ':h')
    silent execute 'edit!' fnameescape(source_path)
    silent execute 'doautocmd User PublishPre' fnameescape(source_path)
    if g:publish_plaintext
      let plaintext_path = xolox#path#merge(a:target, pathname . '.txt')
      silent execute 'write!' fnameescape(plaintext_path)
    endif
    runtime syntax/2html.vim
    if exists('tags_to_links_command')
      silent execute tags_to_links_command
    endif
    call publish#customize_html(pathname)
    silent execute 'write!' fnameescape(target_path)
    bwipeout!
  endfor
  call publish#prep_env(0)
  unlet s:files_to_publish s:tags_to_publish
  let [msg, nfiles] = ["publish.vim: Published %i file%s to %s.", len(a:files)]
  call s:Message(msg, nfiles, nfiles == 1 ? '' : 's', string(a:target))
endfunction

function! s:FindOriginalPath(pathname) " {{{1
  let key = xolox#path#absolute(a:pathname)
  return get(s:files_to_publish, key, '')
endfunction

function! s:Message(...) " {{{1
  try
    redraw
    echohl title
    echomsg call('printf', a:000)
  finally
    echohl none
  endtry
endfunction

function! s:ConvertTagToLink(name) " {{{1
  " Convert each occurrence of every tag into a hyperlink that points to the
  " location where the tag is defined. Since the hyperlinks are relative they
  " work on the local file system just as well as on a web server.
  try
    " Strip HTML from matched text and use result to find tag info.
    let entry = s:tags_to_publish[substitute(a:name, '<[^>]\+>', '', 'g')]
    " Convert the fully resolved pathname back into the one given by the user.
    let pathname = s:FindOriginalPath(entry.filename)
    " Now convert that pathname into a relative hyperlink with an anchor.
    let relative = xolox#path#relative(pathname, s:current_source_directory)
    let suffix = g:publish_omit_dothtml ? '' : '.html'
    return '<a href="' . relative . suffix . '#l' . entry.cmd . '">' . a:name . '</a>'
  catch
    return a:name
  endtry
endfunction

let g:loaded_publish = 1

" vim: ts=2 sw=2 et
