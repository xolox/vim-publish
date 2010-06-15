Here's some things in the nice-to-have department:

 * Build a JavaScript color scheme switcher :-)

 * Hyperlink stuff like Vim functions in Vim scripts and Python standard
   library identifiers in Python scripts to their online documentation?

 * I once wrote a PHP script that created fancy looking dynamic directory
   listings for trees of source code published using a previous incarnation of
   this plug-in. You can [see it in action][autoindex]. Should I reincarnate
   that script as an add-on for the Vim plug-in that generates static index
   pages which don't need PHP but work just as well?

 * Automatically generate a temporary tags file up front? (So I don't have to
   rerun the plug-in when I break my [easytags.vim][easytags] plug-in which
   also breaks the hyperlinking feature of `publish.vim`.

 * Create an option to publish to a temporary local directory, create a tarball
   from the published files, upload the tarball to a remote location and unpack
   it there because establishing SFTP connections has quite a lot of overhead?


[autoindex]: http://peterodding.com/code/vim/profile
[easytags]: http://peterodding.com/code/vim/easytags
