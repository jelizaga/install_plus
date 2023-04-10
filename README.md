# instally

> `instally` is a portable interactive CLI for conveniently & consistently 
installing your favorite packages en masse.

*See also:* [.dotfiles](https://github.com/jelizaga/.dotfiles)

* ⛺ **Minimal dependencies:** You can run `instally` on any machine that you
  can run Bash and `jq`. How much easier can it get?
* 🚚 **Flexibly JSON-driven:** Specify packages for `instally` to install using
  JSON, enjoying support for categorization, fallbacks, preferred methods, 
  multiple package managers, and even running your own installation commands.
* 🧰 **OS agnostic:** Owing to its simplicity, `instally` can install 
  packages on (almost) anything.

## Contents

<!-- vim-markdown-toc GFM -->

* [Installation](#installation)
  * [Dependencies](#dependencies)
* [Usage](#usage)
  * [packages.json](#packagesjson)
* [Troubleshooting](#troubleshooting)

<!-- vim-markdown-toc -->

## Installation

### Dependencies

`instally` checks for and installs its own dependencies if they're missing upon
initial run:

* [`curl`](https://en.wikipedia.org/wiki/CURL) - For installing `gum` and as a
  fallback installation method.
* [`gum`](https://github.com/charmbracelet/gum) - For interactivity.
* [`jq`](https://github.com/stedolan/jq) - For reading your `packages.json` file
  and installing packages.

## Usage

1. Specify the packages you'd like to be installed in `packages.json`.
2. Run `instally`. `instally` will read `packages.json` and provide an
   interactive CLI for package selection and installation.

Now you can take your custom `packages.json` file anywhere with `instally`, and
install your favorite packages on (almost) anything!

### packages.json

## Troubleshooting
