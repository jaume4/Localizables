# update-localizables

A utility for performing updates on localizable files.

## Installation

Grab the latest release [here](https://github.com/jaume4/Localizables/releases) and move it to `/usr/local/bin`

```bash
mv path_to/update-localizables /usr/local/bin
```

## Usage
### File update

Update the contents of a file.
```
USAGE: update-localizables file <destination-file> <updated-file>

ARGUMENTS:
  <destination-file>      Path to the localizable file to be updated
  <updated-file>          Path to the localizable file containing the updates

OPTIONS:
  -h, --help              Show help information.
```

### Folder update

Search and update the contents of a folder.
```
USAGE: update-localizables folder <destination-folder> <update-folder> [--base-language <base-language>]

ARGUMENTS:
  <destination-folder>    Path to the folder containing the .strings files to
                          be updated
  <update-folder>         Path to the folder containing the .strings files to
                          use as updates

OPTIONS:
  -b, --base-language <base-language>
                          Base language (default: en)
  -h, --help              Show help information.
```

## Special Thanks
The Point-Free team for their [swift-parsing library](https://github.com/pointfreeco/swift-parsing).
## License
[MIT](https://github.com/jaume4/Localizables/blob/main/LICENSE)