#!/usr/bin/env perl
# Copyright ©2014 The Gonum Authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

use strict;
use warnings;

my $cblasHeader = "cblas.h";
my $LIB = "/usr/lib/";

my $excludeComplex = 0;
my $excludeAtlas = 1;


open(my $cblas, "<", $cblasHeader) or die;
open(my $goblas, ">", "blas.go") or die;

my %done = ("cblas_errprn"     => 1,
	        "cblas_srotg"      => 1,
	        "cblas_srotmg"     => 1,
	        "cblas_srotm"      => 1,
	        "cblas_drotg"      => 1,
	        "cblas_drotmg"     => 1,
	        "cblas_drotm"      => 1,
	        "cblas_crotg"      => 1,
	        "cblas_zrotg"      => 1,
	        "cblas_cdotu_sub"  => 1,
	        "cblas_cdotc_sub"  => 1,
	        "cblas_zdotu_sub"  => 1,
	        "cblas_zdotc_sub"  => 1,
	        );

my $atlas = "";
if ($excludeAtlas) {
	$done{'cblas_csrot'} = 1;
	$done{'cblas_zdrot'} = 1;
} else {
	$atlas = " -latlas";
}
printf $goblas <<EOH;
// Do not manually edit this file. It was created by the genBlas.pl script from ${cblasHeader}.

// Copyright ©2014 The Gonum Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Package cblas implements the blas interfaces.
package cblas

/*
#cgo CFLAGS: -g -O2
#cgo linux LDFLAGS: -L/usr/lib/ -lcblas
#cgo darwin LDFLAGS: -DYA_BLAS -DYA_LAPACK -DYA_BLASMULT -framework vecLib
#include "${cblasHeader}"
*/
import "C"

import (
	"github.com/gonum/blas"
	"unsafe"
)

// Type check assertions:
var (
	_ blas.Float32    = Blas{}
	_ blas.Float64    = Blas{}
	_ blas.Complex64  = Blas{}
	_ blas.Complex128 = Blas{}
)

// Type order is used to specify the matrix storage format. We still interact with
// an API that allows client calls to specify order, so this is here to document that fact.
type order int

const (
	rowMajor order = 101 + iota
	colMajor
)

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

type Blas struct{}

// Special cases...

type srotmParams struct {
	flag float32
	h    [4]float32
}

type drotmParams struct {
	flag float64
	h    [4]float64
}

