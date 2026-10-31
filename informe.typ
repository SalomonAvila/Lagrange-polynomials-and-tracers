// Informe, Análisis Numérico, Proyecto Final 2026-3
#set document(title: "Proyecto Final: Lagrange y trazadores cúbicos", author: "Salomón Alfredo Ávila Larrotta")
#set page(paper: "a4", margin: (x: 2.3cm, y: 2.4cm), numbering: "1 de 1")
#set text(lang: "es", size: 10.5pt, font: "New Computer Modern")
#set par(justify: true, leading: 0.62em)
#set heading(numbering: "1.1.")
#set math.equation(numbering: "(1)", supplement: none)
#show heading.where(level: 1): set block(above: 1.4em, below: 0.8em)
#show raw.where(block: true): set text(size: 8pt)
#show raw.where(block: true): block.with(fill: luma(246), inset: 8pt, radius: 3pt, width: 100%)
#show figure.caption: set text(size: 9pt)

#let datos = csv("resultados.csv").slice(1)
// Formato de miles con espacio fino: 4619362 -> 4 619 362
#let miles(s) = {
  let c = s.clusters().rev()
  let out = ()
  for (i, d) in c.enumerate() {
    if i > 0 and calc.rem(i, 3) == 0 { out.push(sym.space.thin) }
    out.push(d)
  }
  out.rev().join()
}
// Tiempos de ejecución (microsegundos) medidos por los programas en C++.
#let tiempos(nombre) = {
  let d = (:)
  for r in csv(nombre).slice(1) { d.insert(r.at(0), (reps: int(r.at(1)), us: float(r.at(2)))) }
  d
}
#let tL = tiempos("tiempos_lagrange.csv")
#let tS = tiempos("tiempos_trazador.csv")
// Número con coma decimal y la cantidad de cifras decimales indicada.
#let dec(x, n) = {
  let s = str(calc.round(x, digits: n))
  if n > 0 {
    if not s.contains(".") { s += "." }
    let faltan = n - s.split(".").at(1).len()
    s += "0" * faltan
  }
  s.replace(".", ",")
}
#let veces(a, b) = str(int(calc.round(a / b)))

#let cient(s) = {
  let (m, e) = s.split("e")
  let m = m.replace(".", ",")
  $#m times 10^(#str(int(e)))$
}

#align(center)[
  #text(size: 9pt, smallcaps[Pontificia Universidad Javeriana])
  #v(0.6em)
  #text(size: 16pt, weight: "bold")[Polinomios de Lagrange y trazadores cúbicos: \ interpolación de la población de Croacia entre 1994 y 2023]
  #v(0.5em)
  Análisis Numérico, Proyecto Final \
  Salomón Alfredo Ávila Larrotta \
  #text(size: 9pt)[Noviembre de 2026]
]

#v(0.6em)
#block(inset: (x: 1.5em))[
  #text(size: 9.5pt)[*Resumen.* Se construyen, a partir de 25 datos anuales de población de Croacia, un polinomio interpolante de Lagrange de grado 24 y un trazador cúbico con condiciones de frontera naturales, y se usan ambos para estimar la población en cinco años reservados: 1995, 2000, 2008, 2015 y 2022. En el interior del intervalo los dos métodos alcanzan errores relativos del orden de $10^(-4)$. Cerca de los extremos, en cambio, el polinomio de Lagrange oscila con violencia debido al fenómeno de Runge y produce errores relativos de 12,3 y 8,3, es decir, de más del 800 %. El trazador cúbico mantiene errores por debajo de $#"1,1" times 10^(-3)$ en los cinco años.]
]

= Introducción

Interpolar consiste en construir una función que pase exactamente por un conjunto de datos conocidos, para luego usarla en la estimación de valores intermedios. Cuando los datos son numerosos surgen dos estrategias naturales: usar un único polinomio que pase por todos los puntos, que es el polinomio de Lagrange, o unir de forma suave muchos polinomios de grado bajo, uno por subintervalo, que es el trazador cúbico. El objetivo de este trabajo es comparar ambas estrategias sobre un caso real: la población de Croacia entre 1994 y 2023.

