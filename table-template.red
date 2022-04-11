Red []
;#include %../utils/leak-check.red
#include %style.red
#include %re.red
~: make op! func [a b][re a b]
tpl: [
	type: 'base 
	size: 300x200 
	color: silver
	flags: [scrollable all-over]
	options: [auto-index: #[true]]
	extra: make map! [data: none draw: none table: none]
	me: self
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
			"Filter ..."    filter
			"Unfilter"      unfilter
			"Freeze"        freeze-col
			"Unfreeze"      unfreeze-col
			"Default width" default-width
			"Full height"   full-height
			"Edit ..."      edit-column
			"Type"   [
				"integer!" integer! 
				"float!"   float! 
				"percent!" percent! 
				"string!"  string! 
				"block!"   block! 
				"date!"    date! 
				"time!"    time!
			]
		]
		"Selection" [
			"Copy"      copy-selection
			"Cut"       cut-selection
			"Paste"     paste-selection
			"Transpose" transpose
		]
	]
	actors: [
		scroller: 
		data: loaded:  
		indexes: filtered: 
		default-row-index: row-index: 
		default-col-index: col-index: 
		sizes: full-height-col:
		on-border?: border-col: border-row:
		tbl-editor: 
		marks: anchor: active: pos:
		extra?: extend?: none
		
		total: size: 0x0
		frozen: freeze-point: 0x0
		current: top: 0x0
		grid: grid-size: grid-offset: 0x0
		last-page: 0x0
		box: 100x25
		tolerance: 20x5
		
		frozen-cols: make block! 20
		frozen-rows: make block! 20
		draw-block:  make block! 1000
		filter-cmd:  make block! 10
		selection-data: make block! 10000
		selection-figure: make block! 10
		
		frozen-nums: make map! 2
		frozen-nums/x: frozen-cols
		frozen-nums/y: frozen-rows
		
		index: make map! 2

		
		set-border: function [face ofs dim][
			ofs: ofs/:dim
			cum: 0     ;accumulator
			repeat i frozen/:dim [
				cum: cum + get-size dim frozen-nums/:i
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

		on-border: function [face ofs][
			border: 0x0
			border/x: set-border face ofs 'x
			border/y: set-border face ofs 'y
			either border = 0x0 [false][border]
		]

		set-grid: function [face][
			foreach dim [x y][
				cur: current/:dim
				sz: 0
				repeat i total/:dim - cur [
					j: cur + i
					sz: sz + get-size dim index/:dim/:j
					if sz >= grid-size/:dim [
						grid-offset/:dim: sz - grid-size/:dim 
						break
					]
				]
				grid/:dim: i
			]
		]
		
		set-freeze-point: func [face /local fro][
			fro: frozen
			if fro/y > 0 [fro/y: face/draw/(fro/y)/1/7/y]
			if fro/x > 0 [fro/x: face/draw/1/(fro/x)/7/x]
			grid-size: size - fro
			freeze-point: fro
		]
		
		set-grid-offset: func [face /local end][
			end: get-draw-offset/end face frozen + grid
			grid-offset: end - size
		]
		
		get-draw-address: function [face event][
			col: get-draw-col face event
			row: get-draw-row face event
			;row: round/ceiling/to event/offset/y / box/y 1
			as-pair col row
		]
		
		get-draw-offset: function [face cell /start /end][
			if all [block? row: face/draw/(cell/y) s: row/(cell/x)] [
				case [
					start [s/6]
					end   [s/7]
					true  [copy/part at s 6 2]
				]
			]
		]

		get-draw-col: function [face event][
			row: face/draw/1
			col: length? row 
			ofs: event/offset/x
			forall row [if row/1/7/x > ofs [col: index? row break]]
			col
		]
		
		get-draw-row: function [face event][
			rows: face/draw 
			;index? find/last face/draw block!
			row: total/y ;frozen/y + grid/y
			ofs: event/offset/y
			repeat i row [if rows/:i/1/7/y > ofs [row: i break]]
			row
		]
		
		get-col-number: function [face event][ 
			col: get-draw-col face event
			col: either col <= frozen/x [
				frozen-cols/:col
			][
				col-index/(col - frozen/x + current/x)
			]
		]

		get-data-address: function [face event /with cell][
			if not cell [cell: get-draw-address face event]
			out: get-logic-address cell
			if face/options/auto-index [out/x: out/x - 1]
			out
		]
		
		get-logic-address: func [cell][
			as-pair get-data-col cell/x  get-data-row cell/y
		]
		
		get-data-col: function [col][
			col: either col <= frozen/x [
				frozen-cols/:col
			][
				col-index/(col - frozen/x + current/x)
			]
		]

		get-data-row: function [row][
			either row <= frozen/y [
				frozen-rows/:row
			][
				row-index/(row - frozen/y + current/y)
			]
		]
		
		get-data-index: func [num dim][
			either dim = 'x [get-data-col num][get-data-row num]
		]

		get-index-address: func [draw-cell][
			as-pair get-index-col draw-cell/x  get-index-row draw-cell/y
		]
		
		get-index: func [num dim][
			either dim = 'x [get-index-col num][get-index-row num]
		]

		get-index-col: function [draw-col][
			either draw-col <= frozen/x [
				index? find col-index frozen-cols/:draw-col
			][
				draw-col - frozen/x + current/x
			]
		]

		get-index-row: function [draw-row][
			either draw-row <= frozen/y [
				;probe reduce [frozen/y draw-row frozen-rows/:draw-row index? find row-index frozen-rows/:draw-row]
				index? find row-index frozen-rows/:draw-row
			][
				draw-row - frozen/y + current/y
			]
		]

		set-last-page: function [][
			foreach dim [x y][
				t: total/:dim
				j: sz: 0
				while [
					r: index/:dim/(t - j)
					sz: sz + s: get-size dim r
					sz <= grid-size/:dim
				][j: j + 1]
				last-page/:dim: j
			]
		]
		
		; INITIATION

		init-data: func [spec /local row][
			data: make block! spec/y 
			loop spec/y [
				row: make block! spec/x
				loop spec/x [append row copy ""]
				append/only data row
			]
		]

		set-data: func [face spec /local row][
			switch type?/word spec [
				file!  [data: load spec] ;load/as head clear tmp: find/last read/part file 5000 lf 'csv ;
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
		
		init-grid: func [face /local i][
			total/y: length? data
			total/x: length? first data
			if face/options/sheet? [face/options/auto-index: face/options/auto-columns: yes]
			if face/options/auto-index   [total/x: total/x + 1] ; add auto-index
			if face/options/auto-columns [total/y: total/y + 1]
			sizes: reduce [
				'x make map! copy []
				'y make map! copy []
			]
			grid-size: size: face/size - 17
			;set-grid face
			clear frozen-rows
			clear frozen-cols
		]

		init-indices: func [face force /local i][
			;Prepare indexes
			either all [indexes not force] [
				;clear indexes
				;clear default-row-index
				;clear default-col-index
				;clear frozen-rows
				;clear frozen-cols
			][
				indexes: make map! total/x                             ;Room for index for each column
				filtered: 
					copy row-index:                                    ;Active row-index
					copy default-row-index: make block! total/y        ;Room for row numbers
				col-index: copy default-col-index: make block! total/x ;Active col-index and room for col numbers
			
				repeat i total/y [append default-row-index i]          ;Default is just simple sequence in initial order
				if face/options/auto-index [
					indexes/1: copy default-row-index                  ;Default is for first (auto-index) column
				]
				append clear row-index default-row-index               ;Set default as active index
				repeat i total/x [append default-col-index i] 
				append clear col-index default-col-index
				index/x: col-index
				index/y: row-index
			]

			set-last-page
			adjust-scroller face
		]

		init-fill: function [face /extern marks grid-offset][
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
			mark-active face 1x1
			set-grid-offset face
		]

		init: func [face /force][
			frozen: current: 0x0
			face/selected: copy []
			scroller/x/position: scroller/y/position: 1
			if not empty? data [
				init-grid face
				init-indices face force
				init-fill face
			]
		]

		;-------------

		get-size: func [dim idx][
			any [sizes/:dim/:idx box/:dim]
		]
		
		get-color: func [i frozen?][
			case [frozen? [silver] odd? i [white] 'else [snow]]
		]
		
		set-default-height: function [face event][
			dr: get-draw-row face event
			r:  get-data-row dr
			if sz: sizes/y/:r [
				remove/key sizes/y r
				if dr <= frozen/y [
					df: box/y - sz
					freeze-point/y: freeze-point/y + df
				]
				fill face
				show-marks face
			]
		]
		
		set-default-width: function [face event][
			dc: get-draw-col face event
			c:  get-data-col dc
			if sz: sizes/x/:c [
				remove/key sizes/x c
				if dc <= frozen/x [
					df: box/x - sz
					freeze-point/x: freeze-point/x + df
				]
				fill face
			]
		]
		
		set-full-height: func [face event][
			full-height-col: get-draw-col face event
			fill face
			adjust-scroller face
			show-marks face
		]
		
		; FILLING
		
		fill-cell: function [face cell data-row-idx draw-row-idx index-col frozen? /size p0 p1][
			;probe reduce [cell data-row-idx draw-row-idx index-col frozen]
			either index-col <= total/x [
				data-col-idx: col-index/:index-col
				if auto: face/options/auto-index [data-col-idx: data-col-idx - 1]
				cell/11/3: form either all [auto data-col-idx = 0] [data-row-idx][data/:data-row-idx/:data-col-idx]
				cell/4: get-color draw-row-idx frozen?
				if size [
					cell/9: (cell/6:  p0) + 1
					cell/10: (cell/7:  p1) - 1 
					cell/11/2:  4x2  +  p0
				]
			][
				fix-cell-outside cell 'x 
			]
		]
		
		add-cell: function [face row data-row-idx draw-row-idx draw-col-idx index-col p0 p1 frozen?][
			data-col-idx: col-index/:index-col
			if auto: face/options/auto-index [data-col-idx: data-col-idx - 1]
			text: form either all [auto data-col-idx = 0] [data-row-idx][data/:data-row-idx/:data-col-idx]
			insert/only at row draw-col-idx compose/deep [
				line-width 1
				fill-pen (get-color draw-row-idx frozen?)
				box (p0) (p1)
				clip (p0 + 1) (p1 - 1) 
				[
					text (p0 + 4x2)  (text)
				]
			]
		]

		set-cell: func [face row index-col data-row-idx draw-row-idx draw-col-idx px0 py0 py1 frozen?][
			sx: get-size 'x col-index/:index-col
			px1: px0 + sx
			p0: as-pair px0 py0
			p1: as-pair px1 py1
			either block? cell: row/:draw-col-idx [
				fill-cell/size face cell data-row-idx draw-row-idx index-col frozen? p0 p1
			][
				if index-col <= total/x [
					add-cell face row data-row-idx draw-row-idx draw-col-idx index-col p0 p1 frozen?
				]
			]
			px1
		]
		
		fix-cell-outside: func [cell dim][
			cell/11/2/:dim: cell/9/:dim: cell/10/:dim: cell/6/:dim: cell/7/:dim: size/:dim
		]
		
		set-cells: function [face row data-row-idx draw-row-idx py0 py1 frozen?][
			px0: freeze-point/x
			grid-col: 0
			while [px0 < size/x][
				grid-col: grid-col + 1
				index-col: current/x + grid-col
				either index-col <= total/x [
					px0: set-cell face row index-col data-row-idx draw-row-idx grid-col px0 py0 py1 frozen?
					grid/x: grid-col
				][
					cell: row/:grid-col
					either all [block? cell cell/6/x < self/size/x] [ 
						fix-cell-outside cell 'x
					][break]
				]
			]
			cell: row/(grid-col + 1)
			if all [block? cell cell/6/x < self/size/x] [ 
				fix-cell-outside cell 'x
			]
		]
		
		fill: function [face /only dim][
			recycle/off
			system/view/auto-sync?: off
			
			py0: 0
			draw-row-idx: 0
			index-row: 0
			while [all [py0 < size/y index-row < total/y]][
				draw-row-idx: draw-row-idx + 1
				frozen?: draw-row-idx <= frozen/y
				data-row-idx: get-data-row draw-row-idx
				index-row: get-index-row draw-row-idx
				draw-row: face/draw/:draw-row-idx
				unless block? draw-row [
					insert/only at face/draw draw-row-idx draw-row: copy [] 
					self/marks: next marks
				]
				either all [
					full-height-col 
					draw-row-idx > frozen/y
					data-col-idx: get-data-col full-height-col
					not sizes/y/:data-row-idx
				][
					d: data/:data-row-idx/:data-col-idx
					n: 0 parse d [any [lf (n: n + 1) | skip]]
					sizes/y/:data-row-idx: sy: n + 1 * 16 ;box/y
				][
					sy: get-size 'y data-row-idx
				]
				py1: py0 + sy
				
				px0: 0
				repeat draw-col-idx frozen/x [
					index-col: get-index-col draw-col-idx
					px0: set-cell face draw-row index-col data-row-idx draw-row-idx draw-col-idx px0 py0 py1 true
				]
				draw-row: at draw-row frozen/x + 1
				grid-row-idx: draw-row-idx - frozen/y
				set-cells face draw-row data-row-idx grid-row-idx py0 py1 frozen?
				grid/y: grid-row-idx
				py0: py1
			]                                                                                                                                                     
			while [all [block? draw-row: face/draw/(draw-row-idx: draw-row-idx + 1) draw-row/1/6/y < size/y]][
				foreach cell draw-row [fix-cell-outside cell 'y]
			]
			scroller/y/page-size: grid/y
			scroller/x/page-size: grid/x
			
			show face
			system/view/auto-sync?: on
			recycle/on
		]

		;---------

		ask-code: function [][
			view [
				below text "Code:" 
				code: area 400x100 focus
				across button "OK" [out: code/text unview] 
				button "Cancel" [out: none unview]
			]
			out
		]
		
		; EDIT
		
		make-editor: func [table][
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
						down  [show-editor face/extra/table none face/extra/draw + 0x1]
						up    [show-editor face/extra/table none face/extra/draw - 0x1]
						#"^-" [
							either find event/flags 'shift [
								show-editor face/extra/table none face/extra/draw - 1x0
							][
								show-editor face/extra/table none face/extra/draw + 1x0
							]
						]
					]
				] on-focus [
					face/options/text: copy face/text
				]
			] 
		]
		
		show-editor: function [face event cell][
			addr: get-data-address/with face event cell
			ofs:  get-draw-offset face cell
			either not all [face/options/auto-index addr/x = 0] [ ;Don't edit autokeys
				tbl-editor/extra/table: face
				txt: face/draw/(cell/y)/(cell/x)/11/3
				tbl-editor/extra/data: addr                       ;Register cell
				tbl-editor/extra/draw: cell
				;sz: as-pair sizes/x/(cell/x) box/y
				fof: face/offset                                  ;Compensate offset for VID space
				edit fof + ofs/1 ofs/2 - ofs/1 txt
			][tbl-editor/visible?: no]
		]
		
		hide-editor: does [
			if all [tbl-editor tbl-editor/visible?] [tbl-editor/visible?: no]
		]
		
		update-data: function [face][
			switch type?/word e: face/extra/data [
				pair! [
					type: type? data/(e/y)/(e/x)
					data/(e/y)/(e/x): to type face/text
				]
			] 
		]

		edit: function [ofs sz txt][
			win: tbl-editor
			until [win: win/parent win/type: 'window]
			tbl-editor/offset:    ofs
			tbl-editor/size:      sz
			tbl-editor/text:      txt
			tbl-editor/visible?:  yes
			win/selected:         tbl-editor
		]

		edit-column: function [face event][
			if code: ask-code [
				code: load/all code 
				code: back insert next code '_
				col: get-col-number face event
				if not all [face/options/auto-index col = 0][
					foreach row at data top/y + 1 [
						change/only code row/:col
						row/:col: do head code
					]
					fill face
				]
			]
		]
		
		; MARKS
		
		set-new-mark: func [face cell][
			append face/selected anchor: cell 
		]
		
		mark-active: func [face cell /extend /extra][
			pos: cell
			active: get-index-address cell
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
		
		unmark-active: func [face][
			if active [
				clear marks
				extend?: extra?: false
				anchor: active: pos: none
				clear face/selected
			]
		]
		
		mark-address: function [s dim][
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

		mark-point: function [face a /end][
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

		show-marks: function [face][
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
				;probe reduce [face/selected "r1c1" r1 c1 "r2c2" r2 c2 "a b" a b "p" p1 p2]
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
		]
		
		;----------
		
		normalize-range: function [range [block!]][
			bs: charset range
			clear range
			repeat i length? bs [if bs/:i [append range i]]
		]

		filter: function [face col [integer!] crit /extern filtered][
			append clear filtered frozen-rows ;include frozen rows in result first
			c: col
			if auto: face/options/auto-index [c: c - 1];col-index/(col - 1)
			either block? crit [
				
				switch/default type?/word w: crit/1 [
					word! [
						case [
							op? get/any w [
								forall row-index [
									if not find frozen-rows row: first row-index [
										insert/only crit either all [auto col = 1] [row][data/:row/:c]
										if do crit [append filtered row]
										remove crit
									]
								]
							]
							any-function? get/any w [
								crit: back insert next crit '_
								forall row-index [
									if not find frozen-rows row: first row-index [
										change/only crit either all [auto col = 1] [row][data/:row/:c]
										if do head crit [append filtered row]
									]
								]
							]
						]
					]
					path! [
						case [
							any-function? get/any w/1 [
								crit: back insert next crit '_
								forall row-index [
									if not find frozen-rows row: first row-index [
										change/only crit either all [auto col = 1] [row][data/:row/:c]
										if do head crit [append filtered row]
									]
								]
							]
						]
					]
					paren! [
						
					]
				][  ;Simple list
					either all [auto col = 1] [
						normalize-range crit  ;Use charset spec to select rows
						filtered: intersect row-index crit
					][
						insert crit [_ =]
						forall row-index [
							if not find frozen-rows row: first row-index [
								if find crit data/:row/:c [append filtered row]
							]
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
			append clear row-index filtered
			set-last-page
			adjust-scroller face
			unmark-active face
			fill face
		]

		freeze: function [face event dim /extern grid][
			fro: frozen
			cur: current
			frozen/:dim: either dim = 'x [
				get-draw-col face event
			][
				get-draw-row face event
			]
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
		]

		unfreeze: function [face dim][
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

		adjust-size: func [face /local cum dim i index sz block][
			grid-size: size - freeze-point
			set-grid face
			set-last-page 
		]

		adjust-border: function [face event dim][
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
					]
					event/ctrl? [
						sz: get-size dim index/:dim/:num
						i: num - 1
						repeat n total/:dim - num + 1 [
							sizes/:dim/(i + n): sz + df
							;adjust freeze-point?
						]
					]
					true [
						sz: get-size dim i: index/:dim/:num
						sizes/:dim/:i: sz + df
						if on-border?/:dim <= frozen/:dim [freeze-point/:dim: freeze-point/:dim + df]
					]
				]
			]
		]

		; SCROLLING
		
		make-scroller: func [face /local vscr hscr][
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
				fill face
			]
			step
		]

		adjust-scroller: func [face /only][
			unless only [set-grid face]
			scroller/y/max-size:  max 1 total/y: length? row-index 
			scroller/y/page-size: min grid/y scroller/y/max-size
			scroller/x/max-size:  max 1 total/x: length? col-index 
			scroller/x/page-size: min grid/x scroller/x/max-size
		]

		set-scroller-pos: function [face dim steps][
			pos0: scroller/:dim/position
			min-pos: top/:dim + 1
			max-pos: scroller/:dim/max-size - last-page/:dim + pick [2 1] grid-offset/:dim > 0
			mid-pos: scroller/:dim/position + steps
			pos1: scroller/:dim/position: max min-pos min max-pos mid-pos
			pos1 - pos0
		]
		
		count-cells: function [face dim dir /by-keys][
			case [
				dir > 0 [
					start: current/:dim + grid/:dim 
					gsize: 0 
					repeat count total/:dim - start [
						start: start + 1
						bsize: get-size dim index/:dim/:start
						gsize: gsize + bsize
						if grid-size/:dim <= gsize [break]
					]
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
		
		count-steps: function [face event dim][
			switch event/key [
				up left    [-1] 
				down right [ 1]
				page-up page-left    [steps: count-cells face dim -1  0 - steps] 
				page-down page-right [steps: count-cells face dim  1      steps]
				track      [step: event/picked - scroller/:dim/position]
			]
		]
		
		calc-step-size: function [dim step][
			dir: negate step / s: absolute step
			pos: either dir < 0 [current/:dim][current/:dim + 1]
			sz: 0
			repeat i s [
				sz: sz + get-size dim pos + i
			]
			sz * dir
		]

		; COPY / CUT / PASTE
		
		copy-selection: function [face /cut][
			clear head selection-data
			clear selection-figure
			clpbrd: copy ""
			parse face/selected [any [
				s: pair! '- pair! (
					mn: min s/1 s/3
					mx: max s/1 s/3
					append selection-figure fig: mx - mn + 1
					repeat row fig/y [
						repeat col fig/x [
							d: mn - 1 + as-pair col row
							d: as-pair col-index/(d/x) row-index/(d/y)
							if face/options/auto-index [d/x: d/x - 1]
							append/only selection-data out: 
								either all [face/options/auto-index d/x = 0][
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
					if face/options/auto-index [col: col - 1]
					append selection-data out: 
						either all [face/options/auto-index col = 0][
							s/1/y
						][
							data/:row/:col
						]
					repend clpbrd [mold out tab]
					if cut [data/:row/:col: copy ""]
					append selection-figure 1x1
				)
			]]
			remove back tail clpbrd
			write-clipboard clpbrd
			if cut [fill face]
		]
		
		paste-selection: function [face /transpose /extern selection-data][
			selection-data: head selection-data
			case [
				single? face/selected [
					start: anchor - 1 
					dim: pick [[y x] [x y]] transpose
					foreach fig selection-figure [
						repeat row fig/(dim/2) [
							repeat col fig/(dim/1) [
								pos: start + as-pair col row
								pos: as-pair col-index/(pos/x) row-index/(pos/y)
								if face/options/auto-index [pos/x: pos/x - 1]
								d: first selection-data
								if not pos/x = 0 [data/(pos/y)/(pos/x): d]
								selection-data: next selection-data
							]
						]
					]
				]
				true [
					copied-size: 0
					foreach fig selection-figures [
						copied-size: fig/x * fig/y + copied-size
					]
					selected-size: 0
					parse face/selected [any [s:
						pair! '- pair! (p: s/3 - s/1 + 1 selected-size: p/x * p/y + selected-size)
					|	pair! (selected-size: selected-size + 1)
					]]
					either copied-size <> selected-size [
						print "Warning! Sizes do not match."
					][
						parse face/selected [any [s:
							pair! '- pair! (
								
							)
						|	pair! (
								
							)
							;d: first selection-data
							;selection-data: next selection-data
						]]
					]
				]
			]
			fill face
		]

		; Standard
		
		on-resize: func [face][
			size: face/size - 17
			adjust-size face
			fill face
		]

		on-scroll: function [face event][
			if 'end <> key: event/key [
				dim: pick [y x] event/orientation = 'vertical
				steps: count-steps face event dim
				if steps [scroll face dim steps]
				show-marks face
			]
		]

		on-wheel: function [face event][;May-be switch shift and ctrl ?
			dim: pick [x y] event/shift?
			steps: to-integer -1 * event/picked * either event/ctrl? [grid/:dim][select [x 1 y 3] dim]
			scroll face dim steps
			show-marks face
		]

		on-down: func [face event][
			set-focus face
			on-border?: on-border face event/offset
			if not on-border? [
				hide-editor
				pos: get-draw-address face event
				case [
					event/shift? [mark-active/extend face pos]
					event/ctrl?  [mark-active/extra face pos]
					true [mark-active face pos]
				]
			]
		]
		
		on-unfocus: func [face][
			hide-editor
			unmark-active face
		]

		on-over: function [face event][;probe reduce [event/down? on-border?]
			if event/down? [
				either on-border? [
					adjust-border face event 'x
					adjust-border face event 'y
					fill face
					show-marks face
				][;probe reduce [event/offset/x  size/x event/offset/x > size/x]
					case [
						any [
							all [event/offset/y > size/y           0 < step: scroll face 'y  1]
							all [event/offset/y <= freeze-point/y  0 > step: scroll face 'y -1]
						][
							either '- = first s: skip tail face/selected -2 [
								s/2/y: s/2/y + step
							][
								e: s/1 
								e/y: e/y + step
								repend face/selected ['- e]
							]
							show-marks face
						]
						any [
							all [event/offset/x >= size/x          0 < step: scroll face 'x  1] 
							all [event/offset/x <= freeze-point/x  0 > step: scroll face 'x -1]
						][
							either '- = first s: skip tail face/selected -2 [
								s/2/x: s/2/x + step
							][
								e: s/1 
								e/x: e/x + step
								repend face/selected ['- e]
							] 
							show-marks face
						]
						true [
							if attempt [adr: get-draw-address face event] [
								if all [adr <> pos] [
									mark-active/extend face adr
								]
							]
						]
					]
				]
			]
		]

		on-up: function [face event][
			if on-border? [
				set-grid-offset face
				set-last-page
			]
		]

		on-dbl-click: function [face event /local e][
			either tbl-editor [
				if tbl-editor/visible? [
					update-data tbl-editor   ;Make sure field is updated according to correct type
					face/draw: face/draw     ;Update draw in case we edited a field and didn't enter
				]
			][
				make-editor face
			]
			;tbl-editor/extra/table: face
			cell: get-draw-address face event                     ;Draw-cell address
			show-editor face event cell
		]
		
		on-key-down: func [face event /local key step pos1 pos2 cell szx ofs][
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
				either dim: case [ ; Active mark on edge
					any [
						all [key = 'down    frozen/y + grid/y = pos/y]
						all [key = 'up      frozen/y + 1    = pos/y]
						all [find [page-up page-down] key  pos/y > frozen/y]
					][
						df: scroll face 'y step/y
						switch key [
							page-up   [if step/y < step/y: df [pos/y: pos/y - grid/y - step/y]]
							page-down [if step/y > step/y: df [pos/y: pos/y + grid/y - step/y]]
						]
						'y
					]
					any [
						all [key = 'right frozen/x + grid/x = pos/x current/x < (total/x - last-page/x)]
						all [key = 'left  frozen/x + 1    = pos/x] 
						all [key = 'right ofs: get-draw-offset face pos + step ofs/2/x > size/x] 
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
				][ ;Active mark in center ;probe reduce [active step active + step]
					case [
						all [key = 'down  pos/y = frozen/y][scroll face 'y top/y - current/y]
						all [key = 'right pos/x = frozen/x][scroll face 'x top/x - current/x]
						;all [key = 'up pos/y > grid/y][probe "hi"]
						all [key = 'page-down pos/y <= frozen/y][
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
			][
				switch key [
					#"^M" [
						unless tbl-editor [make-editor face]
						show-editor face none pos
					]
				]
			]
		]
		
		on-created: func [face event][
			make-scroller face
			set-data face face/data
			init face
		]
		
		on-sort: func [face event /loaded /down /local col c fro idx][
			recycle/off
			col: get-col-number face event
			if down [col: negate col]
			either all [face/options/auto-index  1 = absolute col  indexes/:col][
				;row-index: indexes/:col
				append clear row-index default-row-index
				if down [reverse row-index]
			][
				either indexes/:col [clear indexes/:col][indexes/:col: make block! total/y]
				;either indexes/:col [
				;	append clear row-index indexes/:col
				;][
					;indexes/:col: make block! total/y
					c: absolute col
					if face/options/auto-index [c: c - 1]
					idx: at row-index top/y + 1
					sort/compare idx function [a b][;row-index
						attempt [case [
							all [loaded down][(load data/:a/:c) >  (load data/:b/:c)]
							loaded           [(load data/:a/:c) <= (load data/:b/:c)]
							down             [data/:a/:c >  data/:b/:c]
							true             [data/:a/:c <= data/:b/:c]
						]]
					]
					append indexes/:col row-index
				;]
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
		
		on-menu: function [face event][ ;current-row-index  rows cols
			switch event/picked [
				edit-cell     [on-dbl-click face event]
				freeze-cell   [freeze face event 'y freeze face event 'x]
				unfreeze-cell [unfreeze face 'y unfreeze face 'x]
			
				freeze-row    [freeze face event 'y]
				unfreeze-row  [unfreeze face 'y]
				freeze-col    [freeze face event 'x]
				unfreeze-col  [unfreeze face 'x]
				
				default-height [set-default-height face event]
				default-width  [set-default-width  face event]
				full-height    [set-full-height    face event]
				
				sort-up          [on-sort face event]
				sort-down        [on-sort/down face event]
				sort-loaded-up   [on-sort/loaded face event]
				sort-loaded-down [on-sort/loaded/down face event]
				
				filter [
					if code: ask-code [
						code: load code
						col: get-col-number face event
						filter face col code
					]
				]
				unfilter [
					append clear row-index default-row-index
					adjust-scroller face
					fill face
				]
				
				edit-column [edit-column face event]
				
				copy-selection  [copy-selection face]
				cut-selection   [copy-selection/cut face]
				paste-selection [paste-selection face]
				transpose       [paste-selection/transpose face]
				
				integer! float! percent! string! block! date! time! [
					col: get-col-number face event
					if not all [auto: face/options/auto-index  col = 1][
						if auto [col: col - 1]
						type: reduce event/picked
						forall data [if not find frozen-rows index? data [data/1/:col: to type data/1/:col]]
					]
				]
			]
		]
	]
]
