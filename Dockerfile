ARG PYTHON_VERSION=3.8.8
ARG POETRY_VERSION=1.1.4

FROM python:${PYTHON_VERSION}-slim as python-base

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_VERSION=${POETRY_VERSION} \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv"

ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"

RUN apt-get update \
    && apt-get install --no-install-recommends -y curl build-essential ffmpeg dvipng cm-super libgomp1 chromium-chromedriver && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://raw.githubusercontent.com/sdispater/poetry/master/get-poetry.py | python

WORKDIR $PYSETUP_PATH
COPY poetry.lock pyproject.toml ./
RUN poetry install --no-dev -vvv

FROM python-base as development

ARG NB_USER=auser 
ARG NB_UID=1000

ENV USER ${NB_USER}
ENV HOME /home/${NB_USER}

RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}

WORKDIR $PYSETUP_PATH
COPY --from=python-base $POETRY_HOME $POETRY_HOME
COPY --from=python-base $PYSETUP_PATH $PYSETUP_PATH
RUN poetry install -vvv

USER $NB_UID
ENV XDG_CACHE_HOME="/home/${NB_USER}/.cache/"
# RUN MPLBACKEND=Agg python -c "import matplotlib.pyplot"

WORKDIR ${HOME}
USER ${USER} 