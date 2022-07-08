# Package

version       = "0.1.0"
author        = "Lukáš Hozda"
description   = "Ballin"
license       = "Fair"
srcDir        = "src"
bin           = @["main", "article"]


# Dependencies

requires "nim >= 1.6.6"
requires "prologue >= 0.6.0"
requires "karax >= 1.2.2"
requires "https://github.com/nim-lang/redis#9c6e85d"
#we need nim-redis at least 0.4.1 !!!
#requires "redis >= 0.2.0"
requires "dotenv >= 2.0.0"
requires "regex >= 0.19.0"
