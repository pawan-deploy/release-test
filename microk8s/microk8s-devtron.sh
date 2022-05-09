#!/bin/bash
echo "===== Installing microk8s ====="
sudo snap install microk8s --channel=$K8S_VERSION/stable --classic
sudo usermod -a -G microk8s $USER
sudo chown -f -R $USER ~/.kube
echo "===== Wait for 10 seconds ====="
sleep 10
echo "===== Enabling DNS Storage and Helm extensions ====="
sudo microk8s enable dns storage helm3
echo "===== Adding devtron repo ====="
sudo microk8s helm3 repo add devtron https://helm.devtron.ai
echo "===== Wait for 10 seconds ====="
sleep 10
echo "===== Installing Devtron ====="
sudo microk8s helm3 install devtron devtron/devtron-operator --create-namespace --namespace devtroncd --set installer.modules={cicd}
echo "===== Adding kubectl and helm to bashrc ====="
echo "alias kubectl='microk8s kubectl '" >> ~/.bashrc
echo "alias helm='microk8s helm3 '" >> ~/.bashrc
source ~/.bashrc
echo "===== Your microk8s and devtron setup is ready ====="
sudo microk8s kubectl get po -n devtroncd
sudo microk8s kubectl patch -n devtroncd svc devtron-service -p '{"spec": {"ports": [{"port": 80,"targetPort": "devtron","protocol": "TCP","name": "devtron","nodePort": 32080}],"type": "NodePort","selector": {"app": "devtron"}}}'
echo "=========="
PUBLIC_IP=$(curl -s ifconfig.io)
echo "Wait for devtron installation to complete and Your devtron will be accessible on http://${PUBLIC_IP}:32080 after that"
echo "=========="
sudo su - $USER
