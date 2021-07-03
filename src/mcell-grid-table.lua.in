-- SPDX-FileCopyrightText: 2021 Michael Webster
-- SPDX-FileCopyrightText: Western Digital Corporation or its affiliates
--
-- SPDX-License-Identifier: GPL-3.0-or-later
-------------------------------------------------------------------------------
-- 
-- Merge Cell Grid Tables filter for Pandoc
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.
-- 
-- 
-- This is a filter for Pandoc providing an extension of grid table markdown
-- that supports the following features:
-- 
-- 1. Merged cells that may span across column and/or row boundaries
-- 2. Table header, table body, and table footer
-- 3. Multi-line table cells and single-line table cells
-- 4. Visible and invisible column and row boundaries
-- 5. Generates either HTML or DocBook tags to be re-ingested by Pandoc which
--    Pandoc then passes through to the output
-- 
-- The following characters have special meaning when detected at column, row,
-- or intersection boundary positions:
-- 
-- - Plus (i.e. '+') is an intersection char and also sets multi-line mode
-- - Hash (i.e. '#') is an intersection char and also sets single-line mode
-- - Vertical bar (i.e. '|') is a column boundary
-- - Dash (i.e. '-') is a row boundary
-- - Equals (i.e. '=') is a row boundary and marks end of header
-- - Underscore (i.e. '_') is a row boundary and marks start of footer
-- - Colon (i.e. ':') is a row boundary and is also used to set cell alignment
--   (i.e. left justified, center justified, or right justified)
-- - Space (i.e. only ASCII 0x20 - not Tab!) is an invisible column or row
--   boundary depending on where it is found
-- 
-- Intersection chars (i.e. Plus and Hash) in the initial row separator (i.e.
-- the first line of the table) introduce all the column boundary positions.
-- If a column is not introduced in the initial row separator then the filter
-- will not accept or detect the existence of that column boundary later in the
-- table.
-- 
-- Another way to say the above is that column boundaries are defined by the
-- location of intersection chars in the initial row separator.
-- 
-- Intersection chars (i.e. Plus and Hash) in the initial column separator
-- (i.e. the leftmost characters of the table) introduce explicit row
-- boundaries.  While in single-line mode implicit row boundaries are defined
-- after each line.  If an explicit row boundary is not introduced in the
-- initial column separator then the filter will not accept or detect the
-- existence of that row boundary later on that line.
-- 
-- Another way to say the above is that explicit row boundaries are defined by
-- the location of intersection chars in the initial column separator. Implicit
-- row boundaries are defined after each line while in single-line mode.
-- 
-- When the special characters above are detected at places other than column,
-- row, or intersection boundary positions, then they are treated as normal
-- characters.
-------------------------------------------------------------------------------

-- Script Mode Constants
SM_CMD_LINE      = 1;  -- Script Mode: Command Line
SM_PANDOC_FILTER = 2;  -- Script Mode: Pandoc Filter

-- Verbosity Constants
VB_NONE  = 0;  -- No extra output lines, not even error messages
VB_ERROR = 1;  -- Only error messages
VB_WARN  = 2;  -- Warnings or error messages
VB_DEBUG = 3;  -- Maximum amount of messages

-- Result Code Constants
RC_OK    = 0;  -- Success
RC_WARN  = 1;  -- A warning occurred
RC_ERROR = 2;  -- An error occurred

-- Parsing State Constants
ST_BEFORE_TABLE   = 1;  -- State: Before table begins (might see caption)
ST_ROWLINE        = 2;  -- State: A text line that is part of a row
ST_ROWSEP         = 3;  -- State: A text line that might be a row separator
ST_AFTER_TABLE    = 4;  -- State: After table ends (might see caption)
ST_ERROR          = 5;  -- State: Fatal parsing error

-- Line Mode Contants
LM_SINGLE   = 1;  -- Single-line mode
LM_MULTIPLE = 2;  -- Multi-line mode

-- Row Mode Constants
RM_HEADER = 1;  -- Row is in header
RM_BODY   = 2;  -- Row is in body
RM_FOOTER = 3;  -- Row is in footer

-- Globals
script_name = "mcgt.lua";   -- A slightly wrong value that gets replaced when cmd-line mode or filter mode figures it out
script_mode = SM_CMD_LINE;  -- Default to cmd-line mode
mcgtable    = {};           -- Start a new mcell-grid-table
default_fmt = "codeblk";    -- Default to code block format
default_vb  = VB_WARN;      -- Default verbosity
output_ast  = false;        -- A flag to output pandoc AST; otherwise text


