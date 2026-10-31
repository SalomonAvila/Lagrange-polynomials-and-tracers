/*
 * trazador_cubico.cpp
 * -------------------
 * Interpolación de la población de Croacia (1994-2023) con un trazador
 * cúbico natural construido a partir de los 25 datos NO subrayados.
 *
 * En cada subintervalo [x_j, x_{j+1}]:
 *     S_j(x) = a_j + b_j (x - x_j) + c_j (x - x_j)^2 + d_j (x - x_j)^3,
 * con condiciones de frontera naturales S''(x_0) = S''(x_n) = 0.
 *
 * Los coeficientes c_j se obtienen de un sistema tridiagonal resuelto con
 * la factorización de Crout (algoritmo de Thomas), según el Algoritmo 3.4
 * de Burden & Faires, "Análisis Numérico".
 *
 * Compilar:  g++ -std=c++17 -O2 -o trazador_cubico trazador_cubico.cpp
 * Ejecutar:  ./trazador_cubico        (en Windows: trazador_cubico.exe)
 *
 * Salidas: tabla en consola, resultados_trazador.csv y curva_trazador.csv.
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

bool esSubrayado(int anio) {
    for (int s : SUBRAYADOS)
        if (s == anio) return true;
    return false;
}

// Separa los 30 datos en nodos de interpolación (25) y datos de prueba (5).
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

// ---------------------------------------------------------------------------
// Algoritmo del trazador cúbico natural
// ---------------------------------------------------------------------------

// Coeficientes de los n polinomios cúbicos S_0, ..., S_{n-1}.
struct Trazador {
    std::vector<double> x, a, b, c, d;
};

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

// Evalúa el trazador en t: localiza el subintervalo [x_j, x_{j+1}] y aplica S_j.
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

double errorRelativo(double exacto, double aprox) { return std::fabs(exacto - aprox) / std::fabs(exacto); }

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
    std::printf("\nArchivos generados: resultados_trazador.csv, curva_trazador.csv\n");
    return 0;
}
