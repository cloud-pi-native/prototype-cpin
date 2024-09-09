#!/bin/bash

# Chargement des variables d'environnement
if [ -f .env ]; then
    export $(cat .env | xargs)
else
    echo ".env file not found!"
    exit 1
fi

# Vérifie si la clé AGE_KEY est présente dans .env
if [ -z "$AGE_KEY" ]; then
    echo "AGE_KEY not found in .env file!"
    exit 1
fi

# Recherche récursive des fichiers *.dec.yaml
find . -type f -name "*.dec.yaml" | while read -r file; do
    # Récupérer le nom du fichier sans l'extension .dec.yaml
    base_name=$(basename "$file" .dec.yaml)
    
    # Récupérer le chemin du dossier où se trouve le fichier
    dir_name=$(dirname "$file")
    
    # Nouveau nom du fichier chiffré
    encrypted_file="$dir_name/$base_name.enc.yaml"
    
    # Si le fichier chiffré existe déjà, vérifier les dates de modification
    if [ -f "$encrypted_file" ]; then
        if [ "$file" -nt "$encrypted_file" ]; then
            echo "Le fichier $file a été modifié, réencryption..."
        else
            echo "Le fichier $file n'a pas été modifié, encryption ignorée."
            continue
        fi
    fi
    
    # Encrypter le fichier avec sops et la clé AGE
    sops --encrypt --age "$AGE_KEY" -encrypted-suffix Templates "$file" > "$encrypted_file"
    
    if [ $? -eq 0 ]; then
        echo "Fichier encrypté: $encrypted_file"
    else
        echo "Erreur lors de l'encryptage de $file"
    fi
done