func (Blas) Srotg(a float32, b float32) (c float32, s float32, r float32, z float32) {
	C.cblas_srotg((*C.float)(&a), (*C.float)(&b), (*C.float)(&c), (*C.float)(&s))
	return c, s, a, b
}
func (Blas) Srotmg(d1 float32, d2 float32, b1 float32, b2 float32) (p blas.SrotmParams, rd1 float32, rd2 float32, rb1 float32) {
	var pi srotmParams
	C.cblas_srotmg((*C.float)(&d1), (*C.float)(&d2), (*C.float)(&b1), C.float(b2), (*C.float)(unsafe.Pointer(&pi)))
	return blas.SrotmParams{Flag: blas.Flag(pi.flag), H: pi.h}, d1, d2, b1
}
func (Blas) Srotm(n int, x []float32, incX int, y []float32, incY int, p blas.SrotmParams) {
	if n < 0 {
		panic("cblas: n < 0")
	}
	if incX == 0 {
		panic("cblas: zero x index increment")
	}
	if incY == 0 {
		panic("cblas: zero y index increment")
	}
	if (n-1)*incX >= len(x) {
		panic("cblas: index out of range")
	}
	if (n-1)*incY >= len(y) {
		panic("cblas: index out of range")
	}
	if p.Flag < blas.Identity || p.Flag > blas.Diagonal {
		panic("cblas: illegal blas.Flag value")
	}
	pi := srotmParams{
		flag: float32(p.Flag),
		h:    p.H,
	}
	C.cblas_srotm(C.int(n), (*C.float)(&x[0]), C.int(incX), (*C.float)(&y[0]), C.int(incY), (*C.float)(unsafe.Pointer(&pi)))
}
func (Blas) Drotg(a float64, b float64) (c float64, s float64, r float64, z float64) {
	C.cblas_drotg((*C.double)(&a), (*C.double)(&b), (*C.double)(&c), (*C.double)(&s))
	return c, s, a, b
}
func (Blas) Drotmg(d1 float64, d2 float64, b1 float64, b2 float64) (p blas.DrotmParams, rd1 float64, rd2 float64, rb1 float64) {
	var pi drotmParams
	C.cblas_drotmg((*C.double)(&d1), (*C.double)(&d2), (*C.double)(&b1), C.double(b2), (*C.double)(unsafe.Pointer(&pi)))
	return blas.DrotmParams{Flag: blas.Flag(pi.flag), H: pi.h}, d1, d2, b1
}
func (Blas) Drotm(n int, x []float64, incX int, y []float64, incY int, p blas.DrotmParams) {
	if n < 0 {
		panic("cblas: n < 0")
	}
	if incX == 0 {
		panic("cblas: zero x index increment")
	}
	if incY == 0 {
		panic("cblas: zero y index increment")
	}
	if (n-1)*incX >= len(x) {
		panic("cblas: index out of range")
	}
	if (n-1)*incY >= len(y) {
		panic("cblas: index out of range")
	}
	if p.Flag < blas.Identity || p.Flag > blas.Diagonal {
		panic("cblas: illegal blas.Flag value")
	}
	pi := drotmParams{
		flag: float64(p.Flag),
		h:    p.H,
	}
	C.cblas_drotm(C.int(n), (*C.double)(&x[0]), C.int(incX), (*C.double)(&y[0]), C.int(incY), (*C.double)(unsafe.Pointer(&pi)))
}
func (Blas) Cdotu(n int, x []complex64, incX int, y []complex64, incY int) (dotu complex64) {
	if n < 0 {
		panic("cblas: n < 0")
	}
	if incX == 0 {
		panic("cblas: zero x index increment")
	}
	if incY == 0 {
		panic("cblas: zero y index increment")
	}
	if (n-1)*incX >= len(x) {
		panic("cblas: index out of range")
	}
	if (n-1)*incY >= len(y) {
		panic("cblas: index out of range")
	}
	C.cblas_cdotu_sub(C.int(n), unsafe.Pointer(&x[0]), C.int(incX), unsafe.Pointer(&y[0]), C.int(incY), unsafe.Pointer(&dotu))
	return dotu
}
func (Blas) Cdotc(n int, x []complex64, incX int, y []complex64, incY int) (dotc complex64) {
	if n < 0 {
		panic("cblas: n < 0")
	}
	if incX == 0 {
		panic("cblas: zero x index increment")
	}
	if incY == 0 {
		panic("cblas: zero y index increment")
	}
	if (n-1)*incX >= len(x) {
		panic("cblas: index out of range")
	}
	if (n-1)*incY >= len(y) {
		panic("cblas: index out of range")
	}
	C.cblas_cdotc_sub(C.int(n), unsafe.Pointer(&x[0]), C.int(incX), unsafe.Pointer(&y[0]), C.int(incY), unsafe.Pointer(&dotc))
	return dotc
}
func (Blas) Zdotu(n int, x []complex128, incX int, y []complex128, incY int) (dotu complex128) {
	if n < 0 {
		panic("cblas: n < 0")
	}
	if incX == 0 {
		panic("cblas: zero x index increment")
	}
	if incY == 0 {
		panic("cblas: zero y index increment")
	}
	if (n-1)*incX >= len(x) {
		panic("cblas: index out of range")
	}
	if (n-1)*incY >= len(y) {
		panic("cblas: index out of range")
	}
	C.cblas_zdotu_sub(C.int(n), unsafe.Pointer(&x[0]), C.int(incX), unsafe.Pointer(&y[0]), C.int(incY), unsafe.Pointer(&dotu))
	return dotu
}
func (Blas) Zdotc(n int, x []complex128, incX int, y []complex128, incY int) (dotc complex128) {
	if n < 0 {
		panic("cblas: n < 0")
	}
	if incX == 0 {
		panic("cblas: zero x index increment")
	}
	if incY == 0 {
		panic("cblas: zero y index increment")
	}
	if (n-1)*incX >= len(x) {
		panic("cblas: index out of range")
	}
	if (n-1)*incY >= len(y) {
		panic("cblas: index out of range")
	}
	C.cblas_zdotc_sub(C.int(n), unsafe.Pointer(&x[0]), C.int(incX), unsafe.Pointer(&y[0]), C.int(incY), unsafe.Pointer(&dotc))
	return dotc
}
EOH

