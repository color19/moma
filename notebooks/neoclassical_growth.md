---
jupytext:
  text_representation:
    extension: .md
    format_name: myst
kernelspec:
  display_name: Python 3
  language: python
  name: python3
authors:
  - name: Alan Lujan
    url: https://github.com/alanlujan91
description: >-
  Symbolic derivation of the RCK steady state, phase diagram with saddle-path
  computation, transition dynamics, comparative statics, and the saving-growth
  relationship in the neoclassical growth model.
keywords:
  - Ramsey-Cass-Koopmans
  - neoclassical growth
  - phase diagram
  - saddle path
  - golden rule
  - saving rate
tags:
  - growth
  - computational
---

# Neoclassical Growth: The Ramsey-Cass-Koopmans Model

This notebook is a computational companion to the Growth Theory I lecture (Module 11). It covers
the Ramsey {cite}`ramsey:save`-Cass {cite}`cass:growth`-Koopmans {cite}`koopmans:growth` model
of optimal growth with exogenous labor-augmenting technological progress.

The notebook proceeds in four parts. Part I derives the steady state symbolically using SymPy and
compares it to the golden rule {cite}`phelps:golden`. Part II constructs the phase diagram and
computes the saddle path numerically. Part III traces transition dynamics from an initial capital
stock below the steady state. Part IV examines the relationship between the saving rate and the
growth rate of productivity.

:::{seealso}
The [Investment Theory notebook](investment_qmodel.md) uses the same phase-diagram and
saddle-path techniques for the marginal $q$ model of investment.
:::

```{code-cell} ipython3
from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.integrate import solve_ivp
from scipy.interpolate import interp1d
from sympy import (
    symbols, Rational, simplify, solve, diff, Matrix, lambdify,
    init_printing, Eq, sqrt, factor, latex,
)

init_printing()

# Figure output directory
FIG_DIR = Path("../slides/m11/figs")
FIG_DIR.mkdir(parents=True, exist_ok=True)

# Theme colors
ACCENT = '#107895'
RED    = '#9a2515'
```

## Parameters

The model is summarized by six parameters. All variables are expressed per efficiency unit of
labor ($k = K / \Theta L$) unless otherwise noted.

| Parameter | Symbol | Baseline | Description |
|-----------|--------|----------|-------------|
| Capital share | $\alpha$ | 0.33 | Exponent in $f(k) = k^\alpha$ |
| Depreciation | $\delta$ | 0.08 | Physical capital depreciation rate |
| Time preference | $\beta$ | 0.04 | Rate of pure time preference |
| Risk aversion | $\rho$ | 2.0 | Coefficient of relative risk aversion |
| Population growth | $n$ | 0.01 | Constant growth rate of labor force |
| Productivity growth | $g$ | 0.02 | Rate of labor-augmenting tech progress |

```{code-cell} ipython3
from collections import namedtuple

RCKModel = namedtuple('RCKModel', ['alpha', 'delta', 'beta', 'rho', 'n', 'g'])
m = RCKModel(alpha=0.33, delta=0.08, beta=0.04, rho=2.0, n=0.01, g=0.02)
```

# Part I: Steady State

## Symbolic Derivation

The modified golden rule (Keynes-Ramsey rule) requires that consumption growth equals zero in
steady state. Setting $\dot{c}/c = 0$ in the Euler equation:

```{math}
:label: rck_euler
\frac{\dot{c}}{c} = \frac{1}{\rho}\left[f'(k) - \delta - \beta - n - \rho\,g\right] = 0
```

yields the steady-state condition

```{math}
:label: rck_ss_condition
f'(\check{k}) = \beta + n + \delta + \rho\,g.
```

With a Cobb-Douglas production function $f(k) = k^\alpha$, we can solve for $\check{k}$
in closed form.

```{code-cell} ipython3
alpha_s, delta_s, beta_s, rho_s, n_s, g_s, k_s = symbols(
    'alpha delta beta rho n g k', positive=True
)

# Marginal product of capital
fk_prime = alpha_s * k_s**(alpha_s - 1)

# Steady-state condition: f'(k) = beta + n + delta + rho*g
ss_eq = Eq(fk_prime, beta_s + n_s + delta_s + rho_s * g_s)
k_ss_sym = solve(ss_eq, k_s)[0]

print("Steady-state capital per efficiency unit:")
print(f"  k_ss = {k_ss_sym}")
```

The golden rule {cite}`phelps:golden` maximizes steady-state consumption by setting
$f'(k^{GR}) = n + g + \delta$:

```{math}
:label: rck_golden_rule
f'(k^{GR}) = n + g + \delta.
```

