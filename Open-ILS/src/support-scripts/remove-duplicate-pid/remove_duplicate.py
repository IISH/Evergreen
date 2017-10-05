#!/usr/bin/env python
#
# remove_duplicate.py -f [file[
#
# Open the csv and replace all duplicate PIDs values with a unique one


import csv
import getopt
import sys
import uuid



history = set()


def parse_file(file, type = 'xml'):

    if type == 'xml':
        print '<?xml version="1.0" encoding="UTF-8"?>'
        print '<records>'

    with open(file, 'rb') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        for items in reader:
            tcn, tag, date = items # e.g. "1000000","10622 ad738b59 9bee 483e 953a dd2df45231fe","2011-08-09 19:25:11"
            pid = '%s/%s-%s-%s-%s-%s' % tuple(tag.upper().split(' '))
            if pid in history:
                new_pid = '10622/' + str(uuid.uuid4()).upper()
                assert new_pid not in history
                history.add(new_pid)
                if type == 'xml':
                    print '<p t="%s">%s</p>' % tuple([tcn, new_pid])
                else:
                    print '%s,%s' % tuple([tcn, new_pid])
            else:
                history.add(pid)

    if type == 'xml':
        print '</records>'

def usage():
    print('Usage: remove_duplicate.py -f [csv file]')


def main(argv):
    file = type= None

    try:
        opts, args = getopt.getopt(argv, 'f:t:h',
                                   ['file=', 'type=', 'help'])
    except getopt.GetoptError:
        usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        elif opt in ('-f', '--file'):
            file = arg
        elif opt in ('-t', '--type'):
            type = arg
        else:
            print('Unknown argument ' + opt)
            sys.exit(1)

    assert file
    parse_file(file, type)


if __name__ == '__main__':
    main(sys.argv[1:])
