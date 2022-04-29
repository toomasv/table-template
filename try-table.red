Red [Needs: 'View]
tbl: #include %table-template.red
style 'table tbl

file: %data/RV291_29062020120209394.csv  ;%data/annual-enterprise-survey-2020-financial-year-provisional-csv.csv ;
view/flags/options [  ;/no-wait
	below 
	caption: h1 "Example Table" 
	tb: table 617x267 focus data file options [auto-index: #[true]] ;10x20;[["x" "A" "B"]["y" 1 2]["z" 3 4]] ;with [options: [auto-index: #[false]]];
] 'resize [
	text: form file 
	menu: ["File" ["Open ..." open "Save" save "Save as ..." save-as]]
	actors: object [
		on-resizing: func [face event][
			tb/size: face/size - as-pair 20 30 + caption/size/y 
			tb/actors/resize tb
		]
		on-resize: func [face event][
			face/actors/on-resizing face event
		]
		on-menu: function [face event][
			switch event/picked [
				open [
					if file: request-file/title "Open file" [
						tb/data: file 
						data: load file
						either all [
							%.red = suffix? file 
							data/1 = 'Red
							block? opts: data/2 
							opts/current
						][
							tb/actors/open-red-table tb data
						][
							tb/actors/data: load file ;load/as head clear tmp: find/last read/part file 5000 lf 'csv;
							tb/actors/init tb 
						]
						face/text: form file
					]
				]
				save [
					either file? tb/data [
						tb/actors/save-table tb
					][
						tb/actors/save-table-as tb
					]
				]
				save-as [tb/actors/save-table-as tb]
			]
		]
	]
]
;tb/actors/data: load tb/data 
;tb/actors/init/force tb
;show tb
;do-events
