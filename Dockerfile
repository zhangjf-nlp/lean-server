FROM python:3.12-slim

# 构建参数 - 使用 v4.15.0 版本
ARG LEAN_SERVER_LEAN_VERSION=v4.15.0
ARG REPL_REPO_URL=https://github.com/leanprover-community/repl.git
ARG REPL_BRANCH=${LEAN_SERVER_LEAN_VERSION}
ARG MATHLIB_REPO_URL=https://github.com/leanprover-community/mathlib4.git
ARG MATHLIB_BRANCH=${LEAN_SERVER_LEAN_VERSION}

LABEL version="1.0.0"

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    ca-certificates curl git build-essential unzip jq wget \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 创建非 root 用户
RUN useradd -m -u 1000 user
USER user
WORKDIR /home/user

# 设置环境变量
ENV LEAN_SERVER_HOST=0.0.0.0 \
    LEAN_SERVER_PORT=8000 \
    LEAN_SERVER_LOG_LEVEL=INFO \
    LEAN_SERVER_LEAN_VERSION=${LEAN_SERVER_LEAN_VERSION} \
    LEAN_SERVER_MAX_REPLS=1 \
    LEAN_SERVER_MAX_REPL_MEM=10G \
    PATH=/home/user/.elan/bin:/home/user/.local/bin:$PATH \
    HOME=/home/user

# ========== 安装 Elan 和 Lean 4.15.0 ==========
RUN echo "Installing Elan..." && \
    curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | \
    sh -s -- --default-toolchain "${LEAN_SERVER_LEAN_VERSION}" -y

ENV PATH=/home/user/.elan/bin:$PATH

RUN echo "Verifying Lean installation..." && \
    lean --version

# 复制安装文件
COPY --chown=user install_repo.sh ./
RUN chmod +x /home/user/install_repo.sh

# ========== 使用脚本安装 repl 和 mathlib4 ==========
RUN echo "Starting installation using script..." && \
    /home/user/install_repo.sh && \
    echo "All packages installed successfully"

# ========== 设置应用 ==========
WORKDIR /home/user/app

# 复制应用文件
COPY --chown=user requirements.txt ./

# 安装 Python 依赖
RUN python3 -m pip install --no-cache-dir --user -r requirements.txt