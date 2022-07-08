#article file format:
# {date}.{author}.{name}.{tag1}.{tag2}.{tag3 and so on}.md
import os, std/strutils, std/options, std/marshal
import redis/article

let args = command_line_params()
let name: string = args[0]


let key = if args.len() >= 2:
        some(args[1])
    else:
        none(string)

let url = if args.len() >= 3:
        args[2]
    else:
        "article"

let path_parts = name.split("/")
let parts = path_parts[path_parts.high].split(".")
let date: string = parts[0]
let author: string = parts[1]
let title: string = parts[2]
let tags: seq[string] = parts[3..parts.len() - 2]
let content: string = read_file(name)

let res = new(author = author, key = key, date = date, title = title,
                tags = tags, content = content, url = url)

echo $$res
