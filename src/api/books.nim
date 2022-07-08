import prologue

import std/asyncdispatch, std/asyncfutures, std/marshal

import ../redis/rd_utils
import ../redis/books
import ../utils

proc post*(ctx: Context) {.async.} =
    let author = ctx.get_path_params_option("author").get()
    let title = ctx.get_path_params_option("title").get()

    let info = auth_info(ctx)

    if info.is_some():
        let (user, pass) = info.get()

        let con = await write_con(user, pass)
        let book = new(title, author)

        if not (await book.save(con)):
            resp $$"not ok"
            return

        await con.quit()
        resp $$"ok"
    else:
        resp $$"not ok"

proc delete*(ctx: Context) {.async.} =
    let title = ctx.get_path_params_option("title").get()

    let info = auth_info(ctx)

    if info.is_some():
        let (user, pass) = info.get()
        let con = await write_con(user, pass)

        if not (await books.delete(title, con)):
            resp $$"not ok"
            return

        await con.quit()
        resp $$"ok"
    else:
        resp $$"not ok"

