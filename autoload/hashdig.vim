"Name: hashdig.vim, Vim global plugin for generating hashed message digests
"Creator: Daniel Wright
"License: MIT license
"Project Home Page: https://github.com/Drathro/hashdig
"Note: sha1 algorithm adapted from FIPS Publication 180-4

"MIT License
"
"Copyright (c) 2017 Daniel Wright
"
"Permission is hereby granted, free of charge, to any person obtaining a copy
"of this software and associated documentation files (the "Software"), to deal
"in the Software without restriction, including without limitation the rights
"to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
"copies of the Software, and to permit persons to whom the Software is
"furnished to do so, subject to the following conditions:
"
"The above copyright notice and this permission notice shall be included in all
"copies or substantial portions of the Software.
"
"THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
"IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
"FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
"AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
"LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
"OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
"SOFTWARE.

if exists("g:loaded_hashdig")
    finish
endif
let g:loaded_hashdig=1

let s:WIDTHMASK32=0xFFFFFFFF
let s:SHA1BITS=32
let s:SHA1BLOCKSIZE=512

function hashdig#sha1(inputText)
"Purpose: sha1 digest
"Args: input string
"Returns: sha1 digest string
    let l:H=s:sha1InitHash()
    let l:M=s:sha1PreprocessText(a:inputText)
    for i in range(1,len(l:M)*s:SHA1BITS/s:SHA1BLOCKSIZE)
        "step 1 Prepare message schedule
        let [l:M,l:W]=s:sha1UpdateSched(l:M)
        "step 2 set working values
        let a=l:H[0]
        let b=l:H[1]
        let c=l:H[2]
        let d=l:H[3]
        let e=l:H[4]
        "step 3
        for t in range(0,79)
            let l:temp=s:Mask32(s:rotl32(a,5)+
                               \s:sha1FSubT(t,b,c,d)+
                               \e+
                               \s:sha1KSubT(t)+
                               \l:W[t])
            let e=d
            let d=c
            let c=s:rotl32(b,30)
            let b=a
            let a=l:temp
        endfor
        "step 4 Compute new hash
        let l:H[0]=s:Mask32(a+l:H[0])
        let l:H[1]=s:Mask32(b+l:H[1])
        let l:H[2]=s:Mask32(c+l:H[2])
        let l:H[3]=s:Mask32(d+l:H[3])
        let l:H[4]=s:Mask32(e+l:H[4])
    endfor
    return printf("%08x%08x%08x%08x%08x",l:H[0],l:H[1],l:H[2],l:H[3],l:H[4])
endf
        
function s:sha1InitHash()
"Purpose: Returns list of inital hash values
"Returns: list of words
    return [0x67452301,0xEFCDAB89,0x98BADCFE,0x10325476,0xC3D2E1F0]
endfunction

function s:sha1PreprocessText(text)
"Purpose: Converts text to ascii values and pads to a multiple of sha1 block
"         size
"Args: input string
"Returns: input text as list of words
    let l=strlen(a:text)*8
    let k=s:SHA1BLOCKSIZE - ((l+8) % s:SHA1BLOCKSIZE)
    if k<64
        let k+=s:SHA1BLOCKSIZE
    endif
    let k-=64
    let k=k/8
    let l:byteList=[]
    for i in range(0,len(a:text)-1)
        let l:byteList+=[char2nr(a:text[i])]
    endfor
    let l:byteList+=[0x80]+repeat([0],k)
    let l:wordList=[]
    for i in range(0,len(l:byteList)-1,4)
        let l:word=0
        for j in range(0,2)
            let l:word=or(l:word,l:byteList[i+j])
            let l:word=s:ShiftL(l:word,8)
        endfor
        let l:word=or(l:word,l:byteList[i+3])
        let l:wordList+=[l:word]
    endfor
    let l:upperL=s:ShiftR(l,32)
    let l:lowerL=s:Mask32(l)
    return l:wordList+[l:upperL]+[l:lowerL]
endfunction

function s:sha1UpdateSched(M)
"Purpose: Populates sha1 schedule W for each block of input
"         Processed blocks are removed from word list M
"Args: input word list M
"Returns: list:
"          sha1 schedule W
"          input word list M
    let l:pW=[]
    for item in a:M[0:15]
        call add(l:pW,item)
    endfor
    let l:pM=a:M[16:]
    for l:t in range(16,79)
        call add(l:pW,s:rotl32(xor(l:pW[t-16],
                                  \xor(l:pW[t-14],
                                      \xor(l:pW[t-3],l:pW[t-8])))
                              \,1))
    endfor
    return[l:pM,l:pW]
endfunction

function s:sha1Ch(x,y,z)
"Purpose:  sha1 function "Ch"
    return xor(and(a:x,a:y),and(invert(a:x),a:z))
endfunction

function s:sha1Parity(x,y,z)
"Purpose:  sha1 function "Parity"
    return xor(xor(a:x,a:y),a:z)
endfunction

function s:sha1Maj(x,y,z)
"Purpose:  sha1 function "Maj"
    return xor(xor(and(a:x,a:y),and(a:x,a:z)),and(a:y,a:z))
endfunction

function s:sha1FSubT(t,x,y,z)
"Purpose: sha1 function selector
"Args: iteration int, int, int, int
    if a:t<0
        return 0
    elseif a:t<20
        return s:sha1Ch(a:x,a:y,a:z)
    elseif a:t<40
        return s:sha1Parity(a:x,a:y,a:z)
    elseif a:t<60
        return s:sha1Maj(a:x,a:y,a:z)
    elseif a:t<80
        return s:sha1Parity(a:x,a:y,a:z)
    else
        return 0
    endif
endfunction

function s:sha1KSubT(t)
"Purpose: sha1 constant K selector
"Args: iteration int
    if a:t<0
        return 0
    elseif a:t<20
        return 0x5A827999
    elseif a:t<40
        return 0x6ED9EBA1
    elseif a:t<60
        return 0x8F1BBCDC
    elseif a:t<80
        return 0xCA62C1D6
    else
        return 0
endfunction

function s:rotl32(value,shiftwidth)
"Purpose: rotate 32 bit value left shiftwidth positions
"Args: word, int
"Returns: word
    if (a:shiftwidth<0)
        return a:value
    elseif a:shiftwidth>=s:SHA1BITS
        let l:shiftmod=float2nr(fmod(a:shiftwidth,s:SHA1BITS))
    else
        let l:shiftmod=a:shiftwidth
    endif
    return or(s:ShiftL(a:value,l:shiftmod),
             \s:ShiftR(a:value,s:SHA1BITS-l:shiftmod))
endfunction

function s:Mask32(value)
"Returns: value mod 2^32
    return and(a:value,s:WIDTHMASK32)
endfunction

function s:ShiftR(value,shiftwidth)
"Purpose: shift 32 bit word right shiftwidth positions
"Args: word
"Returns: word
    let l:newval=a:value
    for i in range(1,a:shiftwidth)
        let l:newval=l:newval/2
        if s:WIDTHMASK32<0
            let l:newval=and(l:newval,0x7FFFFFFF)
        endif
    endfor
    return l:newval
endfunction

function s:ShiftL(value,shiftwidth)
"Purpose: shift 32 bit word left shiftwidth positions
"Args: word
"Returns: word
    if a:shiftwidth>=s:SHA1BITS
        return 0
    endif
    let l:newval=a:value
    for i in range(1,a:shiftwidth)
        let l:newval=l:newval*2
    endfor
    let l:newval=s:Mask32(l:newval)
    return l:newval
endfunction

