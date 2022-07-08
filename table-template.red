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
	;options: [auto-col: #[true]]
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
				"Insert virtual" insert-virtual-row
				"Append virtual" append-virtual-row
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
				"Insert virtual" insert-virtual-col
				"Append virtual" append-virtual-col
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
			"Set default"  set-default
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
		default-row-index: row-index: 
		default-col-index: col-index: 
		full-height-col:
		on-border?: 
		tbl-editor: 
		marks: anchor: active: pos:
		extra?: extend?: 
		same-offset?: none
		
		dummy: copy ""
		total: size: 0x0
		frozen: freeze-point: 0x0
		current: top: 0x0
		grid: grid-size: grid-offset: 0x0
		last-page: 0x0
		default-box: box: 100x25
		tolerance: 20x5
		
		indices:       make map! 2
		filtered:      make map! 2 
		frozen-cols:   make block! 20
		frozen-rows:   make block! 20
		draw-block:    make block! 1000
		filter-cmd:    make block! 10
		;selected-data: make block! 10000
		;selected-range: make block! 10
		sizes:         make map! 2
		sizes/x:       make map! copy []
		sizes/y:       make map! copy []
		frozen-nums:   make map! 2
		frozen-nums/x: frozen-cols
		frozen-nums/y: frozen-rows
		
		index:     make map! 2
		col-type:  make map! 5
		colors:    make map! 100
		defaults:  make map! 10
		auto-col?: auto-row?: sheet?: false
		auto-y:    auto-x:   0
		
		no-over: false
		true-char:  #"^(2714)" ;#"^(2713)"
		false-char: #"^(274C)" ;#"^(2717)"
		
		names: make map! 10
		big-last: big-length: big-size: prev-length: 0
		prev-lengths: make block! 100
		
		virtual-rows: make map! 10
		virtual-cols: make map! 10
		
		digit: charset "0123456789"
		int: [some digit]
		ws: charset " ^-"
		
		starting?: yes
		
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
			end: get-cell-offset/end face frozen + grid
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
		
		set-default: function [face [object!] event [event! integer!]][
			col: get-col-number face event
			val: either val: defaults/:col [ask-code/with val][ask-code]
			either all [
				series? val: load val
				empty? val
			][
				remove/key defaults col
			][
				defaults/:col: val
			]
		]
		
		; ACCESSING
		
		get-draw-address: function [face [object!] event [event! none!]][
			if all [
				col: get-draw-col face event
				row: get-draw-row face event
				;row: round/ceiling/to event/offset/y / box/y 1
			][as-pair col row]
		]
		
		get-cell-offset: function [face [object!] cell [pair!] /start /end][
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
				if rows/:i/1/7/y > ofs [row: i break] ; box's end/y is greater than mouse's offset/y
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
			;if face/options/auto-col [out/x: out/x - 1]
			out
		]
		
		get-logic-address: func [draw-cell [pair!]][
			as-pair get-data-col draw-cell/x  get-data-row draw-cell/y
		]
		
		get-data-col: function [draw-col [integer!]][
			either draw-col <= frozen/x [
				frozen-cols/:draw-col
			][
				col-index/(draw-col - frozen/x + current/x)
			]
		]
		
		get-data-row: function [draw-row [integer!]][
			either draw-row <= frozen/y [
				frozen-rows/:draw-row
			][
				row-index/(draw-row - frozen/y + current/y)
			]
		]
		
		get-data-index: func [num [integer!] "Draw-index" dim [word!] "Dimension: ['x | 'y]"][
			either dim = 'x [get-data-col num][get-data-row num]
		]

		get-index-address: func [draw-cell [pair!]][
			as-pair get-index-col draw-cell/x  get-index-row draw-cell/y
		]
		
		get-index: func [num [integer!] "Draw-index" dim [word!] "Dimension: ['x | 'y]"][
			either dim = 'x [get-index-col num][get-index-row num]
		]

		get-index-col: function [draw-col [integer!]][
			;probe reduce ["d" draw-col "f" frozen/x "ci" col-index "fc" frozen-cols]
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
				loop spec/x [append row none ];copy ""]
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
			if face/options/auto-col [total/x: total/x + 1] ; add auto-col
			if face/options/auto-row [total/y: total/y + 1]
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
			;Prepare indices
			indices/x: make map! total/x                             ;Room for index for each column
			indices/y: make map! 10 ;total/y                         ;Room for index for some rows     @@ May be on request?
			either default-row-index [
				clear filtered/y
				clear row-index
				clear default-row-index
			][
				filtered/y: 
					copy row-index:                                    ;Active row-index
					copy default-row-index: make block! total/y        ;Room for row numbers
			]
			either default-col-index [
				clear filtered/x
				clear col-index
				clear default-col-index
			][
				filtered/x:
					copy col-index: 
					copy default-col-index: make block! total/x ;Active col-index and room for col numbers
			]
			auto-x: make integer! auto-col?: to-logic face/options/auto-col
			auto-y: make integer! auto-row?: to-logic face/options/auto-row
			repeat i total/y [append default-row-index i - auto-y]   ;Default is just simple sequence in initial order
			if auto-col? [
				indices/x/0: copy default-row-index                  ;Default is for first (auto-col) column
			]
			repeat i total/x [append default-col-index i - auto-x] 
			if auto-row? [
				indices/y/0: copy default-col-index                  ;Default is for first (auto-row) row
			]
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
					text: form case [
						all [auto-col? j = 1] [i] ;(j - 1)
						all [auto-row? i = 1] [j] ;(j - 1)
						true [any [data/:i/(col-index/:j) dummy]]
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
				d: form any [data/:data-y/:full-height-col dummy]
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
			face    [object! ] 
			cell    [block!  ] 
			data-y  [integer!] 
			index-y [integer!]
			index-x [integer!] 
			draw-y  [integer!] 
			draw-x  [integer!]
			frozen? [logic!  ] 
			p0      [pair!   ] 
			p1      [pair!   ]
		][
			either index-x <= total/x [
				data-x: col-index/:index-x
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
					cell/11/3: form case [
						all [data-y > 0 data-x > 0][any [data/:data-y/:data-x dummy]]
						data-x = 0 [either sheet? [index-y][data-y]] 
						data-y = 0 [either sheet? [index-x][data-x]] 
						all [v: virtual-rows/:data-y v: v/data/:data-x] [form v]
						all [v: virtual-cols/:data-x v: v/data/:data-y] [form v]
						true [dummy]
					]
				][
					switch/default type [; AND whether it is specific
						draw [ 
							cell/11/1: 'translate
							cell/11/2: cell/9       ; Start of cell
							cell/11/3: copy/deep data/:data-y/:data-x ; Draw-block
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
								cell/11/3: dummy ;copy ""
							]
							;ico: ico-data: none
						]
					][
						cell/11/1: 'text
						cell/11/2:  4x2  +  p0
						cell/11/3: form case [
							all [data-y > 0 data-x > 0][
								switch/default type [
									do [do data/:data-y/:data-x]
									logic! [either data/:data-y/:data-x [true-char][false-char]]
								][
									any [data/:data-y/:data-x dummy]
								]
							]
							data-x = 0 [either sheet? [index-y][data-y]]
							data-y = 0 [either sheet? [index-x][data-x]] 
							true [
								cell/4: 250.220.220
								case [
									all [v: virtual-rows/:data-y v: v/data/:data-x] [form v]
									all [v: virtual-cols/:data-x v: v/data/:data-y] [form v]
									true [dummy]
								]
							]
						]
					]
				]
			][
				fix-cell-outside cell 'x 
			]
		]
		
		add-cell: function [
			face    [object! ] 
			row     [block!  ]
			data-y  [integer!]
			index-y [integer!]
			index-x [integer!]
			draw-y  [integer!]
			draw-x  [integer!]
			frozen? [logic!  ]
			p0      [pair!   ]
			p1      [pair!   ]
		][
			data-x: col-index/:index-x
			either frozen? [
				text: form case [
					data-x = 0 [either sheet? [index-y][data-y]] 
					data-y = 0 [either sheet? [index-x][data-x]] 
					true [any [data/:data-y/:data-x dummy]]
				]
				cell: compose/only [
					line-width 1
					fill-pen (get-color draw-y frozen?)
					box (p0) (p1)
					clip (p0 + 1) (p1 - 1) 
					(reduce ['text p0 + 4x2 text])
				]
				insert/only at row draw-x cell
			][
				case [
					draw?: all [t: col-type/:data-x t = 'draw][
						drawing: any [data/:data-y/:data-x copy []]
					]
					all [t: col-type/:data-x t = 'do][
						text: form either data/:data-y/:data-x [do data/:data-y/:data-x][dummy]
					]
					true [
						text: form case [
							data-x = 0 [either sheet? [index-y][data-y]] 
							data-y = 0 [either sheet? [index-x][data-x]] 
							true [any [data/:data-y/:data-x dummy]]
						]
					]
				]
				cell: compose/only [
					line-width 1
					fill-pen (get-color draw-y frozen?)
					box (p0) (p1)
					clip (p0 + 1) (p1 - 1) 
					(reduce case [
						draw? [['translate  p0 + 1x1  drawing]]
						true  [['text       p0 + 4x2  text]]
					])
				]
				insert/only at row draw-x cell
			]
		]

		set-cell: function [
			face    [object! ] 
			row     [block!  ] 
			data-y  [integer!]
			index-y [integer!]
			index-x [integer!]
			grid-y  [integer!]
			grid-x  [integer!]
			frozen? [logic!  ]
			px0     [integer!]
			py0     [integer!]
			py1     [integer!]
		][
			sx: get-size 'x col-index/:index-x
			px1: px0 + sx
			p0: as-pair px0 py0
			p1: as-pair px1 py1
			either block? cell: row/:grid-x [
				fill-cell face cell data-y index-y index-x grid-y grid-x frozen? p0 p1
			][
				if index-x <= total/x [
					add-cell face row data-y index-y index-x grid-y grid-x frozen? p0 p1
				]
			]
			px1
		]
		
		set-cells: function [
			face     [object! ] 
			grid-row [block!  ] "Draw row minus frozen"
			data-y   [integer!] "Data row number"
			index-y  [integer!] "Index row number"
			grid-y   [integer!] "Draw row number minus frozen"
			frozen?  [logic!  ]   
			py0      [integer!] "Row offset start"
			py1      [integer!] "Row offset end"
		][
			px0: freeze-point/x
			grid-x: 0
			while [px0 < size/x][
				grid-x: grid-x + 1
				index-x: current/x + grid-x
				;probe reduce [px0 grid-x index-x size/x]
				;probe reduce ["data-y" data-y "grid-y" grid-y "grid-x" grid-x "cur/x" current/x "index-x" index-x]
				either index-x <= total/x [;probe reduce [index-y index-x total]
					px0: set-cell face grid-row data-y index-y index-x grid-y grid-x frozen? px0 py0 py1
					;probe reduce [draw-y index-x grid-x grid-row]
					grid/x: grid-x
				][
					cell: grid-row/:grid-x
					either all [block? cell cell/6/x < self/size/x] [ 
						fix-cell-outside cell 'x
					][break]
				]
			]
			;probe copy grid-row
			cell: grid-row/(grid-x + 1)
			if all [block? cell cell/6/x < self/size/x] [ 
				fix-cell-outside cell 'x
			]
		]
		
		fill: function [
			face [object!] /only dim [word!]
		][
			recycle/off
			system/view/auto-sync?: off
			
			py0: 0
			draw-y: 0
			index-y: 0
			while [all [py0 < size/y index-y < total/y]][
				draw-y: draw-y + 1            ; Skim through draw rows; which number?
				frozen?: draw-y <= frozen/y   ; Is it frozen?
				index-y: get-index-row draw-y ; Corresponding index row
				data-y: get-data-row draw-y   ; Corresponding data row
				draw-row: face/draw/:draw-y   ; Actual draw-row
				unless block? draw-row [      ; Add new row if missing
					insert/only at face/draw draw-y draw-row: copy [] ; Make an empty row
					self/marks: next marks    ; Move marks-pointer further by one (new row before it)
				]
				sy: get-row-height data-y frozen? ;Row height is used in each cell
				py1: py0 + sy                 ; Accumulative height
				
				px0: 0                        ; Start from leftmost cell
				repeat draw-x frozen/x [      ; Render frozen cells first
					index-x: get-index-col draw-x ; Which index is given draw column
					px0: set-cell face draw-row data-y index-y index-x draw-y draw-x true px0 py0 py1 ;last: frozen
				]
				
				grid-row: skip draw-row frozen/x ; Move index to unfrozen cells
				grid-y: draw-y - frozen/y
				set-cells face grid-row data-y index-y grid-y frozen? py0 py1
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
			face/draw: face/draw
		]

		ask-code: function [/with default /txt deftext][
			view [
				below text "Code:" 
				code: area 400x100 focus with [
					case [
						with [text: mold/only default]
						txt  [text: copy deftext]
					]
				]
				across button "OK" [out: code/text unview] 
				button "Cancel"    [out: none unview]
				;do []
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
			ofs:  get-cell-offset face cell
			;either not all [auto: face/options/auto-col col = 0] [ ;Don't edit autokeys
			either col <> 0 [
				;if auto [col: col + 1]
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
					form case [
						all [addr/y >= 0 addr/x > 0] [any [data/(addr/y)/(addr/x) dummy]]
						all [v: virtual-rows/(addr/y) v: v/source/(addr/x)][v]
						all [v: virtual-cols/(addr/x) v: v/source/(addr/y)][v]
						true [dummy]
					]
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
		
		change-to-address: function [x [integer!] y [integer!] c [integer!] r [integer!]][
			rejoin case [
				x = 0 [[" " either sheet? [r][y]]]
				y = 0 [[" " either sheet? [c][x]]]
				all [0 < y 0 < x] [[" data/" y "/" x]]
				all [0 > y 0 > x] [
					either all [v: virtual-rows/y v: v/data/x] [
						[" virtual-rows/" y "/data/" x]
					][
						[" virtual-cols/" x "/data/" y]
					]
				]
				0 > y [[" virtual-rows/" y "/data/" x]]
				0 > x [[" virtual-cols/" x "/data/" y]]
			]
		]
		
		expand-virtual: function [cx addr /local nx ny r c r2 c2][
			parse cx [any [
				change [
					["R" copy r  int "C" copy c  int | "C" copy c  int "R" copy r  int] 
					any ws #":" any ws 
					["R" copy r2 int "C" copy c2 int | "C" copy c2 int "R" copy r2 int]
				] (
					r1: to-integer r
					y-diff: subtract to-integer r2 r1 
					c1: to-integer c
					x-diff: subtract to-integer c2 c1
					
					y-cf: pick [-1 1] negative? y-diff
					x-cf: pick [-1 1] negative? x-diff
					out: copy ""
					
					r1: r1 - y-cf
					c1: c1 - x-cf
					repeat ny (absolute y-diff) + 1 [
						y: pick row-index my: r1 + (ny * y-cf)
						repeat nx (absolute x-diff) + 1 [
							x: pick col-index mx: c1 + (nx * x-cf)
							append out change-to-address x y mx my
						]
					]
					out
				)
			|	change ["R" copy r int "C" copy c int | "C" copy c int "R" copy r int] (
					y: pick row-index r: to-integer r
					x: pick col-index c: to-integer c
					change-to-address x y c r
				)
			| 	change ["R" copy r int any ws #":" any ws "R" copy r2 int] (
					r1: to-integer r
					y-diff: subtract to-integer r2 r1 
					y-cf: pick [-1 1] negative? y-diff
					out: copy ""
					
					r1: r1 - y-cf
					x: addr/x ;pick col-index addr/x
					repeat ny (absolute y-diff) + 1 [
						y: pick row-index my: r1 + (ny * y-cf)
						append out change-to-address x y index? find col-index x my
					]
					out
				)
			|	change ["R" copy r int] (
					x: addr/x ;pick col-index addr/x
					y: pick row-index r: to-integer r
					change-to-address x y index? find col-index x r
				)
			| 	change ["C" copy c int any ws #":" any ws "C" copy c2 int] (
					c1: to-integer c
					x-diff: subtract to-integer c2 c1 
					x-cf: pick [-1 1] negative? x-diff
					out: copy ""
					
					c1: c1 - x-cf
					y: addr/y
					repeat nx (absolute x-diff) + 1 [
						x: pick col-index mx: c1 + (nx * x-cf)
						append out change-to-address x y mx index? find row-index y
					]
					out
				)
			|	change ["C" copy c int] (
					x: pick col-index c: to-integer c
					y: addr/y
					change-to-address x y c index? find row-index y
				)
			|	skip
			]]
		]
							
		update-data: function [face [object!]][; Face is edited field here
			switch type?/word addr2: addr: face/extra/addr [ ; This is data-address
				pair! [
					case [
						addr/y > 0 [;Don't update auto-row
							case [
								addr/x > 0 [ ; Don't update auto-col
									type: type? data/(addr/y)/(addr/x)
									;if face/extra/table/options/auto-col [addr2/x: addr/x + 1]  ;@@ ??
									data/(addr/y)/(addr/x): switch/default col-type/(addr2/x) [
										logic!      [tx: attempt [get face/data]]
										draw image! [tx: face/data]
										do          [tx: to-block face/text]
										icon        [tx: face/text]
									][tx: face/text either none! = type [tx][to type tx]]
									
									cell:  face/extra/cell   ; This is draw-cell address
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
									;Update virtual rows and cols
									system/view/auto-sync?: off
									foreach [row vr] virtual-rows [
										if code: vr/default [
											repeat gx total/x - top/x [
												index-x: top/x + gx
												col: col-index/:index-x
												if not vr/source/:col [
													expand-virtual cy: copy code as-pair col row
													vr/data/:col: do bind load/all cy self
												]
											]
											fill face/extra/table
										]
										if vr/code [
											foreach [x code] vr/code [ 
												vr/data/:x: do code
											]
										]
									]
									foreach [col vc] virtual-cols [
										if code: vc/default [
											repeat gy total/y - top/y [
												index-y: top/y + gy
												row: row-index/:index-y
												if not vc/source/:row [
													expand-virtual cx: copy code as-pair col row
													vc/data/:row: do bind load/all cx self
												]
											]
											fill face/extra/table
										]
										if vc/code [
											foreach [y code] vc/code [ 
												vc/data/:y: do code
											]
										]
									;face/draw: face/draw
									]
									show face
									system/view/auto-sync?: on
								]
								addr/x < 0 [
									either empty? tx: virtual-cols/(addr/x)/source/(addr/y): face/text [
										system/view/auto-sync?: off
										foreach elem [source code data][
											remove/key virtual-cols/(addr/x)/:elem addr/y
										]
										show face
										system/view/auto-sync?: on
									][
										cx: copy tx
										expand-virtual cx addr 
										cx: virtual-cols/(addr/x)/code/(addr/y): bind load/all cx face/extra/table/actors
										dx: virtual-cols/(addr/x)/data/(addr/y): do cx
										cell: face/extra/cell
										draw-cell: face/extra/table/draw/(cell/y)/(cell/x)
										draw-cell/11/3: form dx
									]
								]
							]
						]
						
						addr/y < 0 [
							either empty? tx: virtual-rows/(addr/y)/source/(addr/x): face/text [
								system/view/auto-sync?: off
								foreach elem [source code data][
									remove/key virtual-rows/(addr/y)/:elem addr/x
								]
								show face
								system/view/auto-sync?: on
							][
								cx: copy tx
								expand-virtual cx addr 
								cx: virtual-rows/(addr/y)/code/(addr/x): bind load/all cx face/extra/table/actors
								dx: virtual-rows/(addr/y)/data/(addr/x): do cx
								cell: face/extra/cell
								draw-cell: face/extra/table/draw/(cell/y)/(cell/x)
								draw-cell/11/3: form dx 
								;face/draw: face/draw
							]
						]
					]
				]
			] 
			fill face/extra/table ;Added temporarily for quick refreshing to update virtual rows
		]

		edit: function [ofs [pair!] sz [pair!] txt [string!]][
			win: tbl-editor
			until [win: win/parent win/type = 'window]
			tbl-editor/offset:    ofs
			tbl-editor/size:      sz
			tbl-editor/text:      txt
			tbl-editor/visible?:  yes
			win/selected:         tbl-editor
		]

		edit-column: function [face [object!] event [event! none!]][
			col: get-col-number face event
			case [
				col > 0 [ ; Don't edit auto-col
					if code: ask-code [
						code: load/all code 
						code: back insert next code '_
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
				col < 0 [
					if code: either s: virtual-cols/:col/default [ask-code/txt s][ask-code] [
						system/view/auto-sync?: off
						repeat gy total/y - top/y [
							index-y: top/y + gy
							row: row-index/:index-y
							either empty? virtual-cols/:col/default: copy code [
								virtual-cols/:col/default: none
								if not virtual-cols/:col/source/:row [
									remove/key virtual-cols/:col/data row
								]
							][
								if not virtual-cols/:col/source/:row [
									expand-virtual cx: copy code as-pair col row
									virtual-cols/:col/data/:row: do bind load/all cx self
								]
							]
						]
						fill face
						show face
						system/view/auto-sync?: on
					] 
				]
			]
		]

		set-col-type: function [face [object!] event [event! integer!] /only typ [word!]][
			col: either event? event [get-col-number face event][event]
			if not all [not only col = 0][;auto: face/options/auto-col  col = 1][
				;if all [auto not only] [col: col - 1]
				old-type: col-type/:col
				col-type/:col: type: either event? event [event/picked][typ]
				forall data [
					;probe reduce [data/1]
					either block? data/1 [
						if not find frozen-rows index? data [
							data/1/:col: switch/default type [
								draw do     [to block! any [data/1/:col dummy]]
								load image! [load any [data/1/:col dummy]]
								string!     [mold any [data/1/:col dummy]]
								logic! [
									case [
										all [series? data/1/:col empty? data/1/:col][
											data/1/:col: false                          ; Empty series -> false
										]
										logic? data/1/col []                            ; It's logic! already, do nothing
										all [string? data/1/:col  val: get/any to-word data/1/:col][
											data/1/:col: either logic? val [val][false] ; Textual logic values get mapped
										]
										none? data/1:col [data/1/:col: false]
										'else [data/1/:col: true]                       ; Should it be false instead?
									]
								]
								icon [form any [data/1/:col dummy]]
							][
								attempt [to reduce type any [data/1/:col dummy]]
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
		
		add-new-row: function [face [object!]][
			row: make block! total/x
			repeat col total/x [
				;if face/options/auto-col [col: col + 1] ;@@ ??? Should it?
				content: any [
					defaults/:col
					all [
						type: col-type/:col
						switch/default type [
							do draw image! [copy []] 
							load icon [none]
							;icon [copy ""]
						][make reduce type 0]
					]
					;copy ""
				]
				append/only row content
			]
			append/only data row
			total/y: total/y + 1
		]

		add-virtual-row: function [face [object!]][
			x: total/x
			vr: object [addr: none source: make map! x code: make map! x data: make map! x default: none]
			len: negate 1 + length? virtual-rows
			virtual-rows/:len: vr
			total/y: total/y + 1
			len
		]
		
		add-virtual-col: function [face [object!]][
			y: total/y
			vc: object [addr: none source: make map! y code: make map! y data: make map! y default: none]
			len: negate 1 + length? virtual-cols
			virtual-cols/:len: vc
			total/x: total/x + 1
			len
		]
		
		refresh-view: func [face [object!]][
			set-last-page
			adjust-scroller face
			fill face
			show-marks face
		]
		
		insert-row: function [face [object!] event [event!]][
			dr: get-draw-row face event
			r: get-index-row dr
			add-new-row face 
			insert/only at row-index r total/y
			refresh-view face
		]

		append-row: function [face [object!]][
			add-new-row face
			append row-index total/y
			refresh-view face
		]

		insert-virtual-row: function [face [object!] event [event! integer!]][
			dr: get-draw-row face event
			ir: get-index-row dr
			vr: add-virtual-row face 
			insert/only at row-index ir vr
			;probe row-index
			refresh-view face
		]
		
		append-virtual-row: function [face [object!]][
			vr: add-virtual-row face
			append row-index vr
			refresh-view face
		]

		insert-col: function [face [object!] event [event! none!]][
			dc: get-draw-col face event
			c: get-index-col dc
			repeat i total/y [append data/:i none];copy ""]
			total/x: total/x + 1
			insert/only at col-index c total/x
			refresh-view face
		]

		append-col: function [face [object!]][
			repeat i total/y [append data/:i none];copy ""]
			total/x: total/x + 1
			append col-index total/x
			refresh-view face
		]
		
		insert-virtual-col: function [face [object!] event [event! integer!]][
			dc: get-draw-col face event
			ic: get-index-col dc
			vc: add-virtual-col face 
			insert/only at col-index ic vc
			;probe row-index
			refresh-view face
		]
		
		append-virtual-col: function [face [object!]][
			vc: add-virtual-col face
			append col-index vc
			refresh-view face
		]

		remove-row: function [face [object!] event [event!]][
			dr: get-draw-row face event
			r: get-index-row dr
			remove at row-index r
			refresh-view face
		]
		
		remove-col: function [face [object!] event [event!]][
			dc: get-draw-col face event
			c: get-index-col dc
			remove at col-index c
			refresh-view face
		]
		
		restore-row: function [face [object!]][
			append clear row-index default-row-index
			refresh-view face
		]
		
		restore-col: function [face [object!]][
			append clear col-index default-col-index
			refresh-view face
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
			refresh-view face
		]
		
		delete-col: function [face [object!] event [event!]][
			dc: get-draw-col face event
			ci: get-index-col dc
			cd: get-data-col dc
			;if face/options/auto-col [cd: cd - 1]
			if cd > 0 [
				foreach row data [either block? row [remove at row cd][break]]
				remove at col-index ci
				repeat i length? col-index [
					if col-index/:i > cd [col-index/:i: col-index/:i - 1]
				]
				take/last default-col-index
				refresh-view face
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
							;if face/options/auto-col [x: x - 1]
							y: row-index/(pos/y)
							put colors as-pair x y color
						]
					]
				)
			|	pair! (
					x: col-index/(s/1/x)
					;if face/options/auto-col [x: x - 1]
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
		
		filter-rows: function [face [object!] data-col [integer!] crit [any-type!] /extern filtered row-index][
			c: data-col
			;if auto: face/options/auto-col [c: c - 1];col-index/(col - 1)
			either block? crit [
				switch/default type?/word w: crit/1 [
					word! [
						case [
							op? get/any w [
								forall row-index [
									;if not find frozen-rows 
									row: first row-index 
									;[
										;insert/only crit either all [auto col = 1] [row][data/:row/:c]
										insert/only crit either data-col = 0 [row][data/:row/:c]
										if do crit [append filtered/y row]
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
										;change/only crit either all [auto col = 1] [row][data/:row/:c]
										change/only crit either data-col = 0 [row][data/:row/:c]
										if do head crit [append filtered/y row]
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
										;change/only crit either all [auto col = 1] [row][data/:row/:c]
										change/only crit either data-col = 0 [row][data/:row/:c]
										if do head crit [append filtered/y row]
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
								;change/only crit either all [auto col = 1] [row][data/:row/:c]
								change/only crit either data-col = 0 [row][data/:row/:c]
								if do head crit [append filtered/y row]
							;]
						]				
					]
				][  ;Simple list
					;either all [auto col = 1] [
					either data-col = 0 [
						normalize-range crit  ;Use charset spec to select rows
						filtered/y: intersect row-index crit
					][
						insert crit [_ =]
						forall row-index [
							;if not find frozen-rows 
							row: first row-index 
							;[
								if find crit data/:row/:c [append filtered/y row]
							;]
						]
					]
				]
			][  ;Single entry
				case [
					data-col > 0 [
						forall row-index [
							row: row-index/1
							if data/:row/:c = crit [append filtered/y row]
						]
					]
					data-col = 0 [
						filtered/y: to-block crit
					]
					data-col < 0 [
						
					]
				]
			]
		]
		
		filter: function [face [object!] data-col [integer!] crit [any-type!] /extern filtered row-index top current][
			;append clear filtered/y frozen-rows ;include frozen rows in result first
			row-index: skip row-index top/y
			scroller/y/position: 1 + top/y: current/y: frozen/y 
			filter-rows face data-col crit
			row-index: head append clear row-index filtered/y
				   
			adjust-scroller face
			set-last-page
			unmark-active face
			on-filter face
			fill face
			face/draw: face/draw
		]
		
		on-filter: func [face [object!]][]
		
		unfilter: func [face [object!]][
			clear filtered/y
			append clear head row-index default-row-index
			adjust-scroller face
			on-filter face
			fill face
			face/draw: face/draw
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
							m: index/:dim/(i + n)
							sizes/:dim/:m: sz + df
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
							;if auto: face/options/auto-col [d/x: d/x - 1]
							append/only selected-data out: 
								either d/x = 0 [
									d/y
								][
									data/(d/y)/(d/x)
								]
							repend clpbrd [mold out tab]
							if cut [data/(d/y)/(d/x): none];copy ""]
						]
						change back tail clpbrd lf
					] 
				)
				|  pair! (
					row: row-index/(s/1/y)
					col: col-index/(s/1/x)
					;if auto: face/options/auto-col [col: col - 1]
					append/only selected-data out: 
						either col = 0 [
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
							;if face/options/auto-col [pos/x: pos/x - 1]
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
					;if face/options/auto-col [pos/x: pos/x - 1]
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
			either 0 = col [
				append clear head row-index default-row-index
				if frozen/y > 0 [row-index: skip row-index frozen-rows/(frozen/y)]
				if down [reverse row-index]
				row-index: head row-index
			][
				either indices/x/:col [clear indices/x/:col][indices/x/:col: make block! total/y]
				c: absolute col
				;if face/options/auto-col [c: c - 1]
				idx: skip head row-index top/y
				sort/compare idx function [a b][
					attempt [case [
						all [loaded down][(load data/:b/:c) <= (load data/:a/:c)];[(load data/:a/:c) >  (load data/:b/:c)]
						loaded           [(load data/:a/:c) <= (load data/:b/:c)]
						down             [data/:b/:c <= data/:a/:c];[data/:a/:c >  data/:b/:c]
						true             [data/:a/:c <= data/:b/:c]
					]]
				]
				append indices/x/:col row-index
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
							all [key = 'right ofs: get-cell-offset face pos + step ofs/2/x > size/x x <> 'done] 
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
				either event/ctrl? [
					switch key [
						#"C" [copy-selected face]
						#"X" [copy-selected/cut face]
						#"V" [paste-selected face]
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
		]
		
		do-menu: function [face [object!] event [event! none!]][
			switch/default event/picked [
				; TABLE
				open-table      [open-table face]
				save-table      [save-table face]
				save-table-as   [save-table-as face]
				save-state      [save-state face]
				use-state       [use-state face]
				unhide-all      [unhide-all  face]
				;force-state     [use-state/force face]
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
				insert-virtual-row [insert-virtual-row face event]
				append-virtual-row [append-virtual-row face]
				
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
				insert-virtual-col [insert-virtual-col face event]
				append-virtual-col [append-virtual-col face]
				
				find-in-col     [find-in-col face event]
				
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

				set-default     [set-default face event]

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
				case [
					on-border? [
						adjust-border face event 'x
						adjust-border face event 'y
						fill face
						show-marks face
					]
					event/ctrl? []
					true [
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
			]
			no-over: false
		]
		
		find-in-row: function [face [object!] event [event!]][
			code: ask-code
			clear face/selected
			r: get-row-number face event
			foreach c col-index [
				;if face/options/auto-col [c0: c - 1]
				;if (form data/:r/:c0) ~ code [append face/selected as-pair c r]
				if (form data/:r/:c) ~ code [append face/selected as-pair c r]
			]
			;probe face/selected
			show-marks face
		]

		find-in-col: function [face [object!] event [event! integer!] /extern filtered row-index][
			if code: ask-code [
				code: load code
				col: case [
					event? event [get-col-number face event]
					sheet? [col-index/:col]
					true   [col]
				]

				;append clear filtered/ frozen-rows ;include frozen rows in result first
				clear filtered/y
				row-index: skip head row-index top/y
				filter-rows face col code
				row-index: head row-index
				clear face/selected
				index-col: index? find col-index col
				foreach r filtered/y [
					index-row: index? find row-index r 
					append face/selected as-pair index-col index-row
				]
				if not empty? face/selected [
					;current/y: top/y
					first-found: index? find row-index filtered/y/1
					scroll face 'y first-found - current/y - 1 
					;adjust-scroller face
					;fill face
					marks/-1: 0.220.0.220
					show-marks face
				]
			]
		]
		
		; OPEN
		
		open-red-table: func [face [object!] fdata [block!] /only /local opts i col type sz][
			starting?: yes
			either only [
				opts: fdata
			][
				opts: fdata/2 
				data: remove/part fdata 2
			]
			sheet?: to-logic find [true on yes] opts/sheet
			either sheet? [
				put face/options 'sheet yes
				put face/options 'auto-col auto-col?: yes 
				put face/options 'auto-row auto-row?: yes
			][
				auto-col?: to-logic find [true on yes] opts/auto-col ;index
				auto-row?: to-logic find [true on yes] opts/auto-row ;index
				put face/options 'auto-col auto-col?
				put face/options 'auto-row auto-row?
				;either find face/options 'auto-col [
				;	face/options/auto-col: auto-col?
				;][
				;	append face/options compose [auto-col: (auto-col?)]
				;]
			]
			init-grid face ;/only
			init-indices/only face
			;probe reduce [opts opts/frozen-rows]
			if opts/frozen-cols [append clear frozen-cols opts/frozen-cols]
			if opts/frozen-rows [append clear frozen-rows opts/frozen-rows]
			frozen: as-pair length? frozen-cols length? frozen-rows
			append clear col-index either opts/col-index [opts/col-index][default-col-index]
			append clear row-index either opts/row-index [opts/row-index][default-row-index]
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
			if opts/defaults [defaults: to-map opts/defaults]
			
			box: any [opts/box default-box]
			top: case/all [
				(x: frozen/x) > 0 [x: index? find col-index frozen-cols/:x] 
				(y: frozen/y) > 0 [y: index? find row-index frozen-rows/:y] 
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
			
			fill face
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
		
		open-big-table: function [face [object!] /with file][
			if any [file file: request-file/title "Open large file"] [
				self/big-size: length? read/binary file
				self/big-length: length? csv: head clear find/last read/binary/part file 1000'000 lf
				face/data: file
				
				self/data: load-csv to-string csv
				;save rejoin [file "-1.redbin"] self/data
				open-red-table/only face [frozen-rows: [1]]
				;lines: 1 c: csv while [c: find/tail c lf][lines: lines + 1] lines
			]
		]
		
		next-chunk: function [face [object!]][
			file: face/data
			self/big-last: big-last + big-length + 1
			append self/prev-lengths big-length
			state: save-state/only/with face [col-sizes col-types frozen-cols] ;col-index ? why error?
			if attempt [found: find/last read/binary/seek/part file big-last 1000'000 lf] [
				self/big-length: length? csv: head clear found
				;probe reduce ["Next:" big-last big-length]
				csv: to-string csv 
				either error? loaded: load-csv csv [loaded halt][
					self/data: loaded
					;save rejoin [file "-" 1 + length? prev-lengths ".redbin"] loaded
				]
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
				either error? loaded: load-csv csv [loaded halt][self/data: loaded]
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
				top:         (top)
				current:     (current)
				col-sizes:   (body-of sizes/x)
				row-sizes:   (body-of sizes/y)
				box:         (box)
				row-index:   (row-index)
				col-index:   (col-index)
				auto-col:    (face/options/auto-col)
				auto-row:    (face/options/auto-row)
				col-type:    (body-of col-type)
				selected:    (face/selected)
				anchor:      (anchor)
				active:      (active)
				names:       (body-of names)
				defaults:    (body-of defaults)
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

		on-up: function [face [object!] event [event! none!]][
			case [
				on-border? [
					set-grid-offset face
					set-last-page
				]
				event/ctrl? [
					address: get-draw-address face event
					case/all [
						pos/x <> address/x [move at col-index pos/x  at col-index address/x]
						pos/y <> address/y [move at row-index pos/y  at row-index address/y]
					]
					fill face
				]
				true [
					if all [
						same-offset?
						address: get-data-address face event
						col-type/(address/x) = 'logic!
					][
						;if face/options/auto-col [address/x: address/x - 1] 
						data/(address/y)/(address/x): not data/(address/y)/(address/x) 
						fill face
					]
				]
			]
			address
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
				block? config: data/2 ;opts:
				;opts/current
			][
				open-red-table face data config
			][
				set-data face face/data
				either config: face/options/config [
					if file? config [config: load config]
					open-red-table/only face config
				][
					if face/options/sheet [
						sheet?: yes
						put face/options 'auto-col auto-col?: yes
						put face/options 'auto-row auto-row?: yes
					]
					init face
				]
			]
			;inspect on-created
		]
		
		on-menu: function [face [object!] event [event! none!]][do-menu face event]
	]
]
style 'table tbl