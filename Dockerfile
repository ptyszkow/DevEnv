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
    jq tidy dotnet-sdk-10.0 poppler-utils ruby-full \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && curl -fsSL https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o /tmp/chrome.deb \
    && apt-get install -y /tmp/chrome.deb \
    && rm /tmp/chrome.deb \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Node.js LTS (latest, system-wide)
RUN NODE_VERSION=$(curl -fsSL https://nodejs.org/dist/index.json | jq -r '[.[] | select(.lts != false)] | first | .version') \
    && curl -fsSL "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.xz" \
    | tar -xJ -C /usr/local --strip-components=1

# AsciiDoc + Mermaid
RUN gem install asciidoctor asciidoctor-diagram \
    && PUPPETEER_SKIP_DOWNLOAD=true npm install -g @mermaid-js/mermaid-cli

# Neovim, tree-sitter, uv (system-wide)
RUN curl -fsSL https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz \
    | tar -C /opt -xz \
    && mv /opt/nvim-linux-x86_64 /opt/nvim \
    && ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim \
    && curl -fsSL https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz \
    | gunzip > /usr/local/bin/tree-sitter \
    && chmod +x /usr/local/bin/tree-sitter \
    && curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

USER ubuntu
WORKDIR /home/ubuntu

ENV PATH="/home/ubuntu/.opencode/bin:/home/ubuntu/.local/share/uv/bin:/home/ubuntu/.local/bin:$PATH" \
    UV_CACHE_DIR=/home/ubuntu/.cache/uv \
    UV_TOOL_DIR=/home/ubuntu/.local/share/uv/tools \
    UV_PYTHON_INSTALL_DIR=/home/ubuntu/.local/share/uv/python \
    UV_PYTHON_CACHE_DIR=/home/ubuntu/.cache/uv/python \
    UV_TOOL_BIN_DIR=/home/ubuntu/.local/share/uv/bin \
    UV_LINK_MODE=copy \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable \
    TERM=xterm-256color \
    COLORTERM=truecolor

# Chrome sandbox config for rootless Podman
RUN mkdir -p "$HOME/.config/puppeteer" \
    && echo 'module.exports = { args: ["--no-sandbox"] };' > "$HOME/.config/puppeteer/puppeteer.config.cjs"

ARG GIT_USER_NAME
ARG GIT_USER_EMAIL

# Claude Code + OpenCode (binaries baked in image, state persisted via volumes)
RUN curl -fsSL https://claude.ai/install.sh | bash
RUN curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path

# basedpyright
RUN uv tool install basedpyright

# Git config
RUN git config --global user.name "$GIT_USER_NAME" \
    && git config --global user.email "$GIT_USER_EMAIL" \
    && git config --global --add safe.directory '*'

# Neovim config + plugins (most volatile — last)
RUN git clone https://github.com/ptyszkow/nvim "$HOME/.config/nvim" \
    && nvim --headless "+Lazy! sync" +qa \
    && nvim --headless "+MasonInstall lua-language-server" +qa

WORKDIR /home/ubuntu/Projects
CMD ["bash"]
