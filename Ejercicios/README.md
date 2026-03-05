# Ejercicios: Flex - Capítulo 2

## Estructura del repositorio

```
├── ejercicio1.l     # fb2-3.l modificado: patrones más eficientes
├── ejercicio2.l     # fb2-4.l modificado: concordancia sin distinguir mayúsculas
├── ejercicio3.l     # fb2-4.l modificado: tabla de símbolos de tamaño variable
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

### ejercicio1.l — Patrones más eficientes en fb2-3

```bash
flex ejercicio1.l
gcc lex.yy.c -o ejercicio1
./ejercicio1 entrada4.txt
```

Ejemplo de salida:
```
   1 Poema del otoño - Ruben Dario
   2
   3 Tú, que estás la barba en la mano
   ...
```

---

### ejercicio2.l — Concordancia sin distinguir mayúsculas

```bash
flex ejercicio2.l
gcc lex.yy.c -o ejercicio2
./ejercicio2 entrada.txt
```

Ejemplo de salida:

<!-- Agregar captura de pantalla aquí -->

---

### ejercicio3.l — Concordancia con tabla de tamaño variable

```bash
flex ejercicio3.l
gcc lex.yy.c -o ejercicio3
./ejercicio3 entrada.txt entrada2.txt entrada3.txt
```

Ejemplo de salida:

<!-- Agregar captura de pantalla aquí -->

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
