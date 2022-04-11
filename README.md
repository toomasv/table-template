# table-template
Template for table style

To enable table style:
```
#include %table-template.red
style 'table tpl
```
After that table style can be used in layout, as e.g.
```
view [table 717x517 options [auto-index: #[false]]]
```
This will create an empty table with 7x20 grid. Default cell size is 100x25. Both vertial and horizontal scrollers are always included. Scrollers are 17 points thick.
If `auto-index` is not set to false an extra columun will be created, automatically enumerated. By this the original order of rows can be restored whenever necessary.

Grid size of table can be determined separately, e.g.
```
view [table 717x517 data 10x50]
```
This will create table with eleven columns (10 requested + 1 auto-index) and 50 rows, but in previous boundaries.

When instead of grid size a block is presented as data, this block is interpreted as table. Block should consist of row blocks of equal size. E.g.
```
view [table 717x517 data [["" A B][1 First Row][2 Second Row]] options [auto-index: #[false]]]
```
Values are formed to be presented in table.

Instead of giving data diretly as block, file name or url may be specified, to be loaded as table, e.g.
```
view [
    table 717x515 
    data https://support.staffbase.com/hc/en-us/article_attachments/360009197011/username-password-recovery-code.csv 
    options [auto-index: #[false] delimiter: #";"]
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
        options: [auto-index: #[false]]
    ]
]
```

