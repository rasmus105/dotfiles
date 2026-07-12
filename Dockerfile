FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    file \
    git \
    procps \
    sudo && \
    rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash dotfiles && \
    echo 'dotfiles ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dotfiles && \
    chmod 0440 /etc/sudoers.d/dotfiles

COPY . /home/dotfiles/dotfiles

RUN chown -R dotfiles:dotfiles /home/dotfiles/dotfiles

USER dotfiles
WORKDIR /home/dotfiles/dotfiles

CMD ["./setup.sh"]
