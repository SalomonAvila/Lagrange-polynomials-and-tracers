Proyecto Final - Análisis Numérico (2026-3) - Croacia
Salomón Alfredo Ávila Larrotta

Interpolación de la población de Croacia (1994-2023) con un polinomio de
Lagrange y con un trazador cúbico natural, construidos con los 25 datos no
subrayados y evaluados en los 5 años subrayados (1995, 2000, 2008, 2015, 2022).

Archivos
  lagrange.cpp          Polinomio de Lagrange de grado 24, en long double.
  trazador_cubico.cpp   Trazador cúbico natural: arma la matriz A y el vector y,
                        resuelve A c = y por eliminación gaussiana y calcula b y d.
  graficas.py           Dibuja las figuras del informe a partir de los CSV.
  informe.pdf           Informe final (fuente Typst: informe.typ).

Requisitos: cualquier compilador de C++17 (g++, clang++, MinGW, Visual Studio).
No se necesitan librerías externas: los datos están dentro de cada .cpp.

  g++ -std=c++17 -O2 -o lagrange lagrange.cpp
  ./lagrange                    (Windows: lagrange.exe)

  g++ -std=c++17 -O2 -o trazador_cubico trazador_cubico.cpp
  ./trazador_cubico             (Windows: trazador_cubico.exe)

Cada programa imprime la tabla de errores relativos y el tiempo de ejecución
de cada etapa del algoritmo, y genera tres CSV:
  resultados_*.csv   aproximación y error relativo en los 5 años subrayados
  curva_*.csv        el interpolante evaluado en 2001 puntos, para graficar
  tiempos_*.csv      tiempo promedio de cada etapa, en microsegundos

Opcional (figuras del informe, después de correr los dos programas):
  python graficas.py            (requiere matplotlib y la fuente Noto Sans)

Informe: typst compile informe.typ
