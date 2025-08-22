# SimpleVote — Système de Vote Blockchain

## 📋 Groupe I

| Nom            | Prénom  |
|----------------|---------|
| DOSSOU-YOVO    | Czmil   |
| PAGE           | Lilian  |
| TORRES         | Diego   |
| GLITHO         | Eckson  |
| FOTSO          | Moesha  |
| MOUNIB         | Yanisse |
| DURIMEL        | Terence |
| ELFAKIH        | Marwan  |
| DJONDANG       | Aoudou  |
| MASSAH         | Joyce   |
| Tenuda-Eklou   | Afi     |

---

## 🧑‍💻 Répartition des charges

Pour garantir l'implication de chaque membre du groupe, voici la répartition des tâches réalisée sur le projet SimpleVote :

- **Aoudou Djondang** : Mise en place de l'environnement de développement (Foundry, outils), gestion des dépendances.
- **Czmil Dossou-Yovo** : Conception générale, développement principal du smart contract, intégration blockchain et MetaMask, gestion du projet.
- **Yanisse Mounib** : Mise en place et exécution des tests unitaires et d'invariants sur le smart contract.
- **Lilian Page** : Développement de l'interface utilisateur (frontend), design glassmorphism et gestion de la communication Web3 (Ethers.js).
- **Eckson Glitho** : Participation à l'intégration frontend-backend, automatisation du script de déploiement.
- **Diego Torres** : Relecture du code, vérification de la sécurité du smart contract et des accès.
- **Terence Durimel** : Optimisation des performances, correction de bugs, revue technique.
- **Marwan Elfakih** : Support au développement, tests manuels de l'application, retours utilisateurs.
- **Moesha Fotso** : Coordination de la documentation, rédaction du rapport final et synthèse des contributions de chaque membre.
- **Joyce Massah** : Suivi de l'avancement, organisation interne, gestion de la deadline.
- **Afi Tenuda-Eklou** : Participation au développement frontend, retours sur l'ergonomie et l'expérience utilisateur.

> *Remarque : Chaque membre a contribué à une tâche spécifique pour garantir la réussite collective du projet.*

---

## 🎯 Présentation du Projet

SimpleVote est une application de vote décentralisée révolutionnaire qui combine la transparence de la blockchain avec une interface utilisateur moderne. Le système permet à un administrateur (owner) de lancer une session de vote temporaire pour une liste de candidats, garantissant l'intégrité et l'immutabilité des résultats.
### Caractéristiques Principales
- **Vote temporaire** : Durée configurable par l'owner (60s à 1h)
- **4 candidats (test)** : Czmil, Yanisse, Lilian, Eckson
- **Sécurité maximale** : Une fois lancé, personne ne peut arrêter le vote
- **Interface moderne** : Design glassmorphism avec feedback temps réel
- **Optimisation poussée** : Code professionnel avec optimisations et bonnes pratiques

---

## 🛠️ Architecture Technique

### Stack Technologique
- **Smart Contract** : Solidity avec OpenZeppelin (Ownable)
- **Framework** : Foundry (tests, déploiement, fuzzing)
- **Frontend** : HTML5, CSS3 (glassmorphism), JavaScript ES6+
- **Web3** : Ethers.js v6 pour l'interaction blockchain
- **Wallet** : MetaMask pour la signature des transactions

### Structure du Projet
```
blockchain_app/
├── contracts/
│   └── SimpleVote.sol          # Contrat principal
├── test/
│   ├── SimpleVote.t.sol        # Tests unitaires
│   └── Invariants.t.sol        # Tests d'invariants
├── script/
│   └── Deploy.s.sol            # Script de déploiement
├── web/
│   ├── index.html              # Interface utilisateur
│   └── styles.css              # Design glassmorphism
└── foundry.toml                # Configuration Foundry
```

---

## 🔧 Fonctionnement du Système

### 1. Smart Contract (SimpleVote.sol)
Le cœur du système repose sur un contrat intelligent optimisé :

```solidity
// Variables d'état packées pour économiser le gas
uint8 private _voteState;        // 0=NOT_STARTED, 1=ACTIVE, 2=ENDED
uint32 private _voteStartTime;   // Timestamp de début
uint32 private _voteEndTime;     // Timestamp de fin
mapping(uint8 => uint8) public votesCount;  // Compteurs de votes
```

**Optimisations clés :**
- Packing des variables d'état
- Events optimisés pour le gas
- Custom errors pour économiser le gas

### 2. Interface Web (index.html)
L'interface utilise une architecture moderne avec :
- **État réactif** : Mise à jour temps réel via `setInterval`
- **Cache intelligent** : `cachedState` pour optimiser les performances
- **Gestion d'erreurs** : Messages contextuels et validation
- **Design responsive** : Glassmorphism avec animations fluides

### 3. Connexion Blockchain
```javascript
// Connexion MetaMask
provider = new ethers.BrowserProvider(window.ethereum);
signer = await provider.getSigner();

// Interaction avec le contrat
contract = new ethers.Contract(address, ABI, signer);
```

---

## 🚀 Workflow Complet

### Phase 1 : Déploiement
1. **Anvil** : `anvil` (blockchain locale)
2. **Déploiement** : `forge script Deploy --rpc-url http://localhost:8545 --broadcast`
3. **Vérification** : Contrat déployé avec 4 candidats

