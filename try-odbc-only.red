Red [Needs: 'View]
#include %table-template.red
context [
	render: function [statement /columns][
		content/data: content/actors/data: copy statement 
		insert/only content/data extract next statement/state/columns 10
		opts: either columns [
			[frozen-rows: [1] col-index [4 5 6 7 8 9 10 11 12 13 14 15 16 17 18]]
		][
			[frozen-rows: [1]]
		]
		content/actors/use-state/with content opts
	]
	sources: ["mariadb" "mysql" "postgres" "sqlite" "text"] 
	default: ["nation" "sakila" "dvdrental" none "C:\CSV\WDI" ]
	
	dbs: tbls: sql: sql?: cols?: none ; content:
	source: database: none
	connection: statement: none
	
	view [
		on-close [print "Closing..." close connection]
		panel [
			origin 0x0 
			below 
			drop-down 150 data sources
			on-change [/local [default-sql databases]
				source: pick face/data face/selected
				connection: open rejoin [odbc:// source]
				change statement: open connection [flat?: yes]
				columns: insert statement compose [tables (default/(face/selected)) none none "TABLE"]
				databases: unique extract copy statement 5
				dbs/data: databases 
				dbs/selected: 1
				dbs/actors/on-change dbs none
			]
			dbs: drop-down 150 data [] on-change [/local [tables err]
				database: pick face/data face/selected
					columns: insert statement compose [tables (database) none none "TABLE"] 
					tables: extract at copy statement 3 5 
				tbls/data: tables
				change statement [flat?: no] 
				tbls/selected: 1 
				tbls/actors/on-change tbls none
			]
		] 
		pad -2x0 sql: area 490x60 wrap
		panel [
			origin 0x0
			sql?: radio data #[true] 15 on-change [tbls/actors/on-change tbls none]
			button "Query" 75 [
				insert statement sql/text
				render statement
			]
			return
			cols?: radio 15 
		]
		return 
		tbls: text-list 150x400 data [] on-change [/local [table qry]
			table: pick face/data face/selected
			qry: either sql?/data [
				rejoin ["SELECT * FROM " table]
			][
				compose [columns none none (table)]
			]
			insert statement qry
			either sql?/data [
				render statement
			][
				render/columns statement
			]
		]
		content: table 617x417
	]
]