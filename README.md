# WIP OpenBSD ports

This Git repository is an overlay for the OpenBSD ports tree. It contains
port recipes, source patches, packing lists and service definitions.

List the maintained ports from the checkout:

```sh
ksh fetch-ports.ksh --list
```

For an existing, compatible OpenBSD ports checkout, select the ports you
intend to overlay:

```sh
ksh fetch-ports.ksh --copy-only /path/to/ports net/simplexmq net/simplex-chat
```

- [Build, validate and synchronize ports](docs/BUILDING.md)
- [Update versions and regenerate metadata](docs/UPDATE.md)
- [Contribute and follow repository conventions](AGENTS.md)
- [Validate agent and skill changes](docs/agent-knowledge-validation.md)

Use a matching OpenBSD tree for package and runtime validation. Inspect
local changes and destination permissions before overlaying ports.
