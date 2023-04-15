# instally

> `instally` is a portable interactive CLI for conveniently & consistently 
installing your favorite packages en masse.

*See also:* [.dotfiles](https://github.com/jelizaga/.dotfiles)

* ⛺ **Minimal dependencies:** Owing to its simplicity, you can bring `instally`
  to any machine that's capable of running Bash and `jq`.
* 🚚 **JSON-driven flexibility:** Specify packages for `instally` to install
  using JSON and enjoy support for grouping, preferred methods of installation, 
  fallback methods, multiple package managers, and even running your own
  installation commands.
* 💼 **Super portable:** With `instally` and your own custom `package.json`
  file, you can bring your favorite packages to (almost) any distro and install
  them right away.

## Contents

<!-- vim-markdown-toc GFM -->

* [💽 Installation](#-installation)
  * [🔩 Dependencies](#-dependencies)
* [🙂 Usage](#-usage)
  * [📒 packages.json](#-packagesjson)
    * [Package objects](#package-objects)
    * [Installation methods](#installation-methods)
      * [Installation by package manager](#installation-by-package-manager)
        * [Supported package managers](#supported-package-managers)
      * [Installation by command](#installation-by-command)
      * [Preferring installation methods](#preferring-installation-methods)
      * [How does instally choose installation methods?](#how-does-instally-choose-installation-methods)
    * [Grouping packages](#grouping-packages)
    * [Installation order](#installation-order)
* [🎨 Configuration](#-configuration)
* [👉 Protips](#-protips)
  * [Getting package IDs](#getting-package-ids)
    * [apt](#apt)
    * [dnf](#dnf)
    * [flatpak](#flatpak)
    * [npm](#npm)
    * [pip](#pip)
    * [yum](#yum)
    * [zypper](#zypper)
* [🔧 Troubleshooting](#-troubleshooting)

<!-- vim-markdown-toc -->

## 💽 Installation

### 🔩 Dependencies

`instally` checks for and automatically installs its own dependencies if
they're missing upon initial run:

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
      },
      "dnf": {
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
      "name": "Taskwarrior",
      "description": "CLI todo list",
      "apt": {
        "id": "taskwarrior"
      },
      "dnf": {
        "id": "task"
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
  [package managers](#installation-by-package-manager). `instally` can also 
  install packages using
  [custom shell commands](#installation-by-command).
* `"prefer"` - *Optional* preferred installation method. See
  [preferring installation methods](#preferring-installation-methods).

#### Installation methods

Specify as few or as many installation methods for a package as you'd like.


##### Installation by package manager

```json
{
  "name": "Vim",
  "description": "your favorite text editor",
  "apt": {
    "id": "vim-gtk3"
  }
}
```

* 👉 *Protip:* See [getting package IDs](#getting-package-ids) for help getting
  the `"id"`s of your packages.

###### Supported package managers

* `apt`
* `dnf`
* `flatpak`
* `npm`
* `pip`
* `yum`
* `zypper`

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

##### How does instally choose installation methods?

`instally` will dynamically chose whatever methods are appropriate for your OS,
unless you [prefer an installation method](#preferring-installation-methods).

For example, `instally` won't use `apt` if you're using a non-Debian-based
distro, and won't use `dnf` if you're not using a RHEL-based distro.

If `flatpak`, `npm`, or `pip` are missing but are specified to be used for
installing a package, `instally` will automatically attempt to install them for
you during the installation run.

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

## 🎨 Configuration

Configure `instally` by editing `~/.instally/instally.conf`:

```
COLOR_ACTIVE="VALUE" # Active color; use a hex code.
COLOR_ACCENT="VALUE" # Accent color; use a hex code.
```

## 👉 Protips

### Getting package IDs

#### apt

Search for the package:

```bash
→ apt search [PACKAGE NAME]
```

The `"id"` is `"cmatrix"`:

```bash
cmatrix/jammy,now 2.0-3 amd64 [installed]
  simulates the display from "The Matrix"
```

#### dnf

Search for the package:

```bash
→ dnf search [PACKAGE NAME]
```

The `"id"` is `"task"` (or `"task.x86_64"`):

```bash
Last metadata expiration check: 0:09:21 ago on Thu 13 Apr 2023 05:08:31 PM EDT.
========================= Summary Matched: taskwarrior =========================
task.x86_64 : Taskwarrior - a command-line TODO list manager
taskopen.noarch : Script for taking notes and open urls with taskwarrior
tasksh.x86_64 : Shell command that wraps Taskwarrior commands
vit.noarch : Visual Interactive Taskwarrior full-screen terminal interface
```

#### flatpak

Search for the package:

```bash
→ flatpak search [PACKAGE NAME]
```

The `"id"` is `"com.spotify.Client"`, under `Application ID`:

```bash
Name       Description                       Application ID        Version             Branch Remotes
Spotify    Online music streaming service    com.spotify.Client    1.2.8.923.g4f94bf0d stable flathub
```

#### npm

Search for the package:

```bash
→ npm search [PACKAGE NAME]
```

The `"id"` is `"tiddlywiki"`, under `NAME`:

```bash
NAME                      | DESCRIPTION          | AUTHOR          | DATE       | VERSION  | KEYWORDS                   
tiddlywiki                | a non-linear…        | =jermolene      | 2023-03-26 | 5.2.7    | tiddlywiki tiddlywiki5 wiki
```

#### pip

1. Search for the package at [https://pypi.org/search/](https://pypi.org/search/).
2. The `"id"` is in the installation command at the top of your package's page.
   Example: in `pip install buku`, `"buku"` is the `"id"`.

`pip search [PACKAGE NAME]` isn't supported by PyPI.

#### yum

#### zypper

## 🔧 Troubleshooting
