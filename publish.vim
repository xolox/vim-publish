" Vim plug-in
" Author: Peter Odding <peter@peterodding.com>
" Last Change: September 6, 2010
" URL: http://peterodding.com/code/vim/publish/
" License: MIT
" Version: 1.7.1

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
  let start = xolox#timer#start()
  call xolox#message("Preparing to publish file%s ..", len(a:files) == 1 ? '' : 's')
  let s:files_to_publish = publish#resolve_files(a:source, a:files)
  call publish#update_tags(values(s:files_to_publish))
  let s:tags_to_publish = publish#find_tags(s:files_to_publish)
  if s:tags_to_publish != {}
    let tags_to_links_command = publish#create_subst_cmd(s:tags_to_publish)
  endif
  let rsync_target = publish#rsync_check(a:target)
  if rsync_target != ''
    let rsync_dir = xolox#path#tempdir()
  endif
  let target_dir = rsync_target != '' ? rsync_dir : a:target
  call publish#prep_env(1)
  for pathname in a:files
    let source_path = xolox#path#merge(a:source, pathname)
    let suffix = g:publish_omit_dothtml ? '' : '.html'
    let target_path = xolox#path#merge(target_dir, pathname . suffix)
    call xolox#message("Publishing %s", string(pathname))
    if !publish#create_dirs(target_path)
      return
    endif
    " Save the pathname of the directory containing the source file in a
    " script-local variable so that s:ConvertTagToLink() has access to it.
    let given_source = s:FindOriginalPath(source_path)
    let s:current_source_directory = fnamemodify(given_source, ':h')
    silent execute 'edit!' fnameescape(source_path)
    if g:publish_plaintext
      let plaintext_path = xolox#path#merge(target_dir, pathname . '.txt')
      silent execute 'write!' fnameescape(plaintext_path)
    endif
    " Highlight tags in current buffer using easytags.vim?
    if exists('g:loaded_easytags')
      HighlightTags
    endif
    let highlight_start = xolox#timer#start()
    call publish#munge_syntax_items()
    runtime syntax/2html.vim
    let msg = "publish.vim: The 2html.vim script took %s to highlight %s."
    call xolox#timer#stop(msg, highlight_start, pathname)
    if exists('tags_to_links_command')
      let tags_to_links_start = xolox#timer#start()
      silent execute tags_to_links_command
      let msg = "publish.vim: Finished converting tags in %s to links in %s."
      call xolox#timer#stop(msg, pathname, tags_to_links_start)
    endif
    call publish#customize_html(pathname)
    silent execute 'write!' fnameescape(target_path)
    bwipeout!
  endfor
  unlet s:files_to_publish s:tags_to_publish
  if rsync_target != ''
    call publish#run_rsync(rsync_target, rsync_dir)
  endif
  let msg = "publish.vim: Published %i file%s to %s."
  call xolox#message(msg, len(a:files), len(a:files) == 1 ? '' : 's', a:target)
  call xolox#timer#stop("Finished publishing files in %s.", start)
  call publish#prep_env(0)
endfunction

function! s:FindOriginalPath(pathname) " {{{1
  let key = xolox#path#absolute(a:pathname)
  return get(s:files_to_publish, key, '')
endfunction

function! s:ConvertTagToLink(name) " {{{1
  " Convert each occurrence of every tag into a hyperlink that points to the
  " location where the tag is defined. Since the hyperlinks are relative they
  " work on the local file system just as well as on a web server.
  try
    " Strip HTML from matched text and use result to find tag info.
    let text = substitute(a:name, '<[^>]\+>', '', 'g')
    if has_key(s:tags_to_publish, text)
      let entry = s:tags_to_publish[text]
    else
      let text = substitute(text, '^\(s:\|&lt;[Ss][Ii][Dd]&gt;\)', '', 'g')
      let entry = s:tags_to_publish[text]
    endif
    " Convert the fully resolved pathname back into the one given by the user.
    let pathname = s:FindOriginalPath(entry.filename)
    " Now convert that pathname into a relative hyperlink with an anchor.
    " TODO This is likely to be slow so cache the results?!
    let relative = xolox#path#relative(pathname, s:current_source_directory)
    let suffix = g:publish_omit_dothtml ? '' : '.html'
    let href = publish#html_encode(relative . suffix . '#l' . entry.lnum)
    return '<a href="' . href . '">' . a:name . '</a>'
  catch
    return a:name
  endtry
endfunction

let g:loaded_publish = 1

" vim: ts=2 sw=2 et
