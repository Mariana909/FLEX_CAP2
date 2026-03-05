# Ejercicios: Flex - Capítulo 2

## Estructura del repositorio

```
├── e1-fb2-3.l     # fb2-3.l modificado: patrones más eficientes
├── e2-fb2-4.l     # fb2-4.l modificado: concordancia sin distinguir mayúsculas
├── e3-fb2-4.l     # fb2-4.l modificado: tabla de símbolos de tamaño variable
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

### e1-fb2-3.l — Patrones más eficientes en fb2-3

```bash
flex e1-fb2-3.l
gcc lex.yy.c -o e1-fb2-3.l
./e1-fb2-3.l entrada4.txt
```

Ejemplo de salida:
```
   1 Poema del otoño - Ruben Dario
   2
   3 Tú, que estás la barba en la mano
   ...
```

---

<img width="417" height="251" alt="image" src="https://github.com/user-attachments/assets/acea6f5c-0fdd-493d-9aad-4298d744a132" />


### e2-fb2-4.l — Concordancia sin distinguir mayúsculas

```bash
flex e2-fb2-4.l
gcc lex.yy.c -o e2-fb2-4.l
./e2-fb2-4.l entrada.txt
```

Ejemplo de salida:

<img width="440" height="412" alt="image" src="https://github.com/user-attachments/assets/2be252ac-35bc-4af1-bcc0-d52229899f80" />


---

### e3-fb2-4.l — Concordancia con tabla de tamaño variable

```bash
flex e3-fb2-4.l
gcc lex.yy.c -o e3-fb2-4.l
./e3-fb2-4.l entrada.txt entrada2.txt entrada3.txt
```

Ejemplo de salida:

<img width="580" height="378" alt="image" src="https://github.com/user-attachments/assets/e2e7aa2a-91a0-487e-a3d8-af0e37874b76" />


---

## Respuestas a las preguntas del capítulo

### Pregunta 1 — ¿Por qué fb2-3.l no usa `^.*\n` para leer líneas completas?

El `.` en Flex nunca hace match con el salto de línea `\n`, por lo que `^.*\n` no puede capturar una línea completa por sí solo.

Pero el problema más importante es otro: Flex siempre le da prioridad a la regla que captura más caracteres. Si se usara `^.*\n` como regla general, esta se tragaría toda la línea de un `#include` antes de que la regla específica pudiera detectarla, y el programa nunca procesaría los archivos incluidos.

La solución es usar una combinación de patrones que excluya las líneas que empiezan con `#`:

```
^[^#].*\n   |
^\n         { fprintf(yyout, "%4d %s", yylineno++, yytext); }
```

`^[^#].*\n` captura líneas completas que no empiezan con `#`, y `^\n` cubre las líneas vacías, que `^[^#].*\n` no puede capturar porque necesita al menos un carácter antes del salto de línea.

---

### Pregunta 2 — Concordancia sin distinguir mayúsculas y minúsculas

Se hacen dos cambios en `fb2-4.l`:

**1. En `symhash()`**, se convierte cada carácter a minúscula antes de calcular su posición en la tabla, para que "Amor" y "amor" vayan al mismo lugar:

```c
while(c = tolower(*sym++)) hash = hash * 9 ^ c;
```

**2. En `lookup()`**, se reemplaza `strcmp` por `strcasecmp` para que la comparación entre palabras ignore mayúsculas y minúsculas:

```c
if(sp->name && !strcasecmp(sp->name, sym)) return sp;
```

Además se ajustan las palabras comunes ignoradas al español, ya que las entradas son poemas en ese idioma.

---

### Pregunta 3 — Tabla de símbolos de tamaño variable

El programa original usa una tabla de tamaño fijo. Cuando se llena, simplemente termina con un error. Para evitar eso se implementa **rehashing**: cuando la tabla se llena, se crea una nueva del doble de tamaño, se copian todas las palabras recalculando su posición, y se libera la tabla vieja.

El enunciado propone dos técnicas: rehashing y chaining. Se eligió **rehashing** porque la otra técnica (chaining) almacena los símbolos en listas enlazadas dispersas en memoria, lo que haría muy complicado ordenarlos con `qsort` al momento de imprimir los resultados. Con rehashing la tabla sigue siendo un bloque contiguo de memoria y `qsort` funciona igual que antes.

Los cambios principales son:

- La tabla pasa de ser fija a reservarse dinámicamente con `calloc` al inicio del programa.
- Se agrega la función `rehash()` que crea una tabla nueva del doble de tamaño, copia los símbolos recalculando sus posiciones y libera la tabla vieja.
- Cuando `lookup()` detecta que la tabla está llena, llama a `rehash()` y reintenta la búsqueda.

```c
fputs("symbol table overflow\n", stderr);
rehash();
return lookup(sym);
```
