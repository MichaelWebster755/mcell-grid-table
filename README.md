<!--
SPDX-FileCopyrightText: 2021 Michael Webster
SPDX-FileCopyrightText: 2021 Western Digital Corporation or its affiliates

SPDX-License-Identifier: GPL-3.0-or-later
-->

Introduction
============

Merge Cell Grid Table is a Pandoc Lua filter that translates a Markdown-like
syntax of a table into a tagged version of that table.
The Markdown-like syntax looks like an ASCII art layout of your table.
The primary feature that Merge Cell Grid Table provides beyond Markdown pipe
tables is the ability for a table cell to span column and row boundaries.

For more details see the [User Manual](doc/user-manual.pdf).


Installation
============

The following sections describe installation steps.


Prerequisites
-------------

You will need the following installed to build and install the Merge Cell Grid
Table utility.

- AutoConf
- AutoMake
- Pandoc

You will need the following installed if you intend to rebuild the package's
user manual.

- xsltproc
- DocBook XML 4.5
- DocBook XSL
- Apache FOP

The operating specific instructions below have suggestions on how to install
each of these prerequisistes.


Linux or macOS
--------------

Installation for Linux and macOS is similar.


### Linux Prerequisites

The author has not validated any of these Linux instructions.


#### For Ubuntu

1. Linux usually already has an acceptable version of AutoConf, but if not then
   perform: `sudo apt install autoconf`
1. Linux usually alfeady has an acecptbale version of AutoMake, but if not then
   perform: `sudo apt install automake`
1. `sudo apt install dejagnu`
1. `sudo apt install lua`
1. `sudo apt install pandoc`
1. `sudo apt install libxml2` (to get xlstproc)
1. `sudo apt install libxslt` (to get xlstproc)
1. `sudo apt install docbook`
    1. You might need to set XML_CATALOG_FILES environment var in your
       "~/.bashrc" or "~/.bash_profile"
1. `sudo apt install docbook-xsl`
1. `sudo apt install openjdk-11-jdk` (openjdk-11-jre might work)
1. `sudo apt install fop`
1. Add `export FOP=/path/to/your/fop-2.6/fop/fop.sh` to your "~/.bashrc" or
   "~/.bash_profile"


#### For Redhat and CentOS

1. Linux usually already has an acceptable version of AutoConf, but if not then
   perform: `yum install autoconf`
1. Linux usually alfeady has an acecptbale version of AutoMake, but if not then
   perform: `yum install automake`
1. `yum install dejagnu`
1. `yum install lua`
1. `yum install pandoc`
1. `yum install libxml2` (to get xlstproc)
1. `yum install libxslt` (to get xlstproc)
1. `yum install docbook`
    1. You might need to set XML_CATALOG_FILES environment var in your
       "~/.bashrc" or "~/.bash_profile"
1. `yum install docbook-xsl`
1. `yum install java-11-openjdk`
1. `yum install fop`
1. Add `export FOP=/path/to/your/fop-2.6/fop/fop.sh` to your "~/.bashrc" or
   "~/.bash_profile"


### macOS Prerequisites

