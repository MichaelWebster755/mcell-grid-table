# SPDX-FileCopyrightText: 2021 Michael Webster
# SPDX-FileCopyrightText: Western Digital Corporation or its affiliates
#
# SPDX-License-Identifier: GPL-3.0-or-later
# 
# I extended this example from BoxExtension in https://python-markdown.github.io/extensions/api/
from markdown.extensions import Extension
from markdown.blockprocessors import BlockProcessor
from threading import Thread
import xml.etree.ElementTree as etree
import re
import queue
import subprocess
import sys
import errno


def mcgt_xml_parse_task(src, result):
    result.put(etree.parse(src))
    #lines = src.readlines()
    #result.put(parser.parseDocument(lines))

class MCellGridTableBlockProcessor(BlockProcessor):
    RE_CODE_BLK_START = r'^ *`{3,}mcgtable *\n' # For example: '```mcgtable'
    RE_CODE_BLK_END = r'\n *`{3,}\s*$'          # For example: '```\n\n'

    def test(self, parent, block):
        return re.match(self.RE_CODE_BLK_START, block)

    def run(self, parent, blocks):
        result         = queue.Queue()
        original_block = blocks[0]

        # Remove code block's opening marker
        blocks[0] = re.sub(self.RE_CODE_BLK_START, '', blocks[0])

        # Find code block with closing marker
        for block_num, block in enumerate(blocks):
            if re.search(self.RE_CODE_BLK_END, block):

                # Remove code block's closing marker
                blocks[block_num] = re.sub(self.RE_CODE_BLK_END, '', block)

                #f = open("data.txt", "w")

                # Render code block as table
                cmd = "lua mcell-grid-table.lua -t html".split()
                proc = subprocess.Popen(
                    cmd,
                    shell=False,
                    stdin=subprocess.PIPE,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.DEVNULL,
                    universal_newlines=True
                )
                t = Thread(
                    target=mcgt_xml_parse_task,
                    args=(proc.stdout, result)
                )
                t.start()
                for i in range(0, block_num + 1):
                    proc.stdin.write(blocks[i])
                    proc.stdin.write("\n\n")
                    #f.write(blocks[i])
                    #f.write("\n\n")
                #f.close()
                try:
                    proc.stdin.close()
                except BrokenPipeError:
                    pass
                except OSError as exc:
                    if exc.errno == errno.EINVAL:
                        pass
                    else:
                        raise
                t.join()
                if not result.empty():
                    e = result.get(block=False)

                    # Process cell contents
                    for cell in e.findall('thead/tr/th'):
                        txt = cell.text
                        cell.text = ""
                        self.parser.parseChunk(cell, txt)
                    for cell in e.findall('thead/tr/td'):
                        txt = cell.text
                        cell.text = ""
                        self.parser.parseChunk(cell, txt)
                    for cell in e.findall('tbody/tr/th'):
                        txt = cell.text
                        cell.text = ""
                        self.parser.parseChunk(cell, txt)
                    for cell in e.findall('tbody/tr/td'):
                        txt = cell.text
                        cell.text = ""
                        self.parser.parseChunk(cell, txt)
                    for cell in e.findall('tfoot/tr/th'):
                        txt = cell.text
                        cell.text = ""
                        self.parser.parseChunk(cell, txt)
                    for cell in e.findall('tfoot/tr/td'):
                        txt = cell.text
                        cell.text = ""
                        self.parser.parseChunk(cell, txt)
                    # TODO: if just one paragraph found reduce it to just the td/th text?

                    parent.append(e.getroot())

                    #e = etree.SubElement(parent, 'div')
                    #e.set('style', 'display: inline-block; border: 1px solid red;')
                    #self.parser.parseBlocks(e, blocks[0:block_num + 1])

                    # Remove consumed blocks
                    for i in range(0, block_num + 1):
                        blocks.pop(0)
                    return True

        # Something went wrong!  Restore original blocks.
        blocks[0] = original_block
        return False

class MCellGridTableExtension(Extension):
    def extendMarkdown(self, md):
        md.parser.blockprocessors.register(MCellGridTableBlockProcessor(md.parser), 'mcgtable', 175)

def makeExtension(**kwargs):
    return MCellGridTableExtension(**kwargs)
