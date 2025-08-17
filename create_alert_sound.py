#!/usr/bin/env python3
"""
Script pour créer un son d'alerte WAV pour SafetyRing
Génère un son dissuasif de 3 secondes avec des fréquences variables
"""

import numpy as np
import wave
import struct

def create_alert_sound(filename="ios/Resources/alert.wav", duration=3.0, sample_rate=44100):
    """
    Crée un son d'alerte dissuasif
    
    Args:
        filename: Chemin du fichier de sortie
        duration: Durée en secondes
        sample_rate: Taux d'échantillonnage
    """
    
    # Calculer le nombre d'échantillons
    num_samples = int(duration * sample_rate)
    
    # Créer un tableau de temps
    t = np.linspace(0, duration, num_samples)
    
    # Générer plusieurs fréquences pour un effet dissuasif
    # Fréquence principale qui varie dans le temps
    base_freq = 800  # Hz
    freq_modulation = 200 * np.sin(2 * np.pi * 2 * t)  # Modulation de fréquence
    frequency = base_freq + freq_modulation
    
    # Générer le signal principal
    signal = np.sin(2 * np.pi * frequency * t)
    
    # Ajouter des harmoniques pour plus d'impact
    signal += 0.5 * np.sin(2 * np.pi * 2 * frequency * t)
    signal += 0.3 * np.sin(2 * np.pi * 3 * frequency * t)
    
    # Ajouter un effet de "pulse" (clignotement)
    pulse_rate = 4  # Hz
    pulse = 0.5 + 0.5 * np.sin(2 * np.pi * pulse_rate * t)
    signal *= pulse
    
    # Normaliser le signal
    signal = signal / np.max(np.abs(signal))
    
    # Convertir en 16-bit PCM
    signal_16bit = (signal * 32767).astype(np.int16)
    
    # Créer le fichier WAV
    with wave.open(filename, 'w') as wav_file:
        # Paramètres du fichier WAV
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(sample_rate)
        
        # Écrire les données
        wav_file.writeframes(signal_16bit.tobytes())
    
    print(f"Son d'alerte créé : {filename}")
    print(f"Durée : {duration}s")
    print(f"Taux d'échantillonnage : {sample_rate} Hz")
    print(f"Format : 16-bit PCM Mono")

if __name__ == "__main__":
    try:
        create_alert_sound()
        print("\n✅ Son d'alerte généré avec succès !")
        print("Le fichier 'alert.wav' est maintenant dans ios/Resources/")
        print("\nCaractéristiques du son :")
        print("- Fréquence de base : 800 Hz")
        print("- Modulation de fréquence : 200 Hz")
        print("- Effet de pulse : 4 Hz")
        print("- Harmonies : 2ème et 3ème harmoniques")
        print("- Son dissuasif et professionnel")
        
    except Exception as e:
        print(f"❌ Erreur lors de la création du son : {e}")
        print("\nAssurez-vous que :")
        print("1. Le dossier ios/Resources/ existe")
        print("2. Vous avez les permissions d'écriture")
        print("3. Les modules numpy et wave sont installés")
        
        # Installation des dépendances si nécessaire
        print("\nPour installer numpy :")
        print("pip install numpy")
