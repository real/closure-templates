#!/bin/bash

set -ex

rm -f package/SoyToJsSrcCompiler.jar package/SoyMsgExtractor.jar package/soyutils.js package/soyutils_usegoog.js
mvn clean
mvn package
cp target/*-SoyToJsSrcCompiler.jar package/SoyToJsSrcCompiler.jar
cp target/*-SoyMsgExtractor.jar package/SoyMsgExtractor.jar
cp target/soyutils_usegoog.js package/
