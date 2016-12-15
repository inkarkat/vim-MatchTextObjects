" MatchTextObjects.vim: Additional text objects for % matches.
"
" DEPENDENCIES:
"   - ingo/cursor/move.vim autoload script
"   - ingo/err.vim autoload script
"
" Copyright: (C) 2008-2016 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"	009	05-May-2014	Abort on error.
"	008	20-Nov-2013	Need to use ingo#compat#setpos() to make a
"				selection in Vim versions before 7.3.590.
"	007	03-Jul-2013	Move ingocursormove.vim into ingo-library.
"	006	16-Feb-2013	Make s:GetPairPositionsAndLengths() public for
"				re-use by other plugins.
"				Rename variables to make their contents clearer.
"	005	09-Jan-2013	Factor start match end position correction out
"				of s:GetPairPositions() and rename to
"				s:GetPairPositionsAndLengths() to allow reuse
"				for ,% omap.
"				Add omap ,% via
"				MatchTextObjects#RemoveEndEditStartMotion().
"				Add vmap ,% via
"				MatchTextObjects#RemoveEndEditStartVisual().
"	004	08-Jan-2013	Rename to MatchTextObjects.vim.
"				Change warning messages into either :echo or
"				error message.
"				Avoid clobbering search history with
"				:substitute.
"				Don't clobber the default register with the last
"				deleted match line.
"				Consistently beep on d%<Space> error.
"				Return status to enable repeating via
"				repeat.vim.
"				Add matchit implementation of d%<Space>.
"				FIX: Do not remove one inner match (e.g. "!"
"				from b:match_words = "<:!:>" in "a!b!c") when
"				the start / end matches are missing. Ensure that
"				g% actually moves.
"	003	07-Jan-2013	Split off functions into autoload script.
"				Implement d%<Space> for non-matchit case.
"	002	11-Feb-2009	Now setting v:warningmsg on warning.
"	001	27-Jul-2008	Split off from textobjects.vim
"				file creation

function! s:SetErrorAndBeep( text )
    call ingo#err#Set(a:text)
    execute "normal! \<C-\>\<C-n>\<Esc>" | " Beep.
endfunction

function! s:ListComparePositions( i1, i2 )
    if a:i1[1] == a:i2[1]
	" Same line, compare columns.
	return a:i1[2] == a:i2[2] ? 0 : a:i1[2] > a:i2[2] ? 1 : -1
    else
	return a:i1[1] > a:i2[1] ? 1 : -1
    endif
endfunction
function! s:ProcessPatternForReplacement( pattern )
    " If the pattern does not start at the beginning, but somewhere in the
    " middle, the stored cursor position will be there, not at the beginning.
    " The 'html' filetype uses this to start the match at the tag name, not
    " the <.
    if a:pattern =~# '\\@<=' || a:pattern =~# '\\zs'
	return substitute(a:pattern, '\\@<=', '\\%#', '')
    endif

    " If the pattern already contains a cursor position match, do nothing.
    if a:pattern =~# '\\%#'
	return a:pattern
    endif

    " The cursor must be at the beginning of the match, as we're restoring
    " the match position before deleting the match.
    return '\%#' . a:pattern
endfunction
function! s:DeleteMatches( positions, patterns, what )
    let l:sortedPositions = sort(a:positions, 's:ListComparePositions')
"****D echomsg '**** sortPos' string(l:sortedPositions)
    let l:allPatterns = join(map(keys(a:patterns), 's:ProcessPatternForReplacement(v:val)'), '\|')
"****D echomsg '**** allPat' l:allPatterns

    let l:isLast = 1
    for l:idx in range(len(l:sortedPositions) - 1, 0, -1)
	let l:isFirst = (l:idx == 0)
	let l:pos = l:sortedPositions[l:idx]

	call setpos('.', l:pos)

	let l:search = l:allPatterns
	if a:what ==# 'i' && l:isLast || a:what ==# 'o' && l:isFirst
	    let l:search = '\s*\%(' . l:search . '\)'
	elseif a:what ==# 'i' && l:isFirst || a:what ==# 'o' && l:isLast
	    let l:search = '\%(' . l:search . '\)\s*'
	elseif a:what ==# 'i' || a:what ==# 'a'
	    let l:search = '\s*\%(' . l:search . '\)\s*'
	endif

	execute printf('substitute/%s//e', escape(l:search, '/'))

	let l:isLast = 0
    endfor

    call histdel('search', -1)
endfunction

