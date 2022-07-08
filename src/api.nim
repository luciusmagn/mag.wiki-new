import api/article
export article

import api/books
export books

# static website implementation
import prologue
import std/asyncdispatch, std/asyncfutures, std/json, std/marshal

import redis/rd_utils
import redis/static_sites
import utils

proc site*(name: string): proc(ctx: Context): Future[void] {.gcsafe.}  =
    return proc(ctx: Context) {.async.} =
        let info = auth_info(ctx)

        if info.is_some():
            let (user, pass) = info.get()
            let con = await write_con(user, pass)
            let content = ctx.request.body.to[:string]()

            if not await name.save(content, con):
                resp $$"not ok"
                return
            resp $$"ok"
        else:
            resp $$"not ok"

