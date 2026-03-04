# Actividad: Flex - Capítulo 2

## Estructura del repositorio

```
├── fb2-1.l          # Contador de palabras (un archivo)
├── fb2-2.l          # Contador de palabras (múltiples archivos)
├── fb2-3.l          # Numerador de líneas con soporte de #include anidados
├── fb2-4.l          # Generador de concordancia de texto
├── fb2-5.l          # Cross-referencer de código C
├── entrada.txt      # Poema "Poema del otoño" - Rubén Darío
├── entrada2.txt     # Poema "Infancia" - José Asunción Silva
├── entrada3.txt     # Poema "Reír Llorando" - Juan de Dios Peza
└── entrada4.txt     # Archivo con #include a los tres poemas anteriores
```

---

## Requisitos

- **Flex** (`flex`)
- **GCC** (`gcc`)
- Sistema operativo: Linux

### Instalación

```bash
sudo apt update
sudo apt install flex gcc
```

---

## Compilación y ejecución

### fb2-1.l — Contador de palabras (un archivo)

```bash
flex fb2-1.l
gcc lex.yy.c -o fb2-1
./fb2-1 entrada.txt
```

Ejemplo de entrada:
```
Poema del otoño - Ruben Dario
```

Ejemplo de salida:
```
       1       5      31
```
Ejecución:

<img width="625" height="38" alt="image" src="https://github.com/user-attachments/assets/12749146-88de-4347-b2ed-4ffa78c23eee" />


<img width="552" height="35" alt="image" src="https://github.com/user-attachments/assets/1bd716cc-d5e5-4b99-9229-5f786b1ab63a" />
---

### fb2-2.l — Contador de palabras (múltiples archivos)

```bash
flex fb2-2.l
gcc lex.yy.c -o fb2-2
./fb2-2 entrada.txt entrada2.txt entrada3.txt
```

Ejemplo de entrada:
```
entrada.txt   entrada2.txt   entrada3.txt
```

Ejemplo de salida:
```
     131     672    4821 entrada.txt
      73     375    2708 entrada2.txt
      80     399    2762 entrada3.txt
     284    1446   10291 total
```
---
Ejecución:

<img width="610" height="36" alt="image" src="https://github.com/user-attachments/assets/1b7f1d79-a2bd-4e39-bf79-407d4ce97da0" />

<img width="759" height="87" alt="image" src="https://github.com/user-attachments/assets/8f60eafa-68dc-4821-8e1a-a8cf0f117289" />



### fb2-3.l — Numerador de líneas con #include anidados

```bash
flex fb2-3.l
gcc lex.yy.c -o fb2-3
./fb2-3 entrada4.txt
```

Ejemplo de entrada (`entrada4.txt`):
```
#include <entrada.txt>
#include <entrada2.txt>
#include <entrada3.txt>
```

Ejemplo de salida:
```
   1 Poema del otoño - Ruben Dario
   2
   3 Tú, que estás la barba en la mano
   ...
```

> El programa sigue los `#include` de forma recursiva, numerando las líneas de cada archivo incluido como si fueran parte del flujo principal.

---

Ejecución:

<img width="619" height="35" alt="image" src="https://github.com/user-attachments/assets/30e54b65-25e5-4f7c-ae9e-45dd153b9bb9" />

<img width="575" height="410" alt="image" src="https://github.com/user-attachments/assets/3921cea1-bbbe-4343-8b3d-fb741ac6f1f2" />

<img width="398" height="426" alt="image" src="https://github.com/user-attachments/assets/593343b5-c838-42ba-b7f7-e26910b3b852" />

<img width="441" height="437" alt="image" src="https://github.com/user-attachments/assets/ccea2719-f338-4254-9eac-4121bff619f2" />

### fb2-4.l — Generador de concordancia de texto

```bash
flex fb2-4.l
gcc lex.yy.c -o fb2-4
./fb2-4 entrada3.txt
```

Ejemplo de entrada:
```
Viendo a Garrik —actor de la Inglaterra—
el pueblo al aplaudirlo le decía:
```

Ejemplo de salida:

<img width="624" height="32" alt="image" src="https://github.com/user-attachments/assets/c0a339c3-7af4-4b5f-8418-0c5af736bebc" />

<img width="555" height="435" alt="image" src="https://github.com/user-attachments/assets/0d18e761-d67d-4959-841a-aebe32015ea0" />

---

### fb2-5.l — Cross-referencer de código C

```bash
flex fb2-5.l
gcc lex.yy.c -o fb2-5
./fb2-5 lex.yy.c
```

> Se usa `lex.yy.c` (el archivo C generado por flex) como entrada, ya que este programa espera código C válido.

Ejemplo de salida:

<!-- Agregar captura de pantalla aquí -->

> Cada línea muestra un identificador seguido de los archivos y números de línea donde aparece. El símbolo `*` marca las definiciones.

---

## Notas

- `fb2-1.l` recibe el archivo como argumento directo (`./fb2-1 archivo.txt`).
- `fb2-2.l` acepta uno o más archivos como argumentos; si no se pasa ninguno, lee desde `stdin`.
- `fb2-3.l` requiere que los archivos referenciados en los `#include` estén en el mismo directorio de ejecución.
- `fb2-4.l` ignora palabras comunes en inglés (a, an, the, is...) y es insensible a mayúsculas.
- `fb2-5.l` está diseñado para analizar código C; pasarle texto plano producirá resultados con caracteres no reconocidos.

