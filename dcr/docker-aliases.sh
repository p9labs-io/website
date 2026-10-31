# Docker Aliases & Shortcuts
# Usage: add to ~/.bashrc or ~/.zshrc ->  [ -f ~/docker-aliases.sh ] && source ~/docker-aliases.sh

# ---- Info ----
alias dps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dpsa='docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dimg='docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.ID}}"'
alias dstats='docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"'
alias ddf='docker system df'
alias dvol='docker volume ls'
alias dnet='docker network ls'
alias dtail='docker logs -f --tail 100'

# ---- Container control (xargs -r = no error when nothing is running) ----
alias dstop='docker ps -q | xargs -r docker stop'
alias dkill='docker ps -q | xargs -r docker kill'
alias drmc='docker ps -aq -f status=exited -f status=created | xargs -r docker rm'

# ---- Cleanup (safe) ----
alias dprune='docker system prune -f'                 # stopped containers, dangling images, unused networks
alias dprunei='docker image prune -f'                 # dangling images only
alias dpruneb='docker builder prune -f'               # build cache

# ---- Cleanup (DESTRUCTIVE - deletes data) ----
alias drmi-all='docker images -q | xargs -r docker rmi'
alias dnuke='docker system prune -af --volumes'       # everything incl. ALL unused volumes (DB data!)

# ---- Helpers ----
# Shell into container (bash if available, else sh): dsh <container>
dsh() { docker exec -it "$1" sh -c 'command -v bash >/dev/null && exec bash || exec sh'; }
# Container IP(s): dip <container>
dip() { docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' "$1"; }
# Env vars of container: denv <container>
denv() { docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$1"; }
# Run throwaway container with current dir mounted: drun <image> [cmd]
drun() { docker run --rm -it -v "$PWD":/work -w /work "$@"; }

# ---- Docker Compose ----
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcub='docker compose up -d --build'
alias dcd='docker compose down'
alias dcdv='docker compose down -v'                   # also removes named volumes (DB data!)
alias dcb='docker compose build'
alias dcr='docker compose restart'
alias dce='docker compose exec'
alias dcl='docker compose logs -f --tail=100'
alias dcps='docker compose ps'
alias dcpull='docker compose pull'
alias dcw='docker compose watch'
alias dccfg='docker compose config'                  # print merged/resolved config (debug .env + overrides)
