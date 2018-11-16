#!/bin/bash
rm -rf dist &&
mkdir -p ./dist/KeeperOfStatistics/ &&
cp *.lua ./dist/KeeperOfStatistics/ &&
cp *.toc ./dist/KeeperOfStatistics/ &&
zip -r ./dist/KeeperOfStatistics.zip ./dist/KeeperOfStatistics &&
echo 'created file: '$(pwd -P ./dist/KeeperOfStatistics.zip)/dist/KeeperOfStatistics.zip