printf $goblas <<EOH unless $excludeAtlas;
func (Blas) Crotg(a complex64, b complex64) (c complex64, s complex64, r complex64, z complex64) {
	C.cblas_srotg(unsafe.Pointer(&a), unsafe.Pointer(&b), unsafe.Pointer(&c), unsafe.Pointer(&s))
	return c, s, a, b
}
func (Blas) Zrotg(a complex128, b complex128) (c complex128, s complex128, r complex128, z complex128) {
	C.cblas_drotg(unsafe.Pointer(&a), unsafe.Pointer(&b), unsafe.Pointer(&c), unsafe.Pointer(&s))
	return c, s, a, b
}
EOH

print $goblas "\n";

$/ = undef;
my $header = <$cblas>;

# horrible munging of text...
$header =~ s/#[^\n\r]*//g;                 # delete cpp lines
$header =~ s/\n +([^\n\r]*)/\n$1/g;        # remove starting space
$header =~ s/(?:\n ?\n)+/\n/g;             # delete empty lines
$header =~ s! ((['"]) (?: \\. | .)*? \2) | # skip quoted strings
             /\* .*? \*/ |                 # delete C comments
             // [^\n\r]*                   # delete C++ comments just in case
             ! $1 || ' '                   # change comments to a single space
             !xseg;    	                   # ignore white space, treat as single line
                                           # evaluate result, repeat globally
$header =~ s/([^;])\n/$1/g;                # join prototypes into single lines
$header =~ s/, +/,/g;
$header =~ s/ +/ /g;
$header =~ s/ +}/}/g;
$header =~ s/\n+//;

$/ = "\n";
my @lines = split ";\n", $header;

our %retConv = (
	"int" => "int ",
	"float" => "float32 ",
	"double" => "float64 ",
	"CBLAS_INDEX" => "int ",
	"void" => ""
);

foreach my $line (@lines) {
	process($line);
}

close($goblas);
`go fmt .`;

sub process {
	my $line = shift;
	chomp $line;
	if (not $line =~ m/^enum/) {
		processProto($line);
	}
}

sub processProto {
	my $proto = shift;
	my ($func, $paramList) = split /[()]/, $proto;
	(my $ret, $func) = split ' ', $func;
	if ($done{$func} or $excludeComplex && $func =~ m/_[isd]?[zc]/ or $excludeAtlas && $func =~ m/^catlas_/) {
		return
	}
	$done{$func} = 1;
	my $GoRet = $retConv{$ret};
	my $complexType = $func;
	$complexType =~ s/.*_[isd]?([zc]).*/$1/;
	print $goblas "func (Blas) ".Gofunc($func)."(".processParamToGo($func, $paramList, $complexType).") ".$GoRet."{\n";
	print $goblas processParamToChecks($func, $paramList);
	print $goblas "\t";
	if ($ret ne 'void') {
		chop($GoRet);
		print $goblas "return ".$GoRet."(";
	}
	print $goblas "C.$func(".processParamToC($func, $paramList).")";
	if ($ret ne 'void') {
		print $goblas ")";
	}
	print $goblas "\n}\n";
}

sub Gofunc {
	my $fnName = shift;
	$fnName =~ s/_sub//;
	my ($pack, $func, $tail) = split '_', $fnName;
	if ($pack eq 'cblas') {
		$pack = "";
	} else {
		$pack = substr $pack, 1;
	}

	return ucfirst $pack . ucfirst $func . ucfirst $tail if $tail;
	return ucfirst $pack . ucfirst $func;
}

sub processParamToGo {
	my $func = shift;
	my $paramList = shift;
	my $complexType = shift;
	my @processed;
	my @params = split ',', $paramList;
	my $skip = 0;
	foreach my $param (@params) {
		my @parts = split /[ *]/, $param;
		my $var = lcfirst $parts[scalar @parts - 1];
		$param =~ m/^(?:const )?int/ && do {
			push @processed, $var." int"; next;
		};
		$param =~ m/^(?:const )?void/ && do {
			my $type;
			if ($var eq "alpha" || $var eq "beta") {
				$type = " ";
			} else {
				$type = " []";
			}
			if ($complexType eq 'c') {
				push @processed, $var.$type."complex64"; next;
			} elsif ($complexType eq 'z') {
				push @processed, $var.$type."complex128"; next;
			} else {
				die "unexpected complex type for '$func' - '$complexType'";
			}
		};
		$param =~ m/^(?:const )?char \*/ && do {
			push @processed, $var." *byte"; next;
		};
		$param =~ m/^(?:const )?float \*/ && do {
			push @processed, $var." []float32"; next;
		};
		$param =~ m/^(?:const )?double \*/ && do {
			push @processed, $var." []float64"; next;
		};
		$param =~ m/^(?:const )?float/ && do {
			push @processed, $var." float32"; next;
		};
		$param =~ m/^(?:const )?double/ && do {
			push @processed, $var." float64"; next;
		};
		$param =~ m/^const enum/ && do {
			$var eq "order" && $skip++;
			$var =~ /trans/ && do {
				$var =~ s/trans([AB]?)/t$1/;
				push @processed, $var." blas.Transpose"; next;
			};
			$var eq "uplo" && do {
				$var = "ul";
				push @processed, $var." blas.Uplo"; next;
			};
			$var eq "diag" && do {
				$var = "d";
				push @processed, $var." blas.Diag"; next;
			};
			$var eq "side" && do {
				$var = "s";
				push @processed, $var." blas.Side"; next;
			};
		};
	}
	die "missed Go parameters from '$func', '$paramList'" if scalar @processed+$skip != scalar @params;
	return join ", ", @processed;
}

sub processParamToChecks {
	my $func = shift;
	my $paramList = shift;
	my @processed;
	my @params = split ',', $paramList;
	my %arrayArgs;
	my %scalarArgs;
	foreach my $param (@params) {
		my @parts = split /[ *]/, $param;
		my $var = lcfirst $parts[scalar @parts - 1];
		$param =~ m/^(?:const )?int \*[a-zA-Z]/ && do {
			$scalarArgs{$var} = 1; next;
		};
		$param =~ m/^(?:const )?void \*[a-zA-Z]/ && do {
			if ($var ne "alpha" && $var ne "beta") {
				$arrayArgs{$var} = 1;
			}
			next;
		};
		$param =~ m/^(?:const )?(?:float|double) \*[a-zA-Z]/ && do {
			$arrayArgs{$var} = 1; next;
		};
		$param =~ m/^(?:const )?(?:int|float|double) [a-zA-Z]/ && do {
			$scalarArgs{$var} = 1; next;
		};
		$param =~ m/^const enum [a-zA-Z]/ && do {
			$var eq "order" && do {
				$scalarArgs{'o'} = 1;
			};
			$var =~ /trans/ && do {
				$var =~ s/trans([AB]?)/t$1/;
				$scalarArgs{$var} = 1;
				if ($func =~ m/cblas_[cz]h/) {
					push @processed, "if $var != blas.NoTrans && $var != blas.ConjTrans { panic(\"cblas: illegal transpose\") }"; next;
				} elsif ($func =~ m/cblas_[cz]s/) {
					push @processed, "if $var != blas.NoTrans && $var != blas.Trans { panic(\"cblas: illegal transpose\") }"; next;
				} else {
					push @processed, "if $var != blas.NoTrans && $var != blas.Trans && $var != blas.ConjTrans { panic(\"cblas: illegal transpose\") }"; next;
				}
			};
			$var eq "uplo" && do {
				push @processed, "if ul != blas.Upper && ul != blas.Lower { panic(\"cblas: illegal triangle\") }"; next;
			};
			$var eq "diag" && do {
				push @processed, "if d != blas.NonUnit && d != blas.Unit { panic(\"cblas: illegal diagonal\") }"; next;
			};
			$var eq "side" && do {
				$scalarArgs{'s'} = 1;
				push @processed, "if s != blas.Left && s != blas.Right { panic(\"cblas: illegal side\") }"; next;
			};
		};
	}

	# shape checks
	foreach my $ref ('m', 'n', 'k', 'kL', 'kU') {
		push @processed, "if $ref < 0 { panic(\"cblas: $ref < 0\") }" if $scalarArgs{$ref};
	}

	if ($arrayArgs{'ap'}) {
		push @processed, "if n*(n + 1)/2 > len(ap) { panic(\"cblas: index of ap out of range\") }"
	}

	push @processed, "if incX == 0 { panic(\"cblas: zero x index increment\") }" if $scalarArgs{'incX'};
	push @processed, "if incY == 0 { panic(\"cblas: zero y index increment\") }" if $scalarArgs{'incY'};
	if ($func =~ m/cblas_[sdcz]g[eb]mv/) {
		push @processed, "var lenX, lenY int";
		push @processed, "if tA == blas.NoTrans { lenX, lenY = n, m } else { lenX, lenY = m, n }";
		push @processed, "if (incX > 0 && (lenX-1)*incX >= len(x)) || (incX < 0 && (1-lenX)*incX >= len(x)) { panic(\"cblas: x index out of range\") }";
		push @processed, "if (incY > 0 && (lenY-1)*incY >= len(y)) || (incY < 0 && (1-lenY)*incY >= len(y)) { panic(\"cblas: y index out of range\") }";
	} elsif ($scalarArgs{'m'}) {
		push @processed, "if (incX > 0 && (m-1)*incX >= len(x)) || (incX < 0 && (1-m)*incX >= len(x)) { panic(\"cblas: x index out of range\") }" if $scalarArgs{'incX'};
		push @processed, "if (incY > 0 && (n-1)*incY >= len(y)) || (incY < 0 && (1-n)*incY >= len(y)) { panic(\"cblas: y index out of range\") }" if $scalarArgs{'incY'};
	} elsif ($func =~ m/cblas_[sdcz]s?scal/) {
		push @processed, "if incX < 0 { return }";
		push @processed, "if incX > 0 && (n-1)*incX >= len(x) { panic(\"cblas: x index out of range\") }";
	} elsif ($func =~ m/cblas_i[sdcz]amax/) {
		push @processed, "if n == 0 || incX < 0 { return -1 }";
		push @processed, "if incX > 0 && (n-1)*incX >= len(x) { panic(\"cblas: x index out of range\") }";
	} elsif ($func =~ m/cblas_[sdz][cz]?(?:asum|nrm2)/) {
		push @processed, "if incX < 0 { return 0 }";
		push @processed, "if incX > 0 && (n-1)*incX >= len(x) { panic(\"cblas: x index out of range\") }";
	} else {
		push @processed, "if (incX > 0 && (n-1)*incX >= len(x)) || (incX < 0 && (1-n)*incX >= len(x)) { panic(\"cblas: x index out of range\") }" if $scalarArgs{'incX'};
		push @processed, "if (incY > 0 && (n-1)*incY >= len(y)) || (incY < 0 && (1-n)*incY >= len(y)) { panic(\"cblas: y index out of range\") }" if $scalarArgs{'incY'};
	}

	if (not $func =~ m/(?:mm|r2?k)$/) {
		if ($arrayArgs{'a'}) {
			if ($scalarArgs{'s'}) {
					push @processed, "if s == blas.Left {";
					push @processed, "if lda*(n-1)+m > len(a) || lda < max(1, m) { panic(\"cblas: index of a out of range\") }";
					push @processed, "} else {";
					push @processed, "if lda*(m-1)+n > len(a) || lda < max(1, n) { panic(\"cblas: index of a out of range\") }";
					push @processed, "}";
					push @processed, "if ldb*(m-1)+n > len(b) || ldb < max(1, n) { panic(\"cblas: index of b out of range\") }";
			} elsif (($scalarArgs{'kL'} && $scalarArgs{'kU'}) || $scalarArgs{'m'}) {
				if ($scalarArgs{'kL'} && $scalarArgs{'kU'}) {
					push @processed, "if lda*(m-1)+kL+kU+1 > len(a) || lda < kL+kU+1 { panic(\"cblas: index of a out of range\") }";
				} else {
					push @processed, "if lda*(m-1)+n > len(a) || lda < max(1, n) { panic(\"cblas: index of a out of range\") }";
				}
			} else {
				if ($scalarArgs{'k'}) {
					push @processed, "if lda*(n-1)+k+1 > len(a) || lda < k+1 { panic(\"cblas: index of a out of range\") }";
				} else {
					push @processed, "if lda*(n-1)+n > len(a) || lda < max(1, n) { panic(\"cblas: index of a out of range\") }";
				}
			}
		}
	} else {
		if ($scalarArgs{'s'}) {
			push @processed, "var k int";
			push @processed, "if s == blas.Left { k = m } else { k = n }";
			push @processed, "if lda*(k-1)+k > len(a) || lda < max(1, k) { panic(\"cblas: index of a out of range\") }";
			push @processed, "if ldb*(m-1)+n > len(b) || ldb < max(1, n) { panic(\"cblas: index of b out of range\") }";
			if ($arrayArgs{'c'}) {
				push @processed, "if ldc*(m-1)+n > len(c) || ldc < max(1, n) { panic(\"cblas: index of c out of range\") }";
			}
		}
		if ($scalarArgs{'t'}) {
			push @processed, "var row, col int";
			push @processed, "if t == blas.NoTrans { row, col = n, k } else { row, col = k, n }";
			foreach my $ref ('a', 'b') {
				if ($arrayArgs{$ref}) {
					push @processed, "if ld${ref}*(row-1)+col > len(${ref}) || ld${ref} < max(1, col) { panic(\"cblas: index of ${ref} out of range\") }";
				}
			}
			if ($arrayArgs{'c'}) {
				push @processed, "if ldc*(n-1)+n > len(c) || ldc < max(1, n) { panic(\"cblas: index of c out of range\") }";
			}
		}
		if ($scalarArgs{'tA'} && $scalarArgs{'tB'}) {
			push @processed, "var rowA, colA, rowB, colB int";
			push @processed, "if tA == blas.NoTrans { rowA, colA = m, k } else { rowA, colA = k, m }";
			push @processed, "if tB == blas.NoTrans { rowB, colB = k, n } else { rowB, colB = n, k }";
			push @processed, "if lda*(rowA-1)+colA > len(a) || lda < max(1, colA) { panic(\"cblas: index of a out of range\") }";
			push @processed, "if ldb*(rowB-1)+colB > len(b) || ldb < max(1, colB) { panic(\"cblas: index of b out of range\") }";
			push @processed, "if ldc*(m-1)+n > len(c) || ldc < max(1, n) { panic(\"cblas: index of c out of range\") }";
		}
	}

	my $checks = join "\n", @processed;
	$checks .= "\n" if scalar @processed > 0;
	return $checks
}

sub processParamToC {
	my $func = shift;
	my $paramList = shift;
	my @processed;
	my @params = split ',', $paramList;
	foreach my $param (@params) {
		my @parts = split /[ *]/, $param;
		my $var = lcfirst $parts[scalar @parts - 1];
		$param =~ m/^(?:const )?int \*[a-zA-Z]/ && do {
			push @processed, "(*C.int)(&".$var.")"; next;
		};
		$param =~ m/^(?:const )?void \*[a-zA-Z]/ && do {
			my $type;
			if ($var eq "alpha" || $var eq "beta") {
				$type = "";
			} else {
				$type = "[0]";
			}
			push @processed, "unsafe.Pointer(&".$var.$type.")"; next;
		};
		$param =~ m/^(?:const )?char \*[a-zA-Z]/ && do {
			push @processed, "(*C.char)(&".$var.")"; next;
		};
		$param =~ m/^(?:const )?float \*[a-zA-Z]/ && do {
			push @processed, "(*C.float)(&".$var."[0])"; next;
		};
		$param =~ m/^(?:const )?double \*[a-zA-Z]/ && do {
			push @processed, "(*C.double)(&".$var."[0])"; next;
		};
		$param =~ m/^(?:const )?int [a-zA-Z]/ && do {
			push @processed, "C.int(".$var.")"; next;
		};
		$param =~ m/^(?:const )float [a-zA-Z]/ && do {
			push @processed, "C.float(".$var.")"; next;
		};
		$param =~ m/^(?:const )double [a-zA-Z]/ && do {
			push @processed, "C.double(".$var.")"; next;
		};
		$param =~ m/^const enum [a-zA-Z]/ && do {
			$var eq "order" && do {
				push @processed, "C.enum_$parts[scalar @parts - 2](rowMajor)"; next;
			};
			$var =~ /trans/ && do {
				$var =~ s/trans([AB]?)/t$1/;
				push @processed, "C.enum_$parts[scalar @parts - 2](".$var.")"; next;
			};
			$var eq "uplo" && do {
				$var = "ul";
				push @processed, "C.enum_$parts[scalar @parts - 2](".$var.")"; next;
			};
			$var eq "diag" && do {
				$var = "d";
				push @processed, "C.enum_$parts[scalar @parts - 2](".$var.")"; next;
			};
			$var eq "side" && do {
				$var = "s";
				push @processed, "C.enum_$parts[scalar @parts - 2](".$var.")"; next;
			};
		};
	}
	die "missed C parameters from '$func', '$paramList'" if scalar @processed != scalar @params;
	return join ", ", @processed;
}
