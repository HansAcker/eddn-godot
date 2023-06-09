class_name StarClasses


## Colors and sprites for different star classes


const colors := {
	&"default" : Color8(0xff, 0xd3, 0x8a), ## default color

	## http://www.vendian.org/mncharity/dir3/starcolor/
	&"K": Color8(0xff, 0xd2, 0xa1),
	&"G": Color8(0xff, 0xf4, 0xea),
	&"B": Color8(0xaa, 0xbf, 0xff),
	&"F": Color8(0xf8, 0xf7, 0xef),
	&"O": Color8(0x9b, 0xb0, 0xff),
	&"A": Color8(0xca, 0xd7, 0xff),
	&"M": Color8(0xff, 0xcc, 0x6f),

	## TODO: arbitrary-ish values. review colors.
	&"A_BlueWhiteSuperGiant": Color8(0xe1, 0xe7, 0xff),
	&"B_BlueWhiteSuperGiant": Color8(0xac, 0xc0, 0xff),
	&"F_WhiteSuperGiant": Color8(0xfc, 0xf8, 0xfa),
	&"G_WhiteSuperGiant": Color8(0xff, 0xf1, 0xe7),
	&"K_OrangeGiant": Color8(0xff, 0xcf, 0x95),
	&"M_RedSuperGiant": Color8(0xff, 0xcd, 0x90),
	&"M_RedGiant": Color8(0xff, 0xc3, 0x7c),

	&"TTS": Color8(0xff, 0xd1, 0x9a),
	&"WN": Color8(0xc4, 0xc4, 0xff),
	&"WC": Color8(0xe5, 0xcb, 0xff),
	&"C" : Color8(0xff, 0x9e, 0x40),
	&"DC": Color8(0xc4, 0xd8, 0xff),
	&"DQ": Color8(0xcb, 0xd4, 0xff),

	## Neutron stars are orange, apparently. Not here.
#	&"N": Color8(0xff, 0xa7, 0x36),
	&"N": Color8(0x9b, 0xb2, 0xff),

	## TODO: totally unchecked colors. maybe too much green.
	&"AeBe": Color8(0xff, 0xcd, 0x90),
	&"CJ" : Color8(0xff, 0x9a, 0x38),
	&"CN" : Color8(0xff, 0x98, 0x36),
	&"D": Color8(0x7c, 0xa4, 0xff),
	&"DA": Color8(0x7c, 0xa4, 0xff),
	&"DAB": Color8(0x7c, 0xa4, 0xff),
	&"DAV": Color8(0x7c, 0xa4, 0xff),
	&"DAZ": Color8(0x7c, 0xa4, 0xff),
	&"DB": Color8(0x7c, 0xa4, 0xff),
	&"DBV": Color8(0x7c, 0xa4, 0xff),
	&"DBZ": Color8(0x7c, 0xa4, 0xff),
	&"DCV": Color8(0x7c, 0xa4, 0xff),

#	&"L": Color8(0xd9, 0x45, 0x00),
	&"L": Color8(0xd9, 0x62, 0x2b),
	&"H": Color8(0xff, 0xd3, 0x8a),
	&"MS": Color8(0xff, 0xd3, 0x8a),
	&"S": Color8(0xff, 0xd3, 0x8a),
	&"T": Color8(0xbd, 0x6d, 0x00),
	&"W": Color8(0xc4, 0xc4, 0xff),
	&"WNC": Color8(0xd3, 0xc8, 0xff),
	&"WO": Color8(0xc4, 0xc4, 0xff),
	&"Y": Color8(0xbd, 0x6d, 0x00),
	&"SupermassiveBlackHole": Color8(0xdd, 0xdd, 0xdd),
}


## TODO: use multiple star classes
const sprites := {
	&"default": preload("res://stars/star_class_generic.tscn"),
}
