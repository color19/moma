"""M11 Growth Theory I — standalone test of all pyodide code blocks."""

import numpy as np
import matplotlib.pyplot as plt
from scipy.integrate import solve_ivp

# %% Block 1: Exploring the Steady State
print("Block 1: Exploring the Steady State")

alpha = 0.33
delta_dep = 0.08
delta_t = 0.04
n = 0.01
rho = 2.0  # held fixed for left panel

fig, axes = plt.subplots(1, 2, figsize=(10, 4))

# Effect of g (holding rho = 2)
g_values = np.linspace(0.0, 0.05, 100)
k_ss = (alpha / (delta_t + n + delta_dep + rho * g_values)) ** (1 / (1 - alpha))
axes[0].plot(g_values * 100, k_ss, lw=2)
axes[0].set_xlabel(r'Productivity growth rate $g$ (%)')
axes[0].set_ylabel(r'Steady-state $\check{k}$')
axes[0].set_title(r'Faster tech progress lowers $\check{k}$')
axes[0].grid(True, alpha=0.3)

# Effect of rho
rho_values = np.linspace(0.5, 6.0, 100)
g = 0.02
k_ss_rho = (alpha / (delta_t + n + delta_dep + rho_values * g)) ** (1 / (1 - alpha))
axes[1].plot(rho_values, k_ss_rho, lw=2, color='C1')
axes[1].set_xlabel(r'Risk aversion $\rho$')
axes[1].set_ylabel(r'Steady-state $\check{k}$')
axes[1].set_title(r'Higher risk aversion lowers $\check{k}$')
axes[1].grid(True, alpha=0.3)

plt.tight_layout()
plt.show()

# %% Block 2: Phase Diagram
print("Block 2: Phase Diagram")

alpha, delta_dep, delta_t, n, g, rho = 0.33, 0.08, 0.04, 0.01, 0.02, 2.0

k_grid = np.linspace(0.01, 8.0, 500)
c_kdot0 = k_grid**alpha - (g + n + delta_dep) * k_grid
c_kdot0 = np.maximum(c_kdot0, 0)
k_ss = (alpha / (delta_t + n + delta_dep + rho * g)) ** (1 / (1 - alpha))
c_ss = k_ss**alpha - (g + n + delta_dep) * k_ss

# Golden rule
k_gr = (alpha / (g + n + delta_dep)) ** (1 / (1 - alpha))

fig, ax = plt.subplots(figsize=(8, 5))
ax.plot(k_grid, c_kdot0, 'b-', lw=2, label=r'$\dot{k}=0$ locus')
ax.axvline(k_ss, color='r', ls='--', lw=2, label=r'$\dot{c}/c=0$ locus')
ax.plot(k_ss, c_ss, 'ko', ms=8, zorder=5)
ax.annotate('Steady state', xy=(k_ss, c_ss), xytext=(k_ss + 0.8, c_ss + 0.15),
            fontsize=10, arrowprops=dict(arrowstyle='->', color='black'))
ax.axvline(k_gr, color='gray', ls=':', lw=1, alpha=0.6)
ax.annotate('$k^{GR}$', xy=(k_gr, 0), xytext=(k_gr + 0.2, 0.05), fontsize=10, color='gray')

# Direction arrows
ax.annotate('', xy=(k_ss - 1.5, c_ss + 0.15), xytext=(k_ss - 1.5, c_ss - 0.05),
            arrowprops=dict(arrowstyle='->', color='C2', lw=1.5))
ax.annotate('', xy=(k_ss + 1.5, c_ss - 0.15), xytext=(k_ss + 1.5, c_ss + 0.05),
            arrowprops=dict(arrowstyle='->', color='C2', lw=1.5))

ax.set_xlabel('Capital per efficiency unit $k$')
ax.set_ylabel('Consumption per efficiency unit $c$')
ax.set_title('Phase diagram of the RCK model')
ax.legend(fontsize=9)
ax.set_xlim(0, 8)
ax.set_ylim(0, max(c_kdot0) * 1.15)
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()

# %% Block 3: Simulating the Saddle Path
print("Block 3: Simulating the Saddle Path")

alpha, delta_dep, delta_t, n, g, rho = 0.33, 0.08, 0.04, 0.01, 0.02, 2.0
k_ss = (alpha / (delta_t + n + delta_dep + rho * g)) ** (1 / (1 - alpha))
c_ss = k_ss**alpha - (g + n + delta_dep) * k_ss

def rck_system(t, y):
    k, c = y
    if k <= 0:
        return [0, 0]
    fk = alpha * k**(alpha - 1)
    kdot = k**alpha - c - (g + n + delta_dep) * k
    cdot = c / rho * (fk - delta_dep - delta_t - n - rho * g)
    return [kdot, cdot]

k_grid = np.linspace(0.01, 8.0, 500)
c_kdot0 = np.maximum(k_grid**alpha - (g + n + delta_dep) * k_grid, 0)

fig, ax = plt.subplots(figsize=(8, 5))
ax.plot(k_grid, c_kdot0, 'b-', lw=1.5, alpha=0.4)
ax.axvline(k_ss, color='r', ls='--', lw=1.5, alpha=0.4)

