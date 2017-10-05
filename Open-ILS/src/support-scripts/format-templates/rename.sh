#!/bin/bash

for file in *.txt
do
    filename=${file%.*}
    filename=${filename,,}
    mv "$file" "${filename}.xml"
done