# Publish hyperlinked, syntax highlighted source code with Vim

The [Vim text editor](http://www.vim.org/) includes the script [2html.vim](http://vimdoc.sourceforge.net/htmldoc/syntax.html#2html.vim) which can be used to convert a syntax highlighted buffer in Vim to an HTML document that, when viewed in a web browser, should look exactly the same. After using that script for a while and discovering the excellent [Exuberant Ctags](http://ctags.sourceforge.net/) I wondered *"Wouldn't it be nice to have those tags converted to hyperlinks when I publish source code as HTML?"*.

After several attempts I managed a working prototype, but it was quite rough around the edges and I didn't really have the time or interest to clean it up. Several months later I found myself with some free time and a renewed interest in Vim scripting so I decided to clean up my code and release it. If you're wondering what the result looks like, I've published [the plug-in source code](http://peterodding.com/code/vim/profile/plugin/publish.vim) as a demonstration.

## Installation & usage

Unzip the most recent [ZIP archive](http://peterodding.com/code/vim/downloads/publish.zip) file inside your Vim profile directory (usually this is `~/.vim` on UNIX and `%USERPROFILE%\vimfiles` on Windows), restart Vim and execute the command `:helptags ~/.vim/doc` (use `:helptags ~\vimfiles\doc` instead on Windows). As an example we'll publish the plug-in using itself. First create a tags file that contains entries for the files you want to publish using a shell command such as:

    $ ctags -Rf ~/.publish_tags ~/.vim/

If this doesn't work because [ctags](http://vimdoc.sourceforge.net/htmldoc/tagsrch.html#ctags) isn't installed you can download it from the [Exuberant Ctags homepage](http://ctags.sourceforge.net/), or if you're running Debian/Ubuntu you can install it by executing the following shell command:

    $ sudo apt-get install exuberant-ctags

The plug-in needs an up-to-date tags file so that it can create hyperlinks between the published files. Now start Vim and write a script that registers the tags file you just created and calls the function `Publish()` as follows:

    :set tags=~/.publish_tags
    :let sources = '/home/peter/.vim'
    :let target = 'sftp://peterodding.com/code/vim/profile'
    :call Publish(sources, target, [
        \ 'autoload/xolox/escape.vim',
        \ 'autoload/xolox/path.vim',
        \ 'autoload/publish.vim',
        \ 'plugin/publish.vim',
        \ ])

Change the `sources` and `target` variables to reflect your situation, save the script as `~/publish_test.vim` and try it in Vim by executing the command `:source ~/publish_test.vim`. If everything goes well Vim will be busy for a moment and after that you will find a bunch of syntax highlighted, interlinked HTML documents in the `target` directory!

## Publishing to a remote location (website)

As you can see from the example above it's possible to publish files directly to your web server using the [netrw plug-in](http://vimdoc.sourceforge.net/htmldoc/pi_netrw.html#netrw) that's bundled with Vim, simply by starting the `target` path with `sftp://`. All you need for this to work is the ability to establish [SCP](http://en.wikipedia.org/wiki/Secure_copy) connections to your server. There are however two disadvantages to remote publishing over [SFTP](http://en.wikipedia.org/wiki/SSH_file_transfer_protocol):

1. The `publish.vim` plug-in can't automatically create directories on the remote side, which means you'll have to do so by hand -- very bothersome.

2. It can take a while to publish a dozen files because a new connection is established for every file that's uploaded to the remote location.

As a workaround to both of these issues the `publish.vim` plug-in will automatically use [rsync](http://en.wikipedia.org/wiki/rsync) when both the local and remote system have it installed. This cuts the time to publish to a remote location in half and enables the plug-in to automatically create directories on the remote side.

## Contact

If you have questions, bug reports, suggestions, etc. the author can be contacted at <peter@peterodding.com>. The latest version is available at <http://peterodding.com/code/vim/publish/> and <http://github.com/xolox/vim-publish>. If you like the script please vote for it on [Vim Online](http://www.vim.org/scripts/script.php?script_id=2252).

## License

This software is licensed under the [MIT license](http://en.wikipedia.org/wiki/MIT_License).  
© 2011 Peter Odding &lt;<peter@peterodding.com>&gt;.
