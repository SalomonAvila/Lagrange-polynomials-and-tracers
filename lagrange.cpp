/**
 * @file lagrange.cpp
 * @brief Interpolación de la población de Croacia con el polinomio de Lagrange.
 *
 * El polinomio se construye con los 25 datos no subrayados de 1994 a 2023 y se
 * evalúa en los 5 años subrayados para medir el error relativo:
 *
 *     P(x) = sum_{k=0}^{n} y_k L_k(x),   L_k(x) = prod_{j != k} (x - x_j) / (x_k - x_j).
 *
 * La variable independiente se traslada a t = año - 1994 para no operar con
 * potencias de números cercanos a 2000, y los cálculos se hacen en long double
 * para reducir el redondeo. Al imprimir, los valores se convierten a double
 * porque MinGW no imprime bien long double con printf.
 *
 * El programa imprime la tabla de errores y los tiempos de ejecución, y escribe
 * resultados_lagrange.csv, curva_lagrange.csv y tiempos_lagrange.csv.
 *
 * Compilación: g++ -std=c++17 -O2 -o lagrange lagrange.cpp
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

/** Tipo real de precisión extendida usado en todos los cálculos. */
typedef long double real;

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
 * Los nodos se guardan con la variable trasladada t = año - 1994.
 *
 * @param xNodos Salida con los valores de t de los nodos.
 * @param yNodos Salida con la población en cada nodo.
 * @param anioPrueba Salida con los años subrayados.
 * @param yPrueba Salida con la población exacta de cada año subrayado.
 */
void separarDatos(std::vector<real>& xNodos, std::vector<real>& yNodos,
                  std::vector<int>& anioPrueba, std::vector<real>& yPrueba) {
    for (int i = 0; i < N_DATOS; i++) {
        int anio = ANIO_INICIAL + i;
        if (esSubrayado(anio)) {
            anioPrueba.push_back(anio);
            yPrueba.push_back(POBLACION[i]);
        } else {
            xNodos.push_back(anio - ANIO_INICIAL);  // variable trasladada t
            yNodos.push_back(POBLACION[i]);
        }
    }
}

/**
 * @brief Evalúa el k-ésimo polinomio base de Lagrange en un punto.
 *
 * @param k Índice del polinomio base.
 * @param x Punto donde se evalúa.
 * @param nodos Abscisas de los nodos de interpolación.
 * @return Valor de L_k(x).
 */
real baseLagrange(int k, real x, const std::vector<real>& nodos) {
    real L = 1.0L;
    for (size_t j = 0; j < nodos.size(); j++) {
        if ((int)j != k) L *= (x - nodos[j]) / (nodos[k] - nodos[j]);
    }
    return L;
}

/**
 * @brief Evalúa el polinomio interpolante de Lagrange en un punto.
 *
 * Cada evaluación cuesta O(n^2) operaciones, porque calcula de nuevo todos los polinomios base.
 *
 * @param x Punto donde se evalúa.
 * @param nodos Abscisas de los nodos de interpolación.
 * @param valores Ordenadas de los nodos de interpolación.
 * @return Valor de P(x).
 */
real lagrange(real x, const std::vector<real>& nodos, const std::vector<real>& valores) {
    real suma = 0.0L;
    for (size_t k = 0; k < nodos.size(); k++) suma += valores[k] * baseLagrange((int)k, x, nodos);
    return suma;
}

/**
 * @brief Calcula el error relativo de una aproximación.
 *
 * @param exacto Valor exacto, distinto de cero.
 * @param aprox Valor aproximado.
 * @return El cociente |exacto - aprox| / |exacto|.
 */
real errorRelativo(real exacto, real aprox) { return std::fabs(exacto - aprox) / std::fabs(exacto); }

/**
 * Recibe los resultados de los cálculos cronometrados. Al ser volatile, el
 * compilador no puede eliminar esos cálculos aunque su resultado no se use.
 */
volatile real sumidero;

/**
 * Cero que se suma a los argumentos de los cálculos cronometrados. Al ser
 * volatile, el compilador no puede sacar esos cálculos del ciclo de repeticiones.
 */
volatile real cero = 0.0L;

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
    std::vector<real> xNodos, yNodos, yPrueba;
    std::vector<int> anioPrueba;
    separarDatos(xNodos, yNodos, anioPrueba, yPrueba);

    std::printf("Polinomio de Lagrange de grado %zu - Croacia\n", xNodos.size() - 1);
    std::printf("Nodos usados: %zu datos\n\n", xNodos.size());
    std::printf("%6s %14s %18s %16s\n", "Anio", "Exacto", "Lagrange", "Error relativo");

    FILE* res = std::fopen("resultados_lagrange.csv", "w");
    if (res) std::fprintf(res, "anio,exacto,aproximado,error_relativo\n");

    for (size_t i = 0; i < anioPrueba.size(); i++) {
        real t = anioPrueba[i] - ANIO_INICIAL;
        real aprox = lagrange(t, xNodos, yNodos);
        real err = errorRelativo(yPrueba[i], aprox);
        std::printf("%6d %14.0f %18.2f %16.6e\n", anioPrueba[i], (double)yPrueba[i], (double)aprox, (double)err);
        if (res) std::fprintf(res, "%d,%.0f,%.2f,%.6e\n", anioPrueba[i], (double)yPrueba[i], (double)aprox, (double)err);
    }
    if (res) std::fclose(res);

    // Curva en una malla fina de 2001 puntos para graficar.
    FILE* curva = std::fopen("curva_lagrange.csv", "w");
    if (curva) {
        std::fprintf(curva, "anio,poblacion\n");
        for (int i = 0; i <= 2000; i++) {
            real t = 29.0L * i / 2000.0L;
            std::fprintf(curva, "%.4f,%.2f\n", (double)(t + ANIO_INICIAL), (double)lagrange(t, xNodos, yNodos));
        }
        std::fclose(curva);
    }

    // Tiempo de ejecución. El polinomio de Lagrange no tiene etapa de
    // construcción: todo el trabajo se hace en cada evaluación.
    const int REPS_PRUEBA = 100000, REPS_MALLA = 200;
    double tPrueba = medirMicrosegundos([&] {
        for (int anio : anioPrueba) sumidero = lagrange(anio - ANIO_INICIAL + cero, xNodos, yNodos);
    }, REPS_PRUEBA);
    double tMalla = medirMicrosegundos([&] {
        for (int i = 0; i <= 2000; i++) sumidero = lagrange(29.0L * i / 2000.0L + cero, xNodos, yNodos);
    }, REPS_MALLA);

    std::printf("\nTiempo de ejecucion (promedio por repeticion)\n");
    std::printf("%-34s %10s %16s\n", "Etapa", "Repet.", "Tiempo (us)");
    std::printf("%-34s %10d %16.3f\n", "Evaluacion en 5 anios de prueba", REPS_PRUEBA, tPrueba);
    std::printf("%-34s %10d %16.3f\n", "Evaluacion en malla de 2001 puntos", REPS_MALLA, tMalla);

    FILE* tiempos = std::fopen("tiempos_lagrange.csv", "w");
    if (tiempos) {
        std::fprintf(tiempos, "etapa,repeticiones,microsegundos\n");
        std::fprintf(tiempos, "prueba,%d,%.6f\n", REPS_PRUEBA, tPrueba);
        std::fprintf(tiempos, "malla,%d,%.6f\n", REPS_MALLA, tMalla);
        std::fclose(tiempos);
    }
    std::printf("\nArchivos generados: resultados_lagrange.csv, curva_lagrange.csv, tiempos_lagrange.csv\n");
    return 0;
}
