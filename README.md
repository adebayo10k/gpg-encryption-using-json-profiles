# gpg-encryption-using-json-profiles

> Information Privacy and Security == Freedom of Expression, Freedom of Communication and ultimately, Freedom of Thought.

A bit philosophical, but it's assumed that you've arrive at a similar awareness, else the rest of this project won't make much sense.

GnuPG gpg is a tool for encrypting stuff. Usually documents and images that we need to communicate over any channel, but particularly email. It has many capabilties that implement security concepts and best practices.
Email communication is still analogous to sending a postcard.
The internet is not a trusted network.


## About this Project

A highly opinionated source code generator - that _source code_ being a basic, single-line, `gpg` command.
A BASH shell program that uses JSON format profiles to create and interactively execute `gpg` file encryption commands.
Simplifies the encryption of messages by abstracting away the command details.

The program was developed and tested only on 64-bit Ubuntu (20.04) Linux and with its' default, built-in BASH interpreter.

## Files
- gpg-file-encrypt.sh
- profiles.config.EXAMPLE.json

- includes/build-profile.inc.sh
- includes/config.inc.sh
- includes/controller.inc.sh
- includes/helper.inc.sh

- tests/public-key-profile-tests.json
- tests/symmetric-key-profile-tests.json

- shared-functions-library/shared-bash-constants.inc.sh - common module.
- shared-functions-library/shared-bash-functions.inc.sh - common module.

## Purpose

### Use Case

#### 1. Build the profile

- You have one or more messages you need to encrypt before sending to an existing public key encrypted messaging correspondent.
- You run the program with the plaintext files (message(s)) to encrypt as command line parameters.
- The program validates the plaintext files.
- You select the appropriate human-friendly profile name.
- The program uses jq to filter-in the appropriate encryption parameters from your JSON format profile document.
- The program builds the in-memory data structure needed for that particular communication.

#### 2. Create the command strings

- The program checks that your gpg keyring contains the necessary public keys for every recipient with which you're about to communicate that secret message.
- The program then crafts an arbitrary length command, which it presents, for your verification and approval.

#### 3. Interactively encrypt and shred the plaintext messages

- The program calls gpg to encrypt each of the messages for those recipients.
- Finally, after creating encrypted messages, the program gives you the option to irreversibly delete the original plaintext versions. This is a security best practice.


### What are the benefits?

- That whole process took a matter of seconds.
- Crafting a single command by hand, might take longer and be more error-prone.
- The program is only slightly more than a wrapper for `gpg`, so remains portable, with minimal dependencies.

So, for example, creating and issuing a `gpg` encryption command that public key encrypts 10 files, making them only decryptable by say, 20 recipients (of course each with their own public key) is achieved using the program in a matter of seconds.
Obviously `gpg` doesn't care if the single-line command wraps 10 lines either.




## Dependencies

("jq" "shred" "gpg")

Using the shred program assumes HDD, which were still common when I first wrote this program. The SSD permanent file deletion solution ...

## Requirements

None of the programs called require sudo privilege.

## Prerequisites

1. Assumed that you're already familiar with  using the `gpg` utility, and so have generated one or more public keypairs, imported others' public keys and may even have used passphrases for symmetric key encryption.
2. Assumed that you're able to edit a JSON format document.

## Installation

If you have all the above prerequisites covered, you're ready to clone, test, use and extend away.

This project includes the separate shared-functions-library repository as a submodule. The clone command must therefore include the `--recurse-submodules` option which (apparently) will initialise and fetch changes from the submodule repository, like so...

``` bash
git clone --recurse-submodules https://github.com/adebayo10k/gpg-encryption-using-json-profiles.git

```

