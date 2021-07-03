<!--
SPDX-FileCopyrightText: 2021 Michael Webster
SPDX-FileCopyrightText: 2021 Western Digital Corporation or its affiliates

SPDX-License-Identifier: GPL-3.0-or-later
-->

Merge Cell Grid Table Project Notes
===================================

These notes do not reflect the current state of this project.  Instead it
contains notes to myself about the steps I took to create this project from
scratch so I can remember how to do it again on future projects.


Create Git Respository
----------------------

1. `cd /srv/git`
2. `mkdir mcell-grid-table.git`
3. `cd mcell-grid-table.git`
4. `git init --bare`


Populate Initial Working Directory
----------------------------------

1. `cd /cygdrive/e/Projects`
2. `git clone me@MyComputer:/srv/git/mcell-grid-table.git`
3. `cd mcell-grid-table`
4. `mkdir config`
5. `mkdir m4`
6. `mkdir doc`
7. `mkdir src`
8. `mkdir -p testsuite/mcgt-clm`
9. Create initial `src/mcell-grid-table.lua.in`
10. Configure VSCodium to recognize ".lua.in" the same as ".lua"
    1. Note: cannot use `ctrl+k m` "Configure File Association" technique since
       that will only recognize ".in" and I want to associate ".lua.in" so I
       had to use the longer method below
    2. Open VSCodium
    3. View->Command Palette... (or ctrl+shift+p or cmd+shift+p)
    4. Type "settings.json"
    5. Select "Preferences: Open Settings (JSON)" from drop-down list
    6. "settings.json" tab is openned
    7. In that tab add ".lua.in" to "files.associations" list as `"*.lua.in": "lua"`
    8. If "files.associations" list doesn't exist yet then add the following
       
       ~~~
       "files.associations": {
           "*.lua.in": "lua"
       }
       ~~~

11. Create initial `testsuite/mcgt-clm/mcgt-clm.exp`

    ~~~
    proc exec-test { tcname } {
        global MCGT_LUA
        if { [file exists $tcname-act.md] } {
            exec rm $tcname-act.md
        }
        exec $MCGT_LUA -t docbook < $tcname-in.md > $tcname-act.md
        set rc [ diff "$tcname-act.md" "$tcname-exp.md" ]
        if { $rc == 1 } {
            pass $tcname
        } else {
            fail $tcname
        }
    }
    
    set file_list [glob $srcdir/mcgt-clm/*-in.md]
    foreach fn $file_list {
        regexp "(.*)-in.md" $fn ignore tcname
        exec-test $tcname
    }
    ~~~

12. Create initial `Makefile.am`

    ~~~
    AUTOMAKE_OPTIONS = dejagnu
    bin_SCRIPTS = src/mcell-grid-table.lua
    CLEANFILES = $(bin_SCRIPTS)
    EXTRA_DIST = testsuite
    DEJATOOL = mcgt-clm
    AM_RUNTESTFLAGS = MCGT_LUA=`pwd`/src/mcell-grid-table.lua --srcdir $${srcdir}/testsuite
    ~~~

13. Create initial `configure.ac`

    ~~~
    # Process this file with autoconf to produce a configure script.
    AC_PREREQ(2.59)
    AC_INIT([mcell-grid-table], [0.1])  # TODO: add email address?
    AC_CONFIG_AUX_DIR(config)
    AM_INIT_AUTOMAKE
    AC_CONFIG_FILES([Makefile])
    AC_CONFIG_FILES([src/mcell-grid-table.lua], [chmod +x src/mcell-grid-table.lua])
    AC_OUTPUT
    ~~~

14. First commit before Autotool initialization
    1. `git add doc`
    2. `git add src`
    3. `git add testsuite`
    4. `git add Makefile.am`
    5. `git add configure.ac`
    6. `git commit -m "Initial version"`
    7. `git push`
15. Autotool project initialization
    1. `aclocal`
    2. `autoconf`
    3. `automake --add-missing --foreign`
16. Build and test
    1. `./configure`
    2. `make`
    3. `make check`


Reference Documentation
-----------------------

- Relating to problem domain: writing a Pandoc filter to process merge cell grid tables
    - [Pandoc User’s Guide](https://pandoc.org/MANUAL.html)
    - [Pandoc filters](https://pandoc.org/filters.html)
    - [Pandoc Lua Filters](https://pandoc.org/lua-filters.html)
    - [Lua 5.3 Reference Manual](https://www.lua.org/manual/5.3/)
    - [Programming in Lua (first edition)](https://www.lua.org/pil/contents.html)
- Project management
    - [Pro Git](https://github.com/progit/progit2/releases/download/2.1.224/progit.pdf)
    - The "Goat Book": [GNU Autoconf, Automake, and Libtool](https://www.sourceware.org/autobook/)
    - [GNU Autoconf - Creating Automatic Configuration Scripts](https://www.gnu.org/software/autoconf/manual/)
    - [GNU Automake](https://www.gnu.org/software/automake/manual/)
- Project test suite
    - [DejaGnu: a short introduction](http://www.scarpaz.com/Documents/dejagnu.pdf)
    - [DejaGnu manual](https://www.gnu.org/software/dejagnu/manual/index.html)
    - [Exploring Expect: A Tcl-based Toolkit for Automating Interactive Programs](http://shop.oreilly.com/product/9781565920903.do)
