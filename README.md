# My Personal 


###### `figlet dotfiles -f basic`
---
```text
        d8888b.  .d88b.  d888888b d88888b d888888b db      d88888b .d8888. 
        88  `8D .8P  Y8. `~~88~~' 88'       `88'   88      88'     88'  YP 
        88   88 88    88    88    88ooo      88    88      88ooooo `8bo.   
        88   88 88    88    88    88~~~      88    88      88~~~~~   `Y8b. 
        88  .8D `8b  d8'    88    88        .88.   88booo. 88.     db   8D 
        Y8888D'  `Y88P'     YP    YP      Y888888P Y88888P Y88888P `8888Y' 
```

# How to use

Clone this repository by typing:
```bash
git clone git@github.com:klaygomes/dotfiles.git ~/dotfiles && cd $_
```

If you want to configure everything just run:

```bash
make
```

You may also configure `nvim`, `git`, `brew`, `zsh` or `node` individually by typing

```bash
make [ nvim | git | brew | zsh | node ]
```
> You can type more than item at same time `make nvim git` for example

You may also force a full update whenever you want by typing:

```bash
make all -B
```

If you have any question read the [Makefile](Makefile)