NOTE: There are multiple ways of doing this. Check the [Github documentation](https://git-scm.com/book/en/v2/Git-Tools-Submodules), or this nice [submodule explanation](https://gist.github.com/gitaarik/8735255), if unfamiliar.



## Configuration

Encrypted communication profiles are stored as JSON objects.
'Profile' refers to a specific, reusable combination of :

- One sender uid
- One or more recipient uids
- An encryption system (public key or symmetric)
- An output file format (ascii or binary)

An example would be:
```
{
    "profileID": "0",
    "profileName": "project cloud migration",
    "profileDescription": "plans to take over leadership of company",
    "encryptionSystem": "public_key",
    "outputFileFormat": "binary",
    "senderUID": "self@work.org",
    "recipientUIDList": [
        "'self@work.org'",
        "'friend@work.org'"
    ]
}
```
1. Open `includes/config.inc.sh`.
2. Edit the value of the `config_file_fullpath` variable to `whatever-you-prefer.json`.
3. Rename `profiles.a10k.config.json.EXAMPLE.json` to `whatever-you-prefer.json`.
4. Edit at least one `whatever-you-prefer.json` JSON object with one of your existing secure comms profiles.
5. Once tested, optionally make `whatever-you-prefer.json` read only.

### JSON Property Values that are Arrays
I chose to use the -r jq filter option. This meant that in order to maintain the distinction between each array element, single quotes were used. Perhaps another option would be better for this filter, but since the single quotes solution worked, along with a sed filter, I'll perhaps address that another time.


## Parameters
``` bash
gpg-file-encrypt.sh [help] | FILE...
```

## Running the Script

A profile for an already existing, secure communication...

```
{
    "profileID": "1",
    "profileName": "local message encryption",
    "profileDescription": "profile to public key encrypt local files",
    "encryptionSystem": "public_key",
    "outputFileFormat": "ascii",
    "senderUID": "damola@host0.org",
    "recipientUIDList": [
        "'damola@host0.org'",
        "'damola@host1.org'"
    ]
},
...
```

```
ls | grep astral
astral0
astral1
astral2
```
```
gpg-file-encrypt.sh astral0 astral1
```


```
1) local message encryption	 3) work team roles
2) project keyfiles dev	 4) project UML diagram images
Which JSON Profile to use for the encryption? Choose an option : 1

You Selected : local message encryption


Keypair identified for sender damola@host0.org OK
Keypair identified for recipient damola@host0.org OK
Keypair identified for recipient damola@host1.org OK

File to encrypt : ./astral0

===specific encryption command string===

gpg --armor --output ./astral0.ENCRYPTED.asc --local-user damola@host0.org --recipient damola@host0.org --recipient damola@host1.org --encrypt ./astral0

1) Yes, looks good. Encrypt it.
2) No, Quit the Program
Does that command look good? OK to encrypt? Choose an option : 1

You Selected : Yes, looks good. Encrypt it.

Encrypting file...


ENCRYPTION SUCCESSFUL.



File to encrypt : ./astral1

===specific encryption command string===

gpg --armor --output ./astral1.ENCRYPTED.asc --local-user damola@host0.org --recipient damola@host0.org --recipient damola@host1.org --encrypt ./astral1

1) Yes, looks good. Encrypt it.
2) No, Quit the Program
Does that command look good? OK to encrypt? Choose an option : 1

You Selected : Yes, looks good. Encrypt it.

Encrypting file...


ENCRYPTION SUCCESSFUL.


Original plaintext files:

./astral0
./astral1


1) Yes, shred them all.
2) No, Keep them and Quit the Program
OK to Shred the plaintext files? (Best practice). Choose an option : 1

You Selected : Yes, shred them all.

Attempting Shred...

shred: ./astral0: pass 1/1 (random)...
shred: ./astral0: removing
shred: ./astral0: renamed to ./0000000
shred: ./0000000: renamed to ./000000
shred: ./000000: renamed to ./00000
shred: ./00000: renamed to ./0000
shred: ./0000: renamed to ./000
shred: ./000: renamed to ./00
shred: ./00: renamed to ./0
shred: ./astral0: removed
shred: ./astral1: pass 1/1 (random)...
shred: ./astral1: removing
shred: ./astral1: renamed to ./0000000
shred: ./0000000: renamed to ./000000
shred: ./000000: renamed to ./00000
shred: ./00000: renamed to ./0000
shred: ./0000: renamed to ./000
shred: ./000: renamed to ./00
shred: ./00: renamed to ./0
shred: ./astral1: removed

SUCCESSFUL SHRED REMOVAL OF FILE:
./astral0


SUCCESSFUL SHRED REMOVAL OF FILE:
./astral1


The End.

```
```
ls | grep astral
astral0.ENCRYPTED.asc
astral1.ENCRYPTED.asc
astral2
```

The program is highly opinionated with regard to the structure of filenames of encrypted messages.


## Testing
Feed the program with combinations of valid and invalid configurations.



## Logging

None.

## License
See [LICENCE](./LICENSE).



