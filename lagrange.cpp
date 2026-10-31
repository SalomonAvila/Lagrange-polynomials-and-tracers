/*
 * lagrange.cpp
 * ------------
 * Interpolación de la población de Croacia (1994-2023) con el polinomio de
 * Lagrange construido a partir de los 25 datos NO subrayados.
 *
 *     P(x) = sum_{k=0}^{n} y_k * L_k(x),
 *     L_k(x) = prod_{j != k} (x - x_j) / (x_k - x_j).
 *
 * Decisiones de implementación:
 *   - Los datos se escriben directamente en el código (tomados de la hoja
 *     CROACIA del Excel del curso), así el programa no depende de archivos
 *     externos ni de librerías adicionales.
 *   - La variable independiente se traslada a t = año - 1994 para no operar
 *     con potencias de números del orden de 2000.
 *   - Se usa long double (precisión extendida) para reducir el redondeo.
 *     Al imprimir se convierte a double, porque algunos compiladores de
 *     Windows (MinGW) no imprimen bien long double con printf.
 *
 * Compilar:  g++ -std=c++17 -O2 -o lagrange lagrange.cpp
 * Ejecutar:  ./lagrange        (en Windows: lagrange.exe)
 *
 * Salidas: tabla en consola, resultados_lagrange.csv y curva_lagrange.csv
 * (esta última sirve para graficar el polinomio en todo el intervalo).
 */

#include <cmath>
#include <cstdio>
#include <vector>

// ---------------------------------------------------------------------------
// Datos: población de Croacia 1994-2023 (hoja CROACIA del archivo Excel).
// ---------------------------------------------------------------------------
const int N_DATOS = 30;
const int ANIO_INICIAL = 1994;
const long POBLACION[N_DATOS] = {
    4675517, 4619362, 4562290, 4504627, 4445669, 4385823, 4326105, 4301079,
    4305783, 4306683, 4310050, 4313946, 4315802, 4315959, 4314635, 4310537,
    4301150, 4280827, 4259233, 4242403, 4219485, 4183732, 4136438, 4079198,
    4024868, 3986338, 3953956, 3924607, 3907031, 3896023};
// Años subrayados (resaltados en el Excel): se reservan para medir el error.
const int SUBRAYADOS[5] = {1995, 2000, 2008, 2015, 2022};

typedef long double real;

bool esSubrayado(int anio) {
    for (int s : SUBRAYADOS)
        if (s == anio) return true;
    return false;
}

// Separa los 30 datos en nodos de interpolación (25) y datos de prueba (5).
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

// ---------------------------------------------------------------------------
// Algoritmo de Lagrange
// ---------------------------------------------------------------------------

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
    for (size_t k = 0; k < nodos.size(); k++) suma += valores[k] * baseLagrange((int)k, x, nodos);
    return suma;
}

real errorRelativo(real exacto, real aprox) { return std::fabs(exacto - aprox) / std::fabs(exacto); }

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
    std::printf("\nArchivos generados: resultados_lagrange.csv, curva_lagrange.csv\n");
    return 0;
}
