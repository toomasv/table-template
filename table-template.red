Red []
;#include %../utils/leak-check.red
#include %CSV.red
#include %re.red
~: make op! func [a b][re a b]
table-ctx: #include %table-ctx.red
tbl: copy/deep [
	type: 'base 
	size: 317x217 
	color: silver
	flags: [scrollable all-over]
	;options: [cursor: 'arrow] ;auto-index: #[true]]
	table: none
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
			"Hide"           hide-row
			"Insert"         insert-row
			"Append"         append-row
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
			"Hide"          hide-col
			;"Show"
			"Insert"        insert-col
			"Append"        append-col
			"Edit ..."      edit-column
			"Type"   [
				"integer!" integer! 
				"float!"   float! 
				"percent!" percent! 
				"string!"  string! 
				"block!"   block! 
				"date!"    date! 
				"time!"    time!
				"image!"   image!
				"draw"     draw
				"do"       do
			]
		]
		"Selection" [
			"Copy"      copy-selection
			"Cut"       cut-selection
			"Paste"     paste-selection
			"Transpose" transpose
			"Unhide"    [
				"All"    unhide-all
				"Row"    unhide-row
				"Column" unhide-col
			]
		]
	]
	actors: [
		; STANDARD

		on-scroll: function [face [object!] event [event!]][
			if 'end <> key: event/key [
				dim: pick [y x] event/orientation = 'vertical
				steps: table-ctx/count-steps face event dim
				if steps [table-ctx/scroll face dim steps]
				table-ctx/show-marks face
			]
		]

		on-wheel: function [face [object!] event [event!]][;May-be switch shift and ctrl ?
			dim: pick [x y] event/shift?
			steps: to-integer -1 * event/picked * either event/ctrl? [face/table/grid/:dim][select [x 1 y 3] dim]
			table-ctx/scroll face dim steps
			table-ctx/show-marks face
		]

		on-down: func [face [object!] event [event!]][
			set-focus face
			face/table/on-border?: table-ctx/on-border face event/offset
			if not face/table/on-border? [
				table-ctx/hide-editor
				face/table/pos: table-ctx/get-draw-address face event
				case [
					event/shift? [table-ctx/mark-active/extend face face/table/pos]
					event/ctrl?  [table-ctx/mark-active/extra face face/table/pos]
					true         [table-ctx/mark-active face face/table/pos]
				]
			]
		]
		
		on-unfocus: func [face [object!] event [event!]][
			table-ctx/hide-editor
			table-ctx/unmark-active face
		]

		on-over: func [face [object!] event [event!]][table-ctx/do-over face event]

		on-up: func [face [object!] event [event!]][
			if face/table/on-border? [
				table-ctx/set-grid-offset face
				table-ctx/set-last-page face
			]
		]

		on-dbl-click: function [face [object!] event [event!]][table-ctx/use-editor face event]
		
		on-key-down: func [face [object!] event [event!]][table-ctx/hot-keys face event]
		
		on-created: func [face [object!]][
			face/table: object copy/deep [
				scroller: 
				data: ;loaded:  
				indexes: filtered: 
				default-row-index: row-index: 
				default-col-index: col-index: 
				sizes: full-height-col:
				on-border?: 
				marks: anchor: active: pos:
				extra?: extend?: none
				
				total: size: 0x0
				frozen: freeze-point: 0x0
				current: top: 0x0
				grid: grid-size: grid-offset: 0x0
				last-page: 0x0
				box: 100x25
				;tolerance: 20x5
				
				frozen-cols: make block! 20
				frozen-rows: make block! 20
				;draw-block:  make block! 1000
				;filter-cmd:  make block! 10
				
				frozen-nums: make map! 2
				frozen-nums/x: frozen-cols
				frozen-nums/y: frozen-rows
				
				index: make map! 2
				col-types: make map! 5
			]

			table-ctx/make-scroller face
			table-ctx/set-data face face/data
			table-ctx/init face
		]
		
		on-menu: function [face [object!] event [event!]][table-ctx/do-menu face event]
	]
]
;style/init 'table copy/deep tbl copy/deep [
;]
style 'table tbl
