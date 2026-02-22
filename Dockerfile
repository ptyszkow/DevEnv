FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    unzip \
    xz-utils \
    build-essential \
    git \
    ripgrep \
    fd-find \
    lua5.1 \
    luarocks \
    golang-go \
    pandoc \
    texlive-latex-base \
    texlive-fonts-recommended \
    plantuml \
    jq \
    tidy \
    dotnet-sdk-10.0 \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

ENV NVM_DIR=/root/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm alias default lts/* \
    && NODE_DIR="$NVM_DIR/versions/node/$(nvm version default)/bin" \
    && ln -sf "$NODE_DIR/node" /usr/local/bin/node \
    && ln -sf "$NODE_DIR/npm" /usr/local/bin/npm \
    && ln -sf "$NODE_DIR/npx" /usr/local/bin/npx

RUN curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz -o /tmp/nvim.tar.gz \
    && tar -C /opt -xzf /tmp/nvim.tar.gz \
    && mv /opt/nvim-linux-x86_64 /opt/nvim \
    && ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim \
    && rm /tmp/nvim.tar.gz \
    && nvim --version | head -n 1 | grep -E 'NVIM v0\.(11|12|13|14|15|16|17|18|19|[2-9][0-9])\.'

RUN curl -fsSL https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz \
    | gunzip > /usr/local/bin/tree-sitter \
    && chmod +x /usr/local/bin/tree-sitter

ENV PATH="/root/.local/bin:$PATH"

RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh \
    && uv tool install basedpyright

RUN git config --global user.name "peter" \
    && git config --global user.email "your-email@example.com"

RUN git clone https://github.com/ptyszkow/nvim /root/.config/nvim
# alternative: map nvim config as a volume in docker-compose.yml instead of cloning

EXPOSE 5000

WORKDIR /home

CMD ["bash"]
