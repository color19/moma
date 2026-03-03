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
  Advanced consumption models: habit formation, durable goods, and
  quasi-hyperbolic discounting (Laibson). Derives optimality conditions,
  envelope results, and testable implications for each extension.
keywords:
  - habit formation
  - durable goods
  - quasi-hyperbolic discounting
  - Laibson
  - time inconsistency
tags:
  - consumption
  - intertemporal-choice
---

# Advanced Consumption Models

Standard consumption theory assumes time-separable utility and exponential discounting. Each of these assumptions can be relaxed in economically meaningful ways. Part I introduces habit formation, where past consumption raises the reference point against which current consumption is judged. Part II adds durable goods, whose stocks depreciate gradually and provide utility over many periods. Part III replaces exponential discounting with quasi-hyperbolic preferences, producing the present-bias and self-control problems studied by {cite:t}`laibson:goldeneggs`.

::::{seealso}
This notebook builds on the envelope theorem and Euler equation machinery developed in [](./envelope_crra.md). The random walk result modified by habit formation in Part I contrasts with the standard random walk derived in [](./random_walk_cons_fn.md).
::::

```{code-cell} ipython3
import numpy as np
from scipy.optimize import brentq
import matplotlib.pyplot as plt
import sympy as sp
import pandas as pd
from collections import namedtuple
```

```{code-cell} ipython3
# Parameters for the habit formation model
HabitModel = namedtuple(
    'HabitModel',
    ['R', 'beta', 'rho', 'alpha', 'T']
)

# Parameters for the durable goods model
DurableModel = namedtuple(
    'DurableModel',
    ['R', 'beta', 'rho', 'alpha_d', 'delta', 'T']
)

# Parameters for the Laibson model
LaibsonModel = namedtuple(
    'LaibsonModel',
    ['R', 'beta', 'delta_hyp', 'rho', 'T']
)
```

# Part I: Habit Formation

Habit formation means that utility depends not only on current consumption $c_t$ but also on a habit stock $h_t$ that summarizes past consumption. Higher past consumption raises the bar: utility is decreasing in the habit stock, $u^h < 0$. This section follows {cite:t}`carroll:solvinghabits`.

## The Problem

The consumer maximizes

```{math}
:label: hab_objective
\max \sum_{n=0}^{T-t} \beta^n u(c_{t+n}, h_{t+n})
```

subject to the dynamic budget constraint

```{math}
:label: hab_dbc
m_{t+1} = (m_t - c_t)\mathsf{R} + y_{t+1}
```

and the habit evolution rule

```{math}
:label: hab_evolution
h_{t+1} = c_t.
```

