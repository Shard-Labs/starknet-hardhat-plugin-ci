FROM python:3.9.13-alpine3.16 AS compiler

ARG SCARB_VERSION

RUN apk add git musl-dev curl

# Install scarb
# doesn't work with /bin/sh and bash is not available by default
ARG SHELL=/bin/ash
RUN curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | $SHELL -s -- -v $SCARB_VERSION

ARG COMPILER_BINARY_URL
ARG CAIRO_COMPILER_ASSET_NAME

# Download cairo1 compiler
RUN curl --location -O --request GET $COMPILER_BINARY_URL
RUN tar -zxvf $CAIRO_COMPILER_ASSET_NAME

# Install cairo-lang
FROM python:3.9.13-alpine3.16 as cairo-lang

COPY requirements.txt .

RUN apk add gmp-dev g++ gcc

ARG CAIRO_VERSION
ARG OZ_VERSION

RUN pip wheel --no-cache-dir --no-deps\
    --wheel-dir /wheels\
    -r requirements.txt\
    cairo-lang==$CAIRO_VERSION openzeppelin-cairo-contracts==$OZ_VERSION

# Final image
FROM python:3.9.13-alpine3.16

ARG SCARB_VERSION

RUN apk add --no-cache libgmpxx

COPY --from=cairo-lang /wheels /wheels

COPY --from=compiler /cairo /usr/local/bin/cairo
COPY --from=compiler /root/.local/share/scarb-install/${SCARB_VERSION}/bin/scarb /usr/local/bin/scarb

RUN pip install --no-cache /wheels/*

RUN rm -rf /wheels
