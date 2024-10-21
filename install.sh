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

# Vérification si les fichiers git sont déjà téléchargés
if [ -d "$HOME/.oh-my-zsh/plugins/zsh-syntax-highlighting" ]; then
  echo "Les plugins Zsh sont déjà téléchargés."
else
  # Demande pour configurer Zsh
  echo "Voulez-vous installer et configurer Oh My Zsh et ses plugins ? (y/n)"
  read install_zsh
  if [ "$install_zsh" == "y" ]; then
    echo "Installation de Oh My Zsh et de ses plugins..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    # Clonage des plugins de Zsh
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-autosuggestions.git $HOME/.oh-my-zsh/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-completions.git $HOME/.oh-my-zsh/plugins/zsh-completions
    git clone https://github.com/romkatv/powerlevel10k.git $HOME/.oh-my-zsh/themes/powerlevel10k

    # Modification du fichier .zshrc pour ajouter les plugins et le thème
    sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions)/' ~/.zshrc
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

    # Application des modifications
    source ~/.zshrc
  fi
fi

# Nettoyage des paquets obsolètes
echo "Nettoyage des paquets inutilisés..."
apt autoremove -y

echo "Setup terminé avec succès."
