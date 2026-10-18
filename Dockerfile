# Blender MCP lab (spike, 18 Oct 2026): Blender 5.2.2 LTS + mcp-for-blender 2.1.9 on Debian 12, with a virtual
# display (Xvfb) so Blender runs with its normal window and can be screen-recorded (ffmpeg x11grab).
# Nothing is installed on the Windows host.
FROM debian:12-slim
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl xz-utils python3 xvfb xauth x11-utils xdotool ffmpeg \
      libxi6 libxxf86vm1 libxfixes3 libxrender1 libxkbcommon0 libsm6 libgl1 libegl1 libglu1-mesa libx11-6 \
      libxkbcommon-x11-0 libwayland-client0 libwayland-cursor0 libwayland-egl1 libdbus-1-3 \
      fonts-dejavu-core \
 && rm -rf /var/lib/apt/lists/*
# Blender 5.2.2 LTS, the official Linux build, checked against Blender's published SHA-256 list.
WORKDIR /opt
RUN curl -fsSLO https://download.blender.org/release/Blender5.2/blender-5.2.2-linux-x64.tar.xz \
 && curl -fsSL https://download.blender.org/release/Blender5.2/blender-5.2.2.sha256 | grep 'linux-x64.tar.xz' > sums \
 && sha256sum -c sums \
 && tar xf blender-5.2.2-linux-x64.tar.xz && rm blender-5.2.2-linux-x64.tar.xz sums \
 && ln -s /opt/blender-5.2.2-linux-x64/blender /usr/local/bin/blender
# uv (official installer, pinned version) and the MCP server, pinned.
ENV UV_INSTALL_DIR=/usr/local/bin
RUN curl -LsSf https://astral.sh/uv/0.9.2/install.sh | sh && uv --version
RUN uv tool install mcp-for-blender==2.1.9 && ln -s /root/.local/bin/mcp-for-blender /usr/local/bin/mcp-for-blender 2>/dev/null; \
    ls /root/.local/bin
# Claude Code, the same version as on the owner's PC (official installer, pinned). It signs in with the owner's
# subscription token from the git-ignored .env (CLAUDE_CODE_OAUTH_TOKEN), passed at run time, never baked in.
RUN curl -fsSL https://claude.ai/install.sh | bash -s 2.1.302 && ln -sf /root/.local/bin/claude /usr/local/bin/claude && claude --version
WORKDIR /work
