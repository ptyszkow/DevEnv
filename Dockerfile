# syntax=docker/dockerfile:1
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG GIT_USER_NAME=peter
ARG GIT_USER_EMAIL=your-email@example.com

# System packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl unzip xz-utils build-essential git \
    ripgrep fd-find lua5.1 luarocks golang-go \
    pandoc texlive-latex-base texlive-fonts-recommended plantuml \
    jq tidy dotnet-sdk-10.0 \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd

# Node.js (via nvm)
ENV NVM_DIR=/root/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm alias default lts/* \
    && NODE_DIR="$NVM_DIR/versions/node/$(nvm version default)/bin" \
    && ln -sf "$NODE_DIR/node" /usr/local/bin/node \
    && ln -sf "$NODE_DIR/npm" /usr/local/bin/npm \
    && ln -sf "$NODE_DIR/npx" /usr/local/bin/npx

# Neovim, tree-sitter, uv + basedpyright
ENV PATH="/root/.local/bin:$PATH"
RUN curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
    | tar -C /opt -xz \
    && mv /opt/nvim-linux-x86_64 /opt/nvim \
    && ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim \
    && curl -fsSL https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz \
    | gunzip > /usr/local/bin/tree-sitter \
    && chmod +x /usr/local/bin/tree-sitter \
    && curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh \
    && uv tool install basedpyright

# Git identity (rarely changes — good cache boundary)
RUN git config --global user.name "$GIT_USER_NAME" \
    && git config --global user.email "$GIT_USER_EMAIL"

# Neovim config + plugins + Mason LSP servers (last — most volatile)
RUN git clone https://github.com/ptyszkow/nvim /root/.config/nvim \
    && nvim --headless "+Lazy! sync" +qa \
    && nvim --headless "+MasonInstall lua-language-server" +qa

EXPOSE 5000
WORKDIR /home
CMD ["bash"]
