# Splunk config

## Splunk version

The [environment file](.env) is read by docker-compose and sets the variables `splunk_version` and `splunk_universalforwarder_version`. These are used in the docker-compose file to use the specified versions for the respective instances.

## Compatible Splunk containers

This docker-compose setup works with most of the Splunk containers, while the actual Splunk configuration may work with all versions.
The difference in (compatibility with) Splunk containers is in the initialization scripts, and setup parameters.

As of 7.2.0, the containers are shipped with a custom Ansible version, which changes handling of (environment/startup) variables.

Most notably is `SPLUNK_ADD` (and multiple `SPLUNK_ADD_`n);

- Version 6.5.0-7.0.3 makes use of multiple variables (`SPLUNK_ADD_`n), or just a single variable/command (`SPLUNK_ADD`) to add indexes or monitors.
- Versions as of 7.2.0 expects `SPLUNK_ADD` to contain a comma-separated list of add statements for (e.g.) indexes or monitors.
- While versions above 7.2.0 will safely ignore any `SPLUNK_ADD_`n variables, Version 6.5.0-7.0.3 will break on the comma separated list in `SPLUNK_ADD`.

__When using version 6.5.0-7.0.3, remove/comment the `SPLUNK_ADD` sections in the [docker-compose.yml](/docker-compose.yml) file!__

For later version of the containers, the Splunk processes explicitly run a `splunk` user. Commands run within the container should be run using `sudo -u splunk`. While it doesn't seem to be a problem to run without it, it sure eliminates a lot of error messages.

As of versions 7.2.0 of the Universal Forwarder (containers), the `SPLUNK_HOME` is changed from `/opt/splunk` to `/opt/splunkforwarder`. For this reason the [docker-compose.yml](docker-compose.yml) file just mounts the local configurations into both locations.

### Web interface

The web interface is enabled on the [_Enterprise_](http://localhost:8000) and [_HeavyForwarder_](http://localhost:8001) instances, through which configuration can be done.

### Splunk (container) Configuration

Some of the Splunk configuration is done in the [docker-compose.yml](/docker-compose.yml) file, either by supplying environment variables to the containers or executing splunk commands.

On container startup, each container will mount a respective local folder found under [/config](/config)_`/servername`_`/apps/custom_config`. This represents a Splunk app named `custom_app`.

Due to (possibly issues with) scoping in Splunk, for some instances [/config](/config)_`/servername`_`/system/local/props.conf` is mounted as well.

After changing these local configuration files, you need to _restart_ the setup (by following the [Starting the Splunk demo](#Starting-the-Splunk-demo) section).
