" Vim script
" Author: Peter Odding <peter@peterodding.com>
" Last Change: May 20, 2013
" URL: http://peterodding.com/code/vim/publish/

let g:xolox#publish#version = '1.7.12'

call xolox#misc#compat#check('publish.vim', g:xolox#publish#version, 7)

function! xolox#publish#resolve_files(directory, pathnames) " {{{1
  " Create a dictionary that maps the fully resolved pathnames of the files to
  " be published to the absolute pathnames provided by the user. This enables
  " the script to gracefully handle symbolic links which I use a lot :-)
  let resolved_files = {}
  for pathname in a:pathnames
    let pathname = xolox#misc#path#merge(a:directory, pathname)
    let absolute = fnamemodify(pathname, ':p')
    let resolved_files[resolve(absolute)] = absolute
  endfor
  return resolved_files
endfunction

function! xolox#publish#update_tags(pathnames) " {{{1
  " Integration with easytags.vim to automatically create/update tags for all
  " files before they're published, see http://peterodding.com/code/vim/easytags/
  if exists('g:loaded_easytags')
    call easytags#update(1, 0, a:pathnames)
  endif
endfunction

function! xolox#publish#find_tags(files_to_publish) " {{{1
  " Given a dictionary like the one created above, this function will filter
  " the results of taglist() to remove irrelevant entries. In the process tag
  " search ex-commands are converted into line numbers.
  let start = xolox#misc#timer#start()
  let num_duplicates = 0
  let tags_to_publish = {}
  let s:cached_contents = {}
  for entry in taglist('.')
    let pathname = xolox#misc#path#absolute(entry.filename)
    if has_key(a:files_to_publish, pathname) && s:pattern_to_lnum(entry, pathname)
      if !has_key(tags_to_publish, entry.name)
        let tags_to_publish[entry.name] = entry
      else
        let num_duplicates += 1
        let other = tags_to_publish[entry.name]
        if entry.filename == other.filename && entry.lnum < other.lnum
          let tags_to_publish[entry.name] = entry
        endif
        if num_duplicates <= 3
          let tag_name = string(entry.name)
          let this_path = string(entry.filename)
          let other_path = string(other.filename)
          let msg = "publish.vim %s: Ignoring duplicate tag %s! (duplicate is in %s, first was in %s)"
          call xolox#misc#msg#warn(msg, g:xolox#publish#version, tag_name, this_path, other_path)
        endif
      endif
    endif
  endfor
  if num_duplicates > 3
    let more = num_duplicates - 3
    let msg = "publish.vim: %s Ignored %s more duplicate tag%s!"
    call xolox#misc#msg#warn(msg, g:xolox#publish#version, more, more == 1 ? '' : 's')
  endif
  unlet s:cached_contents
  let msg = "publish.vim %s: Found %i tag%s to publish in %s."
  let numtags = len(tags_to_publish)
  call xolox#misc#timer#stop(msg, g:xolox#publish#version, numtags, numtags != 1 ? 's' : '', start)
  return tags_to_publish
endfunction

function! s:pattern_to_lnum(entry, pathname) " {{{2
  " Tag file entries can refer to source file locations with line numbers and
  " search patterns. Since search patterns are more flexible I use those, but
  " the plug-in needs absolute line numbers, so this function converts search
  " patterns into line numbers.
  if a:entry.cmd =~ '^\d\+$'
    let a:entry.lnum = a:entry.cmd + 0
    return 1
  else
    if !has_key(s:cached_contents, a:pathname)
      let contents = readfile(a:pathname)
      let s:cached_contents[a:pathname] = contents
    else
      let contents = s:cached_contents[a:pathname]
    endif
    " Convert tag search command to plain Vim pattern, based on :help tag-search.
    let pattern = a:entry.cmd
    let pattern = matchstr(pattern, '^/^\zs.*\ze$/$')
    let pattern = '^' . xolox#misc#escape#pattern(pattern) . '$'
    try
      let index = match(contents, pattern)
    catch
      throw "Failed pattern: " . string(pattern)
    endtry
    if index >= 0
      let a:entry.lnum = index + 1
      return 1
    endif
  endif
