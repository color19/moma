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
  Phase diagrams, investment dynamics, and impulse response functions
  for the Abel-Hayashi marginal q model of investment.
keywords:
  - investment
  - q-theory
  - phase diagram
  - Abel-Hayashi
  - adjustment costs
  - impulse response
tags:
  - investment
  - computational
---

# Investment Theory: The Marginal $q$ Model

This notebook is a computational companion to the investment theory lecture (Module 10). It covers
the Abel-Hayashi model {cite}`abel:1982,hayashi:1982` with quadratic adjustment costs, no taxes
($\tau = \xi = 0$), and a Cobb-Douglas production function $f(k) = k^\alpha$.

The notebook proceeds in four parts. Part I derives the steady state and local dynamics symbolically
using SymPy. Part II generates the phase diagram and investment function. Part III simulates impulse
responses to a permanent productivity shock. Part IV collects a comparative-statics table.

```{code-cell} ipython3
from collections import namedtuple
from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.integrate import solve_ivp
from sympy import (
    symbols, Function, sqrt, Rational, simplify, factor, latex,
    solve, diff, Matrix, lambdify, init_printing
)

init_printing()

# Figure output directory (relative to this notebook file, one level up to project root)
FIG_DIR = Path("../slides/m10/figs")
FIG_DIR.mkdir(parents=True, exist_ok=True)

# Theme colors
ACCENT = '#107895'
RED    = '#9a2515'
```

# Part I: Steady State and Local Dynamics

## Parameters

The model is summarized by three parameters.

| Parameter | Symbol | Baseline | Description |
|-----------|--------|----------|-------------|
| Capital share | $\alpha$ | 0.30 | Exponent in $f(k) = k^\alpha$ |
| Interest rate | $r$ | 0.05 | Riskless rate, equal to $1/\beta - 1$ |
| Adjustment cost | $\omega$ | 5.0 | Scales the quadratic penalty $j(i,k) = (\omega k/2)(i/k - \delta)^2$, zero at pure replacement investment |

```{code-cell} ipython3
QModel = namedtuple('QModel', ['alpha', 'r', 'omega'])
m = QModel(alpha=0.3, r=0.05, omega=5.0)
```

## Symbolic Derivation of the Steady State

At the steady state $(\check{k}, \check{q})$, both $\Delta k = 0$ and $\mathbb{E}_t[\Delta q] = 0$.
The first condition requires $\iota = 0$, which means $q = 1$. The second requires $f'(\check{k}) = r$.
With $f(k) = k^\alpha$, this pins down

```{math}
:label: iq_kss
\check{k} = \left(\frac{\alpha}{r}\right)^{1/(1-\alpha)}.
```

```{code-cell} ipython3
alpha_s, r_s, omega_s, k_s = symbols('alpha r omega k', positive=True)

# Steady-state condition: f'(k) = r => alpha * k^(alpha-1) = r
fk_s    = alpha_s * k_s**(alpha_s - 1)
k_ss_sym = solve(fk_s - r_s, k_s)[0]

print("Steady-state capital:")
print(f"  k_ss = {k_ss_sym}")
```

```{code-cell} ipython3
k_ss = float(k_ss_sym.subs({alpha_s: m.alpha, r_s: m.r}))
q_ss = 1.0
print(f"Baseline: k_ss = {k_ss:.4f},  q_ss = {q_ss:.2f}")
```

## Eigenvalues of the Jacobian

The continuous-time system linearized around $(\check{k}, \check{q})$ has the Jacobian

```{math}
:label: iq_jacobian
J = \begin{pmatrix} 0 & \check{k}/\omega \\ -f''(\check{k}) & r \end{pmatrix}.
```

The eigenvalues determine local stability. Since $\det(J) = \check{k} f''(\check{k})/\omega < 0$
(because $f'' < 0$), the two eigenvalues have opposite signs: the system is a saddle. We compute
them symbolically.

