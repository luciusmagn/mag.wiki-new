import std/options, std/asyncdispatch, std/asyncfutures, std/strformat, std/sequtils, std/strutils
import std/json, std/marshal

import rd_utils

type
    BookMeta* = object
        author*: string
        link*: Option[string]
    Book* = object
        name*: string
        meta*: BookMeta

func final_key(key: string): string =
    if key.starts_with("web:book:"):
        var copy = deep_copy(key)
        copy.remove_prefix("web:book:")
        copy
    else:
        key

proc new*(name: string, author: string, link: Option[string] = none(string)): Book =
    Book(
        name: name,
        meta: BookMeta(author: author, link: link)
    )

proc read*(key: string, con: AsyncRedis): Future[Option[Book]] {.async.} =
    let final_key = final_key(key)

    try:
        if (await con.exists(fmt"web:book:{final_key}")):
            let meta = (await con.get(fmt"web:book:{final_key}")).to[:BookMeta]()
            return some(Book(
                name: final_key,
                meta: meta,
            ))
        else:
            return none(Book)
    except:
        return none(Book)

proc delete*(title: string, con: AsyncRedis): Future[bool] {.async.} =
    let final_key = final_key(title)

    try:
        discard (await con.del(@[fmt"web:book:{final_key}"]))
        return true
    except:
        return false


proc save*(book: Book, con: AsyncRedis): Future[bool] {.async.} =
    try:
        await con.setk(fmt"web:book:{book.name}", $$book.meta)
        return true
    except:
        return false

proc list*(con: AsyncRedis): Future[seq[Book]] {.async.} =
    {.gcsafe.}:
        let keys = await con.keys("web:book:*")

        let articles = (await all(keys.map(proc (key: auto): auto = key.read(con))))
            .filter(proc (x: auto): auto = x.is_some())
            .map(proc (x: auto): auto = x.get())

        return articles
