# instally

> `instally` is a portable interactive CLI for conveniently & consistently 
installing your favorite packages en masse.

*See also:* [.dotfiles](https://github.com/jelizaga/.dotfiles)

* ⛺ **Minimal dependencies:** You can run `instally` on any machine that you
  can run Bash and `jq`. How much easier can it get?
* 🚚 **Flexibly JSON-driven:** Specify packages for `instally` to install using
  JSON, enjoying support for grouping, fallbacks, preferred methods, 
  multiple package managers, and even running your own installation commands.
* 🧰 **OS agnostic:** Owing to its simplicity, `instally` can install 
  packages on (almost) anything.

## Contents

<!-- vim-markdown-toc GFM -->

* [💽 Installation](#-installation)
  * [🔩 Dependencies](#-dependencies)
* [🙂 Usage](#-usage)
  * [📒 packages.json](#-packagesjson)
    * [Package objects](#package-objects)
    * [Installation methods](#installation-methods)
      * [Preferring installation methods](#preferring-installation-methods)
      * [Installation by command](#installation-by-command)
    * [Grouping packages](#grouping-packages)
    * [Installation order](#installation-order)
* [🔧 Troubleshooting](#-troubleshooting)

<!-- vim-markdown-toc -->

## 💽 Installation

### 🔩 Dependencies

`instally` checks for and installs its own dependencies if they're missing upon
initial run:

* [`curl`](https://en.wikipedia.org/wiki/CURL) - For installing `gum` and as a
  fallback installation method.
* [`gum`](https://github.com/charmbracelet/gum) - For interactivity.
* [`jq`](https://github.com/stedolan/jq) - For reading your 
  [`packages.json`](#-packagesjson) file and installing packages.

## 🙂 Usage

1. Specify the packages you'd like to be installed in the 
   [`packages.json`](#-packagesjson) file.
2. Run `instally`. `instally` will read `packages.json` and provide an
   interactive CLI for package selection and installation.

Now you can take your custom `packages.json` file anywhere with `instally`, and
install your favorite packages on (almost) anything!

### 📒 packages.json

`packages.json` is the brains behind your `instally` experience. Using
`packages.json`, you can configure:

* What packages `instally` can install,
* Installation methods and fallback installation methods,
* Grouping of packages,
* What order packages are installed in.

---

Here's a *simple example* of a `packages.json`:

```json
{
  "packages": [
    {
      "name": "curl",
      "apt": {
        "id": "curl"
      }
    },
    {
      "name": "Vim",
      "apt": {
        "id": "vim-gtk3"
      }
    },
    {
      "name": "nsnake",
      "apt": {
        "id": "nsnake"
      }
    }
  ]
}
```

* `"packages"` - An array of [*package objects*](#package-objects) listing the
  packages for installation.
* `"groups"` - *Optional* array of [*package groups*](#grouping-packages)
  containing package objects for installation.

#### Package objects

`instally` *package objects* are shaped like so:

```json
{
  "name": "Vim",
  "description": "your favorite text editor",
  "apt": {
    "id": "vim-gtk3"
  }
}
```

* `"name"` - The name of the package. This could be virtually anything and
  spelled in any way.
* `"description"` - *Optional* description of the package.
* [*Installation methods*](#installation-methods) - `"apt"`, `"dnf"`
  `"flatpak"`, `"yum"`, and `"zypper"` are all valid installation methods using
  package managers. `instally` can also install packages using
  [custom shell commands](#installation-by-command).
* `"prefer"` - *Optional* preferred installation method. See
  [preferring installation methods](#preferring-installation-methods).

#### Installation methods

##### Preferring installation methods

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

##### Installation by command

*Install packages using commands* with the `"command"` field in a package
object:

```json
{
  "name": "VirtualBox",
  "description": "x86 virtualization",
  "command": "wget -P ~/Downloads https://download.virtualbox.org/virtualbox/7.0.6/virtualbox-7.0_7.0.6-155176~Ubuntu~jammy_amd64.deb; sudo dpkg -i ~/Downloads/virtualbox-7.0_7.0.6-155176~Ubuntu~jammy_amd64.deb; rm ~/Downloads/virtualbox-7.0_7.0.6-155176~Ubuntu~jammy_amd64.deb;"
}
```

`instally` will run the contents of your `"command"` field to install your
package.

* ⚠ *Caution:* Make sure you know what you're doing. `instally` will run
  whatever is in the `"command"` field without sanitization or guardrails.
* 👉 *Protip:* String together shell commands in sequence using `;` or `&&`.
* 👉 *Protip:* You can use `"command"` to execute your own scripts.
* 👉 *Protip:* Remember to delete downloaded files and install scripts if you
  don't want them anymore. You can automate this by adding an `rm` statement at
  the end of your command, as in the above example.

#### Grouping packages

*Group packages* using the `"groups"` field to create an
*array of groups*:

```json
{
  "groups": [
    {
      "group": "🎸 Music",
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
      "group": "🎨 Graphics",
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

* `"groups"` should be an array of group objects.
* Each group object within `"groups"` has:
  * `"group"` - the name of your group,
  * `"packages"` - the array of packages contained within the group,
  * `"description"` - *optional* description of your group.

#### Installation order

`instally` installs packages from  `packages.json` sequentially, from the top
to the bottom of the file, so the order of package installation is up to the
user.

* 👉 *Protip:* Install dependencies before the packages that depend on them.
* 👉 *Protip:* Using [grouping](#grouping-packages), you can bundle packages
  with their dependencies.

## 🔧 Troubleshooting
