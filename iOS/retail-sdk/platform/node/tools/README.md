Node.js Retail SDK Tools
========================

A collection of tools for working with the Retail SDK. To run the tools (which are written in ES6), run

```
node index.js <toolName>
```

usbUpdate
=========

Make a Bluetooth-only Miura terminal accept connections over USB (convert it from a mass storage device to a payment device)

```
node index.js usbUpdate
```

swUpdate
========

Update a Miura terminal. Pass os/mpi/config arguments to FORCE an upgrade of that component regardless of version
matching logic.

```
node index.js swUpdate [--os] [--mpi] [--config]
```

connect
=======

Test the connection process to the Miura terminal.

```
node index.js connect
```

logs
====

Get or clear the logs on the Miura terminal

```
node index.js logs [--remove]
```

print
=====

Print a message on the Miura display

```
node index.js print <message>
```

parse
=====

Parse a file with TLV data in it and print the interpreted contents.

```
node index.js parse tlvfile.txt
```

miuraCopy
=========

Write a file to the Miura device

```
node index.js miuraCopy contactless.cfg
```
