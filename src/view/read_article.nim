import regex
import prologue
import karax/[karaxdsl, vdom]

import std/asyncdispatch, std/asyncfutures, std/strformat

import base

import ../redis/rd_utils, ../redis/article

proc read_article*(ctx: Context) {.async.} =
    let key = ctx.get_path_params_option("article_id").get()
    let con = await read_con()

    let res = await article.read(key, con)

    let article = if res.is_some():
            res.get()
        else:
            resp "404"
            return
    let html_content = if article.html.is_some():
            article.html.get()
        else:
            resp "404"
            return

    let base_elem = content_elem()
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

    let content = build_html(article):
        header: h1: text article.title
        verbatim(
            html_content
            .replace(re"<p>", "<p class=\"has-side-note\">", limit = 1)
            .replace(re"</p>", fmt"</p>{$side_note}", limit = 1)
        )

    base_elem.add(content)

    let text = base("Article", "", content = base_elem)
    resp $text
