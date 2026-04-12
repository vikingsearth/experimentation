FROM python:3.12-slim

RUN pip install uv

WORKDIR /app

COPY pyproject.toml .
RUN uv sync --no-dev

COPY agents.py main.py ./

EXPOSE 3051

CMD ["uv", "run", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "3051"]
