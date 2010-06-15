# Publish hyperlinked, syntax highlighted source code with Vim

The [Vim text editor] [vim] includes the script [2html.vim] [2html] which can
be used to convert a syntax highlighted buffer in Vim to an HTML document that,
when viewed in a web browser, should look exactly the same. After using that
script for a while and discovering the excellent [Exuberant Ctags] [ctags] I
wondered *"Wouldn't it be nice to have those tags converted to hyperlinks when
I publish source code as HTML?"*.

After several attempts I managed a working prototype, but it was quite rough
around the edges and I didn't really have the time or interest to clean it up.
Several months later I found myself with some free time and a renewed interest
in Vim scripting so I decided to clean up my code and release it. If you're
wondering what the result looks like, I've published [the plug-in source code]
[demo] as a demonstration.

## Installation & usage

Unzip the most recent [ZIP archive] [zip] file inside your Vim profile
directory (usually this is `~/.vim` on UNIX and `%USERPROFILE%\vimfiles` on
Windows). As an example we'll publish the plug-in using itself. First create a
tags file that contains entries for the files you want to publish using a shell
command such as:

    ctags -Rf ~/.publish_tags ~/.vim/

If this doesn't work because `ctags` isn't installed you can download it from
the [Exuberant Ctags homepage] [ctags], or if you're running Debian/Ubuntu you
can install it by executing the following shell command:

    sudo apt-get install exuberant-ctags

The plug-in needs an up-to-date tags file so that it can create hyperlinks
between the published files. Now start Vim and write a script that registers
the tags file you just created and calls the function `Publish()` as follows:

    set tags=~/.publish_tags
    let sources = '/home/peter/.vim'
    let target = 'sftp://peterodding.com/code/vim/profile'
    call Publish(sources, target, [
        \ 'autoload/xolox/escape.vim',
        \ 'autoload/xolox/path.vim',
        \ 'autoload/publish.vim',
        \ 'plugin/publish.vim',
        \ ])

Change the `sources` and `target` variables to reflect your situation, save the
script as `~/publish_test.vim` and execute it in Vim by typing `:source
~/publish_test.vim` and pressing `Enter↵`. If everything goes well Vim will be
busy for a moment and after that you will find a bunch of syntax highlighted,
interlinked HTML documents in the `target` directory!

## Contact

If you have questions, bug reports, suggestions, etc. the author can be
contacted at <peter@peterodding.com>. The latest version is available
at <http://peterodding.com/code/vim/publish> and <http://github.com/xolox/vim-publish>.
If you like the script please vote for it on [www.vim.org] [vim_scripts_entry].

## License

This software is licensed under the [MIT license] [license].<br>
© 2010 Peter Odding &lt;<peter@peterodding.com>&gt;.


[2html]: http://ftp.vim.org/vim/runtime/syntax/2html.vim
[ctags]: http://ctags.sourceforge.net/
[demo]: http://peterodding.com/code/vim/profile/plugin/publish.vim
[license]: http://en.wikipedia.org/wiki/MIT_License
[vim]: http://www.vim.org/
[vim_scripts_entry]: http://www.vim.org/scripts/script.php?script_id=2252
[zip]: http://peterodding.com/code/vim/download.php?script=publish
