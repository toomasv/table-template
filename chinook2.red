Red []
#include %table-template.red
sql-query: func [sql][; /header /db name][
	out: copy ""
	call/output rejoin [{sqlite3 -csv -header C:\Users\Toomas\sqlite\chinook.db "} sql {"}]  out
	load/as out 'csv
]


tables: next extract sql-query {SELECT name FROM sqlite_master WHERE type='table' and name not like 'sqlite_%'} 1
forall tables [tables/1: tables/1/1]

keep-opts?: yes

if not all [value? 'table-opts keep-opts?] [table-opts: make map! 0]

lay: view/no-wait/flags [
	title "SQLite: Chinook.db"
	on-resizing [
		pan/size/x: face/size/x - pan/offset/x - 10
		qry/size/x: pan/size/x - 127
		tbls/size/y: face/size/y - tbls/offset/y - inf/size/y - 16
		content/size: face/size - content/offset - 10x0 - (as-pair 0 inf/size/y)
		inf/offset: as-pair face/size/x - 180 face/size/y - inf/size/y
		content/actors/resize content
	]
	on-resize [face/actors/on-resizing face event]
	pan: panel [
		origin 0x0
		button 100 "Query" [
			content/data: act/data: sql-query qry/text
			act/use-state/with content [frozen-rows: [1]]
			act/fill content
			act/adjust-scroller content
			rows/text: form act/total/y
			cols/text: form act/total/x
		]
		pad -2x0 qry: area 500x75 wrap
	]
	return
	tbls: text-list 100x300 data tables select 1
	on-select [
		tbl: pick face/data face/selected
		table-opts/:tbl: copy/deep act/save-state/only/except content [row-index col-index]
	]
	on-change [
		sql: rejoin [{select * from } tbl: pick face/data face/selected]
		content/data: act/data: sql-query sql
		state: copy any [table-opts/:tbl [frozen-rows: [1] col-type: [1 integer!]]]
		act/use-state/with content state
		act/fill content 
		act/adjust-scroller content
		rows/text: form act/total/y
		cols/text: form act/total/x
	]
	content: table 517x317 156.156.156 with [
		data: sql-query rejoin [{select * from } pick tbls/data tbls/selected] 
	]
	return
	inf: panel [
		origin 0x0
		text 30 "Rows:" rows: text 30 text 50 "Columns:" cols: text 30
	] with [size: 170x16]
] 'resize

act: content/actors
name: pick tbls/data tbls/selected
act/use-state/with content either all [table-opts/:name keep-opts?] [
	table-opts/:name
][
	[frozen-rows: [1] col-type: [1 integer!]]
]
rows/text: form act/total/y
cols/text: form act/total/x

comment [
sql: [
"SELECT name,sql FROM sqlite_master WHERE type='table' and name not like 'sqlite_%'"
"select * from tracks inner join albums on tracks.AlbumID = albums.AlbumId"
"select TrackId,Name,Title,Composer from tracks inner join albums on tracks.AlbumID = albums.AlbumId"
{SELECT TrackId, tracks.Name AS Track,Composer,Title,artists.Name AS Artist 
FROM tracks INNER JOIN albums ON tracks.AlbumID = albums.AlbumId 
INNER JOIN artists ON albums.ArtistId = artists.ArtistId}]
]
do-events
;parse [collect any ["([" thru "])" | "[" keep to "]" keep (lf) | skip]]