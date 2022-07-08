import prologue
import karax/[karaxdsl, vdom]

import std/asyncdispatch, std/asyncfutures

import base
import ../redis/static_sites, ../redis/rd_utils

proc contact*(ctx: Context) {.async.} =
    let base_elem = content_elem()
    let con = await read_con()
    let read_content = await "contact".read(con)

    let html = if read_content.is_some():
            read_content.get()
        else:
            "<p>Use POST /s/contact to set the content of this site</p>"

    let content = build_html(article):
        header: h1: text "Contacts"
        verbatim(html)

    let text = base("BTC", "/contact", content = content)
    resp $text
