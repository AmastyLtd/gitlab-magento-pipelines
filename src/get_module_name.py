import argparse
import sys
import os.path
import re

__debug = False

def exception_handler(kind, message, traceback):
    if __debug:
        sys.__excepthook__(kind, message, traceback)
    else:
        print('\033[1;31m{0}\033[0m'.format(message), file=sys.stderr)
        exit(255)

sys.excepthook = exception_handler

if __name__ == '__main__':
    parser = argparse.ArgumentParser("tag_processor")
    parser.add_argument("path", help="Path to the working directory.")
    parser.add_argument("--separator", help="Separator between vendor and module name.", default="/")
    parser.add_argument("-v", "--verbose", help="increase output verbosity",
                        action="store_true")
    args = parser.parse_args()

    __debug = args.verbose

    if not os.path.isdir(args.path):
        raise Exception("Path is not a directory!")
    if not os.path.isfile(args.path + "/registration.php"):
        raise Exception("Directory {0} does not contain registration.php".format(os.path.realpath(args.path)))

    with open(args.path + "/registration.php", "r") as f:
        content = f.read()

        if not content:
            raise Exception("registration.php is empty!")

        match = re.search(r"MODULE,[^\']*\'(?:(?P<vendor>[^_]+)_(?P<name>[^\']+))\',", content.replace("\n", ""))

        print(match.group("vendor") + args.separator + match.group("name"))
