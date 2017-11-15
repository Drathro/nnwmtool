# nnwmtool.vim

## Introduction
The nnwmtool Vim plugin provides a word count updater for use with [National Novel Writing Month](https://nanowrimo.org).

## Prerequisites
The nnwmtool plugin uses command line tool "curl" to communicate with the NaNoWriMo server. If curl is not available on your system, see https://curl.haxx.se/download.html

## Installation
Should install the same as any other plugin. Untested, but may work with:
* Vundle
* VimPlug
* Pathogen
  ```
  cd ~/.vim/bundle
  git clone https://github.com/Drathro/nnwmtool
  ```
* Vim 8's Package System
  * I'm a DIYer, so I like Vim 8's package system. See `:help package`. Here's what I did:
    * Check your packpath in Vim for the appropriate location of the "pack" directory.
    * Create and cd to `pack/nnwmtool/start`
    * Populate the new directory with the plugin. Two possible methods:
      * Download and extract the zip, which should create a nnwmtool directory.
      * `git clone https://github.com/Drathro/nnwmtool`
    * Optional: in Vim run `:helptags ALL` (Or specify a directory if you're picky.)

## Usage
Optionally set two globals
- g:nnwmuser
  - Your NaNoWriMo user name
    ```
    :let g:nnwmuser="Annabelle"
    ```
- g:nnwmkey
  - Your NaNoWriMo "secret key"
  - Login to nanowrimo.org and copy your secret key at https://nanowrimo.org/api/wordcount 
    ```
    :let g:nnwmkey="abc123"
    ```

Execute or map the following command:
```
:call nnwmtool#UpdateWC()
```

If you want to skip confirmation before updating the wordcount, instead pass the function any argument:
```
:call nnwmtool#UpdateWC(1)
```

##### Sample mapping
```
nnoremap <F8> :call nnwmtool#UpdateWC()<CR>
```

## Error Status
Most errors are self-explanatory. If an error says the hash is invalid, your secret key has probably been entered incorrectly.

