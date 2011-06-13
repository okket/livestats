#
# This file is part of the Spludo Framework.
# Copyright (c) 2009-2010 DracoBlue, http://dracoblue.net/
# 
# Licensed under the terms of MIT License. For the full copyright and license
# information, please see the LICENSE file in the root folder.
# 

child_process = require 'child_process'
fs            = require 'fs'
sys           = require  'sys'

dev_server =
    process: null
    files: []
    restarting: false
    "restart": ->
        @.restarting = true
        sys.debug 'DEVSERVER: Stopping server for restart'
        @.process.kill()
    "start": -> 
        self = @
        sys.debug 'DEVSERVER: Starting server'
        self.watchFiles()
        @.process = child_process.spawn process.ARGV[0], ['server.js']
        @.process.stdout.on 'data', (data) ->
            process.stdout.write data
        @.process.stderr.on 'data', (data) ->
            sys.print data
        @.process.on 'exit', (code) ->
            sys.debug 'DEVSERVER: Child process exited: ' + code
            @.process = null
            if self.restarting
                self.restarting = true
                self.unwatchFiles()
                self.start()
    "watchFiles": ->
        self = @
        child_process.exec 'find . | grep "\.js$"', (error, stdout, stderr) ->
            files = stdout.trim().split "\n"
            files.forEach (file) ->
                self.files.push file 
                fs.watchFile file, interval: 500, (curr, prev) ->
                    if curr.mtime.valueOf() isnt prev.mtime.valueOf() or curr.ctime.valueOf() isnt prev.ctime.valueOf()
                        sys.debug 'DEVSERVER: Restarting because of changed file at ' + file
                        dev_server.restart()
    "unwatchFiles": ->
        @.files.forEach (file) ->
            fs.unwatchFile file 
        this.files = [];

dev_server.start()




