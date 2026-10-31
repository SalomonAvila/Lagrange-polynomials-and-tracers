/**
 * @file trazador_cubico.cpp
 * @brief Interpolación de la población de Croacia con un trazador cúbico natural.
 *
 * El trazador se construye con los 25 datos no subrayados de 1994 a 2023 y se
 * evalúa en los 5 años subrayados para medir el error relativo. En cada
 * subintervalo [x_j, x_{j+1}] se usa
 *
 *     S_j(x) = a_j + b_j (x - x_j) + c_j (x - x_j)^2 + d_j (x - x_j)^3,
 *
 * con las condiciones de frontera naturales S''(x_0) = S''(x_n) = 0.
 *
 * El programa imprime la tabla de errores y los tiempos de ejecución, y escribe
 * resultados_trazador.csv, curva_trazador.csv y tiempos_trazador.csv.
 *
 * Compilación: g++ -std=c++17 -O2 -o trazador_cubico trazador_cubico.cpp
 *
 * @author Salomón Alfredo Ávila Larrotta
 */

#include <chrono>
#include <cmath>
#include <cstdio>
#include <vector>

/** Número de datos anuales de población. */
const int N_DATOS = 30;

/** Primer año de la serie. */
const int ANIO_INICIAL = 1994;

/** Población de Croacia de 1994 a 2023, tomada de la hoja CROACIA del Excel del curso. */
const long POBLACION[N_DATOS] = {
    4675517, 4619362, 4562290, 4504627, 4445669, 4385823, 4326105, 4301079,
    4305783, 4306683, 4310050, 4313946, 4315802, 4315959, 4314635, 4310537,
    4301150, 4280827, 4259233, 4242403, 4219485, 4183732, 4136438, 4079198,
    4024868, 3986338, 3953956, 3924607, 3907031, 3896023};

/** Años resaltados en el Excel. Se excluyen de la interpolación y se usan para medir el error. */
const int SUBRAYADOS[5] = {1995, 2000, 2008, 2015, 2022};

/**
 * @brief Indica si un año es uno de los años subrayados.
 *
 * @param anio Año que se consulta.
 * @return true si el año está en SUBRAYADOS y false en otro caso.
 */
bool esSubrayado(int anio) {
    for (int s : SUBRAYADOS)
        if (s == anio) return true;
    return false;
}

/**
 * @brief Separa los 30 datos en 25 nodos de interpolación y 5 datos de prueba.
 *
 * @param xNodos Salida con los años de los nodos.
 * @param yNodos Salida con la población en cada nodo.
 * @param anioPrueba Salida con los años subrayados.
 * @param yPrueba Salida con la población exacta de cada año subrayado.
 */
void separarDatos(std::vector<double>& xNodos, std::vector<double>& yNodos,
                  std::vector<int>& anioPrueba, std::vector<double>& yPrueba) {
    for (int i = 0; i < N_DATOS; i++) {
        int anio = ANIO_INICIAL + i;
        if (esSubrayado(anio)) {
            anioPrueba.push_back(anio);
            yPrueba.push_back(POBLACION[i]);
        } else {
            xNodos.push_back(anio);
            yNodos.push_back(POBLACION[i]);
        }
    }
}

/**
 * @brief Coeficientes de los n polinomios cúbicos S_0, ..., S_{n-1} de un trazador.
 */
struct Trazador {
    std::vector<double> x;  ///< Los n + 1 nodos x_0, ..., x_n.
    std::vector<double> a;  ///< Coeficientes a_j, iguales a f(x_j).
    std::vector<double> b;  ///< Coeficientes b_j de los términos lineales.
    std::vector<double> c;  ///< Coeficientes c_j de los términos cuadráticos.
    std::vector<double> d;  ///< Coeficientes d_j de los términos cúbicos.
};

/**
 * @brief Construye el trazador cúbico natural que interpola los datos dados.
 *
 * Los coeficientes c_j se obtienen de un sistema tridiagonal que se resuelve con
 * la factorización de Crout, también llamada algoritmo de Thomas, en O(n) operaciones.
 *
 * @param x Nodos en orden creciente, no necesariamente equiespaciados.
 * @param y Valores de la función en los nodos.
 * @return Los coeficientes del trazador.
 */
