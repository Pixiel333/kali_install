#!/bin/bash

# Vérifie si le script est exécuté en tant que root
if [ "$EUID" -ne 0 ]; then
  echo "Ce script doit être exécuté en tant que root."
  exit 1
fi

# Vérification du clavier en français
current_layout=$(setxkbmap -query | grep layout | awk '{print $2}')
if [ "$current_layout" != "fr" ]; then
  echo "Le clavier n'est pas en français. Voulez-vous le configurer en AZERTY français ? (y/n)"
  read change_layout
  if [ "$change_layout" == "y" ]; then
    echo "Configuration du clavier en français AZERTY..."
    setxkbmap fr
    debconf-set-selections <<< 'keyboard-configuration  keyboard-configuration/layoutcode string fr'
    debconf-set-selections <<< 'keyboard-configuration  keyboard-configuration/variantcode string azerty'
    dpkg-reconfigure -f noninteractive keyboard-configuration
    service keyboard-setup restart
    systemctl daemon-reload
  fi
else
  echo "Le clavier est déjà en français."
fi

# Demande de changement de mot de passe pour kali
echo "Voulez-vous changer le mot de passe pour l'utilisateur kali ? (y/n)"
read change_kali_pass
if [ "$change_kali_pass" == "y" ]; then
  until passwd kali; do
    echo "Échec du changement de mot de passe. Veuillez réessayer."
  done
fi

# Demande de changement de mot de passe pour root
echo "Voulez-vous changer le mot de passe pour l'utilisateur root ? (y/n)"
read change_root_pass
if [ "$change_root_pass" == "y" ]; then
  until passwd root; do
    echo "Échec du changement de mot de passe. Veuillez réessayer."
  done
fi

# Mise à jour du système
echo "Mise à jour du système..."
apt update -y

# Fonction pour installer Oh My Zsh et les plugins pour un utilisateur spécifique
install_oh_my_zsh() {
  local user=$1
  local user_home=$(eval echo ~$user)

  if [ -d "$user_home/.oh-my-zsh/plugins/zsh-syntax-highlighting" ]; then
    echo "Les plugins Zsh sont déjà installés pour $user."
  else
    echo "Installation de Oh My Zsh pour $user..."
    sudo -u $user sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    # Clonage des plugins de Zsh
    sudo -u $user git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $user_home/.oh-my-zsh/plugins/zsh-syntax-highlighting
    sudo -u $user git clone https://github.com/zsh-users/zsh-autosuggestions.git $user_home/.oh-my-zsh/plugins/zsh-autosuggestions
    sudo -u $user git clone https://github.com/zsh-users/zsh-completions.git $user_home/.oh-my-zsh/plugins/zsh-completions
    sudo -u $user git clone https://github.com/romkatv/powerlevel10k.git $user_home/.oh-my-zsh/themes/powerlevel10k

    # Modification du fichier .zshrc pour ajouter les plugins et le thème
    sudo -u $user sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions)/' $user_home/.zshrc
    sudo -u $user sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' $user_home/.zshrc

    # Application des modifications
    sudo -u $user source $user_home/.zshrc
  fi
}

# Installation de Oh My Zsh pour root
echo "Voulez-vous installer et configurer Oh My Zsh pour root ? (y/n)"
read install_root_zsh
if [ "$install_root_zsh" == "y" ]; then
  install_oh_my_zsh root
fi

# Installation de Oh My Zsh pour kali
echo "Voulez-vous installer et configurer Oh My Zsh pour l'utilisateur kali ? (y/n)"
read install_kali_zsh
if [ "$install_kali_zsh" == "y" ]; then
  install_oh_my_zsh kali
fi

# Nettoyage des paquets obsolètes
echo "Nettoyage des paquets inutilisés..."
apt autoremove -y

echo "Setup terminé avec succès."