El archivo de datos del curso contiene 30 parejas de año y población. Cinco de ellas están resaltadas: 1995, 2000, 2008, 2015 y 2022. Estos cinco datos se excluyen de la construcción de los interpolantes y se reservan para medir la calidad de las aproximaciones mediante el error relativo
$ E_r = (|p - p^*|) / (|p|), $
donde $p$ es el valor exacto y $p^*$ el aproximado.

= Implementación

== Elección del lenguaje y organización del programa

Los algoritmos se implementaron en *C++*, con el estándar C++17. Se eligió este lenguaje por su velocidad, por el control explícito que ofrece sobre los tipos numéricos, en particular sobre la precisión extendida `long double`, y porque basta un compilador estándar como `g++`, `clang++` o el de Visual Studio para ejecutar los programas en cualquier sistema operativo. Los dos métodos se programaron desde cero, sin rutinas de interpolación externas y usando solo las cabeceras `<vector>`, `<cmath>`, `<cstdio>` y `<chrono>` de la librería estándar.

Cada algoritmo está en un único archivo autocontenido, que incluye los datos y todas sus dependencias. El archivo `lagrange.cpp` construye y evalúa el polinomio de Lagrange, imprime la tabla de errores y exporta en formato CSV los resultados, la curva y los tiempos de ejecución. El archivo `trazador_cubico.cpp` calcula los coeficientes del trazador natural, lo evalúa y produce las mismas salidas. Por último, el script auxiliar `graficas.py` lee los CSV producidos por los dos programas y dibuja las figuras de este informe.

Cada programa se compila y se ejecuta de inmediato:
```
g++ -std=c++17 -O2 -o lagrange lagrange.cpp && ./lagrange
g++ -std=c++17 -O2 -o trazador_cubico trazador_cubico.cpp && ./trazador_cubico
```
Ambos programas se organizan de la misma forma. Empiezan con un bloque de datos, siguen con la función `separarDatos`, que divide los datos en nodos y datos de prueba, continúan con las funciones del método numérico y terminan con la función `main`, que calcula las aproximaciones y el error relativo, mide los tiempos y escribe los archivos de salida. El código completo se incluye en el Anexo.

== Captura de los datos

Los 30 valores de población de la hoja `CROACIA` del archivo Excel del curso se copiaron en el arreglo constante `POBLACION`, indexado desde 1994, y los años resaltados se guardaron en el arreglo `SUBRAYADOS = {1995, 2000, 2008, 2015, 2022}`. Escribir los datos dentro del código evita depender de librerías para leer archivos de Excel, que no forman parte de la librería estándar de C++, y garantiza que el programa corra sin archivos adicionales.

La función `separarDatos` recorre los 30 años y, con ayuda de `esSubrayado(anio)`, los reparte en dos grupos de vectores. Los vectores `xNodos` y `yNodos` guardan los 25 años no resaltados y su población, que son los datos de interpolación. Los vectores `anioPrueba` y `yPrueba` guardan los 5 años resaltados y su población exacta, que sirven para medir el error.

== Polinomio de Lagrange

Dados $n + 1$ nodos distintos $(x_0, y_0), dots, (x_n, y_n)$, el polinomio de Lagrange es el único polinomio de grado a lo sumo $n$ que pasa por todos ellos:
$ P(x) = sum_(k=0)^n y_k L_k (x), quad quad L_k (x) = product_(j=0, j != k)^n (x - x_j) / (x_k - x_j). $ <lagrange>
Cada polinomio base $L_k$ vale 1 en $x_k$ y 0 en los demás nodos, por lo que $P(x_k) = y_k$. Con 25 nodos se obtiene un polinomio de grado 24.

La implementación sigue literalmente la ecuación @lagrange: la función `baseLagrange(k, x, nodos)` acumula el producto que define $L_k (x)$, y la función `lagrange(x, nodos, valores)` realiza la suma ponderada. Para que el resultado sea confiable se tomaron dos decisiones. La primera es trasladar la variable: en lugar de trabajar directamente con los años, se usa $t = "año" - 1994$, de modo que $t in [0, 29]$. Esto no cambia el polinomio, pero evita operar con números grandes. La segunda es usar precisión extendida: todos los cálculos se hacen con el tipo `long double`, al que el código llama `real`, y que en `g++` ofrece unas 19 cifras significativas en lugar de las 16 de `double`. Al imprimir, los valores se convierten a `double`, porque el compilador MinGW de Windows no muestra correctamente `long double` con `printf`.

