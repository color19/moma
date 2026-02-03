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
  The Diamond overlapping generations model with population growth:
  competitive equilibrium, the social planner's problem, the Golden Rule,
  and dynamic efficiency.
keywords:
  - OLG
  - overlapping generations
  - Diamond model
  - population growth
  - dynamic efficiency
  - Golden Rule
  - social planner
tags:
  - olg
  - nonlinear
---

# The Diamond OLG Model

How do the savings decisions of one generation affect the capital stock
and welfare of future generations?  This is the central question of the
overlapping generations (OLG) model introduced by
{cite}`diamond:olg`, building on the pure-exchange framework of
{cite}`samuelson1958exact`.

In an infinite-horizon representative agent model, a single
household lives forever and internalizes the effect of its savings on
future capital.  In the OLG model, by contrast, each household lives
for only two periods.  Young households save for retirement, and
their collective savings become the capital stock available to the
next generation.  Because no single household lives long enough to
account for the entire future path of capital, the competitive
equilibrium need not be efficient.

In this lecture we develop the two-period Diamond OLG model from first
principles.  We derive the competitive equilibrium, characterize the
social planner's solution, define the Golden Rule, and show how
these three benchmarks relate to one another.  Along the way we
introduce the concept of dynamic efficiency and explain why the
first welfare theorem can fail in an OLG economy.

:::{seealso}
The individual consumption-savings problem that underlies each
household's decision is developed in
[Two-Period Consumption and Labor Supply](./consumption_two_period.md).
This notebook embeds that decision in a general equilibrium with
production and capital accumulation.
:::

We use a per-generation calibration in which each model period
represents roughly 30 years.  The baseline parameters are
$\varepsilon = 0.33$ (capital share), $\beta = 0.96$ (household
discount factor), $N = 2.5$ (gross population growth, corresponding
to approximately 3% annual growth compounded over 30 years), and
$\beth = 0.99$ (social planner discount factor).

:::{note}
A per-generation discount factor of $\beta = 0.96$ is *not* the same
as an annual discount factor of 0.96.  The annual equivalent is
$\beta^{1/30} \approx 0.9986$, corresponding to an annual discount
rate of roughly 0.14%.  Similarly, $N = 2.5$ means the population
roughly triples each 30-year generation, well above modern
developed-country growth rates.  These values are chosen for
pedagogical clarity; the qualitative results hold for a wide range of
calibrations.
:::

```{code-cell} ipython3
import numpy as np
from scipy import optimize
import matplotlib.pyplot as plt
import sympy as sp
import pandas as pd
```

```{code-cell} ipython3
from collections import namedtuple

OLGModel = namedtuple('OLGModel', ['epsilon', 'beta', 'N', 'beth'])
```

## Model Setup

### Demographics and Timing

Time is discrete, indexed by $t = 0, 1, 2, \ldots$.  Each individual
lives for two periods: young (period $t$) and old (period $t+1$).
The population of young agents in period $t$ is

```{math}
:label: population_growth

\mathcal{N}_t = \mathcal{N}_0 \, N^t
```

where $N = 1 + n > 1$ is the gross population growth factor and
$n > 0$ is the net growth rate.  In each period the economy contains
$\mathcal{N}_t$ young agents and $\mathcal{N}_{t-1}$ old agents.

### Endowments and Technology

Young agents supply one unit of labor inelastically and earn a wage.
Old agents do not work, so their only source of income is the return
on savings accumulated when young.  We write $Y_{1,t}$ for the income
of a young agent and set $Y_{2,t+1} = 0$.

There are no bequests, so each generation starts with zero financial
wealth.  Total savings of the young generation at $t$ fund the capital
stock at $t+1$:

```{math}
:label: capital_accumulation

K_{t+1} = \mathcal{N}_t \, a_{1,t}
```

where $a_{1,t}$ denotes the assets (savings) of a representative
young agent after consumption.

A representative firm operates a constant-returns-to-scale production
function $F(K, \mathcal{N})$.  By Euler's theorem for homogeneous
functions, output equals the sum of factor payments:

```{math}
:label: production_crs

F(K_t, \mathcal{N}_t) = F_K \, K_t + F_{\mathcal{N}} \, \mathcal{N}_t
```

We assume no depreciation of capital within a generation.

### Per-Capita Variables and Factor Prices

