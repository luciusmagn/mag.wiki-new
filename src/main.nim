import prologue
import prologue/middlewares/staticfile
import dotenv
dotenv.load()

import std/asyncdispatch

import view
import api

proc main() {.async.} =
    #let book = new("Moby-Dick; or, The Whale", "Herman Melville")
    #discard (await book.save(redis_client))

    let settings =
        #new_settings(debug = false)
        new_settings()
    var app = new_app(settings = settings)
    app.get("/", view.index)
    app.get("/articles", view.articles)

    # article
    app.post("/a", api.article.post)
    app.get("/a/{article_id}/{url}$", view.read_article)
    app.get("/t/{tag}", view.tag_articles)
    app.get("/u/{author}", view.author_articles)
    app.delete("/a/{key}", api.article.delete)
    app.get("/list", api.list)

    # TODO: make books smarter
    app.get("/books", view.books)
    app.post("/b/{author}/{title}", api.books.post)
    app.delete("/b/{title}", api.books.delete)

    # static pages
    app.get("/btc", view.btc)
    app.post("/s/btc", api.btc.post)

    app.get("/contact", view.contact)
    app.post("/s/contact", api.contact.post)

    app.get("/join", view.join)
    app.post("/s/join", api.join.post)

    # misc
    app.use(staticFileMiddleware("static"))
    app.run()

waitFor main()
