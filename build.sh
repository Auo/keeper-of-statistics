#!/bin/bash
rm -rf dist &&
mkdir -p ./dist/KeeperOfStatistics/ &&
cp *.lua ./dist/KeeperOfStatistics/ &&
cp *.toc ./dist/KeeperOfStatistics/ &&
cd dist &&
zip -r ./KeeperOfStatistics.zip ./KeeperOfStatistics &&
echo 'created file: '$(pwd -P ./dist/KeeperOfStatistics.zip)/dist/KeeperOfStatistics.zip
