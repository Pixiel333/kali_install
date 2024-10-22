#!/bin/bash

# Vérifie si le script est exécuté en tant que root
if [ "$EUID" -ne 0 ]; then
  echo "Ce script doit être exécuté en tant que root."
  exit 1
fi

# Fonction pour rendre la configuration du clavier en AZERTY persistante
configure_keyboard_fr() {
  echo "Configuration du clavier en AZERTY français..."

  # Modification du fichier /etc/default/keyboard pour rendre la configuration persistante
  sed -i 's/XKBLAYOUT=.*/XKBLAYOUT="fr"/' /etc/default/keyboard
  sed -i 's/XKBVARIANT=.*/XKBVARIANT="azerty"/' /etc/default/keyboard

  # Recharger la configuration du clavier
  dpkg-reconfigure -f noninteractive keyboard-configuration
  service keyboard-setup restart
  systemctl restart keyboard-setup
  systemctl daemon-reload

  # Application immédiate pour la session actuelle
  setxkbmap fr
}

# Vérification du clavier en français
current_layout=$(setxkbmap -query | grep layout | awk '{print $2}')
if [ "$current_layout" != "fr" ]; then
  echo "Le clavier n'est pas en français. Voulez-vous le configurer en AZERTY français ? (y/n)"
  read change_layout
  if [ "$change_layout" == "y" ]; then
    configure_keyboard_fr
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
apt update && apt upgrade -y

# Fonction pour installer Oh My Zsh et les plugins pour un utilisateur spécifique
install_oh_my_zsh() {
  local user=$1
  local user_home=$(eval echo ~$user)
