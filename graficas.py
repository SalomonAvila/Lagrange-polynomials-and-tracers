"""
graficas.py
-----------
Genera las figuras del informe a partir de los archivos CSV que producen
los programas en C++ (lagrange.cpp y trazador_cubico.cpp).

Uso: primero ejecute ./lagrange y ./trazador_cubico; luego
     python graficas.py          (requiere matplotlib)
"""

import csv

import matplotlib

matplotlib.use("Agg")
matplotlib.rcParams["svg.fonttype"] = "path"
import matplotlib.pyplot as plt

AZUL, NARANJA, TINTA, GRIS = "#2a78d6", "#eb6834", "#0b0b0b", "#52514e"

# Datos exactos de Croacia 1994-2023 y años subrayados.
ANIOS = list(range(1994, 2024))
POB = [4675517, 4619362, 4562290, 4504627, 4445669, 4385823, 4326105, 4301079,
       4305783, 4306683, 4310050, 4313946, 4315802, 4315959, 4314635, 4310537,
       4301150, 4280827, 4259233, 4242403, 4219485, 4183732, 4136438, 4079198,
       4024868, 3986338, 3953956, 3924607, 3907031, 3896023]
SUBRAYADOS = [1995, 2000, 2008, 2015, 2022]
x_n = [a for a in ANIOS if a not in SUBRAYADOS]
y_n = [p / 1e6 for a, p in zip(ANIOS, POB) if a not in SUBRAYADOS]
x_p = SUBRAYADOS
y_p = [p / 1e6 for a, p in zip(ANIOS, POB) if a in SUBRAYADOS]


def leer(nombre):
    with open(nombre, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


curva_L = leer("curva_lagrange.csv")
curva_S = leer("curva_trazador.csv")
res_L = leer("resultados_lagrange.csv")
res_S = leer("resultados_trazador.csv")

plt.rcParams.update({
    "font.size": 10, "axes.spines.top": False, "axes.spines.right": False,
    "axes.edgecolor": GRIS, "axes.labelcolor": TINTA, "xtick.color": GRIS,
    "ytick.color": GRIS, "axes.grid": True, "grid.color": "#e4e3df",
    "grid.linewidth": 0.6, "legend.frameon": False,
})


def dibujar_base(ax):
    ax.plot([float(r["anio"]) for r in curva_L], [float(r["poblacion"]) / 1e6 for r in curva_L],
            color=AZUL, lw=1.6, label="Polinomio de Lagrange (grado 24)")
    ax.plot([float(r["anio"]) for r in curva_S], [float(r["poblacion"]) / 1e6 for r in curva_S],
            color=NARANJA, lw=1.6, ls="--", label="Trazador cúbico natural")
    ax.plot(x_n, y_n, "o", color=TINTA, ms=4, label="Datos usados (25 nodos)")
    ax.plot(x_p, y_p, "D", mfc="white", mec=TINTA, mew=1.4, ms=7,
            label="Datos subrayados (valor exacto)")
    ax.set_xlabel("Año")
    ax.set_ylabel("Población (millones)")


# Figura 1: vista completa.
fig, ax = plt.subplots(figsize=(7.5, 4.2))
dibujar_base(ax)
ax.set_title("Vista completa del intervalo 1994–2023", loc="left", fontsize=11)
ax.legend(loc="upper center", fontsize=8.5)
fig.tight_layout()
fig.savefig("fig_completa.svg")

# Figura 2: acercamiento a la escala de los datos.
fig, ax = plt.subplots(figsize=(7.5, 4.2))
dibujar_base(ax)
ax.plot(ANIOS, [p / 1e6 for p in POB], color=GRIS, lw=0.8, alpha=0.6, zorder=0)
ax.set_ylim(3.8, 4.75)
ax.set_xlim(1993.5, 2023.5)
ax.set_title("Acercamiento a la escala de los datos", loc="left", fontsize=11)
ax.legend(loc="upper right", fontsize=8.5)
fig.tight_layout()
fig.savefig("fig_acercamiento.svg")

# Figura 3: errores relativos (escala logarítmica).
eL = [float(r["error_relativo"]) for r in res_L]
eS = [float(r["error_relativo"]) for r in res_S]
fig, ax = plt.subplots(figsize=(7.5, 3.6))
pos = range(len(x_p))
ax.bar([p - 0.2 for p in pos], eL, width=0.38, color=AZUL, label="Lagrange")
ax.bar([p + 0.2 for p in pos], eS, width=0.38, color=NARANJA, hatch="//",
       edgecolor="white", label="Trazador cúbico")
ax.set_yscale("log")
ax.set_xticks(list(pos), [str(a) for a in x_p])
ax.set_xlabel("Año subrayado")
ax.set_ylabel("Error relativo (escala log)")
ax.legend(loc="upper center", ncol=2, fontsize=9)
ax.grid(axis="x", visible=False)
fig.tight_layout()
fig.savefig("fig_errores.svg")

# Tabla combinada para el informe.
with open("resultados.csv", "w", encoding="utf-8") as f:
    f.write("anio,exacto,lagrange,err_lagrange,trazador,err_trazador\n")
    for l, s in zip(res_L, res_S):
        f.write(f"{l['anio']},{l['exacto']},{float(l['aproximado']):.0f},"
                f"{float(l['error_relativo']):.3e},{float(s['aproximado']):.0f},"
                f"{float(s['error_relativo']):.3e}\n")

print("Generados: fig_completa.svg, fig_acercamiento.svg, fig_errores.svg, resultados.csv")
