FROM python:latest

WORKDIR /app

COPY requirements.txt requirements.txt

RUN python -m pip install -r requirements.txt

COPY . .

ENV PATH="/app/.venv/bin:$PATH"

COPY --from=resume:latest /dist /dist

ENTRYPOINT ["python", "main.py"]