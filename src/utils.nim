import prologue

import std/sequtils, std/random, std/bitops, std/asyncdispatch,
        std/asyncfutures, std/options
from std/strutils import join

import redis/rd_utils
import redis/article_index

proc unimplemented*(msg = "lol noob") {.noreturn.} =
    quit msg

proc gen_key*(con: AsyncRedis): Future[string] {.async.} =
    let pool = concat(('a'..'z').to_seq(), ('A'..'Z').to_seq())
    randomize()

    while true:
        var balls: uint64 = uint64(rand(0i64..8446744073709551615))
        balls.clear_mask(0xFFFF_0000_0000_0000u64)

        var key: string = ""
        while balls != 0:
            key.insert($pool[balls mod 42])
            balls = (balls - (balls mod 42)) div 42

        let index: ArticleIndex = await read(con)
        if not index.keys.contains(key):
            return key

func auth_info*(ctx: Context): Option[tuple[user: string, pass: string]] =
    if ctx.request.has_header("X-User") and ctx.request.has_header("X-Password"):
        let user = ctx.request.get_header("X-User")[0]
        let password = ctx.request.get_header("X-Password")[0]
        return some((user, password))
    else:
        return none((string, string))

