FROM python:latest

WORKDIR /app

COPY . .

RUN python -m pip install -r requirements.txt

ENV PATH="/app/.venv/bin:$PATH"

COPY --from=resume:latest /dist /dist

ENTRYPOINT ["python", "main.py"]