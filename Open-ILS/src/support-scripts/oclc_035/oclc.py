#!/usr/bin/env python
#
# oclc.py -d [source directory] -f [optional filter]
#
# Iterate through the folder and get each file.
# For each number pair, add that to the xml document.
#
# Use the filter to only allow certain expressions.
#
# File structure starts with four lines, then the number pairs.
#
# For example:
#
# OCLC XREF REPORT
#
# OCLC        Submitted
# Control #   001 Field
# 12345    1078015
# 67890    1501741
#
# Should produce a document:
# <?xml version="1.0" encoding="UTF-8"?>
#
# <records>
#     <record>
#         <oclc>12345</oclc>
#         <tcn>1078015</tcn>
#     </record>
#     <record>
#         <oclc>67890</oclc>
#         <tcn>1501741</tcn>
#     </record>
# </records>


import getopt
import glob
import re
import sys


def parse_directory(directory, filter='(\d+)'):
    print('<?xml version="1.0" encoding="UTF-8"?>')
    print('<records>')

    for file in glob.glob(directory + '/*.txt'):
        parse_file(file, filter)

    print('</records>')


def parse_file(file, filter):
    with open(file) as fp:
        for line in fp:
            match = re.match(r"(\d+)\s+(\d+)", line.strip())
            if match:
                t = match.group(1)
                o = match.group(2)
                if re.match(filter, t):
                    print('<r><o>{0}</o><t>{1}</t></r>'.format(o, t))


def usage():
    print('Usage: oclc.py -d [source directory] -f [filter]')


def main(argv):
    directory = None
    filter = '^\d+$'

    try:
        opts, args = getopt.getopt(argv, 'd:f:h',
                                   ['directory=', 'filter=', 'help'])
    except getopt.GetoptError:
        usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        elif opt in ('-d', '--directory'):
            directory = arg
        elif opt in ('-f', '--filter'):
            filter = arg

    assert directory

    parse_directory(directory, filter)


if __name__ == '__main__':
    main(sys.argv[1:])
