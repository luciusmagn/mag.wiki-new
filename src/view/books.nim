import prologue
import karax/[karaxdsl, vdom]

import std/asyncdispatch, std/asyncfutures
import std/algorithm

import base
import ../redis/books, ../redis/rd_utils

const book_text = """
<p>These are books I have read and thoroughly recommend to everyone.
I take suggestions for books to read, send me an email to
<a href="mailto:ahti@tau.directory">ahti@tau.directory</a>. I am
into the following genres:</p>
<ul>
    <li>Computer science</li>
    <li>Psychology</li>
    <li>Philosophy (particularly Hellenistic philosophy)</li>
    <li>Mythology</li>
</ul>
"""

proc books*(ctx: Context) {.async, gcsafe.} =
    let base_elem = content_elem()
    let con = await read_con()
    let books: seq[Book] = await list(con)

    var content = build_html(article):
        header: h1: text "Books"
        p:
            verbatim(book_text)
        table:
            for book in books.sorted_by_it(it.meta.author):
                tr(class = "book-listing"):
                    td:
                        if book.meta.link.is_some():
                            a(href = book.meta.link.get()): text book.name
                        else:
                            text book.name
                    td:
                        text book.meta.author

    base_elem.add(content)
    await con.quit()
    let text = base("Books", "/books", content = base_elem)
    resp $text
