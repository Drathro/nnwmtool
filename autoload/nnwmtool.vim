"Name: nnwmtool.vim
"Description: NaNoWriMo tools plugin for VIM
"Author: Dan Wright
"Project Home Page: https://github.com/Drathro/nnwmtool

"Copyright 2017 Daniel Wright
"
"Permission is hereby granted, free of charge, to any person obtaining a
"copy of this software and associated documentation files (the "Software"),
"to deal in the Software without restriction, including without limitation
"the rights to use, copy, modify, merge, publish, distribute, sublicense,
"and/or sell copies of the Software, and to permit persons to whom the
"Software is furnished to do so, subject to the following conditions:
"
"The above copyright notice and this permission notice shall be included in
"all copies or substantial portions of the Software.
"
"THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
"IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
"FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
"AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
"LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
"FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
"DEALINGS IN THE SOFTWARE.

if exists("g:loaded_nnwmtool")
   finish
endif
let g:loaded_nnwmtool=1

"Purpose: Update NaNoWriMo word count
"Arguments: flag to skip confirmation (optional)
"Notes: User may predefine g:nnwmuser and g:nnwmkey
function nnwmtool#UpdateWC(...)
   let l:wc=wordcount()['words']
   let l:ok='y'
   if a:0<1
      let l:ok=input("Update word count to ".l:wc."? (Y/n): ")
   endif
   if match(l:ok,"^[Nn]$")<0
      call s:NnwmGetUser()
      call s:NnwmGetKey()
      let l:plaintext=g:nnwmkey.g:nnwmuser.l:wc
      let l:hash=hashdig#sha1(l:plaintext)
      redraw
      echo "Contacting NaNoWriMo server..."
      let [l:retval,l:errval]=s:PutRequest(g:nnwmuser,l:wc,l:hash)
      redraw
      echo s:GetResText(l:retval,l:errval)
   else
      redraw
      echo "Word Count Update cancelled."
   endif
endfunction

"Purpose: Reset in-memory storage of NaNoWriMo user and secret key values
function nnwmtool#ResetCred()
   unlet! g:nnwmuser
   unlet! g:nnwmkey
endfunction

"Purpose: Troubleshooting function that can take arbitrary input and display
"         the resulting sha1 hash.
"Side Effect: Clears credentials from memory.
function nnwmtool#TestHash()
   call nnwmtool#ResetCred()
   let l:wc=input("Word count test. Enter test word count: ")
   call s:NnwmGetUser()
   call s:NnwmGetKey()
   let l:hash=hashdig#sha1(g:nnwmkey.g:nnwmuser.l:wc)
   redraw
   let l:dummy=input('"'.g:nnwmkey.g:nnwmuser.l:wc.'"')
   redraw
   echo "hash=".l:hash.",name=".g:nnwmuser.",wc=".l:wc.",key='".g:nnwmkey."'"
   call nnwmtool#ResetCred()
endfunction

"Purpose: Sends the PUT request to the hardcoded word count url
"Arguments: NaNoWriMo user name,
"           current word count,
"           calculated hash digest
"Returns: list:
"           server response,
"           command line return value
function s:PutRequest(user,wc,hash)
   silent let l:retval=system("curl -s -L -d \"hash=".a:hash.
                             \"\" -d \"name=".a:user.
                             \"\" -d \"wordcount=".a:wc.
                             \"\" -X PUT https://nanowrimo.org/api/wordcount")
   return [l:retval,v:shell_error]
endfunction

"Purpose: Formats the results of the PUT request
"Arguments: server response,
"           command line return value
"Returns: Success or Error string with (hopefully) useful information
"Side Effects: If the return value indicates the user name is invalid,
"              variable g:nnwmuser is unset. 
"              If the return value indicates the resulting hash is invalid,
"              variable g:nnwmkey is unset.
function s:GetResText(retval,errval)
   if match(a:retval,'"wordcount"')>=0
      let l:wc=matchstr(matchstr(a:retval,'[0-9]*"}'),"[0-9]*")
      let l:priorwc=matchstr(matchstr(a:retval,'"old_wordcount"[^,]*'),
                            \"[0-9]*$")
      let l:diff=l:wc-l:priorwc
      if l:diff>=0
         let l:diff="+".l:diff
      endif
      return "Word count updated: ".l:wc." (".l:diff.")"
   endif
   if match(a:retval,"invalid user name")>=0
      unlet! g:nnwmuser
   endif
   if match(a:retval,"hash mismatch")>=0
      unlet! g:nnwmkey
   endif
   if a:errval!=0
      return "Error code ".a:errval.", ".a:retval
   endif
   return "Update failed: ".a:retval
endfunction

"Purpose: If defined, gets g:nnwmuser. If not, prompts to define and returns
"         the new value.
function s:NnwmGetUser()
   if !exists("g:nnwmuser")
      let g:nnwmuser=input("Enter NNWM User Name: ")
      return 1
   endif
   return 0
endfunction

"Purpose: If defined, gets g:nnwmkey. If not, prompts to define and returns
"         the new value.
function s:NnwmGetKey()
   if !exists("g:nnwmkey")
      let g:nnwmkey=input("Enter NNWM Secret Key: ")
      return 1
   endif
   return 0
endfunction

