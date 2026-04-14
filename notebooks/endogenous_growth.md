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
  Rebelo's taxonomy of growth possibilities, the AK model, Romer (1986) knowledge
  externalities, and Lucas (1988) human capital accumulation, with symbolic
  derivations and numerical illustrations.
keywords:
  - endogenous growth
  - AK model
  - Romer
  - Lucas
  - knowledge externalities
  - human capital
tags:
  - growth
  - computational
---

# Endogenous Growth: AK, Romer, and Lucas Models

This notebook is a computational companion to the Growth Theory II lecture (Module 12). It covers
three canonical endogenous growth models: the Rebelo {cite}`rebelo:long` AK model, the
Romer {cite}`romer:growth` model of knowledge externalities, and the Lucas {cite}`lucas:growth`
model of human capital accumulation.

The notebook proceeds in four parts. Part I derives Rebelo's taxonomy of steady-state growth
possibilities. Part II solves the AK model and contrasts its dynamics with the RCK model.
Part III examines the private-vs-social growth wedge in the Romer model. Part IV analyzes the
Lucas model with human capital externalities.

:::{seealso}
The [Neoclassical Growth notebook](neoclassical_growth.md) covers the Ramsey-Cass-Koopmans model,
which provides the baseline against which endogenous growth models are compared.
:::

```{code-cell} ipython3
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy import optimize
from sympy import (
    symbols, Rational, simplify, solve, diff, factor, latex, Eq,
    init_printing, oo, limit,
)

init_printing()

# Theme colors
ACCENT = '#107895'
RED    = '#9a2515'
```

## Model Parameters

We define three `namedtuple` types, one per model.

```{code-cell} ipython3
from collections import namedtuple

AKModel    = namedtuple('AKModel',    ['A', 'delta_t', 'rho'])
RomerModel = namedtuple('RomerModel', ['alpha', 'eta', 'delta_t', 'rho'])
LucasModel = namedtuple('LucasModel', ['alpha', 'phi', 'delta_t', 'rho', 'psi'])

ak = AKModel(A=0.15, delta_t=0.04, rho=2.0)
rm = RomerModel(alpha=0.33, eta=0.67, delta_t=0.04, rho=2.0)
lm = LucasModel(alpha=0.33, phi=0.10, delta_t=0.04, rho=2.0, psi=0.2)
```

# Part I: Rebelo's Taxonomy

## The Growth Equation

Rebelo {cite}`rebelo:long` considers a general Cobb-Douglas production function
$Y = A K^\alpha L^\beta$ where $\alpha + \beta$ need not equal one. With a constant saving
rate $s$ and population growth $n$, steady-state growth at rate $\gamma$ requires

```{math}
:label: endo_rebelo_condition
0 = (\alpha - 1)\gamma + n(\alpha + \beta - 1).
```

We derive this condition symbolically and solve for $\gamma$ in each case.

```{code-cell} ipython3
alpha_s, beta_s, gamma_s, n_s = symbols('alpha beta gamma n', real=True)

# The steady-state growth condition
rebelo_eq = Eq((alpha_s - 1) * gamma_s + n_s * (alpha_s + beta_s - 1), 0)

# Solve for gamma
gamma_sol = solve(rebelo_eq, gamma_s)[0]
print(f"General solution: gamma = {gamma_sol}")
```

## Catalog of Growth Possibilities

