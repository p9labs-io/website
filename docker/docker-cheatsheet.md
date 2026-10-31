# Docker Cheatsheet

Commands that are easy to forget. Aliases live in `docker-aliases.sh`.

## Install (Linux)

```bash
curl -fsSL https://get.docker.com | sh            # official convenience script
sudo usermod -aG docker $USER && newgrp docker    # run docker without sudo (= root-equivalent!)
sudo systemctl enable --now docker
docker run --rm hello-world
```

## Build

```bash
docker build -t app:1.0 .                               # default Dockerfile
docker build -f Dockerfile.go -t app .                  # specific file
docker build --target static -t web .                   # specific stage
docker build --build-arg VERSION=1.2.3 -t app .
docker build --no-cache --pull -t app .                 # fresh build, newest base image
docker build --progress=plain .                         # full output (debug RUN steps)
docker build --secret id=npmrc,src=$HOME/.npmrc .       # use: RUN --mount=type=secret,id=npmrc ...
docker build --ssh default .                            # use: RUN --mount=type=ssh git clone ...
docker history app:1.0                                  # layer sizes
```

### Multi-arch (buildx)

```bash
docker buildx create --name multi --use --bootstrap
docker buildx build --platform linux/amd64,linux/arm64 -t user/app:1.0 --push .
docker buildx build --platform linux/arm64 -t app --load .          # single arch into local images
docker buildx build --cache-to type=registry,ref=user/app:cache \
                    --cache-from type=registry,ref=user/app:cache -t user/app --push .
docker buildx imagetools inspect user/app:1.0                       # see platforms in manifest
docker buildx du && docker buildx prune -f                          # build cache usage / cleanup
```

## Run

```bash
docker run -d --name app -p 127.0.0.1:8080:8080 app:1.0
docker run --rm -it --entrypoint sh app:1.0             # override entrypoint
docker run --rm -it -v "$PWD":/work -w /work node:24-alpine sh
docker run -d --restart unless-stopped --env-file .env app
docker run --init --read-only --tmpfs /tmp --cap-drop ALL \
           --security-opt no-new-privileges -u 1000:1000 app   # hardened
docker run -m 512m --cpus 1.5 app                        # limits
docker run --network host app                            # host networking (Linux)
docker run --add-host host.docker.internal:host-gateway app
docker run --gpus all nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi
```

## Inspect / debug

```bash
docker logs -f --since 10m app
docker exec -it app sh
docker exec -u root -it app sh                           # as root in a non-root image
docker debug app                                          # shell into distroless/slim (Docker Desktop / Pro)
docker inspect app | less
docker inspect -f '{{.State.Health.Status}}' app          # healthcheck status
docker inspect -f '{{json .State.Health}}' app | jq       # healthcheck log
docker top app                                            # processes
docker diff app                                           # files changed in container
docker cp app:/app/log.txt .                              # copy out (works on distroless too)
docker events --since 10m                                 # daemon events (OOM kills, restarts)
docker stats --no-stream
# Shell tools in a distroless container's namespaces:
docker run --rm -it --pid container:app --network container:app nicolaka/netshoot
```

## Compose

```bash
docker compose up -d --build --wait          # wait until healthchecks pass
docker compose up -d --force-recreate app    # recreate one service
docker compose up -d --scale app=3           # requires no container_name / fixed host port
docker compose --profile debug up -d         # include profiled services
docker compose -f compose.yaml -f compose.prod.yaml up -d
docker compose config                        # resolved config (check .env interpolation)
docker compose watch                         # dev hot reload (develop.watch)
docker compose run --rm app sh               # one-off container
docker compose logs -f --tail=100 app
docker compose down --remove-orphans
docker compose down -v                       # + named volumes (DATA LOSS)
docker compose pull && docker compose up -d  # update images
```

## Images / registry

```bash
docker login ghcr.io -u USER                 # token: echo $CR_PAT | docker login ghcr.io -u USER --password-stdin
docker tag app:1.0 ghcr.io/user/app:1.0
docker push ghcr.io/user/app:1.0
docker save app:1.0 | gzip > app.tar.gz      # offline transfer
docker load < app.tar.gz
docker save app:1.0 | ssh server docker load # copy image to server without registry
docker image ls --filter dangling=true
docker image inspect app:1.0 --format '{{.Size}}'
```

## Volumes / backup

```bash
docker volume ls
docker volume inspect pgdata
# Backup any volume to tar
docker run --rm -v pgdata:/data -v "$PWD":/backup alpine tar czf /backup/pgdata.tgz -C /data .
# Restore
docker run --rm -v pgdata:/data -v "$PWD":/backup alpine sh -c "cd /data && tar xzf /backup/pgdata.tgz"
```

### Postgres

```bash
docker compose exec -T db pg_dump -U postgres -Fc appdb > appdb.dump     # -T: no TTY, keeps binary intact
docker compose exec -T db pg_restore -U postgres -d appdb --clean < appdb.dump
docker compose exec -T db pg_dumpall -U postgres > all.sql                 # all DBs + roles
docker compose exec db psql -U postgres -d appdb
```

## Cleanup

```bash
docker system df                             # disk usage
docker system prune -f                       # stopped containers, dangling images, unused networks
docker image prune -af --filter "until=168h" # unused images older than 7 days
docker builder prune -af --filter "until=72h"
docker volume prune                          # unused ANONYMOUS volumes (add -a for named = data loss)
```

## Security / quality

```bash
docker scout quickview app:1.0               # CVE summary
docker scout cves app:1.0
docker run --rm aquasec/trivy image app:1.0  # alternative scanner
docker run --rm -i hadolint/hadolint < Dockerfile   # Dockerfile linter
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive app:1.0  # explore layers
```

## Contexts (manage remote hosts)

```bash
docker context create prod --docker "host=ssh://user@server"
docker context use prod                      # all commands now run on server
docker --context prod ps
docker context use default
```

## Gotchas

- `ports: "8080:8080"` bypasses UFW/firewalld (Docker writes iptables directly). Bind to `127.0.0.1:` or use a reverse proxy.
- `latest` tag is not "newest", it's just the default tag. Pin versions.
- `COPY . .` without `.dockerignore` ships `.git` and `.env` into the image.
- `ENV`/`ARG` secrets are visible in `docker history`. Use `--secret` mounts.
- `depends_on` waits for start, not readiness. Use `condition: service_healthy`.
- Shell-form `CMD npm start` runs under `/bin/sh -c` -> signals not forwarded. Use exec form `["node", "app.js"]`.
- `docker compose down -v` / `system prune --volumes` deletes database data.
- Bind-mount permission errors: container uid != host uid -> `user: "${UID}:${GID}"` or `chown`.
- Postgres major upgrades don't work by bumping the tag; dump/restore or `pg_upgrade`.
