#!/usr/bin/env python

import os, sys, base64

for name in ['dicts.tsv', 'fonts.tsv']:
    if not os.path.exists(name):
        continue

    with open(name, 'r+b') as file:
        lines = []

        for line in file:
            input = line.rstrip().split('\t')

            if input[2].startswith('sha1:'):
                lines.append(line)
                continue

            if input[2] != 'SHA-1':
                raise Exception('invalid file: %s' % name)

            hash = base64.b64decode(input[3])
            url = input[4].rstrip('/') + '/' + input[5]

            if type(hash) == str:
                hash = 'sha1:' + base64.binascii.hexlify(hash)
            else:
                hash = 'sha1:' + hash.hex()

            output = input[0:2]
            output.append(hash)
            output.append(url)
            output.extend(input[6:])
            lines.append('\t'.join(output) + '\n')

        file.seek(0)
        file.writelines(lines)
        file.truncate()
