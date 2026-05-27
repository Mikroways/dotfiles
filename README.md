# Mikroways dotfiles

Este archivo mantiene las configuraciones sugeridas de algunas de las
aplicaciones que usamos en Mikroways.
La forma de instalar estos dotfiles es tan simple como ejecutar:

```bash
git clone https://github.com/Mikroways/dotfiles.git ~/.dotfiles-mw
~/.dotfiles-mw/script/install
```

Luego de correr los comandos anteriores se configurarán algunos programas
utilizados desde la consola como por ejemplo:

* zsh
* vim
* git
* tmux

## Pasos manuales requeridos

El archivo gitconfig.local es necesario que se edite manualmente con los datos
personales. Por ejemplo

```ini
[user]
  name = Juan Perez
  email = juan.perez@mikroways.net
```

> Se provee un archivo `gitconfig.local.sample` a modo de ejemplo que puede
> copiarse como `gitconfig.local` y volver a correr el archivo

## Cómo usar este repositorio

La idea es que cada integrante de Mikroways utilice este repositorio como punto
de partida, pero personalice su ambiente como mejor le parezca, agregando nuevas
configuraciones y proponiéndolas al repositorio raíz, compartiendo experiencias
que nos hagan más eficientes en el día a día.
Para ello se puede forkear este repositorio y cualquier contribución realizarla
como un Pull Request.

### Personalizaciones de Mikroways y Usuario

Las personalizaciones se pueden hacer en cascada de la siguiente forma:

1. Primero se setean los valores por defecto en `.zshrc`
1. Luego se personalizan los valores por defecto para Mikroways usando
   `.zshrc.mikroways`
1. Finalmente, un usuario puede crear un archivo `.zshrc.user` que idealmente
   conviene no versionarlo en este repositorio con las personalizaciones que
   desea sobreescribir
1. Respecto a los bundles de antigen, es posible aplicar personalizaciones con:
  `.zshrc.mikroways.antigen.bundles` y `.zshrc.user.antigen.bundles`

## Integración con herramientas propias de mikroways

* zshell autocomplete y configuraciones de ssh compartidas mediante [mw-sshconfig-sync](https://gitlab.com/mikroways/tools/mw-sshconfig-sync)
  o simplemente usando el cliente de nextcloud.
* Conexión a las vpn de nuestros clientes usando
  [mw-vpn](https://gitlab.com/mikroways/tools/mw-vpn/). La idea es que cada
  usuario configure sus credenciales, pero ahorramos la forma de conectarte
  agnósticamente a cada cliente. Aún nos queda el autocomplete de este comando.

## Sobre vim

Dejamos algunos [tips sobre vim que hemos configurado con estos
dotfiles](README.vim.md)
