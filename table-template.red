Red []
;#include %../utils/leak-check.red
#include %style.red
#include %CSV.red
#include %re.red
~: make op! func [a b][re a b]
tbl: [
	type: 'base 
	size: 317x217 
	color: silver
	flags: [scrollable all-over]
	;options: [auto-index: #[true]]
	menu: [
		"Cell" [
			"Freeze"   freeze-cell
			"Unfreeze" unfreeze-cell
			"Edit"     edit-cell
		] 
		"Row" [
			"Freeze"         freeze-row
			"Unfreeze"       unfreeze-row
			"Default height" default-height
			"Show" [
				"Select"     select-row
				"Hide"       hide-row
				"Unhide"     unhide-row
				"Remove"     remove-row
				"Restore"    restore-row
				"Delete"     delete-row
				"Insert"     insert-row
				"Append"     append-row
			]
			"Move" [
				"Top"        move-row-top
				"Up"         move-row-up
				"Down"       move-row-down
				"Bottom"     move-row-bottom
				"By ..."     move-row-by
				"To ..."     move-row-to
			]
			"Find ..."       find-in-row
			;"Edit"           edit-row
		] 
		"Column" [
			"Sort"   [
				"Loaded" [
					"Up"   sort-loaded-up 
					"Down" sort-loaded-down
				] 
				"Up"   sort-up 
				"Down" sort-down
			]
			"Unsort"        unsort
			"Filter ..."    filter
			"Unfilter"      unfilter
			"Freeze"        freeze-col
			"Unfreeze"      unfreeze-col
			"Show" [
				"Select"        select-col
				"Default width" default-width
				"Full height"   full-height
				"Hide"          hide-col
				"Unhide"        unhide-col
				"Remove"        remove-col
				"Restore"       restore-col
				"Delete"        delete-col
				"Insert"        insert-col
				"Append"        append-col
			]
			"Move" [
				"First"         move-col-first
				"Left"          move-col-left
				"Right"         move-col-right
				"Last"          move-col-last
				"By ..."        move-col-by
				"To ..."        move-col-to
			]
			"Find ..."      find-in-col
			"Edit ..."      edit-column
			"Type"   [
				"integer!" integer! 
				"float!"   float! 
				"percent!" percent! 
				"string!"  string! 
				"char!"    char!
				"block!"   block! 
				"date!"    date! 
				"time!"    time!
				"logic!"   logic!
				"tuple!"   tuple!
				"image!"   image!
				"Load"     load
				"Draw"     draw
				"Do"       do
				"Icon"     icon
			]
		]
		"Table" [
			"Unhide"    [
				"All"    unhide-all
				"Row"    unhide-row
				"Column" unhide-col
			]
			"Default height" remove-full-height
			;"Default width"  set-table-default-width
			"Open ..."    open-table
			"Open big ..." open-big
			"Save"        save-table
			"Save as ..." save-table-as
			"Use state ..." use-state
			"Save state as ..." save-state
			"Clear color" clear-color
			"Select named range" []
			"Forget names" forget-names
		]
		"Selection" [
			"Copy"      copy-selected
			"Cut"       cut-selected
			"Paste"     paste-selected
			;"Transpose" transpose
			"Set Color" color-selected
			"Set Name"  name-selected
		]
	]
	actors: [
		scroller: data: 
		indexes: filtered: 
		default-row-index: row-index: 
		default-col-index: col-index: 
		full-height-col:
		on-border?: 
		tbl-editor: 
		marks: anchor: active: pos:
		extra?: extend?: 
		same-offset?: none
		
		total: size: 0x0
		frozen: freeze-point: 0x0
		current: top: 0x0
		grid: grid-size: grid-offset: 0x0
		last-page: 0x0
		default-box: box: 100x25
		tolerance: 20x5
		
		frozen-cols: make block! 20
		frozen-rows: make block! 20
		draw-block:  make block! 1000
		filter-cmd:  make block! 10
		;selected-data: make block! 10000
		;selected-range: make block! 10
		sizes: make map! 2
		sizes/x: make map! copy []
		sizes/y: make map! copy []
		frozen-nums: make map! 2
		frozen-nums/x: frozen-cols
		frozen-nums/y: frozen-rows
		
		index: make map! 2
		col-type: make map! 5
		colors: make map! 100
		
		no-over: false
		true-char:  #"^(2714)" ;#"^(2713)"
		false-char: #"^(274C)" ;#"^(2717)"
		
		names: make map! 10
		big-last: big-length: big-size: prev-length: 0
		prev-lengths: make block! 100

		; SETTING
		
		set-border: function [face [object!] ofs [pair!] dim [word!]][
			ofs: ofs/:dim
			cum: 0     ;accumulator
			repeat i frozen/:dim [
				cum: cum + get-size dim frozen-nums/:dim/:i
				if 2 >= absolute cum - ofs [return i]
			]
			cur: current/:dim
			fro: frozen/:dim
			repeat i grid/:dim [
				run: cur + i
				cum: cum + get-size dim index/:dim/:run
				if 2 >= absolute cum - ofs [return fro + i]
			]
			0
		]

		on-border: function [face [object!] ofs [pair!]][
			border: 0x0
			border/x: set-border face ofs 'x
			border/y: set-border face ofs 'y
			either border = 0x0 [false][border]
		]

		set-grid: function [face [object!]][
			foreach dim [x y][
				cur: current/:dim
				;if dim = y probe reduce [total/y cur total/y - cur]
				i: sz: 0
				if 0 < steps: total/:dim - cur [
					repeat i steps [
						j: cur + i
						sz: sz + get-size dim index/:dim/:j
						if sz >= grid-size/:dim [
							grid-offset/:dim: sz - grid-size/:dim 
							break
						]
					]
				]
				grid/:dim: i
			]
		]
		
		set-freeze-point: func [face [object!]][
			freeze-point: 0x0
			if frozen/y > 0 [freeze-point/y: face/draw/(frozen/y)/1/7/y]
			if frozen/x > 0 [freeze-point/x: face/draw/1/(frozen/x)/7/x]
			grid-size: size - freeze-point
			freeze-point
		]
		
		set-freeze-point2: func [face [object!] /local i][
			freeze-point: 0x0
			if frozen/y > 0 [
				repeat i frozen/y [
					freeze-point/y: freeze-point/y + get-size 'y frozen-rows/:i
				]
			]
			if frozen/x > 0 [
				repeat i frozen/x [
					freeze-point/x: freeze-point/x + get-size 'x frozen-cols/:i
				]
			]
			grid-size: size - freeze-point
			freeze-point
		]
		
		set-grid-offset: func [face [object!] /local end][
			end: get-draw-offset/end face frozen + grid
			grid-offset: end - size
		]
		
		set-last-page: function [][
			foreach dim [x y][
				t: total/:dim
				j: sz: 0
				while [
					all [
						r: index/:dim/(t - j)
						sz: sz + s: get-size dim r
						sz <= grid-size/:dim
					]
				][j: j + 1]
				last-page/:dim: j
			]
		]
		
		set-default-height: function [face [object!] event [event!]][
			dr: get-draw-row face event
			r:  get-data-row dr
			if sz: sizes/y/:r [
				remove/key sizes/y r
				if dr <= frozen/y [
					df: box/y - sz
					freeze-point/y: freeze-point/y + df
				]
				fill face
				set-grid face
				show-marks face
			]
		]
		
		set-table-default-height: func [face [object!]][
			full-height-col: none 
			clear sizes/y
			fill face
			set-grid face
			show-marks face
		]
		
		set-default-width: function [face [object!] event [event! none!]][
			dc: get-draw-col face event
			c:  get-data-col dc
			if sz: sizes/x/:c [
				remove/key sizes/x c
				if dc <= frozen/x [
					df: box/x - sz
					freeze-point/x: freeze-point/x + df
				]
				fill face
				set-grid face
				show-marks face
			]
		]
		
		set-full-height: func [face [object!] event [event! none!] /local found][
			full-height-col: get-col-number face event
			fill face
			set-grid face
			adjust-scroller face
			show-marks face
			if found: find face/menu/"Column" "Full height" [change/part found ["Normal height" remove-full-height] 2]
		]
		
		remove-full-height: func [face [object!] /local found][
			set-table-default-height face
			if found: find face/menu/"Column" "Normal height" [change/part found ["Full height" full-height] 2]
		]
		
		; ACCESSING
		
		get-draw-address: function [face [object!] event [event! none!]][
			if all [
				col: get-draw-col face event
				row: get-draw-row face event
				;row: round/ceiling/to event/offset/y / box/y 1
			][as-pair col row]
		]
		
		get-draw-offset: function [face [object!] cell [pair!] /start /end][
			if all [block? row: face/draw/(cell/y) s: row/(cell/x)] [
				case [
					start [s/6]
					end   [s/7]
					true  [copy/part at s 6 2]
				]
			]
		]

		get-draw-col: function [face [object!] event [event! none!]][
			if block? row: face/draw/1 [
				ofs: event/offset/x
				repeat i length? row [
					case [
						total/x < get-index i 'x [break]
						row/:i/7/x > ofs [
							col: i 
							break
						]
					]
				]
				col
			]
		]
		
		get-draw-row: function [face [object!] event [event! none!]][
			rows: face/draw 
			row: total/y - current/y + frozen/y
			ofs: event/offset/y
			repeat i row [
				if rows/:i/1/7/y > ofs [row: i break]
			]
			row
		]
		
		get-col-number: function [face [object!] event [event! none!]][ 
			col: get-draw-col face event
			get-data-col col
		]
		
		get-row-number: function [face [object!] event [event! none!]][
			row: get-draw-row face event
			get-data-row row
		]

		get-data-address: function [face [object!] event [event! pair!]][
			cell: either event? event [cell: get-draw-address face event][event]
			out: get-logic-address cell
			if face/options/auto-index [out/x: out/x - 1]
			out
		]
		
		get-logic-address: func [cell [pair!]][
			as-pair get-data-col cell/x  get-data-row cell/y
		]
		
		get-data-col: function [col [integer!]][
			col: either col <= frozen/x [
				frozen-cols/:col
			][
				col-index/(col - frozen/x + current/x)
			]
		]

		get-data-row: function [row [integer!]][
			either row <= frozen/y [
				frozen-rows/:row
			][
				row-index/(row - frozen/y + current/y)
			]
		]
		
		get-data-index: func [num [integer!] dim [word!]][
			either dim = 'x [get-data-col num][get-data-row num]
		]

		get-index-address: func [draw-cell [pair!]][
			as-pair get-index-col draw-cell/x  get-index-row draw-cell/y
		]
		
		get-index: func [num [integer!] dim [word!]][
			either dim = 'x [get-index-col num][get-index-row num]
		]

		get-index-col: function [draw-col [integer!]][
			either draw-col <= frozen/x [
				index? find col-index frozen-cols/:draw-col
			][
				draw-col - frozen/x + current/x
			]
		]

		get-index-row: function [draw-row [integer!]][
			either draw-row <= frozen/y [
				index? find row-index frozen-rows/:draw-row
			][
				draw-row - frozen/y + current/y
			]
		]

		get-size: func [dim [word!] idx [integer!]][
			any [sizes/:dim/:idx box/:dim]
		]
		
		get-color: func [i [integer!] frozen? [logic!]][
			case [frozen? [silver] odd? i [white] 'else [snow]]
		]
		
		; INITIATION

		init-data: func [spec [pair!] /local row][
			data: make block! spec/y 
			loop spec/y [
				row: make block! spec/x
				loop spec/x [append row copy ""]
				append/only data row
			]
		]

		set-data: func [face [object!] spec [file! url! block! pair! none!] /local row][
			switch type?/word spec [
				file!  [
					data: switch/default suffix? spec [
						%.csv [load-csv read spec]
						%.red [at load spec 3]
					][load spec]
				] ;load/as head clear tmp: find/last read/part file 5000 lf 'csv ;
				url!   [data: either face/options/delimiter [
					load-csv/with read-thru spec face/options/delimiter
				][
					load-csv read-thru spec
				]]
				block! [data: spec]
				pair!  [
					total: spec
					init-data total
				]
				none! [
					total: face/size / box
					init-data total
				]
			]
		]
		
		init-grid: func [face [object!] /only][
			total/y: length? data
			total/x: length? first data
			if face/options/sheet? [face/options/auto-index: face/options/auto-columns: yes]
			if face/options/auto-index   [total/x: total/x + 1] ; add auto-index
			if face/options/auto-columns [total/y: total/y + 1]
			grid-size: size: face/size - 17
			;set-grid face
			;unless only [
				clear sizes/x
				clear sizes/y
				clear frozen-rows
				clear frozen-cols
			;]
		]

		init-indices: func [face [object!] /only /local i][
			;Prepare indexes
			indexes: make map! total/x                             ;Room for index for each column
			either default-row-index [
				clear filtered
				clear row-index
				clear default-row-index
			][
				filtered: 
					copy row-index:                                    ;Active row-index
					copy default-row-index: make block! total/y        ;Room for row numbers
			]
			either default-col-index [
				clear col-index
				clear default-col-index
			][
				col-index: copy default-col-index: make block! total/x ;Active col-index and room for col numbers
			]
		
			repeat i total/y [append default-row-index i]          ;Default is just simple sequence in initial order
			if face/options/auto-index [
				indexes/1: copy default-row-index                  ;Default is for first (auto-index) column
			]
			repeat i total/x [append default-col-index i] 
			either only [
				clear row-index
				clear col-index
			][
				append clear row-index default-row-index               ;Set default as active index
				append clear col-index default-col-index
			]
			index/x: col-index
			index/y: row-index
			unless only [
				set-last-page
				adjust-scroller face
			]
		]

		init-fill: function [face [object!] /only /extern marks [block!] grid-offset [pair!]][
			clear draw-block
			repeat i grid/y [
				row: make block! grid/x 
				repeat j grid/x  [
					s: (as-pair j i) - 1 * box
					text: form either face/options/auto-index [
						either j = 1 [i][c: col-index/(j - 1) data/:i/:c]
					][
						data/:i/(col-index/:j)
					]
					;Cell structure
					cell: make block! 11    ;each column has the following 11 elements
					color: pick [white snow] odd? i
					repend cell [
						'line-width 1
						'fill-pen color
						'box s s + box
						'clip s + 1 s + box - 1 
						reduce [
							'text s + 4x2  text
						]
					]
					append/only row cell
				]
				append/only draw-block row
			]
			face/draw: draw-block
			;Initialize marks
			marks: insert tail face/draw [line-width 2.5 fill-pen 0.0.0.220]
			unless only [
				mark-active face 1x1
				set-grid-offset face
			]
		]

		init: func [face [object!]][
			frozen: top: current: 0x0
			face/selected: copy []
			scroller/x/position: scroller/y/position: 1
			if not empty? data [
				init-grid face
				init-indices face
				init-fill face
			]
		]

		; FILLING

		fix-cell-outside: func [cell [block!] dim [word!]][
			cell/6/:dim: cell/7/:dim: cell/9/:dim: cell/10/:dim: cell/11/2/:dim: size/:dim
		]
		
		get-row-height: function [data-y [integer!] frozen-y? [logic!]][
			either all [
				full-height-col 
				not frozen-y?
				not sizes/y/:data-y
			][
				d: data/:data-y/:full-height-col
				n: 0 parse d [any [lf (n: n + 1) | skip]]
				;probe reduce [sizes n data-y]
				either n > 0 [sizes/y/:data-y: n + 1 * 16][get-size 'y data-y]
			][
				get-size 'y data-y
			]
		]

		get-icon: function [lib name /type typ][
			base: https://raw.githubusercontent.com/google/material-design-icons/master/png/
			mi-lib: ""
			either typ [mi-lib: copy typ if typ = "outline" [append mi-lib "d"]][typ: "baseline"]
			load to-url rejoin [base lib "/" name "/materialicons" mi-lib "/24dp/1x/" typ "_" name "_black_24dp.png"]
		] 

		fill-cell: function [
			face [object!] 
			cell [block!] 
			data-y [integer!] 
			draw-y [integer!] 
			index-x [integer!] 
			frozen? [logic!] 
			p0 [pair!] 
			p1 [pair!]
		][
			either index-x <= total/x [
				data-x: col-index/:index-x
				if auto: face/options/auto-index [data-x: data-x - 1]
				cell/4:  any [
					colors/(as-pair data-x data-y) 
					get-color draw-y frozen?
				]
				cell/9:  (cell/6: p0) + 1
				cell/10: (cell/7: p1) - 1 
				type: col-type/:data-x ; Check whether it is set
				either frozen? [
					cell/11/1: 'text
					cell/11/2:  4x2  +  p0
					cell/11/3: form either all [auto data-x = 0] [data-y][data/:data-y/:data-x]
				][
					switch/default type [; AND whether it is specific
						draw [ 
							cell/11/1: 'translate
							cell/11/2: cell/9
							cell/11/3: copy/deep data/:data-y/:data-x
						]
						image! [
							switch type?/word data/:data-y/:data-x [
								word! image! [
									cell/11/1: 'image
									cell/11/2: data/:data-y/:data-x
									cell/11/3: cell/9
								]
								file! url! [
									cell/11/1: 'image
									cell/11/2: load data/:data-y/:data-x
									cell/11/3: cell/9
								]
							]
						]
						icon [
							either all [
								1 < length? ico-data: split data/:data-y/:data-x #"/"
								image? ico: get-icon/type ico-data/1 ico-data/2 ico-data/3
							][
								cell/11/1: 'image
								cell/11/2: ico
								cell/11/3: cell/9
							][
								cell/11/1: 'text
								cell/11/2: cell/9
								cell/11/3: copy ""
							]
							;ico: ico-data: none
						]
					][
						cell/11/1: 'text
						cell/11/2:  4x2  +  p0
						cell/11/3: form either all [auto data-x = 0] [data-y][
							switch/default type [
								do [do data/:data-y/:data-x]
								logic! [either data/:data-y/:data-x [true-char][false-char]]
							][
								data/:data-y/:data-x
							]
						]
					]
				]
			][
				fix-cell-outside cell 'x 
			]
		]
		
		add-cell: function [
			face [object!] 
			row [block!]
			data-y [integer!]
			draw-y [integer!]
			draw-x [integer!]
			index-x [integer!]
			p0 [pair!]
			p1 [pair!]
			frozen? [logic!]
		][
			data-x: col-index/:index-x
			if auto: face/options/auto-index [data-x: data-x - 1]
			either frozen? [
				text: form data/:data-y/:data-x
				insert/only at row draw-x compose/only [
					line-width 1
					fill-pen (get-color draw-y frozen?)
					box (p0) (p1)
					clip (p0 + 1) (p1 - 1) 
					(reduce ['text p0 + 4x2 text])
				]
			][
				case [
					draw?: all [t: col-type/:data-x t = 'draw][
						drawing: any [data/:data-y/:data-x copy []]
					]
					all [t: col-type/:data-x t = 'do][
						text: form do data/:data-y/:data-x
					]
					true [
						text: form either all [auto data-x = 0] [data-y][data/:data-y/:data-x]
					]
				]
				insert/only at row draw-x compose/only [
					line-width 1
					fill-pen (get-color draw-y frozen?)
					box (p0) (p1)
					clip (p0 + 1) (p1 - 1) 
					(reduce case [
						draw? [['translate  p0 + 1x1  drawing]]
						true  [['text       p0 + 4x2  text]]
					])
				]
			]
		]

		set-cell: function [
			face [object!] 
			row [block!] 
			index-x [integer!]
			data-y [integer!]
			draw-y [integer!]
			draw-x [integer!]
			px0 [integer!]
			py0 [integer!]
			py1 [integer!]
			frozen? [logic!]
		][
			sx: get-size 'x col-index/:index-x
			px1: px0 + sx
			p0: as-pair px0 py0
			p1: as-pair px1 py1
			either block? cell: row/:draw-x [
				fill-cell face cell data-y draw-y index-x frozen? p0 p1
			][
				if index-x <= total/x [
					add-cell face row data-y draw-y draw-x index-x p0 p1 frozen?
				]
			]
			px1
		]
		
		set-cells: function [
			face [object!] 
			row [block!]
			data-y [integer!]
			draw-y [integer!]
			py0 [integer!]
			py1 [integer!]
			frozen? [logic!]
		][
			px0: freeze-point/x
			grid-x: 0
			while [px0 < size/x][
				grid-x: grid-x + 1
				index-x: current/x + grid-x
				;probe reduce [data-y draw-y index-x]
				either index-x <= total/x [
					px0: set-cell face row index-x data-y draw-y grid-x px0 py0 py1 frozen?
					;probe reduce [draw-y index-x grid-x row]
					grid/x: grid-x
				][
					cell: row/:grid-x
					either all [block? cell cell/6/x < self/size/x] [ 
						fix-cell-outside cell 'x
					][break]
				]
			]
			;probe copy row
			cell: row/(grid-x + 1)
			if all [block? cell cell/6/x < self/size/x] [ 
				fix-cell-outside cell 'x
			]
		]
		
		fill: function [face [object!] /only dim [word!]][
			recycle/off
			system/view/auto-sync?: off
			
			py0: 0
			draw-y: 0
			index-y: 0
			while [all [py0 < size/y index-y < total/y]][
				draw-y: draw-y + 1            ; Skim through draw rows; which number?
				frozen?: draw-y <= frozen/y   ; Is it frozen?
				data-y: get-data-row draw-y   ; Corresponding data row
				index-y: get-index-row draw-y ; Corresponding index row
				draw-row: face/draw/:draw-y   ; Actual draw-row
				unless block? draw-row [      ; Add new row if missing
					insert/only at face/draw draw-y draw-row: copy [] 
					self/marks: next marks
				]
				sy: get-row-height data-y frozen? ;Row height is used in each cell
				py1: py0 + sy                 ; Accumulative height
				
				px0: 0                        ; Start from rightmost cell
				repeat draw-x frozen/x [      ; Render frozen cells first
					index-x: get-index-col draw-x ; Which index is given draw column
					px0: set-cell face draw-row index-x data-y draw-y draw-x px0 py0 py1 true 
				]
				
				draw-row: at draw-row frozen/x + 1 ; Move index to unfrozen cells
				grid-y: draw-y - frozen/y
				set-cells face draw-row data-y grid-y py0 py1 frozen?
				;grid/y: grid-y
				py0: py1
			]
			; Move cells in unused rows outside of visible borders
			while [all [block? draw-row: face/draw/(draw-y: draw-y + 1) draw-row/1/6/y < size/y]][
				foreach cell draw-row [fix-cell-outside cell 'y]
			]
			scroller/y/page-size: grid/y
			scroller/x/page-size: grid/x
			
			show face
			system/view/auto-sync?: on
			recycle/on
		]

		ask-code: function [][
			view [
				below text "Code:" 
				code: area 400x100 focus
				across button "OK" [out: code/text unview] 
				button "Cancel"    [out: none unview]
			]
			out
		]
		
		; EDIT
		
		make-editor: func [table [object!]][
			append table/parent/pane layout/only [
				at 0x0 tbl-editor: field hidden with [
					options: [text: none]
					extra: #()
				] on-enter [
					face/visible?: no 
					update-data face 
					set-focus face/extra/table
				] on-key-down [
					switch event/key [
						#"^[" [ ;esc
							append clear face/text face/options/text
							face/visible?: no
						]
						down  [show-editor face/extra/table face/extra/cell + 0x1]
						up    [show-editor face/extra/table face/extra/cell - 0x1]
						#"^-" [
							either find event/flags 'shift [
								show-editor face/extra/table face/extra/cell - 1x0
							][
								show-editor face/extra/table face/extra/cell + 1x0
							]
						]
					]
				] on-focus [
					face/options/text: copy face/text
				]
			] 
		]
		
		use-editor: function [face [object!] event [event! none!]][
			either tbl-editor [
				if tbl-editor/visible? [
					update-data tbl-editor   ;Make sure field is updated according to correct type
					face/draw: face/draw     ;Update draw in case we edited a field and didn't enter
				]
			][
				make-editor face
			]
			cell: get-draw-address face event                     ;Draw-cell address
			show-editor face cell
		]
		
		show-editor: function [face [object!] cell [pair!]][
			addr: get-data-address face cell
			col: addr/x
			ofs:  get-draw-offset face cell
			either not all [auto: face/options/auto-index col = 0] [ ;Don't edit autokeys
				if auto [col: col + 1]
				tbl-editor/extra/table: face                      ;Reference to table itself
				txt: switch/default col-type/:col [
					image! [
						either block? data/(addr/y)/(addr/x) [
							form data/(addr/y)/(addr/x)
						][
							mold data/(addr/y)/(addr/x)
						]
					]
				][
					form data/(addr/y)/(addr/x)
				]
				tbl-editor/extra/addr: addr                       ;Register data address
				tbl-editor/extra/cell: cell                       ;Register draw-cell address
				fof: face/offset                                  ;Compensate offset for VID space
				edit fof + ofs/1 ofs/2 - ofs/1 txt
			][tbl-editor/visible?: no]
		]
		
		hide-editor: does [
			if all [tbl-editor tbl-editor/visible?] [tbl-editor/visible?: no]
		]
		
		update-data: function [face [object!]][
			switch type?/word addr2: addr: face/extra/addr [
				pair! [
					if addr/x > 0 [ ; Don't update auto-index
						type: type? data/(addr/y)/(addr/x)
						if face/extra/table/options/auto-index [addr2/x: addr/x + 1]
						data/(addr/y)/(addr/x): switch/default col-type/(addr2/x) [
							logic!      [tx: get face/data]
							draw image! [tx: face/data]
							do          [tx: to-block face/text]
							icon        [tx: face/text]
						][to type tx: face/text]
						
						cell:  face/extra/cell
						draw-cell: face/extra/table/draw/(cell/y)/(cell/x)
						switch/default col-type/(addr2/x) [
							logic! [draw-cell/11/3: form either tx [true-char][false-char]]
							draw   [draw-cell/11:   compose/only [translate (draw-cell/9) (tx)]]
							image! [if attempt [image? img: load tx] [draw-cell/11: compose [image (img) (draw-cell/9)]]]
							do     [draw-cell/11/3: form do tx]
							icon   [
								if all [
									1 < length? i: split data/(addr/y)/(addr/x) #"/"
									image? ico: get-icon/type i/1 i/2 i/3 
								][
									draw-cell/11: compose [image (ico) (draw-cell/9)]
								]
								;ico: i: none
							]
						][draw-cell/11/3: tx]
						face/draw: face/draw
					]
				]
			] 
		]

		edit: function [ofs [pair!] sz [pair!] txt [string!]][
			win: tbl-editor
			until [win: win/parent win/type: 'window]
			tbl-editor/offset:    ofs
			tbl-editor/size:      sz
			tbl-editor/text:      txt
			tbl-editor/visible?:  yes
			win/selected:         tbl-editor
		]

		edit-column: function [face [object!] event [event! none!]][
			if code: ask-code [
				code: load/all code 
				code: back insert next code '_
				col: get-col-number face event
				if auto: face/options/auto-index [col: col - 1]
				if not all [auto col = 0][
					foreach i at row-index top/y + 1 [
						row: data/(row-index/:i)
						change/only code row/:col
						if res: attempt [do head code][
							row/:col: either series? res [head res][res]
						]
					]
					fill face
				]
			]
		]

		set-col-type: function [face [object!] event [event! integer!] /only typ [word!]][
			col: either event? event [get-col-number face event][event]
			if not all [not only auto: face/options/auto-index  col = 1][
				if all [auto not only] [col: col - 1]
				old-type: col-type/:col
				col-type/:col: type: either event? event [event/picked][typ]
				forall data [
					;probe reduce [data/1]
					either block? data/1 [
						if not find frozen-rows index? data [
							data/1/:col: switch/default type [
								draw do     [to block! data/1/:col]
								load image! [load data/1/:col]
								string!     [mold data/1/:col]
								logic! [
									case [
										all [series? data/1/:col empty? data/1/:col][
											data/1/:col: false                          ; Empty series -> false
										]
										logic? data/1/col []                            ; It's logic! already, do nothing
										all [string? data/1/:col  val: get/any to-word data/1/:col][
											data/1/:col: either logic? val [val][false] ; Textual logic values get mapped
										]
										'else [data/1/:col: true]                       ; Should it be false instead?
									]
								]
								icon [form data/1/:col]
							][
								to reduce type data/1/:col
							]
						]
					][break]
				]
			]
			if not only [fill face]
		]

		hide-row: function [face [object!] event [event! integer!]][
			row: either integer? event [event][get-row-number face event]
			sizes/y/:row: 0
			fill face
			show-marks face
		]
		
		hide-rows: function [face [object!] rows [block!]][
			foreach row rows [sizes/y/:row: 0]
			fill face
			show-marks face			
		]
		
		hide-col: function [face [object!] event [event! integer!]][
			col: either integer? event [event][get-col-number face event]
			sizes/x/:col: 0
			fill face
			show-marks face
		]
		
		hide-column: function [face [object!] event [event! integer!]][
			hide-col face event
		]
		
		hide-columns: function [face [object!] cols [block!]][
			foreach col cols [sizes/x/:col: 0]
			fill face
			show-marks face
		]
		
		unhide: function [face [object!] dim [word!] /only][
			foreach [key val] sizes/:dim [
				if zero? val [remove/key sizes/:dim key]
			]
			unless only [
				fill face
				show-marks face
			]
		]
		
		unhide-all: function [face [object!]][
			foreach dim [x y][unhide/only face dim]
			fill face
			show-marks face
		]
		
		show-row: function [face [object!] event [event! none!]][]
		
		show-col: function [face [object!] event [event! none!]][]
		
		insert-row: function [face [object!] event [event!]][
			dr: get-draw-row face event
			r: get-index-row dr
			row: make block! total/x
			;loop total/x [append row copy ""]
			repeat col total/x [
				if face/options/auto-index [col: col + 1]
				content: either type: col-type/:col [
					switch/default type [
						do draw image! [copy []] 
						load [none]
						icon [copy ""]
					][make reduce type 0]
				][copy ""]
				append/only row content
			]
			append/only data row
			total/y: total/y + 1
			insert/only at row-index r total/y
			set-last-page
			adjust-scroller face
			fill face
			show-marks face
		]

		append-row: function [face [object!]][
			row: make block! total/x
			repeat col total/x [
				if face/options/auto-index [col: col + 1]
				content: either type: col-type/:col [
					switch/default type [
						do draw image! [copy []]
						load [none]
						icon [copy ""]
					][make reduce type 0]
				][copy ""]
				append/only row content
			]
			append/only data row
			total/y: total/y + 1
			append row-index total/y
			set-last-page
			adjust-scroller face
			fill face
			show-marks face
		]

		insert-col: function [face [object!] event [event! none!]][
			dc: get-draw-col face event
			c: get-index-col dc
			repeat i total/y [append data/:i copy ""]
			total/x: total/x + 1
			insert/only at col-index c total/x
			set-last-page
			adjust-scroller face
			fill face
			show-marks face
		]

		append-col: function [face [object!]][
			repeat i total/y [append data/:i copy ""]
			total/x: total/x + 1
			append col-index total/x
			set-last-page
			adjust-scroller face
			fill face
			show-marks face
		]
		
		remove-row: function [face [object!] event [event!]][
			dr: get-draw-row face event
			r: get-index-row dr
			remove at row-index r
			set-last-page
			adjust-scroller face
			fill face
			show-marks face
		]
		
		remove-col: function [face [object!] event [event!]][
			dc: get-draw-col face event
			c: get-index-col dc
			remove at col-index c
			set-last-page
			adjust-scroller face
			fill face
			show-marks face
		]
		
		restore-row: function [face [object!]][
			append clear row-index default-row-index
			set-last-page
			adjust-scroller face
			fill face
			show-marks face
		]
		
		restore-col: function [face [object!]][
			append clear col-index default-col-index
			set-last-page
			adjust-scroller face
			fill face
			show-marks face
		]
		
		delete-row: function [face [object!] event [event!]][
			dr: get-draw-row face event
			ri: get-index-row dr
			remove at data rd: row-index/:ri
			remove at row-index ri
			repeat i length? row-index [
				if row-index/:i > rd [row-index/:i: row-index/:i - 1]
			]
			take/last default-row-index
			set-last-page
			adjust-scroller face
			fill face
			show-marks face
		]
		
		delete-col: function [face [object!] event [event!]][
			dc: get-draw-col face event
			ci: get-index-col dc
			cd: get-data-col dc
			if face/options/auto-index [cd: cd - 1]
			if cd > 0 [
				foreach row data [either block? row [remove at row cd][break]]
				remove at col-index ci
				repeat i length? col-index [
					if col-index/:i > cd [col-index/:i: col-index/:i - 1]
				]
				take/last default-col-index
				set-last-page
				adjust-scroller face
				fill face
				show-marks face
			]
		]

		move-row: function [face [object!] event [event! integer!] step [word! integer!] /to][
			either event? event [
				dr: get-draw-row face event
				ri: get-index-row dr
			][
				ri: event
			]
			case [
				to [
					pos: max top/y + 1 min total/y step
					step: pos - ri
				]
				integer? step [
					step: max top/y - ri + 1 min total/y - ri step
				]
				word? step [
					step: switch step [
						up [-1]
						down [1]
						top [top/y - ri + 1]
						bottom [total/y - ri]
					]
				]
			]
			move i: at row-index ri skip i step
			fill face
			show-marks face
		]
		
		move-col: function [face [object!] event [event! integer!] step [word! integer!] /to][
			either event? event [
				dc: get-draw-col face event
				ci: get-index-col dc
			][
				ci: event
			]
			case [
				to [
					pos: max top/x + 1 min total/x step
					step: pos - ci
				]
				integer? step [
					step: max top/x - ci + 1 min total/x - ci step
				]
				word? step [
					step: switch step [
						left  [-1]
						right [1]
						first [top/x - ci + 1]
						last  [total/x - ci]
					]
				]
			]
			move i: at col-index ci skip i step
			fill face
			show-marks face
		]
		
		; MARKS
		
		set-new-mark: func [face [object!] active [pair!]][
			append face/selected anchor: active 
		]
		
		mark-active: func [face [object!] cell [pair!] /extend /extra /index][
			either index [
				active: cell
			][
				pos: cell
				active: get-index-address cell			
			]
			marks/-1: 0.0.0.220
			either pair? last face/draw [
				case [
					extend [
						extend?: true
						either '- = first skip tail face/selected -2 [
							change back tail face/selected active
						][
							repend face/selected ['- active]
						]
					]
					extra  [
						extend?: false extra?: true
						set-new-mark face active
					]
					true   [
						extra?: extend?: false
						clear face/selected
						set-new-mark face active 
					]
				]
			] [
				set-new-mark face active
			] 
			show-marks face
		]
		
		unmark-active: func [face [object!]][
			if active [
				clear marks
				extend?: extra?: false
				anchor: active: pos: none
				clear face/selected
			]
		]
		
		mark-address: function [s [pair!] dim [word!]][
			case [
				s/:dim > top/:dim [
					case [
						s/:dim <= current/:dim [0]
						s/:dim > (current/:dim + grid/:dim) [-1]
						true [frozen/:dim + s/:dim - current/:dim];probe reduce [frozen/:dim s/:dim current/:dim frozen/:dim + s/:dim - current/:dim] 
					]
				]
				found: find frozen-nums/:dim index/:dim/(s/:dim) [index? found]
				
			]
		]

		mark-point: function [face [object!] a [pair!] /end][
			n: pick [7 6] end
			case [
				all [a/x > 0 a/y > 0][
					face/draw/(a/y)/(a/x)/:n
				]
				a/x > 0 [
					y: either a/y = 0 [freeze-point/y][size/y]
					as-pair face/draw/1/(a/x)/:n/x y
				]
				a/y > 0 [
					x: either a/x = 0 [freeze-point/x][size/x]
					as-pair x face/draw/(a/y)/1/:n/y
				]
				true [
					x: either a/x = 0 [freeze-point/x][size/x]
					y: either a/y = 0 [freeze-point/y][size/y]
					as-pair x y
				]
			]
		]

		show-marks: function [face [object!]][
			system/view/auto-sync?: off
			clear marks
			parse face/selected [any [
				s: pair! '- pair! (
					a: min s/1 s/3
					b: max s/1 s/3
					r1: mark-address a 'y
					c1: mark-address a 'x
					r2: mark-address b 'y
					c2: mark-address b 'x
					a: as-pair c1 r1
					b: as-pair c2 r2
					p1: mark-point face a
					p2: mark-point/end face b
					repend marks ['box p1 p2]
				)
			|  pair! (
				if all [
					r: mark-address s/1 'y
					c: mark-address s/1 'x
				][
					case [
						all [r > 0 c > 0][
							append marks copy/part at face/draw/:r/:c 5 3
						]
						r > 0 [
							x: either c = 0 [freeze-point/x][size/x]
							p1: as-pair x face/draw/:r/1/6/y
							p2: as-pair x face/draw/:r/1/7/y
							repend marks ['box p1 p2]
						]
						c > 0 [
							y: either r = 0 [freeze-point/y][size/y]
							p1: as-pair face/draw/1/:c/6/x y
							p2: as-pair face/draw/1/:c/7/x y
							repend marks ['box p1 p2]
						]
					]
				]
			   )
			]]
			show face
			system/view/auto-sync?: on
			face/draw: face/draw
		]
		
		adjust-selection: function [face [object!] step [integer!] s [block!] dim [word!]][
			active/:dim: active/:dim + step
			either '- = s/-1 [
				s/1/:dim: s/1/:dim + step
			][
				e: s/1 
				e/:dim: e/:dim + step
				repend face/selected ['- e]
			]
			show-marks face
		]
		
		color-selected: function [face [object!] color [tuple! word! none!]][
			unless color [color: load ask-code]
			parse face/selected [any [s:
				pair! '- pair! (
					mn: (min s/1 s/3) - 1
					mx: max s/1 s/3
					df: mx - mn
					repeat dy df/y [
						repeat dx df/x [
							pos: mn + as-pair dx dy
							x: col-index/(pos/x)
							if face/options/auto-index [x: x - 1]
							y: row-index/(pos/y)
							put colors as-pair x y color
						]
					]
				)
			|	pair! (
					x: col-index/(s/1/x)
					if face/options/auto-index [x: x - 1]
					y: row-index/(s/1/y)
					put colors as-pair x y color
				)
			]]
			fill face
		]
		
		name-selected: function [face [object!] name [word! none!]][
			unless name [name: ask-code]
			names/:name: copy face/selected
			if block? items: face/menu/"Table"/"Select named range" [
				repend items [name to-word name]
			]
		]
		
		forget-names: function [face [object!] names [word! block! none!]][
			unless names [names: load ask-code]
			case [
				names = 'all [
					clear self/names 
					all [items: face/menu/"Table"/"Select named range" clear items]
				]
				word? names [
					remove/key self/names names: form names
					all [
						items: face/menu/"Table"/"Select named range" 
						found: find items names 
						remove/part found 2
					]
				]
				block? names [
					foreach name names [
						remove/key self/names name: form name
						all [
							items: face/menu/"Table"/"Select named range" 
							found: find items name 
							remove/part found 2
						]
					]
				]
			]
		]
		
		;----------
		
		normalize-range: function [range [block!]][
			bs: charset range
			clear range
			repeat i length? bs [if bs/:i [append range i]]
		]
		
		filter-rows: function [face [object!] col [integer!] crit [any-type!] /extern filtered row-index][
			c: col
			if auto: face/options/auto-index [c: c - 1];col-index/(col - 1)
			either block? crit [
				
				switch/default type?/word w: crit/1 [
					word! [
						case [
							op? get/any w [
								forall row-index [
									;if not find frozen-rows 
									row: first row-index 
									;[
										insert/only crit either all [auto col = 1] [row][data/:row/:c]
										if do crit [append filtered row]
										remove crit
									;]
								]
							]
							any-function? get/any w	[
								crit: back insert next crit '_
								forall row-index [
									;if not find frozen-rows 
									row: first row-index 
									;[
										change/only crit either all [auto col = 1] [row][data/:row/:c]
										if do head crit [append filtered row]
									;]
								]
							]
						]
					]
					path! [
						case [
							any-function? get/any w/1 [
								crit: back insert next crit '_
								forall row-index [
									;if not find frozen-rows 
									row: first row-index 
									;[
										change/only crit either all [auto col = 1] [row][data/:row/:c]
										if do head crit [append filtered row]
									;]
								]
							]
						]
					]
					paren! [
						
					]
					set-word! [
						crit: back insert next crit '_
						forall row-index [
							;if not find frozen-rows 
							row: first row-index 
							;[
								change/only crit either all [auto col = 1] [row][data/:row/:c]
								if do head crit [append filtered row]
							;]
						]				
					]
				][  ;Simple list
					either all [auto col = 1] [
						normalize-range crit  ;Use charset spec to select rows
						filtered: intersect row-index crit
					][
						insert crit [_ =]
						forall row-index [
							;if not find frozen-rows 
							row: first row-index 
							;[
								if find crit data/:row/:c [append filtered row]
							;]
						]
					]
				]
			][  ;Single entry
				either all [auto  col = 1] [
					filtered: to-block crit
				][
					forall row-index [
						row: row-index/1
						if data/:row/:c = crit [append filtered row]
					]
				]
			]
		]
		
		filter: function [face [object!] col [integer!] crit [any-type!] /extern filtered row-index][
			;append clear filtered frozen-rows ;include frozen rows in result first
			row-index: skip row-index top/y
			filter-rows face col crit
			row-index: head append clear row-index filtered
			current/y: top/y
			adjust-scroller face
			set-last-page
			unmark-active face
			fill face
		]
		
		unfilter: func [face [object!]][
			clear filtered
			append clear head row-index default-row-index
			adjust-scroller face
			fill face
		]

		freeze: function [face [object!] event [event!] dim [word!] /extern grid [pair!]][
			fro: frozen
			cur: current
			;either event? event [
				frozen/:dim: either dim = 'x [
					get-draw-col face event
				][
					get-draw-row face event
				]
			;][
			;	case [
			;		all [dim integer? event][frozen/:dim: event]
			;		pair? event [frozen: event]
			;	]
			;]
			fro/:dim: frozen/:dim - fro/:dim
			grid/:dim: grid/:dim - fro/:dim
			set-freeze-point face 
			if fro/:dim > 0 [
				append frozen-nums/:dim copy/part at index/:dim cur/:dim + 1 fro/:dim
			]
			current/:dim: cur/:dim + fro/:dim
			top/:dim: current/:dim ;- frozen/:dim
			set-last-page
			adjust-scroller/only face
			scroller/:dim/position: current/:dim + 1
			either dim = 'y [
				repeat i frozen/y [
					repeat j grid/x [
						j: j + frozen/x 
						face/draw/:i/:j/4: 192.192.192
					]
				]
			][
				repeat i grid/y [
					i: i + frozen/y
					repeat j frozen/:dim [
						face/draw/:i/:j/4: 192.192.192
					]
				]
			]
			face/draw: face/draw
			;probe reduce ["freeze:" dim frozen/:dim frozen-nums/:dim grid/:dim freeze-point/:dim]
		]

		unfreeze: function [face [object!] dim [word!]][
			top/:dim: current/:dim: frozen/:dim: 0
			freeze-point/:dim: 0
			grid-size/:dim: size/:dim
			scroller/:dim/position: 1 
			clear frozen-nums/:dim
			set-grid face
			set-last-page
			fill face
			show-marks face
			adjust-scroller face
		]

		adjust-size: func [face [object!]][
			grid-size: size - freeze-point
			set-grid face
			set-last-page 
		]

		adjust-border: function [face [object!] event [event! none!] dim [word!]][
			if on-border?/:dim > 0 [
				ofs0: either dim = 'x [
					face/draw/1/(on-border?/x)/7/x            ;box's actual end
				][
					face/draw/(on-border?/y)/1/7/y
				]
				ofs1: event/offset/:dim
				df:   ofs1 - ofs0
				num: get-index on-border?/:dim dim
				case [
					all [event/ctrl? on-border?/:dim = 1] [
						clear sizes/:dim
						box/:dim: box/:dim + df
						if frozen/:dim > 0 [
							freeze-point/:dim: frozen/:dim * df + freeze-point/:dim
							grid-size/:dim: size/:dim - freeze-point/:dim
						]
					]
					event/ctrl? [
						sz: get-size dim index/:dim/:num
						i: num - 1
						repeat n total/:dim - num + 1 [
							sizes/:dim/(i + n): sz + df
						]
						if on-border?/:dim <= frozen/:dim [
							freeze-point/:dim: frozen/:dim - on-border?/:dim + 1 * df + freeze-point/:dim
							grid-size/:dim: size/:dim - freeze-point/:dim
						]
					]
					true [
						sz: get-size dim i: index/:dim/:num
						sizes/:dim/:i: sz + df
						if on-border?/:dim <= frozen/:dim [
							freeze-point/:dim: freeze-point/:dim + df
							grid-size/:dim: size/:dim - freeze-point/:dim
						]
					]
				]
				set-grid face
				;probe reduce ["adjust:" dim i sizes/:dim freeze-point/:dim]
			]
		]

		; SCROLLING
		
		make-scroller: func [face [object!] /local vscr hscr][
			vscr: get-scroller face 'vertical
			hscr: get-scroller face 'horizontal
			scroller: make map! 2
			scroller/x: hscr
			scroller/y: vscr
		]
		
		scroll: function [face [object!] dim [word!] steps [integer!]][
			if 0 <> step: set-scroller-pos face dim steps [
				dif: calc-step-size dim step
				current/:dim: current/:dim + step
				hide-editor
				set-grid face
				fill face
			]
			step
		]

		adjust-scroller: func [face [object!] /only][
			scroller/y/max-size:  max 1 total/y: length? row-index 
			scroller/x/max-size:  max 1 total/x: length? col-index 
			unless only [set-grid face]
			scroller/y/page-size: min grid/y scroller/y/max-size
			scroller/x/page-size: min grid/x scroller/x/max-size
		]

		set-scroller-pos: function [face [object!] dim [word!] steps [integer!]][
			pos0: scroller/:dim/position
			min-pos: top/:dim + 1
			max-pos: scroller/:dim/max-size - last-page/:dim + pick [2 1] grid-offset/:dim > 0
			mid-pos: scroller/:dim/position + steps
			pos1: scroller/:dim/position: max min-pos min max-pos mid-pos
			pos1 - pos0
		]
		
		count-cells: function [face [object!] dim [word!] dir [integer!] /by-keys][
			case [
				dir > 0 [
					start: current/:dim
					gsize: 0 
					repeat count total/:dim - start [
						start: start + 1
						bsize: get-size dim index/:dim/:start
						gsize: gsize + bsize
						if gsize >= grid-size/:dim [break]
					]
					if (gsize - grid-size/:dim) > tolerance/:dim [count: count - 1]
				]
				dir < 0 [
					start: current/:dim
					gsize: count: 0 
					if start > 0 [
						until [
							count: count + 1
							gsize: gsize + get-size dim index/:dim/:start
							any [grid-size/:dim <= gsize 0 = start: start - 1]
						]
					]
				]
			]
			count
		]
		
		count-steps: function [face [object!] event [event! none!] dim [word!]][
			switch event/key [
				up left    [-1] 
				down right [ 1]
				page-up page-left    [steps: count-cells face dim -1  0 - steps] 
				page-down page-right [steps: count-cells face dim  1      steps]
				track      [step: event/picked - scroller/:dim/position]
			]
		]
		
		calc-step-size: function [dim [word!] step [integer!]][
			dir: negate step / s: absolute step
			pos: either dir < 0 [current/:dim][current/:dim + 1]
			sz: 0
			repeat i s [
				sz: sz + get-size dim pos + i
			]
			sz * dir
		]

		scroll-on-border: function [face [object!] event [event! none!] s [block!] dim [word!]][
			if any [
				all [
					event/offset/:dim > size/:dim
					0 < step: scroll face dim  1
				]
				all [
					s/1/:dim > frozen/:dim
					event/offset/:dim <= freeze-point/:dim
					0 > step: scroll face dim -1
				]
				all [
					s/1/:dim = frozen/:dim
					event/offset/:dim >= freeze-point/:dim
					0 > scroll face dim top/:dim - current/:dim
					step: 1
				]
			][step]
		]
		
		; SELECT / COPY / CUT / PASTE
		
		copy-selected: function [face [object!] /cut /extern selected-data selected-range][
			either value? 'selected-data  [
				clear selected-data 
			][
				selected-data:  make block! 1000
			]
			selected-range: copy face/selected
			clpbrd: copy ""
			parse face/selected [any [
				s: pair! '- pair! (
					start: s/1
					dabs: absolute df: s/3 - s/1
					sign: 1x1 
					if df/x < 0 [sign/x: -1]
					if df/y < 0 [sign/y: -1]
					repeat row dabs/y + 1  [
						repeat col dabs/x + 1 [
							d: start - sign + (sign * as-pair col row)
							d: as-pair col-index/(d/x) row-index/(d/y)
							if auto: face/options/auto-index [d/x: d/x - 1]
							append/only selected-data out: 
								either all [auto d/x = 0][
									d/y
								][
									data/(d/y)/(d/x)
								]
							repend clpbrd [mold out tab]
							if cut [data/(d/y)/(d/x): copy ""]
						]
						change back tail clpbrd lf
					] 
				)
				|  pair! (
					row: row-index/(s/1/y)
					col: col-index/(s/1/x)
					if auto: face/options/auto-index [col: col - 1]
					append/only selected-data out: 
						either all [auto col = 0][
							s/1/y
						][
							data/:row/:col
						]
					repend clpbrd [mold out tab]
					if cut [data/:row/:col: make type? out 0]
					;append selected-range 1x1
				)
			]]
			remove back tail clpbrd
			write-clipboard clpbrd
			if cut [fill face]
		]
		
		parse-selection: function [face [object!] selection [block!] start [pair!] /extern selected-data][
			;probe reduce [start selection col-index]
			parse selection [any [s:
				(diff: s/1 - selection/1)
				pair! '- pair! (
					dabs: absolute df: s/3 - s/1
					sign: 1x1 
					if df/x < 0 [sign/x: -1]
					if df/y < 0 [sign/y: -1]
					repeat y dabs/y + 1 [
						repeat x dabs/x + 1 [
							pos: start + diff - sign + (sign * as-pair x y)
							pos/x: col-index/(pos/x)
							if face/options/auto-index [pos/x: pos/x - 1]
							pos/y: row-index/(pos/y)
							d: first selected-data
							;probe reduce ["p-p:" diff pos d]
							if not pos/x = 0 [data/(pos/y)/(pos/x): d]
							selected-data: next selected-data
						]
					]
				)
			|	pair! (
					pos: start + diff
					pos/x: col-index/(pos/x)
					if face/options/auto-index [pos/x: pos/x - 1]
					pos/y: row-index/(pos/y)
					d: first selected-data
					;probe reduce ["p:" diff pos d]
					if not pos/x = 0 [data/(pos/y)/(pos/x): d]
					selected-data: next selected-data
				)
			]]
		]
		
		paste-selected: function [face [object!] /transpose /extern selected-data selected-range][
			either single? face/selected [
				start: anchor
				parse-selection face selected-range start
			][
				; Compare copied and selected sizes
				copied-size: 0
				parse selected-range [any [s:
					pair! '- pair! (p: (absolute s/3 - s/1) + 1 copied-size: p/x * p/y + copied-size)
				|	pair! (copied-size: copied-size + 1)
				]]
				selected-size: 0
				parse face/selected [any [e:
					pair! '- pair! (q: (absolute e/3 - e/1) + 1 selected-size: q/x * q/y + selected-size)
				|	pair! (selected-size: selected-size + 1)
				]]
				either copied-size = selected-size [
					start: face/selected/1 ;anchor ;- 1 
					parse-selection face face/selected start
				][
					print "Warning! Sizes do not match."
				]
			]
			selected-data: head selected-data
			fill face
		]

		select: function [
			face [object!] 
			range [pair! integer! block!] 
			/from 
				start "Either `top` - start counting from first non-frozen -, or `current` (also `cur`) - start from first visible after frozen -, or `view` - start from current view-port"
			/col 
			/row
		][
			unmark-active face
			switch type?/word range [
				pair! [
					either from [
						switch start [
							view [mark-active/extra face range]
							top [mark-active/index/extra face top + range]
							cur current [mark-active/index/extra face current + range]
						]
					][
						mark-active/index face range
					]
				]
				integer! [
					
				]
				block! [
					parse range [any [s:
						pair! '- pair! (
							either from [
								switch start [
									view [
										mark-active/extra  face s/1
										mark-active/extend face s/3
									]
									current cur [
										mark-active/index/extra  face current + s/1 
										mark-active/index/extend face current + s/3
									]
									top [
										mark-active/index/extra  face top + s/1 
										mark-active/index/extend face top + s/3
									]
								]
							][
								mark-active/index/extra  face s/1 
								mark-active/index/extend face s/3
							]
						)
					|	pair! (
							either from [
								switch start [
									view [
										mark-active/extra face s/1
									]
									current cur [
										mark-active/index/extra face current + s/1
									]
									top [
										mark-active/index/extra face top + s/1
									]
								]
							][
								mark-active/index/extra face s/1
							]
						)
					]]
					show-marks face
				]
			]
			set-focus tb
		]
		
		which-index: function [face [object!] event [event! integer!] dim [word!]][
			either event? event [
				switch dim [
					row [
						dri: get-draw-row face event
						get-index-row dri
					]
					col [
						dri: get-draw-col face event
						get-index-col dri
					]
				]
			][
				event
			]
		]
		
		select-row: function [face [object!] event [event! integer!] /add][
			ri: which-index face event 'row
			unless add [clear face/selected]
			repend face/selected [as-pair 1 ri '- as-pair total/x ri]
			show-marks face
		]
		
		select-col: function [face [object!] event [event! integer!] /add][
			ci: which-index face event 'col
			unless add [clear face/selected]
			repend face/selected [as-pair ci 1 '- as-pair ci total/y]
			show-marks face
		]
		
		select-name: function [face [object!] name [string!] /add][
			unless add [clear face/selected]
			append face/selected names/:name
			show-marks face
		]
		
		; More helpers

		on-sort: func [face [object!] event [event! integer!] /loaded /down /local col c fro idx found][
			recycle/off
			col: switch type?/word event [
				event!   [get-col-number face event]
				integer! [col-index/:event]
			]
			either all [face/options/auto-index  1 = absolute col][
				append clear head row-index default-row-index
				if frozen/y > 0 [row-index: skip row-index frozen-rows/(frozen/y)]
				if down [reverse row-index]
				row-index: head row-index
			][
				either indexes/:col [clear indexes/:col][indexes/:col: make block! total/y]
				c: absolute col
				if face/options/auto-index [c: c - 1]
				idx: skip head row-index top/y
				sort/compare idx function [a b][
					attempt [case [
						all [loaded down][(load data/:b/:c) <= (load data/:a/:c)];[(load data/:a/:c) >  (load data/:b/:c)]
						loaded           [(load data/:a/:c) <= (load data/:b/:c)]
						down             [data/:b/:c <=  data/:a/:c];[data/:a/:c >  data/:b/:c]
						true             [data/:a/:c <= data/:b/:c]
					]]
				]
				append indexes/:col row-index
			]
			set-last-page
			scroller/y/position: either 0 < fro: frozen/y [
				if found: find row-index frozen-rows/:fro [
					top/y: current/y: index? found
					current/y + 1
				]
			][
				top/y: current/y: 0
				1
			]
			fill face
			;recycle
			recycle/on
		]
		
		unsort: func [face [object!]][
			append clear row-index default-row-index
			adjust-scroller face
			fill face
		]
		
		resize: func [face [object!]][
			size: face/size - 17
			adjust-size face
			fill face
			show-marks face
		]

		hot-keys: function [face [object!] event [event! none!] /extern pos extend?][
			key: event/key
			step: switch key [
				down      [0x1]
				up        [0x-1]
				left      [-1x0]
				right     [1x0]
				page-up   [as-pair 0 negate grid/y]
				page-down [as-pair 0 grid/y]
				home      [as-pair negate grid/x 0] ;TBD
				end       [as-pair grid/x 0]        ;TBD
			]
			either all [active step] [
				case [
					; Active mark beyond edge
					case/all [
						all [active/y > (edge: current/y + grid/y)][
							ofs: active/y + step/y - edge
							either ofs > 0 [
								df: scroll face 'y ofs ;active/y - edge + step/y
								pos/y: frozen/y + grid/y
							][
								pos/y: frozen/y + grid/y + ofs
							]
							step/y: 0
							y: 'done
							false
						]
						all [active/x > (edge: current/x + grid/x)][
							ofs: active/x + step/x - edge
							either ofs > 0 [
								df: scroll face 'x ofs ;active/y - edge + step/y
								pos/x: frozen/x + grid/x
							][
								pos/x: frozen/x + grid/x + ofs
							]
							step/x: 0
							x: 'done
							false
						]
						all [active/y > top/y active/y <= current/y 'y <> 'done][
							;probe reduce ["anc" anchor "act" active "pos" pos "top" top "cur" current "fro" frozen "grd" grid "stp" step active/y - current/y - 1 + step/y]
							scroll face 'y active/y - current/y - 1 + step/y
							pos/y: frozen/y + 1
							step/y: 0
							y: 'done
							false
						]
						all [active/x > top/x step/x <> 0 active/x <= current/x 'x <> 'done][
							scroll face 'x active/x - current/x - 1 + step/x
							pos/x: frozen/x + 1
							step/x: 0
							x: 'done
							false
						]
					][false]
					; Active mark on edge
					dim: case [ 
						any [
							all [key = 'down    frozen/y + grid/y = pos/y y <> 'done]
							all [key = 'up      frozen/y + 1    = pos/y y <> 'done]
							all [find [page-up page-down] key pos/y > frozen/y y <> 'done]
						][
							df: scroll face 'y step/y
							switch key [
								page-up   [if step/y < step/y: df [pos/y: pos/y - grid/y - step/y]]
								page-down [if step/y > step/y: df [pos/y: pos/y + grid/y - step/y]]
							]
							'y
						]
						any [
							all [key = 'right frozen/x + grid/x = pos/x current/x < (total/x - last-page/x) x <> 'done]
							all [key = 'left  frozen/x + 1    = pos/x x <> 'done] 
							all [key = 'right ofs: get-draw-offset face pos + step ofs/2/x > size/x x <> 'done] 
						][
							df: scroll face 'x step/x
							step/x: df
							'x
						]
					][
						pos: max 1x1 min grid + frozen pos
						either df = 0 [
							if switch key [
								up        [pos/y: max 1 pos/y - 1]
								left      [pos/x: max 1 pos/x - 1]
								page-up   [pos/y: frozen/y + 1]
								page-down [pos/y: grid/y]
							][
								either event/shift? [
									mark-active/extend face pos
								][	mark-active face pos]
							]
						][
							if event/shift? [extend?: true]
							either any [extra? extend?] [
								either '- = first s: skip tail face/selected -2 [
									s/2: s/2 + step
								][
									repend face/selected ['- s/1 + step]
								]  
								show-marks face
							][
								mark-active face pos
							]
						]
					]
					;Active mark in center ;probe reduce [active step active + step]
					true [ 
						case [
							all [key = 'down  pos/y = frozen/y y <> 'done][scroll face 'y top/y - current/y]
							all [key = 'right pos/x = frozen/x x <> 'done][scroll face 'x top/x - current/x]
							;all [key = 'up pos/y > grid/y][probe "hi"]
							all [key = 'page-down pos/y <= frozen/y y <> 'done][
								scroll face 'y top/y - current/y 
								step/y: frozen/y - pos/y + grid/y
							]
						]
						pos: pos + step
						pos: max 1x1 min grid + frozen pos
						either event/shift? [
							mark-active/extend face pos
						][	mark-active face pos]
					]
				]
			][
				switch key [
					#"^M" [
						unless tbl-editor [make-editor face]
						show-editor face pos
					]
				]
			]
		]
		
		do-menu: function [face [object!] event [event! none!]][
			switch/default event/picked [
				; TABLE
				open-table      [open-table face]
				save-table      [save-table face]
				save-table-as   [save-table-as face]
				save-state   [save-state face]
				use-state       [use-state face]
				unhide-all      [unhide-all  face]
				;force-state   [use-state/force face]
				clear-color     [clear colors fill face]
				forget-names    [forget-names face none]
				
				open-big        [open-big-table face]
				
				; CELL
				edit-cell       [on-dbl-click face event]
				freeze-cell     [freeze face event 'y freeze face event 'x]
				unfreeze-cell   [unfreeze face 'y unfreeze face 'x]
			
				; ROW
				freeze-row      [freeze face event 'y]
				unfreeze-row    [unfreeze face 'y]
				default-height  [set-default-height face event]
				
				select-row      [select-row face event]
				hide-row        [hide-row   face event]
				insert-row      [insert-row face event]
				append-row      [append-row face]
				
				find-in-row     [find-in-row face event]
				
				move-row-top    [move-row face event 'top]
				move-row-up     [move-row face event 'up]
				move-row-down   [move-row face event 'down]
				move-row-bottom [move-row face event 'bottom]
				move-row-by     [if integer? step: load ask-code [move-row face event step]]
				move-row-to     [if integer? pos:  load ask-code [move-row/to face event pos]]
				
				remove-row      [remove-row  face event]
				restore-row     [restore-row face]
				delete-row      [delete-row  face event]
				unhide-row      [unhide face 'y]
				
				; COLUMN
				freeze-col      [freeze face event 'x]
				unfreeze-col    [unfreeze face 'x]
				default-width   [set-default-width  face event]
				full-height     [set-full-height    face event]
				remove-full-height [remove-full-height face]
				
				sort-up          [on-sort face event]
				sort-down        [on-sort/down face event]
				sort-loaded-up   [on-sort/loaded face event]
				sort-loaded-down [on-sort/loaded/down face event]
				unsort           [unsort face]
				
				filter [
					if code: ask-code [
						code: load code
						col: get-col-number face event
						filter face col code
					]
				]
				unfilter    [unfilter face]
				
				select-col  [select-col face event]
				hide-col    [hide-col   face event]
				insert-col  [insert-col face event]
				append-col  [append-col face]
				
				find-in-col     [
					if code: ask-code [
						code: load code
						col: get-col-number face event
						find-in-col face col code
					]
				]
				
				move-col-first  [move-col face event 'first]
				move-col-left   [move-col face event 'left]
				move-col-right  [move-col face event 'right]
				move-col-last   [move-col face event 'last]
				move-col-by     [if integer? step: load ask-code [move-col face event step]]
				move-col-to     [if integer? pos:  load ask-code [move-col/to face event pos]]

				edit-column     [edit-column face event]
				
				unhide-col      [unhide face 'x]
				remove-col      [remove-col  face event]
				restore-col     [restore-col face]
				delete-col      [delete-col  face event]

				load draw do icon 
				integer! float! percent! 
				string! char! block! 
				date! time! logic! 
				image! tuple!   [set-col-type face event]

				; SELECTION
				copy-selected   [copy-selected face]
				cut-selected    [copy-selected/cut face]
				paste-selected  [paste-selected face]
				transpose       [paste-selected/transpose face]
				color-selected  [color-selected face none]
				name-selected   [name-selected face none]
			][
				case [
					all [menu: face/menu/"Table"/"Select named range" find menu name: form event/picked] [
						select-name face name
					]
				]
			]
		]
		
		do-over: function [
			face [object!] 
			event [event! none!] 
			/extern 
				no-over 
				same-offset?
		][
			if all [event/down? not no-over][
				either on-border? [
					adjust-border face event 'x
					adjust-border face event 'y
					fill face
					show-marks face
				][
					selection: find/last face/selected pair!
					same-offset?: no
					case [
						step: scroll-on-border face event selection 'y [
							adjust-selection face step selection 'y
						]
						step: scroll-on-border face event selection 'x [
							adjust-selection face step selection 'x
						]
						true [
							if attempt [addr: get-draw-address face event] [
								if all [addr addr <> pos] [
									mark-active/extend face addr
								]
							]
						]
					]
				]
			]
			no-over: false
		]
		
		find-in-row: function [face [object!] event [event!]][
			code: ask-code
			clear face/selected
			r: get-row-number face event
			foreach c col-index [
				if face/options/auto-index [c0: c - 1]
				if (form data/:r/:c0) ~ code [append face/selected as-pair c r]
			]
			;probe face/selected
			show-marks face
		]

		find-in-col: function [face [object!] col [integer!] code [any-type!] /extern filtered row-index][
			;append clear filtered frozen-rows ;include frozen rows in result first
			clear filtered
			row-index: skip row-index top/y
			filter-rows face col code
			row-index: head row-index
			clear face/selected
			foreach r filtered [append face/selected as-pair col r]
			if not empty? face/selected [
				;current/y: top/y
				scroll face 'y filtered/1 - current/y - 1 
				;adjust-scroller face
				;fill face
				marks/-1: 0.220.0.220
				show-marks face
			]
		]
		
		; OPEN
		
		open-red-table: func [face [object!] fdata [block!] /only /local opts i col type sz][
			either only [
				opts: fdata
			][
				opts: fdata/2 
				data: remove/part fdata 2
			]
			either find face/options 'auto-index [
				face/options/auto-index: 'true = opts/auto-index
			][
				append face/options compose [auto-index: ('true = opts/auto-index)]
			]
			
			init-grid face ;/only
			init-indices/only face
			;probe reduce [opts opts/frozen-rows]
			if opts/frozen-cols [append frozen-cols opts/frozen-cols]
			if opts/frozen-rows [append frozen-rows opts/frozen-rows]
			frozen: as-pair length? frozen-cols length? frozen-rows
			append col-index either opts/col-index [opts/col-index][default-col-index]
			append row-index either opts/row-index [opts/row-index][default-row-index]
			either sz: opts/sizes [
				if sz/x [sizes/x: to-map sz/x]
				if sz/y [sizes/y: to-map sz/y]
			][
				if sz: opts/col-sizes [sizes/x: to-map sz]
				if sz: opts/row-sizes [sizes/y: to-map sz]
			]
			either opts/col-type  [
				col-type: to-map opts/col-type
				if only [
					foreach [col type] body-of col-type [
						set-col-type/only face col type
					]
				]
			][
				col-type: clear col-type
			]
			
			box: any [opts/box default-box]
			top: case/all [
				(x: frozen/x) > 0 [x: frozen-cols/:x] 
				(y: frozen/y) > 0 [y: frozen-rows/:y] 
				true [as-pair x y]
			]
			current:       any [opts/current  top]
			face/selected: any [opts/selected [1x1]]
			anchor:        any [opts/anchor   1x1]
			active:        any [opts/active   1x1]
			
			pos: active - current + frozen
			
			either opts/names [names: to-map opts/names][clear names]
			
			;probe reduce [frozen frozen-rows frozen-cols top current face/selected anchor active pos]
			
			scroller/x/position: current/x + 1 ;opts/scroller-x
			scroller/y/position: current/y + 1 ;opts/scroller-y
			
			set-freeze-point2 face
			adjust-scroller face
			set-last-page
			
			face/draw: copy []
			marks: insert tail face/draw [line-width 2.5 fill-pen 0.0.0.220]
			
			;either face/draw [
				fill face
			;][init-fill/only face]
			show-marks face
			no-over: true
		]
		
		open-table: func [
			face [object!] 
			/with state [file! block!] ;TBD
			/local file opts
		][
			if file: request-file/title "Open file" [
				face/data: file 
				data: load file
				either all [
					%.red = suffix? file 
					data/1 = 'Red
					block? opts: data/2 
					;opts/current
				][open-red-table face data][init face];data: load file ;load/as head clear tmp: find/last read/part file 5000 lf 'csv;
			]
			no-over: true
			file
		]
		
		open-big-table: function [face [object!]][
			if file: request-file/title "Open large file" [
				self/big-size: length? read/binary file
				self/big-length: length? csv: head clear find/last read/binary/part file 1'000'000 lf
				face/data: file
				
				self/data: load-csv to-string csv
				open-red-table/only face [frozen-rows: [1]]
				;lines: 1 c: csv while [c: find/tail c lf][lines: lines + 1] lines
			]
		]
		
		next-chunk: function [face [object!]][
			file: face/data
			self/big-last: big-last + big-length + 1
			append self/prev-lengths big-length
			state: save-state/only/with face [col-sizes col-types frozen-cols] ;col-index ? why error?
			if attempt [found: find/last read/binary/seek/part file big-last 1'000'000 lf] [
				self/big-length: length? csv: head clear found
				;probe reduce ["Next:" big-last big-length]
				csv: to-string csv 
				either error? loaded: load-csv csv [probe loaded halt][self/data: loaded]
				;init face
				open-red-table/only face state
			]
		]
		
		prev-chunk: function [face [object!]][
			file: face/data
			state: save-state/only/with face [col-sizes col-types frozen-cols]
			if not empty? prev-lengths [
				self/big-length: take/last prev-lengths
				self/big-last: big-last - big-length - 1 
				;probe reduce ["Prev:" big-last big-length]
				csv: read/binary/seek/part file big-last big-length
				csv: to-string csv 
				either error? loaded: load-csv csv [probe loaded halt][self/data: loaded]
				;init face
				open-red-table/only face state
			]
		]
		
		use-state: function [face [object!] /with opts [block!]][
			either with [
				state: opts
			][
				if file: request-file/title "Select state to use ..." [
					state: load file
				]
			]
			if state [open-red-table/only face state]
		]
		
		; SAVE
		
		get-table-state: func [face [object!]][
			compose/only [
				frozen-rows: (frozen-rows)
				frozen-cols: (frozen-cols)
				top: (top)
				current: (current)
				col-sizes: (body-of sizes/x)
				row-sizes: (body-of sizes/y)
				box: (box)
				row-index: (row-index)
				col-index: (col-index)
				auto-index: (face/options/auto-index)
				col-type: (body-of col-type)
				selected: (face/selected)
				anchor: (anchor)
				active: (active)
				names: (body-of names)
				;scroller-x: (scroller/x/position)
				;scroller-y: (scroller/y/position)
			]
		]
		
		save-state: function [face [object!] /only /with included [block!] /except excluded [block!]][
			state: get-table-state face
			
			if any [with except] [
				state: to map! state
				foreach key keys-of state [
					case/all [
						with   [if not find included key [remove/key state key]]
						except [if     find excluded key [remove/key state key]]
					]
				]
				state: to block! state
			]
			
			either only [state][
				if file: request-file/save/title "Save state as ..." [
					save file state
				]
			]
		]
		
		save-red-table: function [face [object!]][
			out: new-line/all data true 
			opts: get-table-state face
			save/header face/data out opts
		]
		
		save-table: function [face [object!]][
			either file? file: face/data [
				switch/default suffix? file [
					%.red [save-red-table face]
					%.csv [write file to-csv data]
				][write file data]
			][
				file: save-table-as face
			]
			no-over: true
			file
		]
		
		save-table-as: func [face [object!] /local file][
			if file: request-file/save/title "Save file as" [
				face/data: file
				save-table face
			]
			file
		]
		
		; STANDARD
		
		on-scroll: function [face [object!] event [event! none!]][
			if 'end <> key: event/key [
				dim: pick [y x] event/orientation = 'vertical
				steps: count-steps face event dim
				if steps [scroll face dim steps]
				show-marks face
			]
		]

		on-wheel: function [face [object!] event [event! none!]][;May-be switch shift and ctrl ?
			dim: pick [x y] event/shift?
			steps: to-integer -1 * event/picked * either event/ctrl? [grid/:dim][system/words/select [x 1 y 3] dim]
			scroll face dim steps
			show-marks face
		]

		on-down: func [face [object!] event [event! none!] /local addr col][
			set-focus face
			on-border?: on-border face event/offset
			if not on-border? [
				hide-editor
				pos: get-draw-address face event
				same-offset?: yes
				case [
					event/shift? [mark-active/extend face pos]
					event/ctrl?  [mark-active/extra face pos]
					true         [mark-active face pos]
				]
			]
		]
		
		on-unfocus: func [face [object!]][
			hide-editor
			unmark-active face
		]

		on-over: func [face [object!] event [event! none!]][do-over face event]

		on-up: func [face [object!] event [event! none!]][
			either on-border? [
				set-grid-offset face
				set-last-page
			][
				if all [
					same-offset?
					addr: get-data-address face event
					col-type/(addr/x) = 'logic!
				][
					if face/options/auto-index [addr/x: addr/x - 1] 
					data/(addr/y)/(addr/x): not data/(addr/y)/(addr/x) 
					fill face
				]
			]
		]

		on-dbl-click: function [face [object!] event [event! none!] /local e][use-editor face event]
		
		on-key-down: func [face [object!] event [event! none!]][hot-keys face event]
		
		on-created: func [face [object!] event [event! none!] /local file config][
			make-scroller face
			either all [
				file? file: face/data 
				%.red = suffix? file
				data: load file
				data/1 = 'Red
				block? opts: data/2 
				;opts/current
			][
				open-red-table face data config
			][
				set-data face face/data
				either config: face/options/config [
					if file? config [config: load config]
					open-red-table/only face config
				][
					init face
				]
			]
		]
		
		on-menu: function [face [object!] event [event! none!]][do-menu face event]
	]
]
style 'table tbl