if exists('g:loaded_matchit') && g:loaded_matchit
    function! s:MatchNum( expr, pattern )
	let l:matchCnt = 0
	let l:matchStart = 0
	while l:matchStart < len(a:expr)
	    let l:matchStart = match(a:expr, a:pattern, l:matchStart)
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
	    for l:part in split(l:matchPat, '\\|')
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
	let l:lines = s:GetUniqueLines(a:positions)
	for l:line in reverse(sort(l:lines, 's:ScalarCompareNumerical'))
	    execute l:line . 'delete _'
	endfor
	echo len(l:lines) 'fewer lines'
    endfunction
    function! MatchTextObjects#RemoveMatchingPair( what )
	let l:save_cursor = getpos('.')

	" Enable matchit debugging to get hold of the internal data.
	let b:match_debug = 1

	let l:positions = []
	let l:matches = {}
	let l:patterns = {}

	let l:current = getpos('.')
	silent! normal g%
	if l:current != getpos('.')
	    let l:current = getpos('.')
	    while index(l:positions, l:current) == -1
		call add(l:positions, l:current)
		call s:Tally(l:matches, l:patterns)
		silent! normal %
		let l:current = getpos('.')
	    endwhile
	    call s:Tally(l:matches, l:patterns)
	endif

"****D echomsg '**** Found' string(l:positions)
"****D echomsg '**** matches' string(keys(l:matches))
"****D echomsg '**** patterns' string(keys(l:patterns))
	if len(l:positions) < 2
	    " Found no or only one part of a match.
	    let l:action = ''
	else
	    let l:maxMatchLen = max(map(keys(l:matches), 'len(v:val)'))
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
	    endif
	endif

	if empty(l:action)
	    call s:SetErrorAndBeep('No matching pairs found')
	elseif l:action ==# 'c'
	    echo 'Canceled deletion of matchpairs'
	elseif l:action ==# 'm'
	    call s:DeleteMatches(l:positions, l:patterns, a:what)
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
    function! s:DeleteSingleCharacterMatches( positions )
	if a:positions[0][1] == a:positions[1][1] && a:positions[0][2] > a:positions[1][2]
	    " Position A is in the same line behind position B. Because of the same
	    " line, we need to delete from end to start (as removal of start would
	    " invalidate end position), so go back to A.
	    call setpos('.', a:positions[0])
	    " Swap positions.
	    let a:positions[0] = a:positions[1]
	endif
	normal! x
	call setpos('.', a:positions[0])
	normal! x
    endfunction
    function! MatchTextObjects#RemoveMatchingPair( what )
	let l:save_cursor = getpos('.')

	silent! normal! %
	let l:positions = [getpos('.')]
	silent! normal! %
	call add(l:positions, getpos('.'))

	if l:positions[0] == l:positions[1]
	    call s:SetErrorAndBeep('No matching pairs found')
	    return 0
	endif

	if empty(a:what)
	    call s:DeleteSingleCharacterMatches(l:positions)
	else
	    call s:DeleteMatches(l:positions, {'\%#.': 1}, a:what) " The cursor position anchors the pattern to the actual matching character, no need to extract it from the buffer.
	endif

	call setpos('.', l:save_cursor)

	return 1
    endfunction
endif


if exists('g:loaded_matchit') && g:loaded_matchit
    function! MatchTextObjects#GetPairPositionsAndLengths()
	let l:pairPositionsAndLengths = [[], 0, [], 0]

	" Enable matchit debugging to get hold of the internal data.
	let b:match_debug = 1

	let l:positions = []
	let l:lengths = []

	let l:current = getpos('.')
	silent! normal g%
	if exists('b:match_match') && l:current != getpos('.')
	    let l:current = getpos('.')
	    while index(l:positions, l:current) == -1
		call add(l:positions, l:current)
		call add(l:lengths, len(b:match_match))
		silent! normal %
		let l:current = getpos('.')
	    endwhile
	    call add(l:lengths, len(b:match_match))

	    " b:match_match is for the original position before the jump, so
	    " positions and (previous position's) lengths need to be combined with
	    " an offset.
	    let l:positionsAndLengths = []
	    for l:i in range(len(l:positions))
		call add(l:positionsAndLengths, l:positions[l:i] + [l:lengths[l:i + 1]])
	    endfor
"****D echomsg '**** Found' string(l:positionsAndLengths)
	    if len(l:positionsAndLengths) >= 2
		let l:sortedPositionsAndLengths = sort(l:positionsAndLengths, 's:ListComparePositions')
		let l:pairPositionsAndLengths = [l:positionsAndLengths[0][0:3], l:positionsAndLengths[0][4], l:positionsAndLengths[-1][0:3], l:positionsAndLengths[-1][4]]
	    endif
	endif

	" Disable matchit debugging.
	unlet! b:match_debug
	unlet! b:match_pat b:match_match b:match_col b:match_wholeBR b:match_iniBR b:match_ini b:match_tail b:match_word b:match_table