```cpp
/** @brief Evalúa el k-ésimo polinomio base de Lagrange en x. */
real baseLagrange(int k, real x, const std::vector<real>& nodos) {
    real L = 1.0L;
    for (size_t j = 0; j < nodos.size(); j++) {
        if ((int)j != k) L *= (x - nodos[j]) / (nodos[k] - nodos[j]);
    }
    return L;
}

/** @brief Evalúa el polinomio interpolante P(x) = sum_k y_k L_k(x). */
real lagrange(real x, const std::vector<real>& nodos, const std::vector<real>& valores) {
    real suma = 0.0L;
    for (size_t k = 0; k < nodos.size(); k++)
        suma += valores[k] * baseLagrange((int)k, x, nodos);
    return suma;
}
```

Evaluar $P$ en un punto cuesta $O(n^2)$ operaciones, lo cual es despreciable para 25 nodos.

== Trazador cúbico natural

Un trazador cúbico $S$ es una función definida a trozos: en cada subintervalo $[x_j, x_(j+1)]$, con $j = 0, dots, n-1$,
$ S_j (x) = a_j + b_j (x - x_j) + c_j (x - x_j)^2 + d_j (x - x_j)^3. $
Se exige que $S$ interpole los datos y que $S$, $S'$ y $S''$ sean continuas en los nodos interiores. Las condiciones de frontera naturales son $S''(x_0) = S''(x_n) = 0$, lo que equivale a $c_0 = c_n = 0$.

Con $h_j = x_(j+1) - x_j$ y $a_j = y_j$, estas condiciones se reducen a un sistema cuadrado de $n + 1$ ecuaciones, $A arrow(c) = arrow(y)$, cuyas incógnitas son $c_0, dots, c_n$. La matriz de coeficientes es
$ A = mat(
  1, 0, 0, 0, dots, 0;
  h_0, 2(h_0 + h_1), h_1, 0, dots, 0;
  0, h_1, 2(h_1 + h_2), h_2, dots, 0;
  dots.v, dots.v, dots.v, dots.down, dots.down, dots.v;
  0, 0, dots, h_(n-2), 2(h_(n-2) + h_(n-1)), h_(n-1);
  0, 0, dots, 0, 0, 1;
) $
y los vectores de incógnitas y del lado derecho son
$ arrow(c) = mat(c_0; c_1; dots.v; c_(n-1); c_n), quad quad arrow(y) = mat(
  0;
  3/h_1 (a_2 - a_1) - 3/h_0 (a_1 - a_0);
  dots.v;
  3/h_(n-1) (a_n - a_(n-1)) - 3/h_(n-2) (a_(n-1) - a_(n-2));
  0;
). $
La primera y la última fila imponen $c_0 = c_n = 0$, que son las condiciones de frontera naturales, y cada fila interior resulta de exigir la continuidad de $S$, $S'$ y $S''$ en un nodo interior. La matriz es tridiagonal y estrictamente diagonal dominante, así que el sistema tiene solución única. Una vez conocidos los $c_j$, los demás coeficientes se obtienen con
$ b_j = 1/h_j (a_(j+1) - a_j) - h_j / 3 (2 c_j + c_(j+1)), quad quad d_j = (c_(j+1) - c_j) / (3 h_j). $

Los coeficientes se agrupan en la estructura `Trazador`, que guarda los nodos y los vectores `a`, `b`, `c` y `d`. La función `trazadorNatural(x, y)` sigue paso a paso la construcción general vista en clase: calcula las longitudes $h_j$, arma la matriz `A` y el vector `vecY`, resuelve el sistema con la función `eliminacionGaussiana` y, por último, obtiene $b_j$ y $d_j$ con las fórmulas anteriores:

