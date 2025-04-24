 "...........////////.........USAGE...........//////////........."
 
 "...........Snippets.......................#..
 "flop    -> pastes code for dff
 "mod     -> pastes a module sceleton
 "clkf    -> pastes code for clock and failsafe finish
 "delayt  -> pastes code for a delay task

"............shotcuts (visual mode).............
"ctrl-c   -> comment/uncomment selected code
"ctrl-f   -> format selected port connection of instantiated modules
"tab      -> insert tab to selected text
"shift-tab-> remove tab from selected text

 
 "basic settings
 set number
 colorscheme slate
 set cursorline
 syntax on
 set wildmenu
 set wildmode=list:longest
 set tabstop=2
 set incsearch
 set autoindent
 set expandtab
 set filetype=verilog

syntax match sv_group /logic/
highlight sv_group guifg=CornflowerBlue gui=Bold
highlight comment guibg=white
highlight comment guifg=black

"Insert mode keymaps
" Automatically insert 'end' after typing 'begin'
inoremap begin begin<CR><CR>end
inoremap always always@()begin<CR><CR>end

"abbreviations for code snippets
iabbrev mod <Esc>: call Snippet(0)<CR>
iabbrev clkf <Esc>: call Snippet(1)<CR>
iabbrev delayt <Esc>: call Snippet(2)<CR>
iabbrev flop <Esc>: call Snippet(3)<CR>

"visual mode keyshortcuts
vnoremap <C-C> : call Com()<CR>
vnoremap <C-Tab> : call Add_tab()<CR>
vnoremap <S-Tab> : call Remove_tab()<CR>
vnoremap <C-F>  :<C-U> call Format(line("'<"), line("'>"))<CR>
vnoremap <C-I>  :<C-U> call Instantiate()<CR>
vnoremap c "+y

"code snippets
function! Snippet(serial)
    let prev_pos = getpos('.')
    let snip = " "
    "insert new template here
    if a:serial == 0
      let prev_pos[2] = 8 
      let snip = "module (\r\t\tinput logic clk,\r\t\tinput logic reset,\r\r);\r\rendmodule;/"
    elseif a:serial == 1
      let prev_pos[2] = 0
      call setpos('.', prev_pos)
      let snip =  "initial forever begin\r\t#5\r\tclk = \\~clk;\rend\rinitial forever begin\r\trepeat(5000)begin\r\t\t@posedge(clk);\r\tend\r\t$finish;\rend" 
    elseif a:serial == 2
      let snip = "task delay; (integer a)\r\trepeat(a)begin\r\t\t@(posedge clk);\r\tend\rendtask"
    elseif a:serial == 3
      let snip = "dff #(\r\t.RESET_VALUE(1'b0),\r\t.FLOP_WIDTH(1)\r)u_dff(\r\t.clk(clk),\r\t.reset_b(reset),\r\t.d(),\r\t.q()\r);"
    endif
    execute "." . "s/.*/" . snip
    call setpos('.', prev_pos)
    startinsert
endfunction

"Function to comment/uncomment sections in visual mode
"Select the portion and press Ctrl-C to comment/uncomment

function! Com()
  let cur_line  = getline(".")
  if cur_line !~ '^\s*//' 
    execute "." . "s/\\(.*\\)/\\/\\/\\1" 
  else 
    execute "." . "s/^\\(\\s*\\)\\/\\/\\(.*\\)/\\1\\2"
  endif
endfunction

"Adds tab to selected lines in visual mode
""Press tab after selecting lines
function! Add_tab()
  execute '.' . "s/\\(.*\\)/  \\1" 
endfunction

"Removes tab from the selected lines in visual mode
""Press shift-tab after selecting lines
function! Remove_tab()
  execute '.' . "s/  \\(.*\\)/\\1" 
endfunction

"paste the instantiation code of a module if the input-output ports are copied
"from the diclaration 
function! Instantiate()
  let snip = ""
  let clip_cont = getreg('"+y')
  let lines = split(clip_cont, "\n")
  echo len(lines)
  for i in range(0, len(lines)-1)
    let port = matchstr(lines[i], '\s*\(input\|output\)\s*logic\s*\(\[.*\]\)*\s*\zs\w*')
    if len(port) > 0
      let port2 = "." . port
      let snip = snip . "\r" . port2 ."(" . port . "),"
    else 
      let snip = snip . "\r"
    endif
  endfor
  execute "." . "s/.*/" . snip
  startinsert
endfunction


"........................////////////////////////////////////////////////////////.................
"
"Formats lines that have port connection such as '.clk(sclk) -> .clk( sclk  )'
"
"......................../////////////////////////////////////////////////////................


function! Format(start, end)
 
  let max_padd = 0
  let max_port = 0
  let max_pin  = 0


  " FIrst pass, getting the maximum port length and spacing
  for i in range(a:start, a:end)
 
	let pad = strlen(matchstr(getline(i), '\s*'))
	let port  = strlen(matchstr(getline(i), '\S*\ze\s*(.*)'))
	let pin  = strlen(matchstr(getline(i), '(\s*\zs\S\+\ze\s*)'))

	if max_padd < pad
  	let max_padd = pad
	endif
	
	if max_port < port
  	let max_port = port
	endif
 
	if max_pin < pin
  	let max_pin = pin
	endif
  
  endfor
 
  "second pass, going through the whole thing and fixing
  for i in range(a:start, a:end)

	let port  = matchstr(getline(i), '\S*\ze\s*(.*)')
	let pin  = matchstr(getline(i), '(\s*\zs\S*\ze\s*)')
	let pin_end = matchstr(getline(i), '(\s*\S\+\s*\zs).*')

	let sp1 = repeat(' ', max_padd)
	let sp2 = repeat(' ', max_port - strlen(port))
	let sp3 = repeat(' ', max_pin - strlen(pin))
	
	if strlen(port) > 0
 	
  	let line = sp1 . port . sp2 . " ( ". pin . sp3 . pin_end
 	
	execute i . "s/.*/". line .  "/g"
	endif
	
  endfor

endfunction