```{code-cell} ipython3
# Golden rule: f'(k) = n + g + delta
gr_eq = Eq(fk_prime, n_s + g_s + delta_s)
k_gr_sym = solve(gr_eq, k_s)[0]

print("Golden rule capital:")
print(f"  k_gr = {k_gr_sym}")
```

```{code-cell} ipython3
# Numerical steady-state values
subs = {alpha_s: m.alpha, delta_s: m.delta, beta_s: m.beta,
        rho_s: m.rho, n_s: m.n, g_s: m.g}

k_ss = float(k_ss_sym.subs(subs))
k_gr = float(k_gr_sym.subs(subs))
c_ss = k_ss**m.alpha - (m.g + m.n + m.delta) * k_ss
y_ss = k_ss**m.alpha
r_ss = m.alpha * k_ss**(m.alpha - 1) - m.delta

print(f"Baseline steady state:")
print(f"  k_ss = {k_ss:.4f},  k_gr = {k_gr:.4f}")
print(f"  c_ss = {c_ss:.4f},  y_ss = {y_ss:.4f}")
print(f"  r_ss = {r_ss:.4f}")
print(f"  k_ss < k_gr: {k_ss < k_gr}")
```

## Comparative Statics

The steady-state capital stock depends on all six parameters. We vary each in turn, holding
the others at baseline, and collect the results in a table.

```{code-cell} ipython3
rows = []
for label, field, vals in [
    (r'$\alpha$', 'alpha',   [0.25, 0.33, 0.40]),
    (r'$\delta$', 'delta',   [0.05, 0.08, 0.12]),
    (r'$\beta$', 'beta', [0.02, 0.04, 0.06]),
    (r'$\rho$',   'rho',     [1.0, 2.0, 4.0]),
    (r'$n$',      'n',       [0.00, 0.01, 0.02]),
    (r'$g$',      'g',       [0.01, 0.02, 0.03]),
]:
    for v in vals:
        params = m._replace(**{field: v})
        k = (params.alpha / (params.beta + params.n + params.delta + params.rho * params.g)
             ) ** (1 / (1 - params.alpha))
        c = k**params.alpha - (params.g + params.n + params.delta) * k
        s = 1 - c / k**params.alpha
        rows.append({'Parameter': label, 'Value': v,
                     'k_ss': round(k, 4), 'c_ss': round(c, 4), 's (%)': round(s * 100, 2)})

df = pd.DataFrame(rows)
df
```

# Part II: Phase Diagram and Saddle Path

## The Two Loci

The dynamics of the RCK model are governed by two differential equations. The **$\dot{k}=0$
locus** is the set of $(k, c)$ pairs where capital per efficiency unit is constant:

```{math}
:label: rck_kdot_locus
c = f(k) - (g + n + \delta)k.
```

