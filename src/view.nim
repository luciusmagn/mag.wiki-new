import view/index
export index.index

import view/articles
export articles.articles

import view/books
export books.books

import view/read_article
export read_article.read_article

import view/tag_articles
export tag_articles.tag_articles

import view/author_articles
export author_articles.author_articles

###
### Simple text view impl
###
import prologue
import karax/[karaxdsl, vdom]

import std/[asyncdispatch, asyncfutures, strformat]

import view/base
import redis/[static_sites, rd_utils]

proc simple_text*(key: string, title: string, url: string): proc(ctx: Context): Future[void] {.gcsafe} =
    return proc(ctx: Context) {.async.} =
        let base_elem = content_elem()
        let con = await read_con()
        let read_content = await key.read(con)

        let html = if read_content.is_some():
                read_content.get()
            else:
                fmt"<p>Use POST /s/{key} to set the content of this site</p>"

        let content = build_html(article):
            header: h1: text title
            verbatim(html)

        let text = base(title, url, content = content)
        resp $text

