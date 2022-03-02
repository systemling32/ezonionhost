# Easy Onion host

This Docker image can help you reach local services over a TOR hidden service without any effort of setting up hidden services and fiddeling with a tor config.
This image compiles tor from source, automatically configures the torrc config for you and starts the tor daemon with that config.
## Usage:

To use the Docker image you first have to build it as usual by cloning the repo and executing
`docker build .` inside of the folder containing the Dockerfile.

Afterwards you can start a container with the following parameters:

- To have the container expose a Socks5 proxy into TOR on container port 9050, pass the environment variable `-e PROXY="True"`
    and forward the Socks5 port from the container the your host with `-p 9050:9050`
- To configure services to be made reachable over TOR, configure them in the HOSTS environment variable like:
    `-e HOSTS="webserver=80:127.0.0.1:80,bitcoin=8333:bitcoind:8333"`

`docker run -d --name onion-proxy -v <absolute-path>:/tor -e PROXY="True" -e HOSTS="webserver=80:127.0.0.1:80" -p 9050:9050 ezonionhost`

Several hosts can be comma seperated in the HOSTS env to look like this: "servicename1=onionpor1t:host1:port1,servicename2=onionport2:host2:port2".

Suppose you have a webserver running on port 80 of your server as well as REST API on port 3000 inside of a container named *api*.
You could create two seperate onion services with two distinct onion addresses to serve these two hosts over TOR.
To do that, simply pass all desired hosts inside the HOSTs env in the format of "servicename=onionport:host:port".

- **servicename** is just to differentiate the different services. The container will create folders at /tor/services/*servicename* inside of which you can find the private keys of the service, as well as the *hostname* file containing the .onion address under which you can reach your service.
- **onionport** is the port over which you want to reach the hidden service on the TOR network. You could have multiple services all running on onionport 80 as they have distinct .onion addresses. *Under normal circumstances you should probably use the same port as on your server.*
- **host** IP/host/container to which the onion requests should be forwarded. Could be 127.0.0.1 for localhost, or web\_apache\_1 as a ficticious container name. *Make sure the ezonionhost container is in the correct network to reach the host under the given hostname/IP.*
- **port** which port on the host do you want to make available through the TOR network? *Could be a common port 80 for a webserver.*

I recommend mounting the /tor/ directory from inside the container to some path on your host. Inside of that folder you will find the .onion addresses that you need to reach your hosts over TOR. Especially useful if you want to keep the same .onion domain across restarts.

You can also use the image inside of a docker-compose.yaml file:

``` bash
version: "3.7"
services:
  tor:
    container_name: onion-proxy
    image: systemling32/ezonionhost
    environment:
      PROXY: 'True'
      HOSTS: 'webserver=80:127.0.0.1:80,bitcoin=8333:bitcoind:8333'
    volumes:
      - ${PWD}:/tor/
    ports:
      - "9050:9050/tcp"
    restart: unless-stopped
```
## Credits

Most of the Dockerfile code is copied from [BarneyBuffet/docker-tor](https://github.com/BarneyBuffet/docker-tor). Many thanks for the awesome work!
Please check out his github.

Also check out the [TOR Project](https://torproject.org) and consider supporting them by donating or running a node in order to strengthen the network.

If you want to donate directly to me, I happily accept Bitcoin Lightning Tips at the following lightning address: systemling32@ln.tips
