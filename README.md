# IoT Edge Proxy Lab

This lab is designed to demonstrate how to use the [IoT Edge Hub Proxy](https://github.com/Azure/iotedge/blob/main/edge-modules/edgehub-proxy/README.md) module to limit the version of TLS as well as cipher suites supported by the edge device endpoints.

## Setup environment


## Build Edge Hub Proxy module

### Clone repo

```bash	
git clone https://github.com/Azure/iotedge.git
```

### Change settings

Modify `iotedge/edge-modules/edgehub-proxy/haproxy.cfg` with desired configuration and save the file:
- Modify the ssl-default-bind-options entry.
- Modify the ssl-default-bind-ciphers entry.

Check options:
- https://www.haproxy.com/documentation/haproxy-configuration-tutorials/ssl-tls/client-side-encryption/#set-the-tls-ciphers
- https://www.haproxy.com/documentation/haproxy-configuration-manual/latest/#ssl-default-bind-ciphers
- https://ssl-config.mozilla.org/#server=haproxy&version=1.8&config=intermediate&openssl=3.4.0&guideline=5.7

### Build image

```bash
cd iotedge
cp ../build/* .
docker build -t edge-hub-builder .
docker create --name dummy_edge-hub-builder edge-hub-builder
docker cp dummy_edge-hub-builder:/usr/src/edge-modules/edgehub-proxy/target/release/edgehub-proxy .
docker rm -f dummy_edge-hub-builder
```

## Add proxy to IoT Edge deployment

1. Remove the entire PortBindings section from the HostConfig section of IoT Edge Hub's Container Create Options.

2. Add the previously built proxy module to the deployment, with the following Container Create Options:

    ```json
    {
        "HostConfig": {
            "PortBindings": {
                "443/tcp": [
                    {
                        "HostPort": "443"
                    }
                ],
                "5671/tcp": [
                    {
                        "HostPort": "5671"
                    }
                ],
                "8883/tcp": [
                    {
                        "HostPort": "8883"
                    }
                ]
            }
        }
    }
    ```

## Testing

You can use the `openssl s_client` command to test TLS versions and cipher suites exposed by the IoT Edge device (via the proxy module). Here is an [example](https://www.feistyduck.com/library/openssl-cookbook/online/ch-testing-with-openssl.html#testing-protocol-support).