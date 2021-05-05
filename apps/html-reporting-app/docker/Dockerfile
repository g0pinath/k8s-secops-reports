FROM mcr.microsoft.com/powershell:latest
RUN mkdir scripts
RUN cd scripts
COPY /scripts /scripts
RUN chmod +x ./scripts/buildscript.sh
RUN chmod +x ./scripts/k8s-secops-reports-launcher.ps1
#Install AZ cli
RUN apt-get update && apt-get upgrade -y
RUN apt install curl -y
RUN apt-get update
RUN apt-get install ca-certificates curl apt-transport-https lsb-release gnupg -y
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
#Known issue, lsb_release isnt there in 20.0 -- cat/etc/os-release to know the codename
#RUN AZ_REPO=focal
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ focal main" | tee /etc/apt/sources.list.d/azure-cli.list
RUN apt-get install azure-cli -y
# Run kubectl
RUN curl -LO https://dl.k8s.io/release/v1.21.0/bin/linux/amd64/kubectl
RUN install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
RUN mkdir -p ~/.local/bin/kubectl
RUN mv ./kubectl ~/.local/bin/kubectl
#ENTRYPOINT ["pwsh", "-c"]
CMD  ["pwsh", "/scripts/k8s-secops-reports-launcher.ps1"]
ENTRYPOINT ["pwsh", "-c"]