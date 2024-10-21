#!/bin/bash

# Vérifie si le script est exécuté en tant que root
if [ "$EUID" -ne 0 ]; then
  echo "Ce script doit être exécuté en tant que root."
  exit 1
fi

# Reconfigure le clavier pour un changement persistant en français AZERTY
echo "Configuration du clavier en français AZERTY..."
setxkbmap fr
debconf-set-selections <<< 'keyboard-configuration  keyboard-configuration/layoutcode string fr'
debconf-set-selections <<< 'keyboard-configuration  keyboard-configuration/variantcode string azerty'
dpkg-reconfigure -f noninteractive keyboard-configuration
service keyboard-setup restart
systemctl daemon-reload

# Change le mot de passe pour l'utilisateur kali
echo "Veuillez changer le mot de passe pour l'utilisateur kali :"
until passwd kali; do
  echo "Échec du changement de mot de passe. Veuillez réessayer."
done

# Change le mot de passe pour root
echo "Veuillez changer le mot de passe pour l'utilisateur root :"
until passwd root; do
  echo "Échec du changement de mot de passe. Veuillez réessayer."
done

# Mise à jour du système
echo "Mise à jour du système..."
apt update && apt upgrade -y

# Installation de Oh My Zsh et des plugins
echo "Installation de Oh My Zsh et de ses plugins..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Clonage des plugins de Zsh
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-completions.git ~/.oh-my-zsh/custom/plugins/zsh-completions
git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

# Modification du fichier .zshrc pour ajouter les plugins et le thème
sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions)/' ~/.zshrc
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

# Application des modifications
source ~/.zshrc

# Nettoyage des paquets obsolètes
echo "Nettoyage des paquets inutilisés..."
apt autoremove -y

echo "Setup terminé avec succès."