```{code-cell} ipython3
#| output: asis
from sympy.printing.mathml import mathml

def show(expr):
    ml = mathml(expr, printer='presentation')
    print(f'<math display="block" xmlns="http://www.w3.org/1998/Math/MathML">{ml}</math>')

fkk_s  = diff(fk_s, k_s)
J_sym  = Matrix([[0, k_s / omega_s], [-fkk_s, r_s]])
evals  = J_sym.eigenvals(simplify=True)

show(J_sym)
```

```{code-cell} ipython3
# Numerical eigenvalues at baseline parameters
def fk(k):  return m.alpha * k**(m.alpha - 1)
def fkk(k): return m.alpha * (m.alpha - 1) * k**(m.alpha - 2)

J_num = np.array([[0.0,        k_ss / m.omega],
                  [-fkk(k_ss), m.r           ]])
eigvals, eigvecs = np.linalg.eig(J_num)
s_idx = np.argmin(np.real(eigvals))    # negative eigenvalue = stable
v     = np.real(eigvecs[:, s_idx])
v     = v / np.linalg.norm(v)

print(f"Eigenvalues:  lambda_1 = {eigvals[0]:.4f},  lambda_2 = {eigvals[1]:.4f}")
print(f"Stable eigenvector (normalized): [{v[0]:.4f}, {v[1]:.4f}]")
```

The negative eigenvalue $\lambda_1 < 0$ corresponds to the saddle path: starting conditions off the
saddle path grow at rate $\lambda_2 > 0$ and diverge. The only bounded solution is the one that
lies exactly on the arm associated with $\lambda_1$.

# Part II: Phase Diagram and Investment Function

## Phase Diagram

The two loci partition the $(k, q)$ plane into four quadrants.

- The $\Delta k = 0$ locus is the horizontal line $q = 1$, because net investment $\iota = (q-1)/\omega$ is zero only at $q = 1$.
- The $\mathbb{E}_t[\Delta q] = 0$ locus satisfies $q = f'(k)/r$; it is downward-sloping because $f'' < 0$.

The saddle path is traced by backward-integrating the system from a starting point near the
steady state along the stable eigenvector.

```{code-cell} ipython3
def odes(t, y):
    k, q = y
    dk = (q - 1) / m.omega * k
    dq = m.r * q - fk(k)
    return [dk, dq]

# Backward-integrate saddle-path arms from a small perturbation near the SS.
# Starting close to the SS and integrating outward ensures each arm passes
# through the SS region and the two arms together form a continuous curve.
eps  = 0.02 * k_ss
arms = []
for sign in (+1, -1):
    y0  = [k_ss + sign * eps * v[0], q_ss + sign * eps * v[1]]
    sol = solve_ivp(lambda t, y: [-x for x in odes(t, y)],
                    (0, 150), y0, max_step=0.05)
    arms.append(sol.y)
```

