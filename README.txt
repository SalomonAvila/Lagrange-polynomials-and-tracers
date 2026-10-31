Proyecto Final - Análisis Numérico (2026-3) - Croacia
Salomón Alfredo Ávila Larrotta

Requisitos: cualquier compilador de C++17 (g++, clang++, MinGW, Visual Studio).
No se necesitan librerías externas: los datos están dentro de cada .cpp.

  g++ -std=c++17 -O2 -o lagrange lagrange.cpp
  ./lagrange                    (Windows: lagrange.exe)

  g++ -std=c++17 -O2 -o trazador_cubico trazador_cubico.cpp
  ./trazador_cubico             (Windows: trazador_cubico.exe)

Cada programa imprime la tabla de errores relativos y el tiempo de ejecución
de cada etapa del algoritmo, y genera tres CSV (resultados_*.csv, curva_*.csv
y tiempos_*.csv).

Opcional (figuras del informe): python graficas.py  (requiere matplotlib)
Informe: informe.pdf  (fuente Typst: informe.typ; compilar con  typst compile informe.typ)
