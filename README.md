# Proyecto Final - Análisis Numérico (2026-3) - Croacia

**Autor:** Salomón Alfredo Ávila Larrotta

## Descripción del Proyecto

Interpolación de la población de Croacia (1994-2023) utilizando un polinomio de Lagrange y un trazador cúbico natural, construidos con los 25 datos no subrayados y evaluados en los 5 años subrayados (**1995**, **2000**, **2008**, **2015**, **2022**).

---

## Estructura de Archivos

* **`lagrange.cpp`** — Polinomio de Lagrange de grado 24, implementado en `long double`.
* **`trazador_cubico.cpp`** — Trazador cúbico natural: arma la matriz $A$ y el vector $y$, resuelve $Ac = y$ por eliminación gaussiana y calcula los coeficientes $b$ y $d$.
* **`graficas.py`** — Dibuja las figuras del informe a partir de los archivos CSV.
* **`informe.pdf`** — Informe final (fuente Typst: `informe.typ`).

---

## Requisitos y Compilación

* **Requisitos:** Cualquier compilador compatible con C++17 (`g++`, `clang++`, MinGW, Visual Studio).
* No se necesitan librerías externas: los datos están integrados dentro de cada archivo `.cpp`.

### Comandos de Compilación y Ejecución

#### Opción 1: Lagrange

```bash
g++ -std=c++17 -O2 -o lagrange lagrange.cpp
./lagrange              # (Windows: lagrange.exe)

```

#### Opción 2: Trazador Cúbico

```bash
g++ -std=c++17 -O2 -o trazador_cubico trazador_cubico.cpp
./trazador_cubico       # (Windows: trazador_cubico.exe)

```

---

## Salidas Generadas

Cada programa imprime la tabla de errores relativos y el tiempo de ejecución de cada etapa del algoritmo, generando tres archivos CSV:

* **`resultados_*.csv`** — Aproximación y error relativo en los 5 años subrayados.
* **`curva_*.csv`** — El interpolante evaluado en 2001 puntos (para graficar).
* **`tiempos_*.csv`** — Tiempo promedio de cada etapa, en microsegundos.

---

## Generación de Figuras e Informe (Opcional)

Para generar las figuras del informe (después de correr los dos programas anteriores; requiere `matplotlib` y la fuente *Noto Sans*):

```bash
python graficas.py

```

Para compilar el documento final en Typst:

```bash
typst compile informe.typ

```
