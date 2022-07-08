import prologue
import karax/[karaxdsl, vdom, vstyles]

import std/asyncdispatch, std/asyncfutures, std/strformat, std/sequtils
import std/algorithm

import base
import ../redis/article_index, ../redis/article, ../redis/rd_utils

proc tags(con: AsyncRedis): Future[VNode] {.async.} =
    let index = await read(con)

    var tag_elems = build_html(tdiv(class = "side-note", style = style((
            border_left, "none")))):
        h1: text "Tags"

    for tag in index.tags.sorted():
        let tag_link = build_html(a(href = fmt"/t/{tag}")):
            text tag
            br()

        tag_elems.add(tag_link)

    return tag_elems

const intro_text = """
Everything published on this site will be listed here, roughly
in the order of submission. Of the provided metadata, only date is
not clickable.
You can add your writings here, I will publish them (or rather
tell you how you can publish them to this site yourself.)
"""

proc links(con: AsyncRedis): Future[VNode] {.async.} =
    let keys = await fetch_articles(con)
    let articles: seq[Article] = (await all(keys.map(proc (
            x: auto): auto = x.read(con))))
        .filter(proc (x: auto): auto = x.is_some())
        .map(proc (x: auto): auto = x.get())

    let content = build_html(tdiv(class = "has-side-note")):
        h1: text "Articles"
        p:
            verbatim intro_text
        table(class = "article-table"):
            for article in articles:
                tr:
                    td:
                        a(class = "article-listing",
                                href = fmt"/a/{article.key.get()}/{article.url}"):
                            text article.title
                    td:
                        a(class = "article-author",
                                href = fmt"/u/{article.author}"):
                            text article.author
                    td:
                        text article.date
                    td:
                        for tag in article.tags.sorted():
                            a(class = "article-listing-tag",
                                    href = fmt"/t/{tag}"): text tag

    return content

proc articles*(ctx: Context) {.async.} =
    let base_elem = content_elem()
    let con = await read_con()
    let tags = await tags(con)
    let links = await links(con)

    let content = build_html(article):
        links
        tags

    base_elem.add(content)

    let text = base("Articles", "/articles", content = base_elem)
    await con.quit()
    resp $text