```{code-cell} ipython3
cases = []

# Case 1a: CRS with alpha < 1 (Solow)
g1a = gamma_sol.subs(beta_s, 1 - alpha_s)  # alpha + beta = 1
cases.append({
    'Case': '1a: CRS, α < 1',
    'Condition': r'$\alpha + \beta = 1$, $\alpha < 1$',
    'gamma': f'{simplify(g1a)}',
    'Name': 'Solow',
})

# Case 1b: CRS with alpha = 1 (AK)
cases.append({
    'Case': '1b: CRS, α = 1',
    'Condition': r'$\alpha = 1$, $\beta = 0$',
    'gamma': 'any (from Euler eq.)',
    'Name': 'Rebelo AK',
})

# Case 2a.i: IRS with n > 0
g2ai = gamma_sol  # general form
cases.append({
    'Case': '2a.i: IRS, n > 0',
    'Condition': r'$\alpha + \beta > 1$, $\alpha < 1$, $n > 0$',
    'gamma': rf'$\frac{{(\alpha+\beta-1)}}{{(1-\alpha)}} n$',
    'Name': 'Scale effects',
})

# Case 2a.ii: IRS with n = 0
g2aii = gamma_sol.subs(n_s, 0)
cases.append({
    'Case': '2a.ii: IRS, n = 0',
    'Condition': r'$\alpha + \beta > 1$, $\alpha < 1$, $n = 0$',
    'gamma': f'{g2aii}',
    'Name': 'No growth',
})

# Case 2b.i: IRS with alpha = 1, beta > 0, n > 0
cases.append({
    'Case': '2b.i: IRS, α = 1, n > 0',
    'Condition': r'$\alpha = 1$, $\beta > 0$, $n > 0$',
    'gamma': 'No steady state',
    'Name': '(inconsistent)',
})

# Case 2b.ii: IRS with alpha = 1, beta > 0, n = 0
cases.append({
    'Case': '2b.ii: IRS, α = 1, n = 0',
    'Condition': r'$\alpha = 1$, $\beta > 0$, $n = 0$',
    'gamma': 'any (from Euler eq.)',
    'Name': 'Second endogenous config.',
})

df_cases = pd.DataFrame(cases)
df_cases
```

## Numerical Examples

```{code-cell} ipython3
# Compute growth rates for specific parameterizations
examples = []
for alpha_val, beta_val, n_val, label in [
    (0.33, 0.67, 0.01, 'Solow (CRS)'),
    (1.0,  0.0,  0.01, 'AK'),
    (0.4,  0.8,  0.02, 'IRS, n=0.02'),
    (0.4,  0.8,  0.0,  'IRS, n=0'),
]:
    if alpha_val == 1.0:
        g_val = 'N/A (no transition)'
    elif alpha_val + beta_val == 1.0 and alpha_val < 1.0:
        g_val = 0.0
    else:
        g_val = float(gamma_sol.subs({alpha_s: alpha_val, beta_s: beta_val, n_s: n_val}))
    examples.append({
        'Model': label, 'alpha': alpha_val, 'beta': beta_val,
        'n': n_val, 'gamma': g_val,
    })

pd.DataFrame(examples)
```

# Part II: The AK Model

## Growth Rate and Saving

In the AK model ($Y = AK$, no depreciation or population growth), the Euler equation gives
a constant consumption growth rate:

```{math}
:label: endo_ak_euler
\frac{\dot{C}}{C} = \frac{1}{\rho}(A - \delta_t).
```

The saving rate is constant and proportional to growth:

```{math}
:label: endo_ak_saving
s = \gamma / A, \quad \text{where } \gamma = \frac{A - \delta_t}{\rho}.
```

```{code-cell} ipython3
A_s, delta_t_s, rho_s = symbols('A delta_t rho', positive=True)

gamma_ak = (A_s - delta_t_s) / rho_s
s_ak = gamma_ak / A_s

print(f"AK growth rate: {gamma_ak}")
print(f"AK saving rate: {simplify(s_ak)}")

# Numerical
gamma_num = (ak.A - ak.delta_t) / ak.rho
s_num = gamma_num / ak.A
print(f"\nBaseline: gamma = {gamma_num:.4f} ({gamma_num*100:.2f}%)")
print(f"          s     = {s_num:.4f} ({s_num*100:.2f}%)")
```

## Impatience Condition

The AK model has a well-defined solution only when $\gamma < A$. For a given $A$, the minimum
feasible $\rho$ satisfies $\rho^{-1}(A - \delta_t) < A$. We find the critical $\rho$ numerically.

```{code-cell} ipython3
# Find the rho at which the impatience condition binds: gamma = A
# gamma = (A - delta_t) / rho = A  =>  rho = (A - delta_t) / A
rho_crit_exact = (ak.A - ak.delta_t) / ak.A

# Verify numerically with brentq
def impatience_residual(rho_val):
    return (ak.A - ak.delta_t) / rho_val - ak.A

rho_crit = optimize.brentq(impatience_residual, 0.01, 10.0)
print(f"Critical rho (analytic): {rho_crit_exact:.4f}")
print(f"Critical rho (brentq):   {rho_crit:.4f}")
print(f"Baseline rho = {ak.rho} is {'feasible' if ak.rho > rho_crit else 'infeasible'}")
```

