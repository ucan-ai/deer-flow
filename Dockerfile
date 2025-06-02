FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# Install uv.
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

WORKDIR /app

# Copy dependency files and install dependencies (no BuildKit mounts)
COPY uv.lock pyproject.toml ./
RUN uv sync --locked --no-install-project

# Copy the application into the container.
COPY . /app

# Debug: List files and print conf.yaml
RUN ls -l /app && cat /app/conf.yaml

# Install the application dependencies.
RUN uv sync --locked

EXPOSE 8000

# Run the application.
CMD ["uv", "run", "python", "server.py", "--host", "0.0.0.0", "--port", "8000"]