It is convenient to express all quantities in per-young-worker terms.
Define the capital-labor ratio $k_t = K_t / \mathcal{N}_t$ and the
per-worker production function

```{math}
:label: per_capita_production

f(k) = F(k, 1)
```

Under competitive factor markets, each input is paid its marginal
product.  The wage equals the marginal product of labor and the
gross interest rate equals the marginal product of capital:

```{math}
:label: factor_prices

W_t = f(k_t) - k_t \, f'(k_t),
\qquad
R_t = f'(k_t)
```

We adopt a Cobb-Douglas specification $f(k) = k^\varepsilon$ with
$\varepsilon \in (0,1)$ representing the capital share.  Factor
prices then take the form

```{math}
:label: cobb_douglas_prices

W_t = (1 - \varepsilon) \, k_t^\varepsilon,
\qquad
R_t = \varepsilon \, k_t^{\varepsilon - 1}
```

```{code-cell} ipython3
def wage(k, epsilon):
    """Cobb-Douglas wage: marginal product of labor."""
    return (1 - epsilon) * k**epsilon

def interest_rate(k, epsilon):
    """Cobb-Douglas gross interest rate: marginal product of capital."""
    return epsilon * k**(epsilon - 1)
```

## Household Optimization

### Preferences and Budget Constraints

A household born at date $t$ has preferences over consumption when
young, $c_{1,t}$, and consumption when old, $c_{2,t+1}$.  We
represent these preferences with the lifetime utility function

```{math}
:label: lifetime_utility

v_t = u(c_{1,t}) + \beta \, u(c_{2,t+1})
```

where $u$ is a strictly increasing, strictly concave flow utility
function and $\beta \in (0,1)$ is the discount factor.

The household faces two budget constraints.  When young, labor income
$W_t$ is split between consumption and savings:

```{math}
:label: budget_young

c_{1,t} + a_{1,t} \leq W_t
```

When old, consumption is financed entirely by the gross return on
savings:

```{math}
:label: budget_old

c_{2,t+1} \leq R_{t+1} \, a_{1,t}
```

Since $u$ is strictly increasing, both constraints bind at the
optimum.

### The Euler Equation

Substituting the binding budget constraints into the lifetime
utility function and taking the first-order condition with respect
to $a_{1,t}$ yields the Euler equation:

```{math}
:label: euler_equation

u'(c_{1,t}) = \beta \, R_{t+1} \, u'(c_{2,t+1})
```

The left side is the marginal utility cost of saving one additional
unit when young.  The right side is the discounted marginal utility
benefit of consuming the gross return $R_{t+1}$ when old.  At the
optimum the household is indifferent between consuming a little more
today and saving a little more for tomorrow.

### Log Utility

We specialize to the case $u(c) = \log c$.  The Euler equation
becomes $1/c_{1,t} = \beta \, R_{t+1} / c_{2,t+1}$.  Substituting
the budget constraints and solving for consumption when young:

```{math}
:label: log_consumption

c_{1,t} = \frac{W_t}{1 + \beta}
```

Savings are whatever is left from the wage:

```{math}
:label: log_savings

a_{1,t} = \frac{\beta}{1 + \beta} \, W_t
```

A useful feature of log utility is that savings depend only on the
wage and the discount factor, not on the interest rate.  This occurs
because the income and substitution effects of a change in $R_{t+1}$
exactly offset each other.

