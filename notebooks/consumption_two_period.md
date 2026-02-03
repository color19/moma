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
  The Fisher two-period optimal consumption problem and consumption with
  labor supply: budget constraints, the Euler equation, CRRA utility,
  the consumption function, Fisherian separation, comparative statics,
  intratemporal choice with Cobb-Douglas preferences, and the
  intertemporal elasticity of labor supply puzzle.
keywords:
  - two-period model
  - Euler equation
  - consumption function
  - Fisherian separation
  - labor supply
  - intertemporal elasticity
tags:
  - consumption
  - intertemporal-choice
---

# Two-Period Consumption and Labor Supply

This notebook develops two foundational models of intertemporal choice.
**Part I** covers the Fisher two-period consumption problem: a consumer
allocates resources across two periods of life, and the solution yields
the Euler equation, the consumption function, and the principle of
Fisherian separation.  **Part II** extends the framework to include a
labor-leisure choice, introducing Cobb-Douglas preferences over
consumption and leisure and confronting the theory with the empirical
puzzle of the intertemporal elasticity of labor supply.

The treatment follows {cite}`fisherInterestTheory` for the basic
framework, {cite}`samuelson1937note` for time-separable utility,
{cite}`summersCapTax` for the decomposition of interest rate effects,
{cite}`kpr:prodn` for the choice of preferences consistent with
balanced growth, and {cite}`rameyFrancisLeisure` for long-run evidence
on leisure.

```{code-cell} ipython3
import numpy as np
from scipy import optimize
import matplotlib.pyplot as plt
import sympy as sp
import pandas as pd
```

```{code-cell} ipython3
from collections import namedtuple

FisherModel = namedtuple('FisherModel', ['b1', 'y1', 'y2', 'R', 'beta', 'rho'])
LaborModel = namedtuple('LaborModel', ['R', 'beta', 'eta_s', 'W1', 'W2'])
```

# Part I: The Fisher Two-Period Problem

## Budget Constraints and Human Wealth

A consumer lives for two periods.  In period 1 the consumer begins
with bank balances $b_1$ and earns income $y_1$.  Total resources are
split between consumption $c_1$ and end-of-period assets $a_1$:

```{math}
:label: dbc_young

c_1 + a_1 = b_1 + y_1
```

Assets earn a gross interest factor $\mathsf{R} = 1 + r$, so
beginning-of-period-2 resources are $b_2 = \mathsf{R} \, a_1$.
In the last period of life, the consumer spends everything:
$c_2 = b_2 + y_2$.
Since $u'(c) > 0$ for all $c > 0$, an additional unit of consumption always raises utility.  It follows that the consumer exhausts all resources in the final period and both budget constraints bind at the optimum.  The IBC therefore holds with equality.

Combining the two period budget constraints gives the
**intertemporal budget constraint** (IBC):

```{math}
:label: ibc_two_period

c_1 + c_2 / \mathsf{R} = b_1 + y_1 + y_2 / \mathsf{R}
```

The right-hand side is total wealth.  It is convenient to define
**human wealth** as the present discounted value of labor income:

```{math}
:label: human_wealth_def

h_1 = y_1 + y_2 / \mathsf{R}
```

so total wealth is $b_1 + h_1$.

```{code-cell} ipython3
def human_wealth(y1, y2, R):
    """Present discounted value of labor income."""
    return y1 + y2 / R


def budget_set(b1, y1, y2, R, n_points=200):
    """Return (c1, c2) pairs on the intertemporal budget line."""
    total_wealth = b1 + human_wealth(y1, y2, R)
    c1 = np.linspace(0, total_wealth, n_points)
    c2 = (total_wealth - c1) * R
    return c1, c2
```

## Optimization and the Euler Equation

The consumer maximizes lifetime utility

```{math}
:label: lifetime_util

u(c_1) + \beta \, u(c_2)
```

subject to the IBC, where $\beta \in (0,1)$ is the discount factor.
The Lagrangian is

$$
\mathcal{L} = u(c_1) + \beta\,u(c_2) + \lambda\bigl(b_1 + h_1 - c_1 - c_2/\mathsf{R}\bigr)
$$

The first-order conditions $\partial\mathcal{L}/\partial c_1 = 0$ and $\partial\mathcal{L}/\partial c_2 = 0$ yield $u'(c_1) = \lambda$ and $\beta\,u'(c_2) = \lambda/\mathsf{R}$.  Eliminating $\lambda$ produces the
**Euler equation**:

```{math}
:label: euler_eq

u'(c_1) = \mathsf{R} \, \beta \, u'(c_2)
```

The left side is the marginal utility cost of saving one more unit
today.  The right side is the discounted marginal utility benefit of
consuming the gross return $\mathsf{R}$ tomorrow.  At the optimum,
the consumer is indifferent at the margin between consuming today and
saving for tomorrow.

