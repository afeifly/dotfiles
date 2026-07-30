set clipboard=unnamed,unnamedplus

" Map jk to Escape in insert mode
inoremap jk <Esc>

" --- Seamless Tmux-Vim Navigation ---
function! TmuxMove(direction)
    let l:winnr = winnr()
    execute 'wincmd ' . a:direction
    if l:winnr == winnr()
        let l:tmux_direction = {'h': 'L', 'j': 'D', 'k': 'U', 'l': 'R'}[a:direction]
        let l:command = "tmux select-pane -" . l:tmux_direction
        call system(l:command)
    endif
endfunction

nnoremap <silent> <C-h> :call TmuxMove('h')<cr>
nnoremap <silent> <C-j> :call TmuxMove('j')<cr>
nnoremap <silent> <C-k> :call TmuxMove('k')<cr>
nnoremap <silent> <C-l> :call TmuxMove('l')<cr>

