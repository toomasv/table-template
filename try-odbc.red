Red []
#include %table-template.red

render: function [statement][
	content/data: content/actors/data: copy statement
	insert/only content/data extract next statement/state/columns 10
	content/actors/use-state/with content [frozen-rows: [1]]
]
default-db: [
	"mariadb"  "nation" 
	"mysql"    "sakila" 
	"postgres" "dvdrental" 
	;"sqlite"   "chinook"
]
default-sql: [
	"mariadb" "SELECT countries.name AS Country, regions.name AS Region from countries,regions WHERE countries.region_id = regions.region_id"
	"mysql" "SELECT city, country from city,country WHERE country.country_id = city.country_id"
	"postgres" "SELECT address, city from address, city WHERE address.city_id = city.city_id"
]
view [
	on-close [print "Closing..." close connection]
	panel [
		origin 0x0 
		below 
		button "Query" 150 [
			insert statement sql/text
			render statement
		]
		db: drop-down 150 data ["mariadb" "mysql" "postgres"]; "sqlite"] 
		on-change [
			connection: open rejoin [odbc:// selection: face/data/(face/selected)] 
			statement: open connection 
			change statement  [flat?: yes]
			switch selection [
				"mariadb" "mysql" [insert statement "SHOW databases"]
				"postgres" [insert statement "SELECT datname FROM pg_database"]
			] 
			sql/text: copy default-sql/:selection
			either selection = "sqlite" [
				dbs/data: ["Chinook"] dbs/selected: 1
			][
				dbs/data: copy statement  
				dbs/selected: index? find dbs/data select default-db selection
			]
			dbs/actors/on-change dbs none
		]
		dbs: drop-down 150 data [] on-change [
			;statement: open connection
			switch selection [
				"mariadb" "mysql" [
					insert statement rejoin ["USE " face/data/(face/selected)]
					insert statement "SHOW tables"
				]
				"postgres" [
					insert statement rejoin ["SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public'"]
				]
				"sqlite" [
				insert statement rejoin ["SELECT name FROM sqlite_master WHERE type ='table' AND name NOT LIKE 'sqlite_%'"]
				]
			]
			change statement  [flat?: yes]
			tbls/data: copy statement  
			tbls/selected: 1
			change statement [flat?: no]
			tbls/actors/on-change tbls none
			;close statement
		]
	] 
	pad -2x0 sql: area 600x95 
	return 
	tbls: text-list 150x400 data [] on-change [
		;statement: open connection
		insert statement rejoin ["SELECT * FROM " face/data/(face/selected)]
		render statement
	]
	content: table 617x417
]