def k_zero_event(t, y):
    return y[0] - 0.001
k_zero_event.terminal = True
k_zero_event.direction = -1

for k0 in [1.0, 2.0]:
    for c_mult in [0.7, 1.0, 1.3]:
        c0_approx = k0**alpha - (g + n + delta_dep) * k0
        c0 = c0_approx * c_mult
        if c0 <= 0:
            continue
        sol = solve_ivp(rck_system, [0, 80], [k0, c0], max_step=0.1,
                        events=k_zero_event)
        k_path, c_path = sol.y
        style = '-' if abs(c_mult - 1.0) < 0.01 else ':'
        color = 'green' if abs(c_mult - 1.0) < 0.01 else 'gray'
        ax.plot(k_path, c_path, style, color=color, lw=1.8)

ax.plot(k_ss, c_ss, 'ko', ms=8, zorder=5)
ax.set_xlabel('$k$')
ax.set_ylabel('$c$')
ax.set_title('Saddle path (green) vs. divergent paths (gray)')
ax.set_xlim(0, 8)
ax.set_ylim(0, max(c_kdot0) * 1.15)
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()

# %% Block 4: Government Spending and the Phase Diagram
print("Block 4: Government Spending and the Phase Diagram")

alpha, delta_dep, delta_t, n, g, rho = 0.33, 0.08, 0.04, 0.0, 0.0, 2.0
k_grid = np.linspace(0.01, 8.0, 500)
k_ss = (alpha / (delta_t + delta_dep)) ** (1 / (1 - alpha))

fig, ax = plt.subplots(figsize=(8, 5))
for T, ls, label in [(0, '-', '$T = 0$'), (0.05, '--', '$T = 0.05$'), (0.10, ':', '$T = 0.10$')]:
    c_kdot0 = np.maximum(k_grid**alpha - delta_dep * k_grid - T, 0)
    ax.plot(k_grid, c_kdot0, ls, lw=2, label=label)

ax.axvline(k_ss, color='r', ls='--', lw=2, alpha=0.5, label=r'$\dot{c}/c=0$')
ax.set_xlabel('Capital per worker $k$')
ax.set_ylabel('Consumption per worker $c$')
ax.set_title(r'Balanced budget: $\dot{k}=0$ shifts down, $\dot{c}/c=0$ unchanged')
ax.legend(fontsize=9)
ax.set_xlim(0, 8)
ax.set_ylim(0)
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()

# %% Block 5: Capital Tax and the Phase Diagram
print("Block 5: Capital Tax and the Phase Diagram")

alpha, delta_t, rho = 0.33, 0.04, 2.0
delta_dep = 0.0  # delta = 0 assumed in this section
k_grid = np.linspace(0.01, 20.0, 500)

fig, ax = plt.subplots(figsize=(8, 5))
c_kdot0 = np.maximum(k_grid**alpha - delta_dep * k_grid, 0)
ax.plot(k_grid, c_kdot0, 'b-', lw=2, label=r'$\dot{k}=0$ locus (unchanged)')

for tau, color, label in [(0, 'r', r'$\tau = 0$'), (0.2, 'C1', r'$\tau = 0.2$'), (0.4, 'C3', r'$\tau = 0.4$')]:
    k_ss = (alpha * (1 - tau) / delta_t) ** (1 / (1 - alpha))
    c_ss = k_ss**alpha - delta_dep * k_ss
    ax.axvline(k_ss, color=color, ls='--', lw=1.5, alpha=0.7)
    ax.plot(k_ss, c_ss, 'o', color=color, ms=8, zorder=5)
    ax.annotate(label, xy=(k_ss, c_ss), xytext=(k_ss + 0.3, c_ss + 0.05),
                fontsize=9, color=color)

ax.set_xlabel('$k$')
ax.set_ylabel('$c$')
ax.set_title(r'Capital income tax shifts $\dot{c}/c = 0$ locus left')
ax.legend(fontsize=9)
ax.set_xlim(0, 20)
ax.set_ylim(0, max(c_kdot0) * 1.1)
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()

# %% Block 6: Saving Rate and Risk Aversion
print("Block 6: Saving Rate and Risk Aversion")

alpha, delta_dep, delta_t = 0.33, 0.08, 0.04
g_grid = np.linspace(0.0, 0.05, 100)

fig, ax = plt.subplots(figsize=(8, 4))
for rho in [0.5, 1.0, 2.0, 4.0]:
    s = alpha * (delta_dep + g_grid) / (delta_dep + delta_t + rho * g_grid)
    ax.plot(g_grid * 100, s * 100, lw=2, label=rf'$\rho = {rho}$')

ax.axhline(alpha * 100, color='gray', ls=':', lw=1, alpha=0.5)
ax.annotate(r'$s = \alpha$ (Solow with $\delta=g=0$)', xy=(3, alpha * 100 + 0.5),
            fontsize=8, color='gray')
ax.set_xlabel('Productivity growth rate $g$ (%)')
ax.set_ylabel('Steady-state gross saving rate (%)')
ax.set_title('Only low risk aversion produces a positive saving-growth relationship')
ax.legend(fontsize=9)
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()

print("\nAll 6 blocks ran successfully.")
