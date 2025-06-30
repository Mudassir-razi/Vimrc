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
 syntax enable
 set wildmenu
 set wildmode=list:longest
 set tabstop=2
 set incsearch
 set autoindent
 set expandtab
 set filetype=verilog


" Set terminal GUI colors (safe in gVim)
"colorscheme desert          " or your preferred colorscheme


"autocmd BufReadPost * hi Normal ctermbg=none guibg=#0e1630

" Force colorscheme to apply after GUI loads
"autocmd GUIEnter * set background=dark | colorscheme desert


function! Col()
syntax enable
set filetype=verilog
syntax match sv_group /logic/
hi Normal ctermbg=none guibg=#0e1630
highlight sv_group guifg=LightGreen gui=Bold
highlight sv_group2 guifg =RED gui=Bold
highlight comment guibg=white
highlight comment guifg=black
endfunction
autocmd BufReadPost * call Col()

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
vnoremap <C-Tab> : call Add_tab()<CR>gv
vnoremap <S-Tab> : call Remove_tab()<CR>gv
xnoremap <silent> <C-F>  :<C-U> call Format(line("'<"), line("'>"))<CR>gv
vnoremap <C-I>  :<C-U> call Instantiate()<CR>
vnoremap <C-W>  :<C-U> call InstantiateWire()<CR>
vnoremap <silent> <C-R>  :<C-U> call RemoveDuplicate(line("'<"), line("'>"))<CR>
vnoremap c "+y

"code snippets
function! Snippet(serial)
    let prev_pos = getpos('.')
    let snip = " "
    "insert new template here
    if a:serial == 0
      let prev_pos[2] = 8 
      let snip = "module (\r\t\tinput logic clk,\r\t\tinput logic reset,\r\r);\r\rendmodule/"
    elseif a:serial == 1
      let prev_pos[2] = 0
      call setpos('.', prev_pos)
      let snip =  "initial forever begin\r\t#5\r\tclk = \\~clk;\rend\rinitial forever begin\r\trepeat(5000)begin\r\t\t@posedge(clk);\r\tend\r\t$finish;\rend" 
    elseif a:serial == 2
      let snip = "task delay; (integer a)\r\trepeat(a)begin\r\t\t@(posedge clk);\r\tend\rendtask"
    elseif a:serial == 3
      let snip = "dff #(\r\t.RESET_VALUE(1'b0),\r\t.FLOP_WIDTH(1)\r)u_(\r\t.clk(clk),\r\t.reset_b(reset),\r\t.d(),\r\t.q()\r);"
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
  execute '.' . "s/\\(.*\\)/ \\1" 
endfunction

"Removes tab from the selected lines in visual mode
""Press shift-tab after selecting lines
function! Remove_tab()
  execute '.' . "s/ \\(.*\\)/\\1" 
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

"paste the logic instantiation. 
"Just omits the input output
function! InstantiateWire()
  let snip = ""
  let clip_cont = getreg('"+y')
  let lines = split(clip_cont, "\n")
  echo len(lines)
  for i in range(0, len(lines)-1)
    let port = matchstr(lines[i], '\s*\(input\|output\)\s*logic\s*\zs.*\ze,$')
    if len(port) > 0
      let port2 = "." . port
      let snip = snip . "\r" ."logic " . port . ";"
    else 
      let snip = snip . "\r"
    endif
  endfor
  execute "." . "s/.*/" . snip
  startinsert
endfunction



"........................////////////////////////////////////////////////////////.................

"Formats lines that have port connection such as '.clk(sclk) -> .clk( sclk  )'

"......................../////////////////////////////////////////////////////................


function! Format(start, end)
 
  let max_padd = 0
  let max_port = 0
  let max_pin  = 0
  let type     = 0

