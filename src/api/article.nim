import prologue

import std/asyncdispatch, std/asyncfutures, std/marshal
import std/sequtils, std/marshal, std/json

import ../redis/rd_utils
import ../redis/article, ../redis/article_index
import ../utils

import std/asyncdispatch, std/asyncfutures

proc post*(ctx: Context) {.async.} =
    let info = auth_info(ctx)

    if info.is_some():
        let (user, pass) = info.get()
        let con = await write_con(user, pass)

        let article = ctx.request.body.to[:Article]()
        await article.save(con)

        await con.quit()
        resp $$article.key.get()
    else:
        resp $$"not ok"

proc delete*(ctx: Context) {.async.} =
    let key = ctx.get_path_params_option("key").get()

    let info = auth_info(ctx)

    if info.is_some():
        let (user, pass) = info.get()
        let con = await write_con(user, pass)

        await article.delete(key, con)
        var index = await article_index.read(con)
        index.keys.keep_it_if(it != key)
        await index.save(con)

        await con.quit()
        resp $$"ok"
    else:
        resp $$"not ok"


proc list*(ctx: Context) {.async.} =
    let con = await read_con()
    let articles = await fetch_articles(con)
    resp $$articles