Trazador trazadorNatural(const std::vector<double>& x, const std::vector<double>& y) {
    int n = (int)x.size() - 1;  // número de subintervalos
    std::vector<double> a = y;  // a_j = f(x_j)

    // Paso 1: longitudes de los subintervalos.
    std::vector<double> h(n);
    for (int i = 0; i < n; i++) h[i] = x[i + 1] - x[i];

    // Paso 2: lado derecho del sistema tridiagonal.
    std::vector<double> alfa(n + 1, 0.0);
    for (int i = 1; i < n; i++)
        alfa[i] = 3.0 / h[i] * (a[i + 1] - a[i]) - 3.0 / h[i - 1] * (a[i] - a[i - 1]);

    // Pasos 3-5: factorización de Crout y sustitución hacia adelante.
    // Las filas 0 y n codifican c_0 = c_n = 0 (frontera natural).
    std::vector<double> l(n + 1, 0.0), mu(n + 1, 0.0), z(n + 1, 0.0);
    l[0] = 1.0;
    for (int i = 1; i < n; i++) {
        l[i] = 2.0 * (x[i + 1] - x[i - 1]) - h[i - 1] * mu[i - 1];
        mu[i] = h[i] / l[i];
        z[i] = (alfa[i] - h[i - 1] * z[i - 1]) / l[i];
    }
    l[n] = 1.0;
    z[n] = 0.0;

    // Paso 6: sustitución hacia atrás para c, y cálculo de b y d.
    std::vector<double> c(n + 1, 0.0), b(n), d(n);
    for (int j = n - 1; j >= 0; j--) {
        c[j] = z[j] - mu[j] * c[j + 1];
        b[j] = (a[j + 1] - a[j]) / h[j] - h[j] * (c[j + 1] + 2.0 * c[j]) / 3.0;
        d[j] = (c[j + 1] - c[j]) / (3.0 * h[j]);
    }

    Trazador S;
    S.x = x;
    S.a.assign(a.begin(), a.end() - 1);
    S.b = b;
    S.c.assign(c.begin(), c.end() - 1);
    S.d = d;
    return S;
}

/**
 * @brief Evalúa el trazador en un punto.
 *
 * Localiza el subintervalo [x_j, x_{j+1}] que contiene a t y evalúa S_j(t). Si t
 * está fuera del intervalo de los nodos, se usa el primer o el último tramo.
 *
 * @param t Punto donde se evalúa.
 * @param S Trazador construido con trazadorNatural.
 * @return Valor de S(t).
 */
double evaluarTrazador(double t, const Trazador& S) {
    int n = (int)S.x.size() - 1;
    int j = n - 1;  // por defecto el último tramo (incluye t = x_n)
    for (int i = 0; i < n; i++) {
        if (S.x[i] <= t && t < S.x[i + 1]) {
            j = i;
            break;
        }
    }
    if (t < S.x[0]) j = 0;
    double dx = t - S.x[j];
    return S.a[j] + S.b[j] * dx + S.c[j] * dx * dx + S.d[j] * dx * dx * dx;
}

/**
 * @brief Calcula el error relativo de una aproximación.
 *
 * @param exacto Valor exacto, distinto de cero.
 * @param aprox Valor aproximado.
 * @return El cociente |exacto - aprox| / |exacto|.
 */
double errorRelativo(double exacto, double aprox) { return std::fabs(exacto - aprox) / std::fabs(exacto); }

/**
 * Recibe los resultados de los cálculos cronometrados. Al ser volatile, el
 * compilador no puede eliminar esos cálculos aunque su resultado no se use.
 */
volatile double sumidero;

/**
 * Cero que se suma a los argumentos de los cálculos cronometrados. Al ser
 * volatile, el compilador no puede sacar esos cálculos del ciclo de repeticiones.
 */
volatile double cero = 0.0;

/**
 * @brief Mide el tiempo promedio de ejecución de una función.
 *
 * La función se ejecuta reps veces seguidas, porque una sola ejecución dura
 * menos que la resolución del reloj, y el tiempo total se divide entre reps.
 *
 * @tparam F Tipo de la función que se mide, normalmente una lambda sin argumentos.
 * @param f Función que se mide.
 * @param reps Número de repeticiones.
 * @return Tiempo promedio de una ejecución de f, en microsegundos.
 */
