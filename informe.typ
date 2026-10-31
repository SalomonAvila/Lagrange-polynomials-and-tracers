// Informe — Análisis Numérico, Proyecto Final (2026-3)
#set document(title: "Proyecto Final — Lagrange vs. trazadores cúbicos", author: "Salomón Alfredo Ávila Larrotta")
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
#let cient(s) = {
  let (m, e) = s.split("e")
  let m = m.replace(".", ",")
  $#m times 10^(#str(int(e)))$
}

#align(center)[
  #text(size: 9pt, smallcaps[Pontificia Universidad Javeriana · Facultad de Ciencias · Departamento de Matemáticas])
  #v(0.6em)
  #text(size: 16pt, weight: "bold")[Polinomios de Lagrange y trazadores cúbicos: \ interpolación de la población de Croacia (1994–2023)]
  #v(0.5em)
  Análisis Numérico — Proyecto Final \
  Salomón Alfredo Ávila Larrotta \
  #text(size: 9pt)[Noviembre de 2026]
]

#v(0.6em)
#block(inset: (x: 1.5em))[
  #text(size: 9.5pt)[*Resumen.* Se construyen, a partir de 25 datos anuales de población de Croacia, un polinomio interpolante de Lagrange de grado 24 y un trazador cúbico con condiciones de frontera naturales, y se usan ambos para estimar la población en cinco años reservados (1995, 2000, 2008, 2015 y 2022). En el interior del intervalo los dos métodos alcanzan errores relativos del orden de $10^(-4)$; cerca de los extremos, en cambio, el polinomio de Lagrange oscila con violencia (fenómeno de Runge) y produce errores relativos de 12,3 y 8,3, es decir, de más del 800 %. El trazador cúbico mantiene errores por debajo de $#"1,1" times 10^(-3)$ en los cinco años.]
]

= Introducción

Interpolar consiste en construir una función que pase exactamente por un conjunto de datos conocidos, para luego usarla en la estimación de valores intermedios. Cuando los datos son numerosos surgen dos estrategias naturales: usar un único polinomio que pase por todos los puntos (polinomio de Lagrange) o unir muchos polinomios de grado bajo, uno por subintervalo, de forma suave (trazador cúbico). El objetivo de este trabajo es comparar ambas estrategias sobre un caso real: la población de Croacia entre 1994 y 2023.

El archivo de datos del curso contiene 30 parejas (año, población). Cinco de ellas están resaltadas: 1995, 2000, 2008, 2015 y 2022. Estos cinco datos se excluyen de la construcción de los interpolantes y se reservan para medir la calidad de las aproximaciones mediante el error relativo
$ E_r = (|p - p^*|) / (|p|), $
donde $p$ es el valor exacto y $p^*$ el aproximado.

= Implementación

== Elección del lenguaje y organización del programa

Los algoritmos se implementaron en *C++* (estándar C++17). Se eligió este lenguaje por su velocidad, por el control explícito que ofrece sobre los tipos numéricos (en particular, la precisión extendida `long double`) y porque basta un compilador estándar, como `g++`, `clang++` o el de Visual Studio, para ejecutar los programas en cualquier sistema operativo. Los dos métodos se programaron desde cero, usando solo la librería estándar (`<vector>`, `<cmath>` y `<cstdio>`), sin rutinas de interpolación externas.

Cada algoritmo está en un único archivo autocontenido, que incluye los datos y todas sus dependencias:

#table(
  columns: (auto, 1fr),
  stroke: none,
  inset: (x: 6pt, y: 4pt),
  table.hline(stroke: 0.6pt),
  [*Archivo*], [*Función*],
  table.hline(stroke: 0.4pt),
  [`lagrange.cpp`], [Construcción y evaluación del polinomio de Lagrange; imprime la tabla de errores y exporta los resultados y la curva en formato CSV.],
  [`trazador_cubico.cpp`], [Cálculo de los coeficientes del trazador natural, evaluación, tabla de errores y exportación a CSV.],
  [`graficas.py`], [Script auxiliar que lee los CSV producidos por los programas en C++ y dibuja las figuras de este informe.],
  table.hline(stroke: 0.6pt),
)

