FROM python:3.12.3-slim

RUN apt-get update && apt-get install -y default-jre && apt-get clean

WORKDIR /project-parallelcomputing-distributed

CMD ["sh", "-c", "\
    python3 -m venv .venv && \
    . .venv/bin/activate && \
    pip install --upgrade pip && \
    pip install pyspark numpy pandas findspark joblib scikit-learn ipykernel]