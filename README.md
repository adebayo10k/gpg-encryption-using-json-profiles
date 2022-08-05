# gpg-encryption-using-json-profiles

> Information Privacy and Security == Freedom of Expression, Freedom of Communication and ultimately, Freedom of Thought.

A bit philosophical, but it's assumed that you've arrive at a similar awareness, else the rest of this project won't make much sense.

Being able to control our information and the information with which we're entrusted is no longer just a nice-to-have for professionals in all fields who need to remain trusted as reasonably competent.

GnuPG is a tool for encrypting stuff. Usually textual documents that we need to communicate. It has many capabilties that implement security concepts and best practices.

Email communication is still analogous to sending a postcard.

The internet is not a trusted network.


## About this Project

A highly opinionated source code generator, that source code being a basic, single line, gpg command.

A BASH shell program that uses JSON format profiles to create and interactively execute gpg file encryption commands.

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

What is this program for?
What does this program do?
How does this program do it?

### Use Case

#### 1. Build the profile

- You have one or more messages you need to encrypt before sending to an existing public key encrypted message correspondent.
- You run the program with the message(s) (files) to encrypt as command line parameters.
- The program validates the files.
- You select the appropriate human friendly profile_name.
- The program uses jq to filter in the appropriate encryption parameters from your JSON format profile document.
- The program builds the in-memory data structure needed for that particular communication.

#### 2. Create the command strings

- The program checks that your gpg keyring contains the necessary public keys for every recipient with which you're about to communicate that secret message.
- The program then crafts an arbitrary length command, which it presents for your verification and approval.

#### 3. Interactively encrypt and shred the plaintext messages

- The program calls gpg to encrypt each of the messages for those recipients.
- Finally, after creating encrypted messages, the program gives you the option to irreversibly delete the original plaintext versions. This is a security best practice.


### What are the benefits?

- That whole process took a matter of seconds.
- Crafting a single command by hand, might take longer and be more error-prone.
- The program is only slightly more than a wrapper for gpg, so remains portable, with minimal dependencies.

So, for example, creating and issuing a gpg encryption command that public key encrypts 10 files, making them only decryptable by say, 20 recipients (of course each with their own public key) is achieved using the program in a matter of seconds.
Of course when executing, gpg doesn't care if the single-line command wraps 10 lines either.







## Dependencies

("jq" "shred" "gpg")

Using the shred program assumes HDD, which were still common when I first wrote this program. The SSD permanent file deletion solution ...

## Requirements

None of the programs called require sudo privilege.

## Prerequisites

Assumed that you're already familiar with  using the gpg utility, and so have generated one or more public keypairs, imported others' public keys and may even have used passphrases for symmetric key encryption.
Assumed that you know how to create of JSON format document.

## Installation

If you have all the above prerequisites covered, you're ready to clone, test, use and extend away.

This project includes the separate shared-functions-library repository as a submodule. The clone command must therefore include the `--recurse-submodules` option which (apparently) will initialise and fetch changes from the submodule repository, like so...

``` bash
git clone --recurse-submodules https://github.com/adebayo10k/gpg-encryption-using-json-profiles.git

```

NOTE: There are multiple ways of doing this. Check the Github documentation if unfamiliar.



## Configuration

Encrypted communication profiles are stored as JSON objects.
A profile refers to a specific, reusable combination of :

- One sender uid
- One or more recipient uids
- An encryption system (public key or symmetric)
- An output file format (ascii or binary)

```
An example would be:

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


## Parameters
``` bash
gpg-file-encrypt.sh [help] | FILE...
```

## Running the Script



The program is highly opinionated with regard to the structure of filenames of encrypted messages. Thus, the templates ...

THIS IS THE FORM FOR PUBLIC KEY ENCRYPTION:
$ gpg [--armor] --output "$plaintext_file_fullpath.ENCRYPTED[.asc|.gpg]" \
 --local-user <uid> --recipient <uid> --encrypt "$plaintext_file_fullpath"
	
COMMAND FORM:
$ gpg [--armor] --output "$plaintext_file_fullpath.ENCRYPTED[.asc]" --symmetric "$plaintext_file_fullpath"


## Logging

None.

## License
No changes or additions. See [LICENCE](./LICENSE).



