#!bin/bash
fileList="$(find source/crated -name '*.d')"

echo $fileList

dmd -c -X -D -Xfdocs.json -I~/.dub/packages/vibe-d-0.7.21-rc.4/source/ $fileList
rm *.o
rm *.html