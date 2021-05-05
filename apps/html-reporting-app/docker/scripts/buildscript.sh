


#INSTALL kubectl
apt-get update &&  apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg |  apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" |  tee -a /etc/apt/sources.list.d/kubernetes.list

apt-get install -y kubectl

#Install Az cli
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

apt-get update -y