# 1psa - 1Password Service Account CLI + Shared Library

A command-line tool that uses the 1Password Go SDK to list credentials available in vaults granted only to a particular 1Password service account. Perfect for constraining what an LLM can do.

## Prerequisites

- Go 1.19 or later
- A 1Password service account token stored in `~/.1psa`

## Build

```bash
# Clone or download the source code
cd 1psa

# Using Makefile (recommended)
make                  # build CLI + shared library
make build            # build CLI only (bin/1psa)
make compile-shared   # build shared library only (bin/libonepsa.dylib + .h)
make install          # install CLI to /usr/local/bin
make clean            # remove/move previous CLI artifact

# Or manually
go build -o bin/1psa ./cmd/1psa
go build -buildmode=c-shared -o bin/libonepsa.dylib ./cshared
```

## Usage

```bash
# List all credentials available to the service account
./1psa -l

# List fields available in a specific item
./1psa -l item_name

# Get a specific field value from an item
./1psa -f item_name field_name

# Get multiple fields from an item in one call
./1psa -m item_name server database username password

# Get username from an item (shortcut)
./1psa -u item_name

# Get password from an item (shortcut)
./1psa -p item_name
```

## Python Library Usage (ctypes/cffi)

Build the shared library first:

```bash
make compile-shared
```

The generated library/API surface is:
- `bin/libonepsa.dylib`
- `bin/libonepsa.h`

Example Python wrappers are included:
- `python/onepsa_ctypes.py`
- `python/onepsa_cffi.py`

Quick start with `ctypes`:

```bash
python -c "from python.onepsa_ctypes import Onepsa; print(Onepsa().get_field('my-item','username'))"
```

Quick start with `cffi`:

```bash
pip install cffi
python -c "from python.onepsa_cffi import Onepsa; print(Onepsa().get_field('my-item','username'))"
```

## Service Account Setup

1. Create a 1Password service account in your 1Password account
2. Grant the service account access to the desired vaults with appropriate permissions
3. Save the service account token in `~/.1psa`

## Features

- **List all credentials**: Shows all vaults and items accessible to the service account
- **List item fields**: Shows available field names for a specific item
- **Get specific field values**: Retrieve any field value from an item
- **Get multiple fields in one call**: Avoid repeated CLI startup/auth checks
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

$ ./1psa -m odus username,password
username=root
password=gzxgzA4t!bsg33mdzsqH

$ ./1psa -m odus server database username password
server=db.example.internal
database=appdb
username=root
password=gzxgzA4t!bsg33mdzsqH

$ ./1psa -u odus
root

$ ./1psa -p odus
gzxgzA4t!bsg33mdzsqH
```
