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
#	&"N": Color8(0xff, 0x9d, 0x00),

	## TODO: arbitrary-ish values. review colors.
	&"A_BlueWhiteSuperGiant": Color8(0xca, 0xd7, 0xff),
	&"B_BlueWhiteSuperGiant": Color8(0xaa, 0xbf, 0xff),
	&"K_OrangeGiant": Color8(0xff, 0xd2, 0xa1),
	&"M_RedGiant": Color8(0xff, 0xcc, 0x6f),
	&"M_RedSuperGiant": Color8(0xff, 0xcc, 0x6f),
	&"MS": Color8(0xff, 0xcc, 0x6f),
	&"AeBe": Color8(0xb3, 0xc5, 0xff),
	&"C" : Color8(0xff, 0xd3, 0x8a),
	&"N": Color8(0x9b, 0xb2, 0xff),
	&"D": Color8(0xb3, 0xc5, 0xff),
	&"DA": Color8(0xb3, 0xc5, 0xff),
	&"DB": Color8(0xb3, 0xc5, 0xff),
	&"DBV": Color8(0xb3, 0xc5, 0xff),
	&"DAB": Color8(0xb3, 0xc5, 0xff),
	&"DAV": Color8(0xb3, 0xc5, 0xff),
	&"DAZ": Color8(0xb3, 0xc5, 0xff),
	&"DBZ": Color8(0xb3, 0xc5, 0xff),
	&"DC": Color8(0xb3, 0xc5, 0xff),
	&"DCV": Color8(0xb3, 0xc5, 0xff),
	&"DQ": Color8(0xb3, 0xc5, 0xff),
	&"WO": Color8(0xb3, 0xc5, 0xff),
	&"WN": Color8(0xb3, 0xc5, 0xff),
	&"WNC": Color8(0xb3, 0xc5, 0xff),
	&"H": Color8(0xca, 0xd7, 0xff),
	&"L": Color8(0xaf, 0x73, 0x42),
	&"T": Color8(0xaf, 0x73, 0x42),
	&"Y": Color8(0xaf, 0x73, 0x42),
	&"TTS": Color8(0xaf, 0x73, 0x42),
	&"S": Color8(0xff, 0xcc, 0x6f),
	&"W": Color8(0xff, 0xcc, 0x6f),
	&"SupermassiveBlackHole": Color8(0xdd, 0xdd, 0xdd),
}


## TODO: use multiple star classes
const sprites := {
	&"default": preload("res://Stars/StarClass_Generic.tscn"),
}
