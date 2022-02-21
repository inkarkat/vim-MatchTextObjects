MATCH TEXT OBJECTS
===============================================================================
_by Ingo Karkat_

DESCRIPTION
------------------------------------------------------------------------------

This plugin defines a d%% command (and more specific variants) which remove
the matching pairs (determined via the % command and the 'matchpairs'
option), but not the content in between. With support of the matchit plugin,
more complex user-defined matches (like HTML tags or "if-else-endif") can also
be deleted. For these complex matches, either only the match or the complete
matching lines can be removed. The latter can be useful e.g. to remove C
preprocessor #ifdef...#endif directives. The matches function as quasi "text
objects" (even though they aren't such, and only work with the delete
operator).
,% is another special "text object" that is mostly used with delete and change
operators, and works on the text up to the start match, but also deletes the
end match. This is very useful on function invocations, so d,% changes
```
    foo(bar);
```
to
    foo;~

### SOURCE

- [d%&lt; has been inspiration](https://stackoverflow.com/questions/58503153/vim-delete-parent-parenthesis-and-reindent-child)

### SEE ALSO
(Plugins offering complementary functionality, or plugins using this library.)

### RELATED WORKS
(Alternatives from other authors, other approaches, references not used here.)

USAGE
------------------------------------------------------------------------------

    d%%                     Remove matching pair characters.
                            Complex matchit plugin matches can also be deleted.
                            The plugin asks whether only the match or the complete
                            matching lines should be removed. This is useful to
                            e.g. remove HTML tags or #ifdef..#endif directives.
    d%i                     Remove matching pair characters, and any whitespace
                            inside.
    d%o                     Remove matching pair characters, and any whitespace
                            outside.
    d%a                     Remove matching pair characters, and all whitespace
                            around them, both inside and outside.
    d%l                     Remove all complete lines that contain matching pair
                            characters.
    d%<                     Remove all complete lines that contain matching pair
                            characters, and dedent the remaining lines inside the
                            pair.

    d%<Space>               Remove the whitespace inside the next matching pair
                            that contains whitespace.
                            For example, turns
                                foo( bar, baz(a, b), quux )
                            into
                                foo(bar, baz(a, b), quux)

    ,%                      Motion that jumps to the end match, deletes it, then
                            operates on the text from the original position to the
                            (and including the) start match.
                            For example, turns
                                |foo(bar, baz(a, b), quux)
                            into
                                |bar, baz(a, b), quux

    {Visual},%              Delete the end match, then select the text from the
                            original position to the (and including the) start
                            match.

INSTALLATION
------------------------------------------------------------------------------

The code is hosted in a Git repo at
    https://github.com/inkarkat/vim-MatchTextObjects
You can use your favorite plugin manager, or "git clone" into a directory used
for Vim packages. Releases are on the "stable" branch, the latest unstable
development snapshot on "master".

This script is also packaged as a vimball. If you have the "gunzip"
decompressor in your PATH, simply edit the \*.vmb.gz package in Vim; otherwise,
decompress the archive first, e.g. using WinZip. Inside Vim, install by
sourcing the vimball or via the :UseVimball command.

    vim MatchTextObjects*.vmb.gz
    :so %

To uninstall, use the :RmVimball command.

### DEPENDENCIES

- Requires Vim 7.0 or higher.
- Requires the ingo-library.vim plugin ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)), version 1.044 or
  higher.

CONFIGURATION
------------------------------------------------------------------------------

For a permanent configuration, put the following commands into your vimrc:
configvar

plugmap

INTEGRATION
------------------------------------------------------------------------------

Plain Vim can only match single-character pairs like ( and ), [ and ]. With
the matchit plugin, arbitrary pairs (also tuples like if..else..endif) can
be matched. This plugin recognizes matchit and then uses its advanced
detection to handle those complex pairs, too.

TODO
------------------------------------------------------------------------------

- d%&lt;Space&gt;: Also remove newlines after / before matches.

### CONTRIBUTING

Report any bugs, send patches, or suggest features via the issue tracker at
https://github.com/inkarkat/vim-MatchTextObjects/issues or email (address
below).

HISTORY
------------------------------------------------------------------------------

##### GOAL
First published version.

##### 0.01    28-Jul-2008
- Started development.

------------------------------------------------------------------------------
Copyright: (C) 2008-2022 Ingo Karkat -
The [VIM LICENSE](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license) applies to this plugin.

Maintainer:     Ingo Karkat &lt;ingo@karkat.de&gt;