## AK vs. RCK Dynamics

The AK model has no transitional dynamics: all economies grow at the same rate regardless of
initial capital. In contrast, the RCK model exhibits convergence to a common steady state.

```{code-cell} ipython3
T = 80
t = np.linspace(0, T, 500)

fig, axes = plt.subplots(1, 2, figsize=(10, 4))

# AK: parallel growth paths
for K0, label in [(1.0, 'Rich country'), (0.3, 'Poor country')]:
    Y = ak.A * K0 * np.exp(gamma_num * t)
    axes[0].plot(t, Y / (ak.A * 1.0), lw=2, label=label)
axes[0].set_xlabel('Time')
axes[0].set_ylabel('Output (relative to rich at $t=0$)')
axes[0].set_title('AK: no convergence')
axes[0].legend(fontsize=9, frameon=False)
axes[0].grid(True, alpha=0.3)

# RCK: convergence (stylized linearization)
alpha_rck, delta_rck, delta_t_rck = 0.33, 0.08, 0.04
n_rck, g_rck, rho_rck = 0.01, 0.02, 2.0
k_ss_rck = (alpha_rck / (delta_rck + delta_t_rck + rho_rck * g_rck)
            ) ** (1 / (1 - alpha_rck))
lam_approx = -0.04

for frac, label in [(0.3, 'Poor country'), (1.5, 'Rich country')]:
    k0 = frac * k_ss_rck
    k_path = k_ss_rck + (k0 - k_ss_rck) * np.exp(lam_approx * t)
    axes[1].plot(t, k_path**alpha_rck, lw=2, label=label)
axes[1].axhline(k_ss_rck**alpha_rck, color='gray', ls=':', lw=1)
axes[1].set_xlabel('Time')
axes[1].set_ylabel('Output per efficiency unit')
axes[1].set_title('RCK: convergence to steady state')
axes[1].legend(fontsize=9, frameon=False)
axes[1].grid(True, alpha=0.3)

plt.tight_layout()
plt.show()
```

## Sensitivity to Technology Parameter

```{code-cell} ipython3
A_grid = np.linspace(0.05, 0.30, 200)

fig, axes = plt.subplots(1, 2, figsize=(10, 4))

for rho_val in [1.0, 2.0, 4.0]:
    gamma_grid = (A_grid - ak.delta_t) / rho_val
    s_grid = gamma_grid / A_grid
    axes[0].plot(A_grid, gamma_grid * 100, lw=2, label=rf'$\rho = {rho_val}$')
    axes[1].plot(A_grid, s_grid * 100, lw=2, label=rf'$\rho = {rho_val}$')

axes[0].set_xlabel(r'Technology parameter $A$')
axes[0].set_ylabel('Growth rate (%)')
axes[0].set_title('AK growth rate increases linearly in $A$')
axes[0].legend(fontsize=9, frameon=False)
axes[0].grid(True, alpha=0.3)

axes[1].set_xlabel(r'Technology parameter $A$')
axes[1].set_ylabel('Saving rate (%)')
axes[1].set_title('AK saving rate increases with $A$')
axes[1].legend(fontsize=9, frameon=False)
axes[1].grid(True, alpha=0.3)

plt.tight_layout()
plt.show()
```

# Part III: Romer (1986) — Knowledge Externalities

## Private vs. Social Returns

In the Romer model, firm-level production is CRS in $(k, \ell)$:

```{math}
:label: endo_romer_production
y_j = k_j^\alpha \, \ell_j^{1-\alpha} \, \Xi^\eta
```

where $\Xi = K$ is aggregate knowledge (a byproduct of investment). On a balanced growth path
with $\alpha + \eta = 1$, the **private** and **social** growth rates are

```{math}
:label: endo_romer_private
\gamma_{\text{private}} = \frac{1}{\rho}(\alpha - \delta_t)
```

```{math}
:label: endo_romer_social
\gamma_{\text{social}} = \frac{1}{\rho}(\alpha + \eta - \delta_t) = \frac{1}{\rho}(1 - \delta_t).
```