```{code-cell} ipython3
k_lo, k_hi = 0.25 * k_ss, 1.75 * k_ss
q_lo, q_hi = 0.30, 2.30
k_grid = np.linspace(k_lo, k_hi, 400)

fig, ax = plt.subplots(figsize=(9, 5))

ax.axhline(1.0, color=RED, lw=2, label=r'$\Delta k = 0$ ($q = 1$)', zorder=2)
ax.plot(k_grid, fk(k_grid) / m.r, color=ACCENT, lw=2,
        label=r'$\mathbb{E}_t[\Delta q] = 0$', zorder=2)

for k_p, q_p in arms:
    mask = (k_p > k_lo) & (k_p < k_hi) & (q_p > q_lo) & (q_p < q_hi)
    ax.plot(k_p[mask], q_p[mask], 'k-', lw=2, zorder=3)
    vis = np.where(mask)[0]
    if len(vis) > 8:
        n  = int(0.55 * len(vis))
        i1 = vis[n]
        i2 = vis[max(n - 3, 0)]
        ax.annotate('', xy=(k_p[i2], q_p[i2]), xytext=(k_p[i1], q_p[i1]),
                    arrowprops=dict(arrowstyle='->', color='black', lw=1.5))

ax.plot(k_ss, q_ss, 'ko', ms=8, zorder=5)
ax.annotate(r'$(\check{k},\;1)$', xy=(k_ss, q_ss),
            xytext=(k_ss + 0.05 * k_ss, q_ss + 0.12), fontsize=11)

for kv, qv in [(0.50 * k_ss, 0.58), (1.50 * k_ss, 0.58),
               (0.50 * k_ss, 1.85), (1.50 * k_ss, 1.85)]:
    dk, dq = odes(0, [kv, qv])
    sc = 0.07 * k_ss / max(np.hypot(dk, dq), 1e-9)
    ax.annotate('', xy=(kv + dk * sc, qv + dq * sc), xytext=(kv, qv),
                arrowprops=dict(arrowstyle='->', color='0.6', lw=1.2))

ax.set_xlim(k_lo, k_hi)
ax.set_ylim(q_lo, q_hi)
ax.set_xlabel(r'Capital stock $k$', fontsize=11)
ax.set_ylabel(r'Marginal $q$', fontsize=11)
ax.legend(fontsize=10, loc='upper right', frameon=False)
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig(FIG_DIR / "phase_diagram.png", dpi=150, bbox_inches='tight')
plt.show()
```

The saddle path enters the steady state from the upper-left (high $q$, low $k$) and lower-right
(low $q$, high $k$). Outside the saddle path, trajectories diverge: either $q \to \infty$ (explosive
investment) or $k \to 0$ (the firm dissolves). The only bounded equilibrium path is the one that lies
exactly on a saddle arm.

## The Investment Function

The optimal investment rule is linear in $q$ with slope $1/\omega$:

```{math}
:label: iq_inv_rule
\iota_t = \frac{q_{t+1} - 1}{\omega}.
```

Higher adjustment costs (larger $\omega$) flatten the schedule: the firm responds less aggressively to
the same capital-market signal.

```{code-cell} ipython3
q_range = np.linspace(0.2, 2.6, 300)
omegas  = [2, 5, 10]
colors  = [ACCENT, '#5a9daf', '#9ac7d4']

fig, ax = plt.subplots(figsize=(9, 4.5))

for om, col in zip(omegas, colors):
    ax.plot(q_range, (q_range - 1) / om, color=col, lw=2, label=rf'$\omega = {om}$')

ax.axhline(0, color='black', lw=0.7, alpha=0.4)
ax.axvline(1, color='black', lw=0.7, alpha=0.4, ls='--')
ax.annotate(r'$q = 1$: pure replacement', xy=(1, 0.03), xytext=(1.08, 0.15),
            fontsize=10, color='gray',
            arrowprops=dict(arrowstyle='->', color='gray', lw=1.0))

ax.set_xlabel(r'Marginal $q_{t+1}$', fontsize=11)
ax.set_ylabel(r'Net investment ratio $\iota_t = i_t/k_t - \delta$', fontsize=11)
ax.set_title(r'$\iota_t = (q_{t+1} - 1)/\omega$', fontsize=12, fontweight='light')
ax.legend(fontsize=10, frameon=False)
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig(FIG_DIR / "investment_function.png", dpi=150, bbox_inches='tight')
plt.show()
```

When $q = 1$, investment exactly replaces depreciated capital ($\iota = 0$) for any $\omega$. When
$q > 1$, the firm expands; when $q < 1$, it contracts. Firms with lower adjustment costs (small
$\omega$) respond more aggressively to deviations of $q$ from 1.

# Part III: Impulse Responses

## Permanent Productivity Shock

