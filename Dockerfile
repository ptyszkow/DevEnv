# syntax=docker/dockerfile:1
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG GIT_USER_NAME=peter
ARG GIT_USER_EMAIL=peter@peter.com

# System packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl unzip xz-utils build-essential git \
    ripgrep fd-find lua5.1 luarocks golang-go \
    pandoc texlive-latex-base texlive-fonts-recommended plantuml \
    jq tidy dotnet-sdk-10.0 poppler-utils \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd

# Create a non-root default user
RUN id -u ubuntu >/dev/null 2>&1 || useradd -m -s /bin/bash -U ubuntu

# Neovim, tree-sitter, uv (system-wide)
RUN curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
    | tar -C /opt -xz \
    && mv /opt/nvim-linux-x86_64 /opt/nvim \
    && ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim \
    && curl -fsSL https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz \
    | gunzip > /usr/local/bin/tree-sitter \
    && chmod +x /usr/local/bin/tree-sitter \
    && curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

RUN mkdir -p /data/claude /data/opencode /data/uv/cache /data/uv/data \
    /home/ubuntu/.config /home/ubuntu/.cache /home/ubuntu/.local/share /home/ubuntu/Projects \
    && chown -R ubuntu:ubuntu /data /home/ubuntu

USER ubuntu
WORKDIR /home/ubuntu

ENV NVM_DIR=/home/ubuntu/.nvm \
    PATH="/home/ubuntu/.opencode/bin:/home/ubuntu/.local/bin:$PATH" \
    UV_CACHE_DIR=/home/ubuntu/.cache/uv \
    TERM=xterm-256color \
    COLORTERM=truecolor

# Shared host workspace + persisted tool data
RUN ln -sfn /data/claude "$HOME/.claude" \
    && ln -sfn /data/opencode "$HOME/.local/share/opencode" \
    && ln -sfn /data/uv/cache "$HOME/.cache/uv" \
    && ln -sfn /data/uv/data "$HOME/.local/share/uv"

# Node.js (via nvm)
RUN mkdir -p "$HOME/.local/bin" \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm alias default lts/* \
    && NODE_DIR="$NVM_DIR/versions/node/$(nvm version default)/bin" \
    && ln -sf "$NODE_DIR/node" "$HOME/.local/bin/node" \
    && ln -sf "$NODE_DIR/npm"  "$HOME/.local/bin/npm" \
    && ln -sf "$NODE_DIR/npx"  "$HOME/.local/bin/npx"

# Claude Code + OpenCode
RUN curl -fsSL https://claude.ai/install.sh | bash
RUN curl -fsSL https://opencode.ai/install | bash

# basedpyright
RUN --mount=type=cache,target=/home/ubuntu/.cache/uv,uid=1000,gid=1000 \
    uv tool install basedpyright

# Git config
RUN git config --global user.name "$GIT_USER_NAME" \
    && git config --global user.email "$GIT_USER_EMAIL" \
    && git config --global --add safe.directory '*'

RUN echo 'umask 0002' >> "$HOME/.bashrc"

# Neovim config + plugins (most volatile — last)
RUN git clone https://github.com/ptyszkow/nvim "$HOME/.config/nvim" \
    && nvim --headless "+Lazy! sync" +qa \
    && nvim --headless "+MasonInstall lua-language-server" +qa

WORKDIR /home/ubuntu/Projects
CMD ["bash"]
