# Toolbox.py
This block contains the runtime python scripts that are used in our images.

Command list:
* composer_json.py  
The script checks the validity of the composer.json file and checks the version inside. It also updates the dependency of our base module.
* create_tag.py  
    The script creates a tag in the project repository for the current release. If the version is already present, the old tag is recreated with a commit, while the current release receives a regular version tag.
