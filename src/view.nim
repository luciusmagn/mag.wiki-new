import view/index
export index.index

import view/articles
export articles.articles

import view/books
export books.books

import view/contacts
export contacts.contact

import view/btc
export btc.btc

import view/join
export join.join

import view/read_article
export read_article.read_article

import view/tag_articles
export tag_articles.tag_articles

import view/author_articles
export author_articles.author_articles

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

