" MatchTextObjects.vim: Additional text objects for % matches.
"
" DEPENDENCIES:
"   - MatchTextObjects.vim autoload script
"
" Copyright: (C) 2008-2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"	004	08-Jan-2013	Rename to MatchTextObjects.vim.
"	003	07-Jan-2013	Split off functions into autoload script.
"				Handle no-modifiable error and readonly warning.
"	002	11-Feb-2009	Now setting v:warningmsg on warning.
"	001	27-Jul-2008	Split off from textobjects.vim
"				file creation

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_MatchTextObjects') || (v:version < 700)
    finish
endif
let g:loaded_MatchTextObjects = 1

nnoremap <silent> <Plug>(MatchTextObjectsRemovePair)       :<C-u>call setline('.', getline('.'))<Bar>call MatchTextObjects#RemoveMatchingPair()<CR>
nnoremap <silent> <Plug>(MatchTextObjectsRemoveWhitespace) :<C-u>call setline('.', getline('.'))<Bar>call MatchTextObjects#RemoveWhitespaceInsideMatchingPair()<CR>
if ! hasmapto('<Plug>(MatchTextObjectsRemovePair)', 'n')
    nmap d%% <Plug>(MatchTextObjectsRemovePair)
endif
if ! hasmapto('<Plug>(MatchTextObjectsRemoveWhitespace)', 'n')
    nmap d%<Space> <Plug>(MatchTextObjectsRemoveWhitespace)
endif

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
