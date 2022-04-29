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
	menu: ["File" ["Open" open "Save" save "Save as ..." save-as]]
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
							tb/actors/data: remove/part data 2
							tb/options/auto-index: 'true = opts/auto-index
							tb/actors/frozen: as-pair length? opts/frozen-cols length? opts/frozen-rows
							tb/actors/frozen-nums/x: tb/actors/frozen-cols: opts/frozen-cols
							tb/actors/frozen-nums/y: tb/actors/frozen-rows: opts/frozen-rows
							tb/actors/total/y: index? find/last data block!
							tb/actors/total/x: length? data/1
							tb/actors/index/x: opts/col-index
							tb/actors/index/y: opts/row-index
							tb/actors/default-row-index: opts/default-row-index
							tb/actors/default-col-index: opts/default-col-index
							tb/actors/box: opts/box
							tb/actors/sizes: opts/sizes
							tb/actors/top: opts/top
							tb/actors/current: opts/current
							tb/actors/col-types: opts/col-types
							;foreach [k v] tb/actors/col-types [if attempt/safer [datatype? get/any v][tb/actors/col-types/k: get v]]
							tb/selected: opts/selected
							
							tb/actors/set-freeze-point tb
							tb/actors/adjust-scroller tb
							tb/actors/set-last-page
							tb/actors/fill tb
							tb/actors/show-marks tb
							tb/actors/anchor: opts/anchor
							tb/actors/active: opts/active
							tb/actors/pos: opts/pos
							set 'opening true
						][
							tb/actors/data: load file ;load/as head clear tmp: find/last read/part file 5000 lf 'csv;
							tb/actors/init tb 
						]
						face/text: form file
					]
				]
				save [
					either file? tb/data [
						switch suffix? file: tb/data [
							%.red [
								out: new-line/all tb/actors/data true 
								opts: compose/only [
									;file: (file)
									;total: (tb/actors/total)
									;frozen: (tb/actors/frozen)
									;grid: (tb/actors/grid)
									frozen-rows: (tb/actors/frozen-rows)
									frozen-cols: (tb/actors/frozen-cols)
									top: (tb/actors/top)
									current: (tb/actors/current)
									sizes: (tb/actors/sizes)
									box: (tb/actors/box)
									row-index: (tb/actors/row-index)
									col-index: (tb/actors/col-index)
									default-row-index: (tb/actors/default-row-index)
									default-col-index: (tb/actors/default-col-index)
									auto-index: (either ai: tb/options/auto-index [quote #[true]][quote #[false]])
									col-types: (tb/actors/col-types)
									selected: (tb/selected)
									anchor: (tb/actors/anchor)
									active: (tb/actors/active)
									pos: (tb/actors/pos)
								]
								save/header tb/data out opts
							]
							%.csv [write tb/data to-csv tb/actors/data]
						]
					][
						if file: request-file/save/title "Save file as" [
							write file tb/actors/data
							tb/data: file
							face/text: form file
						]
					]
				]
				save-as [
					if file: request-file/save/title "Save file as" [
						write file tb/actors/data
						tb/data: file
						face/text: form file
					]
				]
			]
		]
	]
]
;tb/actors/data: load tb/data 
;tb/actors/init/force tb
;show tb
;do-events