```cpp
// Paso 2: matriz A. La primera y la última fila imponen c_0 = c_n = 0.
std::vector<std::vector<double>> A(n + 1, std::vector<double>(n + 1, 0.0));
A[0][0] = 1.0;
for (int j = 1; j < n; j++) {
    A[j][j - 1] = h[j - 1];
    A[j][j] = 2.0 * (h[j - 1] + h[j]);
    A[j][j + 1] = h[j];
}
A[n][n] = 1.0;

// Paso 3: vector y del lado derecho, con ceros en la primera y la última posición.
std::vector<double> vecY(n + 1, 0.0);
for (int j = 1; j < n; j++)
    vecY[j] = 3.0 / h[j] * (a[j + 1] - a[j]) - 3.0 / h[j - 1] * (a[j] - a[j - 1]);

// Paso 4: se resuelve A c = y para obtener c_0, ..., c_n.
std::vector<double> c = eliminacionGaussiana(A, vecY);

// Paso 5: b_j y d_j a partir de los c_j.
std::vector<double> b(n), d(n);
for (int j = 0; j < n; j++) {
    b[j] = (a[j + 1] - a[j]) / h[j] - h[j] / 3.0 * (2.0 * c[j] + c[j + 1]);
    d[j] = (c[j + 1] - c[j]) / (3.0 * h[j]);
}
```

La función `eliminacionGaussiana` anula los elementos que están debajo de la diagonal y después despeja la solución con sustitución hacia atrás. No necesita intercambiar filas, porque en una matriz estrictamente diagonal dominante ningún pivote se anula. Como recorre la matriz completa, de tamaño $(n + 1) times (n + 1)$, su costo es $O(n^3)$ operaciones, que para $n = 24$ sigue siendo muy poco. Para comprobar la implementación se resolvió también el Ejemplo 1 de clase, con los puntos $(5, 5)$, $(7, 2)$ y $(9, 4)$, y el programa obtuvo los mismos coeficientes: $c_1 = 15 slash 16$, $b_0 = -17 slash 8$, $b_1 = -1 slash 4$ y $d_0 = 5 slash 32$. Por su parte, `evaluarTrazador(t, S)` localiza el subintervalo que contiene a $t$ y evalúa el polinomio cúbico correspondiente. Como faltan los años reservados, los nodos no son equiespaciados y las longitudes $h_j$ valen 1 o 2 años. El algoritmo admite este caso sin modificaciones.

== Medición del tiempo de ejecución

Cada programa mide, con el reloj monótono `std::chrono::steady_clock` de la librería estándar, cuánto tarda cada etapa del algoritmo. Solo se cronometran los cálculos: la lectura de los datos, la impresión en consola y la escritura de archivos quedan por fuera. Se midieron tres etapas. La construcción es el cálculo de los coeficientes $a_j, b_j, c_j, d_j$ del trazador con `trazadorNatural`. El polinomio de Lagrange, en la forma de la ecuación @lagrange, no tiene esta etapa, porque no precalcula nada y hace todo el trabajo en cada evaluación. La segunda etapa es la evaluación en los 5 años de prueba, que produce las aproximaciones de la @tabla, y la tercera es la evaluación en la malla de 2001 puntos con la que se dibujan las curvas de las figuras.

Una sola ejecución de estas etapas puede durar menos de un microsegundo, por debajo de la resolución práctica del reloj. Por eso la función `medirMicrosegundos` repite cada etapa entre 200 y 100 000 veces y reporta el tiempo promedio por repetición. Para que el compilador, al optimizar el código, no elimine cálculos cuyo resultado no se usa, cada resultado se guarda en una variable `volatile`:

```cpp
/** @brief Tiempo promedio, en microsegundos, de una ejecución de f. */
template <typename F>
double medirMicrosegundos(F f, int reps) {
    auto inicio = std::chrono::steady_clock::now();
    for (int r = 0; r < reps; r++) f();
    auto fin = std::chrono::steady_clock::now();
    return std::chrono::duration<double, std::micro>(fin - inicio).count() / reps;
}
```

Los tiempos se imprimen en consola y se exportan a `tiempos_lagrange.csv` y `tiempos_trazador.csv`.

== Verificación

Para comprobar las implementaciones, sus resultados se compararon con cálculos independientes: el polinomio de Lagrange se evaluó también en aritmética racional exacta, sin redondeo alguno, y con la rutina `BarycentricInterpolator` de SciPy, y el trazador con `CubicSpline` de SciPy usando `bc_type="natural"`. Los valores coinciden en todas las cifras significativas reportadas. En particular, la coincidencia con la aritmética exacta muestra que el redondeo no influye en los resultados del polinomio de Lagrange.