```{code-cell} ipython3
alpha_s, eta_s, delta_t_s, rho_s = symbols('alpha eta delta_t rho', positive=True)

gamma_priv = (alpha_s - delta_t_s) / rho_s
gamma_soc  = (alpha_s + eta_s - delta_t_s) / rho_s
wedge      = simplify(gamma_soc - gamma_priv)

print(f"Private growth rate: {gamma_priv}")
print(f"Social growth rate:  {gamma_soc}")
print(f"Externality wedge:   {wedge}")
```

## Optimal Subsidy

The optimal Pigouvian subsidy $s^*$ on capital equates private after-subsidy MPK to social MPK:

$$(1 + s^*)\alpha = \alpha + \eta \quad \Longrightarrow \quad s^* = \eta / \alpha.$$

```{code-cell} ipython3
s_star = eta_s / alpha_s
print(f"Optimal subsidy rate: s* = {s_star}")
print(f"Baseline: s* = {rm.eta / rm.alpha:.4f} ({rm.eta / rm.alpha * 100:.1f}%)")
```

## Private vs. Social Growth Rates

```{code-cell} ipython3
alpha_grid = np.linspace(0.15, 0.85, 200)
eta_grid = 1 - alpha_grid  # balanced growth path condition

g_priv = (alpha_grid - rm.delta_t) / rm.rho
g_soc  = (1 - rm.delta_t) / rm.rho * np.ones_like(alpha_grid)

fig, ax = plt.subplots(figsize=(8, 5))
ax.plot(alpha_grid, g_priv * 100, lw=2, color=ACCENT, label='Private (decentralized)')
ax.plot(alpha_grid, g_soc * 100, lw=2, ls='--', color=RED, label='Social (planner)')
ax.fill_between(alpha_grid, g_priv * 100, g_soc * 100, alpha=0.12, color=RED)

mid_y = (g_priv[100] + g_soc[100]) / 2 * 100
ax.annotate(r'Wedge $= \eta / \rho$', xy=(0.5, mid_y), fontsize=11,
            ha='center', color=RED)

ax.set_xlabel(r'Capital share $\alpha$ (with $\eta = 1 - \alpha$)', fontsize=12)
ax.set_ylabel('Growth rate (%)', fontsize=12)
ax.set_title('Romer (1986): knowledge externalities create underinvestment', fontsize=13)
ax.legend(fontsize=10, frameon=False)
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()
```

## Subsidy Rates by Capital Share

```{code-cell} ipython3
subsidy_grid = (1 - alpha_grid) / alpha_grid

fig, ax = plt.subplots(figsize=(8, 4))
ax.plot(alpha_grid, subsidy_grid * 100, lw=2, color=ACCENT)
ax.set_xlabel(r'Capital share $\alpha$', fontsize=12)
ax.set_ylabel(r'Optimal subsidy rate $s^* = \eta/\alpha$ (%)', fontsize=12)
ax.set_title('Optimal investment subsidy falls as private capital share rises', fontsize=12)
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()
```

# Part IV: Lucas (1988) — Human Capital

## The Planner's Growth Rate

Lucas {cite}`lucas:growth` introduces a time allocation between work ($u$) and study ($1-u$).
Human capital $h$ accumulates at rate $\dot{h}/h = \phi(1-u)$, with no diminishing returns.

The social planner's optimal growth rate is

```{math}
:label: endo_lucas_planner
\gamma_{\text{planner}} = \frac{1}{\rho}(\phi - \delta_t).
```

## Decentralized Growth with Externalities

When individual productivity depends on average human capital $\bar{h}^\psi$, the
decentralized growth rate is

```{math}
:label: endo_lucas_decentral
\gamma_h = \frac{\rho^{-1}(\phi - \delta_t)}{1 + \psi(1 - 1/\rho)/(1-\alpha)}.
```

The direction of the externality's effect depends on whether $\rho \gtrless 1$.

```{code-cell} ipython3
phi_s, psi_s = symbols('phi psi', positive=True)

gamma_planner = (phi_s - delta_t_s) / rho_s
gamma_decent  = gamma_planner / (1 + psi_s * (1 - 1/rho_s) / (1 - alpha_s))

print(f"Planner growth rate:       {gamma_planner}")
print(f"Decentralized growth rate: {simplify(gamma_decent)}")
```

