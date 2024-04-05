#!/usr/bin/env bash
files="$@"
cp -t ../scratchpad/geography $files
cd ../scratchpad
git add geography
git commit -m "Update topojson files"
git push

# return to previous directory
cd -

gh release upload geos \
  $files \
  --repo "CT-Data-Haven/scratchpad" \
  --clobber 

gh release view geos \
  --repo "CT-Data-Haven/scratchpad" \
  --json id,tagName,assets,createdAt,url > \
  .shapes_uploaded.json