import karax/[karaxdsl, vdom]

import std/strformat, std/sequtils

proc menu_link(href: string, selected: string, content: string): VNode =
    result = build_html():
        if href == selected:
            a(href = href, class = "current"):
                text content
        else:
            a(href = href):
                text content

proc menu(selected: string): VNode =
    result = build_html(nav):
        "/".menu_link(selected, "Home")
        "/articles".menu_link(selected, "Articles")
        "/books".menu_link(selected, "Books")
        "/contact".menu_link(selected, "Contact")
        "/btc".menu_link(selected, "BTC")
        "/join".menu_link(selected, "Join")

func spawn_tags*(tags: seq[string]): VNode =
    let elems = tags.map(
        func (t: string): VNode =
        build_html(span(class = "tags")): a(href = fmt"/t/{t}"): text t
    )

    result = build_html(span())

    for elem in elems:
        result.add(elem)

func content_elem*(): VNode =
    build_html(main(class = "page-content"))

func base*(title: string, selected: string, include_css = @["/static/main.css",
        "/static/fonts.css"], content: VNode): VNode =
    let menu = menu(selected)

    result = build_html(html):
        head:
            title:
                text title
            for l in include_css:
                link(rel = "stylesheet", type = "text/css", href = l)
        body:
            header:
                a(href = "/"):
                    text "magnusi"
            menu
            content
            footer:
                text "2022"
