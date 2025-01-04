```text
        d8888b.  .d88b.  d888888b d88888b d888888b db      d88888b .d8888. 
        88  `8D .8P  Y8. `~~88~~' 88'       `88'   88      88'     88'  YP 
        88   88 88    88    88    88ooo      88    88      88ooooo `8bo.   
        88   88 88    88    88    88~~~      88    88      88~~~~~   `Y8b. 
        88  .8D `8b  d8'    88    88        .88.   88booo. 88.     db   8D 
        Y8888D'  `Y88P'     YP    YP      Y888888P Y88888P Y88888P `8888Y' 
```

These are Mac only configuration files. If, for some crazy reason, you want to use have it in
mind.

## How to use

Install Xcode Command Line Tools:

```bash
xcode-select --install
```

Clone this repository by typing:
```bash
git clone git@github.com:klaygomes/dotfiles.git ~/dotfiles && cd $_
```

If you want to configure everything just run:

```bash
make all
```

You may also configure `nvim`, `git`, `brew`, `zsh` or `node` individually by typing

```bash
make [ nvim | git | brew | zsh | node ]
```
> You can type more than one item at same time `make nvim git` for example

You may also force a full update whenever you want by typing:

```bash
make all -B
```

If you need help type:

```bash
make help
```

```text
+-----------------------------------------------------------------------------+
|              This Makefile should work in most shell environments.          | 
|             But it was only tested on Mac running with Apple sillicon.      |
+--------------------+--------------------------------------------------------+
| commands:          | description:                                           |    
+--------------------+--------------------------------------------------------+
| vim                | Install neovim configuration                           |
| zsh                | Configure zsh default alias, functions and etc.        |
| mac                | Configure mac settings                                 |
| brew               | Install brew packages                                  |
| git                | Install git configuration                              |
| node               | Install nvm, node lts and global packages              |
| help               | Show this help                                         |
+--------------------+--------------------------------------------------------+
```

## How it works

If you want to understand how I'm managing my dotfiles, I wrote a [complete article
teach](https://www.estacouveflor.com/dotfiles-configuration/) what each line of my Makefile does.

## License

DO WHAT THE F**K YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

[READ MORE](/blob/master/LICENSE)
