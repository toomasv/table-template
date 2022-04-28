# table-template
Template for table style

To enable table style:
```
tbl: #include %table-template.red
style 'table tbl
```
After that table style can be used in layout, as e.g.
```
view [table]
```
This will create an empty table with default size of 317x217 and grid 3x8. Default cell size is 100x25. Both vertial and horizontal scrollers are always included. Scrollers are 17 points thick.

Specifying size for table will fill the extra space with additional cells.
```
view [table 717x517]]
```
This will create an empty table with 7x20 grid.

Grid size of table can be specified separately, e.g.
```
view [table 717x517 data 10x50 options [auto-index: #[true]]
```
When `auto-index` is set to `true` an extra column will be created, automatically enumerated. By this the original order of rows can be restored whenever necessary.
This will create table with eleven columns (10 requested + 1 auto-index) and 50 rows, but in previous boundaries.

When instead of grid size a block is presented as data, this block is interpreted as table. Block should consist of row blocks of equal size. E.g.
```
view [table 717x517 data [["" A B][1 First Row][2 Second Row]]]
```
Values are formed to be presented in table.

Instead of giving data directly as block, file name or url may be specified, to be loaded as table, e.g.
```
view [
    table 717x515 
    data https://support.staffbase.com/hc/en-us/article_attachments/360009197011/username-password-recovery-code.csv 
    options [delimiter: #";"]
]
```
Non-standard delimiter (standard is comma) can currently be specified for urls only.

If you have set up sqlite, data source may be specified as sql query, e.g.
```
sql-query: func [sql][
    out: copy ""
    call/output rejoin [{sqlite3 -csv -header C:\Users\Toomas\sqlite\chinook.db "} sql {"}]  out
    load/as out 'csv
]
view [
    table 717x517 with [
        data: sql-query "select TrackId, Name, Title, Composer from tracks inner join albums on tracks.AlbumID = albums.AlbumId"
    ]
]
```

## Features

**Row and column sizes** can be changed by dragging on cell border. If holding down control while dragging, sizes of all following rows/columns will be changed too. If ctrl-dragging on first row/column, default size is changed.


**Scrolling** will move the whole grid together with selection. **Wheeling** will sroll table vertically by 3 rows, with ctrl-down by page. Shift-wheel scrolls table horizontally.

Navigation by keys moves **selection**, extending it with shift-down. Moving selection outside of visual borders will automatically scroll table if not in end already. Selection is also moved by clicking on cells (if not on/near border), extending selection with shift-down and/or ctrl-down.

**Freezing** of rows and/or columns is enabled from local menu. Right-click on row/column/cell which you want to freeze and choose "Freeze" from submenu of cell, row or column. Frozen rows/columns are dark-colored. Freezing can be repeated, e.g. if table is scrolled after previous freezing. "Unfreeze" removes all freezing correspondingly from cells/rows/columns. To unfreeze, it is not necessary to place mouse on corresponding row/column as when freezing.

**Sorting** is currently possible by single column only. With mouse on column to be sorted by, select "Up" or "Down" from Column->Sort submenu. Table is sorted from non-frozen rows downward. If table is created from csv file, then all data is of type `string!`, and sorted accordingly. To sort by loaded values, choose Column->Sort->Loaded... or convert column to different type before sorting (see below). The only way to restore original order currently is to sort by column that holds original order (e.g. with options/auto-index set to `true`).

**Filtering** is so far also possible by single column at time only. As with sorting, only non-frozen rows are considered. Select Column->Filter from local menu and enter selection criteria. There is special format for criteria. It may start with operator, e.g. `< 100` (provided data is of corresponding type - see type changing below), or with function name expecting data as its first argument, but without specifying this argument, e.g. `find charset [#"a" #"e" #"i" #"o" #"u"]`. Missing argument will be inserted automatically. Repeated filtering will consider already filtered rows only (but it is buggy :)). To remove filter choose Column->Unfilter from local menu.

TBD:
Copying/pasting

Cell editing is activated with double-click or enter on cell, and committed with enter.