::::{tip}
**Perturbation argument.**  Suppose $c_1^*$, $c_2^*$ solve the
problem.  Reduce period-1 consumption by $\epsilon$ and raise
period-2 consumption by $\mathsf{R}\epsilon$.  The utility change is

$$
-u'(c_1^*)\,\epsilon + \beta\,u'(c_2^*)\,\mathsf{R}\,\epsilon
$$

At the optimum this must be zero for all $\epsilon$, giving the Euler
equation.
::::

```{code-cell} ipython3
# Symbolic derivation of the Euler equation
c1, c2, lam, R_s, beta_s, rho_s = sp.symbols(
    'c_1 c_2 lambda R beta rho', positive=True
)
b1_s, h1_s = sp.symbols('b_1 h_1', positive=True)

# Lagrangian
L = sp.Function('u')(c1) + beta_s * sp.Function('u')(c2) + lam * (b1_s + h1_s - c1 - c2 / R_s)

# First-order conditions
foc1 = sp.diff(L, c1)   # u'(c1) - lambda = 0
foc2 = sp.diff(L, c2)   # beta*u'(c2) - lambda/R = 0
display(sp.Eq(foc1, 0), sp.Eq(foc2, 0))

# CRRA specialization: u(c) = c^(1-rho)/(1-rho)
u_crra = lambda c: c ** (1 - rho_s) / (1 - rho_s)
euler_crra = sp.Eq(c1 ** (-rho_s), R_s * beta_s * c2 ** (-rho_s))
growth = sp.solve(euler_crra, c2)[0] / c1
display(sp.Eq(c2 / c1, sp.simplify(growth)))

# Limit as rho -> 1 (log utility)
log_limit = sp.limit(R_s ** (-1) * (R_s * beta_s) ** (1 / rho_s), rho_s, 1)
print("lim_{rho->1} R^{-1}(R*beta)^{1/rho} =", log_limit)
```

## CRRA Utility

We specialize to **constant relative risk aversion** (CRRA) utility:

```{math}
:label: crra_utility

u(c) = \frac{c^{1-\rho}}{1-\rho}
```

with marginal utility $u'(c) = c^{-\rho}$.  Substituting into the
Euler equation:

```{math}
:label: crra_euler

c_2 / c_1 = (\mathsf{R}\,\beta)^{1/\rho}
```

The parameter $1/\rho$ is the **intertemporal elasticity of
substitution** (IES): it measures the percent change in the
consumption ratio $c_2/c_1$ in response to a percent change in the
intertemporal price $\mathsf{R}$.

## The Consumption Function

Using the Euler equation to substitute $c_2$ in the IBC and solving
for $c_1$:

```{math}
:label: consumption_function

c_1 = \frac{b_1 + h_1}{1 + \mathsf{R}^{-1}(\mathsf{R}\,\beta)^{1/\rho}}
```

This is the **consumption function**: it maps total wealth and
parameters to the optimal level of first-period consumption.

```{code-cell} ipython3
def consumption_growth(R, beta, rho):
    """Optimal ratio c2/c1 from the Euler equation with CRRA utility."""
    return (R * beta) ** (1 / rho)


def consumption_function(b1, h1, R, beta, rho):
    """Optimal c1 from the two-period CRRA consumption problem."""
    g = consumption_growth(R, beta, rho)
    return (b1 + h1) / (1 + g / R)


def solve_two_period(b1, y1, y2, R, beta, rho):
    """Solve the two-period problem; return c1, c2, a1."""
    h1 = human_wealth(y1, y2, R)
    c1 = consumption_function(b1, h1, R, beta, rho)
    a1 = b1 + y1 - c1
    c2 = R * a1 + y2
    return c1, c2, a1
```

## Fisherian Separation

A striking property of the solution is **Fisherian separation**: the
*growth rate* of consumption $c_2/c_1 = (\mathsf{R}\beta)^{1/\rho}$
depends only on $\mathsf{R}$, $\beta$, and $\rho$, not on the
timing of income.  Two consumers with the same total wealth but
different income profiles $(y_1, y_2)$ will choose the same
consumption levels.

```{code-cell} ipython3
model = FisherModel(b1=0, y1=100, y2=0, R=1.04, beta=0.96, rho=2.0)
R, beta, rho = model.R, model.beta, model.rho

# Three income profiles with identical total wealth
profiles = [
    {"label": "All income in period 1", "b1": 0, "y1": 100, "y2": 0},
    {"label": "Equal income",           "b1": 0, "y1": 50,  "y2": 52},
    {"label": "All income in period 2", "b1": 0, "y1": 0,   "y2": 104},
]

rows = []
for p in profiles:
    h1 = human_wealth(p["y1"], p["y2"], R)
    c1, c2, a1 = solve_two_period(p["b1"], p["y1"], p["y2"], R, beta, rho)
    rows.append({"Profile": p["label"], "c1": c1, "c2": c2, "a1": a1, "h1": h1})
pd.DataFrame(rows).set_index("Profile").round(3)
```