The **$\dot{c}/c = 0$ locus** is the vertical line at $\check{k}$ where the Euler equation
[](#rck_ss_condition) holds.

## Jacobian and Eigenvalues

Linearizing the system around $(\check{k}, \check{c})$ gives the Jacobian

```{math}
:label: rck_jacobian
J = \begin{pmatrix}
f'(\check{k}) - (g+n+\delta) & -1 \\
\check{c}\,f''(\check{k})/\rho & 0
\end{pmatrix}.
```

Since $f'(\check{k}) = \beta + n + \delta + \rho g$ and $\dot{k}=0$ requires
$c_{ss} = f(k_{ss}) - (g+n+\delta)k_{ss}$, the top-left entry simplifies to
$\beta + (\rho - 1)g$.

```{code-cell} ipython3
# Numerical Jacobian
fpp_ss = m.alpha * (m.alpha - 1) * k_ss**(m.alpha - 2)
J = np.array([
    [m.beta + (m.rho - 1) * m.g,  -1.0],
    [c_ss * fpp_ss / m.rho,            0.0],
])

eigvals, eigvecs = np.linalg.eig(J)
s_idx = np.argmin(np.real(eigvals))
lam_stable = np.real(eigvals[s_idx])
v_stable = np.real(eigvecs[:, s_idx])
v_stable = v_stable / np.linalg.norm(v_stable)

print(f"Eigenvalues:  lambda_1 = {eigvals[0]:.4f},  lambda_2 = {eigvals[1]:.4f}")
print(f"Stable eigenvector: [{v_stable[0]:.4f}, {v_stable[1]:.4f}]")
print(f"Half-life of convergence: {np.log(2) / abs(lam_stable):.1f} years")
```

## Saddle Path Computation

We compute the saddle path by backward-integrating the dynamical system from a small
perturbation near the steady state along the stable eigenvector. This is the same technique
used in the [investment notebook](investment_qmodel.md).

```{code-cell} ipython3
def rck_odes(t, y):
    """RHS of the RCK dynamical system."""
    k, c = y
    if k <= 0:
        return [0.0, 0.0]
    fp = m.alpha * k**(m.alpha - 1)
    kdot = k**m.alpha - c - (m.g + m.n + m.delta) * k
    cdot = c / m.rho * (fp - m.delta - m.beta - m.n - m.rho * m.g)
    return [kdot, cdot]

# Backward-integrate two arms of the saddle path
eps = 0.02 * k_ss

def stop_at_k_bound(t, y):
    return min(y[0] - 0.01, 8.0 - y[0])
stop_at_k_bound.terminal = True
stop_at_k_bound.direction = -1

arms = []
for sign in (+1, -1):
    y0 = [k_ss + sign * eps * v_stable[0],
          c_ss + sign * eps * v_stable[1]]
    sol = solve_ivp(lambda t, y: [-dy for dy in rck_odes(t, y)],
                    [0, 200], y0, max_step=0.5,
                    events=stop_at_k_bound)
    if sol.status >= 0:
        arms.append(sol.y)

assert len(arms) == 2, f"Saddle path failed: only {len(arms)} arm(s) converged"
saddle_k = np.concatenate([arms[0][0][::-1], [k_ss], arms[1][0][::-1]])
saddle_c = np.concatenate([arms[0][1][::-1], [c_ss], arms[1][1][::-1]])
```

## Phase Diagram

```{code-cell} ipython3
k_grid = np.linspace(0.01, 8.0, 500)
c_kdot0 = np.maximum(k_grid**m.alpha - (m.g + m.n + m.delta) * k_grid, 0)

fig, ax = plt.subplots(figsize=(8, 6))

# Loci
ax.plot(k_grid, c_kdot0, color=ACCENT, lw=2, label=r'$\dot{k}=0$ locus')
ax.axvline(k_ss, color=RED, ls='--', lw=2, label=r'$\dot{c}/c=0$ locus')

# Saddle path
mask = (saddle_k > 0.01) & (saddle_k < 8)
ax.plot(saddle_k[mask], saddle_c[mask], 'k-', lw=2.5, label='Saddle path')

# Steady state and golden rule
ax.plot(k_ss, c_ss, 'ko', ms=8, zorder=5)
ax.annotate(r'$(\check{k}, \check{c})$', xy=(k_ss, c_ss),
            xytext=(k_ss + 0.5, c_ss + 0.1), fontsize=11,
            arrowprops=dict(arrowstyle='->', color='black'))
ax.axvline(k_gr, color='gray', ls=':', lw=1, alpha=0.6)
ax.annotate(r'$k^{GR}$', xy=(k_gr, 0.02), fontsize=10, color='gray')


ax.set_xlabel(r'Capital per efficiency unit $k$', fontsize=12)
ax.set_ylabel(r'Consumption per efficiency unit $c$', fontsize=12)
ax.set_title('Phase Diagram of the RCK Model', fontsize=13)
ax.legend(fontsize=10, frameon=False)
ax.set_xlim(0, 8)
ax.set_ylim(0, max(c_kdot0) * 1.15)
ax.grid(True, alpha=0.3)
plt.tight_layout()
fig.savefig(FIG_DIR / 'rck_phase_diagram.png', dpi=150, bbox_inches='tight')
plt.show()
```

# Part III: Transition Dynamics

We trace the economy's path starting from $k_0 = 0.5 \check{k}$ (below the steady state).
The initial consumption is read off the saddle path.

```{code-cell} ipython3
# Interpolate saddle path to find c0 for a given k0
# Sort by k for interpolation
order = np.argsort(saddle_k)
saddle_interp = interp1d(saddle_k[order], saddle_c[order], kind='linear',
                         bounds_error=False, fill_value='extrapolate')

k0 = 0.5 * k_ss
c0 = float(saddle_interp(k0))

sol = solve_ivp(rck_odes, [0, 150], [k0, c0], max_step=0.5)
k_path, c_path = sol.y
t_path = sol.t
y_path = k_path**m.alpha
r_path = m.alpha * k_path**(m.alpha - 1) - m.delta
```

```{code-cell} ipython3
fig, axes = plt.subplots(2, 2, figsize=(10, 7))

for ax, var, label, ss_val in zip(
    axes.flat,
    [k_path, c_path, y_path, r_path],
    [r'Capital $k(t)$', r'Consumption $c(t)$',
     r'Output $y(t)$', r'Interest rate $r(t)$'],
    [k_ss, c_ss, y_ss, r_ss],
):
    ax.plot(t_path, var, lw=2, color=ACCENT)
    ax.axhline(ss_val, color='gray', ls=':', lw=1)
    ax.set_xlabel('Time')
    ax.set_ylabel(label)
    ax.grid(True, alpha=0.3)

axes[0, 0].set_title(r'Starting from $k_0 = 0.5\,\check{k}$')
plt.tight_layout()
plt.show()
```

# Part IV: Saving and Growth

## The Steady-State Saving Rate

In steady state with $n = 0$, the gross saving rate is

```{math}
:label: rck_saving_rate
s = \frac{\alpha(\delta + g)}{\delta + \beta + \rho\,g}.
```

We derive this symbolically and examine how it responds to changes in $g$.

```{code-cell} ipython3
# Symbolic saving rate (n = 0)
s_sym = alpha_s * (delta_s + g_s) / (delta_s + beta_s + rho_s * g_s)
ds_dg = diff(s_sym, g_s)
ds_dg_simplified = simplify(ds_dg)

print("Saving rate:")
print(f"  s = {s_sym}")
print(f"\nDerivative ds/dg:")
print(f"  ds/dg = {ds_dg_simplified}")
```

```{code-cell} ipython3
# Threshold: ds/dg > 0 iff rho < 1 + beta / delta
threshold = 1 + m.beta / m.delta
print(f"Threshold: rho < {threshold:.2f}")
print(f"Baseline rho = {m.rho} => ds/dg {'> 0' if m.rho < threshold else '< 0'}")
```

## Saving Rate vs. Growth Rate

```{code-cell} ipython3
g_grid = np.linspace(0.0, 0.05, 200)

fig, ax = plt.subplots(figsize=(8, 5))
for rho_val in [0.5, 1.0, 2.0, 4.0]:
    s_val = m.alpha * (m.delta + g_grid) / (m.delta + m.beta + rho_val * g_grid)
    ax.plot(g_grid * 100, s_val * 100, lw=2, label=rf'$\rho = {rho_val}$')

ax.axhline(m.alpha * 100, color='gray', ls=':', lw=1, alpha=0.5)
ax.set_xlabel(r'Productivity growth rate $g$ (%)', fontsize=12)
ax.set_ylabel('Steady-state gross saving rate (%)', fontsize=12)
ax.set_title('Saving-growth relationship depends on risk aversion', fontsize=13)
ax.legend(fontsize=10, frameon=False)
ax.grid(True, alpha=0.3)
plt.tight_layout()
fig.savefig(FIG_DIR / 'saving_growth.png', dpi=150, bbox_inches='tight')
plt.show()
```

## Exercises

```{exercise}
:label: ex_rck_golden_rule

**Golden rule and impatience.**

(a) For the baseline parameterization, verify numerically that $\check{k} < k^{GR}$.

(b) Find the value of $\rho$ (holding all other parameters at baseline) that makes the
RCK steady state equal to the golden rule. What economic interpretation does this have?

(c) What happens to the steady-state saving rate as $\rho \to 0$?
```

```{solution-start} ex_rck_golden_rule
:class: dropdown
```

```{code-cell} ipython3
# (a) Direct comparison
print(f"k_ss = {k_ss:.4f}")
print(f"k_gr = {k_gr:.4f}")
print(f"k_ss < k_gr: {k_ss < k_gr}")

# (b) k_ss = k_gr requires beta + rho*g = g, i.e., rho = (g - beta) / g
rho_golden = (m.g - m.beta) / m.g
print(f"\nrho for k_ss = k_gr: {rho_golden:.4f}")
print("Since rho < 0, there is no positive rho that achieves the golden rule.")
print("Impatient consumers (beta > 0) always accumulate less than the golden rule.")

# (c) As rho -> 0, s -> alpha*(delta + g)/(delta + beta), which is the maximum saving rate
s_max = m.alpha * (m.delta + m.g) / (m.delta + m.beta)
print(f"\nSaving rate as rho -> 0: {s_max * 100:.2f}%")
```

The golden rule requires $\beta + \rho g = g$, i.e., $\rho = 1 - \beta/g$. With
$\beta = 0.04 > g = 0.02$, this gives $\rho < 0$, which is infeasible. Positive time
preference always pushes the economy below the golden rule.

```{solution-end}
```

```{exercise}
:label: ex_rck_convergence

**Convergence speed.**

(a) Compute the stable eigenvalue $\lambda_1$ of the linearized RCK system for $\rho \in \{1, 2, 3, 5\}$.

(b) For each $\rho$, compute the half-life of convergence $t_{1/2} = \ln(2)/|\lambda_1|$.

(c) Collect the results in a pandas DataFrame. Which parameter has the largest effect on
convergence speed?
```

```{solution-start} ex_rck_convergence
:class: dropdown
```

```{code-cell} ipython3
rows = []
for rho_val in [1.0, 2.0, 3.0, 5.0]:
    params = m._replace(rho=rho_val)
    k = (params.alpha / (params.beta + params.n + params.delta + params.rho * params.g)
         ) ** (1 / (1 - params.alpha))
    c = k**params.alpha - (params.g + params.n + params.delta) * k
    fpp = params.alpha * (params.alpha - 1) * k**(params.alpha - 2)
    J_local = np.array([
        [params.beta + (params.rho - 1) * params.g,  -1.0],
        [c * fpp / params.rho,                            0.0],
    ])
    ev = np.real(np.linalg.eigvals(J_local))
    lam1 = min(ev)
    rows.append({
        'rho': rho_val,
        'k_ss': round(k, 4),
        'lambda_1': round(lam1, 4),
        'half-life (years)': round(np.log(2) / abs(lam1), 1),
    })

pd.DataFrame(rows)
```

Higher risk aversion (lower intertemporal elasticity of substitution $1/\rho$) slows
convergence because households are less willing to deviate from their current consumption path.

```{solution-end}
```

```{exercise}
:label: ex_rck_capital_tax

**Capital income tax.**

Consider a capital income tax at rate $\tau$ with revenue rebated lump-sum. Assume $n = g = \delta = 0$ for simplicity.

(a) Derive the new steady-state condition: $f'(\bar{k})(1-\tau) = \beta$.

(b) Compute $\bar{k}$ for $\tau \in \{0, 0.1, 0.2, 0.3, 0.4\}$ and collect in a table.

(c) Plot the phase diagram showing how the $\dot{c}/c = 0$ locus shifts left as $\tau$ increases.
```

```{solution-start} ex_rck_capital_tax
:class: dropdown
```

```{code-cell} ipython3
# (a) and (b)
tau_s = symbols('tau', positive=True)
k_tax_sym = solve(Eq(alpha_s * k_s**(alpha_s - 1) * (1 - tau_s), beta_s), k_s)[0]
print(f"k_bar = {k_tax_sym}")

rows = []
for tau_val in [0.0, 0.1, 0.2, 0.3, 0.4]:
    k_bar = float(k_tax_sym.subs({alpha_s: m.alpha, beta_s: m.beta, tau_s: tau_val}))
    c_bar = k_bar**m.alpha  # with delta = 0
    rows.append({'tau': tau_val, 'k_bar': round(k_bar, 4), 'c_bar': round(c_bar, 4)})

df_tax = pd.DataFrame(rows)
df_tax
```

```{code-cell} ipython3
# (c) Phase diagram
k_grid = np.linspace(0.01, 25.0, 500)

fig, ax = plt.subplots(figsize=(8, 5))
c_locus = k_grid**m.alpha  # kdot=0 with delta=0
ax.plot(k_grid, c_locus, color=ACCENT, lw=2, label=r'$\dot{k}=0$ locus')

colors = ['gray', 'C0', 'C1', 'C3', 'C4']
for (_, row), color in zip(df_tax.iterrows(), colors):
    ax.axvline(row['k_bar'], color=color, ls='--', lw=1.5, alpha=0.7)
    ax.plot(row['k_bar'], row['c_bar'], 'o', color=color, ms=7, zorder=5)
    ax.annotate(rf"$\tau={row['tau']}$", xy=(row['k_bar'], row['c_bar']),
                xytext=(row['k_bar'] + 0.5, row['c_bar'] + 0.1),
                fontsize=9, color=color)

ax.set_xlabel(r'$k$', fontsize=12)
ax.set_ylabel(r'$c$', fontsize=12)
ax.set_title(r'Capital tax shifts $\dot{c}/c=0$ left ($\delta = n = g = 0$)', fontsize=12)
ax.legend(fontsize=10, frameon=False)
ax.set_xlim(0, 25)
ax.set_ylim(0, max(c_locus[:400]) * 1.1)
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()
```

The tax reduces the after-tax return to saving, so households accumulate less capital. The
$\dot{k}=0$ locus is unchanged (aggregate resources are unaffected by a rebated tax), but the
$\dot{c}/c=0$ locus shifts left as $\tau$ rises.

```{solution-end}
```

## References

```{bibliography}
:filter: docname in docnames
```
