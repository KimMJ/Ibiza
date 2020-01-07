#!/bin/bash

hugo
cd public
cp -r . ../../kimmj.github.io/
cd ../../kimmj.github.io

git add .
message="update blog with script $(date '+%Y-%m-%d %H:%M:%S')"
echo $message
git commit -m "$message"
git push origin master
