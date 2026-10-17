#!/usr/bin/env bash
#
# Yamtrack 一键运行脚本(Docker Compose)
#
# 用法:
#   ./run.sh               构建(如有变化)并启动, 后台运行, 首次约需几分钟
#   ./run.sh logs          实时查看日志 (Ctrl+C 退出, 不影响服务)
#   ./run.sh stop          停止并移除容器(数据保留在 ./db)
#   ./run.sh restart       重启服务(不重新构建)
#   ./run.sh rebuild       强制重新构建镜像并启动
#   ./run.sh status        查看容器状态
#   ./run.sh shell         进入应用容器 shell
#   ./run.sh manage <cmd>  在容器内执行 Django 管理命令, 例如:
#                            ./run.sh manage createsuperuser
#                            ./run.sh manage migrate
#                            ./run.sh manage dbshell
#
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

PORT="${PORT:-8000}"
BASE_URL="http://localhost:${PORT}"

# 公开访问地址(来自 .env 的 URLS, 如有)
PUBLIC_URL=""
if [[ -f .env ]]; then
  PUBLIC_URL="$(grep -E '^URLS=' .env | tail -n1 | cut -d= -f2- || true)"
fi

# --- 环境检查 ---
if ! command -v docker >/dev/null 2>&1; then
  echo "错误: 未找到 docker, 请先安装 Docker。"
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "错误: Docker 守护进程未运行, 请先启动 Docker。"
  exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
  echo "错误: 需要 Docker Compose V2 (docker compose)。"
  exit 1
fi
if [[ ! -f .env ]]; then
  echo "提示: 未找到 .env, 将使用默认配置(内置默认 API Key)。"
fi

compose() {
  docker compose "$@"
}

check_proxy() {
  # 容器内 TMDB 等 API 请求依赖宿主机代理(见 docker-compose.override.yml)
  if ! timeout 2 bash -c 'echo > /dev/tcp/127.0.0.1/10808' 2>/dev/null; then
    echo "警告: 宿主机代理 127.0.0.1:10808 未运行, 容器内 TMDB 等 API 调用会失败。"
    echo "      如需代理, 请先执行: nohup /root/.cnb/proxy/start.sh >/root/proxy.log 2>&1 &"
  fi
}

wait_ready() {
  echo "等待应用就绪(首次启动含数据库迁移, 请耐心等待)..."
  local code
  for _ in $(seq 1 60); do
    code="$(curl -s -o /dev/null -w '%{http_code}' "${BASE_URL}/health/" 2>/dev/null || true)"
    if [[ "${code}" == "200" ]]; then
      echo "应用已就绪。"
      return 0
    fi
    sleep 3
  done
  echo "警告: 等待超时, 请执行 ./run.sh logs 查看日志排查。"
  return 0
}

print_access_info() {
  echo ""
  echo "=============================================="
  echo "  Yamtrack 已启动!"
  echo "=============================================="
  echo "  本地访问:   ${BASE_URL}"
  if [[ -n "${PUBLIC_URL}" ]]; then
    echo "  公开访问:   ${PUBLIC_URL}"
  fi
  echo ""
  echo "  首次使用:  打开上面地址, 点击 Sign up 注册账号"
  echo "  创建管理员: ./run.sh manage createsuperuser"
  echo "  查看日志:  ./run.sh logs"
  echo "  停止服务:  ./run.sh stop"
  echo "=============================================="
}

case "${1:-start}" in
  start)
    check_proxy
    compose up -d --build
    wait_ready
    print_access_info
    ;;
  rebuild)
    check_proxy
    compose up -d --build --force-recreate
    wait_ready
    print_access_info
    ;;
  logs)
    compose logs -f
    ;;
  stop)
    compose down
    echo "已停止(数据库文件保留在 ./db/db.sqlite3)。"
    ;;
  restart)
    compose restart
    ;;
  status | ps)
    compose ps
    ;;
  shell)
    compose exec yamtrack sh
    ;;
  manage)
    shift
    if [[ $# -eq 0 ]]; then
      echo "用法: ./run.sh manage <django 管理命令>, 例如: ./run.sh manage createsuperuser"
      exit 1
    fi
    compose exec yamtrack python manage.py "$@"
    ;;
  *)
    echo "未知命令: $1"
    echo "可用命令: start(默认) rebuild logs stop restart status shell manage"
    exit 1
    ;;
esac
