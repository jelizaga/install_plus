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
    * [Categorizing packages](#categorizing-packages)
    * [Preferring installation methods](#preferring-installation-methods)
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

1. Specify the packages you'd like to be installed in the 
   [`packages.json`](#packagesjson) file.
2. Run `instally`. `instally` will read `packages.json` and provide an
   interactive CLI for package selection and installation.

Now you can take your custom `packages.json` file anywhere with `instally`, and
install your favorite packages on (almost) anything!

### packages.json

`packages.json` is the brains behind your `instally` experience.

#### Categorizing packages

*Categorize packages* using the `"categories"` field to create an
*array of categories*:

```json
{
  "categories": [
    {
      "category": "🎸 Music",
      "packages": [
        {
          "name": "Spotify",
          "description": "massive audio streaming service",
          "flatpak": {
            "id": "com.spotify.Client" 
          }
        },
        {
          "name": "ncmpcpp",
          "description": "CLI music player",
          "apt": {
            "id": "ncmpcpp"
          }
        }
      ]
    },
    {
      "category": "🎨 Graphics",
      "packages": [
        {
          "name": "GIMP",
          "description": "GNU Image Manipulation Program",
          "apt": {
            "id": "gimp"
          }
        },
        {
          "name": "Krita",
          "description": "digital painting suite",
          "apt": {
            "id": "krita"
          },
          "flatpak": {
            "id": "org.kde.krita"
          }
        }
      ]
    }
  ]
}
```

* `"categories"` should be an array of category objects.
* Each category object within `"categories"` has:
  * `"category"` - the name of your category,
  * `"packages"` - the array of packages contained within the category,
  * `"description"` - *optional* description of your category.

#### Preferring installation methods

*Prefer an installation method for a package* by specifying your preferred
method using the `"prefer"` field:

```json
{
  "name": "Blender",
  "prefer": "flatpak",
  "apt": {
    "id": "blender"
  },
  "flatpak": {
    "id": "org.blender.Blender"
  }
}
```

Since `"prefer"` is `"flatpak"`, `instally` will install this package using
`flatpak` instead of `apt`.

## Troubleshooting