" Trying to figure out which type of formatting is needed

  for i in range(a:start, a:end)
    if  strlen(matchstr(getline(i), '\S*=\S*'))
      let type = 3
      break
    elseif strlen(matchstr(getline(i), '\s*logic'))
      let type = 2
      break
    elseif strlen(matchstr(getline(i), '\S*\ze\s*(.*)'))
      let type = 1
      break
    endif
  endfor
  echo type

  if type == 1
    " FIrst pass, getting the maximum port length and spacing
    for i in range(a:start, a:end)
      let pad = strlen(matchstr(getline(i), '^\s*'))
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
   	
    	let line = sp1 . port . sp2 . " ( ". pin . sp3 . " " . pin_end
   	
  	execute i . "s/.*/". line .  "/g"
  	endif
  	
    endfor

  "Type two formatting. module port declaration format
  elseif type == 2
    let maxpad = 0
    let maxinout = 0
    let maxlogic = 0
    let maxport = 0
    "First pass
    for i in range(a:start,a:end)
      let pad     = matchstr(getline(i), '\s*')
    	let inout   = matchstr(getline(i), '\s*\zs\(input\|output\)*\ze\s\+')
    	let logic   = matchstr(getline(i), '\s*\(input\|output\)*\s*\zslogic\s*\(\[.*\]\)*\ze\s*')
      let port    = matchstr(getline(i), '\s*\(input\|output\)*\s*logic\s*\(\[.*\]\)*\s*\zs.*')

      if strlen(pad) > strlen(maxpad)
        let maxpad = pad
      endif

      if strlen(inout) > strlen(maxinout)
        let maxinout = inout
      endif

      if strlen(logic) > strlen(maxlogic)
        let maxlogic = logic
      endif
      
      if strlen(port) > strlen(maxport)
        let maxport = port
      endif 
    endfor
    "Second pass
    for i in range(a:start, a:end)
      let inout   = matchstr(getline(i), '\s*\zs\(input\|output\)*\ze\s\+')
    	let logic   = matchstr(getline(i), '\s*\(input\|output\)*\s*\zslogic\s*\(\[.*\]\)*\ze\s*')
      let port    = matchstr(getline(i), '\s*\(input\|output\)*\s*logic\s*\(\[.*\]\)*\s*\zs.*')
    
      let sp1 = repeat(' ', strlen(maxpad))
      let sp3 = repeat(' ', strlen(maxinout) - strlen(inout))
    	let sp2 = repeat(' ', strlen(maxlogic) - strlen(logic))
      let line= sp1 . inout . sp3 . ' ' . logic . ' ' . sp2 . port
      execute i . "s/.*/". line . "/g"

    endfor
" Type three formatting
   elseif type == 3
    let maxpad = ''
    let maxlhs = ''
    let maxrhs = ''
    for i in range(a:start,a:end)
      let pad   = matchstr(getline(i), '^\s*')
    	let lhs   = matchstr(getline(i), '^\s*\zs[^=]\{-}\ze\s*<*=')
    	let rhs   = matchstr(getline(i), '^\s*[^=]\{-}\s*<*=\s*\zs.*\ze$')
      let lhs = matchstr(lhs, '^\zs.\{-}\ze\s*$')
      if strlen(pad) > strlen(maxpad)
        let maxpad = pad
      endif

      if strlen(lhs) > strlen(maxlhs)
        let maxlhs = lhs
      endif

      if strlen(rhs) > strlen(maxrhs)
        let maxrhs = rhs
      endif

    endfor
    for i in range(a:start, a:end)
    	let lhs   = matchstr(getline(i), '^\s*\zs[^=]\{-}\ze\s*<*=') 
      let lhs = matchstr(lhs, '^\zs.\{-}\ze\s*$')
    	let rhs   = matchstr(getline(i), '^\s*[^=]*\s*<*=\s*\zs.*\ze')
      let op = matchstr(getline(i), '^.\{-}\zs<*=\ze.*')
      let sp1   = repeat(' ', strlen(maxlhs) - strlen(lhs) + 1)
      let line = maxpad . lhs . sp1 . op . ' ' . rhs
      if strlen(lhs) > 0 
        call setline(i, line)
      endif
    endfor
  endif

endfunction

function! RemoveDuplicate(start, end)

  for i in range(a:start, a:end)
    let actual = matchstr(getline(i), '\s*logic\s*\zs\S*\ze\s*;$')
  endfor

endfunction

