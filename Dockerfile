FROM python:3.11-slim as python-base

    # python
ENV PYTHONUNBUFFERED=1 \
    # prevents python creating .pyc files
    PYTHONDONTWRITEBYTECODE=1 \
    \
    # pip
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    \
    # poetry
    # https://python-poetry.org/docs/configuration/#using-environment-variables
    POETRY_VERSION=1.5.1 \
    # make poetry install to this location
    POETRY_HOME="/opt/poetry" \
    # do not ask any interactive question
    POETRY_NO_INTERACTION=1 \
    # paths
    # app code lives here
    APP_DIR="/app"


# prepend poetry home to path
ENV PATH="$POETRY_HOME/bin:$PATH"

FROM python-base as builder-base

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        # deps for building python deps
        build-essential \
        curl && curl -sSL https://install.python-poetry.org | python3 -


# copy project requirement files here to ensure they will be cached.
WORKDIR $APP_DIR

COPY pyproject.toml* poetry.lock* ./
 
# prevent poetry creating a new venv.
RUN poetry config virtualenvs.create false
RUN if [ -f pyproject.toml ]; then poetry install --no-root --without dev; fi


# `development` image is used during development / testing
FROM builder-base as development
ENV FASTAPI_ENV=development
WORKDIR $APP_DIR

# copy in our built poetry
COPY --from=builder-base $POETRY_HOME $POETRY_HOME

# quicker install as runtime deps are already installed
RUN if [ -f pyproject.toml ]; then poetry install --no-root ; fi

CMD ["poetry", "run", "streamlit", "run", "main.py"]

# `production` image used for runtime
FROM python-base as production
WORKDIR $APP_DIR
COPY ./ /app/
RUN if [ -f .env ]; then rm .env ; fi
RUN if [ -f requirements.txt ]; then python3 -m pip install -r requirements.txt ; fi
CMD ["streamlit", "run", "main.py", "--server.port", "8080"]