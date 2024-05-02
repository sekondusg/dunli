ARG PYTHON_VERSION=3.12
 FROM python:${PYTHON_VERSION}-bookworm as base
#FROM quay.io/jupyter/base-notebook as base

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED=1

# For bind mounted volumes from the host OS, align the guest/host account IDs for sharing
ARG USER=cyrk
ARG PROJ=UGrainium
ARG HOST_UID=1024
ARG HOST_GID=1024
RUN groupadd -g ${HOST_GID} ${USER}
RUN useradd -u ${HOST_UID} -g ${HOST_GID} -d /home/${USER} -c "${PROJ}" -ms /bin/sh ${USER}

# Add OS level dependencies
#RUN apk add --no-cache gcc g++ musl-dev linux-headers git

# Download dependencies as a separate step to take advantage of Docker's caching.
# Leverage a cache mount to /root/.cache/pip to speed up subsequent builds.
# Leverage a bind mount to requirements.txt to avoid having to copy them into
# into this layer.
USER ${USER}
WORKDIR /home/${USER}

RUN --mount=type=cache,target=/home/${USER}/.cache/pip \
    --mount=type=bind,source=requirements.txt,target=requirements.txt \
    pip install -r requirements.txt

ENV PATH=${PATH}:/home/${USER}/.local/bin
WORKDIR /vol/${PROJ}
ENV PYTHONPATH=/vol/${PROJ}:.

ENTRYPOINT exec jupyter lab --notebook-dir=/vol/${PROJ} --port=8008 --ip=0.0.0.0 --no-browser --allow-root --NotebookApp.token=ugrainium --NotebookApp.password=ugrainium
