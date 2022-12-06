# Continuous integration tools used at Amasty

Repository content:
- [Documentation branch](../../tree/docs)
- [Magento 2 images branch](../../tree/images) [[doc](/docs/01-images.md)]
- [toolbox.sh branch](../../tree/toolbox.sh) [[doc](/docs/02-toolbox-sh.md)]
- [toolbox.py branch](../../tree/toolbox.py) [[doc](/docs/03-toolbox-py.md)]
- [PHPCS image branch](../../tree/phpcs) [[doc](/docs/04-phpcs.md)]
- [Allure image branch](../../tree/allure) [[doc](/docs/05-allure.md)]
- [GitLab CI/CD config branch](../../tree/gitlab-ci) [[doc](/docs/06-gitlab.md)]

---
### About
This repository contains the tools we use to organize the process of continuous integration within the company.
For convenience, all tools are divided into blocks, each of which is stored in a separate repository. In GitLab, we use a group to keep all the repositories, but in GitHub, all blocks are stored in individual branches of the current repository.
This branch is the main one and contains the documentation on our tools.
The blocks themselves also have documentation, which is described directly in the code.

All code is ready to use; however, we are not currently distributing the built images to some.
For full use, you should build images and connect them according to the instructions.
All of our pipelines are configured to use the registry built into Gitlab.

Please feel free to create issues or contribute.