A permanent 20 percent increase in total factor productivity ($\Psi = 1.2$) shifts the
$\mathbb{E}_t[\Delta q] = 0$ locus upward and raises the steady-state capital stock. At the
announcement date, $q$ jumps to the value on the new saddle path at the old capital stock, and
investment rises. Over time, $k$ accumulates and $q$ declines back to 1.

```{code-cell} ipython3
np.random.seed(42)
Psi = 1.2

k_ss_new = (Psi * m.alpha / m.r)**(1 / (1 - m.alpha))

def odes_new(t, y):
    k, q = y
    return [(q - 1) / m.omega * k,
            m.r * q - Psi * fk(k)]

def fkk_new(k): return Psi * m.alpha * (m.alpha - 1) * k**(m.alpha - 2)

J_new    = np.array([[0.0,               k_ss_new / m.omega],
                     [-fkk_new(k_ss_new), m.r              ]])
ev, evec = np.linalg.eig(J_new)
s_new    = np.argmin(np.real(ev))
v_new    = np.real(evec[:, s_new])
v_new   /= np.linalg.norm(v_new)

print(f"Old steady state: k_ss = {k_ss:.2f}")
print(f"New steady state: k_ss = {k_ss_new:.2f}  (+{100*(k_ss_new/k_ss - 1):.1f}%)")
```

```{code-cell} ipython3
# Find q_0: backward-integrate new saddle path from very close to the new SS.
# A 1% perturbation keeps us in the linear regime, giving an accurate start;
# then backward integration traces the nonlinear saddle path out to k_ss.
q_0 = None
for sign in (+1, -1):
    y0  = [k_ss_new + sign * 0.01 * k_ss_new * v_new[0],
           1.0      + sign * 0.01 * k_ss_new * v_new[1]]
    sol = solve_ivp(lambda t, y: [-x for x in odes_new(t, y)],
                    (0, 100), y0, max_step=0.005, rtol=1e-10, atol=1e-12)
    k_p, q_p = sol.y
    if k_p.min() <= k_ss <= k_p.max():
        idx_s = np.argsort(k_p)
        q_0   = float(np.interp(k_ss, k_p[idx_s], q_p[idx_s]))
        break

if q_0 is None:
    slope = np.real(ev[s_new]) * m.omega / k_ss_new
    q_0   = 1.0 + slope * (k_ss - k_ss_new)

print(f"Initial jump: q_0 = {q_0:.4f}  (from q = 1.0)")
```

```{code-cell} ipython3
T_sim  = 40
t_eval = np.linspace(0, T_sim, 500)
sol    = solve_ivp(odes_new, (0, T_sim), [k_ss, q_0],
                   t_eval=t_eval, max_step=0.01, rtol=1e-10, atol=1e-12)
t      = sol.t
k_t    = sol.y[0]
q_t    = sol.y[1]
iota_t = (q_t - 1) / m.omega

fig, axes = plt.subplots(1, 3, figsize=(12, 3.8))

panels = [
    (k_t,    k_ss,  k_ss_new, r'$k_t$',     'Capital $k$'),
    (q_t,    1.0,   1.0,      r'$q_t$',     'Marginal $q$'),
    (iota_t, 0.0,   0.0,      r'$\iota_t$', r'Net investment $\iota$'),
]
for ax, (y, y_old, y_new, ylabel, title) in zip(axes, panels):
    ax.plot(t, y, color=ACCENT, lw=2)
    ax.axhline(y_old, color='gray',  lw=1, ls='--', alpha=0.6, label='old SS')
    if abs(y_new - y_old) > 1e-10:
        ax.axhline(y_new, color=ACCENT, lw=1, ls=':', alpha=0.8, label='new SS')
        ax.legend(fontsize=8, loc='right', frameon=False)
    ax.set_xlabel(r'Time $t$', fontsize=10)
    ax.set_ylabel(ylabel, fontsize=11)
    ax.set_title(title, fontsize=11, fontweight='light')
    ax.grid(True, alpha=0.3)

plt.suptitle(
    r'Permanent Productivity Shock ($\Psi = 1.2$, $\omega = 5$)',
    fontsize=11, fontweight='light'
)
plt.tight_layout()
plt.savefig(FIG_DIR / "irf_productivity.png", dpi=150, bbox_inches='tight')
plt.show()
```

