from kubernetes import client, config, watch
from kubernetes.client.exceptions import ApiException
import os, threading

# Configs can be set in Configuration class directly or using helper utility
config.load_incluster_config()
v1 = client.CoreV1Api()
w = watch.Watch()

# Get All Namespaces in cluster

all_namespaces = []
exclude_namespaces = os.getenv('EXCLUDE_NAMESPACES', [])
print("Excluded Namespaces:")
print(exclude_namespaces)
namespace_env = os.getenv('SECRETS_NAMESPACE', "devtroncd")
print("Namespace to sync secrets from: " + namespace_env)
secret_type = os.getenv('SECRET_TYPE', "kubernetes.io/tls")
print("Secret type to sync: " + secret_type)

def get_all_namespaces():
    namespaces = v1.list_namespace()
    for i in namespaces.items:
        if i.metadata.name != namespace_env and i.metadata.name not in exclude_namespaces:
            all_namespaces.append(str(i.metadata.name))
    print("\nNamespaces Found:")
    print(all_namespaces)

get_all_namespaces()

# Create TLS secret to sync to new namespaces
def createSecret(name, namespace, cert=None, key=None, config=None):

    if secret_type == "kubernetes.io/tls":
        secret_data = {
            "kind": "Secret",
            "apiVersion": "v1",
            "metadata": {
                "name": name,
                "labels": {
                    "managed-by": "secrets-replicator",
                },
            },
            "type": "kubernetes.io/tls",
            "data": {
                "tls.crt": cert,
                "tls.key": key,
            },
        }
    
    else:
        secret_data = {
            "kind": "Secret",
            "apiVersion": "v1",
            "metadata": {
                "name": name,
                "labels": {
                    "managed-by": "secrets-replicator",
                },
            },
            "type": "kubernetes.io/dockerconfigjson",
            "data": {
                ".dockerconfigjson": config
            },
        }

    v1.create_namespaced_secret(body=secret_data, namespace=namespace)
    print("Created secret %s in namespace %s" % (name, namespace))

# Sync secret to namespaces
def syncSecret(name, cert=None, key=None, config=None):
    if secret_type == "kubernetes.io/tls":
        secret_data = {
            "kind": "Secret",
            "apiVersion": "v1",
            "metadata": {
                "name": name,
                "labels": {
                    "managed-by": "secrets-replicator",
                },
            },
            "type": "kubernetes.io/tls",
            "data": {
                "tls.crt": cert,
                "tls.key": key,
            },
        }
    
    else:
        secret_data = {
            "kind": "Secret",
            "apiVersion": "v1",
            "metadata": {
                "name": name,
                "labels": {
                    "managed-by": "secrets-replicator",
                },
            },
            "type": "kubernetes.io/dockerconfigjson",
            "data": {
                ".dockerconfigjson": config
            },
        }

    for namespace in all_namespaces:
        try:
            v1.patch_namespaced_secret(name=name, body=secret_data, namespace=namespace)
            print("Secret %s patched successfully in namespace %s" % (name, namespace))
        except ApiException as e:
            if e.status == 404:
                v1.create_namespaced_secret(body=secret_data, namespace=namespace)
                print("Secret %s was not present, created successfully in namespace %s" % (name, namespace))

# Start secrets first time sync and sync on new secret add event
all_secrets = []
def add_secrets():
    for event in w.stream(v1.list_namespaced_secret, namespace=namespace_env, field_selector="type=%s" % (secret_type)):
        if event['type'] == "ADDED" and secret_type == "kubernetes.io/tls":
            print("\nGot a new secret %s, syncing it to all namespaces\n" % (event['object'].metadata.name))
            name = event['object'].metadata.name
            cert = event['object'].data['tls.crt']
            key = event['object'].data['tls.key']
            all_secrets.append(event['object'].metadata.name)
            syncSecret(name=name, cert=cert, key=key)
        elif event['type'] == "ADDED" and secret_type == "kubernetes.io/dockerconfigjson":
            print("\nGot a new secret %s, syncing it to all namespaces\n" % (event['object'].metadata.name))
            name = event['object'].metadata.name
            config = event['object'].data['.dockerconfigjson']
            all_secrets.append(event['object'].metadata.name)
            syncSecret(name=name, config=config)

# Check for secrets getting modified
def modify_secrets():
    for event in w.stream(v1.list_namespaced_secret, namespace=namespace_env, field_selector="type=%s" % (secret_type)):
        if event['type'] == "MODIFIED" and secret_type == "kubernetes.io/tls":
            print("\nSecret %s changed, syncing it to all namespaces\n" % (event['object'].metadata.name))
            name = event['object'].metadata.name
            cert = event['object'].data['tls.crt']
            key = event['object'].data['tls.key']
            all_secrets.append(event['object'].metadata.name)
            syncSecret(name=name, cert=cert, key=key)
        elif event['type'] == "MODIFIED" and secret_type == "kubernetes.io/dockerconfigjson":
            print("\nSecret %s changed, syncing it to all namespaces\n" % (event['object'].metadata.name))
            name = event['object'].metadata.name
            config = event['object'].data['.dockerconfigjson']
            all_secrets.append(event['object'].metadata.name)
            syncSecret(name=name, config=config)

# Sync secrets to new namespace whenever a new namespace is added
def watch_namespaces():
    # global tls_secrets
    for event in w.stream(v1.list_namespace):
        if event['type'] == "ADDED":
            added_namespace = event['object'].metadata.name
            if added_namespace in all_namespaces or added_namespace == namespace_env or added_namespace in exclude_namespaces:
                pass
            else:
                print("\nNew namespace %s added, syncing all tls secrets to this namespace\n" % (added_namespace))
                all_namespaces.append(added_namespace)
                print("Updated namespaces:")
                print(all_namespaces)
                print("\nSecrets to sync:")
                print(all_secrets)
                if secret_type == "kubernetes.io/tls":
                    for secret in all_secrets:
                        secretData = v1.read_namespaced_secret(name=secret, namespace=namespace_env).data
                        cert = secretData["tls.crt"]
                        key = secretData["tls.key"]
                        createSecret(name=secret, namespace=added_namespace, cert=cert, key=key)
                elif secret_type == "kubernetes.io/dockerconfigjson":
                    for secret in all_secrets:
                        secretData = v1.read_namespaced_secret(name=secret, namespace=namespace_env).data
                        config = secretData[".dockerconfigjson"]
                        createSecret(name=secret, namespace=added_namespace, config=config)
        elif event['type'] == "DELETED":
            deleted_namespace = event['object'].metadata.name
            all_namespaces.remove(deleted_namespace)

if __name__ == '__main__':
    add_thread = threading.Thread(target=add_secrets)
    modify_thread = threading.Thread(target=modify_secrets)
    ns_thread = threading.Thread(target=watch_namespaces)
    add_thread.start()
    modify_thread.start()
    ns_thread.start()
