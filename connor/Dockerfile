# syntax=docker/dockerfile:1

FROM resume:latest AS resume

RUN ./cli.js build --public-url /resume/

FROM python:latest

WORKDIR /app

COPY requirements.txt requirements.txt

RUN python -m pip install -r requirements.txt

COPY . .

ENV PATH="/app/.venv/bin:$PATH"

RUN mkdir -p /app/dist/resume/

COPY --link --from=resume /app/dist/ /app/dist/resume/

ENTRYPOINT ["python", "main.py"]
