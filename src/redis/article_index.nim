import std/asyncdispatch, std/asyncfutures, std/marshal
import std/algorithm

import rd_utils

type
    ArticleIndex* = object
        keys*: seq[string]
        tags*: seq[string]

proc read*(con: AsyncRedis): Future[ArticleIndex] {.async.} =
    try:
        result.keys = (await con.get("web:article:index:keys")).to[:seq[
                string]]()
    except:
        result.keys = @[]
        let write_con = await write_con()
        await write_con.setk("web:article:index:keys", $$result.keys)
        await write_con.quit()

    try:
        result.tags = (await con.get("web:article:index:tags")).to[:seq[
                string]]()
    except:
        result.tags = @[]
        let write_con = await write_con()
        await con.setk("web:article:index:tags", $$result.tags)
        await write_con.quit()


proc save*(index: ArticleIndex, con: AsyncRedis) {.async.} =
    await con.setk("web:article:index:keys", $$index.keys)
    await con.setk("web:article:index:tags", $$index.tags)

proc fetch_articles*(con: AsyncRedis): Future[seq[string]] {.async.} =
    let index = await con.read()
    return index.keys.reversed()
