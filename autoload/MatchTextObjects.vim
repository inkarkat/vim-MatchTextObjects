" MatchTextObjects.vim: Additional text objects for % matches.
"
" DEPENDENCIES:
"
" Copyright: (C) 2008-2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"	004	08-Jan-2013	Rename to MatchTextObjects.vim.
"				Change warning messages into either :echo or
"				error message.
"				Avoid clobbering search history with
"				:substitute.
"				Consistently beep on d%<Space> error.
"				Return status to enable repeating via
"				repeat.vim.
"	003	07-Jan-2013	Split off functions into autoload script.
"				Implement d%<Space> for non-matchit case.
"	002	11-Feb-2009	Now setting v:warningmsg on warning.
"	001	27-Jul-2008	Split off from textobjects.vim
"				file creation

function! s:ErrorMsg( text )
    let v:errmsg = a:text
    echohl ErrorMsg
    echomsg v:errmsg
    echohl None
endfunction

" Remove the matching pairs as identified by the '%' command.
if exists('g:loaded_matchit') && g:loaded_matchit
    function! s:MatchNum( expr, pattern )
	let l:matchCnt = 0
	let l:matchStart = 0
	while l:matchStart < len(a:expr)
	    let l:matchStart = match( a:expr, a:pattern, l:matchStart )
	    if l:matchStart == -1
		break
	    endif
	    let l:matchStart += 1
	    let l:matchCnt += 1
	endwhile
	return l:matchCnt
    endfunction
    function! s:Tally( matches, patterns )
	if ! exists('b:match_match')
	    " No actual match.
	    return
	endif

	let a:matches[ b:match_match ] = 1

	" The match patterns may themselves consist of multiple branches. Truly
	" separate each pattern, because these will later be processed.
	for l:matchPat in [ b:match_ini, b:match_tail ]
	    let l:splitPatterns = []
	    let l:pat = ''
	    for l:part in split( l:matchPat, '\\|' )
		let l:fullPat = l:pat . l:part
		if s:MatchNum(l:fullPat, '\\%\?(') > s:MatchNum(l:fullPat, '\\)')
		    " We split an inner (i.e. contained in a \() or \%() group)
		    " branch, which must be re-joined, as we're only interested
		    " in top-level branches.
		    let l:pat .= l:part . '\|'
		else
		    " The pattern is (now) complete, start over.
		    call add(l:splitPatterns, l:fullPat)
		    let l:pat = ''
		endif
	    endfor
	    for l:pat in l:splitPatterns
		let a:patterns[ l:pat ] = 1
	    endfor
	endfor
    endfunction
    function! s:ScalarCompareNumerical( i1, i2 )
	let l:n1 = 0 + a:i1
	let l:n2 = 0 + a:i2
	return l:n1 == l:n2 ? 0 : l:n1 > l:n2 ? 1 : -1
    endfunction
    function! s:ListComparePositions( i1, i2 )
	if a:i1[1] == a:i2[1]
	    " Same line, compare columns.
	    return a:i1[2] == a:i2[2] ? 0 : a:i1[2] > a:i2[2] ? 1 : -1
	else
	    return a:i1[1] > a:i2[1] ? 1 : -1
	endif
    endfunction
    function! s:GetUniqueLines( positions )
	let l:lines = {}
	for l:pos in a:positions
	    let l:lines[ l:pos[1] ] = 1
	endfor
	return keys(l:lines)
    endfunction
    function! s:DeleteLines( positions )
	" Delete unique lines from end to begin, so that the line numbers remain
	" valid throughout the operation.
	let l:lines = s:GetUniqueLines( a:positions )
	for l:line in reverse( sort(l:lines, 's:ScalarCompareNumerical') )
	    execute l:line . 'delete _'
	endfor
	echo len(l:lines) 'fewer lines'
    endfunction
    function! s:ProcessPatternForReplacement( pattern )
	" If the pattern does not start at the beginning, but somewhere in the
	" middle, the stored cursor position will be there, not at the beginning.
	" The 'html' filetype uses this to start the match at the tag name, not
	" the <.
	if a:pattern =~# '\\@<=' || a:pattern =~# '\\zs'
	    return substitute( a:pattern, '\\@<=', '\\%#', '' )
	endif

	" If the pattern already contains a cursor position match, do nothing.
	if a:pattern =~# '\\%#'
	    return a:pattern
	endif

	" The cursor must be at the beginning of the match, as we're restoring
	" the match position before deleting the match.
	return '\%#' . a:pattern
    endfunction
    function! s:DeleteMatches( positions, patterns )
	let l:sortedPositions = sort( a:positions, 's:ListComparePositions' )
"****D echomsg '**** sortPos' string(l:sortedPositions)
	let l:allPatterns = join( map( keys(a:patterns), 's:ProcessPatternForReplacement(v:val)'), '\|' )
"****D echomsg '**** allPat' l:allPatterns

	for l:pos in reverse(l:sortedPositions)
	    call setpos('.', l:pos)
	    " TODO: Check for collisions with + separator.
	    execute 'substitute+' . l:allPatterns . '++e'
	endfor
	call histdel('search', -1)
    endfunction

    function! MatchTextObjects#RemoveMatchingPair()
	let l:save_cursor = getpos('.')

	" Enable matchit debugging to get hold of the internal data.
	let b:match_debug = 1

	let l:positions = []
	let l:matches = {}
	let l:patterns = {}

	silent! normal g%
	let l:current = getpos('.')
	while index(l:positions, l:current) == -1
	    call add(l:positions, l:current)
	    call s:Tally(l:matches, l:patterns)
	    silent! normal %
	    let l:current = getpos('.')
	endwhile
	call s:Tally(l:matches, l:patterns)

