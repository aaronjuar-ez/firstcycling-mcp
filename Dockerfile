FROM python:3.12-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends gcc \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml .
COPY firstcycling.py .
COPY FirstCyclingAPI/ ./FirstCyclingAPI/

RUN pip install --no-cache-dir .

# Bake in the mcp-host-fix so Azure/Tailscale Host headers don't 421
RUN SITE=$(python -c "import site; print(site.getsitepackages()[0])") && \
    sed -i 's/default=True,/default=False,/' $SITE/mcp/server/transport_security.py && \
    sed -i 's/enable_dns_rebinding_protection=True,/enable_dns_rebinding_protection=False,/' \
        $SITE/mcp/server/fastmcp/server.py && \
    sed -i 's/allowed_hosts=\["127.0.0.1:\*", "localhost:\*", "\[::1\]:\*"\]/allowed_hosts=["*"]/' \
        $SITE/mcp/server/fastmcp/server.py && \
    find $SITE/mcp -name "*.pyc" -delete

ENV MCP_PORT=8000 \
    LOG_LEVEL=INFO

EXPOSE 8000

CMD ["python", "firstcycling.py"]