Capital rises gradually from the old steady state to the new one: adjustment costs prevent the firm
from jumping immediately. Marginal $q$ overshoots on impact, then declines monotonically back to 1
as the firm approaches the new optimum. Net investment $\iota$ mirrors $q$: it peaks on the
announcement date and asymptotes back to zero.

# Part IV: Comparative Statics

## How Parameters Shape the Steady State

The steady-state capital stock $\check{k} = (\alpha/r)^{1/(1-\alpha)}$ depends only on $\alpha$ and
$r$, not on $\omega$. The adjustment-cost parameter $\omega$ does not affect where the economy ends
up; it governs how fast it gets there, measured by the magnitude of the stable eigenvalue.

```{code-cell} ipython3
rows = []
for alpha_i in [0.25, 0.30, 0.35]:
    for r_i in [0.04, 0.05, 0.06]:
        for omega_i in [3.0, 5.0, 8.0]:
            mi = QModel(alpha=alpha_i, r=r_i, omega=omega_i)
            kss_i = (mi.alpha / mi.r)**(1 / (1 - mi.alpha))
            fkk_i = mi.alpha * (mi.alpha - 1) * kss_i**(mi.alpha - 2)
            J_i   = np.array([[0.0,     kss_i / mi.omega],
                              [-fkk_i,  mi.r            ]])
            ev_i  = np.linalg.eigvals(J_i)
            lam_i = float(np.real(ev_i[np.argmin(np.real(ev_i))]))
            rows.append({
                r'$\alpha$': alpha_i,
                r'$r$':      r_i,
                r'$\omega$': omega_i,
                r'$\check{k}$': round(kss_i, 2),
                r'$\lambda_-$': round(lam_i, 4),
                r'Half-life (yr)': round(-np.log(2) / lam_i, 1),
            })

df = pd.DataFrame(rows)
df
```

The table illustrates three comparative-statics predictions. A higher capital share $\alpha$ raises
$\check{k}$ (more profitable capital accumulation). A lower interest rate $r$ also raises $\check{k}$
(cheaper discounting). A higher adjustment cost $\omega$ leaves $\check{k}$ unchanged but slows
convergence, as reflected in the longer half-life.

## Exercises

```{exercise}
:label: ex_iq_hayashi

**Hayashi's theorem.** Under perfect capital markets, Hayashi (1982) shows that the firm's average
$Q$ (stock market value divided by replacement cost of capital) equals its marginal $q$ (shadow
value of one additional unit of capital). The equality breaks down when capital markets are
imperfect.

(a) Write down the firm's value $V(k)$ in the Abel-Hayashi model and define average $Q = V(k)/(pk)$,
where $p$ is the replacement price of capital.

(b) Show that constant-returns-to-scale production and homogeneous adjustment costs together imply
$V(k) = q \cdot k$, so average $Q = q =$ marginal $q$.

(c) Explain in words why the equality fails when the firm faces a financial wedge between internal
and external funds.
```

```{solution-start} ex_iq_hayashi
:class: dropdown
```

**Part (a).** With normalized replacement price $p = 1$, average $Q = V(k)/k$. In the continuous-time
version, $V(k)$ is the present discounted value of future dividends along the optimal path.

**Part (b).** Under constant returns, $f(\lambda k) = \lambda f(k)$ and $j(\lambda i, \lambda k) = \lambda j(i, k)$.
Euler's theorem then gives $V(\lambda k) = \lambda V(k)$, so $V$ is homogeneous of degree one. This
means $V(k) = V'(k) \cdot k = q \cdot k$, and average $Q = q$.

