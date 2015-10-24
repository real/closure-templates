// Copyright 2015 Unreal

/**
 * @fileoverview Public interface for soy packaged files.
 */

var fs = require('fs'),
    path = require('path')

var fileDict = {}
fs.readdirSync(__dirname).forEach(function (file) {
  if (file == 'package.json' || file == 'soyfiles.js') return
  fileDict[file] = path.join(__dirname, file)
})


module.exports = fileDict