All three profiles yield the same $c_1$, $c_2$, confirming Fisherian
separation.

## Log Utility Special Case

When $\rho = 1$, CRRA utility reduces to $u(c) = \log c$.  The
consumption function simplifies to

```{math}
:label: log_consumption_fn

c_1 = \frac{b_1 + h_1}{1 + \beta}
```

which is independent of the interest rate $\mathsf{R}$.  This happens
because with log utility the income and substitution effects of a
change in $\mathsf{R}$ exactly offset each other.
This simplification follows from the general formula by taking $\rho \to 1$, since $\lim_{\rho \to 1} \mathsf{R}^{-1}(\mathsf{R}\beta)^{1/\rho} = \beta$.

```{code-cell} ipython3
# Verify the log-utility formula
b1, y1, y2 = 0, 80, 40
R_test = 1.05
h1 = human_wealth(y1, y2, R_test)

c1_formula = (b1 + h1) / (1 + beta)
c1_general = consumption_function(b1, h1, R_test, beta, rho=1.0)

print(f"Log-utility formula: c1 = {c1_formula:.6f}")
print(f"General formula:     c1 = {c1_general:.6f}")
```

## Fisher Diagram

The classic Fisher diagram plots the budget constraint in
$(c_1, c_2)$ space together with indifference curves.  We reproduce
the analysis for two cases: income concentrated in period 1 (saver)
and income concentrated in period 2 (borrower).

```{code-cell} ipython3
def indifference_curve(c1_grid, c_ref1, c_ref2, beta, rho):
    """Compute c2 on the indifference curve through (c_ref1, c_ref2)."""
    if rho == 1.0:
        target = np.log(c_ref1) + beta * np.log(c_ref2)
        c2 = np.exp((target - np.log(c1_grid)) / beta)
    else:
        u = lambda c: c ** (1 - rho) / (1 - rho)
        target = u(c_ref1) + beta * u(c_ref2)
        c2 = np.empty_like(c1_grid)
        for i, c1v in enumerate(c1_grid):
            residual = target - u(c1v)
            try:
                c2[i] = optimize.brentq(
                    lambda c: u(c) * beta - residual, 1e-10, c_ref2 * 20
                )
            except ValueError:
                c2[i] = np.nan
    return c2


def fisher_diagram(b1, y1, y2, R_low, R_high, beta, rho, title=""):
    """Plot the Fisher diagram with two interest rates."""
    fig, ax = plt.subplots(figsize=(7, 7))

    # Budget lines
    for R_val, ls, lbl in [(R_low, '-', f'$\\mathsf{{R}} = {R_low}$'),
                           (R_high, '--', f'$\\mathsf{{R}} = {R_high}$')]:
        c1_line, c2_line = budget_set(b1, y1, y2, R_val)
        ax.plot(c1_line, c2_line, 'k', ls=ls, lw=1.5, label=lbl)

    # Optimal points
    c1_A, c2_A, _ = solve_two_period(b1, y1, y2, R_low, beta, rho)
    c1_C, c2_C, _ = solve_two_period(b1, y1, y2, R_high, beta, rho)

    # Indifference curves
    c1_grid = np.linspace(0.01, (b1 + human_wealth(y1, y2, R_high)) * 1.1, 500)
    ic_A = indifference_curve(c1_grid, c1_A, c2_A, beta, rho)
    ic_C = indifference_curve(c1_grid, c1_C, c2_C, beta, rho)

    ax.plot(c1_grid, ic_A, 'b-', lw=1, alpha=0.6)
    ax.plot(c1_grid, ic_C, 'r-', lw=1, alpha=0.6)

    ax.plot(c1_A, c2_A, 'bo', ms=9, zorder=5, label=f'A  ($c_1={c1_A:.1f}$)')
    ax.plot(c1_C, c2_C, 'rs', ms=9, zorder=5, label=f'C  ($c_1={c1_C:.1f}$)')

    # Endowment point
    ax.plot(b1 + y1, y2, 'k^', ms=10, zorder=5, label='Endowment')

    ymax = max(c2_A, c2_C, y2) * 1.3
    xmax = (b1 + human_wealth(y1, y2, R_low)) * 1.1
    ax.set_xlim(0, xmax)
    ax.set_ylim(0, ymax)
    ax.set_xlabel('$c_1$')
    ax.set_ylabel('$c_2$')
    ax.legend(frameon=False, fontsize=9)
    ax.grid(True, alpha=0.3)
    if title:
        ax.set_title(title)
    plt.show()
```

### Case 1: Income in Period 1 (Saver)

