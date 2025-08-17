# SafetyRing iOS - App d'alerte d'urgence moderne 🚨

Une application iOS professionnelle avec interface moderne pour iPhone 12/16, connectée à une bague BLE "SafetyRing" pour déclencher des alertes d'urgence avec SMS automatique et localisation GPS.

## ✨ Nouvelles fonctionnalités (v2.0)

### 🎨 Interface moderne iPhone 12/16
- **Design fluide** avec NavigationStack et gradients subtils
- **Cartes de statut** visuelles pour BLE et réseau
- **Bouton d'alerte** rouge/orange avec ombres et animations
- **Interface adaptative** pour tous les écrans iPhone
- **Icônes SF Symbols** et typographie optimisée

### 🚨 Système d'alerte intelligent
- **Vibration de 5 secondes** avec possibilité d'annulation
- **Compte à rebours visuel** pendant la période d'annulation
- **SMS automatique** ou manuel selon les préférences
- **Localisation GPS** incluse dans le message d'urgence
- **Gestion hors-ligne** avec stockage et re-tentative

### ⚙️ Personnalisation complète
- **Paramètres d'alerte** configurables (vibration, son, SMS auto)
- **Durée de vibration** ajustable (1-10 secondes)
- **Sons d'alerte** personnalisables
- **Gestion des destinataires** avec interface intuitive
- **Journal des alertes** avec historique complet

## 🔧 Installation et test (Windows-friendly)

### 1) Build via GitHub Actions (pas besoin de Xcode)
```bash
git init
git add .
git commit -m "SafetyRing iOS v2.0 - Interface moderne + alertes intelligentes"
git branch -M main
git remote add origin https://github.com/<ton-user>/<ton-repo>.git
git push -u origin main
```

- Attends la fin du workflow "Build iOS (unsigned IPA)"
- Télécharge l'artifact `SafetyRingApp-unsigned.ipa`

### 2) Installation sur iPhone
- Installe **Sideloadly** (`https://sideloadly.io`)
- Branche ton iPhone en USB
- Ouvre Sideloadly → sélectionne l'IPA → installe
- **Autorise l'app** : Réglages → VPN et gestion de l'appareil → Fais confiance à [ton email]

### 3) Configuration de l'app
- Ouvre SafetyRing → autorise Bluetooth, Localisation, Notifications
- Ajoute des destinataires SMS (format international : `+33612345678`)
- Configure tes préférences dans l'onglet Paramètres (⚙️)

## 🧪 Test des alertes BLE

### Option Windows (recommandée) : Android + nRF Connect
1. **Installe "nRF Connect"** sur un téléphone Android
2. **Ouvre l'onglet "Advertiser"**
3. **Configure le périphérique :**
   - **Nom** : `SafetyRing`
   - **Service** : Alert Notification `0x1811`
   - **Caractéristique** : New Alert `0x2A46` (propriété Notify)
4. **Démarre l'annonce**
5. **Dans l'app iOS** : statut doit passer à "Connecté à SafetyRing"
6. **Dans nRF Connect** : envoie une notification avec valeur `ALERT`

### Option Linux/macOS : Simulateur Python
```bash
python3 -m venv .venv
source .venv/bin/activate  # PowerShell: .venv\Scripts\Activate.ps1
pip install -r sim_requirements.txt
python sim_ring.py
```
- Appuie **Entrée** pour émettre un `ALERT`

## 🚀 Utilisation de l'app

### Déclenchement d'alerte
1. **Appuie sur "DÉCLENCHER ALERTE"** (bouton rouge)
2. **Vibration de 5 secondes** commence immédiatement
3. **Compte à rebours** affiché avec possibilité d'annulation
4. **Après 5 secondes** : SMS automatique préparé (si activé)
5. **Validation** : tu tapes "Envoyer" dans l'app Messages

### Gestion hors-ligne
- **Alerte stockée** localement avec timestamp
- **Re-proposition** automatique quand le réseau revient
- **Journal complet** de toutes les actions

### Personnalisation
- **Paramètres** → icône ⚙️ en haut à droite
- **Vibration** : active/désactive + durée
- **Son d'alerte** : personnalisable
- **SMS automatique** : préparation automatique ou manuelle

## 🏗️ Architecture technique

### Structure du projet
```
ios/
├── Sources/
│   ├── App/           # SwiftUI main views
│   ├── BLE/           # CoreBluetooth manager
│   ├── Location/      # GPS location
│   ├── Alert/         # Alert handling + storage
│   └── Reachability/  # Network monitoring
├── Resources/          # Info.plist, assets
└── project.yml        # XcodeGen configuration
```

### Composants clés
- **BLEManager** : Scan/connect BLE "SafetyRing"
- **AlertHandler** : Notifications + sons + haptics
- **AlertStore** : Stockage local + gestion hors-ligne
- **AlertSettingsManager** : Configuration utilisateur
- **LocationManager** : GPS pour localisation d'urgence

## 🔒 Sécurité et limitations

### Limitations iOS
- **SMS automatique impossible** : validation utilisateur requise
- **Bluetooth background** : limité par iOS
- **Localisation** : autorisation "Pendant l'utilisation" requise

### Stockage local
- **Destinataires** : UserDefaults (chiffré par iOS)
- **Logs d'alerte** : JSON local
- **Paramètres** : UserDefaults persistants

## 🐛 Dépannage

### L'app ne voit pas SafetyRing
- Vérifie le nom exact : `SafetyRing`
- Service : `0x1811` (Alert Notification)
- Caractéristique : `0x2A46` avec Notify activé
- Autorisations Bluetooth sur iPhone

### IPA n'installe pas
- **Sideloadly** à jour
- **iOS 16+** requis
- **Apple ID** valide pour signature
- **Autorisation** : VPN et gestion de l'appareil

### Alerte ne fonctionne pas
- **Destinataires** configurés
- **Autorisations** accordées
- **Réseau** disponible (ou mode hors-ligne)
- **Vibration** activée dans Paramètres

## 📱 Compatibilité

- **iOS** : 16.0+
- **iPhone** : 12, 13, 14, 15, 16
- **Bluetooth** : BLE 4.0+
- **Localisation** : GPS + réseau

## 🎯 Roadmap

- [ ] **Widgets iOS** pour accès rapide
- [ ] **Apple Watch** companion app
- [ ] **Siri Shortcuts** intégration
- [ ] **Mode urgence** avec contacts prioritaires
- [ ] **Historique des positions** avec carte
- [ ] **Export des logs** pour analyse

---

**⚠️ Avertissement** : Cette app est un prototype. Ne pas utiliser comme système de sécurité critique sans tests approfondis.

**💡 Support** : Issues GitHub pour bugs, suggestions pour améliorations.