### Phase 2 : Utilisation
1. **Connexion** : MetaMask → Anvil (compte owner)
2. **Chargement** : Adresse du contrat dans l'interface
3. **Configuration** : Durée du vote (ex: 200 secondes)
4. **Lancement** : Transaction `startVote(duration)`
5. **Vote** : Sélection candidat + transaction `vote(index)`
6. **Résultats** : Affichage temps réel avec pourcentages

### Phase 3 : Expiration
- **Automatique** : Le vote se termine à l'heure exacte
- **Immutable** : Aucune possibilité d'arrêt manuel
- **Transparent** : Résultats visibles immédiatement

---

## 🧪 Tests et Qualité

### Tests Unitaires (SimpleVote.t.sol)
- **Fonctionnalités** : Vote, owner, durée, états
- **Sécurité** : Overflow, double vote, accès non autorisé
- **Edge cases** : Durées limites, timestamps invalides
- **Fuzzing** : Tests avec valeurs aléatoires
- etc...

### Tests d'Invariants (Invariants.t.sol)
- **Cohérence** : Somme des votes = nombre de votants uniques
- **Robustesse** : Résistance aux appels multiples
- **Timestamps** : Validation des fenêtres temporelles
- **Overflow** : Protection contre les débordements
- etc...

### Métriques de Qualité
- **Gas optimisé** : Types minimaux, packing, events
- **Code coverage** : Tests exhaustifs de tous les cas
- **Sécurité** : Validation stricte, custom errors
- **Performance** : Cache côté client, updates optimisés

---


## 🔒 Sécurité et Bonnes Pratiques

### Smart Contract
- **Access Control** : Seul l'owner peut lancer le vote
- **Validation** : Durée entre 60s et 3600s (1h)
- **Immutabilité** : Aucun contrôle après lancement
- **Events** : Traçabilité complète des actions

### Frontend
- **Validation** : Vérification côté client et serveur
- **Gestion d'erreurs** : Messages explicites et récupération
- **Sécurité MetaMask** : Connexion sécurisée et signature
- **État cohérent** : Synchronisation avec la blockchain

---

## 📊 Résultats et Démonstration

### Captures d'Écran
<div align="center">

<table>
  <tr>
    <td><img src="captures/capture 1.png" alt="Capture 1"></td>
    <td><img src="captures/capture 2.png" alt="Capture 2"></td>
  </tr>
  <tr>
    <td><img src="captures/capture 3.png" alt="Capture 3"></td>
    <td><img src="captures/capture 4.png" alt="Capture 4"></td>
  </tr>
  <tr>
    <td><img src="captures/capture 5.png" alt="Capture 5"></td>
    <td><img src="captures/capture 6.png" alt="Capture 6"></td>
  </tr>
  <tr>
    <td><img src="captures/capture 7.png" alt="Capture 7"></td>
    <td><img src="captures/capture 8.png" alt="Capture 8"></td>
  </tr>
</table>

</div>

---

🎥 **Voir la démonstration vidéo complète :**  
[Demo vidéo (demo.mp4)](../captures/demo.mp4)

### Métriques de Performance
- **Déploiement** : ~200k gas
- **Start Vote** : ~50k gas
- **Vote** : ~30k gas
- **Interface** : Mise à jour < 100ms

### Fonctionnalités Démo
1. **Connexion MetaMask** → Anvil
2. **Déploiement contrat** → 4 candidats
3. **Lancement vote** → 200 secondes
4. **Votes multiples** → Différents comptes
5. **Expiration automatique** → Résultats finaux

---

## 🎓 Apprentissages et Compétences

### Techniques
- **Solidity avancé** : Optimisation gas, patterns de sécurité
- **Foundry** : Tests, fuzzing, déploiement
- **Web3** : Interaction blockchain, MetaMask
- **Frontend moderne** : Glassmorphism, JavaScript ES6+

### Méthodologiques
- **Travail en équipe** : Répartition des tâches, coordination
- **Gestion de projet** : Planning, tests, documentation
- **Optimisation** : Code propre, performance, maintenabilité
- **Présentation** : Démo, documentation, communication

---

## 🚀 Installation et Utilisation

### Prérequis
```bash
# Installation Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clonage et installation
git clone https://github.com/CzmilDos/blockchain_vote_app.git
cd blockchain_vote_app 
forge install
```

### Lancement
```bash
# Terminal 1 : Blockchain locale
anvil

# Terminal 2 : Déploiement
forge script Deploy --rpc-url http://localhost:8545 --broadcast

# Terminal 3 : Tests
forge test

# Interface web
python3 -m http.server 8080 --bind 127.0.0.1 (dans le répertoire web)
# Ou simplement ouvrir web/index.html dans un navigateur
```

---

## 📝 Conclusion

SimpleVote représente une implémentation simple mais efficace et propre, d'un système de vote blockchain. Le projet démontre la maîtrise des technologies modernes (Solidity, Foundry, Web3) combinée à des bonnes pratiques de développement (tests, optimisation, UX).

**Points forts :**
- ✅ Code optimisé et sécurisé
- ✅ Interface moderne et intuitive
- ✅ Tests exhaustifs et robustes
- ✅ Démo fonctionnelle

Ce travail illustre les compétences acquises en développement blockchain et en travail d'équipe...

---

*Projet réalisé dans le cadre du cours de Blockchain - Estiam 2025*