Cada programa se compila y se ejecuta de inmediato:
```
g++ -std=c++17 -O2 -o lagrange lagrange.cpp && ./lagrange
g++ -std=c++17 -O2 -o trazador_cubico trazador_cubico.cpp && ./trazador_cubico
```
Ambos programas se organizan de la misma forma: (i) un bloque de datos, (ii) la función `separarDatos`, que divide los datos en nodos y datos de prueba, (iii) las funciones del método numérico y (iv) la función `main`, que calcula las aproximaciones, el error relativo y escribe los archivos de salida. El código completo se incluye en el Anexo.

== Captura de los datos

Los 30 valores de población de la hoja `CROACIA` del archivo Excel del curso se copiaron en el arreglo constante `POBLACION`, indexado desde 1994, y los años resaltados se guardaron en el arreglo `SUBRAYADOS = {1995, 2000, 2008, 2015, 2022}`. Escribir los datos dentro del código evita depender de librerías para leer archivos de Excel, que no forman parte de la librería estándar de C++, y garantiza que el programa corra sin archivos adicionales.

La función `separarDatos` recorre los 30 años y, con ayuda de `esSubrayado(anio)`, los reparte en dos grupos de vectores:

- `xNodos`, `yNodos`: los 25 años no resaltados y su población (datos de interpolación);
- `anioPrueba`, `yPrueba`: los 5 años resaltados y su población exacta.

== Polinomio de Lagrange

Dados $n + 1$ nodos distintos $(x_0, y_0), dots, (x_n, y_n)$, el polinomio de Lagrange es el único polinomio de grado a lo sumo $n$ que pasa por todos ellos:
$ P(x) = sum_(k=0)^n y_k L_k (x), quad quad L_k (x) = product_(j=0, j != k)^n (x - x_j) / (x_k - x_j). $ <lagrange>
Cada polinomio base $L_k$ vale 1 en $x_k$ y 0 en los demás nodos, por lo que $P(x_k) = y_k$. Con 25 nodos se obtiene un polinomio de grado 24.

La implementación sigue literalmente la ecuación @lagrange: la función `baseLagrange(k, x, nodos)` acumula el producto que define $L_k (x)$, y la función `lagrange(x, nodos, valores)` realiza la suma ponderada. Se tomaron dos decisiones para que el resultado sea confiable:

+ *Traslación de la variable.* En lugar de trabajar con años como 2023, se usa $t = "año" - 1994$, de modo que $t in [0, 29]$. Esto no cambia el polinomio, pero evita operar con números grandes.
+ *Precisión extendida.* Todos los cálculos se hacen con el tipo `long double` (alias `real` en el código), que en `g++` ofrece unas 19 cifras significativas en lugar de las 16 de `double`. Al imprimir, los valores se convierten a `double`, porque algunos compiladores de Windows (MinGW) no muestran correctamente `long double` con `printf`.

