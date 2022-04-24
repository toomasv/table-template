Red []
object [
	tbl-editor: none
	selection-data: make block! 10000
	selection-figure: make block! 10

	; SETTING
	
	set-border: function [face [object!] ofs [pair!] dim [word!]][
		tb: face/table
		frozen-nums: tb/frozen-nums
		index: tb/index
		ofs: ofs/:dim
		cum: 0     ;accumulator
		repeat i tb/frozen/:dim [
			cum: cum + get-size face dim frozen-nums/:dim/:i
			if 2 >= absolute cum - ofs [return i]
		]
		cur: tb/current/:dim
		fro: tb/frozen/:dim
		repeat i tb/grid/:dim [
			run: cur + i
			cum: cum + get-size face dim index/:dim/:run
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
		tb: face/table
		index: tb/index
		foreach dim [x y][
			cur: tb/current/:dim
			sz: 0
			repeat i tb/total/:dim - cur [
				j: cur + i
				sz: sz + get-size face dim index/:dim/:j
				if sz >= tb/grid-size/:dim [
					tb/grid-offset/:dim: sz - tb/grid-size/:dim 
					break
				]
			]
			tb/grid/:dim: i
		]
	]
	
	set-freeze-point: function [face [object!]][
		tb: face/table
		fro: tb/frozen
		if fro/y > 0 [fro/y: face/draw/(fro/y)/1/7/y]
		if fro/x > 0 [fro/x: face/draw/1/(fro/x)/7/x]
		tb/grid-size: tb/size - fro
		tb/freeze-point: fro
	]
	
	set-last-page: function [face [object!]][
		tb: face/table
		index: tb/index
		foreach dim [x y][
			t: tb/total/:dim
			j: sz: 0
			while [
				all [
					r: index/:dim/(t - j)
					sz: sz + s: get-size face dim r
					sz <= tb/grid-size/:dim
				]
			][j: j + 1]
			tb/last-page/:dim: j
		]
	]
	
	set-grid-offset: function [face [object!]][
		tb: face/table
		end: get-draw-offset/end face tb/frozen + tb/grid
		tb/grid-offset: end - tb/size
	]
	
	set-default-height: function [face [object!] event [event!]][
		tb: face/table
		dr: get-draw-row face event
		r:  get-data-row face dr
		if sz: tb/sizes/y/:r [
			remove/key tb/sizes/y r
			if dr <= tb/frozen/y [
				df: tb/box/y - sz
				tb/freeze-point/y: tb/freeze-point/y + df
			]
			fill face
			show-marks face
		]
	]
	
	set-default-width: function [face [object!] event [event!]][
		tb: face/table
		dc: get-draw-col face event
		c:  get-data-col face dc
		if sz: tb/sizes/x/:c [
			remove/key tb/sizes/x c
			if dc <= tb/frozen/x [
				df: tb/box/x - sz
				tb/freeze-point/x: tb/freeze-point/x + df
			]
			fill face
			show-marks face
		]
	]
	
	set-full-height: function [face [object!] event [event!]][
		tb: face/table
		tb/full-height-col: get-col-number face event
		fill face
		adjust-scroller face
		show-marks face
	]
	
	; ACCESSING
	
	get-draw-address: function [face [object!] event [event!]][
		if all [
			col: get-draw-col face event
			row: get-draw-row face event
			;row: round/ceiling/to event/offset/y / tb/box/y 1
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

	get-draw-col: function [face [object!] event [event!]][
		tb: face/table
		if block? row: face/draw/1 [
			ofs: event/offset/x
			repeat i length? row [
				case [
					tb/total/x < get-index face i 'x [break]
					row/:i/7/x > ofs [
						col: i 
						break
					]
				]
			]
			col
		]
	]
	
	get-draw-col: function [face [object!] event [event!]][
		tb: face/table
		if block? row: face/draw/1 [
			ofs: event/offset/x
			repeat i length? row [
				case [
					tb/total/x < get-index face i 'x [break]
					row/:i/7/x > ofs [
						col: i 
						break
					]
				]
			]
			col
		]
	]
	
	get-draw-row: function [face [object!] event [event!]][
		tb: face/table
		rows: face/draw 
		row: tb/total/y - tb/current/y 
		ofs: event/offset/y
		repeat i row [
			if rows/:i/1/7/y > ofs [row: i break]
		]
		row
	]
	
	get-col-number: function [face [object!] event [event!]][ 
		col: get-draw-col face event
		get-data-col face col
	]
	
	get-row-number: function [face [object!] event [event!]][
		row: get-draw-row face event
		get-data-row face row
	]

	get-data-address: function [face [object!] event [event! none!] /with cell [pair!]][
		if not cell [cell: get-draw-address face event]
		out: get-logic-address face cell
		if face/options/auto-index [out/x: out/x - 1]
		out
	]
	
	get-logic-address: func [face [object!] cell [pair!]][
		as-pair get-data-col face cell/x  get-data-row face cell/y
	]
	
	get-data-col: function [face [object!] col [integer!]][
		tb: face/table
		col: either col <= tb/frozen/x [
			tb/frozen-cols/:col
		][
			tb/col-index/(col - tb/frozen/x + tb/current/x)
		]
	]

	get-data-row: function [face [object!] row [integer!]][
		tb: face/table
		either row <= tb/frozen/y [
			tb/frozen-rows/:row
		][
			tb/row-index/(row - tb/frozen/y + tb/current/y)
		]
	]
	
	get-data-index: func [face [object!] num [integer!] dim [word!]][
		either dim = 'x [get-data-col face num][get-data-row face num]
	]

	get-index-address: func [face [object!] draw-cell [pair!]][
		as-pair get-index-col face draw-cell/x  get-index-row face draw-cell/y
	]
	
	get-index: func [face [object!] num [integer!] dim [word!]][
		either dim = 'x [get-index-col face num][get-index-row face num]
	]

	get-index-col: function [face [object!] draw-col [integer!]][
		tb: face/table
		either draw-col <= tb/frozen/x [
			index? find tb/col-index tb/frozen-cols/:draw-col
		][
			draw-col - tb/frozen/x + tb/current/x
		]
	]

	get-index-row: function [face [object!] draw-row [integer!]][
		tb: face/table
		either draw-row <= tb/frozen/y [
			index? find tb/row-index tb/frozen-rows/:draw-row
		][
			draw-row - tb/frozen/y + tb/current/y
		]
	]

	get-size: function [face [object!] dim [word!] idx [integer!]][
		tb: face/table
		any [tb/sizes/:dim/:idx tb/box/:dim]
	]
	
	get-color: func [face [object!] i [integer!] frozen? [logic!]][
		case [frozen? [silver] odd? i [white] 'else [snow]]
	]
	
	; INITIATION

	init-data: function [face [object!] spec [pair!]][
		tb: face/table
		tb/data: make block! spec/y 
		loop spec/y [
			row: make block! spec/x
			loop spec/x [append row copy ""]
			append/only tb/data row
		]
	]

	set-data: function [face [object!] spec [file! url! block! pair! none!]][
		tb: face/table
		switch type?/word spec [
			file!  [tb/data: load spec] ;load/as head clear tmp: find/last read/part file 5000 lf 'csv ;
			url!   [tb/data: either face/options/delimiter [
				load-csv/with read-thru spec face/options/delimiter
			][
				load-csv read-thru spec
			]]
			block! [tb/data: copy/deep spec]
			pair!  [
				tb/total: spec
				init-data face tb/total
			]
			none! [
				tb/total: face/size / tb/box
				init-data face tb/total
			]
		]
	]
	
	init-grid: function [face [object!]][
		tb: face/table
		tb/total/y: length? tb/data
		tb/total/x: length? first tb/data
		if face/options/sheet? [face/options/auto-index: face/options/auto-columns: yes]
		if face/options/auto-index   [tb/total/x: tb/total/x + 1] ; add auto-index
		if face/options/auto-columns [tb/total/y: tb/total/y + 1]
		tb/sizes: reduce [
			'x make map! copy []
			'y make map! copy []
		]
		tb/grid-size: tb/size: face/size - 17
		;set-grid face
		clear tb/frozen-rows
		clear tb/frozen-cols
	]

	init-indices: function [face [object!] force [logic!]][
		;Prepare indexes
		tb: face/table
		either all [tb/indexes not force] [
			;clear tb/indexes
			;clear tb/default-row-index
			;clear tb/default-col-index
			;clear tb/frozen-rows
			;clear tb/frozen-cols
		][
			tb/indexes: make map! tb/total/x                             ;Room for index for each column
			tb/filtered: 
				copy tb/row-index:                                    ;Active row-index
				copy tb/default-row-index: make block! tb/total/y        ;Room for row numbers
			tb/col-index: 
				copy tb/default-col-index: make block! tb/total/x        ;Active col-index and room for col numbers
		
			repeat i tb/total/y [append tb/default-row-index i]          ;Default is just simple sequence in initial order
			if face/options/auto-index [
				tb/indexes/1: copy tb/default-row-index                  ;Default is for first (auto-index) column
			]
			append clear tb/row-index tb/default-row-index               ;Set default as active index
			repeat i tb/total/x [append tb/default-col-index i] 
			append clear tb/col-index tb/default-col-index
			tb/index/x: tb/col-index
			tb/index/y: tb/row-index
		]

		set-last-page face
		adjust-scroller face
	]

	init-fill: function [face [object!]][
		;clear tb/draw-block
		tb: face/table
		draw-block: clear []
		repeat i tb/grid/y [
			row: make block! tb/grid/x 
			repeat j tb/grid/x  [
				s: (as-pair j i) - 1 * tb/box
				text: form either face/options/auto-index [
					either j = 1 [i][c: tb/col-index/(j - 1) tb/data/:i/:c]
				][
					tb/data/:i/(tb/col-index/:j)
				]
				;Cell structure
				cell: make block! 11    ;each column has the following 11 elements
				color: pick [white snow] odd? i
				repend cell [
					'line-width 1
					'fill-pen color
					'box s s + tb/box
					'clip s + 1 s + tb/box - 1 
					reduce [
						'text s + 4x2  text
					]
				]
				append/only row cell
			]
			;append/only tb/draw-block row
			append/only draw-block row
		]
		;face/draw: tb/draw-block
		face/draw: draw-block
		;Initialize marks
		tb/marks: insert tail face/draw [line-width 2.5 fill-pen 0.0.0.220]
		mark-active face 1x1
		set-grid-offset face
	]

	init: function [face [object!] /force][
		tb: face/table
		tb/frozen: tb/current: 0x0
		face/selected: copy []
		tb/scroller/x/position: tb/scroller/y/position: 1
		if not empty? tb/data [
			init-grid face
			init-indices face force
			init-fill face
		]
	]

	; FILLING

	fix-cell-outside: function [face [object!] cell [block!] dim [word!]][
		tb: face/table
		cell/6/:dim: cell/7/:dim: cell/9/:dim: cell/10/:dim: cell/11/2/:dim: tb/size/:dim
	]
	
	get-row-height: function [face [object!] data-y [integer!] frozen-y? [logic!]][
		tb: face/table
		either all [
			tb/full-height-col 
			not frozen-y?
			not tb/sizes/y/:data-y
		][
			d: tb/data/:data-y/(tb/full-height-col)
			n: 0 parse d [any [lf (n: n + 1) | skip]]
			tb/sizes/y/:data-y: n + 1 * 16 ;tb/box/y
		][
			get-size face 'y data-y
		]
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
		tb: face/table
		either index-x <= tb/total/x [
			data-x: tb/col-index/:index-x
			if auto: face/options/auto-index [data-x: data-x - 1]
			case [
				all [t: tb/col-types/:data-x t = 'draw][
					cell/11: compose/only [translate (cell/9) (tb/data/:data-y/:data-x)]
				]
				all [t: tb/col-types/:data-x t = 'do][
					cell/11/3: form either all [auto data-x = 0] [data-y][do tb/data/:data-y/:data-x]
					cell/11/2:  4x2  +  p0
				]
				true [
					cell/11/3: form either all [auto data-x = 0] [data-y][tb/data/:data-y/:data-x]
					cell/11/2:  4x2  +  p0
				]
			]
			cell/4: get-color face draw-y frozen?
			cell/9: (cell/6:  p0) + 1
			cell/10: (cell/7:  p1) - 1 
		][
			fix-cell-outside face cell 'x 
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
		tb: face/table
		data-x: tb/col-index/:index-x
		if auto: face/options/auto-index [data-x: data-x - 1]
		case [
			draw?: all [t: tb/col-types/:data-y t = 'draw][
				drawing: tb/data/:data-y/:data-x
			]
			all [t: tb/col-types/:data-y t = 'do][
				text: form do tb/data/:data-y/:data-x
			]
			true [
				text: form either all [auto data-x = 0] [data-y][tb/data/:data-y/:data-x]
			]
		]
		insert/only at row draw-x compose/only [
			line-width 1
			fill-pen (get-color face draw-y frozen?)
			box (p0) (p1)
			clip (p0 + 1) (p1 - 1) 
			(reduce case [
				draw? [['translate p0 + 1 drawing]]
				true [['text p0 + 4x2 text]]
			])
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
		tb: face/table
		sx: get-size face 'x tb/col-index/:index-x
		px1: px0 + sx
		p0: as-pair px0 py0
		p1: as-pair px1 py1
		either block? cell: row/:draw-x [
			fill-cell face cell data-y draw-y index-x frozen? p0 p1
		][
			if index-x <= tb/total/x [
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
		tb: face/table
		px0: tb/freeze-point/x
		grid-x: 0
		while [px0 < tb/size/x][
			grid-x: grid-x + 1
			index-x: tb/current/x + grid-x
			either index-x <= tb/total/x [
				px0: set-cell face row index-x data-y draw-y grid-x px0 py0 py1 frozen?
				tb/grid/x: grid-x
			][
				cell: row/:grid-x
				either all [block? cell cell/6/x < tb/size/x] [ 
					fix-cell-outside face cell 'x
				][break]
			]
		]
		cell: row/(grid-x + 1)
		if all [block? cell cell/6/x < tb/size/x] [ 
			fix-cell-outside face cell 'x
		]
	]
	
	fill: function [face [object!] /only dim [word!]][
		recycle/off
		system/view/auto-sync?: off
		tb: face/table
		
		py0: 0
		draw-y: 0
		index-y: 0
		while [all [py0 < tb/size/y index-y < tb/total/y]][
			draw-y: draw-y + 1
			frozen?: draw-y <= tb/frozen/y
			data-y: get-data-row face draw-y
			index-y: get-index-row face draw-y
			draw-row: face/draw/:draw-y
			unless block? draw-row [
				insert/only at face/draw draw-y draw-row: copy [] 
				tb/marks: next tb/marks
			]
			sy: get-row-height face data-y frozen?
			py1: py0 + sy
			
			px0: 0
			repeat draw-x tb/frozen/x [
				index-x: get-index-col face draw-x
				px0: set-cell face draw-row index-x data-y draw-y draw-x px0 py0 py1 true
			]
			draw-row: at draw-row tb/frozen/x + 1
			grid-y: draw-y - tb/frozen/y
			set-cells face draw-row data-y grid-y py0 py1 frozen?
			tb/grid/y: grid-y
			py0: py1
		]                                                                                                                                                     
		while [all [block? draw-row: face/draw/(draw-y: draw-y + 1) draw-row/1/6/y < tb/size/y]][
			foreach cell draw-row [fix-cell-outside face cell 'y]
		]
		tb/scroller/y/page-size: tb/grid/y
		tb/scroller/x/page-size: tb/grid/x
		
		show face
		system/view/auto-sync?: on
		recycle/on
	]

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
	
	make-editor: function [table [object!] /extern tbl-editor][
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
	
	use-editor: function [face [object!] event [event!]][
		either tbl-editor [
			if tbl-editor/visible? [
				update-data tbl-editor  ;Make sure field is updated according to correct type
				face/draw: face/draw     ;Update draw in case we edited a field and didn't enter
			]
		][
			make-editor face
		]
		;tbl-editor/extra/table: face
		cell: get-draw-address face event                     ;Draw-cell address
		show-editor face event cell
	]
	
	show-editor: function [face [object!] event [event! none!] cell [pair!]][
		tb: face/table
		addr: get-data-address/with face event cell
		ofs:  get-draw-offset face cell
		either not all [face/options/auto-index addr/x = 0] [ ;Don't edit autokeys
			tbl-editor/extra/table: face
			txt: form tb/data/(addr/y)/(addr/x);face/draw/(cell/y)/(cell/x)/11/3
			tbl-editor/extra/data: addr                       ;Register cell
			tbl-editor/extra/draw: cell
			fof: face/offset                                  ;Compensate offset for VID space
			edit fof + ofs/1 ofs/2 - ofs/1 txt
		][tbl-editor/visible?: no]
	]
	
	hide-editor: does [
		if all [tbl-editor tbl-editor/visible?] [tbl-editor/visible?: no]
	]
	
	update-data: function [face [object!]][
		tb: face/extra/table/table
		switch type?/word e: face/extra/data [
			pair! [
				type: type? tb/data/(e/y)/(e/x)
				tb/data/(e/y)/(e/x): to type tx: face/text
				face/extra/table/draw/(e/y)/(e/x)/11/3: tx
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

	edit-column: function [face [object!] event [event!]][
		tb: face/table
		if code: ask-code [
			code: load/all code 
			code: back insert next code '_
			col: get-col-number face event
			if not all [face/options/auto-index col = 0][
				foreach row at tb/data tb/top/y + 1 [
					change/only code row/:col
					row/:col: head do head code
				]
				fill face
			]
		]
	]
	
	set-col-type: function [face [object!] event [event!]][
		tb: face/table
		col: get-col-number face event
		data: tb/data
		if not all [auto: face/options/auto-index  col = 1][
			if auto [col: col - 1]
			type: reduce event/picked
			case [
				all [tb/col-types/:col = 'draw event/picked <> 'draw][
					tb/col-types/:col: event/picked
					col: get-draw-col face event
					system/view/auto-sync?: off
					foreach row face/draw [
						either block? row [
							if 'translate = first row/:col/11 [
								cell: row/:col/11
								cell/1: 'text 
								cell/2: cell/2 + 3x1
								cell/3:	form cell/3
							] 
						][break]
					]
					show face
					system/view/auto-sync?: on
					face/draw: face/draw
				]
				event/picked = 'string! [
					tb/col-types/:col: event/picked
					forall data [if not find tb/frozen-rows index? data [data/1/:col: mold data/1/:col]]
				]
				true [
					tb/col-types/:col: event/picked
					forall data [if not find tb/frozen-rows index? data [data/1/:col: to type data/1/:col]]
				]
			]
		]
	]
	
	draw-col: function [face [object!] event [event!]][
		tb: face/table
		col: get-col-number face event
		x:   get-draw-col face event
		data: tb/data
		if not all [auto: face/options/auto-index  col = 1][
			if auto [col: col - 1]
			tb/col-types/:col: 'draw
			repeat y tb/grid/y [
				y: tb/frozen/y + y
				row: get-data-row face y
				cell: face/draw/:y/:x
				cell/11: reduce ['translate cell/9 data/:row/:col]
			]
		]
	]
	
	do-col: function [face [object!] event [event!]][
		tb: face/table
		col: get-col-number face event
		x:   get-draw-col face event
		data: tb/data
		if not all [auto: face/options/auto-index  col = 1][
			if auto [col: col - 1]
			tb/col-types/:col: 'do
			repeat y tb/grid/y [
				y: tb/frozen/y + y
				row: get-data-row face y
				cell: face/draw/:y/:x
				cell/11/3: form do data/:row/:col
			]
		]
	]

	hide-row: function [face [object!] event [event!]][
		tb: face/table
		r: get-row-number face event
		tb/sizes/y/:r: 0
		fill face
		show-marks face
	]
	
	hide-col: function [face [object!] event [event!]][
		tb: face/table
		c: get-col-number face event
		tb/sizes/x/:c: 0
		fill face
		show-marks face
	]
	
	unhide: function [face [object!] event [event!] dim [word!]][
		tb: face/table
		either dim = 'all [
			
		][
			
			;find/tail tb/index/:dim
		]
	]
	
	show-row: function [face [object!] event [event!]][
		
	]
	
	show-col: function [face [object!] event [event!]][]
	
	insert-row: function [face [object!] event [event!]][
		tb: face/table
		dr: get-draw-row face event
		r: get-index-row face dr
		row: make block! tb/total/x
		loop tb/total/x [append row copy ""]
		append/only tb/data row
		tb/total/y: tb/total/y + 1
		insert/only at tb/row-index r tb/total/y
		set-last-page face
		adjust-scroller face
		fill face
		show-marks face
	]

	append-row: function [face [object!]][
		tb: face/table
		row: make block! tb/total/x
		loop tb/total/x [append row copy ""]
		append/only tb/data row
		tb/total/y: tb/total/y + 1
		append tb/row-index tb/total/y
		set-last-page face
		adjust-scroller face
		fill face
		show-marks face
	]

	insert-col: function [face [object!] event [event!]][
		tb: face/table
		dc: get-draw-col face event
		c: get-index-col face dc
		data: tb/data
		repeat i tb/total/y [append data/:i copy ""]
		tb/total/x: tb/total/x + 1
		insert/only at tb/col-index c tb/total/x
		set-last-page face
		adjust-scroller face
		fill face
		show-marks face
	]

	append-col: function [face [object!]][
		tb: face/table
		data: tb/data
		repeat i tb/total/y [append data/:i copy ""]
		tb/total/x: tb/total/x + 1
		append tb/col-index tb/total/x
		set-last-page face
		adjust-scroller face
		fill face
		show-marks face
	]

	; MARKS
	
	set-new-mark: function [face [object!] cell [pair!]][
		tb: face/table
		append face/selected tb/anchor: cell 
	]
	
	mark-active: function [face [object!] cell [pair!] /extend /extra][
		tb: face/table
		tb/pos: cell
		tb/active: get-index-address face cell
		either pair? last face/draw [
			case [
				extend [
					tb/extend?: true
					either '- = first skip tail face/selected -2 [
						change back tail face/selected tb/active
					][
						repend face/selected ['- tb/active]
					]
				]
				extra  [
					tb/extend?: false tb/extra?: true
					set-new-mark face tb/active
				]
				true   [
					tb/extra?: tb/extend?: false
					clear face/selected
					set-new-mark face tb/active 
				]
			]
		] [
			set-new-mark face tb/active
		] 
		show-marks face
	]
	
	unmark-active: function [face [object!]][
		tb: face/table
		if tb/active [
			clear tb/marks
			tb/extend?: tb/extra?: false
			tb/anchor: tb/active: tb/pos: none
			clear face/selected
		]
	]
	
	mark-address: function [face [object!] s [pair!] dim [word!]][
		tb: face/table
		case [
			s/:dim > tb/top/:dim [
				case [
					s/:dim <= tb/current/:dim [0]
					s/:dim > (tb/current/:dim + tb/grid/:dim) [-1]
					true [tb/frozen/:dim + s/:dim - tb/current/:dim]
				]
			]
			found: find tb/frozen-nums/:dim tb/index/:dim/(s/:dim) [index? found]
			
		]
	]

	mark-point: function [face [object!] a [pair!] /end][
		tb: face/table
		n: pick [7 6] end
		case [
			all [a/x > 0 a/y > 0][
				face/draw/(a/y)/(a/x)/:n
			]
			a/x > 0 [
				y: either a/y = 0 [tb/freeze-point/y][tb/size/y]
				as-pair face/draw/1/(a/x)/:n/x y
			]
			a/y > 0 [
				x: either a/x = 0 [tb/freeze-point/x][tb/size/x]
				as-pair x face/draw/(a/y)/1/:n/y
			]
			true [
				x: either a/x = 0 [tb/freeze-point/x][tb/size/x]
				y: either a/y = 0 [tb/freeze-point/y][tb/size/y]
				as-pair x y
			]
		]
	]

	show-marks: function [face [object!]][
		system/view/auto-sync?: off
		tb: face/table
		clear tb/marks
		parse face/selected [any [
		s: pair! '- pair! (
			a: min s/1 s/3
			b: max s/1 s/3
			r1: mark-address face a 'y
			c1: mark-address face a 'x
			r2: mark-address face b 'y
			c2: mark-address face b 'x
			a: as-pair c1 r1
			b: as-pair c2 r2
			p1: mark-point face a
			p2: mark-point/end face b
			repend tb/marks ['box p1 p2]
		)
		|  pair! (
			if all [
				r: mark-address face s/1 'y
				c: mark-address face s/1 'x
			][
				case [
					all [r > 0 c > 0][
						append tb/marks copy/part at face/draw/:r/:c 5 3
					]
					r > 0 [
						x: either c = 0 [tb/freeze-point/x][tb/size/x]
						p1: as-pair x face/draw/:r/1/6/y
						p2: as-pair x face/draw/:r/1/7/y
						repend tb/marks ['box p1 p2]
					]
					c > 0 [
						y: either r = 0 [tb/freeze-point/y][tb/size/y]
						p1: as-pair face/draw/1/:c/6/x y
						p2: as-pair face/draw/1/:c/7/x y
						repend tb/marks ['box p1 p2]
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

	filter: function [face [object!] col [integer!] crit [any-type!]][
		tb: face/table
		data: tb/data
		filtered: tb/filtered
		row-index: tb/row-index
		frozen-rows: tb/frozen-rows
		append clear filtered frozen-rows ;include frozen rows in result first
		c: col
		if auto: face/options/auto-index [c: c - 1];tb/col-index/(col - 1)
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
		set-last-page face
		adjust-scroller face
		unmark-active face
		fill face
	]

	freeze: function [face [object!] event [event!] dim [word!]][
		tb: face/table
		fro: tb/frozen
		cur: tb/current
		tb/frozen/:dim: either dim = 'x [
			get-draw-col face event
		][
			get-draw-row face event
		]
		fro/:dim: tb/frozen/:dim - fro/:dim
		tb/grid/:dim: tb/grid/:dim - fro/:dim
		set-freeze-point face 
		if fro/:dim > 0 [
			append tb/frozen-nums/:dim copy/part at tb/index/:dim cur/:dim + 1 fro/:dim
		]
		tb/current/:dim: cur/:dim + fro/:dim
		tb/top/:dim: tb/current/:dim ;- tb/frozen/:dim
		set-last-page face
		adjust-scroller/only face
		tb/scroller/:dim/position: tb/current/:dim + 1
		either dim = 'y [
			repeat i tb/frozen/y [
				repeat j tb/grid/x [
					c: j + tb/frozen/x 
					face/draw/:i/:c/4: 192.192.192
				]
			]
		][
			repeat i tb/grid/y [
				r: i + tb/frozen/y
				repeat j tb/frozen/:dim [
					face/draw/:r/:j/4: 192.192.192
				]
			]
		]
	]

	unfreeze: function [face [object!] dim [word!]][
		tb: face/table
		tb/top/:dim: tb/current/:dim: tb/frozen/:dim: 0
		tb/freeze-point/:dim: 0
		tb/grid-size/:dim: tb/size/:dim
		tb/scroller/:dim/position: 1 
		clear tb/frozen-nums/:dim
		set-grid face
		set-last-page face
		fill face
		show-marks face
		adjust-scroller face
	]

	adjust-size: function [face [object!]][
		tb: face/table
		tb/grid-size: tb/size - tb/freeze-point
		set-grid face
		set-last-page face
	]

	adjust-border: function [face [object!] event [event!] dim [word!]][
		tb: face/table
		if tb/on-border?/:dim > 0 [
			ofs0: either dim = 'x [
				face/draw/1/(tb/on-border?/x)/7/x            ;box's actual end
			][
				face/draw/(tb/on-border?/y)/1/7/y
			]
			ofs1: event/offset/:dim
			df:   ofs1 - ofs0
			num: get-index face tb/on-border?/:dim dim
			case [
				all [event/ctrl? tb/on-border?/:dim = 1] [
					clear tb/sizes/:dim
					tb/box/:dim: tb/box/:dim + df
					if tb/frozen/:dim > 0 [
						tb/freeze-point/:dim: tb/frozen/:dim * df + tb/freeze-point/:dim
						tb/grid-size/:dim: tb/size/:dim - tb/freeze-point/:dim
					]
				]
				event/ctrl? [
					sz: get-size face dim tb/index/:dim/:num
					i: num - 1
					repeat n tb/total/:dim - num + 1 [
						tb/sizes/:dim/(i + n): sz + df
					]
					if tb/on-border?/:dim <= tb/frozen/:dim [
						tb/freeze-point/:dim: tb/frozen/:dim - tb/on-border?/:dim + 1 * df + tb/freeze-point/:dim
						tb/grid-size/:dim: tb/size/:dim - tb/freeze-point/:dim
					]
				]
				true [
					sz: get-size face dim i: tb/index/:dim/:num
					tb/sizes/:dim/:i: sz + df
					if tb/on-border?/:dim <= tb/frozen/:dim [
						tb/freeze-point/:dim: tb/freeze-point/:dim + df
						tb/grid-size/:dim: tb/size/:dim - tb/freeze-point/:dim
					]
				]
			]
		]
	]

	; SCROLLING
	
	make-scroller: function [face [object!]][
		tb: face/table
		vscr: get-scroller face 'vertical
		hscr: get-scroller face 'horizontal
		tb/scroller: make map! 2
		tb/scroller/x: hscr
		tb/scroller/y: vscr
	]
	
	scroll: function [face [object!] dim [word!] steps [integer!]][
		tb: face/table
		if 0 <> step: set-scroller-pos face dim steps [
			dif: calc-step-size face dim step
			tb/current/:dim: tb/current/:dim + step
			hide-editor
			fill face
		]
		step
	]

	adjust-scroller: function [face [object!] /only][
		tb: face/table
		unless only [set-grid face]
		tb/scroller/y/max-size:  max 1 tb/total/y: length? tb/row-index 
		tb/scroller/y/page-size: min tb/grid/y tb/scroller/y/max-size
		tb/scroller/x/max-size:  max 1 tb/total/x: length? tb/col-index 
		tb/scroller/x/page-size: min tb/grid/x tb/scroller/x/max-size
	]

	set-scroller-pos: function [face [object!] dim [word!] steps [integer!]][
		tb: face/table
		pos0: tb/scroller/:dim/position
		min-pos: tb/top/:dim + 1
		max-pos: tb/scroller/:dim/max-size - tb/last-page/:dim + pick [2 1] tb/grid-offset/:dim > 0
		mid-pos: tb/scroller/:dim/position + steps
		pos1: tb/scroller/:dim/position: max min-pos min max-pos mid-pos
		pos1 - pos0
	]
	
	count-cells: function [face [object!] dim [word!] dir [integer!] /by-keys][
		tb: face/table
		index: tb/index
		case [
			dir > 0 [
				start: tb/current/:dim + tb/grid/:dim 
				gsize: 0 
				repeat count tb/total/:dim - start [
					start: start + 1
					bsize: get-size face dim index/:dim/:start
					gsize: gsize + bsize
					if tb/grid-size/:dim <= gsize [break]
				]
			]
			dir < 0 [
				start: tb/current/:dim
				gsize: count: 0 
				if start > 0 [
					until [
						count: count + 1
						gsize: gsize + get-size face dim index/:dim/:start
						any [tb/grid-size/:dim <= gsize 0 = start: start - 1]
					]
				]
			]
		]
		count
	]
	
	count-steps: function [face [object!] event [event!] dim [word!]][
		tb: face/table
		switch event/key [
			up left    [-1] 
			down right [ 1]
			page-up page-left    [steps: count-cells face dim -1  0 - steps] 
			page-down page-right [steps: count-cells face dim  1      steps]
			track      [step: event/picked - tb/scroller/:dim/position]
		]
	]
	
	calc-step-size: function [face [object!] dim [word!] step [integer!]][
		tb: face/table
		dir: negate step / s: absolute step
		pos: either dir < 0 [tb/current/:dim][tb/current/:dim + 1]
		sz: 0
		repeat i s [
			sz: sz + get-size face dim pos + i
		]
		sz * dir
	]

	; COPY / CUT / PASTE
	
	copy-selection: function [face [object!] /cut /extern selection-data selection-figure][
		tb: face/table
		data: tb/data
		row-index: tb/row-index
		col-index: tb/col-index
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
	
	paste-selection: function [face [object!] /transpose /extern selection-data selection-figure][
		tb: face/table
		data: tb/data
		row-index: tb/row-index
		col-index: tb/col-index
		selection-data: head selection-data
		case [
			single? face/selected [
				start: tb/anchor - 1 
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
				foreach fig selection-figure [
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

	; More helpers

	on-sort: function [face [object!] event [event!] /loaded /down][
		tb: face/table
		recycle/off
		data: tb/data
		indexes: tb/indexes
		col: get-col-number face event
		if down [col: negate col]
		either all [face/options/auto-index  1 = absolute col  indexes/:col][
			;row-index: indexes/:col
			append clear tb/row-index tb/default-row-index
			if down [reverse tb/row-index]
		][
			either indexes/:col [clear indexes/:col][indexes/:col: make block! tb/total/y]
			;either indexes/:col [
			;	append clear tb/row-index indexes/:col
			;][
				;indexes/:col: make block! tb/total/y
				c: absolute col
				if face/options/auto-index [c: c - 1]
				idx: at tb/row-index tb/top/y + 1
				sort/compare idx function [a b][;tb/row-index
					attempt [case [
						all [loaded down][(load data/:a/:c) >  (load data/:b/:c)]
						loaded           [(load data/:a/:c) <= (load data/:b/:c)]
						down             [data/:a/:c >  data/:b/:c]
						true             [data/:a/:c <= data/:b/:c]
					]]
				]
				append indexes/:col tb/row-index
			;]
		]
		set-last-page face
		tb/scroller/y/position: either 0 < fro: tb/frozen/y [
			if found: find tb/row-index tb/frozen-rows/:fro [
				tb/top/y: tb/current/y: index? found
				tb/current/y + 1
			]
		][
			tb/top/y: tb/current/y: 0
			1
		]
		fill face
		;recycle
		recycle/on
	]
	
	resize: function [face [object!]][
		tb: face/table
		tb/size: face/size - 17
		adjust-size face
		fill face
		show-marks face
	]
		
	hot-keys: function [face [object!] event [event!]][
		tb: face/table
		key: event/key
		step: switch key [
			down      [0x1]
			up        [0x-1]
			left      [-1x0]
			right     [1x0]
			page-up   [as-pair 0 negate tb/grid/y]
			page-down [as-pair 0 tb/grid/y]
			home      [as-pair negate tb/grid/x 0] ;TBD
			end       [as-pair tb/grid/x 0]        ;TBD
		]
		either all [tb/active step] [
			case [
				; Active mark beyond edge
				case/all [
					a: all [tb/active/y > (edge: tb/current/y + tb/grid/y)][
						ofs: tb/active/y + step/y - edge
						either ofs > 0 [
							df: scroll face 'y ofs 
							tb/pos/y: tb/frozen/y + tb/grid/y
						][
							tb/pos/y: tb/frozen/y + tb/grid/y + ofs
						]
						step/y: 0
						y: 'done
						false
					]
					b: all [tb/active/x > (edge: tb/current/x + tb/grid/x)][
						ofs: tb/active/x + step/x - edge
						either ofs > 0 [
							df: scroll face 'x ofs 
							tb/pos/x: tb/frozen/x + tb/grid/x
						][
							tb/pos/x: tb/frozen/x + tb/grid/x + ofs
						]
						step/x: 0
						x: 'done
						false
					]
					c: all [tb/active/y > tb/top/y tb/active/y <= tb/current/y y <> 'done][
						scroll face 'y tb/active/y - tb/current/y - 1 + step/y
						tb/pos/y: tb/frozen/y + 1
						step/y: 0
						y: 'done
						false
					]
					d: all [tb/active/x > tb/top/x tb/active/x <= tb/current/x x <> 'done][
						scroll face 'x tb/active/x - tb/current/x - 1 + step/x
						tb/pos/x: tb/frozen/x + 1
						step/x: 0
						x: 'done
						false
					]
					;false []
					;true [false]
				][false]
				; Active mark on edge
				dim: case [ 
					any [
						all [key = 'down    tb/frozen/y + tb/grid/y = tb/pos/y y <> 'done]
						all [key = 'up      tb/frozen/y + 1    = tb/pos/y y <> 'done]
						all [find [page-up page-down] key  tb/pos/y > tb/frozen/y y <> 'done]
					][
						df: scroll face 'y step/y
						switch key [
							page-up   [if step/y < step/y: df [tb/pos/y: tb/pos/y - tb/grid/y - step/y]]
							page-down [if step/y > step/y: df [tb/pos/y: tb/pos/y + tb/grid/y - step/y]]
						]
						'y
					]
					any [
						all [key = 'right tb/frozen/x + tb/grid/x = tb/pos/x tb/current/x < (tb/total/x - tb/last-page/x) x <> 'done]
						all [key = 'left  tb/frozen/x + 1    = tb/pos/x x <> 'done] 
						all [key = 'right ofs: get-draw-offset face tb/pos + step ofs/2/x > tb/size/x x <> 'done] 
					][
						df: scroll face 'x step/x
						step/x: df
						'x
					]
				][
					tb/pos: max 1x1 min tb/grid + tb/frozen tb/pos
					either df = 0 [
						if switch key [
							up        [tb/pos/y: max 1 tb/pos/y - 1]
							left      [tb/pos/x: max 1 tb/pos/x - 1]
							page-up   [tb/pos/y: tb/frozen/y + 1]
							page-down [tb/pos/y: tb/grid/y]
						][
							either event/shift? [
								mark-active/extend face tb/pos
							][	mark-active face tb/pos]
						]
					][
						if event/shift? [tb/extend?: true]
						either any [tb/extra? tb/extend?] [
							either '- = first s: skip tail face/selected -2 [
								s/2: s/2 + step
							][
								repend face/selected ['- s/1 + step]
							]  
							show-marks face
						][
							mark-active face tb/pos
						]
					]
				]
				;Active mark in center 
				true [ 
					case [
						all [key = 'down  tb/pos/y = tb/frozen/y y <> 'done][scroll face 'y tb/top/y - tb/current/y]
						all [key = 'right tb/pos/x = tb/frozen/x x <> 'done][scroll face 'x tb/top/x - tb/current/x]
						all [key = 'page-down tb/pos/y <= tb/frozen/y y <> 'done][
							scroll face 'y tb/top/y - tb/current/y 
							step/y: tb/frozen/y - tb/pos/y + tb/grid/y
						]
					]
					tb/pos: tb/pos + step
					tb/pos: max 1x1 min tb/grid + tb/frozen tb/pos
					either event/shift? [
						mark-active/extend face tb/pos
					][	mark-active face tb/pos]
				]
			]
		][
			switch key [
				#"^M" [
					unless tbl-editor [make-editor face]
					show-editor face none tb/pos
				]
			]
		]
	]
	
	do-menu: function [face [object!] event [event!]][
		tb: face/table
		switch event/picked [
			edit-cell     [tb/actors/on-dbl-click face event]
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
				append clear tb/row-index tb/default-row-index
				adjust-scroller face
				fill face
			]
			
			hide-row    [hide-row   face event]
			insert-row  [insert-row face event]
			append-row  [append-row face]
			
			hide-col    [hide-col   face event]
			insert-col  [insert-col face event]
			append-col  [append-col face]
			
			edit-column [edit-column face event]
			
			copy-selection  [copy-selection face]
			cut-selection   [copy-selection/cut face]
			paste-selection [paste-selection face]
			transpose       [paste-selection/transpose face]
			
			unhide-all      [unhide face event 'all]
			unhide-row      [unhide face event 'y]
			unhide-column   [unhide face event 'x]
			
			draw            [draw-col face event]
			do              [do-col   face event]
			integer! float! percent! string! block! 
			date! time!     [set-col-type face event]
		]
	]
	
	scroll-on-border: function [face [object!] event [event!] s [block!] dim [word!]][
		tb: face/table
		if any [
			all [
				event/offset/:dim > tb/size/:dim
				0 < step: scroll face dim  1
			]
			all [
				s/1/:dim > tb/frozen/:dim
				event/offset/:dim <= tb/freeze-point/:dim
				0 > step: scroll face dim -1
			]
			all [
				s/1/:dim = tb/frozen/:dim
				event/offset/:dim >= tb/freeze-point/:dim
				0 > scroll face dim tb/top/:dim - tb/current/:dim
				step: 1
			]
		][step]
	]
	
	adjust-selection: function [face [object!] step [integer!] s [block!] dim [word!]][
		tb: face/table
		tb/active/:dim: tb/active/:dim + step
		either '- = s/-1 [
			s/1/:dim: s/1/:dim + step
		][
			e: s/1 
			e/:dim: e/:dim + step
			repend face/selected ['- e]
		]
		show-marks face
	]
	
	do-over: function [face [object!] event [event!]][
		tb: face/table
		if event/down? [
			either tb/on-border? [
				adjust-border face event 'x
				adjust-border face event 'y
				fill face
				show-marks face
			][
				s: find/last face/selected pair!
				case [
					step: scroll-on-border face event s 'y [
						adjust-selection face step s 'y
					]
					step: scroll-on-border face event s 'x [
						adjust-selection face step s 'x
					]
					true [
						if attempt [addr: get-draw-address face event] [
							if all [addr addr <> tb/pos] [
								mark-active/extend face addr
							]
						]
					]
				]
			]
		]
	]
]