echomsg '**** Found' string(l:positions)
echomsg '**** matches' string(keys(l:matches))
echomsg '**** patterns' string(keys(l:patterns))
	if len(l:matches) < 2
	    " Found no or only one part of a match.
	    let l:action = ''
	else
	    let l:maxMatchLen = max( map( keys(l:matches), 'len(v:val)' ) )
	    let l:isSimpleMatchPair = (len(l:positions) == 2 && (l:maxMatchLen == 1 || (l:maxMatchLen == 2 && sort(keys(l:matches)) == ['*/', '/*'])))
	    let l:isMultiLineMatch = (len(s:GetUniqueLines(l:positions)) > 1)
	    if ! l:isSimpleMatchPair && isMultiLineMatch
		" Query the user what exactly to delete.
		echohl Question
		echo len(l:positions) . ' matches found. Delete (m)atches or (l)ines? '
		echohl None
		while 1
		    let l:key = nr2char(getchar())
		    if l:key =~? '^[ml]$'
			let l:action = tolower(l:key)
			break
		    elseif l:key == "\<Esc>"
			let l:action = 'c'
			break
		    endif
		endwhile
	    else
		" For a simple matchpair, just remove the matchpair itself.
		let l:action = 'm'

		" Special rule: For C-style comments, also remove the inner
		" whitespace.
		if sort(keys(l:matches)) == ['*/', '/*']
		    let l:patterns = { '\s*\%#\*\/': 1, '\/\*\s*': 1 }
		endif
	    endif
	endif

	if empty(l:action)
	    call s:ErrorMsg('No matching pairs found')
	    execute "normal! \<C-\>\<C-n>\<Esc>" | " Beep.
	elseif l:action ==# 'c'
	    echo 'Canceled deletion of matchpairs'
	elseif l:action ==# 'm'
	    call s:DeleteMatches(l:positions, l:patterns)
	elseif l:action ==# 'l'
	    call s:DeleteLines(l:positions)
	else
	    throw 'ASSERT: Unhandled l:action: ' . l:action
	endif

	" Disable matchit debugging.
	unlet! b:match_debug
	unlet! b:match_pat b:match_match b:match_col b:match_wholeBR b:match_iniBR b:match_ini b:match_tail b:match_word b:match_table

	" Restore original cursor position.
	call setpos('.', l:save_cursor)

	return (! empty(l:action))
    endfunction
else
    " Note: The pairs are limited to the single characters of the 'matchpairs'
    " option, no C-style comments or preprocessor conditionals!
    function! MatchTextObjects#RemoveMatchingPair()
	let l:save_cursor = getpos('.')

	silent! normal! %
	let l:posA = getpos('.')
	silent! normal! %
	let l:posB = getpos('.')

	if l:posA == l:posB
	    call s:ErrorMsg('No matching pairs found')
	    execute "normal! \<C-\>\<C-n>\<Esc>" | " Beep.
	    return 0
	endif
	if l:posA[1] == l:posB[1] && l:posA[2] > l:posB[2]
	    " Position A is in the same line behind position B. Because of the same
	    " line, we need to delete from end to start (as removal of start would
	    " invalidate end position), so go back to A.
	    call setpos('.', l:posA)
	    " Swap positions.
	    let l:posA = l:posB
	endif
	normal! x
	call setpos('.', l:posA)
	normal! x

	call setpos('.', l:save_cursor)

	return 1
    endfunction
endif


function! s:GetPairPositions()
    silent! normal! %
    let l:posA = getpos('.')
    silent! normal! %
    let l:posB = getpos('.')

    if l:posA == l:posB
	return [[], []]
    elseif l:posA[1] > l:posB[1] || l:posA[1] == l:posB[1] && l:posA[2] > l:posB[2]
	" A is after B; swap positions.
	return [l:posB, l:posA]
    else
	return [l:posA, l:posB]
    endif
endfunction
function! MatchTextObjects#RemoveWhitespaceInsideMatchingPair()
    let l:save_view = winsaveview()

    let l:errormsg = 'No matching pairs found'
    while 1
	let [l:startMatch, l:endMatch] = s:GetPairPositions()
	if empty(l:startMatch)
	    break
	else
	    let l:errormsg = 'No matching pairs with inner whitespace found'
	endif

	let l:didRemoval = 0
	let l:whitespaceCol = match(strpart(getline(l:endMatch[1]), 0, l:endMatch[2] - 1), '\s\+$')
"****D echomsg '***e' string(l:endMatch) l:whitespaceCol
	if l:whitespaceCol != -1
	    call cursor(l:endMatch[1], l:whitespaceCol + 1)
	    normal! "_diw
	    let l:didRemoval = 1
	endif

	let l:whitespaceCol = match(getline(l:startMatch[1]), '^\S\zs\s\+', l:startMatch[2] - 1)
"****D echomsg '***s' string(l:startMatch) l:whitespaceCol
	if l:whitespaceCol != -1
	    call cursor(l:startMatch[1], l:whitespaceCol + 1)
	    normal! "_diw
	    let l:didRemoval = 1
	endif

	if l:didRemoval
	    return
	endif

	" No whitespace here, try again with enclosing matching pair, but only
	" in the current line, as % only searches there, too.
	call setpos('.', l:endMatch)
	if search('.', 'W', line('.')) == 0
	    break
	endif
    endwhile

    call winrestview(l:save_view)
    call s:ErrorMsg(l:errormsg)
    execute "normal! \<C-\>\<C-n>\<Esc>" | " Beep.
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