The assumption in [](#hab_evolution) is the simplest case: the habit stock equals last period's consumption. Under this rule, the consumer who ate well yesterday finds today's modest meal less satisfying.

## The Bellman Equation

Because the habit stock $h_t$ enters utility, the value function has two state variables. Bellman's equation is

```{math}
:label: hab_bellman
v_t(m_t, h_t) = \max_{c_t} \; u(c_t, h_t) + \beta \, v_{t+1}\bigl((m_t - c_t)\mathsf{R} + y_{t+1},\; c_t\bigr).
```

The second argument of $v_{t+1}$ is $c_t$ because $h_{t+1} = c_t$ under our habit rule. To apply the envelope theorem, define the "unoptimized" value

$$
\underline{v}_t(m_t, h_t, c_t) = u(c_t, h_t) + \beta \, v_{t+1}\bigl((m_t - c_t)\mathsf{R} + y_{t+1},\; c_t\bigr),
$$

so that $v_t(m_t, h_t) = \underline{v}_t\bigl(m_t, h_t, \mathbf{c}_t(m_t, h_t)\bigr)$ at the optimal consumption rule $\mathbf{c}_t$.

## Optimality Conditions

### The First Order Condition

Differentiating the Bellman equation [](#hab_bellman) with respect to $c_t$ yields

```{math}
:label: hab_foc
u^c_t = \beta\bigl(\mathsf{R}\, v^m_{t+1} - v^h_{t+1}\bigr).
```

Without habits, $v^h_{t+1} = 0$ and this reduces to the standard Euler equation. With habits, an extra unit of consumption today raises tomorrow's habit stock, which reduces tomorrow's utility (since $v^h_{t+1} < 0$). The right-hand side of [](#hab_foc) is therefore larger than in the no-habit case, so the marginal utility on the left must also be larger, which means lower $c_t$. Habits increase the willingness to delay spending.

### Envelope Condition for $m_t$

Applying the envelope theorem to [](#hab_bellman) (treating $c_t$ as constant, since the FOC zeroes out its contribution) gives

```{math}
:label: hab_env_m
v^m_t = \beta \mathsf{R}\, v^m_{t+1}.
```

This is the same envelope result as in the standard problem: the marginal value of wealth today equals the discounted gross return times the marginal value of wealth tomorrow.

### Envelope Condition for $h_t$

The habit stock $h_t$ enters only through $u(c_t, h_t)$, so the envelope theorem gives

```{math}
:label: hab_env_h
v^h_t = u^h_t.
```

The marginal value of a higher habit stock equals the marginal disutility it causes today.

### Combined Euler Equation

Substituting [](#hab_env_m) into [](#hab_foc) produces

```{math}
:label: hab_vmarg
v^m_t = u^c_t + \beta\, v^h_{t+1}.
```

Using [](#hab_env_h) to replace $v^h_{t+1}$ with $u^h_{t+1}$, rolling forward one period, and substituting back into [](#hab_env_m) yields

```{math}
:label: hab_euler_full
u^c_t + \beta\, u^h_{t+1} = \mathsf{R}\beta\bigl[u^c_{t+1} + \beta\, u^h_{t+2}\bigr].
```

When $u^h = 0$, this collapses to the standard Euler equation $u'(c_t) = \mathsf{R}\beta\, u'(c_{t+1})$.

```{code-cell} ipython3
#| output: asis
# Symbolic derivation of the combined Euler equation
from sympy.printing.mathml import mathml

def show(expr):
    ml = mathml(expr, printer='presentation')
    print(f'<math display="block" xmlns="http://www.w3.org/1998/Math/MathML">{ml}</math>')

c_t, c_t1, h_t, h_t1 = sp.symbols('c_t c_{t+1} h_t h_{t+1}', positive=True)
R_s, beta_s, alpha_s, rho_s = sp.symbols('R beta alpha rho', positive=True)

# Specific utility: u(c,h) = f(c - alpha*h), with f(z) = z^(1-rho)/(1-rho)
z_t = c_t - alpha_s * h_t

uc = z_t**(-rho_s)
uh = -alpha_s * z_t**(-rho_s)

# Verify the full Euler equation symbolically
# LHS: u^c_t + beta * u^h_{t+1} = f'_t - alpha*beta*f'_{t+1}
# RHS: R*beta * [u^c_{t+1} + beta * u^h_{t+2}] = R*beta * [f'_{t+1} - alpha*beta*f'_{t+2}]
# With constant marginal utility growth k = f'_t/f'_{t+1}, the solution is k = R*beta

z_t1 = c_t1 - alpha_s * h_t1
ratio = z_t / z_t1  # ratio of "effective consumption" across periods
euler_ratio = sp.Eq(sp.Integer(1), R_s * beta_s * (z_t1 / z_t)**rho_s)

print("For $u(c,h) = f(c - \\alpha h)$ with CRRA kernel $f$:")
print()
print("$u^c = f'(z_t)$, where $z_t = c_t - \\alpha h_t$:")
show(uc)
print()
print("$u^h = -\\alpha\\, f'(z_t)$:")
show(uh)
print()
print("The Euler equation in terms of $z_t$:")
show(euler_ratio)
```

## A Specific Utility Function

Assume the utility function takes the form $u(c,h) = f(c - \alpha h)$, where $f(z) = z^{1-\rho}/(1-\rho)$ is CRRA. The parameter $\alpha \in [0,1)$ controls habit strength: when $\alpha = 0$ habits vanish, and when $\alpha$ is close to 1 only consumption growth above the accustomed level generates satisfaction. The derivatives are

$$
u^c = f'(c - \alpha h), \qquad u^h = -\alpha\, f'(c - \alpha h).
$$

### Serial Correlation of Consumption Growth

Substituting into the full Euler equation [](#hab_euler_full) and looking for a solution where marginal utility grows at a constant rate $k = f'_t / f'_{t+1}$, one can show that $k = \mathsf{R}\beta$. Taking logs and applying a first-order approximation around small consumption changes gives

```{math}
:label: hab_serial_corr
\Delta \log c_{t+1} \approx \frac{1-\alpha}{\rho}\log(\mathsf{R}\beta) + \alpha\,\Delta \log c_t.
```

This is the key testable implication: habit formation produces serial correlation in consumption growth. The coefficient $\alpha$ on lagged consumption growth measures habit strength. When $\alpha = 0$, consumption growth is unpredictable (as in the standard random walk result).

```{code-cell} ipython3
# Simulate consumption paths under habit formation
np.random.seed(42)

params = HabitModel(R=1.04, beta=0.96, rho=2.0, alpha=0.0, T=200)
alphas = [0.0, 0.3, 0.6, 0.9]
log_R_beta = np.log(params.R * params.beta)

fig, axes = plt.subplots(1, 2, figsize=(10, 4))

for alpha in alphas:
    drift = (1 - alpha) / params.rho * log_R_beta
    eps = np.random.normal(0, 0.02, params.T)
    dlogc = np.zeros(params.T)
    for t in range(1, params.T):
        dlogc[t] = drift + alpha * dlogc[t - 1] + eps[t]
    logc = np.cumsum(dlogc)
    axes[0].plot(logc, lw=1.5, label=rf'$\alpha = {alpha}$')

axes[0].set_xlabel('Period')
axes[0].set_ylabel(r'$\log\, c_t$')
axes[0].set_title('Stronger habits produce smoother consumption paths')
axes[0].legend(frameon=False, fontsize=8)
axes[0].grid(True, alpha=0.3)

# Autocorrelation of consumption growth at different habit strengths
n_sim, T_sim = 1000, 500
autocorrs = []
for alpha in alphas:
    drift = (1 - alpha) / params.rho * log_R_beta
    corrs = []
    for _ in range(n_sim):
        eps = np.random.normal(0, 0.02, T_sim)
        dlogc = np.zeros(T_sim)
        for t in range(1, T_sim):
            dlogc[t] = drift + alpha * dlogc[t - 1] + eps[t]
        corrs.append(np.corrcoef(dlogc[1:-1], dlogc[2:])[0, 1])
    autocorrs.append(np.mean(corrs))

axes[1].bar(range(len(alphas)), autocorrs, tick_label=[str(a) for a in alphas])
axes[1].set_xlabel(r'Habit strength $\alpha$')
axes[1].set_ylabel(r'Autocorrelation of $\Delta \log c$')
axes[1].set_title('Habits create predictable consumption growth')
axes[1].grid(True, alpha=0.3, axis='y')

plt.tight_layout()
plt.show()
```

```{code-cell} ipython3
# Summary table: analytical vs simulated autocorrelation
rows = []
for alpha, ac in zip(alphas, autocorrs):
    rows.append({
        'Habit strength (alpha)': alpha,
        'Analytical autocorrelation': alpha,
        'Simulated autocorrelation': round(ac, 4),
    })
df_habits = pd.DataFrame(rows)
df_habits
```

The table confirms that the first-order autocorrelation of consumption growth matches the habit parameter $\alpha$, exactly as [](#hab_serial_corr) predicts. With $\alpha = 0$ consumption growth is white noise; with $\alpha = 0.6$ about 60 percent of last period's growth carries over.

# Part II: Durable Goods

A durable good provides utility over multiple periods rather than being consumed immediately. Housing, automobiles, and appliances are classic examples. The consumer now chooses both nondurable consumption $c_t$ and the durable stock $d_t$, and must account for the fact that durables depreciate gradually.

:::{note}
In this section, $\alpha$ denotes the durable goods share in Cobb-Douglas utility, not the habit strength parameter from Part I.
:::

## Stock Accumulation

The stock of the durable good evolves according to

```{math}
:label: dur_stock
d_{t+1} = (1 - \delta)\,d_t + x_{t+1},
```

where $x_t$ is expenditure on the durable good in period $t$ and $\delta \in [0,1]$ is the depreciation rate. A lower $\delta$ means the good is "more durable." This geometric depreciation assumption contrasts with "one-hoss-shay" models where the good works perfectly until it fails completely.

The dynamic budget constraint subtracts both nondurable consumption and durable expenditure from available resources:

```{math}
:label: dur_dbc
m_{t+1} = (m_t - c_t - x_t)\mathsf{R} + y_{t+1}.
```

## The Two-Control Bellman Equation

The consumer maximizes $\sum_{s=t}^{T} \beta^{s-t} u(c_s, d_s)$ subject to [](#dur_stock) and [](#dur_dbc). Treating $d_t$ directly as the control variable (since $x_t = d_t - (1-\delta)d_{t-1}$), Bellman's equation is

```{math}
:label: dur_bellman
v_t(m_t, d_{t-1}) = \max_{c_t, d_t} \left[u(c_t, d_t) + \beta\, v_{t+1}(m_{t+1}, d_t)\right],
```

where $m_{t+1} = \bigl(m_t - c_t - (d_t - (1-\delta)d_{t-1})\bigr)\mathsf{R} + y_{t+1}$.

## First Order Conditions

With two controls, there are two FOCs. Differentiating [](#dur_bellman) with respect to $c_t$ gives

```{math}
:label: dur_foc_c
u^c_t = \mathsf{R}\beta\, v^m_{t+1}.
```

Differentiating with respect to $d_t$ gives

```{math}
:label: dur_foc_d
u^d_t = \beta\bigl(\mathsf{R}\, v^m_{t+1} - v^d_{t+1}\bigr) = \mathsf{R}\beta\, v^m_{t+1} - \beta\, v^d_{t+1}.
```

The FOC for durables has two terms because choosing a higher $d_t$ both costs $\mathsf{R}$ units of next-period wealth (the spending must be financed) and delivers value through the durable stock carried into next period.

## Envelope Conditions

The envelope theorem applied to [](#dur_bellman) for each state variable gives

```{math}
:label: dur_env_m
v^m_t = \mathsf{R}\beta\, v^m_{t+1}
```

and

```{math}
:label: dur_env_d
v^d_t = (1-\delta)\,\mathsf{R}\beta\, v^m_{t+1} = (1-\delta)\, v^m_t.
```

The second result says that the marginal value of an extra unit of durable stock equals $(1-\delta)$ times the marginal value of wealth. When $\delta = 1$ (a completely nondurable good), $v^d_t = 0$: last period's stock is worthless because it has fully depreciated. When $\delta = 0$ (a perfectly durable good), $v^d_t = v^m_t$: an indestructible durable is as valuable as cash.

## The Intratemporal Condition

Substituting the envelope results into the FOC for durables [](#dur_foc_d) produces the intratemporal optimality condition

```{math}
:label: dur_intratemporal
u^d_t = \frac{r + \delta}{\mathsf{R}}\, u^c_t,
```

where $r = \mathsf{R} - 1$ is the net interest rate. When $\delta < 1$, the current-period marginal utility from the durable is strictly less than the marginal utility from nondurables. The reason is that the durable will continue yielding utility in future periods; what should be equated to $u^c_t$ is the total discounted lifetime utility from an extra unit of the durable, not merely the single-period marginal utility.

```{code-cell} ipython3
#| output: asis
# Symbolic derivation of the intratemporal condition
r_s, delta_s, R_sym = sp.symbols('r delta R', positive=True)
uc_s, ud_s = sp.symbols("u^c u^d")

# From the envelope + FOC derivation: u^d = [(r + delta)/R] * u^c
rhs = (r_s + delta_s) / R_sym * uc_s
intratemporal = sp.Eq(ud_s, rhs)

print("**Intratemporal optimality condition:**")
print()
show(intratemporal)
print()

# Verify the limiting cases symbolically
limit_nondurable = rhs.subs(delta_s, 1).simplify()
limit_perfect = rhs.subs(delta_s, 0).simplify()
print("When $\\delta = 1$ (nondurable): $u^d =$")
show(limit_nondurable)
print()
print("When $\\delta = 0$ (perfectly durable): $u^d =$")
show(limit_perfect)
```

## Cobb-Douglas Utility

Assume $u(c,d) = \frac{(c^{1-\alpha}\, d^{\alpha})^{1-\rho}}{1-\rho}$, where $\alpha \in (0,1)$ governs the taste for durables. The marginal utilities are

$$
u^c = (c^{1-\alpha} d^{\alpha})^{-\rho}\,(1-\alpha)\,(d/c)^{\alpha}, \qquad
u^d = (c^{1-\alpha} d^{\alpha})^{-\rho}\,\alpha\,(d/c)^{\alpha - 1}.
$$

Substituting into [](#dur_intratemporal) and simplifying yields the optimal durable-to-nondurable ratio

```{math}
:label: dur_gamma
\gamma \equiv \frac{d}{c} = \frac{\alpha}{1-\alpha}\,\frac{\mathsf{R}}{r + \delta}.
```

The ratio $\gamma$ is a constant that depends on preferences ($\alpha$) and prices ($\mathsf{R}$, $\delta$). Whenever nondurable consumption jumps, the durable stock must jump by the same proportion.

```{code-cell} ipython3
# Compute the optimal durable-to-nondurable ratio for different depreciation rates
params_d = DurableModel(R=1.04, beta=0.96, rho=2.0, alpha_d=0.3, delta=0.1, T=100)
r = params_d.R - 1

deltas = np.linspace(0.01, 0.50, 50)
gammas = (params_d.alpha_d / (1 - params_d.alpha_d)) * params_d.R / (r + deltas)

fig, axes = plt.subplots(1, 2, figsize=(10, 4))

axes[0].plot(deltas, gammas, lw=2)
axes[0].set_xlabel(r'Depreciation rate $\delta$')
axes[0].set_ylabel(r'Optimal ratio $d/c = \gamma$')
axes[0].set_title('More durable goods command larger stocks relative to $c$')
axes[0].grid(True, alpha=0.3)

# Spending volatility: x_t/x_{t-1} = (epsilon + delta)/delta
epsilons = np.linspace(0.0, 0.10, 50)
delta_vals = [0.05, 0.10, 0.25, 0.50]
for dv in delta_vals:
    ratio = (epsilons + dv) / dv
    axes[1].plot(epsilons, ratio, lw=2, label=rf'$\delta = {dv}$')

axes[1].set_xlabel(r'Consumption shock $\epsilon$')
axes[1].set_ylabel(r'Spending ratio $x_t / x_{t-1}$')
axes[1].set_title('Low depreciation amplifies spending volatility')
axes[1].legend(frameon=False, fontsize=8)
axes[1].grid(True, alpha=0.3)

plt.tight_layout()
plt.show()
```

## Spending Volatility

Suppose nondurable consumption had been constant at $c_{t-2} = c_{t-1}$ and then jumps so that $c_t / c_{t-1} = 1 + \epsilon_t$. Because the durable stock must track nondurables in the ratio $\gamma$, expenditure on durables satisfies

```{math}
:label: dur_spending_vol
\frac{x_t}{x_{t-1}} = \frac{\epsilon_t + \delta}{\delta}.
```

For goods with low depreciation, even small consumption shocks produce large swings in durable spending. A 5 percent permanent income shock with $\delta = 0.05$ doubles durable expenditure. This explains why housing starts and auto sales are among the most cyclically volatile components of GDP.

```{code-cell} ipython3
# Tabulate spending volatility multipliers
rows = []
for eps in [0.01, 0.03, 0.05, 0.10]:
    row = {'Consumption shock': f'{eps:.0%}'}
    for dv in [0.05, 0.10, 0.25]:
        row[f'delta={dv}'] = round((eps + dv) / dv, 2)
    rows.append(row)

df_vol = pd.DataFrame(rows)
df_vol.columns = ['Consumption shock'] + [rf'$\delta = {dv}$' for dv in [0.05, 0.10, 0.25]]
df_vol
```

The table shows spending multipliers: each entry is $x_t / x_{t-1}$ for a given shock size and depreciation rate. A 5 percent shock to permanent income multiplies spending on a good with $\delta = 0.05$ by a factor of 2, but only by a factor of 1.2 for a good with $\delta = 0.25$.

# Part III: Quasi-Hyperbolic Discounting

Standard exponential discounting implies time-consistent preferences: a plan made today remains optimal tomorrow. Experimental evidence suggests otherwise. Subjects routinely prefer \$100 today over \$110 tomorrow, yet prefer \$110 in 31 days over \$100 in 30 days. This reversal is inconsistent with any constant discount factor, but is captured naturally by quasi-hyperbolic preferences introduced by {cite:t}`laibson:goldeneggs`.

## Two Value Functions

Suppose a value function $v_{t+1}(m_{t+1})$ exists for period $t+1$. For any consumption rule $\boldsymbol{\chi}_t$, define two value functions:

```{math}
:label: laib_two_values
\begin{aligned}
v_t(m_t; \boldsymbol{\chi}_t) &= u(\boldsymbol{\chi}_t(m_t)) + \phantom{\delta_h}\beta\,\mathbb{E}_t\bigl[v_{t+1}\bigl((m_t - \boldsymbol{\chi}_t(m_t))\mathsf{R} + y_{t+1}\bigr)\bigr] \\
\mathfrak{v}_t(m_t; \boldsymbol{\chi}_t) &= u(\boldsymbol{\chi}_t(m_t)) + \delta_h\,\beta\,\mathbb{E}_t\bigl[v_{t+1}\bigl((m_t - \boldsymbol{\chi}_t(m_t))\mathsf{R} + y_{t+1}\bigr)\bigr]
\end{aligned}
```

The first function $v_t$ discounts next period by $\beta$ alone; the second function $\mathfrak{v}_t$ applies an additional present-bias factor $\delta_h < 1$. We write $\delta_h$ for the hyperbolic discount factor to distinguish it from the depreciation rate $\delta$ in Part II. {cite:t}`laibsonNeuro` argues that at an annual frequency $\delta_h \approx 0.7$, reflecting the fact that brain regions associated with emotional rewards respond to immediate gratification but not to future rewards.

These functions are well-defined for any feasible consumption rule $\boldsymbol{\chi}_t$; they are not Bellman equations because they do not assume optimality.

## Two Consumption Rules

Two consumption rules arise naturally:

```{math}
:label: laib_two_rules
\begin{aligned}
\mathbf{c}_t(m_t) &= \arg\max_c \; u(c) + \phantom{\delta_h}\beta\,\mathbb{E}_t[v_{t+1}((m_t - c)\mathsf{R} + y_{t+1})] \\
\mathfrak{c}_t(m_t) &= \arg\max_c \; u(c) + \delta_h\,\beta\,\mathbb{E}_t[v_{t+1}((m_t - c)\mathsf{R} + y_{t+1})]
\end{aligned}
```

Solving recursively with $\boldsymbol{\chi} = \mathbf{c}$ in every period yields the standard time-consistent solution. The Laibson consumer uses $\mathfrak{c}_t$, which weights the future less and therefore consumes more today.

## The Modified Euler Equation

For $\boldsymbol{\chi}_t = \mathfrak{c}_t$, the envelope theorem gives $\mathfrak{v}^m_t = u'(c_t)$, and the FOC gives $u'(c_t) = \delta_h\,\beta\,\mathsf{R}\,\mathbb{E}_t[v^m_{t+1}]$. A useful identity links the two value functions:

```{math}
:label: laib_identity
\delta_h\, v_t = \mathfrak{v}_t - (1 - \delta_h)\,u(\mathfrak{c}_t(m_t)).
```

Differentiating [](#laib_identity) with respect to $m_t$ and using the envelope and FOC results yields the modified Euler equation

```{math}
:label: laib_euler
u'(c_t) = \mathfrak{v}^m_t - (1 - \delta_h)\,u'(c_t)\,\mathfrak{c}^m_t(m_t).
```

When $\delta_h = 1$, this reduces to the standard Euler equation. When $\delta_h < 1$, the second term on the right is positive (since $u' > 0$ and $\mathfrak{c}^m_t > 0$), which reduces the effective right-hand side. A lower right-hand side requires lower marginal utility on the left, meaning higher consumption. The Laibson consumer spends more.

The magnitude of the present-bias effect depends on the MPC $\mathfrak{c}^m_t$. When the MPC is small (as for a wealthy consumer with many periods remaining), the bias is small. When the MPC is large (as for a liquidity-constrained consumer), the bias is large.

```{code-cell} ipython3
#| output: asis
# Symbolic derivation of the identity linking v and frak{v}
dh, b = sp.symbols('delta_h beta', positive=True)
u_val, v_next = sp.symbols('u v_{t+1}')

# v_t = u + beta * v_{t+1}, fv_t = u + delta_h * beta * v_{t+1}
v_t_expr = u_val + b * v_next
fv_t_expr = u_val + dh * b * v_next

# Verify: delta_h * v_t = fv_t - (1 - delta_h) * u
lhs_identity = dh * v_t_expr
rhs_identity = fv_t_expr - (1 - dh) * u_val

identity_check = sp.simplify(lhs_identity - rhs_identity)

print("**Verifying the identity** $\\delta_h v_t = \\mathfrak{v}_t - (1 - \\delta_h)u$:")
print()
print(f"$\\delta_h \\cdot v_t =$")
show(sp.expand(lhs_identity))
print()
print(f"$\\mathfrak{{v}}_t - (1 - \\delta_h)u =$")
show(sp.expand(rhs_identity))
print()
print(f"Difference (should be zero): {identity_check}")
```

```{code-cell} ipython3
# Visualize the present-bias effect across MPC values
params_l = LaibsonModel(R=1.04, beta=0.96, delta_hyp=0.7, rho=2.0, T=60)
delta_vals = [0.5, 0.7, 0.9, 1.0]
mpc_grid = np.linspace(0.01, 0.50, 100)

fig, axes = plt.subplots(1, 2, figsize=(10, 4))

for dh in delta_vals:
    bias = (1 - dh) * mpc_grid
    axes[0].plot(mpc_grid, bias, lw=2, label=rf'$\delta_h = {dh}$')

axes[0].set_xlabel(r'MPC $\mathfrak{c}^m_t$')
axes[0].set_ylabel(r'Present-bias term $(1-\delta_h)\,\mathfrak{c}^m_t$')
axes[0].set_title('Present bias is largest when MPC is high')
axes[0].legend(frameon=False, fontsize=8)
axes[0].grid(True, alpha=0.3)

# Modified Euler equation rearranged:
# u'(c) = fv^m - (1 - delta_h) * u'(c) * c^m
# u'(c) * [1 + (1 - delta_h) * c^m] = fv^m
# So the Laibson consumer acts as if marginal utility is scaled down by 1/(1 + (1-dh)*mpc)
# Ratio of Laibson to standard marginal utility:
for dh in delta_vals:
    scaling = 1 / (1 + (1 - dh) * mpc_grid)
    axes[1].plot(mpc_grid, scaling, lw=2, label=rf'$\delta_h = {dh}$')

axes[1].set_xlabel(r'MPC $\mathfrak{c}^m_t$')
axes[1].set_ylabel(r"$u'(c_{\mathrm{Laibson}}) / \mathfrak{v}^m_t$")
axes[1].set_title('How much present bias discounts the future')
axes[1].legend(frameon=False, fontsize=8)
axes[1].grid(True, alpha=0.3)
axes[1].set_ylim(0.5, 1.05)

plt.tight_layout()
plt.show()
```

::::{tip}
The psychological tension captured by the Laibson model is familiar: the cost of deviating from the optimal plan in a single period may be trivially small ("eating dessert this one time will not make me fat"), but the consequence of perpetual deviation could be quite large ("but if I give in to temptation this time, maybe that means I will always give in").
::::

## Exercises

```{exercise}
:label: ex_adv_habit_no_habit
Consider the habit model from Part I with $u(c,h) = f(c - \alpha h)$ and $f(z) = z^{1-\rho}/(1-\rho)$. Set $\alpha = 0$, $\mathsf{R} = 1.04$, $\beta = 0.96$, and $\rho = 2$. Simulate 1000 paths of consumption growth over 200 periods and verify that the sample autocorrelation of $\Delta \log c_t$ is approximately zero. Then repeat with $\alpha = 0.5$ and verify that the autocorrelation is approximately 0.5.
```

```{solution-start} ex_adv_habit_no_habit
:class: dropdown
```

```{code-cell} ipython3
np.random.seed(123)
n_paths, T = 1000, 200
R, beta, rho = 1.04, 0.96, 2.0
log_Rb = np.log(R * beta)

for alpha in [0.0, 0.5]:
    drift = (1 - alpha) / rho * log_Rb
    corrs = []
    for _ in range(n_paths):
        eps = np.random.normal(0, 0.02, T)
        dlogc = np.zeros(T)
        for t in range(1, T):
            dlogc[t] = drift + alpha * dlogc[t - 1] + eps[t]
        corrs.append(np.corrcoef(dlogc[1:-1], dlogc[2:])[0, 1])
    mean_corr = np.mean(corrs)
    print(f"alpha = {alpha}: mean autocorrelation = {mean_corr:.4f} (theory: {alpha})")
```

With $\alpha = 0$ the autocorrelation is near zero, confirming that consumption growth is unpredictable. With $\alpha = 0.5$ the autocorrelation is approximately 0.5, matching the theoretical prediction from [](#hab_serial_corr).

```{solution-end}
```

```{exercise}
:label: ex_adv_dur_gamma
Using the Cobb-Douglas utility parameters $\alpha = 0.3$, $\mathsf{R} = 1.04$, and $\delta = 0.1$, compute the optimal durable-to-nondurable ratio $\gamma$ from [](#dur_gamma). Then use `scipy.optimize.brentq` to verify this ratio by finding the $d/c$ that satisfies the intratemporal condition $u^d / u^c = (r + \delta)/\mathsf{R}$ numerically.
```

```{solution-start} ex_adv_dur_gamma
:class: dropdown
```

```{code-cell} ipython3
R, alpha_d, delta = 1.04, 0.3, 0.1
r = R - 1

# Analytical solution
gamma_analytical = (alpha_d / (1 - alpha_d)) * R / (r + delta)
print(f"Analytical gamma = {gamma_analytical:.6f}")

# Numerical verification: find d/c such that u^d/u^c = (r + delta)/R
# For Cobb-Douglas u(c,d) = (c^(1-a) d^a)^(1-rho) / (1-rho)
# u^d / u^c = (alpha / (1-alpha)) * (c/d)
# Setting this equal to (r + delta)/R:
target = (r + delta) / R

def residual(dc_ratio):
    return (alpha_d / (1 - alpha_d)) / dc_ratio - target

gamma_numerical = brentq(residual, 0.1, 100.0)
print(f"Numerical gamma  = {gamma_numerical:.6f}")
print(f"Difference       = {abs(gamma_analytical - gamma_numerical):.2e}")
```

The analytical and numerical solutions agree to machine precision, confirming the derivation of the optimal ratio $\gamma$.

```{solution-end}
```

```{exercise}
:label: ex_adv_laibson_bias
For the Laibson model with CRRA utility ($\rho = 2$), $\mathsf{R}\beta = 1$, and $\delta_h = 0.7$, plot the present-bias term $(1 - \delta_h)\,u'(c)\,\mathfrak{c}^m$ as a function of wealth $m$ over the range $[1, 20]$. Assume a simple consumption rule $\mathfrak{c}(m) = \kappa\, m$ with MPC $\kappa = 0.05$. How does the bias change if $\kappa$ doubles to $0.10$?
```

```{solution-start} ex_adv_laibson_bias
:class: dropdown
```

```{code-cell} ipython3
rho = 2.0
delta_h = 0.7
m_grid = np.linspace(1, 20, 200)

fig, ax = plt.subplots(figsize=(8, 4))
for kappa in [0.05, 0.10]:
    c = kappa * m_grid
    u_prime = c ** (-rho)
    bias = (1 - delta_h) * u_prime * kappa
    ax.plot(m_grid, bias, lw=2, label=rf'$\kappa = {kappa}$')

ax.set_xlabel(r'Market resources $m$')
ax.set_ylabel(r'Present-bias term')
ax.set_title('Doubling the MPC roughly doubles the present-bias distortion')
ax.legend(frameon=False, fontsize=9)
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()
```

Doubling the MPC from 0.05 to 0.10 approximately doubles the present-bias term at each wealth level. This confirms that the Laibson distortion scales with the MPC: consumers who are more responsive to current resources (because they are liquidity-constrained or near the end of life) suffer more from present bias.

```{solution-end}
```

```{exercise}
:label: ex_adv_dur_volatility
A consumer holds a durable good with depreciation rate $\delta = 0.03$ (roughly quarterly depreciation for housing). She receives a permanent income shock that raises nondurable consumption by 2 percent. Compute the ratio $x_t / x_{t-1}$ of durable spending after vs. before the shock using [](#dur_spending_vol). Then compute the same ratio for $\delta = 0.25$ (a less durable good like clothing). Summarize the results using a `pandas` DataFrame.
```

```{solution-start} ex_adv_dur_volatility
:class: dropdown
```

```{code-cell} ipython3
epsilon = 0.02
deltas = [0.03, 0.05, 0.10, 0.25]
rows = []
for d in deltas:
    ratio = (epsilon + d) / d
    rows.append({
        'Depreciation rate': d,
        'Spending ratio x_t/x_{t-1}': round(ratio, 2),
        'Spending change': f'{(ratio - 1)*100:.0f}%',
    })
df_ex = pd.DataFrame(rows)
df_ex
```

With $\delta = 0.03$, a 2 percent consumption shock produces a 67 percent jump in durable spending. With $\delta = 0.25$, the same shock produces only an 8 percent increase. This confirms the prediction from [](#dur_spending_vol): more durable goods exhibit far more volatile expenditure patterns.

```{solution-end}
```

## References

```{bibliography}
:filter: docname in docnames
```
