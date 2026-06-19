arrow:
	defb %00000000
	defb %00001000
	defb %00000100
	defb %00111110
	defb %00000100
	defb %00001000
	defb %00000000
	defb %00000000
ellipsis:
	defb %00000000
	defb %00001000
	defb %00011100
	defb %00001000
	defb %00000000
	defb %00011100
	defb %00000000
	defb %00000000
rainbowform:
	defb %11111111
	defb %11111110
	defb %11111100
	defb %11111000
	defb %11110000
	defb %11100000
	defb %11000000
	defb %10000000

	
	; ASM data file from a ZX-Paintbrush picture with 24 x 32 pixels (= 3 x 4 characters)
	
	; block based output of pixel data - each block contains 8 x 8 pixels
	
	; blocks at pixel positionn (y=0):
	
	defb %00000000
	defb %00000000
	defb %00000011
	defb %00000110
	defb %00001100
	defb %00011000
	defb %00111000
	defb %00110000
	
	defb %00010000
	defb %11111100
	defb %10000011
	defb %00000001
	defb %00000000
	defb %00000000
	defb %01001000
	defb %01001000
	
	defb %00000000
	defb %00000000
	defb %11000000
	defb %00110000
	defb %11001100
	defb %10110110
	defb %01101110
	defb %00110110
	
	; blocks at pixel positionn (y=8):
	
	defb %01110000
	defb %01100000
	defb %01111111
	defb %00001111
	defb %00000000
	defb %00000011
	defb %00011101
	defb %00110111
	defb %00000000
	defb %01111000
	defb %11111111
	defb %11111111
	defb %11111100
	defb %10000011
	defb %00000001
	defb %00000000
	defb %00111010
	defb %00011101
	defb %11111111
	defb %11111101
	defb %00001011
	defb %00010111
	defb %11101010
	defb %11110110
	
	; blocks at pixel positionn (y=16):
	
	defb %01011010
	defb %11101110
	defb %10101100
	defb %10111000
	defb %11010000
	defb %11110011
	defb %10111111
	defb %10100111
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %11111111
	defb %11111111
	defb %10101011
	defb %11001100
	defb %01111000
	defb %01110000
	defb %00111000
	defb %00011000
	defb %01011000
	defb %11110000
	defb %10000000
	
	; blocks at pixel positionn (y=24):
	
	defb %11100100
	defb %11110111
	defb %11100100
	defb %00001111
	defb %00011100
	defb %00111010
	defb %01110100
	defb %01111111
	defb %01101000
	defb %11001111
	defb %01000100
	defb %11000111
	defb %11101100
	defb %11111000
	defb %01111000
	defb %11111111
	defb %10000000
	defb %10000000
	defb %10000000
	defb %11000000
	defb %01100000
	defb %01110000
	defb %10111000
	defb %11111000