template <typename F>
double medirMicrosegundos(F f, int reps) {
    auto inicio = std::chrono::steady_clock::now();
    for (int r = 0; r < reps; r++) f();
    auto fin = std::chrono::steady_clock::now();
    return std::chrono::duration<double, std::micro>(fin - inicio).count() / reps;
}

/**
 * @brief Calcula las aproximaciones y los errores, mide los tiempos y escribe los archivos CSV.
 *
 * @return 0 si el programa termina correctamente.
 */
int main() {
    std::vector<double> xNodos, yNodos, yPrueba;
    std::vector<int> anioPrueba;
    separarDatos(xNodos, yNodos, anioPrueba, yPrueba);

    Trazador S = trazadorNatural(xNodos, yNodos);

    std::printf("Trazador cubico natural con %zu nodos - Croacia\n\n", xNodos.size());
    std::printf("%6s %14s %16s %16s\n", "Anio", "Exacto", "Trazador", "Error relativo");

    FILE* res = std::fopen("resultados_trazador.csv", "w");
    if (res) std::fprintf(res, "anio,exacto,aproximado,error_relativo\n");

    for (size_t i = 0; i < anioPrueba.size(); i++) {
        double aprox = evaluarTrazador(anioPrueba[i], S);
        double err = errorRelativo(yPrueba[i], aprox);
        std::printf("%6d %14.0f %16.2f %16.6e\n", anioPrueba[i], yPrueba[i], aprox, err);
        if (res) std::fprintf(res, "%d,%.0f,%.2f,%.6e\n", anioPrueba[i], yPrueba[i], aprox, err);
    }
    if (res) std::fclose(res);

    // Curva en una malla fina de 2001 puntos para graficar.
    FILE* curva = std::fopen("curva_trazador.csv", "w");
    if (curva) {
        std::fprintf(curva, "anio,poblacion\n");
        for (int i = 0; i <= 2000; i++) {
            double t = ANIO_INICIAL + 29.0 * i / 2000.0;
            std::fprintf(curva, "%.4f,%.2f\n", t, evaluarTrazador(t, S));
        }
        std::fclose(curva);
    }

    // Tiempo de ejecución: construcción (cálculo de coeficientes) y evaluación.
    const int REPS_CONSTRUCCION = 100000, REPS_PRUEBA = 100000, REPS_MALLA = 2000;
    double tConstruccion = medirMicrosegundos([&] {
        Trazador T = trazadorNatural(xNodos, yNodos);
        sumidero = T.c[1] + cero;
    }, REPS_CONSTRUCCION);
    double tPrueba = medirMicrosegundos([&] {
        for (int anio : anioPrueba) sumidero = evaluarTrazador(anio + cero, S);
    }, REPS_PRUEBA);
    double tMalla = medirMicrosegundos([&] {
        for (int i = 0; i <= 2000; i++) sumidero = evaluarTrazador(ANIO_INICIAL + 29.0 * i / 2000.0 + cero, S);
    }, REPS_MALLA);

    std::printf("\nTiempo de ejecucion (promedio por repeticion)\n");
    std::printf("%-34s %10s %16s\n", "Etapa", "Repet.", "Tiempo (us)");
    std::printf("%-34s %10d %16.3f\n", "Construccion (coeficientes)", REPS_CONSTRUCCION, tConstruccion);
    std::printf("%-34s %10d %16.3f\n", "Evaluacion en 5 anios de prueba", REPS_PRUEBA, tPrueba);
    std::printf("%-34s %10d %16.3f\n", "Evaluacion en malla de 2001 puntos", REPS_MALLA, tMalla);

    FILE* tiempos = std::fopen("tiempos_trazador.csv", "w");
    if (tiempos) {
        std::fprintf(tiempos, "etapa,repeticiones,microsegundos\n");
        std::fprintf(tiempos, "construccion,%d,%.6f\n", REPS_CONSTRUCCION, tConstruccion);
        std::fprintf(tiempos, "prueba,%d,%.6f\n", REPS_PRUEBA, tPrueba);
        std::fprintf(tiempos, "malla,%d,%.6f\n", REPS_MALLA, tMalla);
        std::fclose(tiempos);
    }
    std::printf("\nArchivos generados: resultados_trazador.csv, curva_trazador.csv, tiempos_trazador.csv\n");
    return 0;
}
