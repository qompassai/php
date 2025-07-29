#!/bin/sh
# /qompassai/php/scripts/quickstart.sh
# Qompass AI PHP Quick Start
# Copyright (C) 2025 Qompass AI, All rights reserved
####################################################
set -eu
IFS='
'
XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
mkdir -p "$XDG_BIN_HOME" "$XDG_CONFIG_HOME/php" "$XDG_DATA_HOME/php"
case ":$PATH:" in
*":$XDG_BIN_HOME:"*) ;;
*) PATH="$XDG_BIN_HOME:$PATH" ;;
esac
export PATH
NEEDED_TOOLS="git curl tar make gcc bash"
MISSING=""
for tool in $NEEDED_TOOLS; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    if [ -x "/usr/bin/$tool" ]; then
      ln -sf "/usr/bin/$tool" "$XDG_BIN_HOME/$tool"
      echo " → Added symlink for $tool"
    else
      MISSING="$MISSING $tool"
    fi
  fi
done
if [ -n "$MISSING" ]; then
  echo "⚠ Warning: Missing tools:$MISSING"
  echo "Please install these with your package manager."
  exit 1
fi
cat <<EOF >"/tmp/php_menu.$USER"
1 PHP 8.3.8   8.3.8
2 PHP 8.2.20  8.2.20
3 PHP 8.1.27  8.1.27
a All
q Quit
EOF
printf '╭────────────────────────────────────────────╮\n'
printf '│    Qompass AI · PHP Quick‑Start            │\n'
printf '╰────────────────────────────────────────────╯\n'
printf '    © 2025 Qompass AI. All rights reserved   \n\n'
awk 'NF==3 {printf " %s) %s\n", $1, $2}' "/tmp/php_menu.$USER"
printf ' a) all\n'
printf ' q) quit\n\n'
printf "Choose PHP versions to install [1]: "
read -r choice
[ -z "$choice" ] && choice="a"
[ "$choice" = "q" ] && exit 0
VERSIONS=""
if [ "$choice" = "a" ]; then
  VERSIONS=$(awk 'NF==3{print $3}' "/tmp/php_menu.$USER")
else
  for sel in $choice; do
    SELVER=$(awk -v k="$sel" '$1==k{print $3}' "/tmp/php_menu.$USER")
    if [ -z "$SELVER" ]; then
      echo "Unknown option: $sel"
      rm -f "/tmp/php_menu.$USER"
      exit 1
    fi
    VERSIONS="$VERSIONS $SELVER"
  done
fi
PHPENV_ROOT="$XDG_DATA_HOME/phpenv"
if ! [ -d "$PHPENV_ROOT" ]; then
  echo "==> Installing phpenv in $PHPENV_ROOT"
  git clone --depth=1 https://github.com/phpenv/phpenv.git "$PHPENV_ROOT"
  "$PHPENV_ROOT"/bin/phpenv install --skip-existing # just in case hook needed
fi
export PHPENV_ROOT
export PATH="$PHPENV_ROOT/bin:$PATH"
add_path_to_shell_rc() {
  rcfile=$1
  line="export PATH=\"$XDG_BIN_HOME:\$PATH\""
  if [ -f "$rcfile" ]; then
    if ! grep -Fxq "$line" "$rcfile"; then
      printf '\n# Added by Qompass AI PHP quickstart script\n%s\n' "$line" >>"$rcfile"
      echo " → Added PATH export to $rcfile"
    fi
  fi
}
add_phpenv_to_shell_rc() {
  rcfile=$1
  line="export PHPENV_ROOT=\"$PHPENV_ROOT\"; export PATH=\"\$PHPENV_ROOT/bin:\$PATH\""
  if [ -f "$rcfile" ]; then
    if ! grep -Fq "PHPENV_ROOT" "$rcfile"; then
      printf '\n# Added by Qompass AI PHP quickstart script\n%s\n' "$line" >>"$rcfile"
      echo " → Added PHPENV_ROOT to $rcfile"
    fi
  fi
}
add_path_to_shell_rc "$HOME/.bashrc"
add_path_to_shell_rc "$HOME/.zshrc"
add_path_to_shell_rc "$HOME/.profile"
add_phpenv_to_shell_rc "$HOME/.bashrc"
add_phpenv_to_shell_rc "$HOME/.zshrc"
add_phpenv_to_shell_rc "$HOME/.profile"
echo "==> Installing selected PHP version(s) (may take a while)..."
for VER in $VERSIONS; do
  echo " ▪ Installing PHP $VER"
  phpenv install --skip-existing "$VER"
done
LAST_VER=$(echo "$VERSIONS" | awk '{print $NF}')
phpenv global "$LAST_VER"
COMPOSER_BIN="$XDG_BIN_HOME/composer"
if ! [ -x "$COMPOSER_BIN" ]; then
  echo "==> Installing Composer (PHP package manager)..."
  curl -fsSL https://getcomposer.org/installer | php -- --install-dir="$XDG_BIN_HOME" --filename=composer
  chmod +x "$COMPOSER_BIN"
fi
echo "==> Installing common PHP developer tools (user-space)..."
PHP_TOOLS="phpunit php-cs-fixer phpcs phpcbf"
for tool in $PHP_TOOLS; do
  echo " ▪ composer global require $tool ..."
  composer global require "$tool" --no-interaction 2>/dev/null || true
done
echo "✅ Qmopass AI PHP Quicstart is complete!"
echo "→ Please restart your terminal or run 'export PATH=\"$XDG_BIN_HOME:\$PATH\"' to update your PATH."
rm -f "/tmp/php_menu.$USER"
exit 0
