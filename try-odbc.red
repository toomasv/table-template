Red [Needs: 'View]
#include %table-template.red
context [
	render: function [statement][
		content/data: content/actors/data: copy statement
		insert/only content/data extract next statement/state/columns 10
		content/actors/use-state/with content [frozen-rows: [1]]
	]
	profile: to-map reduce [
		"mariadb" context [
			shell: "mysql -u root -P 3306 --batch -D "
			command: function [database text][
				cmd-line: rejoin [shell database either #"-" = first trim text [text][rejoin [{ -e "} text {"}]]]
				call/output cmd-line out: copy ""
				load-csv/with out tab
			]
			databases: "SHOW DATABASES"
			tables: does [insert statement rejoin ["USE " database] "SHOW TABLES"]
			columns: function [database table][
				cmd-line: rejoin [shell database { -e "SHOW COLUMNS FROM } table {"}]
				call/output cmd-line out: copy ""
				load-csv/with out tab
			]
			query: function [table][insert statement rejoin ["SELECT * FROM " table]]
			default-db:  "nation"
			default-sql: {SELECT countries.name AS Country, regions.name AS Region from countries,regions 
WHERE countries.region_id = regions.region_id}
		]
		"mysql" context [
			shell: "mysql -u root -P 3307 --batch -D " ;mysqlsh
			command: function [database text][
				cmd-line: rejoin [shell database either #"-" = first trim text [text][rejoin [{ -e "} text {"}]]]
				call/output cmd-line out: copy ""
				load-csv/with out tab
			]
			databases: "SHOW DATABASES"
			tables: does [insert statement rejoin ["USE " database] "SHOW TABLES"]
			columns: function [database table][
				cmd-line: rejoin [shell database { -e "SHOW COLUMNS FROM } table {"}]
				call/output cmd-line out: copy ""
				load-csv/with out tab
			]
			query: function [table][insert statement rejoin ["SELECT * FROM " table]]
			default-db:  "sakila"
			default-sql: "SELECT city, country from city,country WHERE country.country_id = city.country_id"
		]
		"postgres" context [
			shell: "psql -U postgres -p 5433 --csv -d "
			command: function [database text][
				cmd-line: rejoin [shell database { -c "} text {"}]
				call/output cmd-line out: copy ""
				out
			]
			databases: "SELECT datname FROM pg_database"
			tables: "SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public'"
			columns: function [database table][
				cmd-line: rejoin [shell database { -c "\d } table {"}]
				call/output cmd-line out: copy ""
				load-csv out
			]
			query: function [table][insert statement rejoin ["SELECT * FROM " table]]
			default-db:  "dvdrental"
			default-sql: "SELECT address, city from address, city WHERE address.city_id = city.city_id"
		]
		"sqlite" context [
			shell: "sqlite3 -csv C:\sqlite\db\"
			command: function [database text][
				cmd-line: rejoin [shell database { --header "} text {"}]
				call/output cmd-line out: copy ""
				load-csv out
			]
			databases:  ["chinook.db"]
			tables:     has [sql out][
				sql: "SELECT name FROM sqlite_master WHERE type ='table' AND name NOT LIKE 'sqlite_%'"
				cmd-line: rejoin [shell database { "} sql {"}]
				call/output cmd-line out: copy ""
				split out lf
			]
			columns: function [database table][
				cmd-line: rejoin [shell database { --header "PRAGMA table_info(} table {)"}]
				call/output cmd-line out: copy ""
				load-csv out
			]
			query: function [table][insert statement rejoin ["SELECT * FROM " table]]
			default-db: "Chinook.db"
			default-sql: none
		]
		"text" context [
			databases: ["WDI"]
			tables: has [files][
				files: read %data/WDI/ 
				forall files [
					either %.csv = suffix? files/1 [
						files/1: to-string files/1
					][
						remove files 
						files: back files
					]
				]
				files
			]
			query: function [table][
				;insert/part statement probe rejoin ["SELECT * FROM " table] 50
				insert statement probe rejoin ["SELECT * FROM " table]
				;head statement
			]
			default-db: "WDI"
			default-sql: none
		]
	]
	schemas: keys-of profile ;["mariadb" "mysql" "postgres" "sqlite" "text"] ;
	dbs: tbls: sql: shell: sql?: shell?: none ; content:
	prof: schema: database: table: none
	connection: statement: none
	
	view [
		on-close [print "Closing..." close connection]
		panel [
			origin 0x0 
			below 
			drop-down 150 data schemas
			on-change [/local [default-sql databases]
				schema: pick face/data face/selected
				connection: open rejoin [odbc:// schema]
				prof: profile/:schema
				statement: open connection 
				change statement  [flat?: yes]
				either string? databases: prof/databases [
					insert statement databases
					dbs/data: copy statement  
					dbs/selected: index? find dbs/data prof/default-db 
				][
					dbs/data: databases 
					dbs/selected: 1
				]
				sql/text: any [prof/default-sql copy ""]
				dbs/actors/on-change dbs none
			]
			dbs: drop-down 150 data [] on-change [/local [tables]
				database: pick face/data face/selected
				either string? tables: prof/tables [
					insert statement tables
					change statement [flat?: yes]
					tbls/data: copy statement  
				][
					tbls/data: tables
				]
				change statement [flat?: no] 
				tbls/selected: 1
				tbls/actors/on-change tbls none
			]
		] 
		pad -2x0 sql: area 490x60 wrap
		at 0x0 shell: area 490x60 wrap hidden on-created [face/offset: sql/offset]
		panel [
			origin 0x0
			sql?: radio data #[true] 15 on-change [tbls/actors/on-change tbls none]
			button "Query" 75 [
				insert statement sql/text
				render statement
			]
			return
			shell?: radio 15 on-change [
				set-focus either shell/visible?: face/data [shell][sql]
			]
			button "Shell" 75 [/local [sql-text out]
				out: prof/command database shell/text
				content/data: content/actors/data: out
				content/actors/use-state/with content [frozen-rows: [1]]
			]
		]
		return 
		tbls: text-list 150x400 data [] on-change [/local [table out query]
			table: pick face/data face/selected
			either sql?/data [
				prof/query table
				render statement
			][
				out: prof/columns database table
				content/data: content/actors/data: out
				content/actors/use-state/with content [frozen-rows: [1]]
			]
		]
		content: table 617x417
		;return
		;button 40 "<" [] 
		;field  45 ""  [] 
		;button 40 ">" []
	]
]