-------------------------------------------------------------------------------
-- Take a multiline text string as input and return an array of single-line
-- strings
-------------------------------------------------------------------------------
local function SplitLines(text)
    local lines = {};
    local len   = string.len(text);
    local i     = 0;
    local j     = 0;
    local p     = 1;
    local v     = "";
    
    -- While text contains more lines to be extracted ...
    while p < len do
        -- Find a line up to the next newline
        i, j, v = string.find(text, "^([^\n]*)\n", p);
        
        if i ~= nil then
            -- We found a newline so append the match at the end of lines array
            --lines[#lines+1] = v;
            table.insert(lines, v);
            p = j + 1;  -- Move to char after newline
        else
            -- We did not find a newline so append the rest of the text to the
            -- end of lines array
            --lines[#lines+1] = string.sub(text, p);
            table.insert(lines, string.sub(text, p));
            p = len;
        end
    end

    return lines;
end


-------------------------------------------------------------------------------
-- Append new text line to output
-------------------------------------------------------------------------------
local function AddOutputLine(line)
    if mcgtable.output == nil then
        mcgtable.output = {};
    end

    -- Remove all trailing spaces
    line = string.gsub(line, "%s+$", "");

    if output_ast then
        table.insert(mcgtable.output, pandoc.Plain({pandoc.Str(line)}));
    else
        table.insert(mcgtable.output, line);
    end
end


-------------------------------------------------------------------------------
-- Append new tag to output
-------------------------------------------------------------------------------
local function AddTag(tag)
    if mcgtable.output == nil then
        mcgtable.output = {};
    end

    if output_ast then
        table.insert(mcgtable.output, pandoc.RawBlock(mcgtable.out_fmt, tag));
    else
        table.insert(mcgtable.output, tag);
    end
end

-------------------------------------------------------------------------------
-- Handle an error
-------------------------------------------------------------------------------
local function Error(msg, line)
    -- If allowed then output error message
    if mcgtable.verbosity >= VB_ERROR then
        AddOutputLine(string.format("\nERROR: %s: %s", script_name, msg));
    end

    -- Update current line to contain characters that have not been consumed
    if mcgtable.in_lines ~= nil then
        mcgtable.in_lines[mcgtable.lines_consumed + 1] = line;
    end

    -- Update result code
    if mcgtable.rc < RC_ERROR then
        mcgtable.rc = RC_ERROR;
    end
end


-------------------------------------------------------------------------------
-- Handle an error at a specific row, column coordinate
-------------------------------------------------------------------------------
local function ErrorXY(row, col, msg, line)
    Error(string.format("r%d,c%d: %s", row, col, msg), line);
end


-------------------------------------------------------------------------------
-- Handle a warning
-------------------------------------------------------------------------------
local function Warning(msg)
    -- If allowed then output warning message
    if mcgtable.verbosity >= VB_WARN then
        AddOutputLine(string.format("\nWARNING: %s: %s", script_name, msg));
    end

    -- Update result code
    if mcgtable.rc < RC_WARN then
        mcgtable.rc = RC_WARN;
    end
end


-------------------------------------------------------------------------------
-- Print a debug message
-------------------------------------------------------------------------------
local function DebugPrint(msg)
    -- If allowed then output debug message
    if mcgtable.verbosity >= VB_DEBUG then
        AddOutputLine(string.format("\nDEBUG: %s: %s", script_name, msg));
    end
end


-------------------------------------------------------------------------------
-- Returns true if line is blank
-------------------------------------------------------------------------------
local function IsBlank(line)
    if string.len(line) == 0 then
        return true;
    end
    _, _, v = string.find(line, "^%s*$");
    if v then
        return true;
    end

    return false;
end


-------------------------------------------------------------------------------
-- Add a single line of text and a single vertical separator to a cell.  Create
-- the cell if it doesn't exist yet.
-------------------------------------------------------------------------------
local function AddToCell(row, col, line, vsep)
    if mcgtable.row_list == nil then
        mcgtable.row_list = {};  -- Create empty row list
    end

    if mcgtable.row_list[row] == nil then
        mcgtable.row_list[row] = {};  -- Create empty cell list
    end

    if mcgtable.row_list[row][col] == nil then
        mcgtable.row_list[row][col] = {};  -- Create empty cell
    end

    local cell = mcgtable.row_list[row][col];

    if cell.lines == nil then
        cell.lines = {};  -- Create empty lines array
    end

    table.insert(cell.lines, line);  -- Add cell line

    if cell.vsep == nil then
        cell.vsep = {};  -- Create empty vertical separator array
    end

    table.insert(cell.vsep, vsep);  -- Add vertical separator
end


-------------------------------------------------------------------------------
-- Finish a cell by recording the horizontal separator (hsep) and intersection
-- separator (isep).  This function assumes the cell was already created by a
-- previous call to AddToCell
-------------------------------------------------------------------------------
local function CloseCell(row, col, hsep, isep)
    local cell          = mcgtable.row_list[row][col];
    local cell_above;
    local cell_to_left;
    local i;
    local v;
    local r;

    cell.hsep = hsep;
    cell.isep = isep;

    -- Set some defaults.  Calc spans might update.
    cell.row_mode = RM_HEADER;
    cell.hspan    = false;
    cell.vspan    = false;
    cell.colspan  = 0;
    cell.rowspan  = 0;

    -- For initial row separator, record default cell alignment for this column.
    -- Note, we limit this to the initial row separator because column spans
    -- might change the answer for spanned cells, but the cells in the initial
    -- row separator cannot by definition span so we can record them now.
    if row == 0 then
        _, _, l_align, r_align = string.find(cell.hsep, "^(.).*(.)$");
        if (l_align == ":") and (r_align == ":") then
            cell.align = "center";
        elseif (l_align == ":") then
            cell.align = "left";
        elseif (r_align == ":") then
            cell.align = "right";
        end

        -- Start of Footer?
        if mcgtable.cur_row_mode < RM_FOOTER then
            r = string.find(cell.hsep, "_");
            if r ~= nil then
                mcgtable.cur_row_mode = RM_FOOTER;
            end
        end

        -- End of Header?
        if mcgtable.cur_row_mode == RM_HEADER then
            r = string.find(cell.hsep, "=");
            if r ~= nil then
                mcgtable.cur_row_mode = RM_BODY;
            end
        end
    end

    -- Set flags for hidden borders.  Again, calc spans might update.
    r = string.find(cell.hsep, "[^ ]");
    cell.hide_bottom = (r == nil);  -- If r is nil then all we found were spaces
    cell.hide_right  = true;
    for i, v in ipairs(cell.vsep) do
        r = string.find(v, "[^ ]");
        -- If r is nil then we found a space
        cell.hide_right = cell.hide_right and (r == nil);
    end
    if col > 0 then
        cell_to_left   = mcgtable.row_list[row][col-1]
        cell.hide_left = cell_to_left.hide_right;
    else
        cell.hide_left = false;
    end
    if row > 0 then
        cell_above    = mcgtable.row_list[row-1][col];
        cell.hide_top = cell_above.hide_bottom;
    else
        cell.hide_top = false;
    end
end


-------------------------------------------------------------------------------
-- Parse the initial row separator line to find all the columns.  This function
-- assumes caller already found the starting plus sign.
-------------------------------------------------------------------------------
local function ParseInitialRowSep(state, line, isep)
    local rest = "";  -- The rest of the line
    local col  = 1;
    local pos  = 0;
    local v;

    -- Create fake cell at 0,0
    AddToCell(0, 0, " ", "|");
    CloseCell(0, 0, "-", isep);

    -- While there is more text in the line to process ...
    while string.len(line) ~= 0 do
        -- It is ok to see all spaces after first column has been parsed
        if col > 1 then
            _, _, v = string.find(line, "^[ ]+$");
            if v ~= nil then
                break;
            end
        end

        -- Parse out next column's worth (i.e. hsep followed by a plus sign)
        _, _, hsep, isep, rest = string.find(line, "^([^%+#]*)([%+#])(.*)");
        if hsep == nil then
            if col > 1 then
                ErrorXY(0, col, "Garbage found to the right of table", line);
            else
                ErrorXY(0, col, "Did not find even one valid column", line);
            end
            return ST_ERROR;
        end

        line = rest;  -- Consume this column's portion from line

        if string.len(hsep) == 0 then
            ErrorXY(0, col, "Cannot have zero width column", line);
            return ST_ERROR;
        end

        -- Syntax check the hsep.  Spaces not allowed in initial row separator.
        -- TODO: following doesn't allow hsep = "::".  Is that a problem?
        v = string.find(hsep, "^:?[%-=_]+:?$");
        if v == nil then
            ErrorXY(0, col, string.format("Syntax error in horizontal separator \"%s\"", hsep), line);
            return ST_ERROR;
        end

        -- Everything looks ok.  Add this cell for our new column.
        AddToCell(0, col, " ", "|");   -- Fake cell content
        CloseCell(0, col, hsep, isep);

        col = col + 1;  -- Bump column number
    end

    DebugPrint(string.format("Found %d column(s)", col - 1));

    -- Calculate column positions
    mcgtable.col_pos = {};
    pos = mcgtable.indent + 2;
    for i=1,col-1 do
        mcgtable.col_pos[i] = {};
        mcgtable.col_pos[i].hsep_start = pos;
        pos = pos + string.len(mcgtable.row_list[0][i].hsep) - 1;
        mcgtable.col_pos[i].hsep_stop  = pos;
        pos = pos + 1;
        mcgtable.col_pos[i].isep_pos = pos;
        mcgtable.exp_line_len = pos;
        pos = pos + 1;
    end

    mcgtable.row_num = 1;  -- Now starting row 1

    -- A row separator (even the initial row separator) must be followed by a
    -- row line
    return ST_ROWLINE;
end


-------------------------------------------------------------------------------
-- Parse lines looking for the start of the table.  If we find a caption then
-- record that.
-------------------------------------------------------------------------------
local function ParseBeforeTable(state, line)
    local i     = 0;
    local j     = 0;
    local v     = "";
    local isep  = "";
    local rest  = "";

    -- Look for table caption
    _, _, v = string.find(line, "^[ ]*Table:[ ]*(.*)");
    if v ~= nil then
        if mcgtable.caption ~= nil then
            Warning("Too many table captions. Will use last one.");
        end
        mcgtable.caption = v;  -- Record the table caption

        return state;  -- Stay in same state
    end

    -- Look for start of table (i.e. first plus sign)
    _, _, v, isep, rest = string.find(line, "^([ ]*)([%+#])(.*)");
    if v then  -- Found beginning of table
        mcgtable.indent = string.len(v);  -- Record indentation length
        line = rest;
        return ParseInitialRowSep(state, line, isep);
    end

    if IsBlank(line) then
        return state;  -- Stay in same state
    end

    -- Found a non-blank line
    Error("Garbage found before start of table");
    return ST_ERROR;
end


-------------------------------------------------------------------------------
-- Parse lines after the end of the table.  If we find a caption then record
-- that.
-------------------------------------------------------------------------------
local function ParseAfterTable(state, line)
    local i     = 0;
    local j     = 0;
    local v     = "";

    -- Look for table caption
    _, _, v = string.find(line, "^[ ]*Table:[ ]*(.*)");
    if v ~= nil then
        if mcgtable.caption ~= nil then
            Warning("Too many table captions. Will use last one.");
        end
        mcgtable.caption = v;  -- Record the table caption

        return state;  -- Stay in same state
    end

    if IsBlank(line) then
        return state;  -- Stay in same state
    end

    -- Found a non-blank line
    Error("Garbage found after end of table");
    return ST_ERROR;
end


-------------------------------------------------------------------------------
-- Parse a row as a text line for each column's cell.  Note there are only two
-- callers of this function: 
-- 
-- - When called directly by ParseLines then we are processing the first line
--   of text for this row
-- - When called by ParseRowSep then we are processing the second or greater
--   line of text for this row
-- 
-- ParseRowSep will call this function after it has determined the first char is
-- a vertical bar so we cannot trigger the error for zero height when called
-- from ParseRowSep.
-------------------------------------------------------------------------------
local function ParseRowLine(state, line)
    local row_num = mcgtable.row_num;
    local text;
    local vsep;
    local indent;
    local rest;

    -- Valid lines start with either a vertical bar, plus sign, or hash sign
    _, _, indent, first, rest = string.find(line, "^([ ]*)([|%+#])(.*)");
    if indent ~= nil then
        if string.len(indent) ~= mcgtable.indent then
            ErrorXY(row_num, 0, "Indent is different", line);
            return ST_ERROR;
        end

        if first == "|" then
            if string.len(line) < mcgtable.exp_line_len then
                ErrorXY(row_num, 0, "Line too short", rest);
                return ST_ERROR;
            end

            -- Use col_pos to substr each column cell parts
            for col_num, col_pos in ipairs(mcgtable.col_pos) do
                -- If working on col_num = 1 then also add fake cell contents
                -- for col_num = 0.
                if col_num == 1 then
                    AddToCell(row_num, 0, " ", "|");
                end

                text = string.sub(line, col_pos.hsep_start, col_pos.hsep_stop);
                vsep = string.sub(line, col_pos.isep_pos, col_pos.isep_pos);
                AddToCell(row_num, col_num, text, vsep);
            end
            return ST_ROWSEP;
        else
            -- But a plus sign or hash sign when we are processing the first
            -- line of text for a row means user is attempting to define a zero
            -- height row.
            ErrorXY(mcgtable.row_num, 0, "Cannot have zero height row", line);
            return ST_ERROR;
        end
    end

    -- Not a valid line of row data so this will terminate the table

    -- Terminated by blank line?
    if IsBlank(line) then
        ErrorXY(mcgtable.row_num, 0, "Row ended unexpectedly", line);
        return ST_ERROR;
    end

    -- Terminated by garbage
    ErrorXY(mcgtable.row_num, 0, "Table ended by garbage", line);
    return ST_ERROR;
end


-------------------------------------------------------------------------------
-- Parse either a row separator or another line for the current row
-------------------------------------------------------------------------------
local function ParseRowSep(state, line)
    local row_num = mcgtable.row_num;
    local hsep;
    local isep;
    local indent;
    local rest;

    -- If line starts with vertical bar then let ParseRowLine process it
    v = string.find(line, "^[ ]*|");
    if v ~= nil then
        -- TODO: handle implicit row separator if in single-line mode
        
        return ParseRowLine(state, line);
    end

    -- Otherwise a valid row separator starts with plus sign or hash sign
    _, _, indent, isep, rest = string.find(line, "^([ ]*)([%+#])(.*)");
    if indent ~= nil then
        if string.len(indent) ~= mcgtable.indent then
            ErrorXY(row_num, 0, "Indent is different", line);
            return ST_ERROR;
        end

        if string.len(line) < mcgtable.exp_line_len then
            ErrorXY(row_num, 0, "Line too short", rest);
            return ST_ERROR;
        end

        -- Use col_pos to substr each column cell parts
        for col_num, col_pos in ipairs(mcgtable.col_pos) do
            -- If working on col_num = 1 then also add fake cell contents for
            -- col_num = 0.  The isep here comes from the string.find above.
            if col_num == 1 then
                CloseCell(row_num, 0, "-", isep);
            end

            hsep = string.sub(line, col_pos.hsep_start, col_pos.hsep_stop);
            isep = string.sub(line, col_pos.isep_pos, col_pos.isep_pos);
            CloseCell(row_num, col_num, hsep, isep);
        end

        mcgtable.row_num = row_num + 1;
        return ST_ROWSEP;
    end

    return ParseAfterTable(ST_AFTER_TABLE, line);
end


-------------------------------------------------------------------------------
-- Parse through all the input lines
-------------------------------------------------------------------------------
local function ParseLines()
    local state = ST_BEFORE_TABLE;

    mcgtable.lines_consumed = 0;  -- So far we've consumed zero lines

    -- Parse each line
    for n, line in ipairs(mcgtable.in_lines) do

        v = string.find(line, "\t");
        if v ~= nil then
            Error("Tab characters are not supported.");
            state = ST_ERROR;
        end

        if state == ST_BEFORE_TABLE then
            state = ParseBeforeTable(state, line);
        elseif state == ST_ROWLINE then
            state = ParseRowLine(state, line);
        elseif state == ST_ROWSEP then
            state = ParseRowSep(state, line);
        elseif state == ST_AFTER_TABLE then
            state = ParseAfterTable(state, line);
        end

        if state ~= ST_ERROR then
            -- Record number of lines successfully consumed
            mcgtable.lines_consumed = n;
        end

    end

    -- If everything goes correctly then all lines will be consumed and this
    -- loop will be a NOP; however, if there are parsing errors or other such
    -- badness then output the remaining unconsumed lines here so that the user
    -- can see where things went bad.
    for n=mcgtable.lines_consumed+1,#mcgtable.in_lines do
        AddOutputLine(mcgtable.in_lines[n]);
    end
end

-------------------------------------------------------------------------------
-- Determine if a cell boundary indicates horizontal spanning
-------------------------------------------------------------------------------
local function IsCellHorzSpanning(cell)
    local i;  -- Index
    local v;  -- Value
    local r;  -- Result

    if cell == nil then
        Error("Assertion failure: IsCellHorzSpanning found nil cell");
        return false;  -- Non-existence cell cannot span
    end

    -- If any vsep is not space or vertical bar then we are spanning
    for i, v in ipairs(cell.vsep) do
        r = string.find(v, "[^ |]");
        if r ~= nil then
            return true;  -- Cell boundary indicates horizontal spanning
        end
    end

    -- If isep is not plus, hash, or vertical bar then we are spanning
    r = string.find(cell.isep, "[^%+#|]");
    if r ~= nil then
        return true;  -- Cell boundary indicates horizontal spanning
    end

    return false;  -- Not horizontal spanning
end

-------------------------------------------------------------------------------
-- Determine if a cell boundary indicates vertical spanning
-------------------------------------------------------------------------------
local function IsCellVertSpanning(cell)
    if cell == nil then
        Error("Assertion failure: IsCellVertSpanning found nil cell");
        return false;  -- Non-existence cell cannot span
    end

    -- If any char of hsep is something other than space, dash, equals,
    -- underscore, or colon then we are spanning
    r = string.find(cell.hsep, "[^ %-=_:]");
    if r ~= nil then
        return true;  -- Cell boundary indicates vertical spanning
    end

    -- If isep is not plus, hash, dash, equals, or underscore then we are
    -- spanning
    r = string.find(cell.isep, "[^%+#%-=_]");
    if r ~= nil then
        return true;  -- Cell boundary indicates vertical spanning
    end

    -- At this point we have determined that hsep contains a valid row boundary
    -- so we can now use it to check whether or not that hsep signals a change
    -- of the row mode (e.g. from body to footer or header to body).  Note that
    -- footer is checked first to make that transition higher priority than the
    -- transition from header to body.

    -- Start of Footer?
    if mcgtable.cur_row_mode < RM_FOOTER then
        r = string.find(cell.hsep, "_");
        if r ~= nil then
            mcgtable.cur_row_mode = RM_FOOTER;
        end
    end

    -- End of Header?
    if mcgtable.cur_row_mode == RM_HEADER then
        r = string.find(cell.hsep, "=");
        if r ~= nil then
            mcgtable.cur_row_mode = RM_BODY;
        end
    end

    return false;  -- Not vertical spanning
end

-------------------------------------------------------------------------------
-- Calculate column and row spanning values
-- 
-- This is accomplished in two passes:
-- 
-- 1. Pass 1 calculates column spanning values for each cell
--     1. Determine if each cell's vsep and isep boundaries are indicating
--        horizontal spanning
--     2. Determine if each cell's hsep and isep boundaries are indicating
--        vertical spanning
--     3. Calculate this cell's colspan value
--     4. Update the colspan value for the cell that starts the spanning
-- 2. Pass 2 calculates row spanning values for each cell
--     1. Calculate this cell's rowspan value
--     2. Update the rowspan value for the cell that starts the spanning
-- 
-- If any of the following are true then we are column spanning.
-- 
-- 1. Any vsep contains something other than space or vertical bar
-- 2. isep contains something other than plus or vertical bar
-- 
-- For each cell calculate the following
--
-- 1. cell.hspan = true if cell boundary indicates horizontal spanning
-- 2. cell.vspan = true if cell boundary indicates vertical spanning
-- 3. Calculate cell.colspan as one of the following
--     1. cell.colspan == n where n is the number of columns this cell spans (i.e. the value reported in HTML attribute colspan)
--     2. cell.colspan == 1 means there is no column spanning (just 1 cell)
--     3. cell.colspan == 0 initial default value before calculating spans
--     4. cell.colspan == -n means this cell was consumed by a cell n steps to the left that spanned over it
--
-- Later when converting to DocBook or HTML consume spanned cells
-- 
-- Again for each cell in each row calculate total column spanning leaving each
-- column span value one of the following
--
-- If any of the following are true then we are potentially row spanning.
-- 
-- - Any char of hsep is something other than space, dash, equals, underscore,
--   or colon
-- - isep contains something other than plus or dash
--
-- Row spanning has a few more requirements
--
-- - You cannot row span across the boundary between table header and table body.  If you attempt to do so the cells will remain split.
-- - If hsep or isep indicate row spanning and corresponding row above has the same colspan value then row spanning is ocurring; otherwise the cells remain split.
-- 
-- Note: earlier code created a fake row at index zero and a fake column at
-- index zero which allows the code below to use row-1 or col-1 without worrying
-- about falling off the top edge or left edge of the table data.
--
-- Also, during this function propagate hidden borders.  We do this here
-- since we are already determining the cell_above and cell_to_left which are
-- needed to check hidden borders.
-------------------------------------------------------------------------------
local function CalcSpans()

    for row, row_list in ipairs(mcgtable.row_list) do

        mcgtable.row_mode[row] = mcgtable.cur_row_mode;

        -- Pass 1: determine column spans
        for col, cell in ipairs(row_list) do
            cell.row_mode = mcgtable.row_mode[row];

            cell.hspan = IsCellHorzSpanning(cell);
            cell.vspan = IsCellVertSpanning(cell);

            cell_to_left = mcgtable.row_list[row][col-1];
            
            if not cell_to_left.hspan then  -- Not column spanning
                cell.colspan = 1;
                -- Record concatenated hsep for determining cell alignment (later)
                cell.align_hsep = cell.hsep;  -- So far the concat is just this cell
            elseif cell_to_left.colspan > 0 then  -- Span starts next to us
                cell.colspan = -1;
                cell_to_left.colspan = cell_to_left.colspan + 1;
                -- Propagate hidden borders leftward to start of span
                cell_to_left.hide_right  = cell.hide_right;
                cell_to_left.hide_top    = cell_to_left.hide_top or cell.hide_top;
                cell_to_left.hide_bottom = cell_to_left.hide_bottom or cell.hide_bottom;
                -- Record concatenated hsep for determining cell alignment (later)
                cell_to_left.align_hsep = cell_to_left.align_hsep .. cell.hsep;
            elseif cell_to_left.colspan < 0 then  -- Span starts further away
                cell.colspan = cell_to_left.colspan - 1;
                idx = col + cell.colspan;
                if idx >= 1 then
                    cell_span_start = mcgtable.row_list[row][idx];
                    cell_span_start.colspan = cell_span_start.colspan + 1;
                    -- Propagate hidden borders leftward to start of span
                    cell_span_start.hide_right  = cell.hide_right;
                    cell_span_start.hide_top    = cell_span_start.hide_top or cell.hide_top;
                    cell_span_start.hide_bottom = cell_span_start.hide_bottom or cell.hide_bottom;
                    -- Record concatenated hsep for determining cell alignment (later)
                    cell_span_start.align_hsep = cell_span_start.align_hsep .. cell.hsep;
                else
                    Error(string.format("Assertion failure: colspan cell_span_start index < 1. Index was %d", idx));
                end
            else
                Error("Assertion failure: CalcSpans found a spanning cell_to_left with zero colspan");
            end
        end

        -- Pass 2: determine row spans
        for col, cell in ipairs(row_list) do
            cell_above = mcgtable.row_list[row-1][col];

            -- In order to be row spanning then the following must be true
            -- 
            -- 1. The boundary for the cell above indicates vertical spanning
            -- 2. The cell above and this cell share the same row_mode (e.g.
            --    they are both in the header)
            -- 3. The width of the column spanning is the same between the cell
            --    above and this cell
            -- 
            -- If the cell above and this cell are not the same row_mode (e.g.
            -- the cell above is in the header and this cell is in the body)
            -- then we cannot row span because that would span across a header
            -- or footer boundary which is not allowed.
            -- 
            -- The reason column spanning plays any role in determining row
            -- spanning is because a cell spanning across rows cannot be
            -- changing widths as it spans.
            if
                (not cell_above.vspan)
                or (cell_above.row_mode ~= cell.row_mode)
                or (cell_above.colspan ~= cell.colspan)
            then  -- Not row spanning
                cell.rowspan = 1;
            elseif cell_above.rowspan > 0 then  -- Span starts next to us
                cell.rowspan = -1;
                cell_above.rowspan = cell_above.rowspan + 1;
                -- Propagate hidden borders upward to start of span
                cell_above.hide_bottom = cell.hide_bottom;
                cell_above.hide_left   = cell_above.hide_left or cell.hide_left;
                cell_above.hide_right  = cell_above.hide_right or cell.hide_right;
                -- Propagate align_hsep to start of span
                cell_above.align_hsep = cell.align_hsep;
            elseif cell_above.rowspan < 0 then  -- Span starts further away
                cell.rowspan = cell_above.rowspan - 1;
                idx = row + cell.rowspan;
                if idx >= 1 then
                    cell_span_start = mcgtable.row_list[idx][col];
                    cell_span_start.rowspan = cell_span_start.rowspan + 1;
                    -- Propagate hidden borders upward to start of span
                    cell_span_start.hide_bottom = cell.hide_bottom;
                    cell_span_start.hide_left   = cell_span_start.hide_left or cell.hide_left;
                    cell_span_start.hide_right  = cell_span_start.hide_right or cell.hide_right;
                    -- Propagate align_hsep to start of span
                    cell_above.align_hsep = cell.align_hsep;
                else
                    Error(string.format("Assertion failure: rowspan cell_span_start index < 1. Index was %d", idx));
                end
            else
                Error("Assertion failure: CalcSpans found a spanning cell_above with zero rowspan");
            end
        end
    end
end

local function OutputCellContents(row, col)
    local row_list;
    local cell;
    local rowspan;
    local colspan;
    local line;
    local cell_lines = {};

    row_list = mcgtable.row_list[row];
    if row_list == nil then
        Error(string.format("Assertion failure: OutputCellContents(%d,%d) found nil row", row, col));
        return;
    end

    cell = row_list[col];
    if cell == nil then
        Error(string.format("Assertion failure: OutputCellContents(%d,%d) found nil cell", row, col));
        return;
    end

    rowspan = cell.rowspan;
    colspan = cell.colspan;

    if (rowspan < 1) and (colspan < 1) then
        Error(string.format("Assertion failure: OutputCellContents(%d,%d) found consumed cell", row, col));
        return;
    end

    -- TODO: Do I need to run the cell content through Pandoc to convert it to HTML or Docbook?

    -- Make sure we use the cell at the start of the row span for criteria that
    -- have been recorded only in the starting cell of the row span.  For
    -- example, text alignment is only properly recorded in the start cell.
    cell_span_start = mcgtable.row_list[row][col];

    -- For each row in rowspan
    for y_row = 0, rowspan - 1 do

        -- Get number of lines in cell
        cell      = mcgtable.row_list[row + y_row][col];
        num_lines = #(cell.lines);
        cur_align = cell_span_start.align;

        -- For each line in cell
        for y_line = 1, num_lines do
            -- For each column in colspan
            line = "";
            for x_col = 0, colspan - 1 do
                cell = mcgtable.row_list[row + y_row][col + x_col];

                -- Handle line and vsep
                line = line .. cell.lines[y_line];
                if cell.hspan then
                    line = line .. cell.vsep[y_line];
                end
            end
            if (cur_align == "center") or (cur_align == "right") then
                -- Remove all leading spaces
                line = string.gsub(line, "^%s+", "");
            end
            if output_ast then
                -- Remove all trailing spaces
                line = string.gsub(line, "%s+$", "");
                -- Record line
                table.insert(cell_lines, line);
            else
                AddOutputLine(line);
            end
        end

        -- Now handle row border in case it contains text
        line = "";
        for x_col = 0, colspan - 1 do
            cell = mcgtable.row_list[row + y_row][col + x_col];

            -- Handle hsep and isep
            if cell.vspan then
                line = line .. cell.hsep;
            end
            if cell.vspan and cell.hspan then
                line = line .. cell.isep;
            end
        end
        if #line ~= 0 then
            if (cur_align == "center") or (cur_align == "right") then
                -- Remove all leading spaces
                line = string.gsub(line, "^%s+", "");
            end
            if output_ast then
                -- Remove all trailing spaces
                line = string.gsub(line, "%s+$", "");
                -- Record line
                table.insert(cell_lines, line);
            else
                AddOutputLine(line);
            end
        end
    end
    if output_ast then
        text = table.concat(cell_lines, "\n");
        doc  = pandoc.read(text, "markdown");
        for i, el in pairs(doc.blocks) do
            table.insert(mcgtable.output, el);
        end
    end
end

local function OutputRowModeStart(row_mode)
    if row_mode == RM_HEADER then
        AddTag("<thead>");
    elseif row_mode == RM_BODY then
        AddTag("<tbody>");
    elseif row_mode == RM_FOOTER then
        AddTag("<tfoot>");
    end
end

local function OutputRowModeEnd(row_mode)
    if row_mode == RM_HEADER then
        AddTag("</thead>");
    elseif row_mode == RM_BODY then
        AddTag("</tbody>");
    elseif row_mode == RM_FOOTER then
        AddTag("</tfoot>");
    end
end

local function GenDocbookOutput()
    local prev_row_mode = 0;  -- No row mode set, yet

    AddTag("<table>");
    if mcgtable.caption ~= nil then
        AddTag("<title>");
        AddOutputLine(mcgtable.caption);
        AddTag("</title>");
    end
    
    -- Start tgroup and output colspec tags
    row_list = mcgtable.row_list[0];
    num_cols = #row_list;
    AddTag(string.format("<tgroup cols=\"%d\">", num_cols));
    for col, cell in ipairs(row_list) do
        parms = string.format(" colnum=\"%d\" colname=\"c%d\"", col, col);
        parms = parms .. string.format(" colwidth=\"%i*\"", string.len(cell.hsep)+1);
        if cell.align ~= nil then
            parms = parms .. string.format(" align=\"%s\"", cell.align);
        end
        AddTag(string.format("<colspec%s />", parms));
    end


    -- For each row in table ...
    for row, row_list in ipairs(mcgtable.row_list) do
        -- If this row switches to a new row mode then end the previous row mode
        -- and start the new row mode.
        if prev_row_mode ~= mcgtable.row_mode[row] then
            OutputRowModeEnd(prev_row_mode);
            prev_row_mode = mcgtable.row_mode[row];
            OutputRowModeStart(mcgtable.row_mode[row])
        end
        -- TODO: can a row be completely spanned at every column?  sounds stupid but is it possible?
        AddTag("<row>");
        -- For each column in row ...
        for col, cell in ipairs(row_list) do
            tag = "entry";

            parms = "";
            output_cell = false;

            -- Does the cell consume at least one row and one column?  If not
            -- then a previous cell is consuming this cell by spanning across
            -- it.
            if (cell.rowspan > 0) and (cell.colspan > 0) then
                if cell.colspan > 1 then  -- If column spanning ...
                    parms =
                        parms ..
                        string.format
                        (
                            " namest=\"c%d\" nameend=\"c%d\"",
                            col,
                            col + cell.colspan - 1
                        );
                end

                if cell.rowspan > 1 then  -- If row spanning ...
                    parms =
                        parms ..
                        string.format(" morerows=\"%d\"", cell.rowspan -1);
                end
                
                output_cell = true;
            end

            -- Generate rowsep and colsep attributes for hidden borders
            if cell.hide_bottom then
                parms = parms .. " rowsep=\"0\"";
            end
            if cell.hide_right then
                parms = parms .. " colsep=\"0\"";
            end

            -- Generate cell alignment (if any)
            if cell.align_hsep ~= nil then
                _, _, l_align, r_align = string.find(cell.align_hsep, "^(.).*(.)$");
                if (l_align == ":") and (r_align == ":") then
                    cell.align = "center";
                elseif (l_align == ":") then
                    cell.align = "left";
                elseif (r_align == ":") then
                    cell.align = "right";
                end
            end
            if cell.align ~= nil then
                parms = parms .. string.format(" align=\"%s\"", cell.align);
            else
                col_cell = mcgtable.row_list[0][col];
                if col_cell.align ~= nil then
                    -- DocBook does support column-level text-align attributes,
                    -- but we still need to propagate the alignment to the cell
                    -- so that OutputCellContents knows when to trim leading
                    -- spaces.  Note, we did this propagation after we generated
                    -- the align attribute (contrast with GenHtmlOutput below).
                    cell.align = col_cell.align;
                end
            end

            -- Now output this cell if it is not consumed by some other cell
            -- spanning across it.
            if output_cell then
                -- Note, the extra newlines after the start tag and before the
                -- end tag are there to separate potential markdown cell
                -- contents from the surrounding tags.
                --
                -- See the following:
                --
                -- - [HTML Best Practices](https://www.markdownguide.org/basic-syntax/#html-best-practices)
                -- - [CommonMark Spec: Example 157](https://spec.commonmark.org/0.29/#example-157)
                AddTag(string.format("<%s%s>\n", tag, parms));
                OutputCellContents(row, col);
                AddTag(string.format("\n</%s>", tag));
            end
        end
        AddTag("</row>");
    end
    OutputRowModeEnd(prev_row_mode);
    AddTag("</tgroup>");
    AddTag("</table>");
end

local function GenHtmlOutput()
    local prev_row_mode = 0;  -- No row mode set, yet

    AddTag("<table>");
    if mcgtable.caption ~= nil then
        AddTag("<caption>");
        AddOutputLine(mcgtable.caption);
        AddTag("</caption>");
    end

    -- For each column set width to number of characters in that column
    for col, cell in ipairs(mcgtable.row_list[0]) do
        css_style = string.format("width: %iem;", string.len(cell.hsep)+1);
        AddTag(string.format("<col style=\"%s\" />", css_style));
    end

    -- For each row in table ...
    for row, row_list in ipairs(mcgtable.row_list) do
        -- If this row switches to a new row mode then end the previous row mode
        -- and start the new row mode.
        if prev_row_mode ~= mcgtable.row_mode[row] then
            OutputRowModeEnd(prev_row_mode);
            prev_row_mode = mcgtable.row_mode[row];
            OutputRowModeStart(mcgtable.row_mode[row])
        end
        -- TODO: can a row be completely spanned at every column?  sounds stupid but is it possible?
        AddTag("<tr>");
        -- For each column in row ...
        for col, cell in ipairs(row_list) do
            if cell.row_mode == RM_HEADER then
                tag = "th";
            else
                tag = "td";
            end

            parms       = "";
            css_style   = "";
            output_cell = false;

            -- Does the cell consume at least one row and one column?  If not
            -- then a previous cell is consuming this cell by spanning across
            -- it.
            if (cell.rowspan > 0) and (cell.colspan > 0) then
                if cell.colspan > 1 then  -- If column spanning ...
                    parms = parms .. string.format(" colspan=\"%s\"", cell.colspan);
                end

                if cell.rowspan > 1 then  -- If row spanning ...
                    parms = parms .. string.format(" rowspan=\"%s\"", cell.rowspan);
                end
                
                output_cell = true;
            end

            -- Generate style for hidden borders
            if cell.hide_top or cell.hide_bottom or cell.hide_left or cell.hide_right then
                if cell.hide_top then
                    css_style = css_style .. "border-top: none; ";
                end
                if cell.hide_bottom then
                    css_style = css_style .. "border-bottom: none; ";
                end
                if cell.hide_left then
                    css_style = css_style .. "border-left: none; ";
                end
                if cell.hide_right then
                    css_style = css_style .. "border-right: none; ";
                end
            end

            -- Generate cell alignment (if any)
            have_cell_align = true;  -- Assume we find one
            if cell.align_hsep ~= nil then
                _, _, l_align, r_align = string.find(cell.align_hsep, "^(.).*(.)$");
                if (l_align == ":") and (r_align == ":") then
                    cell.align = "center";
                elseif (l_align == ":") then
                    cell.align = "left";
                elseif (r_align == ":") then
                    cell.align = "right";
                else
                    have_cell_align = false;  -- Didn't find one
                end
            else
                have_cell_align = false;  -- Didn't find one
            end
            if not have_cell_align then
                col_cell = mcgtable.row_list[0][col];
                if col_cell.align ~= nil then
                    -- HTML and CSS don't support column-level text-align
                    -- attributes so propagate them to the cell
                    cell.align = col_cell.align;
                end
            end
            if cell.align ~= nil then
                css_style = css_style .. string.format("text-align: %s; ", cell.align);
            end

            -- Generate a style attibute if needed
            if string.len(css_style) > 0 then
                parms = parms .. string.format(" style=\"%s\"", css_style);
            end

            -- Now output this cell if it is not consumed by some other cell
            -- spanning across it.
            if output_cell then
                -- Note, the extra newlines after the start tag and before the
                -- end tag are there to separate potential markdown cell
                -- contents from the surrounding tags.
                --
                -- See the following:
                --
                -- - [HTML Best Practices](https://www.markdownguide.org/basic-syntax/#html-best-practices)
                -- - [CommonMark Spec: Example 157](https://spec.commonmark.org/0.29/#example-157)
                AddTag(string.format("<%s%s>\n", tag, parms));
                OutputCellContents(row, col);
                AddTag(string.format("\n</%s>", tag));
            end
        end
        AddTag("</tr>");
    end
    OutputRowModeEnd(prev_row_mode);
    AddTag("</table>");
end

local function GenCodeblkOutput()
    AddOutputLine("");
    AddOutputLine("```");
    for n, line in ipairs(mcgtable.in_lines) do
        AddOutputLine(line);
    end
    AddOutputLine("```");
end

-------------------------------------------------------------------------------
-- Generate output for Merge Cell Grid Table
-------------------------------------------------------------------------------
local function GenOutput()
    if mcgtable.out_fmt == "html" then
        GenHtmlOutput();
    elseif mcgtable.out_fmt == "docbook" then
        --AddOutputLine("```");
        --AddOutputLine("mcgtfixit");
        if (script_mode == SM_PANDOC_FILTER) then
            output_ast = true;
        end
        GenDocbookOutput();
        --AddOutputLine("```");
    else
        GenCodeblkOutput();
    end
end

-------------------------------------------------------------------------------
-- Process a CodeBlock element containing Merge Cell Grid Table markdown
-------------------------------------------------------------------------------
local function ProcCodeBlock(block)
    mcgtable = {};  -- Start a new mcell-grid-table

    -- Set defaults
    mcgtable.verbosity    = VB_WARN;
    mcgtable.rc           = RC_OK;
    mcgtable.cur_row_mode = RM_HEADER;
    mcgtable.row_mode     = {};
    mcgtable.out_fmt      = default_fmt;

    -- TODO: support grabbing parameters from this specific code block's attributes?

    -- Ingest text lines
    mcgtable.in_lines = SplitLines(block.text);

    ParseLines();
    CalcSpans();
    GenOutput();

    if output_ast then
        return mcgtable.output;
    end
    text = table.concat(mcgtable.output, "\n");
    doc  = pandoc.read(text, "markdown")
    return doc.blocks
end

function ExecInPandocFilterMode(pandoc_opts)
    -- Return table with CodeBlock handler
    return
    {
        {
            -- CodeBlock handler called as filter by Pandoc for each instance
            -- of CodeBlock element encountered in document
            CodeBlock = function(block)
                -- If the Codeblock's class type is Merge Cell Grid Table (i.e.
                -- "mcgtable") then forward the CodeBlock data to this filter's
                -- processing function; otherwise ignore it
                if "mcgtable" == block.classes[1] then
                    return ProcCodeBlock(block);
                    --return pandoc.Para {pandoc.Str "Hello, mcell"}
                end
            end,
        }
    }
end


-------------------------------------------------------------------------------
-- Dump internal data structure for debugging
-------------------------------------------------------------------------------
function DumpTable()
    if mcgtable.verbosity < VB_DEBUG then
        return;
    end

    print("mcgtable =");
    print("{");
    print(string.format("    rc           = %d", mcgtable.rc));
    print(string.format("    indent       = %d", mcgtable.indent));
    print(string.format("    exp_line_len = %d", mcgtable.exp_line_len));
    for i, v in ipairs(mcgtable.col_pos) do
        print(string.format("    col_pos[%d] =", i));
        print("    {");
        print(string.format("        hsep_start=%d, hsep_stop=%d, isep_pos=%d", v.hsep_start, v.hsep_stop, v.isep_pos));
        print("    }");
    end
    print("}");
    -- Would use the following, but I want to print out my fake cells at column
    -- zero and row zero so I need to use a manual for-loop to get the zero
    -- indexes instead of the following for-loop using ipairs.
    -- 
    -- for y, row_list in ipairs(mcgtable.row_list) do
    for y = 0,#(mcgtable.row_list) do
        row_list = mcgtable.row_list[y];
        -- Again, use a manual for-loop to get my zero indexes instead of the
        -- following for-loop using ipairs
        --
        -- for x, cell in ipairs(row_list) do
        for x = 0,#(row_list) do
            cell = row_list[x];
            print(string.format("row=%d, col=%d", y, x));
            print(string.format("rowspan=%d, colspan=%d", cell.rowspan, cell.colspan));
            for z, line in ipairs(cell.lines) do
                print(string.format("    text=\"%s\", vsep=\"%s\"", line, cell.vsep[z]));
            end
            if cell.hsep ~= nil then
                print(string.format("    hsep=\"%s\", isep=\"%s\"", cell.hsep, cell.isep));
            end
        end
    end
end


-------------------------------------------------------------------------------
-- Print all output that has been generated
-- 
-- * If we are in filter mode, then the output is Pandoc AST blocks
-- * If we are in command line mode, then the output is text lines
-------------------------------------------------------------------------------
function PrintOutput()
    if (mcgtable == nil) or (mcgtable.output == nil) then
        Error("no output!");
    end

    for i,v in ipairs(mcgtable.output) do
        if script_mode == SM_PANDOC_FILTER then
            -- TODO: handle filter mode
        else
            print(v);
        end
    end
end


-------------------------------------------------------------------------------
-- Print help text
-------------------------------------------------------------------------------
function PrintHelp()
    out_fmt = "codeblock";
    AddOutputLine("\nmcell-grid-table.lua @VERSION@");
    AddOutputLine(string.format("\nUsage: lua %s [options]", script_name));
    AddOutputLine("\nWhere [options] can be any of the following:");
    AddOutputLine("   --to <format>        To output format (like Pandoc)");
    AddOutputLine("   -t <format>          To output format (like Pandoc)");
    AddOutputLine("   --verbosity <level>  Verbosity level: 0=None, 1=Errors, 2=Warnings, 3=Max");
    AddOutputLine("   --help               This help text");
    AddOutputLine("   -h                   This help text");
    AddOutputLine("   -?                   This help text");
    AddOutputLine("   ?                    This help text");
    AddOutputLine("   --version            Prints out version of this script");
    AddOutputLine("\nGenerates Docbook or HTML table tags supporting merged cells within table via");
    AddOutputLine("row spans and column spans.  Pandoc supports passing through these Docbook and");
    AddOutputLine("HTML table tags.  This script runs in one of two modes");
    AddOutputLine("\n- Command line mode");
    AddOutputLine("- As a Pandoc filter");
    AddOutputLine("\nIn both modes this script reads input from STDIN and writes output to STDOUT.");
    PrintOutput();
    return 0;
end


-------------------------------------------------------------------------------
-- Print version text
-------------------------------------------------------------------------------
function PrintVersion()
    out_fmt = "codeblock";
    AddOutputLine("mcell-grid-table.lua @VERSION@");
    AddOutputLine("Copyright (c) 2021 Michael Webster");
    AddOutputLine("Copyright (c) 2021 Western Digital Corporation or its affiliates");
    AddOutputLine("License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>");
    AddOutputLine("This is free software: you are free to change and redistribute it.");
    AddOutputLine("There is NO WARRANTY, to the extent permitted by law.");
    PrintOutput();
    return 0;
end


-------------------------------------------------------------------------------
-- Check format option and return appropriate value
-------------------------------------------------------------------------------
function ProcessFormatOption(fmt)
    if string.find(fmt, "^html") then
        return "html";
    elseif string.find(fmt, "^docbook") then
        return "docbook";
    else
        Warning
        (
            string.format
            (
                "Unsupported output format \"%s\"",
                fmt
            )
        );
        return "codeblk";
    end
end


-------------------------------------------------------------------------------
-- Mainline
-------------------------------------------------------------------------------

-- If we detect Pandoc is running us as a filter then execute in filter mode
-- 
-- See: [Pandoc Lua Filters: Global variables](https://pandoc.org/lua-filters.html#global-variables)
if PANDOC_VERSION ~= nil then
    script_mode = SM_PANDOC_FILTER;
    arg = {};
    arg[0] = PANDOC_SCRIPT_FILE;
    arg[1] = "--to";
    arg[2] = FORMAT;
end

-- Initialize before possible use in Error function
mcgtable.rc             = RC_OK;
mcgtable.cur_row_mode   = RM_HEADER;
mcgtable.row_mode       = {};
mcgtable.out_fmt        = default_fmt;
mcgtable.verbosity      = default_vb;
mcgtable.lines_consumed = 0;           -- So far we've consumed zero lines

script_name = arg[0];

-- Process command line arguments
i = 1;
while arg[i] do
    -- Process options that start with a dash
    if string.find(arg[i], "^%-") then
        if (arg[i] == "--to") or (arg[i] == "-t") then
            if (arg[i+1] == nil) or string.find(arg[i+1], "^%-") then
                Error(string.format("Missing format parameter for option: \"%s\"", arg[i]));
                return PrintHelp();
            end
            default_fmt = ProcessFormatOption(arg[i+1]);
            i = i + 1;  -- Move passed format parameter
        elseif arg[i] == "--verbosity" then
            if (arg[i+1] == nil) or string.find(arg[i+1], "^%-") then
                Error(string.format("Missing level parameter for option: \"%s\"", arg[i]));
                return PrintHelp();
            end
            default_vb = tonumber(arg[i+1], 10);
            if default_vb == nil then
                default_vb = VB_ERROR;
                Error(string.format("Verbosity level parameter is not an integer: \"%s\"", arg[i+1]));
                return PrintHelp();
            end
            if (default_vb < VB_NONE) or (default_vb > VB_DEBUG) then
                default_vb = VB_ERROR;
                Error(string.format("Verbosity level must be %d to %d", VB_NONE, VB_DEBUG));
                return PrintHelp();
            end
            i = i + 1;  -- Move passed verbosity level parameter
        elseif (arg[i] == "--help") or (arg[i] == "-h") or (arg[i] == "-?") then
            return PrintHelp();
        elseif arg[i] == "--version" then
            return PrintVersion();
        else
            Error(string.format("Illegal option: \"%s\"", arg[i]));
            return PrintHelp();
        end
    else  -- If no dash then it is something other than an option
        if arg[i] == "?" then
            -- Do nothing. We are about to print help text anyways.
        else
            Error(string.format("Illegal parameter: \"%s\"", arg[i]));
        end
        return PrintHelp();
    end
    i = i + 1;  -- Move to next command line argument
end

if script_mode == SM_PANDOC_FILTER then
    return ExecInPandocFilterMode(pandoc_opts);
end

-- Otherwise continue executing in command line mode

-- Update some parameters
mcgtable.out_fmt   = default_fmt;
mcgtable.verbosity = default_vb;

-- Ingest text lines
text = io.read("*all");
mcgtable.in_lines = SplitLines(text);

-- Print input for debugging
for i,v in ipairs(mcgtable.in_lines) do
    DebugPrint(string.format("in_line[%d] = \"%s\"", i, v));
end

-- Process input
ParseLines();
CalcSpans();
GenOutput();

-- Print output
PrintOutput();
DumpTable();

return mcgtable.rc;