**Part (c).** With a financing wedge, the cost of external funds exceeds the cost of internal funds.
The firm's investment decision then depends on its internal cash position, not just on $q$. The value
function is no longer homogeneous of degree one in $k$ alone, and the equality between average $Q$
and marginal $q$ fails.

```{solution-end}
```

```{exercise}
:label: ex_iq_omega_speed

**Adjustment-cost sensitivity.** Using the comparative-statics table above:

(a) For fixed $\alpha = 0.30$ and $r = 0.05$, fit a simple regression of the half-life on $\omega$
using the three $\omega$ values in the table. Is the relationship linear?

(b) Derive analytically how the stable eigenvalue $\lambda_-$ depends on $\omega$ as $\omega \to \infty$.
What does this imply for the half-life?

(c) Simulate the impulse response for $\omega \in \{2, 5, 10, 20\}$ and plot the path of $k_t$ on
a single axis. Confirm that higher $\omega$ slows convergence.
```

```{solution-start} ex_iq_omega_speed
:class: dropdown
```

```{code-cell} ipython3
# Part (a): regression of half-life on omega for alpha=0.30, r=0.05
subset = df[(df[r'$\alpha$'] == 0.30) & (df[r'$r$'] == 0.05)].copy()
omegas_sub = subset[r'$\omega$'].values
halflives  = subset['Half-life (yr)'].values

coeffs = np.polyfit(omegas_sub, halflives, 1)
print(f"OLS: half-life = {coeffs[0]:.2f} * omega + {coeffs[1]:.2f}")
print("Relationship is approximately linear over this range.")
```

```{code-cell} ipython3
# Part (c): impulse responses for varying omega
fig, ax = plt.subplots(figsize=(9, 4))
om_vals = [2, 5, 10, 20]
cols    = [ACCENT, '#5a9daf', '#9ac7d4', '#c8e4ec']

for om_i, col in zip(om_vals, cols):
    mi = QModel(alpha=0.30, r=0.05, omega=om_i)
    kss_i = (mi.alpha / mi.r)**(1 / (1 - mi.alpha))
    fkk_i = mi.alpha * (mi.alpha - 1) * kss_i**(mi.alpha - 2)
    kss_new_i = (1.2 * mi.alpha / mi.r)**(1 / (1 - mi.alpha))
    fkk_new_i = lambda k: 1.2 * mi.alpha * (mi.alpha - 1) * k**(mi.alpha - 2)

    J_i   = np.array([[0.0,               kss_new_i / mi.omega],
                      [-fkk_new_i(kss_new_i), mi.r            ]])
    ev_i, evec_i = np.linalg.eig(J_i)
    s_i   = np.argmin(np.real(ev_i))
    v_i   = np.real(evec_i[:, s_i])
    v_i  /= np.linalg.norm(v_i)

    def odes_i(t, y, mi=mi, fk_i=lambda k, a=mi.alpha: a * k**(a - 1)):
        k, q = y
        return [(q - 1) / mi.omega * k, mi.r * q - 1.2 * fk_i(k)]

    q_0_i = None
    for sign in (+1, -1):
        y0_i  = [kss_new_i + sign * 0.01 * kss_new_i * v_i[0],
                 1.0       + sign * 0.01 * kss_new_i * v_i[1]]
        sol_i = solve_ivp(lambda t, y: [-x for x in odes_i(t, y)],
                          (0, 100), y0_i, max_step=0.005, rtol=1e-10, atol=1e-12)
        k_pi, q_pi = sol_i.y
        if k_pi.min() <= kss_i <= k_pi.max():
            idx = np.argsort(k_pi)
            q_0_i = float(np.interp(kss_i, k_pi[idx], q_pi[idx]))
            break
    if q_0_i is None:
        slope = np.real(ev_i[s_i]) * mi.omega / kss_new_i
        q_0_i = 1.0 + slope * (kss_i - kss_new_i)

    sol_i = solve_ivp(odes_i, (0, 60), [kss_i, q_0_i],
                      t_eval=np.linspace(0, 60, 600), max_step=0.01, rtol=1e-10, atol=1e-12)
    ax.plot(sol_i.t, sol_i.y[0] / kss_i, color=col, lw=2, label=rf'$\omega = {om_i}$')

ax.axhline(1.0, color='gray', lw=1, ls='--', alpha=0.6, label='old SS')
ax.set_xlabel(r'Time $t$', fontsize=11)
ax.set_ylabel(r'$k_t / \check{k}_{\text{old}}$', fontsize=11)
ax.set_title('Convergence speed by adjustment cost', fontsize=11, fontweight='light')
ax.legend(fontsize=9, frameon=False)
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()
```

