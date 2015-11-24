# Collect Plugins

A collection of plugins for the [collectd](http://collectd) metrics agent.
Currently all plugins are written in perl and require the collectd perl module.

The plugins have been written at Amadeus Germany GmbH but are fairly generic.

For further documentation take a look at the documentation in the source of the
plugins.

## Example configuration:

```
# use the provided types.db
TypesDB /usr/share/collectd/types.db /usr/share/collectd/types-amadeus.db

<Plugin perl>
  BaseName "Collectd::Plugins"
  LoadPlugin "Vmmemctl"
</Plugin>
```

## Plugins

### `Vmmemctl.pm`

Provides metrics about VMware ballooning on Linux.

## License

* Default: MIT