= Resultados

La @tabla resume las aproximaciones obtenidas en los cinco años reservados.

#figure(
  table(
    columns: 6,
    align: (center, right, right, right, right, right),
    stroke: none,
    inset: (x: 6pt, y: 4.5pt),
    table.hline(stroke: 0.6pt),
    table.header(
      [], [], table.cell(colspan: 2, align: center)[*Lagrange*], table.cell(colspan: 2, align: center)[*Trazador cúbico*],
      [*Año*], [*Exacto*], [*Aproximado*], [*Error rel.*], [*Aproximado*], [*Error rel.*],
    ),
    table.hline(stroke: 0.4pt),
    ..datos.map(r => (
      r.at(0), miles(r.at(1)), miles(r.at(2)), cient(r.at(3)), miles(r.at(4)), cient(r.at(5)),
    )).flatten(),
    table.hline(stroke: 0.6pt),
  ),
  caption: [Población exacta y aproximada de Croacia, en habitantes, en los años reservados, con el error relativo de cada método.],
) <tabla>

La @completa muestra ambos interpolantes en todo el intervalo junto con los 30 datos exactos. La escala vertical está dominada por las oscilaciones del polinomio de Lagrange, que superan los 150 millones de habitantes cerca de 1994 cuando la población real es de unos 4,6 millones.

#figure(
  image("fig_completa.svg", width: 100%),
  caption: [Vista completa: el polinomio de Lagrange de grado 24 oscila con fuerza en el primer y el último subintervalo.],
) <completa>

La @acercamiento repite la gráfica en la escala de los datos. El trazador cúbico, dibujado con línea discontinua, sigue la tendencia en todo el periodo, mientras que el polinomio de Lagrange solo se comporta bien entre aproximadamente 1999 y 2017.

#figure(
  image("fig_acercamiento.svg", width: 100%),
  caption: [Acercamiento a la escala de los datos. Los rombos son los valores exactos de los años reservados.],
) <acercamiento>

Finalmente, la @errores compara los errores relativos en escala logarítmica.

#figure(
  image("fig_errores.svg", width: 100%),
  caption: [Error relativo de cada método en los años reservados, en escala logarítmica.],
) <errores>

== Tiempo de ejecución

Los programas se compilaron y ejecutaron en el equipo descrito en la @equipo. Ambos programas son secuenciales, así que usan un solo hilo del procesador. Las mediciones se hicieron con el portátil conectado a la corriente y con el perfil de energía en modo de alto rendimiento.

#figure(
  table(
    columns: (auto, auto),
    align: (left, left),
    stroke: none,
    inset: (x: 8pt, y: 4pt),
    table.hline(stroke: 0.6pt),
    [*Equipo*], [Portátil ASUS TUF Dash F15, modelo FX517ZC],
    [*Procesador*], [Intel Core i5 12450H de 12.ª generación con 8 núcleos, 4 de rendimiento y 4 de eficiencia, 12 hilos y frecuencia máxima de 4,4 GHz],
    [*Memoria caché*], [L1 de datos de 320 KiB, L2 de 7 MiB y L3 de 12 MiB],
    [*Memoria RAM*], [32 GB],
    [*Sistema operativo*], [Fedora Linux 44 de 64 bits con núcleo Linux 7.2],
    [*Compilador*], [GCC 16.2.1 con optimización de nivel 2 y estándar C++17],
    table.hline(stroke: 0.6pt),
  ),
  caption: [Especificaciones del equipo en el que se ejecutaron los programas.],
) <equipo>

La @tiempos reúne los tiempos medidos. Los valores cambian de una máquina a otra y, en menor medida, de una ejecución a otra, pues en corridas repetidas variaron menos de un 10 %, pero las proporciones entre los dos métodos se mantienen.

