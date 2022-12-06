## Magento Images

We use a two-step build of Magento 2 images. This way, we can reuse PHP images without application for other projects and rebuild only part of the image.
We also use the Dockerfile template, which is allowed us to solve tasks just by changing the values of variables.
We specifically separate runtime scripts and store them separately so they can be updated on the fly without rebuilding images. You can use your scripts by specifying the path to them and accessing them through environment variables.

The build process is described in detail in our Gitlab CI/CD configurations. Please note that we use git tag pipelines to build images.

Required environment variables during build:
| Name | Description | Type | 
| - | - | - |
| CI_COMPOSER_AUTH | composer auth.json file content | File |
| CI_DEPLOY_USER | user with access to production-ready registry | Variable |
| CI_DEPLOY_PASSWORD | password or token for CI_DEPLOY_USER | Variable |
| CI_PROJECT_DIR | project build directory | Predifined variable |
| CI_COMMIT_TAG | tag name | Predifined variable |
| CI_REGISTRY_USER | user with access to Gitlab registry | Predifined variable |
| CI_REGISTRY_PASSWORD | password or token for CI_REGISTRY_USER | Predifined variable |
