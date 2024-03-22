#
# Docker image to generate deterministic, verifiable builds of Anchor programs.
# This must be run *after* a given ANCHOR_CLI version is published and a git tag
# is released on GitHub.
#
# FROM --platform=linux/amd64 ubuntu:latest
FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive
ARG SOLANA_CLI="v1.18.4"
ARG ANCHOR_CLI="v0.29.0"
ARG NODE_VERSION="v18.16.0"

ENV HOME="/root"
ENV PATH="${HOME}/.cargo/bin:${PATH}"
ENV PATH="${HOME}/.local/share/solana/install/active_release/bin:${PATH}"
ENV PATH="${HOME}/.nvm/versions/node/${NODE_VERSION}/bin:${PATH}"

# Install base utilities.
RUN mkdir -p /workdir && mkdir -p /tmp && \
    apt-get update -qq && apt-get upgrade -qq && apt-get install -qq \
    build-essential git curl wget jq pkg-config python3-pip \
    libssl-dev libudev-dev ca-certificates \
    protobuf-compiler libclang-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install rust.
RUN curl "https://sh.rustup.rs" -sfo rustup.sh && \
    sh rustup.sh -y && \
    rustup component add rustfmt clippy

# Install node / npm / yarn.
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
ENV NVM_DIR="${HOME}/.nvm"
RUN . $NVM_DIR/nvm.sh && \
    nvm install ${NODE_VERSION} && \
    nvm use ${NODE_VERSION} && \
    nvm alias default node && \
    npm install -g yarn




# # Copy the Solana release into the image
# COPY solana-release-v1.71.1-x86_64-apple-darwin.tar.bz2 /tmp/solana-release.tar.bz2

# # Install Solana tools.
# RUN tar -xjf /tmp/solana-release.tar.bz2 -C /usr/local --strip-components 1 && \
#     rm /tmp/solana-release.tar.bz2




# Copy the Solana source code tarball into the image
COPY solana-1.17.1.tar /tmp/solana-source-code.tar

# Unpack the Solana source, build it, and install
RUN tar -xf /tmp/solana-source-code.tar -C /tmp && \
    cd /tmp/solana-* && \
    cargo build --release && \
    cp target/release/solana* /usr/local/bin/ && \
    rm -rf /tmp/solana-* /tmp/solana-source-code.tar



# # Clone the Solana repository
# RUN git clone https://github.com/solana-labs/solana.git /tmp/solana

# # Build Solana from source
# RUN cd /tmp/solana && \
#     git checkout v1.18.4 && \
#     cargo install --path cli && \
#     mv /root/.cargo/bin/solana* /usr/local/bin/



# # Clone the Solana repository
# RUN git clone https://github.com/solana-labs/solana.git /tmp/solana

# # Build Solana from source
# RUN cd /tmp/solana && \
#     git checkout v1.18.4 && \
#     cargo install --path cli --bins


# Install anchor.
RUN cargo install --git https://github.com/coral-xyz/anchor avm --locked --force
RUN avm install 0.29.0
RUN avm use 0.29.0

# Build a dummy program to bootstrap the BPF SDK (doing this speeds up builds).
RUN mkdir -p /tmp && cd tmp && anchor init dummy && cd dummy && \
    echo 'anchor-spl = "0.29.0"' >> ./programs/dummy/Cargo.toml && \
    echo 'winnow = "=0.4.1"' >> ./programs/dummy/Cargo.toml && \
    echo 'toml_datetime = "=0.6.1"' >> ./programs/dummy/Cargo.toml && \
    cargo build
# RUN cd /tmp/dummy && \
#     cargo update -p solana-zk-token-sdk --precise 1.18.6 && \
#     anchor build
# WORKDIR /workdir


# Generate a new keypair for the solana CLI.
RUN mkdir -p ~/.config/solana && \
    solana-keygen new --outfile ~/.config/solana/id.json --no-bip39-passphrase

# Install solana-cargo-build-bpf
# RUN cargo install solana-cargo-build-bpf
