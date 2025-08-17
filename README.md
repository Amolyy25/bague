# 🚨 SafetyRing v2.0 - Application de Sécurité Intelligente

## 🎯 Vue d'ensemble

**SafetyRing** est une application iOS de sécurité d'urgence révolutionnaire qui transforme votre iPhone en bouclier de protection personnel. Conçue pour les situations critiques, elle combine technologie BLE, géolocalisation précise et messagerie simplifiée pour assurer votre sécurité.

## ✨ Fonctionnalités Principales v2.0

### 🚨 Système d'Alerte Intelligent
- **Alerte d'urgence en 1 clic** avec compte à rebours de 5 secondes
- **Vibration continue** pendant le compte à rebours pour confirmation
- **Son d'alerte dissuasif** automatique après envoi
- **Templates d'urgence personnalisables** pour différents scénarios
- **Messages dynamiques** avec variables de localisation en temps réel

### 📱 Messagerie Simplifiée
- **iMessage (SMS) automatique** avec géolocalisation précise (recommandé)
- **WhatsApp** via mode scraping expérimental (situations critiques uniquement)
- **Envoi intelligent** selon les préférences des destinataires
- **Gestion hors-ligne** avec stockage et re-tentative automatique

### 📍 Géolocalisation Avancée
- **GPS haute précision** avec mise à jour continue
- **Adresse complète** via géocodage inversé
- **Coordonnées GPS** formatées professionnellement
- **Lien Apple Maps** intégré dans les messages
- **Horodatage** automatique des alertes

### 🔧 Personnalisation Complète
- **Templates d'urgence** : Agressions, Urgence médicale, Accident, Danger immédiat
- **Messages personnalisés** avec variables dynamiques
- **Sons d'alerte** personnalisables
- **Vibrations** configurables
- **Plateforme préférée** pour l'envoi automatique

### 🚨 Mode Urgence Critique (WhatsApp)
- **Scraping WhatsApp Web** expérimental pour envoi automatique
- **Mode sans confirmation** pour situations extrêmes
- **Avertissements et disclaimers** complets
- **Guidelines d'utilisation responsable**
- **Gestion des risques** et limitations

### ✅ Système de Consentement
- **Demande d'autorisation** au premier lancement
- **Explication claire** des fonctionnalités et risques
- **Avertissements WhatsApp** détaillés
- **Choix éclairé** de l'utilisateur

## 🏗️ Architecture Technique

### 📱 Application iOS
- **SwiftUI** moderne avec interface fluide
- **CoreBluetooth** pour communication BLE
- **CoreLocation** pour géolocalisation précise
- **UserNotifications** pour alertes locales
- **MessageUI** pour composition SMS
- **WebKit** pour mode WhatsApp scraping
- **AVFoundation** pour sons et vibrations

### 🔌 Communication BLE
- **Service** : Alert Notification Service (0x1811)
- **Caractéristique** : New Alert (0x2A46)
- **Format** : Paquet "ALERT" pour déclenchement
- **Connexion automatique** au périphérique "SafetyRing"
- **Gestion des déconnexions** et reconnexions

### 💾 Persistance des Données
- **UserDefaults** pour paramètres et templates
- **JSON local** pour logs d'alertes
- **Stockage sécurisé** des destinataires
- **Sauvegarde automatique** des configurations

## 🚀 Installation et Configuration

### 📋 Prérequis
- **iPhone** iOS 16.0 ou plus récent
- **Xcode** 15.4+ (pour compilation)
- **Compte Apple Developer** (pour sideloading)
- **Périphérique BLE** "SafetyRing" ou simulateur

### 🔧 Installation sur Windows (Sans Xcode)

#### 1. Compilation via GitHub Actions
```bash
# Cloner le projet
git clone https://github.com/votre-username/bague.git
cd bague

# Pousser vers GitHub
git add .
git commit -m "Initial commit SafetyRing v2.0"
git push origin main
```

#### 2. Téléchargement de l'IPA
- Aller sur l'onglet **Actions** de votre repo GitHub
- Attendre la fin de la compilation
- Télécharger l'**IPA unsigned** généré

