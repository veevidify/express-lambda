FROM alpine:3.16

RUN wget https://releases.hashicorp.com/terraform/1.2.5/terraform_1.2.5_linux_amd64.zip
RUN unzip terraform_1.2.5_linux_amd64.zip && rm terraform_1.2.5_linux_amd64.zip
RUN mv terraform /usr/bin/terraform

COPY . /app

WORKDIR /app/terraform

ENV USER=deployer
ENV UID=1000
ENV GID=1000

RUN mkdir /home/deployer && adduser \
    --disabled-password \
    --gecos "" \
    --home /home/deployer \
    --uid "$UID" \
    "$USER"

USER deployer
CMD terraform
