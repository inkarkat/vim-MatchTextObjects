" MatchTextObjects.vim: Additional text objects for % matches.
"
" DEPENDENCIES:
"   - MatchTextObjects.vim autoload script
"   - ingo/err.vim autoload script
"   - repeat.vim (vimscript #2136) autoload script (optional)
"
" Copyright: (C) 2008-2018 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"	008	20-Jul-2018	ENH: Add d%l variant. d%% does query for removal
"                               of matches or lines, but only for complex match
"                               pairs; we cannot remove lines containing { and
"                               } with it, for example. (Also for complex match
"                               pairs, it may be desirable to avoid the query.)
"	007	16-Dec-2016	ENH: Add d%i, d%o, d%a variants of d%% that
"				remove certain whitespace as well. d%% drops the
"				special rule for C-style comments.
"	006	05-May-2014	Abort on error.
"	005	09-Jan-2013	Add omap ,% and vmap ,%.
"	004	08-Jan-2013	Rename to MatchTextObjects.vim.
"				Enable repeating via repeat.vim.
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
let s:save_cpo = &cpo
set cpo&vim

" Note: Need to make the no-op modification only when necessary to keep the
" original repeat.vim sequence enabled when this mapping errors out; otherwise,
" b:changedtick is incremented, turning off repeat.vim.
nnoremap <silent> <Plug>(MatchTextObjectsRemovePair)        :<C-u>
\if !&ma<Bar><Bar>&ro<Bar>call setline('.', getline('.'))<Bar>endif<Bar>
\if MatchTextObjects#RemoveMatchingPair('')<Bar>
\   silent! call repeat#set("\<lt>Plug>(MatchTextObjectsRemovePair)")<Bar>
\else<Bar>
\   echoerr ingo#err#Get()<Bar>
\endif<CR>
nnoremap <silent> <Plug>(MatchTextObjectsRemovePairInner)   :<C-u>
\if !&ma<Bar><Bar>&ro<Bar>call setline('.', getline('.'))<Bar>endif<Bar>
\if MatchTextObjects#RemoveMatchingPair('i')<Bar>
\   silent! call repeat#set("\<lt>Plug>(MatchTextObjectsRemovePairInner)")<Bar>
\else<Bar>
\   echoerr ingo#err#Get()<Bar>
\endif<CR>
nnoremap <silent> <Plug>(MatchTextObjectsRemovePairOuter)   :<C-u>
\if !&ma<Bar><Bar>&ro<Bar>call setline('.', getline('.'))<Bar>endif<Bar>
\if MatchTextObjects#RemoveMatchingPair('o')<Bar>
\   silent! call repeat#set("\<lt>Plug>(MatchTextObjectsRemovePairOuter)")<Bar>
\else<Bar>
\   echoerr ingo#err#Get()<Bar>
\endif<CR>
nnoremap <silent> <Plug>(MatchTextObjectsRemovePairAll)   :<C-u>
\if !&ma<Bar><Bar>&ro<Bar>call setline('.', getline('.'))<Bar>endif<Bar>
\if MatchTextObjects#RemoveMatchingPair('a')<Bar>
\   silent! call repeat#set("\<lt>Plug>(MatchTextObjectsRemovePairAll)")<Bar>
\else<Bar>
\   echoerr ingo#err#Get()<Bar>
\endif<CR>
nnoremap <silent> <Plug>(MatchTextObjectsRemovePairLines)   :<C-u>
\if !&ma<Bar><Bar>&ro<Bar>call setline('.', getline('.'))<Bar>endif<Bar>
\if MatchTextObjects#RemoveMatchingPair('l')<Bar>
\   silent! call repeat#set("\<lt>Plug>(MatchTextObjectsRemovePairLines)")<Bar>
\else<Bar>
\   echoerr ingo#err#Get()<Bar>
\endif<CR>
nnoremap <silent> <Plug>(MatchTextObjectsRemoveWhitespace) :<C-u>
\if !&ma<Bar><Bar>&ro<Bar>call setline('.', getline('.'))<Bar>endif<Bar>
\if MatchTextObjects#RemoveWhitespaceInsideMatchingPair()<Bar>
\   silent! call repeat#set("\<lt>Plug>(MatchTextObjectsRemoveWhitespace)")<Bar>
\else<Bar>
\   echoerr ingo#err#Get()<Bar>
\endif<CR>

if ! hasmapto('<Plug>(MatchTextObjectsRemovePair)', 'n')
    nmap d%% <Plug>(MatchTextObjectsRemovePair)
endif
if ! hasmapto('<Plug>(MatchTextObjectsRemovePairInner)', 'n')
    nmap d%i <Plug>(MatchTextObjectsRemovePairInner)
endif
if ! hasmapto('<Plug>(MatchTextObjectsRemovePairOuter)', 'n')
    nmap d%o <Plug>(MatchTextObjectsRemovePairOuter)
endif
if ! hasmapto('<Plug>(MatchTextObjectsRemovePairAll)', 'n')
    nmap d%a <Plug>(MatchTextObjectsRemovePairAll)
endif
if ! hasmapto('<Plug>(MatchTextObjectsRemovePairLines)', 'n')
    nmap d%l <Plug>(MatchTextObjectsRemovePairLines)
endif
if ! hasmapto('<Plug>(MatchTextObjectsRemoveWhitespace)', 'n')
    nmap d%<Space> <Plug>(MatchTextObjectsRemoveWhitespace)
endif

onoremap <silent> <Plug>(MatchTextObjectsRemoveEndEditStartMotion) :<C-u>if ! MatchTextObjects#RemoveEndEditStartMotion()<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
vnoremap <silent> <Plug>(MatchTextObjectsRemoveEndEditStartMotion) :<C-u>if ! MatchTextObjects#RemoveEndEditStartVisual()<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
if ! hasmapto('<Plug>(MatchTextObjectsRemoveEndEditStartMotion)', 'o')
    omap ,% <Plug>(MatchTextObjectsRemoveEndEditStartMotion)
endif
if ! hasmapto('<Plug>(MatchTextObjectsRemoveEndEditStartMotion)', 'x')
    xmap ,% <Plug>(MatchTextObjectsRemoveEndEditStartMotion)
endif

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