"****D echomsg '****' string(l:pairPositionsAndLengths)
	return l:pairPositionsAndLengths
    endfunction
else
    function! s:GetCharacterLength( position )
	return len(matchstr(getline(a:position[1]), printf('\%%%dc.', a:position[2])))
    endfunction
    function! MatchTextObjects#GetPairPositionsAndLengths()
	silent! normal! %
	let l:posA = getpos('.')
	silent! normal! %
	let l:posB = getpos('.')

	if l:posA == l:posB
	    return [[], 0, [], 0]
	elseif l:posA[1] > l:posB[1] || l:posA[1] == l:posB[1] && l:posA[2] > l:posB[2]
	    " A is after B; swap positions.
	    return [l:posB, s:GetCharacterLength(l:posB), l:posA, s:GetCharacterLength(l:posA)]
	else
	    return [l:posA, s:GetCharacterLength(l:posA), l:posB, s:GetCharacterLength(l:posB)]
	endif
    endfunction
endif

function! MatchTextObjects#RemoveWhitespaceInsideMatchingPair()
    let l:save_view = winsaveview()

    let l:errormsg = 'No matching pairs found'
    while 1
	let [l:startMatchPos, l:startLength, l:endMatchPos, l:endLength] = MatchTextObjects#GetPairPositionsAndLengths()
	if empty(l:startMatchPos)
	    break
	else
	    let l:errormsg = 'No matching pairs with inner whitespace found'
	endif

	let l:didRemoval = 0
	let l:whitespaceCol = match(strpart(getline(l:endMatchPos[1]), 0, l:endMatchPos[2] - 1), '\s\+$')
"****D echomsg '***e' string(l:endMatchPos) l:whitespaceCol
	if l:whitespaceCol != -1
	    call cursor(l:endMatchPos[1], l:whitespaceCol + 1)
	    normal! "_diw
	    let l:didRemoval = 1
	endif


	" Use last character position of the start marker, not the first, as
	" this checks for whitespace immediately after the start marker.
	let l:startMatchEndPos = l:startMatchPos[2] + l:startLength - 1

	let l:whitespaceCol = match(getline(l:startMatchPos[1]), '^\S\zs\s\+', l:startMatchEndPos - 1)
"****D echomsg '***s' string(l:startMatchPos) string(l:startLength) l:whitespaceCol
	if l:whitespaceCol != -1
	    call cursor(l:startMatchPos[1], l:whitespaceCol + 1)
	    normal! "_diw
	    let l:didRemoval = 1
	endif

	if l:didRemoval
	    return 1
	endif

	" No whitespace here, try again with enclosing matching pair, but only
	" in the current line, as % only searches there, too.
	call setpos('.', l:endMatchPos)
	if search('.', 'W', line('.')) == 0
	    break
	endif
    endwhile

    call winrestview(l:save_view)
    call s:SetErrorAndBeep(l:errormsg)
    return 0
endfunction


function! MatchTextObjects#RemoveEndEditStartMotion( ... )
    let l:save_cursor = getpos('.')
    let l:save_view = winsaveview()

    let [l:startMatchPos, l:startLength, l:endMatchPos, l:endLength] = MatchTextObjects#GetPairPositionsAndLengths()
    if empty(l:startMatchPos)
	call winrestview(l:save_view)
	call s:SetErrorAndBeep('No matching pairs found')
	return 0
    elseif l:startMatchPos[1] < l:save_cursor[1] || l:startMatchPos[1] == l:save_cursor[1] && l:startMatchPos[2] < l:save_cursor[2]
	call winrestview(l:save_view)
	call s:SetErrorAndBeep('Cursor not before, but inside matching pairs')
	return 0
    endif

    " Remove the end match.
    let l:line = getline(l:endMatchPos[1])
    call setline(l:endMatchPos[1], strpart(l:line, 0, l:endMatchPos[2] - 1) . strpart(l:line, l:endMatchPos[2] + l:endLength - 1))

    call winrestview(l:save_view)

    " Move the cursor to the end of the start match, then one after it, so that
    " the operator works on the text from the original position to the end of
    " the start match.
    let l:startMatchEndPos = l:startMatchPos
    let l:startMatchEndPos[2] += l:startLength - 1
    call setpos('.', l:startMatchEndPos)
    if ! a:0 || ! a:1
	call ingo#cursor#move#Right()
    endif

    return 1
endfunction
function! MatchTextObjects#RemoveEndEditStartVisual()
    let l:save_cursor = getpos('.')
    if MatchTextObjects#RemoveEndEditStartMotion(&selection !=# 'exclusive')
	call ingo#compat#setpos("'<", l:save_cursor)
	call ingo#compat#setpos("'>", getpos('.'))
	normal! gv
    endif
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
