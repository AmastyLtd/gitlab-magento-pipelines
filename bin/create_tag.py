#!/usr/bin/env python

import json
import argparse
import os.path
import sys
import git

__debug = False


def exception_handler(kind, message, traceback):
    """Function that overrides default exception output according to verbose option."""
    if __debug:
        sys.__excepthook__(kind, message, traceback)
    else:
        print(f"{kind.__name__}: {message}", file=sys.stderr)


sys.excepthook = exception_handler

parser = argparse.ArgumentParser()
parser.add_argument("path", help="Path to the working directory.")
parser.add_argument("-v", "--verbose", help="increase output verbosity",
                    action="store_true")
args = parser.parse_args()

__debug = args.verbose

repo = git.Repo(args.path)
origin = repo.remotes.origin
origin.fetch()

if os.path.isfile(args.path + '/composer.json'):
    with open(args.path + '/composer.json', mode="r", encoding="utf-8") as json_file:
        current_version = json.load(json_file)['version']
elif os.path.isfile(args.path + '/package.json'):
    with open(args.path + '/package.json', mode="r", encoding="utf-8") as json_file:
        current_version = json.load(json_file)['version']
else:
    raise RuntimeError('Cannot find supported source for tag creation.')

if repo.active_branch.name != 'master':
    raise RuntimeError('Current branch is not master, cannot continue')
if repo.is_dirty() is True:
    raise RuntimeError('Repo is dirty, cannot continue')

if current_version in repo.tags and repo.tags[current_version].commit.hexsha != repo.head.commit.hexsha:
    tag = repo.tags[current_version]
    repo.create_tag(
        current_version + '-' + repo.git.rev_parse(tag.commit.hexsha, short=4),
        ref=tag.commit.hexsha,
        message=f"Release of {current_version}, build {tag.commit.hexsha}"
    )
    repo.delete_tag(current_version)
    origin.push(current_version, delete=True)
    repo.create_tag(current_version, message=f"Release of {current_version}")
    origin.push(tags=True)
elif current_version not in repo.tags:
    repo.create_tag(current_version, message=f"Release of {current_version}")
    origin.push(tags=True)
else:
    print(f"Tag {current_version} already exists and is up to date.")
