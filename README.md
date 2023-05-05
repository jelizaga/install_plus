# instally

<video width="1100" height="720" autoplay loop muted>
  <source src="https://streamable.com/w0pu05" type="video/mp4">
  Your browser does not support the video tag.
</video>

> `instally` is a portable interactive CLI script for conveniently & 
consistently installing packages en masse.

* 🚚 **JSON-driven flexibility:** Specify packages for `instally` to install
  using JSON and enjoy support for:
    * organizing packages in groups,
    * preferred methods of installation, 
    * fallback installation methods, 
    * OS-specific installation methods,
    * ***10*** different package managers, 
    * and even running your own installation commands.
* ⛺ **Minimal dependencies:** Owing to its simplicity, you can bring `instally`
  to any[\*](#-os-compatibility) machine that's capable of running Bash and 
  `jq`.
* 💼 **Super portable:** With `instally` and your own custom `package.json`
  file, you can bring your favorite packages to
  [(almost) any distro](#-os-compatibility) and install them right away.

## Contents

<!-- vim-markdown-toc GFM -->

* [💽 Installation](#-installation)
  * [🔩 Dependencies](#-dependencies)
* [🙂 Usage](#-usage)
  * [📒 package.json](#-packagejson)
    * [Package objects](#package-objects)
    * [Installation methods](#installation-methods)
      * [Installation by package manager](#installation-by-package-manager)
        * [Supported package managers](#supported-package-managers)
      * [Installation by command](#installation-by-command)
      * [Preferring installation methods](#preferring-installation-methods)
      * [Specifying installation methods by OS](#specifying-installation-methods-by-os)
        * [Specifying installation methods by OS version](#specifying-installation-methods-by-os-version)
      * [How does instally choose installation methods?](#how-does-instally-choose-installation-methods)
    * [Grouping packages](#grouping-packages)
    * [Installation order](#installation-order)
  * [💻 OS Compatibility](#-os-compatibility)
* [🎨 Configuration](#-configuration)
* [👉 Protips](#-protips)
  * [👉 Getting the most out of instally](#-getting-the-most-out-of-instally)
  * [👉 Setting your default package.json editor](#-setting-your-default-packagejson-editor)
  * [👉 Getting package IDs](#-getting-package-ids)
    * [apt](#apt)
    * [dnf](#dnf)
    * [flatpak](#flatpak)
    * [npm](#npm)
    * [pip](#pip)
    * [snap](#snap)
    * [yum](#yum)
    * [zypper](#zypper)
* [🔧 Troubleshooting](#-troubleshooting)
    * [🔧 Where is package.json?](#-where-is-packagejson)
    * [🔧 Where is instally.conf?](#-where-is-installyconf)
    * [🔧 gum is installed, but won't run](#-gum-is-installed-but-wont-run)

<!-- vim-markdown-toc -->

## 💽 Installation

1. Download `instally`'s [latest release](https://github.com/jelizaga/instally/releases/).
2. Un-archive the downloaded release one of these ways:
    * Double-click the downloaded file.
    * *For* `.tar.gz` - `tar -zxvf instally.tar.gz`
    * *For* `instally.zip` - `unzip instally.zip`
3. Start `instally`! There's a few different ways to start `instally`:
    * `→ bash instally`
    * `→ ./instally` (you may need to `→ chmod +x instally` first)
    * *To install* `instally` *and make it accesible from anywhere in your
      terminal,* try moving the `instally` script to `~/.local/bin`. Now you can
      run `instally` like so: `→ instally`.

### 🔩 Dependencies

`instally` checks for and automatically installs its own dependencies if
they're missing upon initial run:

* [`curl`](https://en.wikipedia.org/wiki/CURL) - For installing `gum` and as a
  fallback installation method.
* [`gum`](https://github.com/charmbracelet/gum) - For interactivity.
* [`jq`](https://github.com/stedolan/jq) - For reading your 
  [`package.json`](#-packagejson) file and installing packages.

You can install `curl`, `gum`, and `jq` using whatever installation methods you
prefer, if you'd rather not have `instally` install them for you.

## 🙂 Usage

![instally installing some software.](https://i.imgur.com/ShTUofz.png "instally installing some packages.")

1. Start `instally`.
2. You'll need to specify the packages you'd like to be installed in the 
   [`package.json`](#-packagejson) file. Don't worry—`instally` will create and
   open this file for you.
3. `instally` will read your `package.json` and provide an
   interactive CLI for package selection and installation.

Now you can take your custom `package.json` file anywhere with `instally`, and
install your favorite packages on (almost) anything!

### 📒 package.json

![Editing package.json and running instally.](https://i.imgur.com/xqyDiTf.png "Editing package.json while running instally.")

`package.json` is the brains behind your `instally` experience. Using
`package.json`, you can configure:

* What packages `instally` can install,
* Installation methods, fallback installation methods, and OS-specific
  installation methods,
* Grouping of packages,
* What order packages are installed in.

---

Here's a *simple example* of a `package.json`:

```json
{
  "packages": [
    {
      "name": "Sensors",
      "description": "hardware health monitoring",
      "apt": {
        "id": "lm-sensors"
      },
      "dnf": {
        "id": "lm_sensors"
      },
      "zypper": {
        "id": "sensors"
      }
    },
    {
      "name": "Vim",
      "apt": {
        "id": "vim-gtk3"
      },
      "dnf": {
        "id": "vim-X11"
      },
      "zypper": {
        "id": "vim"
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
  ],
  "groups": [
    {
      "group": "🎨 Graphics",
      "packages": [
        {
          "name": "Blender",
          "description": "legendary FOSS 3D computer graphics suite",
          "prefer": "flatpak",
          "apt": {
            "id": "blender"
          },
          "dnf": {
            "id": "blender"
          },
          "flatpak": {
            "id": "org.blender.Blender"
          },
          "zypper": {
            "id": "blender"
          }
        }
      ]
    },
    {
      "group": "🐮 Goofy",
      "description": "very important superfluous extras",
      "packages": [
        {
          "name": "cmatrix",
          "description": "cascading text in your terminal, just like the Matrix",
          "apt": {
            "id": "cmatrix"
          },
          "dnf": {
            "id": "cmatrix"
          },
        },
        {
          "name": "figlet",
          "description": "generate ASCII text on the fly in all sorts of fun fonts",
          "apt": {
            "id": "figlet"
          },
          "dnf": {
            "id": "figlet"
          },
          "zypper": {
            "id": "zypper"
          }
        },
        {
          "name": "cowsay",
          "description": "cow that speaks wisdom",
          "apt": {
            "id": "cowsay"
          },
          "dnf": {
            "id": "cowsay"
          },
          "zypper": {
            "id": "cowsay"
          }
        }
      ]
    }
  ]
}
```

* `"packages"` - An array of [*package objects*](#package-objects) listing the
  packages for installation.
* `"groups"` - *Optional* array of [*package groups*](#grouping-packages)
  containing package objects for installation.

#### Package objects

Package objects are the atomic pieces of your `instally` experience; each
package object represents a package you'd like to install and its different
installation methods.

`instally` *package objects* are shaped like so:

```json
{
  "name": "Vim",
  "description": "your favorite text editor",
  "apt": {
    "id": "vim-gtk3"
  },
  "dnf": {
    "id": "vim-X11"
  },
  "zypper": {
    "id": "vim"
  }
}
```

* `"name"` - The name of the package. This could be virtually anything and
  spelled in any way.
* `"description"` - *Optional* description of the package.
* [*Installation methods*](#installation-methods) - `"apt"`, `"dnf"`
  `"flatpak"`, `"go"`, `"npm"`, `"pip"`, `"snap"`, `"yum"`, and `"zypper"` are
  all valid installation methods using
  [package managers](#installation-by-package-manager). `instally` can also 
  install packages using
  [custom shell commands](#installation-by-command) (`"command"`).
* `"prefer"` - *Optional* preferred installation method. See
  [preferring installation methods](#preferring-installation-methods).

#### Installation methods

Within a package object, you can specify as few or as many installation methods
as you'd like. 

These are all valid installation methods:

* [`"apt"`](#installation-by-package-manager)
* [`"command"`](#installation-by-command)
* [`"dnf"`](#installation-by-package-manager)
* [`"flatpak"`](#installation-by-package-manager)
* [`"go"`](#installation-by-package-manager)
* [`"npm"`](#installation-by-package-manager)
* [`"pip"`](#installation-by-package-manager)
* [`"snap"`](#installation-by-package-manager)
* [`"yum"`](#installation-by-package-manager)
* [`"zypper"`](#installation-by-package-manager)

##### Installation by package manager

`instally` currently supports ***10*** different package managers. 

Here, we're using 3 of them:

```json
{
  "name": "Vim",
  "description": "play the legendary text editing instrument like a cool kid",
  "apt": {
    "id": "vim-gtk3"
  },
  "dnf": {
    "id": "vim-X11"
  },
  "zypper": {
    "id": "vim"
  }
}
```

↑ On systems with `apt` `instally` will use `apt` to install `"vim-gtk3"`, and
on systems with `dnf` `instally` will use `dnf` to install `"vim-x11"`, and so
on.

* 👉 *Protip:* See [getting package IDs](#getting-package-ids) for help getting
  the `"id"`s of your packages.

###### Supported package managers

`instally` supports ***10*** package managers:

* `apt` - needs an `"id"`
* `dnf` - needs an `"id"`; falls back to `yum` automatically if `dnf` isn't
  installed
* `flatpak` - needs an `"id"`
* `go` - needs a `"path"` containing the URL or path to the package
* `npm` - needs an `"id"`
* `pip` - needs an `"id"`
* `snap` - needs an `"id"`
* `yum` - needs an `"id"`
* `zypper` - needs an `"id"`

![instally resolving a dependency for Node.js](https://i.imgur.com/kCSEonl.png "instally will install a Node.js version manager if Node.js is needed to install an npm package.")

![instally resolving a dependency for Node.js](https://i.imgur.com/sMtWi1Z.png "instally will install Node.js with fnm or nvm, depending on which version manager is available.")

##### Installation by command

*Install packages using shell commands* with the `"command"` field in a package
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
* 👉 *Protip:* `instally` will choose other existing installation methods over
  the `"command"` method due to its risk and inflexibility, so you may need to
  `"prefer"` your `"command"` if other installation methods exist for the
  package.
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

↑ Since `"prefer"` is `"flatpak"`, `instally` will install this package using
`flatpak` instead of `apt`.

##### Specifying installation methods by OS

*Specify installation methods for a specific OS* by adding a field in the
package object containing your OS's name:

```json
{
  "name": "Visual Studio Code",
  "apt": {
    "id": "code"
  },
  "Fedora Linux": {
    "command": "sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc; sudo sh -c 'echo -e \"[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\" > /etc/yum.repos.d/vscode.repo'; dnf check-update; sudo dnf install code;"
  },
  "openSUSE Tumbleweed": {
    "command": "sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc; sudo sh -c 'echo -e \"[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\" > /etc/zypp/repos.d/vscode.repo'; sudo zypper refresh; sudo zypper install code;"
  }
}
```

↑ On a Fedora Linux system, `instally` will try to install this package using
the given `"command"` installation method under `"Fedora Linux"`. On an
openSUSE Tumbleweed system, `instally` will use a totally different command to
install the package.

* 👉 *Protip:* You can check the `/etc/os-release` file for your OS's name (in
  case you forgot it):

  ```bash
  # Linux: Get your OS's name:
  echo $(grep '^NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
  ```

###### Specifying installation methods by OS version

*Specify installation methods for a specific* ***version*** *of an OS* by adding
a field in the package object containing your OS's *full name*:

```json
{
  "name": "VirtualBox",
  "apt": "virtualbox",
  "Debian GNU/Linux 11 (bullseye)": {
    "command": "wget -P ~/Downloads https://download.virtualbox.org/virtualbox/7.0.8/virtualbox-7.0_7.0.8-156879~Debian~bullseye_amd64.deb; sudo dpkg -i ~/Downloads/virtualbox-7.0_7.0.8-156879~Debian~bullseye_amd64.deb; rm ~/Downloads/virtualbox-7.0_7.0.8-156879~Debian~bullseye_amd64.deb;"
  },
  "Debian GNU/Linux 10 (buster)": {
    "command": "wget -P ~/Downloads https://download.virtualbox.org/virtualbox/7.0.8/virtualbox-7.0_7.0.8-156879~Debian~buster_amd64.deb; sudo dpkg -i ~/Downloads/virtualbox-7.0_7.0.8-156879~Debian~buster_amd64.deb; rm ~/Downloads/virtualbox-7.0_7.0.8-156879~Debian~buster_amd64.deb;"
  },
}
```

↑ `instally` will install this package using different commands specific to
different versions of Debian, and use `apt` if it's ran on a system with `apt`
available that isn't Debian 11 or Debian 10.

* 👉 *Protip:* `instally` will choose version-specific installation methods
  for a package over [OS-specific](#specifying-installation-methods-by-os) 
  installation methods.
* 👉 *Protip:* You can find your current OS's full name, including its version,
  at `instally`'s main menu:

  ![instally printing the OS name of the host machine.](https://i.imgur.com/uOx1Zgf.jpg "instally's main menu, where the OS of the host machine is visible.")

##### How does instally choose installation methods?

1. `instally` will automatically chose whatever methods are appropriate for
   your OS, unless you 
   [prefer an installation method](#preferring-installation-methods).
2. If OS-specific installation methods are specified for a package, `instally`
   will only choose from installation methods for the encountered OS.

#### Grouping packages

![Package groups as displayed by instally.](https://i.imgur.com/hfSmQrb.png
"Choosing grouped packages to install.")

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

`instally` installs packages from `package.json` sequentially, from the top
to the bottom of the file, so the order of package installation is up to the
user.

* 👉 *Protip:* Remember to install dependencies before the packages that depend
  on them.
* 👉 *Protip:* Using [grouping](#grouping-packages), you can bundle packages
  together with their dependencies.

### 💻 OS Compatibility

`instally` has been successfully tested and ran on:

* *Linux:*
  * *Debian-based:*
    * Debian 11
    * Ubuntu 22.04 LTS
    * Pop!\_OS 22.04 LTS
  * *RHEL-based:*
    * Fedora Linux 37
    * CentOS Linux 7
  * *SUSE-based:*
    * openSUSE Tumbleweed

Feel free to contribute and expand `instally`'s compatibility!

* 👉 *Protip:* Hypothetically, `instally` could work on any distro by using the
  flexible [`"command"` installation method](#installation-by-command).
  Combine this technique with 
  [OS-specific installation methods](#specifying-installation-methods-by-os)
  for your enigmatic distro and you'll be good-to-go.
* ⚠ *Warning:* `instally` does not currently run on macOS.

*See also:* [Supported package managers](#supported-package-managers)

## 🎨 Configuration

*Configure* `instally` in "Settings":

![instally being configured via "Settings."](https://i.imgur.com/hfLeATt.gif)

Alternatively, you can configure `instally` by editing 
`~/.instally/instally.conf`:

```
# package.json path:
PACKAGE_JSON=/path/to/desired/package.json/file
# Active color; use a hex code or ANSI color code:
COLOR_ACTIVE=117
# Accent color; use a hex code or ANSI color code:
COLOR_ACCENT=#008000
# Cursor used to point to menu items:
CURSOR=→
# Character symbolizing unselected menu items:
CHOOSE_DEFAULT=-
# Character symbolizing selected menu items:
CHOOSE_SELECTED=✔
```

## 👉 Protips

### 👉 Getting the most out of instally

`package.json` and `instally.conf` can be saved in a `git` repo and taken to any
machine with `instally` installed, making bringing your favorite packages and
environment to any distro pretty trivial. 

If you find yourself constantly recalling and reinstalling packages on freshly
installed operating systems over a matter of days (or weeks), 
`instally`'s the thing for you: It can massively reduce your cognitive load and
the time it takes to load your system with all the software you need.

There's some up-front cost in writing your `package.json`, but with your
`package.json` version-controlled, easily accessible, and polished to 
accommodate the different operating systems and package managers you'll be 
using, it can be a really flexible and foolproof way to install consistent 
experiences across systems.

### 👉 Setting your default package.json editor

`instally` uses your `$EDITOR` to determine what application to edit
`package.json` in. If your `$EDITOR` isn't set, `instally` will open
`package.json` with `nano`.

You can set your default `$EDITOR` to your preferred text editor like so:

```bash
# Examples
# Bash users: Set default $EDITOR to gedit:
echo 'export EDITOR=gedit' >> ~/.bashrc
# Zsh users: Set default $EDITOR to gedit:
echo 'export EDITOR=gedit' >> ~/.zshrc
```

### 👉 Getting package IDs

#### apt

Search for the package:

```
→ apt search [PACKAGE NAME]
```

The `"id"` is `"cmatrix"`:

```
cmatrix/jammy,now 2.0-3 amd64 [installed]
  simulates the display from "The Matrix"
```

#### dnf

Search for the package:

```
→ dnf search [PACKAGE NAME]
```

The `"id"` is `"task"` (or `"task.x86_64"`):

```
Last metadata expiration check: 0:09:21 ago on Thu 13 Apr 2023 05:08:31 PM EDT.
========================= Summary Matched: taskwarrior =========================
task.x86_64 : Taskwarrior - a command-line TODO list manager
taskopen.noarch : Script for taking notes and open urls with taskwarrior
tasksh.x86_64 : Shell command that wraps Taskwarrior commands
vit.noarch : Visual Interactive Taskwarrior full-screen terminal interface
```

#### flatpak

Search for the package:

```
→ flatpak search [PACKAGE NAME]
```

The `"id"` is `"com.spotify.Client"`, under `Application ID`:

```
Name       Description                       Application ID        Version             Branch Remotes
Spotify    Online music streaming service    com.spotify.Client    1.2.8.923.g4f94bf0d stable flathub
```

#### npm

Search for the package:

```
→ npm search [PACKAGE NAME]
```

The `"id"` is `"tiddlywiki"`, under `NAME`:

```
NAME                      | DESCRIPTION          | AUTHOR          | DATE       | VERSION  | KEYWORDS                   
tiddlywiki                | a non-linear…        | =jermolene      | 2023-03-26 | 5.2.7    | tiddlywiki tiddlywiki5 wiki
```

#### pip

1. Search for the package at [https://pypi.org/search/](https://pypi.org/search/).
2. The `"id"` is in the installation command at the top of your package's page.
   Example: in `pip install buku`, `"buku"` is the `"id"`.

`pip search [PACKAGE NAME]` isn't supported by PyPI.

#### snap

Search for the package:

```
→ snap search [PACKAGE NAME]
```

The `"id"` is `"krita"` under `"Name"`:

```
Name   Version  Publisher  Notes  Summary
krita  5.1.5    krita✓     -      Digital Painting, Creative Freedom
```

#### yum

Search for the package:

```
→ yum search [PACKAGE NAME]
```

The `"id"` is `"nano"` (or `"nano.x86_64"`):

```
================================== N/S matched: nano ==================================
nano.x86_64 : A small text editor
 
  Name and summary matches only, use "search all" for everything.
```

#### zypper

Search for the package:

```
→ zypper search [PACKAGE NAME]
```

The `"id"` is `"blender"` under `Name`:

```
S | Name         | Summary                              | Type
--+--------------+--------------------------------------+--------
  | blender      | A 3D Modelling And Rendering Package | package
  | blender-demo | Some Blender demo files              | package
  | blender-lang | Translations for package blender     | package
```

## 🔧 Troubleshooting

#### 🔧 Where is package.json?

`package.json` is in `~/.instally` (a directory called `.instally`, located in
your home directory).

If you're having trouble finding `/.instally`, try the `ctrl+h` shortcut in your
file manager to view hidden files.

#### 🔧 Where is instally.conf?

`instally.conf` is in `~/.instally`, just like `package.json`.

#### 🔧 gum is installed, but won't run

If you encounter an error like this:

```
🐛 Error: Go is installed, and gum also might be installed, but Go is not finding gum.
  Ensure your Go binaries (/go/bin) are included in your PATH variable below:

...

See https://github.com/jelizaga/instally/#gum-is-installed-but-wont-run for help.
```

... it's likely that `gum` was successfully installed using Go, but you haven't
added Go binaries to your `$PATH` yet, so `gum` can't be found.

Make sure you've added your Go binaries to your `$PATH` variable, so they can be
used:

```bash
# Prints the contents of your $PATH. Make sure there's a /go/bin:
→ echo $PATH
```

If your Go binaries are in `~/go/bin` (Go's default binary location), add the
path to `/go/bin` to your `$PATH` like so:

```bash
# Bash users: Adds ~/go/bin to your $PATH:
→ echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
# Zsh users: Also adds ~/go/bin to your $PATH:
→ echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.zshrc
```

Now restart your terminal, then try `instally` again.
