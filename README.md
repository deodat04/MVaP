
# Calculatrice Scientifique – Compilateur vers MVàP

Ce projet implémente un **compilateur** pour un **langage de calculatrice scientifique**, conçu pour générer du **code MVàP (Machine Virtuelle à Pile)** à partir d'un langage simple de type **expression/instruction/contrôle**.

---

### 🚀 Fonctionnalités principales

- Compilation d'expressions arithmétiques
- Instructions de base (`if`, `while`, `for`, `function`, `output`, etc.)
- Génération de **code MVàP**
- Support des **fonctions**, des **variables**, et de la **logique booléenne**
- Évaluation interactive via l'outil `TestRig` d'**ANTLR4**

---

### 📦 Structure du projet

- `Calcul.g4` : Grammaire ANTLR4 du langage source
- `TablesSymboles, TableSimple, VariableInfo` : Fichiers nécessaires à la gestion des variables globales, stockage des variables etc.
- `Benchmarks` : Dossier de fichiers de tests et de résultats.
- Génération de code dans un style **Postfix/MVàP** (ex: `PUSHI`, `ADD`, `CALL`, etc.)

---

### 🛠️ Compilation et Exécution

#### 1. Exporter le `CLASSPATH` :
```bash
export CLASSPATH=".:/usr/share/java/*:$CLASSPATH"
```

#### 2. Générer le parseur ANTLR :
```bash
java org.antlr.v4.Tool Calcul.g4
```

#### 3. Compiler les fichiers Java :
```bash
javac *.java
```

#### 4. Lancer l’analyse syntaxique avec visualisation :
```bash
java org.antlr.v4.runtime.misc.TestRig Calcul start -gui
```
---


###  Exemple de code source supporté
Plus d'exemples sont disponibles dans le dossier *benchmarks*
```c
a = 5;
b = 2;
if (a > b) {
  output(a);
}
```

---

### Copyright

- Projet pédagogique de compilation – Licence Informatique
- Utilise **ANTLR4** pour l’analyse syntaxique et lexicale 
- Langage cible : **MVàP** (Machine Virtuelle à Pile)
- made by [deodat04](https://github.com/deodat04)
