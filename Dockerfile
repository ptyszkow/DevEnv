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
    jq tidy dotnet-sdk-10.0 \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd

# Create non-root user
RUN useradd -m -s /bin/bash agentai

# Neovim, tree-sitter, uv (system-wide, as root)
RUN curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
    | tar -C /opt -xz \
    && mv /opt/nvim-linux-x86_64 /opt/nvim \
    && ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim \
    && curl -fsSL https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz \
    | gunzip > /usr/local/bin/tree-sitter \
    && chmod +x /usr/local/bin/tree-sitter \
    && curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

# Auth credentials + ownership
COPY .claude.json /home/agentai/.claude.json
RUN mkdir -p /home/agentai/.claude
COPY .claude/.credentials.json /home/agentai/.claude/.credentials.json
RUN mkdir -p /home/agentai/.local/share/opencode
COPY .local/share/opencode/auth.json /home/agentai/.local/share/opencode/auth.json
RUN chown -R agentai:agentai /home/agentai

USER agentai
WORKDIR /home/agentai

ENV NVM_DIR=/home/agentai/.nvm \
    PATH="/home/agentai/.opencode/bin:/home/agentai/.local/bin:$PATH" \
    TERM=xterm-256color \
    COLORTERM=truecolor

# Node.js (via nvm, user-local)
RUN mkdir -p /home/agentai/.local/bin \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm alias default lts/* \
    && NODE_DIR="$NVM_DIR/versions/node/$(nvm version default)/bin" \
    && ln -sf "$NODE_DIR/node" /home/agentai/.local/bin/node \
    && ln -sf "$NODE_DIR/npm"  /home/agentai/.local/bin/npm \
    && ln -sf "$NODE_DIR/npx"  /home/agentai/.local/bin/npx

# Claude Code + OpenCode (install to user dirs)
RUN curl -fsSL https://claude.ai/install.sh | bash 
RUN curl -fsSL https://opencode.ai/install | bash 

# basedpyright via uv
RUN uv tool install basedpyright

# Git identity
RUN git config --global user.name "$GIT_USER_NAME" \
    && git config --global user.email "$GIT_USER_EMAIL"

# Neovim config + plugins + Mason LSP servers (last — most volatile)
RUN git clone https://github.com/ptyszkow/nvim /home/agentai/.config/nvim \
    && nvim --headless "+Lazy! sync" +qa \
    && nvim --headless "+MasonInstall lua-language-server" +qa

EXPOSE 5000
WORKDIR /workspace
CMD ["bash"]