```{solution-end}
```

```{exercise}
:label: ex_iq_tax

**Investment tax credit.** Suppose the government introduces a permanent investment tax credit at
rate $\xi$. The FOC becomes $(1 - \xi)(1 + \omega \iota) = q$, and the investment function is

$$\iota_t = \frac{q_{t+1}/(1-\xi) - 1}{\omega}.$$

(a) How does the ITC change the $\Delta k = 0$ locus? How does it change the $\Delta q = 0$ locus?

(b) Using Python, plot the old and new phase diagrams side by side for $\xi = 0.10$.

(c) Compute the new steady-state $\check{k}$ and the percentage change relative to the baseline.
Does it depend on $\xi$?
```

```{solution-start} ex_iq_tax
:class: dropdown
```

**Part (a).** The ITC shifts the $\Delta k = 0$ locus downward: investment is zero when
$q = (1 - \xi) < 1$ rather than at $q = 1$. The $\Delta q = 0$ locus is unchanged because it
depends only on $f'(k)$ and $r$.

**Part (b) and (c):**

```{code-cell} ipython3
xi = 0.10

fig, axes = plt.subplots(1, 2, figsize=(12, 5))
k_grid2 = np.linspace(0.25 * k_ss, 1.75 * k_ss, 400)

for ax, xi_i, title_i in zip(axes, [0.0, xi], ['No ITC ($\\xi=0$)', 'ITC ($\\xi=0.10$)']):
    q_dk0 = 1.0 - xi_i           # Δk=0: q = (1-xi)
    q_dq0 = fk(k_grid2) / m.r   # Δq=0: unchanged

    ax.axhline(q_dk0, color=RED, lw=2, label=r'$\Delta k = 0$', zorder=2)
    ax.plot(k_grid2, q_dq0, color=ACCENT, lw=2,
            label=r'$\mathbb{E}_t[\Delta q] = 0$', zorder=2)

    # Steady state: intersection of Δk=0 (q=1-xi) and Δq=0 (q=f'(k)/r)
    kss_xi = (m.alpha / (m.r * (1 - xi_i)))**(1 / (1 - m.alpha))   # increases with xi
    ax.plot(kss_xi, q_dk0, 'ko', ms=8, zorder=5)
    ax.set_xlim(0.25 * k_ss, 1.75 * k_ss)
    ax.set_ylim(0.3, 2.3)
    ax.set_xlabel(r'$k$', fontsize=11)
    ax.set_ylabel(r'$q$', fontsize=11)
    ax.set_title(title_i, fontsize=11)
    ax.legend(fontsize=9, frameon=False)
    ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.show()

kss_itc = (m.alpha / (m.r * (1 - xi)))**(1 / (1 - m.alpha))
print(f"Baseline k_ss = {k_ss:.2f};  ITC (ξ={xi}) k_ss = {kss_itc:.2f}  ({100*(kss_itc/k_ss - 1):.1f}% higher)")
print(f"Steady-state q shifts from 1.00 to {1 - xi:.2f}  (Δk=0 locus moves down; Δq=0 unchanged)")
```

```{solution-end}
```

## References

```{bibliography}
:filter: docname in docnames
```
