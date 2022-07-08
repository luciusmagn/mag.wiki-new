import prologue

import std/asyncdispatch, std/asyncfutures, std/json, std/marshal

import ../redis/rd_utils
import ../redis/static_sites
import ../utils

proc post*(ctx: Context) {.async.} =
    let info = auth_info(ctx)

    if info.is_some():
        let (user, pass) = info.get()
        let con = await write_con(user, pass)
        let content = ctx.request.body.to[:string]()

        if not await "contact".save(content, con):
            resp $$"not ok"
            return
        resp $$"ok"
    else:
        resp $$"not ok"