```cpp
// Evalúa el k-ésimo polinomio base L_k en el punto x.
real baseLagrange(int k, real x, const std::vector<real>& nodos) {
    real L = 1.0L;
    for (size_t j = 0; j < nodos.size(); j++) {
        if ((int)j != k) L *= (x - nodos[j]) / (nodos[k] - nodos[j]);
    }
    return L;
}

// Evalúa el polinomio interpolante P(x) = sum_k y_k L_k(x).
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

Con $h_j = x_(j+1) - x_j$ y $a_j = y_j$, estas condiciones se reducen a un sistema lineal tridiagonal en las incógnitas $c_j$:
$ h_(j-1) c_(j-1) + 2 (h_(j-1) + h_j) c_j + h_j c_(j+1) = 3/h_j (a_(j+1) - a_j) - 3/h_(j-1) (a_j - a_(j-1)), $
para $j = 1, dots, n - 1$. La matriz es estrictamente diagonal dominante, así que el sistema tiene solución única. Una vez conocidos los $c_j$,
$ b_j = (a_(j+1) - a_j) / h_j - h_j / 3 (c_(j+1) + 2 c_j), quad quad d_j = (c_(j+1) - c_j) / (3 h_j). $

Los coeficientes se agrupan en la estructura `Trazador`, que guarda los nodos y los vectores `a`, `b`, `c` y `d`. La función `trazadorNatural(x, y)` implementa el Algoritmo 3.4 de Burden y Faires. El sistema tridiagonal se resuelve con la factorización de Crout (algoritmo de Thomas) en tres fases: cálculo del lado derecho `alfa`, eliminación hacia adelante (`l`, `mu`, `z`) y sustitución hacia atrás para obtener $c$, $b$ y $d$:

```cpp
// Pasos 3-5: factorización de Crout y sustitución hacia adelante.
for (int i = 1; i < n; i++) {
    l[i] = 2.0 * (x[i + 1] - x[i - 1]) - h[i - 1] * mu[i - 1];
    mu[i] = h[i] / l[i];
    z[i] = (alfa[i] - h[i - 1] * z[i - 1]) / l[i];
}
// Paso 6: sustitución hacia atrás para c, y cálculo de b y d.
for (int j = n - 1; j >= 0; j--) {
    c[j] = z[j] - mu[j] * c[j + 1];
    b[j] = (a[j + 1] - a[j]) / h[j] - h[j] * (c[j + 1] + 2.0 * c[j]) / 3.0;
    d[j] = (c[j + 1] - c[j]) / (3.0 * h[j]);
}
```

El costo es $O(n)$. Por su parte, `evaluarTrazador(t, S)` localiza el subintervalo que contiene a $t$ y evalúa el polinomio cúbico correspondiente. Como los nodos no son equiespaciados (faltan los años reservados), las longitudes $h_j$ valen 1 o 2 años; el algoritmo admite este caso sin modificaciones.

== Verificación

Para comprobar las implementaciones, sus resultados se compararon con cálculos independientes: el polinomio de Lagrange se evaluó también en aritmética racional exacta (sin redondeo alguno) y con la rutina `BarycentricInterpolator` de SciPy, y el trazador con `CubicSpline` de SciPy usando `bc_type="natural"`. Los valores coinciden en todas las cifras significativas reportadas. En particular, la coincidencia con la aritmética exacta muestra que el redondeo no influye en los resultados del polinomio de Lagrange.

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
  caption: [Población exacta y aproximada de Croacia (habitantes) en los años reservados, con el error relativo de cada método.],
) <tabla>

La @completa muestra ambos interpolantes en todo el intervalo junto con los 30 datos exactos. La escala vertical está dominada por las oscilaciones del polinomio de Lagrange, que superan los 150 millones de habitantes cerca de 1994 cuando la población real es de unos 4,6 millones.

#figure(
  image("fig_completa.svg", width: 100%),
  caption: [Vista completa: el polinomio de Lagrange de grado 24 oscila con fuerza en el primer y el último subintervalo.],
) <completa>

La @acercamiento repite la gráfica en la escala de los datos. El trazador cúbico (línea discontinua) sigue la tendencia en todo el periodo, mientras que el polinomio de Lagrange solo se comporta bien entre aproximadamente 1999 y 2017.

#figure(
  image("fig_acercamiento.svg", width: 100%),
  caption: [Acercamiento a la escala de los datos. Los rombos son los valores exactos de los años reservados.],
) <acercamiento>

Finalmente, la @errores compara los errores relativos en escala logarítmica.

#figure(
  image("fig_errores.svg", width: 100%),
  caption: [Error relativo de cada método en los años reservados (escala logarítmica).],
) <errores>

= Análisis y comparación

== Diferencias observadas

*En los extremos (1995 y 2022)* la diferencia es enorme. El polinomio de Lagrange estima 61,3 millones de habitantes en 1995 y 36,3 millones en 2022, frente a valores reales de 4,6 y 3,9 millones: errores relativos de 12,3 y 8,3. El trazador cúbico, en cambio, comete errores de $#"5,5" times 10^(-5)$ y $#"1,2" times 10^(-4)$, es decir, se equivoca en unos pocos cientos de habitantes.

*En el interior (2000, 2008 y 2015)* ambos métodos son buenos, con errores entre $10^(-5)$ y $10^(-3)$. El trazador es mejor en 2008 y 2015. En 2000, sin embargo, el polinomio de Lagrange ($#"3,3" times 10^(-4)$) supera al trazador ($#"1,1" times 10^(-3)$), que es el único año en el que Lagrange gana.

== ¿Por qué se producen estas diferencias?

*El fenómeno de Runge.* El error de la interpolación polinomial en un punto $x$ es
$ f(x) - P(x) = (f^((n+1))(xi)) / ((n+1)!) product_(i=0)^n (x - x_i), $
para algún $xi$ en el intervalo. El factor $omega(x) = product (x - x_i)$ depende solo de la ubicación de los nodos, y para nodos (casi) equiespaciados crece de forma explosiva hacia los extremos del intervalo. Con los nodos de este problema, $|omega|$ vale $#"8,7" times 10^24$ en 1995 y $#"5,2" times 10^24$ en 2022, pero apenas $#"1,1" times 10^19$ en 2008: hay una diferencia de cinco a seis órdenes de magnitud entre el centro y los bordes. Para que un único polinomio de grado 24 pase por los 25 nodos, se ve obligado a oscilar con gran amplitud entre los nodos extremos, justo donde caen 1995 (entre 1994 y 1996) y 2022 (entre 2021 y 2023). Que los resultados en precisión extendida coincidan con los de la aritmética exacta confirma que se trata de una limitación del método y no de errores de redondeo.

*La ventaja de trabajar por tramos.* El trazador cúbico nunca usa polinomios de grado mayor que 3, y cada tramo depende sobre todo de los datos cercanos. Por eso no hay oscilaciones que se propaguen por el intervalo: un dato de 2023 tiene muy poca influencia sobre la estimación en 1995. La condición de frontera natural ($S'' = 0$ en los extremos) introduce un pequeño error cerca de los bordes, pero en este caso resultó insignificante.

*El caso del año 2000.* La población de Croacia baja casi linealmente, unos 60 000 habitantes por año, hasta el año 2000, y a partir de 2001 se estabiliza de forma abrupta en torno a 4,3 millones. Con el año 2000 excluido, este cambio de tendencia ocurre dentro del subintervalo $[1999, 2001]$, de dos años. El trazador, que está obligado a tener segunda derivada continua, suaviza ese quiebre y sobrestima la población en unos 4 500 habitantes. El polinomio de Lagrange también es suave, pero en esa zona central su comportamiento resultó estar más cerca del dato real. La ventaja es circunstancial y no contradice la conclusión general: ningún interpolante suave puede reproducir con exactitud un cambio brusco que ocurre entre dos nodos.

== Comparación de costos

Ambos métodos son baratos para 25 datos. El trazador requiere resolver un sistema tridiagonal ($O(n)$ operaciones) una sola vez y luego evaluar un polinomio cúbico; el polinomio de Lagrange requiere $O(n^2)$ operaciones en cada evaluación. Más allá del costo, la diferencia importante es la estabilidad: agregar datos mejora el trazador, mientras que en el polinomio de Lagrange con nodos equiespaciados suele empeorar las oscilaciones.

= Conclusiones

+ Con muchos datos equiespaciados, el polinomio interpolante de Lagrange no es una herramienta adecuada para aproximar valores cerca de los extremos: en 1995 y 2022 produjo estimaciones entre 9 y 13 veces mayores que la población real.
+ El trazador cúbico natural aproximó los cinco años con errores relativos inferiores a $#"1,1" times 10^(-3)$, y en cuatro de ellos inferiores a $#"1,2" times 10^(-4)$.
+ En el centro del intervalo ambos métodos tienen una precisión comparable. Lagrange solo superó al trazador en el año 2000, debido a un cambio brusco de tendencia en los datos que ningún interpolante suave puede capturar por completo.
+ Para interpolar conjuntos numerosos de datos, como series de población, es preferible usar trazadores cúbicos u otros métodos por tramos en lugar de un único polinomio de grado alto.

#v(1em)
*Referencia.* R. L. Burden, J. D. Faires y A. M. Burden, _Análisis Numérico_, 10.ª ed., Cengage Learning, 2017. Capítulo 3: Interpolación y aproximación polinomial.

#pagebreak()
#set heading(numbering: none)
= Anexo: código fuente completo

== `lagrange.cpp`
#raw(read("lagrange.cpp"), lang: "cpp", block: true)

== `trazador_cubico.cpp`
#raw(read("trazador_cubico.cpp"), lang: "cpp", block: true)

== `graficas.py` (auxiliar, para las figuras)
#raw(read("graficas.py"), lang: "python", block: true)
