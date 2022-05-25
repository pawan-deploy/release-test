## K8s Secrets Sync

This sync-service syncs all your secrets of type `kubernetes.io/tls` or `kubernetes.io/dockerconfigjson` from one particular namespace to all other namespaces in a kubernetes cluster.

## Features

- It gets data of all secrets of both the above types mentioned from the namespace and syncs them to other namespaces
- When a new secret of the same type is added in the given namespace, it automatically syncs it's data to other namespaces
- It watches for modifications in any of the secret of that type in given namespace and if any changes are there, it syncs those secrets automatically
- If a new namespace is created, it automatically creates existing secrets of that type in new namespace

## Usage
```
wget https://raw.githubusercontent.com/dheeth/scripts/main/kubernetes/k8s-secrets-sync/secrets-sync.py
```
If using it from outside the cluster, edit `secrets-sync.py` file and replace `config.load_incluster_config()` with `config.load_kube_config()`
```
export EXCLUDE_NAMESPACES=['test','test2']
export SECRETS_NAMESPACE="test-secret"
export SECRET_TYPE="kubernetes.io/tls"
```
EXCLUDE_NAMESPACES - To exclude namespaces from syncing secrets  
SECRETS_NAMESPACE - Namespace in which to look for secrets  
SECRET_TYPE - Type of secrets to sync, currently supported `kubernetes.io/tls` and `kubernetes.io/dockerconfigjson` only

Remember not to give spaces in EXCLUDE_NAMESPACES as it may break and may not even work
```
python3 -m secrets-sync
```

## Use case scenarios

1. **Using certmanager to issue wildcard certificates for many domains** - Certificates will be issued in one namespace but you want to use them on ingresses in any namespace. You can use this secrets-sync service there

2. **Using imagePullSecrets for deployments in kubernetes clusters** - Create the secrets in one namespace and use this to automatically sync to other namespaces

## Limitations

- Type `Opaque` is not supported still
- It doesn't sync the annotations or labels on those secrets, but syncs only the data
- No support to exclude secrets or sync only particular secrets
