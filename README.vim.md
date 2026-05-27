# Tips sobre vim

Vim está configurado con varios plugins que simplifican su uso, pero a veces no
conocemos algunos truquitos que son útiles con el uso de vim. Los plugins se
instalan con [vim-plug](https://github.com/junegunn/vim-plug).

> Es importante destacar que un plugin útil, es el [iamcco/markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim).
> Sin embargo, no lo incluimos acá porque su instalación falla la primera vez
> y en instalaciones desatendidas no es posible que la instalación de dotfiles
> termine.

## Grabar acciones repetitivas

## Ver las diferencias de un archivo modificado

```vim
:w !diff % -
```

> Porque :w graba un archivo, pero si lo que sigue es un comando entonces lo
> graba en el buffer del shell y no en un archivo. Luego es buffer es usado como
> stdin para justamente el comando enviado. Por ejemplo, si probamos `:w !cat`
> veremos el contenido que estamos editando impreso por `cat`. Retomando esta
> idea, el comando anterior guarda el archivo modificado en `STDIN` y esto lo
> envía al comando `diff` (que obviamente debe estar instalado). Luego, `%` en
> vim expande al archivo que se está editando, y `-` significa que se compare
> con `STDIN`.

## Abrir rápido un archivo

Para abrir un archivo bajo el árbol de directorios desde donde se abrió vim,
podemos usar Ctrl+p. Esta acción invoca al comando `fzf` o [fuzzy
finder](https://github.com/junegunn/fzf), que también funciona desde la consola,
pero utilizando Ctrl+t. Esta utilidad en vim puede utilizarse en combinación de
ventanas y solapas.

## Uso de solapas

TODO

Al abrir vim podemos además usar la opción `-p` para abrir varios archivos en
solapas.

## Uso de ventanas

* Ctrl+w+v abrimos una ventana vertical con el mismo contenido que se está
  editando.
* Ctrl+w+s abrimos una ventana horizontal con el mismo contenido que se está
  editando.
* **Para cambiar el layout:** asumiendo que con h,j,k y l nos movemos en vim,
  entonces usando Ctrl+w+(alguna de las mayúsculas) irá modificando el layout
  según lo vamos indicando con las correspondientes letras.
* **Para mover entre ventanas:** Ctrl+w+(alguna de las letras h,j,k,l) o las
  flechas del teclado (preferiblemente utilizar las letras).

Al abrir vim podemos además usar la opción `-o` (horizontal) o `-O` (vertical)
para abrir varios archivos en ventanas.