#### 3. Installation via Sideloadly
- Télécharger **Sideloadly** depuis [sideloadly.io](https://sideloadly.io)
- Connecter votre iPhone via USB
- Glisser-déposer l'IPA dans Sideloadly
- Saisir votre **Apple ID** et mot de passe
- Attendre l'installation

#### 4. Autorisation sur iPhone
- Aller dans **Réglages > Général > VPN et gestion d'appareil**
- Trouver votre profil de développeur
- Appuyer sur **Faire confiance**

### 🧪 Test avec Simulateur

#### Option 1 : Android + nRF Connect (Recommandé)
1. Installer **nRF Connect** sur Android
2. Créer un **GATT Server** avec :
   - **Service UUID** : 0x1811
   - **Caractéristique UUID** : 0x2A46
3. Envoyer des notifications "ALERT"

#### Option 2 : Script Python (Linux/macOS)
```bash
# Installation des dépendances
pip install -r sim_requirements.txt

# Lancement du simulateur
python sim_ring.py

# Appuyer sur Enter pour déclencher une alerte
```

## 🎮 Utilisation de l'Application

### 🚨 Premier Lancement
1. **Vue de consentement** s'affiche automatiquement
2. **Lire attentivement** les avertissements WhatsApp
3. **Accepter les conditions** pour continuer
4. **Destinataires d'urgence** chargés automatiquement

### 🚨 Déclenchement d'Alerte

#### Alerte Simple
1. Appuyer sur **🚨 ALERTE D'URGENCE**
2. **5 secondes de vibration** pour confirmation
3. **Annulation possible** pendant cette période
4. **Envoi automatique** du message après 5s
5. **Son dissuasif** pour attirer l'attention

#### Alerte avec Template
1. Sélectionner un **template d'urgence**
2. Choisir le **scénario approprié**
3. Même processus de **5 secondes**
4. **Message personnalisé** selon le template

### ⚙️ Configuration

#### Destinataires
- **Ajouter** numéros de téléphone
- **Sélectionner** plateformes préférées (iMessage/WhatsApp)
- **Activer/désactiver** individuellement
- **Gérer** les préférences par contact

#### Templates d'Urgence
- **Modifier** les messages existants
- **Créer** de nouveaux scénarios
- **Personnaliser** avec variables
- **Activer/désactiver** selon besoins

#### Paramètres Avancés
- **Plateforme préférée** : iMessage (recommandé) ou WhatsApp
- **Mode WhatsApp scraping** : Pour situations critiques uniquement
- **Sons et vibrations** : Personnalisation complète

### 📍 Variables de Localisation

Les templates supportent ces variables dynamiques :
- `{ADDRESS}` : Adresse complète (ex: "123 Rue de la Paix, Paris")
- `{GPS}` : Coordonnées GPS (ex: "48.8566°N, 2.3522°E")
- `{MAP_LINK}` : Lien Apple Maps direct
- `{TIME}` : Horodatage de l'alerte

## 🔒 Sécurité et Limitations

### ⚠️ Avertissements Importants

#### Mode WhatsApp Scraping
- **Expérimental** et non officiel
- **Risques** de bannissement de compte
- **Utilisation responsable** requise
- **Alternatives** recommandées pour usage quotidien

#### Permissions Requises
- **Bluetooth** : Connexion à SafetyRing
- **Localisation** : Géolocalisation précise
- **Notifications** : Alertes locales
- **Microphone** : Accessibilité vocale

### 🚫 Limitations Techniques
- **SMS automatique** : Requiert interaction utilisateur sur iOS
- **WhatsApp** : URL schemes uniquement (pas d'API officielle)
- **Batterie** : Consommation accrue en mode surveillance
- **Réseau** : Fonctionnalités limitées hors-ligne

## 🧪 Tests et Développement

### 🔍 Débogage
- **Logs détaillés** dans la console Xcode
- **Statuts en temps réel** : BLE, réseau, localisation
- **Historique des alertes** avec timestamps
- **Tests de connectivité** intégrés

### 🐛 Résolution de Problèmes

#### BLE ne se connecte pas
- Vérifier que le Bluetooth est activé
- Redémarrer le scan dans l'app
- Vérifier la distance avec SafetyRing

#### Localisation "inconnue"
- Autoriser l'accès à la localisation
- Attendre la première acquisition GPS
- Vérifier les paramètres de confidentialité

#### Messages non envoyés
- Vérifier la connectivité réseau
- Contrôler les destinataires configurés
- Vérifier les permissions de l'app

## 🚀 Roadmap Future

### 📅 Version 2.1
- [ ] **Mode équipe** : Alertes groupées
- [ ] **Intégration Apple Watch** : Déclenchement depuis la montre
- [ ] **Mode silencieux** : Alertes discrètes
- [ ] **Backup cloud** : Synchronisation iCloud

### 📅 Version 2.2
- [ ] **IA prédictive** : Détection de situations dangereuses
- [ ] **Mode surveillance** : Monitoring continu
- [ ] **Intégration Siri** : Commandes vocales
- [ ] **Mode international** : Support multi-langues

### 📅 Version 3.0
- [ ] **Réseau communautaire** : Alertes entre utilisateurs
- [ ] **Intégration services d'urgence** : Police, pompiers
- [ ] **Mode professionnel** : Pour entreprises et organisations
- [ ] **Analytics avancés** : Statistiques de sécurité

## 🤝 Contribution

### 🐛 Signaler un Bug
1. Créer une **Issue** sur GitHub
2. Décrire le problème en détail
3. Inclure les étapes de reproduction
4. Joindre les logs d'erreur

### 💡 Proposer une Fonctionnalité
1. Créer une **Feature Request**
2. Expliquer l'utilité de la fonctionnalité
3. Décrire l'implémentation souhaitée
4. Discuter avec la communauté

### 🔧 Développement
1. **Fork** le projet
2. Créer une **branch** pour votre fonctionnalité
3. **Commit** vos changements
4. Créer une **Pull Request**

## 📄 Licence

Ce projet est sous licence **MIT**. Voir le fichier `LICENSE` pour plus de détails.

## ⚖️ Avertissement Légal

**SafetyRing** est un outil de sécurité personnel. Les développeurs ne peuvent être tenus responsables de :
- L'utilisation incorrecte de l'application
- Les conséquences des alertes déclenchées
- Les limitations techniques de la plateforme iOS
- Les changements des politiques des services tiers

**Utilisez cette application de manière responsable et conformément aux lois locales.**

## 🆘 Support

### 📧 Contact
- **Issues GitHub** : [github.com/votre-username/bague/issues](https://github.com/votre-username/bague/issues)
- **Discussions** : [github.com/votre-username/bague/discussions](https://github.com/votre-username/bague/discussions)

### 📚 Documentation
- **Wiki** : [github.com/votre-username/bague/wiki](https://github.com/votre-username/bague/wiki)
- **FAQ** : Voir la section Issues marquées "question"

---

## 🎉 Remerciements

Un grand merci à tous les contributeurs qui ont rendu SafetyRing possible. Cette application est dédiée à la sécurité et au bien-être de tous.

**🚨 SafetyRing - Votre bouclier numérique de sécurité** 🛡️
