import std/options, std/asyncdispatch, std/asyncfutures, std/strformat, std/strutils

import rd_utils

proc save*(key: string, content: string, con: AsyncRedis): Future[bool] {.async.} =
    try:
        await con.setk(fmt"web:static:{key}:content", content)
        gen_md_for_key(fmt"web:static:{key}")
        return true
    except:
        return false

proc read*(key: string, con: AsyncRedis): Future[Option[string]] {.async.} =
    try:
        let res = await con.get(fmt"web:static:{key}:html")
        if ($res).is_empty_or_whitespace() or not (await con.exists(fmt"web:static:{key}:html")):
            return none(string)
        else:
            return some(res)
    except:
        return none(string)
