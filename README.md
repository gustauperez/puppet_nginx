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

## Rationale

The module is declared as `netcentric_1` class. It includes 5 class attributes:

- domain
- fwd_port
- ssl_cert
- ssl_key
- dhparm

Those can be set when using the module.

To install Nginx, I needed to add the Nginx apt key. Without that, apt would fail to manage the repo by itself because the execution will not happen in a real terminal, and apt would complain about that (not valid `stdout` and `stderr`).

To solve the first part, I needed to configure the Nginx:

- Set the `/etc/nginx/ssl` directory with the right permissions (www-data and 0600)
- Copy the ssl files with the right modes (0400 for ssl_key and dhparam and 0444 for the ssl cert).
- Define two upstream block of upstream servers (right now)
- Declare a server resource and a location resource. The server will declare itself as a proxy resource (that is, everything will be proxied to `10.10.10.10:80`). The location resource `/resource2` will use the other upstream block as a proxy (20.20.20.20:80). Both will be exposed using SSL.

To solve the second part:

- I declared a new log_format called `forward` with the ` $request_time` `$scheme` and `$upstream_addr`. The first one was already part of the Nginx log format, so I left it were it was. Regarding the two other field, I put them at the end of the logs, that to try not to break any log parsing that might be in place (like logstash or rsyslog parsing).

To address the third part, I had two options. Use Nginx PLUS which has active health checks (out of the scope) or declared a `/health` and pass that to the upstream (Nginx has passive health checks using upstream blocks)

## Usage

Let's suppose the agent is named `puppetagent` and let's suppose the puppet master config is under `/etc/puppet/`. Let's suppose our module is called `netcentric_1` (that's is, we installed it under `/etc/puppet/code/environments/production/modules`)

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
