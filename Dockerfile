FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

WORKDIR /usr/local/src

COPY Replace.Certification Replace.Certification
COPY Replace.Common Replace.Common
COPY Replace.Certification.sln .

RUN --mount=type=cache,target=/root/.nuget/packages \
    dotnet restore Replace.Certification.sln

RUN --mount=type=cache,target=/root/.nuget/packages \
    dotnet publish Replace.Certification.sln --configuration Release --property WarningLevel=0

FROM mcr.microsoft.com/dotnet/runtime:8.0 AS final

ENV USERNAME=certification
ENV GROUPNAME=certification
ENV WORKDIR=/usr/local/bin/certification

ENV ACCOUNT_DATABASE_HOST=
ENV ACCOUNT_DATABASE_PORT=1433
ENV ACCOUNT_DATABASE_USER=sa
ENV ACCOUNT_DATABASE_PASSWORD=
ENV ACCOUNT_DATABASE_NAME=SRO_VT_ACCOUNT

ENV BILLING_IP=
ENV BILLING_PORT=8080

ENV CERTIFICATION_DATABASE_HOST=
ENV CERTIFICATION_DATABASE_PORT=1433
ENV CERTIFICATION_DATABASE_USER=sa
ENV CERTIFICATION_DATABASE_PASSWORD=
ENV CERTIFICATION_DATABASE_NAME=SRO_CERTIFICATION

ENV WHITELIST_HOST=localhost
ENV WHITELIST_IP=0.0.0.0

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get --no-install-recommends install -y \
        # gettext is needed for envsubst
        gettext \
        # net-tools is needed for netstat
        net-tools \
    && rm -rf /var/lib/apt/lists/*

WORKDIR ${WORKDIR}

COPY --from=build /usr/local/src/Replace.Certification/bin/Release/net8.0/publish .

COPY --chmod=655 docker/docker-entrypoint.sh .
COPY --chmod=655 docker/healthcheck.sh .

RUN groupadd --system ${GROUPNAME} \
    && useradd --no-log-init --system --gid ${GROUPNAME} ${USERNAME} \
    && chown ${USERNAME}:${GROUPNAME} ${WORKDIR}/Config

USER ${USERNAME}

EXPOSE 32000
EXPOSE ${BILLING_PORT}

HEALTHCHECK --interval=10s --timeout=30s --start-period=180s --retries=3 CMD [ "./healthcheck.sh" ]

ENTRYPOINT [ "./docker-entrypoint.sh" ]