```{code-cell} ipython3
# Numerical comparison
g_plan = (lm.phi - lm.delta_t) / lm.rho
g_dec  = g_plan / (1 + lm.psi * (1 - 1/lm.rho) / (1 - lm.alpha))

print(f"Planner:       {g_plan*100:.2f}%")
print(f"Decentralized: {g_dec*100:.2f}%")
print(f"Ratio:         {g_dec/g_plan:.4f}")
```

## Externality and Risk Aversion

```{code-cell} ipython3
psi_grid = np.linspace(0, 0.5, 200)

fig, ax = plt.subplots(figsize=(8, 5))
for rho_val in [0.5, 1.0, 2.0, 4.0]:
    g_plan_val = (lm.phi - lm.delta_t) / rho_val
    g_dec_val = g_plan_val / (1 + psi_grid * (1 - 1/rho_val) / (1 - lm.alpha))
    ax.plot(psi_grid, g_dec_val * 100, lw=2, label=rf'$\rho = {rho_val}$')

ax.set_xlabel(r'Externality parameter $\psi$', fontsize=12)
ax.set_ylabel('Decentralized growth rate (%)', fontsize=12)
ax.set_title(r'Lucas externality: direction depends on $\rho$ relative to 1', fontsize=13)
ax.legend(fontsize=10, frameon=False)
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()
```

## Comparing All Three Models

```{code-cell} ipython3
comparison = pd.DataFrame([
    {
        'Model': 'Rebelo AK',
        'Engine': r'$Y = AK$',
        'Growth rate': rf'$({ak.A} - {ak.delta_t}) / {ak.rho} = {gamma_num:.3f}$',
        'Saving rate (%)': round(s_num * 100, 1),
        'Transitional dynamics': 'None',
        'Market failure': 'None',
    },
    {
        'Model': 'Romer (1986)',
        'Engine': r'Knowledge spillovers ($\Xi = K$)',
        'Growth rate': rf'$({rm.alpha} - {rm.delta_t}) / {rm.rho} = {(rm.alpha - rm.delta_t)/rm.rho:.3f}$ (private)',
        'Saving rate (%)': 'N/A (no closed form)',
        'Transitional dynamics': 'None (on BGP)',
        'Market failure': 'Externality',
    },
    {
        'Model': 'Lucas (1988)',
        'Engine': r'Human capital ($\dot{h}/h = \phi(1-u)$)',
        'Growth rate': rf'$({lm.phi} - {lm.delta_t}) / {lm.rho} = {g_plan:.3f}$ (planner)',
        'Saving rate (%)': 'N/A',
        'Transitional dynamics': 'None (on BGP)',
        'Market failure': rf'Externality ($\psi = {lm.psi}$)',
    },
])
comparison
```

## Exercises

```{exercise}
:label: ex_endo_ak_calibration

**Calibrating the AK model.**

(a) US per-capita GDP has grown at roughly 2% per year since 1950. With $\rho = 2$ and
$\delta_t = 0.04$, what value of $A$ is required to match this growth rate?

(b) What is the implied saving rate $s = \gamma / A$?

(c) Use `scipy.optimize.brentq` to find the value of $\rho$ that produces a 3% saving rate
with the $A$ you found in (a).
```

```{solution-start} ex_endo_ak_calibration
:class: dropdown
```

```{code-cell} ipython3
# (a)
target_gamma = 0.02
rho_cal = 2.0
delta_t_cal = 0.04
A_cal = target_gamma * rho_cal + delta_t_cal
print(f"(a) A = gamma * rho + delta_t = {A_cal:.2f}")

# (b)
s_cal = target_gamma / A_cal
print(f"(b) Implied saving rate: {s_cal * 100:.1f}%")

# (c)
target_s = 0.03
def residual(rho_val):
    gamma_val = (A_cal - delta_t_cal) / rho_val
    return gamma_val / A_cal - target_s

rho_star = optimize.brentq(residual, 0.1, 50.0)
print(f"(c) rho for s = 3%: {rho_star:.4f}")
print(f"    Implied growth rate: {(A_cal - delta_t_cal) / rho_star * 100:.2f}%")
```

With $A = 0.08$, the marginal product of capital is 8%, consistent with standard calibrations.
The saving rate of 25% is reasonable. But part (c) reveals a tension: matching a 3% saving rate
requires $\rho \approx 16.7$, far above the conventional range of 1 to 4.

