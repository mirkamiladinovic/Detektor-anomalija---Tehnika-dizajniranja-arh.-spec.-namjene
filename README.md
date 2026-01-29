# Detektor anomalija

Ovaj repozitorijum sadrži **projekat za detekciju anomalija** implementiran u **VHDL-u**, razvijen u okviru predmeta **Tehnika dizajniranja arhitektura specijalizovane namjene**.

---

## 📁 Sadržaj repozitorijuma

- **VHDL kod** glavnog modula detektora  
  (`anomaly_detector.vhd`)
- **Testbench** za simulaciju  
  (`tb_anomaly_detector.vhd`)
- **Projektne datoteke za Quartus**  
  (`.qpf`, `.qsf`, `.qws`)
- **Simulacijski i izlazni fajlovi**  
  (npr. `output_files`, `simulation/modelsim`)
- **Izvještaji i podaci o simulaciji**  
  (`*.rpt`)

---

## 🧠 Šta radi ovaj projekt?

Projekat implementira **detektor anomalija u digitalnoj logici** koristeći VHDL. 
Dizajn može uključivati logiku za **prepoznavanje neobičnih obrazaca** u ulaznim podacima (npr. signalima ili nizovima bitova).

---

## 🚀 Kako koristiti ovaj repo

1. Otvoriti projekat u **Intel Quartus Prime**.
2. Pokrenuti kompilaciju i sintezu dizajna.
3. Izvršiti simulaciju pomoću **ModelSim-a** i testbench fajlova.
