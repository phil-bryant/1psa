# 1psa - 1Password Service Account CLI

A command-line tool that uses the 1Password Go SDK to list credentials available in vaults granted to a service account.

## Prerequisites

- Go 1.19 or later
- A 1Password service account token stored in `~/.odus`

## Installation

```bash
# Clone or download the source code
cd 1psa

# Using Makefile (recommended)
make          # clean, compile, and install to /usr/local/bin
make compile  # compile only
make install  # install to /usr/local/bin only
make clean    # remove compiled binary

# Or manually
go build -o 1psa
```

## Usage

```bash
# List all credentials available to the service account
./1psa -l

# List fields available in a specific item
./1psa -l item_name

# Get a specific field value from an item
./1psa -f item_name field_name

# Get username from an item (shortcut)
./1psa -u item_name

# Get password from an item (shortcut)
./1psa -p item_name
```

## Service Account Setup

1. Create a 1Password service account in your 1Password account
2. Grant the service account access to the desired vaults with appropriate permissions
3. Save the service account token in `~/.odus`

## Features

- **List all credentials**: Shows all vaults and items accessible to the service account
- **List item fields**: Shows available field names for a specific item
- **Get specific field values**: Retrieve any field value from an item
- **Username/password shortcuts**: Quick access to common credential fields
- **Improved formatting**: Item information displayed on single lines
- **Error handling**: Clear error messages and user feedback

## Example Output

### List all credentials
```bash
$ ./1psa -l
Found 1 vault(s) accessible to the service account:

Vault: odus (ID: pufwxxyfeska5o4glt6hvavgei)
------------------------
  Found 1 item(s):
  1. odus (ID: 6b5v7dgm2zc6l447vgs5uabvd4) Category: Login
```

### List fields for a specific item
```bash
$ ./1psa -l odus
Fields for item 'odus':
------------------------
1. password
2. username
3. odus
```

### Get specific field values
```bash
$ ./1psa -f odus username
root

$ ./1psa -u odus
root

$ ./1psa -p odus
gzxgzA4t!bsg33mdzsqH
```