When all income arrives in period 1, the consumer saves part of it.
An increase in $\mathsf{R}$ is unambiguously beneficial: the
consumption possibility set expands.

```{code-cell} ipython3
fisher_diagram(b1=0, y1=100, y2=0, R_low=1.02, R_high=1.10,
               beta=0.96, rho=2.0,
               title="Income in period 1 (saver)")
```

### Case 2: Income in Period 2 (Borrower)

When income is concentrated in period 2, the consumer must borrow.
An increase in $\mathsf{R}$ is unambiguously harmful: the available
consumption set shrinks.

```{code-cell} ipython3
fisher_diagram(b1=0, y1=0, y2=104, R_low=1.02, R_high=1.10,
               beta=0.96, rho=2.0,
               title="Income in period 2 (borrower)")
```

Following {cite}`summersCapTax`, the effect of a change in
$\mathsf{R}$ on first-period consumption can be decomposed into three
components:

1. **Substitution effect**: a higher $\mathsf{R}$ makes future
   consumption cheaper, encouraging the consumer to shift spending
   toward period 2 ($c_1$ falls).
2. **Income effect**: a higher $\mathsf{R}$ makes savers richer,
   enabling more consumption in both periods ($c_1$ rises for savers).
3. **Human wealth effect**: a higher $\mathsf{R}$ reduces the
   present value of future income $h_1$ ($c_1$ falls for anyone with
   $y_2 > 0$).

For most consumers, future labor income is the largest component of
wealth, so the human wealth effect typically dominates.

## Comparative Statics

How do $c_1$, $c_2$, and savings $a_1$ respond to changes in the
interest rate?  The answer depends critically on $\rho$.

```{code-cell} ipython3
b1, y1, y2, beta = 0, 80, 40, 0.96
R_grid = np.linspace(1.0, 1.15, 200)
rho_values = [0.5, 1.0, 2.0, 5.0]

fig, axes = plt.subplots(1, 3, figsize=(14, 4.5))
for rho_val in rho_values:
    results = np.array([solve_two_period(b1, y1, y2, R_val, beta, rho_val)
                        for R_val in R_grid])
    axes[0].plot(R_grid, results[:, 0], lw=2, label=rf'$\rho = {rho_val}$')
    axes[1].plot(R_grid, results[:, 1], lw=2)
    axes[2].plot(R_grid, results[:, 2], lw=2)

titles = ['$c_1$', '$c_2$', '$a_1 = b_1 + y_1 - c_1$']
for ax, t in zip(axes, titles):
    ax.set_xlabel(r'$\mathsf{R}$')
    ax.set_ylabel(t)
    ax.grid(True, alpha=0.3)
axes[0].legend(frameon=False, fontsize=9)
fig.tight_layout()
plt.show()
```

When $\rho$ is small (high IES), the substitution effect dominates:
$c_1$ falls sharply as $\mathsf{R}$ rises.  When $\rho$ is large
(low IES), income and human wealth effects dominate: $c_1$ is
relatively insensitive to $\mathsf{R}$, or may even increase.

# Part II: Consumption and Labor Supply

## Intratemporal Choice

Now suppose the consumer also chooses how much to work.  Utility
depends on consumption $c_t$ and leisure $z_t$:

```{math}
:label: util_cz

u(c_t, z_t)
```

Time is normalized so that $\ell_t + z_t = 1$, where $\ell_t$ is
labor supply.  The wage per unit of labor is $\mathsf{W}_t$, so
labor income is $\mathsf{W}_t \ell_t = \mathsf{W}_t(1 - z_t)$.

Given total expenditure $x_t$ in period $t$, the static budget
constraint is

```{math}
:label: static_budget

x_t = c_t + \mathsf{W}_t \, z_t
```

The price of leisure is the wage $\mathsf{W}_t$: each unit of
leisure costs the consumer $\mathsf{W}_t$ in foregone earnings.
The first-order condition for the optimal leisure choice is

```{math}
:label: foc_leisure

\mathsf{W}_t = \frac{u_z}{u_c}
```

The wage equals the marginal rate of substitution between leisure
and consumption.

## Cobb-Douglas Preferences

Assume an "outer" utility function $f(\cdot)$ that depends on a
Cobb-Douglas aggregate of consumption and leisure:

```{math}
:label: cobb_douglas_pref

u(c_t, z_t) = f\!\left(c_t^{1-\eta_s}\,z_t^{\eta_s}\right)
```

where $\eta_s \in (0,1)$ is the leisure share.  Define
$\eta = \eta_s / (1 - \eta_s)$.  Substituting $c_t = x_t - \mathsf{W}_t z_t$ into the Cobb-Douglas composite and differentiating with respect to $z_t$, the first-order condition equates $(1-\eta_s)\mathsf{W}_t\,c_t^{-\eta_s}\,z_t^{\eta_s}$ with $\eta_s\,c_t^{1-\eta_s}\,z_t^{\eta_s - 1}$.  Simplifying yields