endfunction

function! xolox#publish#create_subst_cmd(tags_to_publish) " {{{1
  " Generate a :substitute command that, when executed, replaces tags with
  " hyperlinks using a callback. This is complicated somewhat by the fact that
  " tag names won't always appear literally in the output of 2html.vim, for
  " example the names of Vim autoload functions can appear as:
  " 
  "   foo#bar#<span class=Normal>baz</span>
  " 
  let patterns = []
  let slfunctions = []
  for name in keys(a:tags_to_publish)
    let entry = a:tags_to_publish[name]
    if get(entry, 'language') == 'Vim'
      let is_slfunc = '\s\(s:\|<[Ss][Ii][Dd]>\)' . xolox#misc#escape#pattern(name) . '\s*('
      if get(entry, 'cmd') =~ is_slfunc
        call add(slfunctions, xolox#misc#escape#pattern(name))
        continue
      endif
    endif
    call add(patterns, xolox#misc#escape#pattern(name))
  endfor
  call insert(patterns, '\%(\%(&lt;[Ss][Ii][Dd]&gt;\|s:\)\%(' . join(slfunctions, '\|') . '\)\)')
  let tag_names_pattern = escape(join(patterns, '\|'), '/')
  " Gotcha: Use \w\@<! and \w\@! here instead of \< and \> which won't work.
  return '%s/[A-Za-z0-9_]\@<!\%(' . tag_names_pattern . '\)[A-Za-z0-9_]\@!/\=s:ConvertTagToLink(submatch(0))/eg'
endfunction

function! xolox#publish#munge_syntax_items() " {{{1
  " Tag to hyperlink conversion only works when tag names appear literally in
  " the output of 2html.vim while this isn't always the case in Vim scripts.
  if &filetype == 'vim'
    syntax match vimFuncName /\<s:\w\+\>/ containedin=vim.*
    syntax match vimFuncName /\c<Sid>\w\+\>/ containedin=vim.*
  endif
endfunction

function! xolox#publish#rsync_check(target) " {{{1
  let start = xolox#misc#timer#start()
  let result = ''
  let matches = matchlist(a:target, '^sftp://\([^/]\+\)\(.*\)$')
  if len(matches) >= 3
    let host = matches[1]
    let path = substitute(matches[2], '^/', '', '')
    let result = xolox#misc#os#exec({'command': 'rsync --version', 'check': 0})
    if result['exit_code'] == 0
      let result = xolox#misc#os#exec({'command': 'ssh ' . host . ' rsync --version', 'check': 0})
      if result['exit_code'] == 0
        let result = host . ':' . path
      endif
    endif
  endif
  call xolox#misc#timer#stop("publish.vim %s: Checked rsync support in %s.", g:xolox#publish#version, start)
  return result
endfunction

function! xolox#publish#run_rsync(target, tempdir) " {{{1
  let start = xolox#misc#timer#start()
  let target = fnameescape(a:target . '/')
  let tempdir = fnameescape(a:tempdir . '/')
  call xolox#misc#msg#info("publish.vim %s: Uploading files to %s using rsync.", g:xolox#publish#version, a:target)
  execute '!rsync -vr' tempdir target
  call xolox#misc#timer#stop("publish.vim %s: Finished uploading in %s.", g:xolox#publish#version, start)
  if v:shell_error
    throw "publish.vim: Failed to run rsync!"
  endif
endfunction

function! xolox#publish#create_dirs(target_path) " {{{1
  " If the directory where the files are published resides on the local file
  " system then try to automatically create any missing directories because
  " creating those directories by hand quickly gets tiresome.
  if a:target_path !~ '://'
    let current_directory = fnamemodify(a:target_path, ':h')
    if !isdirectory(current_directory)
      silent! call mkdir(current_directory, 'p')
      if !isdirectory(current_directory)
        let msg = "Failed to create directory %s! What now?"
        if confirm(printf(msg, string(current_directory)), "&Abort\n&Ignore") == 1
          let msg = "publish.vim %s: Failed to create %s, aborting .."
          call xolox#misc#msg#warn(msg, g:xolox#publish#version, string(current_directory))
          return 0
        else
          let msg = "publish.vim %s: Failed to create %s, ignoring .."
          call xolox#misc#msg#warn(msg, g:xolox#publish#version, string(current_directory))
          continue
        endif
      endif
    endif
  endif
  return 1
endfunction

function! xolox#publish#prep_env(enable) " {{{1

  " Change the environment before publishing and restore afterwards.

  " Avoid E325 when publishing files that are currently being edited in Vim.
  augroup PluginPublish
    autocmd!
    if a:enable
      autocmd SwapExists * let v:swapchoice = 'e'
    endif
  augroup END

  " Avoid the hit-enter prompt!
  if a:enable
    let s:more_save = &more
    set nomore
  else
    let &more = s:more_save
  endif

  " Avoid triggering automatic commands intended to update `Last changed'
  " headers and such by executing :write commands, because the source files
  " aren't actually modified but only copied. I can't use :noautocmd :write
  " for this because that would disable remote publishing through the netrw
  " plug-in! Therefor I've resorted to the following:
  if a:enable
    let s:ei_save = &eventignore
    set eventignore=BufWritePre
  else
    let &eventignore = s:ei_save
  endif

  " Avoid E488 which happens when you publish using netrw, overwriting
  " previously published files that contain modelines.
  if a:enable
    let s:mls_save = &modelines
    set modelines=0
  else
    let &modelines = s:mls_save
  endif

  " Instruct the 2html script to add line numbers that we'll transform into
  " anchors which are used as the targets of hyperlinks created from tags.
  " Also instruct the 2html script to use CSS which we will modify to improve
  " the appearance of hyperlinks (so they inherit the highlighting color).
  " Finally ignore any text folding until I find out how to get the dynamic
  " JavaScript text folding to work.
  if a:enable
    let s:hif_save = exists('g:html_ignore_folding') ? g:html_ignore_folding : 0
    let s:hnl_save = exists('g:html_number_lines') ? g:html_number_lines : 0
    let s:huc_save = exists('g:html_use_css') ? g:html_use_css : 0
    let g:html_ignore_folding = 1
    let g:html_number_lines =  1
    let g:html_use_css = 1
  else
    let g:html_ignore_folding = s:hif_save
    let g:html_number_lines =  s:hnl_save
    let g:html_use_css =  s:huc_save
  endif

endfunction

function! xolox#publish#customize_html(page_title) " {{{1

  " Change document title to relative pathname.
  silent keepjumps %s@<title>\zs.*\ze</title>@\=xolox#publish#html_encode(a:page_title)@e

  " Insert CSS to remove the default colors and underline from hyper links
  " and to remove any padding between the browser chrome and page content.
  let custom_css = "\nhtml, body, pre { margin: 0; padding: 0; }"
  let custom_css .= "\na:link, a:visited { color: inherit; text-decoration: none; }"
  let custom_css .= "\npre:hover a:link, pre:hover a:visited { text-decoration: underline; }"
  let custom_css .= "\na:link span, a:visited span { text-decoration: inherit; }"
  let custom_css .= "\n.lnr a:link, .lnr a:visited { text-decoration: none !important; }"
  silent keepjumps %s@\ze\_s\+-->\_s\+</style>@\= "\n" . custom_css@e

  " Add link anchors to line numbering.
  silent keepjumps %s@<span class="lnr">\zs\s*\(\d\+\)\s*\ze</span>@<a name="l\1" href="#l\1">\0</a>@eg

endfunction

function! xolox#publish#html_encode(s) " {{{1
  let s = substitute(a:s, '&', '\&amp;', 'g')
  let s = substitute(s, '<', '\&lt;', 'g')
  let s = substitute(s, '>', '\&gt;', 'g')
  return s
endfunction

" vim: ts=2 sw=2 et
