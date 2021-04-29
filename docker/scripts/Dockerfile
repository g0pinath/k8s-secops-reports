FROM mcr.microsoft.com/powershell:latest
RUN mkdir scripts
RUN cd scripts

COPY /scripts /scripts
RUN chmod +x ./scripts/buildscript.sh
RUN chmod +x ./scripts/k8s-secops-reports-launcher.ps1
RUN  /scripts/buildscript.sh
#ENTRYPOINT ["pwsh", "-c"]
CMD  ["pwsh", "/scripts/k8s-secops-reports-launcher.ps1"]
ENTRYPOINT ["pwsh", "-c"]