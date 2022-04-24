Red [Needs: 'View]
#include %style.red
#include %table-template.red
;style 'table tbl

file: %data/RV291_29062020120209394.csv  ;%data/annual-enterprise-survey-2020-financial-year-provisional-csv.csv ;
view/flags/options [  ;/no-wait
	below 
	caption: h1 "Example Table" 
	tb: table 617x267 focus data file options [auto-index: #[true]] ;10x20;[["x" "A" "B"]["y" 1 2]["z" 3 4]] ;with [options: [auto-index: #[false]]];
] 'resize [
	text: form file 
	menu: ["File" ["Open" open "Save" save "Save as ..." save-as]]
	actors: object [
		on-resizing: func [face event][
			tb/size: face/size - as-pair 20 30 + caption/size/y 
			table-ctx/resize tb
		]
		on-resize: func [face event][
			face/actors/on-resizing face event
		]
		on-menu: func [face event][
			switch event/picked [
				open [
					if file: request-file/title "Open file" [
						tb/data: file 
						tb/table/data: load file ;load/as head clear tmp: find/last read/part file 5000 lf 'csv;
						table-ctx/init tb 
						face/text: form file
					]
				]
				save [
					either file? tb/data [
						switch suffix? tb/data [
							%.red [out: new-line/all tb/table/data true write tb/data out]
							%.csv [write tb/data to-csv tb/table/data]
						]
					][
						if file: request-file/save/title "Save file as" [
							write file tb/table/data
							tb/data: file
							face/text: form file
						]
					]
				]
				save-as [
					if file: request-file/save/title "Save file as" [
						write file tb/table/data
						tb/data: file
						face/text: form file
					]
				]
			]
		]
	]
]
;tb/table/data: load tb/data 
;tb/table/init/force tb
;show tb
;do-events
