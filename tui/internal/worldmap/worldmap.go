// Package worldmap holds a 1-bit equirectangular land mask of the Earth
// (720x360, half a degree per pixel, from Natural Earth 110m land) and samples
// it by area, so coastlines stay clean at any terminal size.
//
// Regenerate the mask with tools/genmap.
package worldmap

import (
	_ "embed"
	"sync"
)

// Mask dimensions: half a degree per pixel.
const (
	W = 720
	H = 360
)

//go:embed land.bin
var raw []byte

var (
	once sync.Once
	sat  [(W + 1) * (H + 1)]uint32 // summed-area table of land pixels
)

func build() {
	for y := 0; y < H; y++ {
		row := uint32(0)
		for x := 0; x < W; x++ {
			if Land(x, y) {
				row++
			}
			sat[(y+1)*(W+1)+x+1] = sat[y*(W+1)+x+1] + row
		}
	}
}

// Land reports whether mask pixel (x, y) is land (x 0..719 from -180°, y 0..359
// from 90°N).
func Land(x, y int) bool {
	if x < 0 || y < 0 || x >= W || y >= H {
		return false
	}
	i := y*W + x
	if i/8 >= len(raw) {
		return false
	}
	return raw[i/8]&(1<<uint(7-i%8)) != 0
}

// Coverage is the share (0..1) of land in the box spanning lon0..lon1 and
// latTop..latBottom (degrees; latTop >= latBottom). Fractional pixel edges are
// weighted, so a tiny box returns the nearest pixel's value.
func Coverage(lon0, latTop, lon1, latBottom float64) float64 {
	once.Do(build)
	x0 := (lon0 + 180) * W / 360
	x1 := (lon1 + 180) * W / 360
	y0 := (90 - latTop) * H / 180
	y1 := (90 - latBottom) * H / 180
	// a box smaller than one pixel samples the pixel it sits in
	if x1-x0 < 1 {
		c := (x0 + x1) / 2
		x0, x1 = c-0.5, c+0.5
	}
	if y1-y0 < 1 {
		c := (y0 + y1) / 2
		y0, y1 = c-0.5, c+0.5
	}
	area := (x1 - x0) * (y1 - y0)
	if area <= 0 {
		return 0
	}
	return boxSum(x0, y0, x1, y1) / area
}

// boxSum returns the land area inside the box in pixel units.
func boxSum(x0, y0, x1, y1 float64) float64 {
	return integral(x1, y1) - integral(x0, y1) - integral(x1, y0) + integral(x0, y0)
}

// integral is the bilinear interpolation of the summed-area table at a
// fractional pixel corner (clamped to the map).
func integral(x, y float64) float64 {
	if x < 0 {
		x = 0
	}
	if y < 0 {
		y = 0
	}
	if x > W {
		x = W
	}
	if y > H {
		y = H
	}
	ix, iy := int(x), int(y)
	fx, fy := x-float64(ix), y-float64(iy)
	if ix >= W {
		ix, fx = W-1, 1
	}
	if iy >= H {
		iy, fy = H-1, 1
	}
	at := func(i, j int) float64 { return float64(sat[j*(W+1)+i]) }
	a := at(ix, iy)*(1-fx) + at(ix+1, iy)*fx
	b := at(ix, iy+1)*(1-fx) + at(ix+1, iy+1)*fx
	return a*(1-fy) + b*fy
}
