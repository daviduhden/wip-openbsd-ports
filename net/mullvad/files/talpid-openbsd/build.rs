fn main() {
    println!("cargo:rerun-if-changed=native.c");
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() == Ok("openbsd") {
        cc::Build::new()
            .file("native.c")
            .warnings(true)
            .compile("talpid_openbsd");
    }
}