:::{tip}
The interest-rate independence of savings under log utility is the
reason this specification is so widely used in OLG models.  It makes
the law of motion for capital a simple function of the current capital
stock alone, yielding closed-form steady states and clean comparative
statics.  With general CRRA preferences, the law of motion becomes an
implicit equation that must be solved numerically (see
[CRRA Preferences](#crra-preferences) below).
:::

```{code-cell} ipython3
def savings_log(W, beta):
    """Optimal savings under log utility."""
    return beta / (1 + beta) * W
```

## Competitive Equilibrium

### Law of Motion for Capital

In equilibrium, next period's capital stock equals total savings of
the current young generation.  Dividing
[the capital accumulation equation](#capital_accumulation) by
$\mathcal{N}_{t+1}$ gives the per-young-worker capital stock:

```{math}
:label: per_capita_capital

k_{t+1} = \frac{a_{1,t}}{N}
```

Each unit of individual savings is spread across $N$ new workers.
Substituting [the savings function](#log_savings) and
[the wage equation](#cobb_douglas_prices) into this expression:

```{math}
:label: law_of_motion

k_{t+1}
= \underbrace{\frac{(1 - \varepsilon) \, \beta}{N \, (1 + \beta)}}_{\equiv\;\mathcal{Q}}
\cdot k_t^\varepsilon
```

The coefficient $\mathcal{Q}$ summarizes how technology
($\varepsilon$), patience ($\beta$), and population growth ($N$)
interact to determine capital accumulation.  Higher population
growth lowers $\mathcal{Q}$ because each generation's savings must
be spread more thinly.

The derivative of the law of motion is

$$
\frac{dk_{t+1}}{dk_t} = \varepsilon \, \mathcal{Q} \, k_t^{\varepsilon - 1}
$$

Because $\varepsilon < 1$, the map $k_t \mapsto k_{t+1}$ is concave,
which guarantees a unique positive steady state and global convergence
from any positive initial condition.

```{code-cell} ipython3
def Q_coefficient(epsilon, beta, N):
    """Coefficient in the law of motion for capital."""
    return (1 - epsilon) * beta / (N * (1 + beta))

def k_next(k, epsilon, beta, N):
    """One-period law of motion for capital per young worker."""
    return Q_coefficient(epsilon, beta, N) * k**epsilon
```

### Steady State

Setting $k_{t+1} = k_t = \bar{k}$ in [the law of motion](#law_of_motion)
and solving:

```{math}
:label: steady_state_competitive

\bar{k} = \mathcal{Q}^{1/(1 - \varepsilon)}
```

Once we know $\bar{k}$ we can recover the steady-state wage
$\bar{W} = (1 - \varepsilon) \, \bar{k}^\varepsilon$, the gross
interest rate $\bar{R} = \varepsilon \, \bar{k}^{\varepsilon - 1}$,
and consumption in each period of life.

```{code-cell} ipython3
def steady_state_competitive(epsilon, beta, N):
    """Steady-state capital in the competitive equilibrium."""
    Q = Q_coefficient(epsilon, beta, N)
    return Q**(1 / (1 - epsilon))
```

We can verify the steady-state formula symbolically.  Setting
$k_{t+1} = k_t = \bar{k}$ in [the law of motion](#law_of_motion)
gives $\bar{k} = \mathcal{Q}\,\bar{k}^\varepsilon$.  Solving for
$\bar{k}$:

```{code-cell} ipython3
k_sym, Q_sym, eps_sym = sp.symbols('k Q varepsilon', positive=True)

# Steady-state condition: k = Q * k^epsilon
ss_eq = sp.Eq(k_sym, Q_sym * k_sym**eps_sym)
k_star_symbolic = sp.solve(ss_eq, k_sym)
display(sp.Eq(sp.Symbol(r'\bar{k}'), k_star_symbolic[0]))
```

### Phase Diagram and Convergence

The 45-degree diagram below plots $k_{t+1} = \mathcal{Q} \, k_t^\varepsilon$
against the identity line.  The unique intersection at $\bar{k}$
is the steady state.  Because the law of motion is concave and
passes through the origin, any positive initial capital stock
converges monotonically to $\bar{k}$.

```{code-cell} ipython3
model = OLGModel(epsilon=0.33, beta=0.96, N=2.5, beth=0.99)
epsilon, beta, N = model.epsilon, model.beta, model.N

k_bar = steady_state_competitive(epsilon, beta, N)
k_grid = np.linspace(0, 0.15, 300)
k_grid_next = k_next(k_grid, epsilon, beta, N)

fig, ax = plt.subplots(figsize=(6, 6))
ax.plot(k_grid, k_grid_next, lw=2, label=r'$k_{t+1} = \mathcal{Q}\,k_t^\varepsilon$')
ax.plot(k_grid, k_grid, 'k-', lw=1, alpha=0.7, label=r'$45^\circ$ line')
ax.plot(k_bar, k_bar, 'ro', ms=8, zorder=5,
        label=rf'$\bar{{k}} = {k_bar:.4f}$')
ax.set_xlabel('$k_t$')
ax.set_ylabel('$k_{t+1}$')
ax.legend(frameon=False)
ax.set_xlim(0, 0.15)
ax.set_ylim(0, 0.15)
ax.grid(True, alpha=0.3)
plt.show()
```

### Time Series

The following figure simulates capital from three different initial
conditions, confirming convergence to $\bar{k}$ (dashed line).

```{code-cell} ipython3
T = 30
k0_values = [0.005, 0.05, 0.12]

fig, ax = plt.subplots()
for k0 in k0_values:
    k_series = np.empty(T)
    k_series[0] = k0
    for t in range(T - 1):
        k_series[t + 1] = k_next(k_series[t], epsilon, beta, N)
    ax.plot(k_series, '-o', ms=3, lw=1.5, label=rf'$k_0 = {k0}$')

ax.axhline(k_bar, ls='--', color='k', alpha=0.5, label=rf'$\bar{{k}} = {k_bar:.4f}$')
ax.set_xlabel('$t$')
ax.set_ylabel('$k_t$')
ax.legend()
ax.grid(True, alpha=0.3)
plt.show()
```

### Comparative Statics

Higher population growth lowers the steady-state capital stock
because savings are diluted across more workers.  The figure below
plots $\bar{k}$ against $N$ for the baseline calibration.

```{code-cell} ipython3
N_vals = np.linspace(1.0, 4.0, 300)
k_ss_vals = np.array([steady_state_competitive(epsilon, beta, Nv) for Nv in N_vals])

fig, ax = plt.subplots()
ax.plot(N_vals, k_ss_vals, 'r-', lw=2, label=r'$\bar{k}$ vs $N$')
ax.axvline(N, ls=':', color='gray', alpha=0.5)
ax.set_xlabel(r'Population growth factor $N$')
ax.set_ylabel(r'Steady-state capital $\bar{k}$')
ax.grid(True, alpha=0.3)
plt.show()
```

## The Social Planner's Problem

So far we have characterized the competitive equilibrium, describing
what happens when households and firms optimize independently.
We now turn to a normative question: what should happen?  In
particular, is the competitive equilibrium efficient?

In many standard macroeconomic models, the first welfare theorem
guarantees that competitive equilibria are Pareto efficient.
The OLG model is a notable exception.  Because new agents are born
every period, the economy has a countable infinity of agents, and
the standard proof of the first welfare theorem breaks down.  To
evaluate efficiency we need to solve the social planner's problem
and compare its solution with the competitive outcome.

### Social Welfare and the Resource Constraint

Let $v_t = u(c_{1,t}) + \beta \, u(c_{2,t+1})$ denote the lifetime
utility of the generation born at $t$.  The social planner maximizes

```{math}
:label: social_welfare

V_t = \beta \, u(c_{2,t}) + \sum_{s=0}^{\infty} \beth^s \, v_{t+s}
```

where $\beth$ (the Hebrew letter beth) is the rate at which the
planner discounts the welfare of future generations.[^time-consistency]

[^time-consistency]: The term $\beta \, u(c_{2,t})$ gives weight to
the old generation already alive at date $t$.  Multiplying by
$\beta$ rather than some other constant prevents the social
planner's problem from exhibiting time inconsistency.  See
{cite}`blanchard&fischer:text`, Chapter 3, for the derivation.

The planner faces an aggregate resource constraint.  Total output
plus the existing capital stock must cover next period's capital,
consumption of the young, and consumption of the old:

```{math}
:label: aggregate_resource_constraint

\underbrace{K_t + F(K_t, \mathcal{N}_t)}_{\text{sources}}
= \underbrace{K_{t+1} + \mathcal{N}_t \, c_{1,t}
  + \mathcal{N}_{t-1} \, c_{2,t}}_{\text{uses}}
```

### Socially Optimal Steady State

Solving the planner's problem in steady state yields the following
condition on the optimal capital stock $\bar{k}^*$ (see
{cite}`blanchard&fischer:text`, Chapter 3):

```{math}
:label: social_optimum_foc

1 + f'(\bar{k}^*) = N \, \beth^{-1}
```

This equation says that the gross return on capital, $1 + f'(\bar{k}^*)$,
should equal the ratio of population growth to the social discount
factor.  A more patient planner (higher $\beth$) chooses a higher
capital stock.

With Cobb-Douglas production, we can solve
[the optimality condition](#social_optimum_foc) explicitly:

```{math}
:label: social_optimum_cd

\bar{k}^* = \left(
  \frac{N \, \beth^{-1} - 1}{\varepsilon}
\right)^{1/(\varepsilon - 1)}
```

The competitive steady state $\bar{k}$ depends on the household
discount factor $\beta$, while the social optimum $\bar{k}^*$
depends on the social discount factor $\beth$.  There is no reason
for these two capital stocks to coincide: the competitive equilibrium
may feature too much or too little capital relative to what a social
planner would choose.

```{code-cell} ipython3
def steady_state_social(epsilon, N, beth):
    """Steady-state capital chosen by the social planner."""
    return ((N / beth - 1) / epsilon)**(1 / (epsilon - 1))

beth = 0.99
k_bar = steady_state_competitive(epsilon, beta, N)
k_star = steady_state_social(epsilon, N, beth)

print(f"Competitive equilibrium:  k_bar  = {k_bar:.4f}")
print(f"Social optimum:           k_bar* = {k_star:.4f}")
```

## The Golden Rule and Dynamic Efficiency

### Maximizing Steady-State Consumption

Setting aside the planner's intertemporal tradeoff, we can ask an
even simpler question: what capital stock maximizes total per-capita
consumption in steady state?  Dividing the
[resource constraint](#aggregate_resource_constraint) by $\mathcal{N}_t$
and imposing steady-state conditions gives aggregate per-capita
consumption

```{math}
:label: per_capita_consumption

\bar{c} \equiv \bar{c}_1 + \frac{\bar{c}_2}{N} = f(\bar{k}) - n \, \bar{k}
```

where $n = N - 1$ is the net population growth rate.  The Golden
Rule capital stock $\bar{k}^{**}$ maximizes this expression:

```{math}
:label: golden_rule_foc

\max_{\bar{k}} \; \bigl[ f(\bar{k}) - n \, \bar{k} \bigr]
\quad \Longrightarrow \quad
f'(\bar{k}^{**}) = n
```

The first-order condition equates the marginal product of capital to
the net population growth rate.  At the Golden Rule, one additional
unit of capital raises output by exactly enough to equip the $n$
additional workers in the next generation.

With Cobb-Douglas production:

```{math}
:label: golden_rule_cd

\varepsilon \, (\bar{k}^{**})^{\varepsilon - 1} = n
\quad \Longrightarrow \quad
\bar{k}^{**} = (n / \varepsilon)^{1/(\varepsilon - 1)}
```

```{code-cell} ipython3
def steady_state_golden(epsilon, n):
    """Golden Rule capital stock maximizing steady-state consumption."""
    return (n / epsilon)**(1 / (epsilon - 1))
```

### Steady-State Consumption and Dynamic Inefficiency

The figure below plots steady-state per-capita consumption
$\bar{c} = f(\bar{k}) - n \bar{k}$ as a function of $\bar{k}$.
Three capital stocks are marked: the competitive equilibrium
$\bar{k}$, the Golden Rule $\bar{k}^{**}$, and the social
optimum $\bar{k}^*$.  The shaded region to the right of the Golden
Rule is the dynamically inefficient zone where additional capital
actually reduces aggregate consumption.

At the far right, consumption falls to zero at the capital stock
where all output is absorbed by equipping new workers:

```{math}
:label: k_zero_consumption

\bar{k}^\varepsilon = n \, \bar{k}
\quad \Longrightarrow \quad
\bar{k}_0 = n^{1/(\varepsilon - 1)}
```

```{code-cell} ipython3
n = N - 1
k_gold = steady_state_golden(epsilon, n)
k_zero = n**(1 / (epsilon - 1))

k_grid = np.linspace(0.001, min(k_zero * 1.1, 0.7), 400)
c_ss = k_grid**epsilon - n * k_grid

c_gold = k_gold**epsilon - n * k_gold
c_ce = k_bar**epsilon - n * k_bar
c_star = k_star**epsilon - n * k_star

fig, ax = plt.subplots()
ax.plot(k_grid, c_ss, 'b-', lw=2,
        label=r'$\bar{c} = f(\bar{k}) - n\,\bar{k}$')
ax.axhline(0, color='k', lw=0.5)

ax.plot(k_bar, c_ce, 'go', ms=10, zorder=5,
        label=rf'Competitive $\bar{{k}} = {k_bar:.3f}$')
ax.plot(k_star, c_star, 's', color='darkorange', ms=10, zorder=5,
        label=rf'Social optimum $\bar{{k}}^* = {k_star:.3f}$')
ax.plot(k_gold, c_gold, 'r*', ms=15, zorder=5,
        label=rf'Golden Rule $\bar{{k}}^{{**}} = {k_gold:.3f}$')

ax.fill_betweenx([0, c_gold * 1.15], k_gold, min(k_zero, k_grid[-1]),
                 color='red', alpha=0.08, label='Dynamically inefficient')
ax.axvline(k_gold, color='r', ls=':', alpha=0.4)

ax.set_xlabel(r'Steady-state capital $\bar{k}$')
ax.set_ylabel(r'Steady-state consumption $\bar{c}$')
ax.set_xlim(0, k_grid[-1])
ax.legend(fontsize=9, loc='upper right')
ax.grid(True, alpha=0.3)
plt.show()
```

The following table summarizes the three steady states and their
associated prices and consumption levels.

```{code-cell} ipython3
rows = []
for label, kv in [('Competitive $\\bar{k}$', k_bar),
                   ('Social optimum $\\bar{k}^*$', k_star),
                   ('Golden Rule $\\bar{k}^{**}$', k_gold)]:
    W_v = wage(kv, epsilon)
    R_v = interest_rate(kv, epsilon)
    c1_v = W_v / (1 + beta)
    c2_v = R_v * beta / (1 + beta) * W_v
    c_v = kv**epsilon - n * kv
    rows.append({'Steady state': label, 'k': kv, 'W': W_v, 'R': R_v,
                 'c1': c1_v, 'c2': c2_v, 'c_bar': c_v})

df = pd.DataFrame(rows).set_index('Steady state').round(4)
print(f"Zero-consumption capital:  k_0 = {k_zero:.4f}")
df
```

## Pareto Efficiency Across Generations

The Golden Rule divides the set of possible steady states into two
regions with very different welfare properties.

When $\bar{k} < \bar{k}^{**}$, the economy is **dynamically
efficient**.  Capital is scarce enough that its marginal product
exceeds the population growth rate, $f'(\bar{k}) > n$.  Reducing
capital would lower output by more than it saves in equipping new
workers, so there is no free lunch.  Raising one generation's
consumption necessarily comes at the expense of another.

When $\bar{k} > \bar{k}^{**}$, the economy is **dynamically
inefficient**.  Capital is so abundant that its marginal product
falls below the population growth rate, $f'(\bar{k}) < n$.  In
this case, a social planner can reduce saving, raise the consumption
of the current old generation, and simultaneously raise the
consumption of every future generation.  The mechanism is
straightforward: by accumulating less capital, society wastes fewer
resources on a factor whose return is below the growth rate of the
economy.

This observation has a striking implication.

:::{important}
In the dynamically inefficient region, the competitive equilibrium is
not Pareto efficient across generations.  There exists a feasible
reallocation that makes at least one generation strictly better off
without harming any other.  This is a genuine failure of the first
welfare theorem, arising because the OLG economy has a countable
infinity of agents.
:::

The failure arises because the OLG economy has a countable infinity
of agents (one generation per period, stretching into the infinite
future).  With finitely many agents, the first welfare theorem
guarantees efficiency under standard assumptions.  With infinitely
many agents, the argument breaks down: the "budget constraint of the
economy" involves an infinite sum, and Walras' law need not enforce
efficiency.

Under standard calibrations, however, the competitive equilibrium
tends to be dynamically efficient.  As we will see in the exercises
below, pushing $\bar{k}$ above $\bar{k}^{**}$ requires an
implausibly large discount factor $\beta$.

## CRRA Preferences

The log-utility analysis above admits a closed-form savings function
because income and substitution effects cancel exactly.  With general
CRRA preferences $u(c) = c^{1-\gamma}/(1-\gamma)$, $\gamma > 0$,
this cancellation no longer holds and the savings function depends on
the interest rate.

:::{seealso}
The CRRA utility function and the role of the intertemporal elasticity
of substitution $1/\gamma$ are developed in detail in
[Two-Period Consumption and Labor Supply](./consumption_two_period.md),
where the comparative statics of $\rho$ (the notation used there for
the CRRA parameter) on consumption growth are explored.
:::

The household's Euler equation gives optimal savings

```{math}
:label: crra_savings

s_t = \frac{W_t}{1 + \beta^{-1/\gamma}\,R_{t+1}^{(\gamma-1)/\gamma}}
```

When $\gamma > 1$, a higher interest rate raises savings (the
substitution effect dominates); when $\gamma < 1$, savings fall.
At $\gamma = 1$ the expression reduces to the log-utility savings
function [](#log_savings).

Because $R_{t+1} = \varepsilon\,k_{t+1}^{\varepsilon-1}$ depends on
$k_{t+1}$ itself, the law of motion $k_{t+1} = s_t / N$ is now an
implicit equation.  We solve it numerically using
`scipy.optimize.brentq`.  See {cite}`blanchard&fischer:text`,
Chapter 3, for further discussion of the CRRA extension.

```{code-cell} ipython3
def savings_crra(W, R, beta, gamma):
    """Optimal savings under CRRA utility with risk aversion gamma."""
    return W / (1 + beta ** (-1 / gamma) * R ** ((gamma - 1) / gamma))


def k_next_crra(k, epsilon, beta, N, gamma):
    """Solve the implicit law of motion for k_{t+1} under CRRA preferences."""
    def residual(k1):
        R1 = interest_rate(k1, epsilon)
        W = wage(k, epsilon)
        return savings_crra(W, R1, beta, gamma) / N - k1
    try:
        return optimize.brentq(residual, 1e-12, k**epsilon * 2 + 0.5)
    except ValueError:
        return np.nan
```

```{code-cell} ipython3
gamma_values = [0.5, 1.0, 2.0, 5.0]
k_grid_crra = np.linspace(1e-4, 0.15, 300)

fig, ax = plt.subplots(figsize=(6, 6))
ax.plot(k_grid_crra, k_grid_crra, 'k-', lw=1, alpha=0.7, label=r'$45^\circ$ line')

for gamma in gamma_values:
    k1_vals = np.array([k_next_crra(kv, epsilon, beta, N, gamma)
                        for kv in k_grid_crra])
    lbl = rf'$\gamma = {gamma}$'
    if gamma == 1.0:
        lbl += ' (log)'
    ax.plot(k_grid_crra, k1_vals, lw=2, label=lbl)

ax.set_xlabel('$k_t$')
ax.set_ylabel('$k_{t+1}$')
ax.set_xlim(0, 0.15)
ax.set_ylim(0, 0.15)
ax.legend(frameon=False, fontsize=9)
ax.grid(True, alpha=0.3)
ax.set_title('Law of motion under CRRA preferences')
plt.show()
```

## Exercises

```{exercise}
:label: ex_three_steady_states

Using the per-generation calibration $\varepsilon = 0.33$,
$\beta = 0.96$, $N = 2.5$, and $\beth = 0.99$, compute the three
steady-state capital levels: $\bar{k}$ (competitive equilibrium),
$\bar{k}^*$ (social optimum), and $\bar{k}^{**}$ (Golden Rule).

Display the results in a bar chart.  Which capital stock is largest?
Is the competitive equilibrium dynamically efficient?
```

```{solution-start} ex_three_steady_states
:class: dropdown
```

```{code-cell} ipython3
epsilon, beta, N, beth = 0.33, 0.96, 2.5, 0.99
n = N - 1

k_ce = steady_state_competitive(epsilon, beta, N)
k_so = steady_state_social(epsilon, N, beth)
k_gr = steady_state_golden(epsilon, n)

print(f"Competitive equilibrium:  k_bar   = {k_ce:.4f}")
print(f"Social optimum:           k_bar*  = {k_so:.4f}")
print(f"Golden Rule:              k_bar** = {k_gr:.4f}")
print()
if k_ce < k_gr:
    print("The competitive equilibrium is dynamically efficient (k_bar < k_bar**).")
else:
    print("The competitive equilibrium is dynamically INEFFICIENT (k_bar >= k_bar**).")
```

```{code-cell} ipython3
labels = [r'$\bar{k}$' + '\n(competitive)',
          r'$\bar{k}^*$' + '\n(social)',
          r'$\bar{k}^{**}$' + '\n(golden rule)']
values = [k_ce, k_so, k_gr]
colors = ['#2196F3', '#FF9800', '#F44336']

fig, ax = plt.subplots()
bars = ax.bar(labels, values, color=colors, width=0.5)
for bar, v in zip(bars, values):
    ax.text(bar.get_x() + bar.get_width() / 2, v + 0.002,
            f'{v:.4f}', ha='center', fontsize=10)
ax.set_ylabel('Capital per young worker')
ax.grid(True, alpha=0.3, axis='y')
plt.tight_layout()
plt.show()
```

```{solution-end}
```

```{exercise}
:label: ex_vary_beth

How does the social planner's optimal capital $\bar{k}^*$ change as
$\beth$ varies from 0.90 to 0.999?  Plot $\bar{k}^*$ against $\beth$
and include horizontal lines for $\bar{k}$ (competitive equilibrium)
and $\bar{k}^{**}$ (Golden Rule).  What happens as $\beth \to 1$?
What happens as $\beth \to N^{-1}$?
```

```{solution-start} ex_vary_beth
:class: dropdown
```

```{code-cell} ipython3
beth_vals = np.linspace(0.90, 0.999, 200)
k_so_vals = np.array([steady_state_social(epsilon, N, b) for b in beth_vals])

fig, ax = plt.subplots()
ax.plot(beth_vals, k_so_vals, 'b-', lw=2, label=r"$\bar{k}^*(\beth)$")
ax.axhline(k_ce, color='green', ls='--',
           label=rf'$\bar{{k}}$ (competitive) $= {k_ce:.4f}$')
ax.axhline(k_gr, color='red', ls='--',
           label=rf'$\bar{{k}}^{{**}}$ (golden rule) $= {k_gr:.4f}$')
ax.set_xlabel(r'Social discount factor $\beth$')
ax.set_ylabel('Steady-state capital')
ax.legend(fontsize=9)
ax.grid(True, alpha=0.3)
plt.show()
```

As $\beth$ increases toward 1, the planner cares almost as much about
distant future generations as about the current one.  The socially
optimal capital stock rises, approaching the Golden Rule.  In the
limit $\beth = 1$, the planner's optimality condition
([](#social_optimum_foc)) gives $1 + f'(\bar{k}^*) = N$, or
equivalently $f'(\bar{k}^*) = n$, which is exactly the Golden Rule
condition ([](#golden_rule_foc)).

As $\beth$ falls toward $N^{-1} = 1/2.5 = 0.4$, the right-hand
side of [the optimality condition](#social_optimum_foc) grows without
bound, so the optimal $\bar{k}^*$ falls toward zero: a very impatient
planner barely invests.

```{solution-end}
```

```{exercise}
:label: ex_critical_beta

Continuing with $\varepsilon = 0.33$ and $N = 2.5$, find the
critical household discount factor $\beta_{\text{crit}}$ at which the
competitive steady state equals the Golden Rule:
$\bar{k}(\beta_{\text{crit}}) = \bar{k}^{**}$.  For any
$\beta > \beta_{\text{crit}}$, the competitive equilibrium is
dynamically inefficient.

Use `scipy.optimize.brentq` to solve for $\beta_{\text{crit}}$.  Is
the resulting value realistic?
```

```{solution-start} ex_critical_beta
:class: dropdown
```

```{code-cell} ipython3
def gap(beta_val):
    return steady_state_competitive(epsilon, beta_val, N) - steady_state_golden(epsilon, n)

beta_crit = optimize.brentq(gap, 0.5, 50.0)
print(f"Critical beta:  beta_crit = {beta_crit:.4f}")
print(f"For beta > {beta_crit:.2f}, the economy is dynamically inefficient.")
print()
print("Verification:")
print(f"  k_bar(beta_crit) = {steady_state_competitive(epsilon, beta_crit, N):.6f}")
print(f"  k_bar**          = {steady_state_golden(epsilon, n):.6f}")
```

The critical discount factor is approximately 4.58, far above 1.
A per-generation discount factor of $\beta = 0.96$ (the baseline
calibration) implies that households discount the future at a modest
rate.  Even converting from annual to generational rates,
$0.96^{30} \approx 0.29$, the result is well below
$\beta_{\text{crit}}$.

Achieving dynamic inefficiency in this model would require households
to be extraordinarily patient, valuing old-age consumption nearly
five times as much as young-age consumption.  Under any conventional
calibration the competitive equilibrium is dynamically efficient.

```{solution-end}
```
