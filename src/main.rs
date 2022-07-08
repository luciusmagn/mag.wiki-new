use dotenv;
use pulldown_cmark::{html, Options, Parser};
use redis::{Client, Commands};

use std::env;
use std::fs;
use std::os::unix::net::UnixDatagram;

fn main() {
    let _ = fs::remove_file("./markdown-server.socket");
    let _ = dotenv::dotenv();
    let client = Client::open(format!(
        "redis://{}:{}@{}:{}/",
        env::var("REDIS_WRITE_USER").expect("missing env var, check .env file"),
        env::var("REDIS_WRITE_USER_PWD").expect("missing env var, check .env file"),
        env::var("REDIS_HOST").expect("missing env var, check .env file"),
        env::var("REDIS_PORT").expect("missing env var, check .env file"),
    ))
    .unwrap();

    let mut con = loop {
        match client.get_connection() {
            Ok(c) => break c,
            Err(e) => eprintln!("cannot get redis connection: {}", e),
        }
    };

    let socket = loop {
        match UnixDatagram::bind("./markdown-server.socket") {
            Ok(sock) => break sock,
            Err(e) => eprintln!("failed to bind to unix socket: {}", e),
        }
    };

    let options = Options::all();

    let mut buf = [0; 300];
    while let Ok(size) = socket.recv(buf.as_mut_slice()) {
        if size >= 300 {
            continue;
        }

        let res = String::from_utf8_lossy(&buf[..size]);
        println!("{}", res);

        let content: Option<String> = con.get(format!("{}:content", res)).expect("FUCK");

        match content {
            Some(c) => {
                let parser = Parser::new_ext(&c, options);
                let mut html_output = String::new();
                html::push_html(&mut html_output, parser);

                let _ = con.set::<String, &str, ()>(format!("{}:html", res), &html_output);

                let _ = match html_output.find("</p>") {
                    Some(idx) => con.set::<String, &str, ()>(
                        format!("{}:preview", res),
                        &html_output[..idx + 3],
                    ),
                    None => con.set(format!("{}:preview", res), html_output),
                };
            }
            None => continue,
        }
    }
}
