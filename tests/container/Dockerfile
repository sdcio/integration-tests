FROM golang:1.20.5 as builderCache
COPY repos/cache/go.mod repos/cache/go.sum /build/
WORKDIR /build
RUN --mount=type=cache,target=/root/.cache/go-build \
    go mod download
ADD repos/cache /build
RUN --mount=type=cache,target=/root/.cache/go-build \
    make build

FROM golang:1.20.5 as builderData
COPY repos/data/go.mod repos/data/go.sum /build/
WORKDIR /build
RUN --mount=type=cache,target=/root/.cache/go-build \
    go mod download
ADD repos/data /build
RUN --mount=type=cache,target=/root/.cache/go-build \
    make build

FROM golang:1.20.5 as builderSchema
COPY repos/schema/go.mod repos/schema/go.sum /build/
WORKDIR /build
RUN --mount=type=cache,target=/root/.cache/go-build \
    go mod download
ADD repos/schema /build
RUN --mount=type=cache,target=/root/.cache/go-build \
    make build

FROM alpine
WORKDIR /app
ADD ./tests/robot/requirements.txt /build
RUN --mount=type=cache,target=/root/.cache \
    apk add py3-pip gcompat ;\
    pip3 install -r /build/requirements.txt
COPY --from=builderCache /build/bin/* /app/bin/
COPY --from=builderData /build/bin/* /app/bin/
COPY --from=builderSchema /build/bin/* /app/bin/