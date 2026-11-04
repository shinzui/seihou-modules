# seihou-managed. A validated Caddyfile matching the routes of serve.json.
{ writeText, runCommand, caddy }:
{ root ? "/srv/site", port ? "8080" }:
let
  config = writeText "Caddyfile" ''
    {
      admin off
      auto_https off
      persist_config off
      # Without certificates there is nothing to clean, and the image has no writable home.
      storage_clean_interval off
    }
    :${port} {
      log {
        output stdout
      }
      root * ${builtins.toJSON root}
      @search path /api/search
      header @search Content-Type "application/json"
      @markdown path *.md
      header @markdown Content-Type "text/markdown; charset=utf-8"
      # Missing hashed assets and fonts must 404, not fall back to the application
      # shell, and only files that exist may be cached.
      @found file
      handle /assets/* {
        header @found Cache-Control "public, max-age=31536000, immutable"
        file_server
      }
      handle /fonts/* {
        header @found Cache-Control "public, max-age=86400"
        file_server
      }
      handle {
        header Cache-Control "no-cache"
        try_files {path} {path}/index.html /_shell.html
        file_server
      }
    }
  '';
in
runCommand "Caddyfile-validated" { nativeBuildInputs = [ caddy ]; } ''
  cp ${config} $out
  chmod u+w $out
  caddy fmt --overwrite $out
  caddy validate --config $out --adapter caddyfile
''