```{math}
:label: cobb_douglas_foc

\mathsf{W}_t \, z_t = \eta \, c_t
```

```{code-cell} ipython3
# Symbolic derivation: Cobb-Douglas FOC => W*z = eta*c
c_s, z_s, W_s, eta_s_sym = sp.symbols('c z W eta_s', positive=True)
eta_sym = eta_s_sym / (1 - eta_s_sym)
x_s = c_s + W_s * z_s  # total expenditure

# Cobb-Douglas composite
composite = c_s ** (1 - eta_s_sym) * z_s ** eta_s_sym

# Differentiate composite w.r.t. z, set MRS = W
MU_z = sp.diff(composite, z_s)
MU_c = sp.diff(composite, c_s)
foc_ratio = sp.simplify(MU_z / MU_c)
display(sp.Eq(W_s, foc_ratio))

# Solve for W*z in terms of c
sol = sp.solve(sp.Eq(W_s, foc_ratio), W_s * z_s)
display(sp.Eq(W_s * z_s, sp.simplify(eta_s_sym / (1 - eta_s_sym) * c_s)))
```

Spending on leisure is a constant fraction $\eta$ of consumption
spending.  Substituting back, utility becomes
$f((\mathsf{W}_t/\eta)^{-\eta_s}\,c_t)$.

## Constant Leisure Share

The Cobb-Douglas specification implies that the fraction of time
spent in leisure does not depend on the level of wages.  To see
this, consider a single-period model where the budget constraint is
$\mathsf{W}_t = c_t + \mathsf{W}_t z_t$.  Then $c_t = \mathsf{W}_t / (1 + \eta)$
and $z_t = \eta / (1 + \eta)$, a constant.

This is the key reason for adopting Cobb-Douglas inner preferences:
{cite}`rameyFrancisLeisure` document that the fraction of time
Americans spend working has changed little over a century of rising
wages.  {cite}`kpr:prodn` show that other functional forms would
produce counterfactual trends in leisure.

```{code-cell} ipython3
eta_s = 0.4   # leisure share parameter
eta = eta_s / (1 - eta_s)

W_grid = np.linspace(5, 50, 200)
z_star = eta / (1 + eta)
c_star = W_grid / (1 + eta)

fig, axes = plt.subplots(1, 2, figsize=(12, 4.5))

axes[0].plot(W_grid, c_star, lw=2, color='steelblue')
axes[0].set_xlabel(r'Wage $\mathsf{W}$')
axes[0].set_ylabel('$c$')
axes[0].set_title('Consumption rises with wages')
axes[0].grid(True, alpha=0.3)

axes[1].axhline(z_star, lw=2, color='indianred',
                label=rf'$z = \eta/(1+\eta) = {z_star:.3f}$')
axes[1].set_xlabel(r'Wage $\mathsf{W}$')
axes[1].set_ylabel('$z$ (leisure)')
axes[1].set_title('Leisure is constant')
axes[1].set_ylim(0, 1)
axes[1].legend(frameon=False)
axes[1].grid(True, alpha=0.3)

fig.tight_layout()
plt.show()
```

## Two-Period Lifetime with Labor

Now embed the intratemporal choice in a two-period lifetime.  The
consumer maximizes

```{math}
:label: lifetime_labor

u(c_1, z_1) + \beta \, u(c_2, z_2)
```

subject to the lifetime budget constraint

$$
c_2 = (\mathsf{W}_1(1 - z_1) - c_1)\,\mathsf{R}
      + \mathsf{W}_2(1 - z_2)
$$

With the CRRA outer function $f(\chi) = \chi^{1-\rho}/(1-\rho)$ and
Cobb-Douglas inner preferences, the Euler equation for consumption
becomes

```{math}
:label: euler_labor

\frac{c_2}{c_1} = (\mathsf{R}\,\beta)^{1/\rho}
  \left(\frac{\mathsf{W}_2}{\mathsf{W}_1}\right)^{-\eta_s(1-\rho)/\rho}
```

