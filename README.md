⚠️ The repo has been archived. Templates have been replaced by

[Backstage](https://backstage.dai.tamedia.tech/home) (Github [fission-backstage](https://github.com/DND-IT/fission-backstage))

# Templates

A collection of templates to support the development of new and old projects.

## Bases and Addons

Bases are the foundation of a project, they are the starting point. Addons are the extra features that can be added to a project.

## Cookiecutter

This repository maintains multiple [cookiecutter](https://www.cookiecutter.io/) templates.

To configure a cookie cutter template, create a `cookiecutter.json` file in the root of the template directory and add your folder with the templated files. Folder names can also be templated, so you can use the `@{{ cookiecutter.project_slug }}` variable in the folder name.

Example:

```text
mkdocs
├── @{{ cookiecutter.project_slug }}
│   ├── docs
│   │   ├── README.md
│   │   ├── faq.md
│   │   ├── getting-started.md
│   │   ├── index.md
│   │   └── requirements.txt
│   └── mkdocs.yaml
└── cookiecutter.json
```

All the variables in the `cookiecutter.json` file are required to be used at least once in the template files otherwise an error will be produced.

## Tamcli

The `tamcli` tool is used to generate projects from the templates. It is a wrapper around the `cookiecutter` tool that adds some additional functionality like providing static input for the cookiecutter variables.
