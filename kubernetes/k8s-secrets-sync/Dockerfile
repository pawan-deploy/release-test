FROM python:slim-buster

MAINTAINER dheeth@stayhome.li

RUN pip install kubernetes

WORKDIR /

COPY kubernetes/k8s-secrets-sync/secrets-sync.py .

CMD ["python3", "-m", "secrets-sync"]