#figure(
  table(
    columns: 3,
    align: (left, right, right),
    stroke: none,
    inset: (x: 8pt, y: 4.5pt),
    table.hline(stroke: 0.6pt),
    table.header([*Etapa*], [*Lagrange*], [*Trazador cúbico*]),
    table.hline(stroke: 0.4pt),
    [Construcción de coeficientes], [No aplica], [#dec(tS.construccion.us, 3)],
    [Evaluación en los 5 años de prueba], [#dec(tL.prueba.us, 3)], [#dec(tS.prueba.us, 3)],
    [Evaluación en la malla de 2001 puntos], [#dec(tL.malla.us, 1)], [#dec(tS.malla.us, 1)],
    table.hline(stroke: 0.4pt),
    [Tiempo por evaluación en la malla], [#dec(tL.malla.us / 2001 * 1000, 0) ns], [#dec(tS.malla.us / 2001 * 1000, 1) ns],
    table.hline(stroke: 0.6pt),
  ),
  caption: [Tiempo promedio de ejecución de cada etapa en microsegundos, donde 1 µs equivale a $10^(-6)$ s. La última fila, en nanosegundos, divide el tiempo de la malla entre sus 2001 puntos.],
) <tiempos>

Los dos métodos son prácticamente instantáneos para este problema: incluso la etapa más lenta, evaluar el polinomio de Lagrange en los 2001 puntos de la malla, tarda menos de #dec(calc.ceil(tL.malla.us / 1000), 0) milisegundos. Aun así, la diferencia relativa es grande. Calcular los coeficientes del trazador cuesta #dec(tS.construccion.us, 1) µs, pero se hace una sola vez, y después cada evaluación del trazador es unas #veces(tL.malla.us, tS.malla.us) veces más rápida que una del polinomio de Lagrange. Sumando la construcción y las evaluaciones, el trazador obtiene las cinco estimaciones de la @tabla en #dec(tS.construccion.us + tS.prueba.us, 1) µs, frente a #dec(tL.prueba.us, 1) µs del polinomio de Lagrange.

= Análisis y comparación

== Diferencias observadas

*En los extremos*, es decir, en 1995 y 2022, la diferencia es enorme. El polinomio de Lagrange estima 61,3 millones de habitantes en 1995 y 36,3 millones en 2022, frente a valores reales de 4,6 y 3,9 millones: errores relativos de 12,3 y 8,3. El trazador cúbico, en cambio, comete errores de $#"5,5" times 10^(-5)$ y $#"1,2" times 10^(-4)$, es decir, se equivoca en unos pocos cientos de habitantes.

*En el interior*, es decir, en 2000, 2008 y 2015, ambos métodos son buenos, con errores entre $10^(-5)$ y $10^(-3)$. El trazador es mejor en 2008 y 2015. En 2000, sin embargo, el polinomio de Lagrange, con un error de $#"3,3" times 10^(-4)$, supera al trazador, con $#"1,1" times 10^(-3)$. Es el único año en el que Lagrange gana.

== ¿Por qué se producen estas diferencias?

*El fenómeno de Runge.* El error de la interpolación polinomial en un punto $x$ es
$ f(x) - P(x) = (f^((n+1))(xi)) / ((n+1)!) product_(i=0)^n (x - x_i), $
para algún $xi$ en el intervalo. El factor $omega(x) = product (x - x_i)$ depende solo de la ubicación de los nodos, y para nodos equiespaciados o casi equiespaciados crece de forma explosiva hacia los extremos del intervalo. Con los nodos de este problema, $|omega|$ vale $#"8,7" times 10^24$ en 1995 y $#"5,2" times 10^24$ en 2022, pero apenas $#"1,1" times 10^19$ en 2008: hay una diferencia de cinco a seis órdenes de magnitud entre el centro y los bordes. Para que un único polinomio de grado 24 pase por los 25 nodos, se ve obligado a oscilar con gran amplitud entre los nodos extremos, justo donde caen 1995, entre los nodos 1994 y 1996, y 2022, entre los nodos 2021 y 2023. Que los resultados en precisión extendida coincidan con los de la aritmética exacta confirma que se trata de una limitación del método y no de errores de redondeo.

*La ventaja de trabajar por tramos.* El trazador cúbico nunca usa polinomios de grado mayor que 3, y cada tramo depende sobre todo de los datos cercanos. Por eso no hay oscilaciones que se propaguen por el intervalo: un dato de 2023 tiene muy poca influencia sobre la estimación en 1995. La condición de frontera natural, que impone $S'' = 0$ en los extremos, introduce un pequeño error cerca de los bordes, pero en este caso resultó insignificante.

*El caso del año 2000.* La población de Croacia baja casi linealmente, unos 60 000 habitantes por año, hasta el año 2000, y a partir de 2001 se estabiliza de forma abrupta en torno a 4,3 millones. Con el año 2000 excluido, este cambio de tendencia ocurre dentro del subintervalo $[1999, 2001]$, de dos años. El trazador, que está obligado a tener segunda derivada continua, suaviza ese quiebre y sobrestima la población en unos 4 500 habitantes. El polinomio de Lagrange también es suave, pero en esa zona central su comportamiento resultó estar más cerca del dato real. La ventaja es circunstancial y no contradice la conclusión general: ningún interpolante suave puede reproducir con exactitud un cambio brusco que ocurre entre dos nodos.

== Comparación de costos

Los tiempos de la @tiempos coinciden con lo que predice el conteo de operaciones. El trazador arma y resuelve el sistema $A arrow(c) = arrow(y)$ una sola vez. La eliminación gaussiana sobre la matriz completa cuesta $O(n^3)$ operaciones, y por eso la construcción es la etapa más costosa del trazador. Si se aprovechara que la matriz es tridiagonal, el algoritmo de Thomas resolvería el mismo sistema en $O(n)$ operaciones, pero se prefirió la eliminación gaussiana general para seguir la construcción vista en clase. Luego, cada evaluación solo localiza el subintervalo, con a lo sumo $n$ comparaciones, y evalúa un polinomio cúbico. El polinomio de Lagrange, en cambio, no reutiliza nada entre evaluaciones: cada una calcula los $n + 1$ polinomios base, cada uno con $n$ productos y divisiones, es decir, $O(n^2)$ operaciones. Con $n = 24$ son unas $25 times 24 = 600$ divisiones por punto, hechas en `long double`, que es más lento que `double`. Eso explica que una evaluación de Lagrange tarde cerca de #dec(tL.malla.us / 2001 * 1000, 0) ns frente a unos #dec(tS.malla.us / 2001 * 1000, 0) ns del trazador.

La diferencia en las evaluaciones crecería con más datos: duplicar el número de nodos multiplica por cerca de cuatro el costo de cada evaluación de Lagrange, pero solo por dos el del trazador. La construcción del trazador, en cambio, se multiplicaría por cerca de ocho, aunque solo se hace una vez. El costo de Lagrange podría bajar a $O(n)$ por evaluación usando la fórmula baricéntrica, que precalcula unos pesos, pero eso no corregiría su principal defecto: la estabilidad. Agregar datos mejora el trazador, mientras que en el polinomio de Lagrange con nodos equiespaciados suele empeorar las oscilaciones.

= Conclusiones

Con muchos datos equiespaciados, el polinomio interpolante de Lagrange no es una herramienta adecuada para aproximar valores cerca de los extremos del intervalo: en 1995 y 2022 produjo estimaciones entre 9 y 13 veces mayores que la población real. El trazador cúbico natural, en cambio, aproximó los cinco años con errores relativos inferiores a $#"1,1" times 10^(-3)$, y en cuatro de ellos inferiores a $#"1,2" times 10^(-4)$.

En el centro del intervalo ambos métodos tienen una precisión comparable. Lagrange solo superó al trazador en el año 2000, debido a un cambio brusco de tendencia en los datos que ningún interpolante suave puede capturar por completo.

El trazador también es más rápido. Sus coeficientes se calculan una sola vez, en unos #dec(tS.construccion.us, 0) µs, y a partir de ahí cada evaluación es unas #veces(tL.malla.us, tS.malla.us) veces más rápida que la del polinomio de Lagrange. Para 25 datos ambos tiempos son despreciables, pero la diferencia crece con el número de nodos.

Por todo lo anterior, para interpolar conjuntos numerosos de datos, como las series de población, es preferible usar trazadores cúbicos u otros métodos por tramos en lugar de un único polinomio de grado alto.

#pagebreak()
#set heading(numbering: none)
= Anexo: código fuente completo

== `lagrange.cpp`
#raw(read("lagrange.cpp"), lang: "cpp", block: true)

== `trazador_cubico.cpp`
#raw(read("trazador_cubico.cpp"), lang: "cpp", block: true)

== `graficas.py`, script auxiliar para las figuras
#raw(read("graficas.py"), lang: "python", block: true)
