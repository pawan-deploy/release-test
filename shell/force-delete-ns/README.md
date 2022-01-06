This script is useful when you have a kubernetes namespace stuck in terminating stage. Just run the below commands and your namespace will be deleted forcefully  
Download this script  
```
wget -c https://raw.githubusercontent.com/dheeth/scripts/main/shell/force-delete-ns/force-delete-ns.sh
```
Start kubernetes proxy server  
```
kubectl proxy &
```
Make the script executable  
```
chmod +x force-delete-ns.sh
```
Run the script
```
./force-delete-ns.sh
```
It will show you the list of namespaces in your cluster, enter the name of namespace which is stuck in terminating phase and it will be deleted from your cluster
