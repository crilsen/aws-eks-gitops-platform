import os

from fastapi import FastAPI

APP_NAME = "aws-eks-gitops-platform"
APP_VERSION = os.getenv("APP_VERSION", "dev")

app = FastAPI(title=APP_NAME, version=APP_VERSION)


@app.get("/")
def root() -> dict:
    return {"service": APP_NAME, "version": APP_VERSION, "status": "ok"}


@app.get("/health")
def health() -> dict:
    return {"status": "healthy"}