The following instructions assume you will be using
[Homebrew](https://brew.sh/).

1. `brew install autoconf`
1. `brew install automake`
1. `brew install dejagnu`
1. `brew install lua`
1. `brew install pandoc`
1. `brew install libxml2` (to get xlstproc)
1. `brew install libxslt` (to get xsltproc)
1. `brew install docbook`
    1. Don't forget to add
       `export XML_CATALOG_FILES="$(brew --prefix)/etc/xml/catalog"` to your
       "~/.zshrc" or "~/.zsh_profile"
1. `brew install docbook-xsl`
1. Install OpenJDK 11 using either
    1. [AdoptOpenJDK](https://adoptopenjdk.net/) instructions, or ...
    2. `brew install --cask adoptopenjdk`
1. `brew install fop`
1. Add `export FOP=/path/to/your/fop-2.6/fop/fop.sh` to your "~/.zshrc" or
    "~/.zsh_profile"

Author has not validated the above instructions work as intended.


### Package Install

```
mkdir config
aclocal
autoconf
automake --add-missing --foreign
./configure --prefix=$HOME/.local/share
make
make install
```

The above instructions install the utility to a local data directory that is
used by Pandoc to locate Lua Filters.
For more information on this local data directory see the
[Pandoc user manual](https://pandoc.org/MANUAL.html#reader-options) sections on
`--data-dir` and `--lua-filter` command line options.
If your installation of Pandoc expects Lua Filters to live somewhere other than
your that local data directory, then you will need to change the `configure`
line above or manually copy the utility there.
For example:

```
cp src/mcell-grid-table.lua /path/where/your/pandoc/expects/lua-filters
```


Windows
-------

There are some Windows specific steps you must take.


### Windows Prerequisites

The following instructions assume you will be using Cygwin.

1. Install [Cygwin](https://cygwin.com/install.html) with the following packages
   (from Cygwin Setup view: category). Newer versions should be ok.  Let Setup
   install dependencies.
    1. Devel/autoconf2.5
    1. Devel/automake1.16
    1. Devel/dejagnu
    1. Interpreters/lua
    1. Libs/libxml2 (to get xsltproc)
    1. Libs/libxslt (to get xlstproc)
    1. Text/docbook-xml45
    1. Text/docbook-xsl
2. Don't forget to add `export XML_CATALOG_FILES=/etc/xml/catalog` to your
   "~/.bashrc" or "~/.bash_profile"
3. Install [Pandoc](https://github.com/jgm/pandoc/releases/latest) as a native
   Windows app (msi is the easiest way to go)
4. Install [OpenJDK](https://adoptopenjdk.net/) as a native Windows install.
   OpenJDK11 is recommended.
5. Install [Apache FOP](https://xmlgraphics.apache.org/fop/download.html) from
   binary download ZIP is recommended
6. Add `export FOP=/cygdrive/c/path/to/your/fop-2.6/fop/fop.bat` to your
   "~/.bashrc" or "~/.bash_profile"

[MSYS](https://www.msys2.org/) might work as a replacement for Cygwin, but the
Cygwin instructions above are what the author used.
You would also need to translate the above Cygwin packages into whatever are the
equivalent under MSYS.


### Package Install

Within a Cygwin terminal window do the following:

```
mkdir config
aclocal
autoconf
automake --add-missing --foreign
./configure --prefix=`cygpath -u $APPDATA/pandoc`
make
make install
```

The above instructions install the utility to a local data directory that is
used by Pandoc to locate Lua Filters.
For more information on this local data directory see the Pandoc user manual
sections on `--data-dir` and `--lua-filter` command line options.
If your installation of Pandoc expects Lua Filters to live somewhere other than
your that local data directory, then you will need to change the `configure`
line above or manually copy the utility there.
For example:

```
cp src/mcell-grid-table.lua /cygdrive/c/path/where/your/pandoc/expects/lua-filters
```

Running the Test Suite
----------------------

To execute the test suite perform the following after completing the `configure`
step above.
Assuming you performed the install steps described in earlier sections for your
operating system, the following should work in Linux, macOS, or Window(Cygwin).

```
make check
```


Rebuilding the Documentation
----------------------------

By default the package already has the doc/user-manual.pdf created, but if you
wish to recreate it then after completing the `configure` step above do the
following:

```
make doc-clean
make doc-build
cp doc/newly-built-user-manual.pdf doc/user-manual.pdf
```

Assuming you performed the install steps described in earlier sections for your
operating system, the above should work in Linux, macOS, or Window(Cygwin).


Usage
=====

Assuming you installed to the local data directory as described by the
instructions, then you should be able to use the filter with Pandoc as shown
below.

```
pandoc doc.md -o doc.xml -f markdown --lua-filter bin/mcell-grid-table.lua -t docbook
```

The AutoMake install instructions will put the filter in a "bin" folder below
the local data directory which is why that extra folder name is needed.


Credits
=======

Author: Michael Webster

Tino Lin demonstrated an ASCII art table printing routine that excluded the plus
signs above each row.
This allowed his printing routine to only be concerned with the row it was
currently processing.
It also gave me the idea for the syntax of Merge Cell Grid Tables where the
limits of each cell are defined to the bottom and the right and ignores
separators to the left and above.
This made the syntax consistent and easier to parse.


License
=======

See the [License file](LICENSES/GPL-3.0-or-later.txt)
