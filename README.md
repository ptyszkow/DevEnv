# Dev Work Container (Podman)

Ubuntu-based dev container with:

- ripgrep, fd (`fdfind` + `fd` symlink)
- Neovim latest (validated `>= 0.11`)
- .NET SDK 10 (installed via Ubuntu `apt`)
- Node.js LTS + npm (via nvm v0.40.4)
- tree-sitter (prebuilt binary)
- `uv` + `basedpyright`
- pandoc, plantuml
- lua5.1, luarocks
- Go, git

Also mounts your projects into the container under the home directory and keeps CLI auth plus `uv` cache/tool data in one named volume.

## .NET 10

The container ships with **.NET SDK 10** from the Ubuntu `apt` feed (`dotnet-sdk-10.0`).

### Verify inside the container

```bash
dotnet --info
```

### Create a new project

```bash
# Console app
dotnet new console -n MyApp

# Web API (minimal API)
dotnet new webapi -n MyApi

# Blazor
dotnet new blazor -n MyBlazor

# Class library
dotnet new classlib -n MyLib
```

### Build and run

```bash
dotnet build
dotnet run
```

Port `5000` is already exposed by the container, so you can target it for web projects:

```bash
dotnet run --urls http://0.0.0.0:5000
```

### NuGet packages

```bash
dotnet add package Newtonsoft.Json
dotnet add package Dapper
```

### Testing

```bash
dotnet new xunit -n MyApp.Tests
dotnet test
```

### Useful global tools

```bash
dotnet tool install -g dotnet-ef          # Entity Framework CLI
dotnet tool install -g dotnet-outdated    # check for outdated packages
dotnet tool install -g dotnet-format      # code formatter
```

After installing global tools, make sure `~/.dotnet/tools` is on your PATH (it should be by default).

## Prerequisites

- Podman installed
- `podman compose` available

## Start

From this directory:

```bash
podman compose up -d --build
```

## Attach to the running container

```bash
podman exec -it dev bash
```

## Stop

```bash
podman compose down
```

## Volumes and ports

- Host `${HOME}/Projects` -> Container `/home/ubuntu/Projects`
- Named volume `dev-data` -> Container `/data`
- Symlink `/home/ubuntu/.claude` -> `/data/claude`
- Symlink `/home/ubuntu/.local/share/opencode` -> `/data/opencode`
- Symlink `/home/ubuntu/.cache/uv` -> `/data/uv/cache`
- Symlink `/home/ubuntu/.local/share/uv` -> `/data/uv/data`
- Container port `5000` exposed to host `5001`
- Container port `1455` exposed to host `1455`
- Container port `4096` exposed to host `4096`

## Git user/email inside container

Git identity is set directly in the image build.
Current values:

- `user.name = peter`
- `user.email = your-email@example.com`

Check inside container:

```bash
podman exec -it dev git config --global --list
```
