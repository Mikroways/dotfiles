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

## Actualización automática de herramientas Mikroways

Al abrir una nueva terminal, se lanza en background un chequeo de actualizaciones
para todos los repositorios git bajo `~/.mikroways/`. Si hay novedades, se
notifica al inicio de la **próxima** sesión de terminal.

### Comportamiento

- **Una vez por día**: el chequeo corre a lo sumo una vez diaria (controlado por
  `~/.mw-tools-upgrade.lock`).
- **Solo ramas principales**: los repositorios en una rama distinta a `main` o
  `master` se reportan como advertencia pero no se actualizan automáticamente.
- **Sin cambios locales**: si un repositorio tiene cambios sin commitear, se
  aborta la actualización y se avisa.
- **Notificaciones diferidas**: los avisos (actualizaciones disponibles, repos en
  rama no principal, cambios locales sin commitear) se muestran al abrir la
  siguiente terminal, no mientras el chequeo corre en background.

### Comandos disponibles

| Comando | Descripción |
|---|---|
| `mw-tools-upgrade` | Chequea actualizaciones de forma interactiva |
| `mw-tools-upgrade -y` | Chequea y aplica automáticamente (modo background) |
| `mw-tools-force-upgrade` | Fuerza el chequeo ignorando el lock diario |

### Archivos relevantes

| Archivo | Propósito |
|---|---|
| `~/.mw-tools-upgrade.lock` | Evita chequeos repetidos el mismo día |
| `~/.mw-tools-upgrade.warn` | Mensajes pendientes a mostrar en la próxima terminal |
| `~/.mw-tools-upgrade.log` | Log del último chequeo en background |

## Sobre vim

Dejamos algunos [tips sobre vim que hemos configurado con estos
dotfiles](README.vim.md)
