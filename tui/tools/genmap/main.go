//go:build ignore

// genmap rasterizes the Natural Earth 110m land polygons into the 1-bit mask
// the world clock draws (internal/worldmap/land.bin).
//
//	curl -o /tmp/ne_110m_land.geojson https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_land.geojson
//	go run tools/genmap/main.go /tmp/ne_110m_land.geojson internal/worldmap/land.bin
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"sort"
)

const (
	W = 720 // 0.5 degrees per pixel
	H = 360
)

type feature struct {
	Geometry struct {
		Type        string          `json:"type"`
		Coordinates json.RawMessage `json:"coordinates"`
	} `json:"geometry"`
}

type collection struct {
	Features []feature `json:"features"`
}

type ring [][2]float64

func main() {
	if len(os.Args) < 3 {
		fmt.Fprintln(os.Stderr, "usage: genmap in.geojson out.bin")
		os.Exit(2)
	}
	b, err := os.ReadFile(os.Args[1])
	if err != nil {
		panic(err)
	}
	var fc collection
	if err := json.Unmarshal(b, &fc); err != nil {
		panic(err)
	}
	mask := make([]bool, W*H)
	for _, f := range fc.Features {
		var polys [][]ring
		switch f.Geometry.Type {
		case "Polygon":
			var p []ring
			must(json.Unmarshal(f.Geometry.Coordinates, &p))
			polys = append(polys, p)
		case "MultiPolygon":
			must(json.Unmarshal(f.Geometry.Coordinates, &polys))
		}
		for _, p := range polys {
			fill(mask, p)
		}
	}
	out := make([]byte, (W*H+7)/8)
	n := 0
	for i, v := range mask {
		if v {
			out[i/8] |= 1 << uint(7-i%8)
			n++
		}
	}
	must(os.WriteFile(os.Args[2], out, 0o644))
	fmt.Printf("wrote %s: %d bytes, %.1f%% land\n", os.Args[2], len(out), 100*float64(n)/float64(W*H))
}

// fill paints one polygon (outer ring + holes) with the even-odd rule.
func fill(mask []bool, rings []ring) {
	for y := 0; y < H; y++ {
		lat := 90 - (float64(y)+0.5)*180/H
		var xs []float64
		for _, r := range rings {
			for i := 0; i+1 < len(r); i++ {
				a, b := r[i], r[i+1]
				if (a[1] <= lat) == (b[1] <= lat) {
					continue
				}
				t := (lat - a[1]) / (b[1] - a[1])
				xs = append(xs, a[0]+t*(b[0]-a[0]))
			}
		}
		sort.Float64s(xs)
		for i := 0; i+1 < len(xs); i += 2 {
			x0 := int((xs[i]+180)*W/360 + 0.5)
			x1 := int((xs[i+1]+180)*W/360 + 0.5)
			for x := x0; x < x1; x++ {
				if x >= 0 && x < W {
					mask[y*W+x] = true
				}
			}
		}
	}
}

func must(err error) {
	if err != nil {
		panic(err)
	}
}