```{solution-end}
```

```{exercise}
:label: ex_endo_romer_subsidy

**Optimal subsidy in the Romer model.**

(a) Compute the optimal Pigouvian subsidy $s^* = \eta/\alpha$ for $\alpha \in \{0.2, 0.33, 0.5, 0.7\}$
(with $\alpha + \eta = 1$ on the BGP).

(b) For each $\alpha$, compute the private and social growth rates with $\rho = 2$ and $\delta_t = 0.04$.

(c) Collect results in a pandas DataFrame.
```

```{solution-start} ex_endo_romer_subsidy
:class: dropdown
```

```{code-cell} ipython3
rows = []
for alpha_val in [0.2, 0.33, 0.5, 0.7]:
    eta_val = 1 - alpha_val
    s_star = eta_val / alpha_val
    g_priv = (alpha_val - rm.delta_t) / rm.rho
    g_soc  = (1 - rm.delta_t) / rm.rho
    rows.append({
        'alpha': alpha_val,
        'eta': round(eta_val, 2),
        's* (%)': round(s_star * 100, 1),
        'gamma_priv (%)': round(g_priv * 100, 2),
        'gamma_soc (%)': round(g_soc * 100, 2),
        'wedge (pp)': round((g_soc - g_priv) * 100, 2),
    })

pd.DataFrame(rows)
```

When $\alpha$ is small (capital contributes little to private output), the externality is large
and the optimal subsidy exceeds 100%. As $\alpha$ rises, private returns capture more of the
social benefit and the required subsidy falls.

```{solution-end}
```

```{exercise}
:label: ex_endo_lucas_allocation

**Optimal time allocation in the Lucas model.**

In the Lucas model, the planner chooses $u^*$ (fraction of time working) to maximize steady-state
utility. On the balanced growth path, the growth rate is $\gamma = \phi(1-u)$ and output per
worker is $y = A k^\alpha (u h)^{1-\alpha}$.

(a) With $\phi = 0.10$ and $\delta_t = 0.04$, compute $u^*$ from the planner's first-order
condition: the marginal product of working time must equal the marginal value of studying.

(b) How does $u^*$ change as $\phi$ increases from 0.05 to 0.20? Plot the relationship.

(c) What is the growth rate at each $\phi$ value?
```

```{solution-start} ex_endo_lucas_allocation
:class: dropdown
```

```{code-cell} ipython3
# On the BGP, gamma = phi*(1-u). The planner's optimal growth rate is
# gamma = (phi - delta_t)/rho. Substituting and solving for u*:
#   u* = 1 - gamma/phi = 1 - (phi - delta_t) / (rho * phi)

phi_grid = np.linspace(0.05, 0.20, 200)

u_star = 1 - (phi_grid - lm.delta_t) / (lm.rho * phi_grid)
gamma_vals = phi_grid * (1 - u_star)

fig, axes = plt.subplots(1, 2, figsize=(10, 4))

axes[0].plot(phi_grid, u_star, lw=2, color=ACCENT)
axes[0].set_xlabel(r'Human capital efficiency $\phi$')
axes[0].set_ylabel(r'Optimal working fraction $u^*$')
axes[0].set_title(r'Higher $\phi$ lowers time spent working')
axes[0].grid(True, alpha=0.3)

axes[1].plot(phi_grid, gamma_vals * 100, lw=2, color=RED)
axes[1].set_xlabel(r'Human capital efficiency $\phi$')
axes[1].set_ylabel('Growth rate (%)')
axes[1].set_title('Growth accelerates with human capital efficiency')
axes[1].grid(True, alpha=0.3)

plt.tight_layout()
plt.show()

# (a) Baseline
u_baseline = 1 - (lm.phi - lm.delta_t) / (lm.rho * lm.phi)
print(f"(a) u* = {u_baseline:.4f} (spend {(1-u_baseline)*100:.1f}% of time studying)")
print(f"    Growth rate: {lm.phi * (1 - u_baseline) * 100:.2f}%")
```

As $\phi$ rises, the return to studying increases, so the planner allocates more time to
human capital accumulation ($u^*$ falls). The growth rate rises because both channels reinforce:
more efficient studying and more time spent studying.

```{solution-end}
```

## References

```{bibliography}
:filter: docname in docnames
```
