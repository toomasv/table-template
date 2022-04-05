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
		data: loaded:       ;current: ; down:
		indexes: filtered: 
		default-row-index: row-index: ;current-row-index: 
		default-col-index: col-index: 
		sizes:
		on-border?: border-col: border-row:
		tbl-editor: 
		marks: last-mark: 
		active: active-offset: 
		anchor: anchor-offset: 
		extra?: extend?: none
		;by-key?: none ; latest: latest-offset:
		
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
		
		set-border: function [face ofs dim][
			ofs: ofs/:dim
			cum: 0     ;accumulator
			frozen-nums: get pick [frozen-cols frozen-rows] dim = 'x
			index: get pick [col-index row-index] dim = 'x
			forall frozen-nums [
				fro: frozen-nums/1
				cum: cum + get-size dim fro
				if 2 >= absolute cum - ofs [return index? frozen-nums]
			]
			cur: current/:dim
			fro: frozen/:dim
			repeat i grid/:dim [
				run: cur + i
				cum: cum + get-size dim index/:run
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
				index: get pick [row-index col-index]  dim = 'y
				sz: 0
				repeat i total/:dim - cur [
					j: cur + i
					sz: sz + get-size dim index/:j
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
			;probe reduce [frozen grid end: get-draw-offset/end face frozen + grid]
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
				;col-index/(
				col - frozen/x + current/x
				;)
			]
		]

		get-data-address: function [face event /with cell][
			if not cell [cell: get-draw-address face event]
			out: get-logic-address face cell
			if face/options/auto-index [out/x: out/x - 1]
			out
		]
		
		get-logic-address: func [face cell][
			as-pair get-data-col face cell/x  get-data-row face cell/y
		]

		get-data-col: function [face col][
			col: either col <= frozen/x [
				frozen-cols/:col
			][
				col-index/(col - frozen/x + current/x)
			]
		]

		get-data-row: function [face row][
			either row <= frozen/y [
				frozen-rows/:row
			][
				row-index/(row - frozen/y + current/y)
			]
		]

		set-last-page: function [][
			foreach dim [x y][
				t: total/:dim
				j: sz: 0
				index: get pick [row-index col-index] dim = 'y
				while [
					r: index/(t - j)
					sz: sz + s: get-size dim r
					sz <= grid-size/:dim
				][j: j + 1]
				last-page/:dim: j
			]
		]
		
		; INITIATION
		
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

		init-indices: func [face /force /local i][
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
					copy row-index:                                       ;Active row-index
					copy default-row-index: make block! total/y        ;Room for row numbers
				col-index: copy default-col-index: make block! total/x ;Active col-index and room for col numbers
			
				repeat i total/y [append default-row-index i]    ;Default is just simple sequence in initial order
				if face/options/auto-index [
					indexes/1: copy default-row-index               ;Default is for first (auto-index) column
				]
				append clear row-index default-row-index            ;Set default as active index
				
				repeat i total/x [append default-col-index i] 
				append clear col-index default-col-index
			]

			set-last-page
			adjust-scroller face
		]

		init-fill: function [face /extern marks grid-offset][
			clear draw-block
			repeat i grid/y [
				row: make block! grid/x 
				repeat j grid/x  [
					cell: make block! 11    ;each column has 11 elements, see below
					s: (as-pair j i) - 1 * box
					text: form either face/options/auto-index [
						either j = 1 [i][c: col-index/(j - 1) data/:i/:c]
					][
						data/:i/(col-index/:j)
					]
					;Cell structure
					repend cell [
						'line-width 1
						'fill-pen pick [white snow] odd? i
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
			marks: insert tail face/draw: draw-block [line-width 2.5 fill-pen 0.0.0.220]
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
		
		get-color: func [i frozen][
			case [frozen [silver] odd? i [white] 'else [snow]]
		]
		
		set-default-height: function [face event][
			dr: get-draw-row face event
			r:  get-data-row face dr
			if sz: sizes/y/:r [
				remove/key sizes/y r
				if dr <= frozen/y [
					df: box/y - sz
					freeze-point/y: freeze-point/y + df
				]
				fill face
				adjust-marks face
			]
		]
		
		set-default-width: function [face event][
			dc: get-draw-col face event
			c:  get-data-col face dc
			if sz: sizes/x/:c [
				remove/key sizes/x c
				if dc <= frozen/x [
					df: box/x - sz
					freeze-point/x: freeze-point/x + df
				]
				fill face
			]
		]
		
		; FILLING
		
		fill-cell: function [face cell r i x frozen /size p0 p1][
			either x <= total/x [
				cell/11/3: form either face/options/auto-index [
					either x = 1 [r][c: col-index/(x - 1) data/:r/:c]
				][
					data/:r/(col-index/:x)
				]
				cell/4: get-color i frozen
				if size [
					cell/9: (cell/6:  p0) + 1
					cell/10: (cell/7:  p1) - 1 
					cell/11/2:  4x2  +  p0
				]
			][
				fix-cell-outside cell 'x ;cell/11/2/x:  4 + cell/9/x: cell/6/x: self/size/x
			]
		]
		
		add-cell: func [face row r i c x p0 p1 frozen][
			if face/options/auto-index [x: x - 1]
			text: either all [face/options/auto-index x = 0][form r][form data/:r/:x]
			insert/only at row c compose/deep [
				line-width 1
				fill-pen (get-color i frozen)
				box (p0) (p1)
				clip (p0 + 1) (p1 - 1) 
				[
					text (p0 + 4x2)  (text)
				]
			]
		]

		set-cell: func [face row x r i c px0 py0 py1 frozen][
			sx: get-size 'x col-index/:x
			px1: px0 + sx
			p0: as-pair px0 py0
			p1: as-pair px1 py1
			either block? cell: row/:c [
				fill-cell/size face cell r i x frozen p0 p1
			][
				if x <= total/x [
					add-cell face row r i c x p0 p1 frozen
				]
			]
			px1
		]
		
		fix-cell-outside: func [cell dim][
			cell/11/2/:dim: cell/9/:dim: cell/10/:dim: cell/6/:dim: cell/7/:dim: size/:dim
		]
		
		set-cells: function [face row r i py0 py1 frozen][
			px0: freeze-point/x
			c: 0
			while [px0 < size/x][
				c: c + 1
				x: current/x + c
				either x <= total/x [
					px0: set-cell face row x r i c px0 py0 py1 frozen
					grid/x: c
				][
					cell: row/:c
					either all [block? cell cell/6/x < self/size/x] [ 
						fix-cell-outside cell 'x
					][break]
				]
			]
			cell: row/(c + 1)
			if all [block? cell cell/6/x < self/size/x] [ 
				fix-cell-outside cell 'x
			]
		]
		
		fill: function [face /only dim][
			recycle/off
			system/view/auto-sync?: off
			
			py0: 0
			i: 0
			while [all [py0 < size/y i < total/y]][
				i: i + 1
				frozen?: i <= frozen/y
				r: get-data-row face i
				row: face/draw/:i
				unless block? row [
					insert/only at face/draw i row: copy [] 
					self/marks: next marks
					self/last-mark: next last-mark
				]
				sy: get-size 'y r
				py1: py0 + sy
				px0: 0
				repeat c frozen/x [
					x: frozen-cols/:c
					px0: set-cell face row x r i c px0 py0 py1 true
				]
				row: at row frozen/x + 1
				j: i - frozen/y
				set-cells face row r j py0 py1 frozen?
				grid/y: j
				py0: py1
			]                                                                                                                                                     
			while [all [block? row: face/draw/(i: i + 1) row/1/6/y < size/y]][
				foreach cell row [fix-cell-outside cell 'y]
			]
			scroller/y/page-size: grid/y
			scroller/x/page-size: grid/x
			
			show face
			system/view/auto-sync?: on
			recycle/on
		]

		adjust-fill: function [face dim len][
			fro: frozen
			records: either dim = 'y [grid/y][fro/y + grid/y]
			columns: either dim = 'x [grid/x][fro/x + grid/x]
			repeat rec records [
				if dim = 'y [rec: fro/y + rec]
				row: face/draw/:rec
				repeat col columns [
					if dim = 'x [col: fro/x + col]
					cell: row/:col
					cell/6/:dim: cell/6/:dim + len 
					cell/7/:dim: cell/7/:dim + len
					either len > 0 [cell/9/:dim: cell/6/:dim + 1][
						pos: either dim = 'x [col][rec]
						if pos - fro/:dim > 1 [cell/9/:dim: cell/9/:dim + len + 1]
					]
					cell/10/:dim: cell/10/:dim + len - 1
					cell/11/2/:dim: cell/11/2/:dim + len
				]
			]
			grid-offset/:dim: len
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
				code: load code 
				code: back insert next code '_
				col: get-col-number face event
				if not all [face/options/auto-index col = 0][
					foreach row at data top/y + 1 [
						change code row/:col
						row/:col: do head code
					]
					fill face
				]
			]
		]
		; MARKS
		
		add-mark: func [face ofs][
			repend marks ['box ofs/1 ofs/2] 
			set-last-mark
		]
		
		set-anchor: func [face cell][
			anchor: cell
			anchor-offset: get-draw-offset face anchor
			get-logic-address face cell
		]

		move-anchor: function [dim step][
			if any [anchor/:dim > frozen/:dim anchor/:dim <= 0][
				anchor/:dim: anchor/:dim + step
				index: get pick [col-index row-index] dim = 'x
				cur: either step > 0 [current/:dim][current/:dim + 1]
				size: get-size dim index/:cur
				anchor-offset/1/:dim: anchor-offset/1/:dim + (size: step * size)
				anchor-offset/2/:dim: anchor-offset/2/:dim + size
			]
		]
		
		set-new-mark: func [face cell ofs][
			append face/selected set-anchor face cell
			add-mark face ofs
		]
		
		set-last-mark: does [
			last-mark: skip tail marks -2
		]
		
		extend-last-mark: does [;probe reduce [anchor-offset active-offset last-mark]
			last-mark/1: min anchor-offset/1 active-offset/1
			last-mark/2: max anchor-offset/2 active-offset/2
		]
		
		mark-active: func [face cell /extend /extra /local active-data][
			active-offset: get-draw-offset face cell
			active: cell
			active-data: get-logic-address face cell
			either pair? last face/draw [
				case [
					extend [
						extend?: true
						extend-last-mark
						either '- = first skip tail face/selected -2 [
							change back tail face/selected active-data
						][
							repend face/selected ['- active-data]
						]
					]
					extra  [
						extend?: false extra?: true
						set-new-mark face cell active-offset
					]
					true   [
						if extra? [
							clear skip marks 3 
							extra?: false 
							set-last-mark
						]
						extend?: false
						append clear face/selected set-anchor face cell
						change/part next marks active-offset 2
					]
				]
			] [set-new-mark face cell active-offset]
			;probe face/selected
		]
		
		unmark-active: func [face][
			if active [
				clear marks
				extra?: false
				active: none
				clear face/selected
			]
		]
		
		mark-address: function [s dim][
			fro: get pick [frozen-rows frozen-cols] dim = 'y
			idx: get pick [row-index   col-index]   dim = 'y
			case [
				found: find fro s/:dim [index? found]
				all [
					found: find idx s/:dim
					(i: index? found) > current/:dim
					i <= (current/:dim + grid/:dim)
				][
					frozen/:dim + i - current/:dim
				]
				all [i i <= current/:dim] [0]
				all [i i > (current/:dim + grid/:dim)] [-1]
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

		adjust-marks: function [face][
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
			clear filtered
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
							function? get/any w [
								forall row-index [
									row: first row-index
									case [ ;???
										w = 'parse [insert next crit row]
									]
								]
							]
						]
					]
					path! [
						
					]
					paren! [
						
					]
				][  ;Simple list
					either all [auto col = 1] [
						normalize-range crit  ;Use charset spec to select rows
						filtered: intersect row-index crit
					][
						
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
				either dim = 'y [
					index: row-index 
					block: frozen-rows
				][
					index: col-index 
					block: frozen-cols
				]
				append block copy/part at index cur/:dim + 1 fro/:dim
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
			;set pick [rows cols] dim = 'y to-integer face/size/:dim / box/:dim
			anti: select [x y x] dim
			top/:dim: current/:dim: 
			;fro: frozen/:dim
			
			frozen/:dim: 0
			freeze-point/:dim: 0
			grid-size/:dim: size/:dim
			block: either dim = 'y [frozen-rows][frozen-cols]
			scroller/:dim/position: 1 
			clear block
			set-grid face
			set-last-page
			fill face
			adjust-marks face
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
				num: either dim = 'x [
					index: col-index
					get-data-col face on-border?/x
				][
					index: row-index
					get-data-row face on-border?/y
				]
				sz: get-size dim i: index/:num
				sizes/:dim/:i: sz + df
				if num <= frozen/:dim [freeze-point/:dim: freeze-point/:dim + df]
				;probe reduce [active on-border?]
				if active/:dim = on-border?/:dim [active-offset/2/:dim: active-offset/2/:dim + df]
				if anchor/:dim = on-border?/:dim [anchor-offset/2/:dim: anchor-offset/2/:dim + df]
				parse marks [any [
				  p: pair! (
					case [
						4 >= absolute p/1/:dim - ofs1 [p/1/:dim: ofs1]
						ofs1 < p/1/:dim [p/1/:dim: p/1/:dim + df]
					]
				  ) 
				| skip
				]]
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
		
		scroll: function [face [object!] dim [word!] steps [integer!] /extern active][
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
			index: get pick [row-index col-index] dim = 'y
			case [
				dir > 0 [
					start: current/:dim + grid/:dim 
					gsize: 0 
					repeat count total/:dim - start [
						start: start + 1
						bsize: get-size dim index/:start
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
							gsize: gsize + get-size dim index/:start
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
							if face/options/auto-index [col: col - 1]
							d: mn - 1 + as-pair col row
							append/only selection-data out: either all [face/options/auto-index d/x = 0][d/y][data/(d/y)/(d/x)]
							repend clpbrd [mold out tab]
							if cut [data/(d/y)/(d/x): copy ""]
						]
						change back tail clpbrd lf
					]
				)
				|  pair! (
					row: s/1/y
					col: s/1/x
					if face/options/auto-index [col: col - 1]
					append selection-data out: either all [face/options/auto-index col = 0][s/1/y][data/:row/:col]
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
			start: -1 + get-logic-address face anchor
			if face/options/auto-index [start/x: start/x - 1]
			selection-data: head selection-data
			case [
				single? face/selected [
					dim: pick [[y x] [x y]] transpose
					foreach fig selection-figure [
						repeat row fig/(dim/2) [
							repeat col fig/(dim/1) [
								d: first selection-data
								data/(start/y + row)/(start/x + col): d
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
				if steps [
					step: scroll face dim steps
					active/:dim: active/:dim - step
					;anchor/:dim: anchor/:dim - step
					move-anchor dim 0 - step
					;probe reduce [step anchor active face/selected]
					adjust-marks face
				]
			]
		]

		on-wheel: function [face event][;May-be switch shift and ctrl ?
			dim: pick [x y] event/shift?
			steps: to-integer -1 * event/picked * either event/ctrl? [grid/:dim][select [x 1 y 3] dim]
			step: scroll face dim steps
			move-anchor dim 0 - step
			adjust-marks face
		]

		on-down: func [face event /local cell][
			set-focus face
			frozen-cols: head frozen-cols
			frozen-rows: head frozen-rows
			either on-border?: on-border face event/offset [
				if on-border?/x > 0 [
					border-col: either on-border?/x <= frozen/x [
						frozen-cols/(on-border?/x)
					][
						col-index/(on-border?/x - frozen/x + current/x)
					]
				]
				on-border?/y > 0 [
					border-row: either on-border?/y <= frozen/y [
						frozen-rows/(on-border?/y)
					][
						row-index/(on-border?/y - frozen/y + current/y)
					]
				]
			][
				hide-editor
				cell: get-draw-address face event
				case [
					event/shift? [mark-active/extend face cell]
					event/ctrl?  [mark-active/extra face cell]
					true [mark-active face cell]
				]
			]
		]
		
		on-unfocus: func [face][
			hide-editor
			unmark-active face
		]

		on-over: function [face event /extern active active-offset anchor anchor-offset][;probe reduce [event/down? on-border?]
			if event/down? [
				either on-border? [
					adjust-border face event 'x
					adjust-border face event 'y
					fill face
				][;probe reduce [event/offset/x  size/x event/offset/x > size/x]
					case [
						any [
							all [event/offset/y > size/y 0 < step: scroll face 'y  1]
							all [event/offset/y <= 0     0 > step: scroll face 'y -1]
						][
							move-anchor 'y 0 - step
							extend-last-mark
							either '- = first s: skip tail face/selected -2 [
								s/2/y: s/2/y + step
							][
								e: s/1 
								e/y: e/y + step
								repend face/selected ['- e]
							]
						]
						any [
							all [event/offset/x >= size/x   0 < step: scroll face 'x  1] 
							all [event/offset/x <= 0        0 > step: scroll face 'x -1]
						][
							move-anchor 'x 0 - step
							extend-last-mark
							either '- = first s: skip tail face/selected -2 [
								s/2/x: s/2/x + step
							][
								e: s/1 
								e/x: e/x + step
								repend face/selected ['- e]
							] 
						]
						true [
							if attempt [adr: get-draw-address face event] [
								if all [adr <> active] [
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
				comment [
					ofs0: face/draw/1/(on-border?/x)/6/x
					ofs1: face/draw/1/(on-border?/x)/7/x
					df: ofs1 - ofs0
					self/frozen-cols: head frozen-cols
					col: either on-border?/x <= frozen/x [
						frozen-cols/(on-border?/x)
					][
						on-border?/x - frozen/x + current/x
					]
				]
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
			]
			either all [active step] [
				;by-key?: true  ;?? 
				;probe reduce [key step ofs: get-draw-offset face active + step size ofs/2/x > size/x grid-offset/x]
				;probe reduce [key "stp" step "act" active "gr" grid "ofs" get-draw-offset face active + step "tot" total/x "lp" last-page/x "cur" current/x]
				either dim: case [
					any [
						all [key = 'down    frozen/y + grid/y = active/y]
						all [key = 'up      frozen/y + 1    = active/y]
						find [page-up page-down] key
					][
						if key = 'up [szy: get-size 'y current/y]
						df: scroll face 'y step/y
						switch key [
							down      [szy: get-size 'y current/y + 1]
							page-up   [if step/y < step/y: df [active/y: active/y - grid/y - step/y]]
							page-down [if step/y > step/y: df [active/y: active/y + grid/y - step/y]]
						]
						cell: box
						'y
					]
					any [
						all [key = 'right frozen/x + grid/x = active/x current/x < (total/x - last-page/x)]
						all [key = 'left  frozen/x + 1    = active/x] 
						all [key = 'right ofs: get-draw-offset face active + step ofs/2/x > size/x] 
					][
						if key = 'left  [szx: get-size 'x current/x]
						df: scroll face 'x step/x
						if key = 'right [szx: get-size 'x current/x + 1]
						step/x: df
						if szx [cell: as-pair szx 0]
						'x
					]
				][
					active: max 1x1 min grid + frozen active
					either df = 0 [
						if switch key [
							up        [active/y: max 1 active/y - 1]
							left      [active/x: max 1 active/x - 1]
							page-up   [active/y: frozen/y + 1]
							page-down [active/y: grid/y]
						][
							either event/shift? [
								mark-active/extend face active
							][	mark-active face active]
						]
					][
						if event/shift? [extend?: true]
						;probe reduce [pos1 pos2  pos2 - pos1  "step" step  step * absolute pos2 - pos1 "cell" cell step * cell extend?]
						;step: step * absolute pos2 - pos1
						either any [extra? extend?] [
							either '- = first s: skip tail face/selected -2 [
								s/2: s/2 + step
							][
								repend face/selected ['- s/1 + step]
							] 
							cell: step * cell
							anchor: anchor - step
							anchor-offset/1: anchor-offset/1 - cell
							anchor-offset/2: anchor-offset/2 - cell
							active-offset: get-draw-offset face active
							;probe reduce ["active" active "anchor" anchor "cell" cell]
							parse marks [any ['box s: 2 pair! (
								either 2 = length? s [
									s/1/:dim: min anchor-offset/1/:dim active-offset/1/:dim
									s/2/:dim: max anchor-offset/2/:dim active-offset/2/:dim
								][
									s/1: s/1 - cell
									s/2: s/2 - cell
								]
							)]]
						][
							;if all [key = 'right ofs: get-draw-offset face active + step ofs/2/x > size/x][
							;	scroll face 'x 1 
							;]
							mark-active face active
						]
					]
				][;probe reduce [active step active + step]
					active: active + step
					active: max 1x1 min grid + frozen active
					either find event/flags 'shift [
						mark-active/extend face active
					][	mark-active face active]
				]
			][
				switch key [
					#"^M" [
						unless tbl-editor [make-editor face]
						show-editor face none active
					]
				]
			]
		]
		
		on-created: func [face event /local spec row][
			make-scroller face
			if spec: face/data [
				switch type?/word spec [
					file!  [data: load spec] ;load/as head clear tmp: find/last read/part file 5000 lf 'csv ;
					block! [data: spec]
					pair!  [
						total: spec
						data: make block! spec/y 
						loop spec/y [
							row: make block! spec/x
							loop spec/x [append row copy ""]
							append/only data row
						]
					]
					none! []
				]
				init face
			]
		]
		
		on-sort: func [face event /loaded /down /local col c fro][
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
					sort/compare row-index function [a b][
						attempt [case [
							all [loaded down][(load data/:a/:c) > (load data/:b/:c)]
							down             [data/:a/:c > data/:b/:c]
							loaded           [(load data/:a/:c) <= (load data/:b/:c)]
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
