#!/usr/bin/env bash
files="$@"
cp -t ../scratchpad/geography "$files"
cd ../scratchpad
git add geography
git commit -m "Update topojson files"
git push

gh release upload geos \
  geography/*.json \
  --repo "CT-Data-Haven/scratchpad" \
  --clobber 

gh release list 
# return to previous directory
cd -