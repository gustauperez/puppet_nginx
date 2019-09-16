# Puppet nginx configuration

```
Create/extend an existing puppet module for Nginx including the following functionalities:

- Create a proxy to redirect requests for https://domain.com to 10.10.10.10 and redirect requests for https://domain.com/resource2 to 20.20.20.20.
- Create a forward proxy to log HTTP requests going from the internal network to the Internet including: request protocol, remote IP and time take to serve the request.
- (Optional) Implement a proxy health check.
```

## Requirements

In the master we need to run the following:

`puppet module install puppetlabs-apt  && puppet module install  puppet-nginx`

This will pull the `puppet-nginx` module that would allow us to manage an `nginx` server on the agent.

## Usage

Let's suppose the agent is named `puppetagent` and let's suppose the puppet master config is under `/etc/puppet/`. Let's suppose our module is called `netcentric_1` (that's is, we installed it under `/etc/puppet/code)

To use the module, we would need to add the following on the master:

```
node "puppetagent" {
   include netcentric_1
}
```
## SSL files

The Nginx cert, key and Diffie-Helmann param files are self signed. That means we cannot use them on production and are included here for the sole purpose to demostrate everything works.

To generate them I issued:

```
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt && sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

````
