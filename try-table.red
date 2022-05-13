Red [Needs: 'View]
#include %table-template.red

file: %data/RV291.csv  ;%data/annual-enterprise-survey.red ;
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
				open [if file: tb/actors/open-table tb [face/text: form file]]
				save [if file: tb/actors/save-table tb [face/text: form file]]
				save-as [if file: tb/actors/save-table-as tb [face/text: form file]]
			]
		]
	]
]
;tb/actors/data: load tb/data 
;tb/actors/init/force tb
;show tb
;do-events
