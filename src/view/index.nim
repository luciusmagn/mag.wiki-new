import prologue
import karax/[karaxdsl, vdom]

import std/asyncdispatch, std/asyncfutures, std/options, std/sequtils, std/strutils
import std/strformat

import base
import ../redis/article, ../redis/article_index
import ../redis/rd_utils

proc article_entry_view(key: string, con: AsyncRedis): Future[Option[
        VNode]] {.async.} =
    let read_article = await key.read(con)
    let article = if read_article.is_some():
            read_article.get()
        else:
            return none(VNode)
    let preview = if article.preview.is_some():
            article.preview.get()
        else:
            return none(VNode)

    let tags = spawn_tags(article.tags)

    let side_note = build_html(p(class = "side-note")):
        strong:
            text article.date
        br()
        italic:
            a(href = fmt"/u/{article.author}", class = "article-author"):
                text article.author
        br()
        tags

    let res = build_html(article):
        header: h1: a(href = fmt"/a/{article.key.get()}/{article.url}"):
            text article.title
        verbatim(preview.replace("<p>", "<p class=\"has-side-note\">"))
        tdiv: side_note
        a(class = "open", href = fmt"/a/{article.key.get()}/{article.url}"):
            text "open »"

    return some(res)

proc index*(ctx: Context) {.async.} =
    let con = await read_con()
    let keys = await fetch_articles(con)

    let articles = (await all(keys.map(proc (
            x: auto): auto = article_entry_view(x, con))))
        .filter(proc (x: auto): auto = x.is_some())
        .map(proc (x: auto): auto = x.get())

    var content = content_elem()
    for article in articles:
        content.add(article)

    let text = base("Index", "/", content = content)
    await con.quit()
    resp $text
