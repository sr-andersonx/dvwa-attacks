
# TP N°1 - DVWA (Dam Vulnerabilities Web Applications)

Este respositorio contiene algunos recursos utilizados para los ataques:
* fuerza bruta, 
* por diccionario
* páginas web utilizadas para ataques CSFR 
* página utilizada para Open HTTP Redirect la cual se desplegó en Netlify

Se deja un pequeño instructivo sobre la utilización del script de fuerza bruta

- Dar permisos de ejecución
```bash
chmod +x brute_attack.sh
```
- Utilizando diccionario:
Ejecutar -> ```dictionary``` (default)
```bash
./attack.sh [-m modo] [-d dictionary_path ] [-u user] [-p password]

- Otra opción:
Ejecutar -> ```brute``` (default credentials: admin/password)
```bash
./brute_attack.sh [-m brute] [-l min:max] [-u user] [-p password]
```

- Ver menú de ayuda:
```bash
./brute_attack.sh --help
```
