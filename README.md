# IoT Edge Proxy Lab

This lab is designed to demonstrate how to use the [IoT Edge Hub Proxy](https://github.com/Azure/iotedge/blob/main/edge-modules/edgehub-proxy/README.md) module to limit the version of TLS as well as cipher suites supported by the edge device endpoints.

## Setup environment

If you need to create first a new Azure environment with an IoT Hub and an IoT Edge device, you can use the provided script `azure/create-azure-env.sh`, otherwise you can skip this step.
Just copy the `sample.env` to a file named `.env`, fill the required values and run `./create-azure-env.sh`.

```bash
cd azure
cp sample.env .env

# customize the values in .env

./create-azure-env.sh
```

## Prepare Edge Hub Proxy module

### Clone repo

```bash	
git clone https://github.com/Azure/iotedge.git
```

### Change settings for TLS and Ciphers

Modify `iotedge/edge-modules/edgehub-proxy/haproxy.cfg` the with desired configuration entries and save the file:
- Modify the ssl-default-bind-options entry.
- Modify the ssl-default-bind-ciphers entry.

You can use this [configurator](https://ssl-config.mozilla.org/#server=haproxy&version=1.8&config=intermediate&openssl=3.4.0&guideline=5.7) to help you with the configuration.

### Build image

```bash
cp build/buildv2.sh iotedge/edge-modules/edgehub-proxy/
./iotedge/edge-modules/edgehub-proxy/buildv2.sh -i eh-proxy -t x86_64
```

### Push image to container registry

Replace with your container registry name:

```bash
docker tag eh-proxy:latest <container-registry-name>.azurecr.io/eh-proxy:latest
docker push <container-registry-name>.azurecr.io/eh-proxy:latest
```

## Add proxy to IoT Edge deployment

1. Remove the entire `PortBindings` section from the `HostConfig` section of IoT Edge Hub's `Container Create Options`.

2. Add the previously built proxy module to the deployment, with the following `Container Create Options`:

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
