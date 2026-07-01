FROM ollama/ollama:latest

LABEL maintainer="TechCorp Industries Hackathon" \
      description="Phi-3.5-Financial LLM Inference Server" \
      version="1.0.0"

ENV OLLAMA_HOST=0.0.0.0:11434 \
    OLLAMA_NUM_PARALLEL=4 \
    OLLAMA_NUM_THREAD=8

# Install curl for health checks and scripts
RUN apt-get update && apt-get install -y --no-install-recommends curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

EXPOSE 11434

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:11434/api/tags || exit 1

# Note: Modelfile and init-model.sh are mounted via docker-compose volumes
# The actual model initialization happens when the container starts
CMD ["ollama", "serve"]
