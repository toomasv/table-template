Red []
comment {
set-current-dir %/C/Users/Toomas/Documents/Red/table
do %table-template.red
view [tb: table 1017x817 return panel [origin 0x0 button "Next" [tb/actors/next-chunk tb cols/text: form tb/actors/total/x rows/text: form tb/actors/total/y loaded/text: form to-percent round/to tb/actors/big-last / tb/actors/big-size 0.01] text 30 "Cols:" cols: text 30 text 30 "Rows:" rows: text 50 text 45 "Loaded:" loaded: text 30]]


update: does [cols/text: form tb/actors/total/x rows/text: form tb/actors/total/y loaded/text: form to-percent round/to tb/actors/big-last + tb/actors/big-length / tb/actors/big-size 0.01 size/text: append form round/to tb/actors/big-size / 1000000 0.1 "MB"] 
view [tb: table 617x417 return panel [origin 0x0 button "Prev" [tb/actors/prev-chunk tb update] button "Next" [tb/actors/next-chunk tb update] text 30 "Cols:" cols: text 30 text 30 "Rows:" rows: text 50 text 45 "Loaded:" loaded: text 30 text 30 "Size:" size: text 60]]

;--------------
}

;cd table
;set-current-dir %/C/Users/Toomas/Documents/Red/table
do %table-template.red

update-info: func [face][
	cols/text: form face/actors/total/x 
	rows/text: form face/actors/total/y 
	clear loaded/text ;: form to-percent round/to face/actors/big-last + face/actors/big-length / face/actors/big-size 0.01 
	clear size/text ;: append form round/to face/actors/big-size / 1000000 0.1 "MB"
] 
update-big: func [face][
	cols/text: form face/actors/total/x 
	rows/text: form face/actors/total/y 
	loaded/text: form to-percent round/to face/actors/big-last + face/actors/big-length / face/actors/big-size 0.01 
	size/text: append form round/to face/actors/big-size / 1000000 0.1 "MB"
] 
;https://datatopics.worldbank.org/world-development-indicators/
files: read dr: %data/WDI/
forall files [files/1: form files/1]
view [
	button "Query" 150 [/local [fields field heads ind cols data start condition attributes]
		fields: copy []
		parse load no-SQL/text [
			'SELECT set fields block!
			'FROM set tabl file! 
			'WHERE set condition block! 
			opt ['WITH set attributes block!]
		]
		;probe reduce [fields tabl condition]
		cond: head insert next copy {""} condition/3
		data: parse read rejoin [%data/WDI/ tabl] [
			collect [
				copy header thru lf (
					heads: load replace/all copy header #"," " "
					ind: -1 + index? find heads condition/1
					cols: copy []
					not-found: copy []
					foreach field fields [
						either found: find heads field [
							append cols index? found
						][
							append not-found field
						]
					]
				)
				keep (header)
				any [
					start: ind [thru comma] {"} copy val to {"} if (condition/1: val do condition) :start keep thru lf
				| 	thru lf
				]
			]
		]
		if attributes [
			either attributes/col-index [
				attributes/col-index: cols
			][
				insert attributes compose/only [col-index: (cols)]
			]
		]
		;probe attributes
		;write %tmp2 
		queried: rejoin data
		;either 2000000 < length? queried [
			
		;][
			tb/actors/data: load-csv queried
			tb/actors/open-red-table/only tb any [attributes compose/only [frozen-rows: [1] col-index: (cols)]]
			update-info tb
		;]
		if not empty? not-found [probe reduce ["WARNING! Not-found:" not-found]]
	]
	no-SQL: area 600x75 {SELECT ["Country Name" "Indicator Name" "2010" "2011" "2012" "2013" "2014" "2015" "2016" "2017" "2018" "2019" "2020"] 
FROM %WDIData.csv WHERE ["Country Name" = "Estonia"]
WITH [frozen-rows: [1] frozen-cols: [1] col-sizes: [1 200 3 300] box: 50x25]}
	return
	text-list 150x400 data files 
	on-change [
		tb/data: to-file pick face/data face/selected 
		tb/actors/open-big-table/with tb rejoin [dr tb/data]
		update-big tb
	]
	tb: table 617x417 
	return panel [
		origin 0x0 
		button "Prev"    [tb/actors/prev-chunk tb update-big tb] 
		button "Next"    [tb/actors/next-chunk tb update-big tb] 
		text 30 "Cols:"   cols: text 30 
		text 30 "Rows:"   rows: text 50 
		text 45 "Loaded:" loaded: text 30 
		text 30 "Size:"   size: text 60
	]
]