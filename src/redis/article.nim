import std/options, std/strformat, std/asyncfutures, std/asyncdispatch, std/sequtils
import std/json, std/marshal, std/net
import system

import article_index
import ../utils
import rd_utils

type
    Article* = object
        original: Option[ref Article]
        key*: Option[string]
        author*: string
        content*: string
        title*: string
        url*: string
        tags*: seq[string]
        date*: string
        html*: Option[string]
        preview*: Option[string]

proc new*(author: string, content: string, title: string, url: string,
        tags: seq[string], date: string, key: Option[string] = none(
                string)): Article =
    Article(
        original: none(ref Article),
        content: content,
        author: author,
        title: title,
        url: url,
        tags: tags,
        date: date,
        key: key,
        html: none(string),
        preview: none(string),
    )

proc read*(key: string, con: AsyncRedis): Future[Option[Article]] {.async.} =
    var article = Article()

    try:
        article.key = some(key)
        article.author = await con.get(fmt"web:article:{key}:author")
        article.content = await con.get(fmt"web:article:{key}:content")
        article.title = await con.get(fmt"web:article:{key}:title")
        article.url = await con.get(fmt"web:article:{key}:url")
        article.tags = (await con.get(fmt"web:article:{key}:tags")).to[:seq[
                string]]()
        article.date = await con.get(fmt"web:article:{key}:date")

        while true:
            if (await con.exists(fmt"web:article:{key}:html")) and (
                    await con.exists(fmt"web:article:{key}:preview")):
                article.html = some(await con.get(fmt"web:article:{key}:html"))
                article.preview = some(await con.get(
                        fmt"web:article:{key}:preview"))
                break
            else:
                gen_md_for_key(fmt"web:article:{key}")

        var original = new Article
        original[] = deep_copy(article)
        article.original = some(original)
        result = some(article)
    except:
        result = none(Article)

proc save*(article: Article, con: AsyncRedis) {.async, gcsafe.} =
    var v: seq[Future[void]] = @[]

    let key = if article.key.is_some():
            article.key.get()
        else:
            let key: string = await gen_key(con)

            var index = await read(con)
            index.keys.add(key)
            index.tags.add(article.tags)
            index.tags = index.tags.deduplicate()
            await index.save(con)

            key

    if article.original.is_some():
        let original = article.original.get()
        if article.author != original.author:
            v.add(con.setk(fmt"web:article:{key}:author", article.author))

        if article.content != original.content:
            v.add(con.setk(fmt"web:article:{key}:content", article.content))
            gen_md_for_key(fmt"web:article:{key}")

        if article.title != original.title:
            v.add(con.setk(fmt"web:article:{key}:title", article.title))

        if article.url != original.url:
            v.add(con.setk(fmt"web:article:{key}:url", article.url))

        if article.tags != original.tags:
            var index = await read(con)
            index.tags.add(article.tags)
            index.tags = index.tags.deduplicate()
            await index.save(con)

            v.add(con.setk(fmt"web:article:{key}:tags", $$article.tags))

        if article.date != original.date:
            v.add(con.setk(fmt"web:article:{key}:date", article.date))
    else:
        v.add(con.setk(fmt"web:article:{key}:author", article.author))
        v.add(con.setk(fmt"web:article:{key}:content", article.content))
        v.add(con.setk(fmt"web:article:{key}:title", article.title))
        v.add(con.setk(fmt"web:article:{key}:url", article.url))
        v.add(con.setk(fmt"web:article:{key}:tags", $$article.tags))
        v.add(con.setk(fmt"web:article:{key}:date", article.date))

    await all(v)

proc delete*(key: string, con: AsyncRedis) {.async.} =
    discard (await con.del(@[fmt"web:article:{key}:author"]))
    discard (await con.del(@[fmt"web:article:{key}:content"]))
    discard (await con.del(@[fmt"web:article:{key}:html"]))
    discard (await con.del(@[fmt"web:article:{key}:preview"]))
    discard (await con.del(@[fmt"web:article:{key}:title"]))
    discard (await con.del(@[fmt"web:article:{key}:url"]))
    discard (await con.del(@[fmt"web:article:{key}:tags"]))
    discard (await con.del(@[fmt"web:article:{key}:date"]))
