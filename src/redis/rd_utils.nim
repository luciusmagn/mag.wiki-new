import redis
export redis

import std/os, std/asyncdispatch, std/asyncfutures, std/net, std/strutils

proc con_helper(): Future[AsyncRedis] {.async.} =
    result = await open_async(
        os.get_env("REDIS_HOST"),
        Port(parse_int(os.get_env("REDIS_PORT")))
    )

proc read_con*(): Future[AsyncRedis] {.async.} =
    let con = await con_helper()
    await con.auth(
        os.get_env("REDIS_DEFAULT_USER"),
        os.get_env("REDIS_DEFAULT_USER_PWD")
    )
    return con

proc write_con*(user: string = os.get_env("REDIS_WRITE_USER"), pass: string = os.get_env("REDIS_WRITE_USER_PWD")): Future[AsyncRedis] {.async.} =
    result = await con_helper()
    await result.auth(user, pass)

proc gen_md_for_key*(key: string) =
    let socket = new_socket(AF_UNIX, SOCK_DGRAM, IPPROTO_IP)
    socket.connect_unix("./markdown-server.socket");
    socket.send(key)
    socket.close()

