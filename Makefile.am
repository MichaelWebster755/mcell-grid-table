# SPDX-FileCopyrightText: 2021 Michael Webster
# SPDX-FileCopyrightText: 2021 Western Digital Corporation or its affiliates
#
# SPDX-License-Identifier: GPL-3.0-or-later

AUTOMAKE_OPTIONS = dejagnu
bin_SCRIPTS = src/mcell-grid-table.lua
doc_DATA = doc/user-manual.pdf
CLEANFILES = $(bin_SCRIPTS)
EXTRA_DIST = testsuite
DEJATOOL = mcgt-clm
AM_RUNTESTFLAGS = MCGT_LUA=$$(pwd)/src/mcell-grid-table.lua --srcdir $${srcdir}/testsuite

doc/user-manual.xml : doc/user-manual.md Makefile
	cd doc && pandoc user-manual.md -o user-manual.xml -f markdown+fenced_code_attributes --self-contained --lua-filter ../src/mcell-grid-table.lua -t docbook4

doc/user-manual-tweaked.xml : doc/user-manual.xml doc/tweaks.xsl Makefile
	cd doc && xsltproc --output user-manual-tweaked.xml tweaks.xsl user-manual.xml

doc/user-manual.fo : doc/user-manual-tweaked.xml Makefile
	cd doc && xsltproc --stringparam shade.verbatim 1 --output user-manual.fo custom_styles.xsl user-manual-tweaked.xml

doc/newly-built-user-manual.pdf : doc/user-manual.fo Makefile
	cd doc && ${FOP} -fo user-manual.fo -pdf newly-built-user-manual.pdf

.PHONY: doc-build
doc-build : doc/newly-built-user-manual.pdf

.PHONY: doc-clean
doc-clean:
	-rm doc/*.xml
	-rm doc/*.fo
	-rm doc/newly-built-*.pdf
