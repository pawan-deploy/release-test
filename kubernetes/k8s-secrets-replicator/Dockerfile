FROM python:slim-buster

RUN pip install kubernetes

WORKDIR /

COPY secrets-replicator.py .

CMD ["python3", "-m", "secrets-replicator"]