Consumption growth depends not only on $\mathsf{R}\beta$ but also on
wage growth $\mathsf{W}_2/\mathsf{W}_1$.
To derive this expression, note that the Cobb-Douglas utility simplification gives $(\mathsf{W}_1/\eta)^{-\eta_s} c_1^{-\rho}$ as the marginal utility of $c_1$.  The Euler equation is $(\mathsf{W}_1/\eta)^{-\eta_s} c_1^{-\rho} = \mathsf{R}\beta\,(\mathsf{W}_2/\eta)^{-\eta_s} c_2^{-\rho}$.  Rearranging for $c_2/c_1$ yields [](#euler_labor).

## Log Utility and Labor Supply

With log utility ($\rho = 1$), the wage-growth term in
[](#euler_labor) vanishes and $c_2/c_1 = \mathsf{R}\beta$
regardless of wage growth.  This is Fisherian separation for the
consumption profile.

Using $\mathsf{W}_t z_t = \eta\,c_t$, the leisure profile satisfies

```{math}
:label: leisure_profile

\frac{1 - \ell_2}{1 - \ell_1}
= \frac{z_2}{z_1}
= \mathsf{R}\,\beta\,\frac{\mathsf{W}_1}{\mathsf{W}_2}
```

Leisure in period 2 relative to period 1 falls when wages grow
($\mathsf{W}_2 > \mathsf{W}_1$), meaning labor supply $\ell$
rises.  Intuitively, you work harder when work pays better.

```{code-cell} ipython3
def labor_supply_log(ell1, R, beta, W1, W2):
    """Period-2 labor supply under log utility given period-1 labor supply."""
    z1 = 1 - ell1
    z2 = z1 * R * beta * W1 / W2
    return np.clip(1 - z2, 0, 1)  # bound labor supply to [0, 1]


# Baseline: R*beta = 1, W2/W1 = 1 => ell2 = ell1
labor_model = LaborModel(R=1.04, beta=1 / 1.04, eta_s=0.4, W1=1.0, W2=1.0)
ell1 = 0.5
R, beta = labor_model.R, labor_model.beta

Wgrowth_grid = np.linspace(1.0, 4.0, 200)
ell2_vals = np.array([labor_supply_log(ell1, R, beta, 1.0, Wg)
                       for Wg in Wgrowth_grid])

fig, ax = plt.subplots(figsize=(7, 4.5))
ax.plot(Wgrowth_grid, ell2_vals, lw=2, color='steelblue',
        label=r'$\ell_2$')
ax.axhline(ell1, ls='--', color='gray', alpha=0.6, label=r'$\ell_1 = 0.5$')
ax.set_xlabel(r'Wage growth $\mathsf{W}_2 / \mathsf{W}_1$')
ax.set_ylabel('Labor supply')
ax.legend(frameon=False)
ax.grid(True, alpha=0.3)
ax.set_title(r'Period-2 labor supply vs wage growth ($\mathsf{R}\beta=1$)')
plt.show()
```

## The Intertemporal Elasticity of Labor Supply Puzzle

Assume $\mathsf{R}\beta = 1$ and $\ell_1 = 1/2$.  Under log
utility, equation [](#leisure_profile) with
$\mathsf{W}_2/\mathsf{W}_1 = \Gamma$ gives

```{math}
:label: ell2_formula

\ell_2 = 1 - \frac{1 - \ell_1}{\Gamma}
= 1 - \frac{1}{2\,\Gamma}
```

Empirically, wages in the U.S. grow by a factor of $\Gamma \approx 2$
to $4$ between youth and middle age (depending on occupation and
education), yet labor supply is roughly constant across these ages.

```{code-cell} ipython3
ell1 = 0.5

rows = []
for Gamma in [1.0, 1.5, 2.0, 3.0, 4.0]:
    ell2 = 1 - 0.5 / Gamma
    rows.append({"Gamma (wage growth)": Gamma, "ell2 (theory)": ell2, "ell1": ell1, "Delta ell": ell2 - ell1})
pd.DataFrame(rows).set_index("Gamma (wage growth)").round(3)
```

With $\Gamma = 2$, the theory predicts $\ell_2 = 0.75$, meaning workers
spend 75% of their time working in middle age, compared to 50% in
youth.  With $\Gamma = 3$, the prediction is $\ell_2 = 0.833$.
These predictions are far from the data: labor supply varies little
with age despite large predictable changes in wages.

### Variation Across Occupations

Suppose aggregate wage growth is $\Gamma = 2$ and we set
$\mathsf{R}\beta / \Gamma = 1$ (so $\mathsf{R}\beta = 2$) to match
the fact that *average* consumption doubles.  For occupation $i$ with
relative wage growth $\Gamma_i$, the effective wage growth is
$\Gamma \cdot \Gamma_i$ and

```{math}
:label: leisure_occ

(1 - \ell_2)\,\Gamma_i = 1 - \ell_1
```

```{code-cell} ipython3
ell1 = 0.5
Gamma_values = [0.5, 0.75, 1.0, 1.25, 1.5]
labels = ["Manual laborer", "Service worker", "Average",
          "Professional", "Doctor/Lawyer"]

rows = []
for label, Gi in zip(labels, Gamma_values):
    z2 = (1 - ell1) / Gi
    ell2 = 1 - z2
    rows.append({"Occupation": label, "Gamma_i": Gi, "ell2": round(ell2, 3) if ell2 > 0 else "<= 0 (!)"})
pd.DataFrame(rows).set_index("Occupation")
```

For manual laborers ($\Gamma_i = 0.5$), the theory predicts
$\ell_2 = 0$: they would stop working entirely in middle age.  For
doctors ($\Gamma_i = 1.5$), $\ell_2 = 2/3$: they would work much
harder.  In reality, labor supply varies little across occupations
at any given age.

This is the **intertemporal elasticity of labor supply puzzle**: the
theory with log utility (IES = 1) predicts enormous variation in
labor supply in response to predictable wage variation, while the
data show very little.

```{code-cell} ipython3
fig, ax = plt.subplots(figsize=(8, 5))

Gamma_i_grid = np.linspace(0.3, 2.0, 200)
ell2_theory = 1 - (1 - ell1) / Gamma_i_grid

ax.plot(Gamma_i_grid, ell2_theory, lw=2, color='steelblue',
        label=r'Theory: $\ell_2 = 1 - (1-\ell_1)/\Gamma_i$')
ax.axhline(ell1, ls='--', color='gray', alpha=0.6,
           label=r'$\ell_1 = 0.5$')
ax.axhline(ell1, ls=':', lw=3, color='indianred', alpha=0.5,
           label=r'Data: $\ell_2 \approx \ell_1$ (stylized)')

# Mark specific occupations
for Gi, lbl in [(0.5, 'Manual'), (1.0, 'Average'), (1.5, 'Doctor')]:
    ell2_pt = 1 - (1 - ell1) / Gi
    ax.plot(Gi, ell2_pt, 'ko', ms=7, zorder=5)
    ax.annotate(lbl, (Gi, ell2_pt), textcoords="offset points",
                xytext=(8, -12), fontsize=9)

ax.set_xlabel(r'Occupation-specific wage growth factor $\Gamma_i$')
ax.set_ylabel(r'Period-2 labor supply $\ell_2$')
ax.set_ylim(-0.1, 1.1)
ax.legend(frameon=False, fontsize=9, loc='lower right')
ax.grid(True, alpha=0.3)
ax.set_title('Intertemporal Elasticity of Labor Supply Puzzle')
plt.show()
```

## Exercises

```{exercise}
:label: ex_crra_growth

Using the CRRA Euler equation [](#crra_euler), plot $c_2/c_1$ as a
function of $\mathsf{R}$ for $\rho \in \{0.5, 1, 2, 5\}$ with
$\beta = 0.96$.  For which values of $\rho$ does a 1% increase in
$\mathsf{R}$ lead to the largest change in consumption growth?
Explain using the concept of the IES.
```

```{solution-start} ex_crra_growth
:class: dropdown
```

```{code-cell} ipython3
beta = 0.96
R_grid = np.linspace(0.98, 1.15, 200)

fig, ax = plt.subplots(figsize=(7, 5))
for rho_val in [0.5, 1.0, 2.0, 5.0]:
    growth = (R_grid * beta) ** (1 / rho_val)
    ax.plot(R_grid, growth, lw=2, label=rf'$\rho = {rho_val}$ (IES $= {1/rho_val:.1f}$)')

ax.set_xlabel(r'$\mathsf{R}$')
ax.set_ylabel(r'$c_2 / c_1$')
ax.legend(frameon=False, fontsize=9)
ax.grid(True, alpha=0.3)
ax.set_title('Consumption growth vs interest rate')
plt.show()
```

Lower $\rho$ means a higher IES ($1/\rho$), so consumption growth
responds more elastically to $\mathsf{R}$.  With $\rho = 0.5$
(IES = 2), a 1% increase in $\mathsf{R}$ raises $c_2/c_1$ by about
2%.  With $\rho = 5$ (IES = 0.2), the same 1% increase raises
$c_2/c_1$ by only 0.2%.

```{solution-end}
```

```{exercise}
:label: ex_fisherian_numerical

Verify Fisherian separation numerically.  Fix $\mathsf{R} = 1.04$,
$\beta = 0.96$, $\rho = 2$, and total wealth $b_1 + h_1 = 100$.
Vary the income split $(y_1, y_2)$ while keeping $b_1 = 0$ and
$y_1 + y_2/\mathsf{R} = 100$ fixed.  Show that $c_1$ is the same in
all cases.
```

```{solution-start} ex_fisherian_numerical
:class: dropdown
```

```{code-cell} ipython3
R, beta, rho = 1.04, 0.96, 2.0
total_h = 100.0

y1_grid = np.linspace(0, total_h, 11)
y2_grid = (total_h - y1_grid) * R

fig, ax = plt.subplots(figsize=(7, 4.5))
c1_vals = []
for y1v, y2v in zip(y1_grid, y2_grid):
    c1v, _, _ = solve_two_period(0, y1v, y2v, R, beta, rho)
    c1_vals.append(c1v)

ax.plot(y1_grid, c1_vals, 'o-', lw=2, ms=6)
ax.set_xlabel('$y_1$')
ax.set_ylabel('$c_1$')
ax.set_title(f'$c_1$ is constant at {c1_vals[0]:.4f} regardless of income timing')
ax.grid(True, alpha=0.3)
plt.show()
```

All points lie on a horizontal line, confirming that $c_1$ depends
only on total wealth $b_1 + h_1$, not on the income split.

```{solution-end}
```

```{exercise}
:label: ex_labor_supply_table

Using the labor supply formula [](#ell2_formula) with
$\ell_1 = 0.5$ and $\mathsf{R}\beta = 1$, compute $\ell_2$ for
wage growth factors $\Gamma \in \{1, 1.5, 2, 3, 4\}$.  For which
value of $\Gamma$ does the theory most dramatically contradict the
empirical evidence?
```

```{solution-start} ex_labor_supply_table
:class: dropdown
```

```{code-cell} ipython3
ell1 = 0.5

fig, ax = plt.subplots(figsize=(7, 5))
Gamma_vals = [1.0, 1.5, 2.0, 3.0, 4.0]
ell2_vals = [1 - 0.5 / G for G in Gamma_vals]

bars = ax.bar([f'$\\Gamma = {G}$' for G in Gamma_vals], ell2_vals,
              color=['#2196F3', '#4CAF50', '#FF9800', '#F44336', '#9C27B0'],
              width=0.5)
ax.axhline(ell1, ls='--', color='k', alpha=0.5, label=r'$\ell_1 = 0.5$')

for bar, v in zip(bars, ell2_vals):
    ax.text(bar.get_x() + bar.get_width() / 2, v + 0.02,
            f'{v:.3f}', ha='center', fontsize=10)

ax.set_ylabel(r'$\ell_2$')
ax.set_ylim(0, 1.05)
ax.legend(frameon=False)
ax.grid(True, alpha=0.3, axis='y')
ax.set_title('Predicted period-2 labor supply')
plt.tight_layout()
plt.show()
```

The contradiction grows with $\Gamma$.  At $\Gamma = 4$, the model
predicts $\ell_2 = 0.875$, meaning the consumer works 87.5% of
available time, a dramatic increase from 50% in youth.  Empirically,
labor supply barely changes.  This illustrates the intertemporal
elasticity of labor supply puzzle: the model's implied elasticity far
exceeds what is observed.

```{solution-end}
```

```{exercise}
:label: ex_occupation_variation

Assume $\ell_1 = 0.5$, $\mathsf{R}\beta/\Gamma = 1$ (where
$\Gamma = 2$ is average wage growth), and consider five occupations
with $\Gamma_i \in \{0.5, 0.75, 1.0, 1.25, 1.5\}$.  From equation
[](#leisure_occ), compute $\ell_2$ for each occupation.  Plot the
results and discuss whether the predicted cross-occupation variation
in middle-age labor supply is realistic.
```

```{solution-start} ex_occupation_variation
:class: dropdown
```

```{code-cell} ipython3
ell1 = 0.5
Gamma_i_vals = [0.5, 0.75, 1.0, 1.25, 1.5]
occ_labels = ["Manual\nlaborer", "Service\nworker", "Average",
              "Professional", "Doctor/\nLawyer"]

ell2_occ = [max(1 - (1 - ell1) / Gi, 0) for Gi in Gamma_i_vals]

fig, ax = plt.subplots(figsize=(8, 5))
colors = ['#F44336', '#FF9800', '#4CAF50', '#2196F3', '#9C27B0']
bars = ax.bar(occ_labels, ell2_occ, color=colors, width=0.5)
ax.axhline(ell1, ls='--', color='k', alpha=0.5,
           label=r'$\ell_1 = 0.5$ (all occupations)')

for bar, v in zip(bars, ell2_occ):
    ax.text(bar.get_x() + bar.get_width() / 2, v + 0.02,
            f'{v:.2f}', ha='center', fontsize=10)

ax.set_ylabel(r'$\ell_2$ (middle age)')
ax.set_ylim(0, 1.05)
ax.legend(frameon=False, fontsize=9)
ax.grid(True, alpha=0.3, axis='y')
ax.set_title(r'Cross-occupation variation in middle-age labor supply ($\Gamma = 2$)')
plt.tight_layout()
plt.show()
```

The model predicts enormous cross-occupation variation: manual
laborers ($\Gamma_i = 0.5$) would work 0% of the time in middle
age, while doctors ($\Gamma_i = 1.5$) would work 67%.  In reality,
labor supply at any given age varies little across occupations.
This is further evidence that the log-utility model's implied
intertemporal elasticity of labor supply is far too large.

```{solution-end}
```
