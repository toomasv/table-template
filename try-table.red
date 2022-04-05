Red []
#include %table-template.red
style 'table tpl

file: %data/RV291_29062020120209394.csv  ;annual-enterprise-survey-2020-financial-year-provisional-csv.csv ;
view/flags/options [
	on-resize [system/view/auto-sync: off tb/size: face/size - as-pair 20 30 + h/size/y show tb system/view/auto-sync: on] 
	on-menu [
		switch event/picked [
			open [
				if file: request-file/title "Open file" [
					tb/data: file 
					tb/actors/data: load file
					tb/actors/init tb face/text: form file
				]
			]
			save []
		]
	]
	below h: h1 "Example Table" tb: table 617x267 data file ;with [options: [auto-index: #[false]]]
	react later [
		actors: face/actors
		actors/size: face/size - 17
		actors/adjust-size
		actors/init-fill face
		actors/init-indices face
		actors/fill face 
	]
	;button [probe tb/options]
] 'resize [text: form file menu: ["File" ["Open" open "Save" save]]]
