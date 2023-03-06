#!/bin/bash
for f in $(find "${PWD}/" -name "*.png"); do
	f2="${f::(${#f}-4)}.t3x"
	tex3ds "$f" -o "$f2"
	echo "$f2"
done
