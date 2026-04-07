---
title: Midterm Study Guide
short_title: Lecture 07
subtitle: Modeling Macroeconomics | Lecture 07
label: lecture-07
date: 2026-03-03
description: Cumulative study guide covering Lectures 03 through 07, from the Fisher two-period model through asset pricing and the equity premium puzzle.
tags:
  - study guide
  - intertemporal choice
  - consumption theory
  - asset pricing
  - C-CAPM
  - equity premium puzzle
---

## Materials

- [Slides: Asset Pricing](/slides/m07/asset-pricing-slides.html)

This study guide covers the key concepts, results, and equations from Lectures 03 through 07. Derivations are omitted; focus on understanding what each result says and when it applies.

---

## Intertemporal Choice (Lecture 03)

### The Fisher Two-Period Model

- A consumer allocates resources across two periods to maximize $u(c_1) + \beta\,u(c_2)$
- The intertemporal budget constraint: the PDV of spending equals nonhuman wealth $b_1$ plus human wealth $h_1 = y_1 + y_2/R$
- **The Euler equation:**

$$u'(c_1) = R\beta\,u'(c_2)$$

- Perturbation argument: at the optimum, the consumer is indifferent between consuming one more unit today and saving it for tomorrow

### CRRA Utility and the IES

- CRRA utility: $u(c) = c^{1-\rho}/(1-\rho)$, marginal utility $u'(c) = c^{-\rho}$
- **Consumption growth:** $(c_2/c_1) = (R\beta)^{1/\rho}$
- The IES is $1/\rho$: how strongly the consumption ratio responds to a change in $R$
- **Fisherian separation:** consumption growth depends on $R$ and $\beta$, not on the timing of income

### Three Effects of a Change in $R$

- **Substitution:** future consumption is cheaper $\Rightarrow$ save more ($c_1 \downarrow$)
- **Income:** higher return on savings $\Rightarrow$ richer ($c_1 \uparrow$)
- **Human wealth:** PDV of future labor income falls ($c_1 \downarrow$)
- Summers (1981): the human wealth effect dominates quantitatively for most consumers

### Labor Supply

- Cobb-Douglas preferences keep the expenditure share on leisure constant as wages rise
- The model predicts strong labor supply responses to predictable wage variation; the data show near-constant hours
- This is the "small intertemporal elasticity of labor supply" puzzle

### The OLG Model

- Young workers save, old retirees consume; no bequests; two generations alive at any time
- With log utility, the saving rate $\beta/(1+\beta)$ is independent of $R$
- **Capital accumulation:** $k_{t+1} = \mathcal{Q}\,k_t^\varepsilon$ converges to steady state $\bar{k} = \mathcal{Q}^{1/(1-\varepsilon)}$
- **Golden Rule:** $f'(\bar{k}^{**}) = n$ maximizes steady-state per-capita consumption
- The competitive equilibrium can be dynamically inefficient (too much capital)

---

## Consumption Theory (Lecture 04)

### The Envelope Condition

- In the $T$-period Bellman equation, the envelope theorem gives:

$$v'(m_t) = u'(c_t)$$

- Marginal value of resources = marginal utility of consumption
- This extends the Euler equation $u'(c_t) = R\beta\,u'(c_{t+1})$ to any finite or infinite horizon

### Perfect Foresight CRRA

- Consumption grows at the **absolute patience factor** $\Phi = (R\beta)^{1/\rho}$ every period
- Three conditions for a well-behaved infinite-horizon solution:
  - **AIC** ($\Phi < 1$): consumption falls over time (absolute impatience)
  - **FHWC** ($G < R$): human wealth is finite
  - **RIC** ($\Phi/R < 1$): the PDV of desired consumption is finite
- **The consumption function** is linear in overall wealth $o_t = b_t + h_t$:

$$c_t = \underbrace{(1 - \Phi/R)}_{\kappa}\,o_t$$

- The GIC ($\Phi < G$) determines whether the wealth-to-income ratio is falling

### The Random Walk of Consumption

- Quadratic utility + $R\beta = 1$ $\Rightarrow$ $\mathbb{E}_t[c_{t+1}] = c_t$
- Hall (1978): no lagged variable should predict consumption changes
- Powerful because it is model-free (no need to specify the income process)
- Fails with CRRA utility or when $R\beta \neq 1$
- Quadratic utility has $u''' = 0$, so the random walk model rules out precautionary saving

### The Consumption Function and Muth's Insight

- With permanent ($\psi_t$) and transitory ($\theta_t$) shocks:

$$c_t = \frac{r}{R}(b_t + \theta_t) + p_t$$

- **MPC out of transitory income:** $r/R \approx 5\%$
- **MPC out of permanent income:** $1$ (one for one)
- The Keynesian $c = \alpha_0 + \alpha_1 y$ is meaningless without specifying which type of shock changed income

---

## Advanced Consumption Models (Lecture 05)

### Habit Formation

- Past consumption raises a reference point; higher habits make any given $c_t$ less satisfying
- The consumer accounts for the cost of raising future habits, which pushes consumption *down* relative to the standard model
- **Modified Euler equation:**

$$u^c_t + \beta\,u^h_{t+1} = R\beta\left[u^c_{t+1} + \beta\,u^h_{t+2}\right]$$

- With $u(c,h) = f(c - \alpha h)$, consumption growth is positively autocorrelated: $\Delta\log c_{t+1} \approx \text{const} + \alpha\,\Delta\log c_t$

### Durable Goods

- The stock $d_t$ yields utility; expenditure $x_t = d_t - (1-\delta)d_{t-1}$ is a flow
- **Intratemporal condition:**

$$u^d_t = \frac{r + \delta}{R}\,u^c_t$$

- The marginal utility of the durable is *lower* than that of the nondurable because it yields service over multiple periods
- With Cobb-Douglas utility, $d/c = \gamma$ is constant
- **Spending is volatile:** a small consumption adjustment of size $\epsilon$ multiplies durable expenditure by a factor of $(\epsilon + \delta)/\delta$

### Quasi-Hyperbolic Discounting (Laibson)

- An extra discount factor $\delta_h < 1$ ($\approx 0.7$) applies to the step from "now" to "all of the future"
- The present-biased consumer consumes more than the standard consumer
- The distortion scales with the MPC: high-MPC consumers (young, poor, constrained) suffer the most from present bias
- Low-MPC consumers (wealthy, long horizon) are barely affected

---

## Risk and Consumption (Lecture 06)

### CRRA with Risky Returns

- With a single risky asset (lognormal), no labor income, and $c_t = \kappa\,m_t$:

$$\kappa = 1 - \left(\beta\,\mathbb{E}[\tilde{R}^{1-\rho}]\right)^{1/\rho}$$

- **Approximate MPC** decomposes into three forces:

$$\kappa \approx \underbrace{\tilde{r}}_{\text{income}} - \underbrace{\rho^{-1}(\tilde{r} - \vartheta)}_{\text{substitution}} - \underbrace{(\rho-1)\sigma_r^2/2}_{\text{precautionary}}$$

- More risk ($\sigma_r^2 \uparrow$) lowers the MPC $\Rightarrow$ more saving (for $\rho > 1$)
- Log utility ($\rho = 1$) is a knife-edge where risk does not affect consumption

### CARA with Income Risk

- CARA utility $u(C) = -(1/\alpha)e^{-\alpha C}$ yields additive consumption changes
- **Consumption under uncertainty:**

$$C_{t+1} = C_t + \alpha^{-1}\log(R\beta) + \frac{\alpha\sigma_\Psi^2}{2} + \Psi_{t+1}$$

- The precautionary premium $\alpha\sigma_\Psi^2/2$ does not depend on wealth
- The MPC out of bank balances is $r/R$, independent of impatience

### Campbell-Mankiw (Time-Varying $R$)

- Log-linearization relates the log consumption-wealth ratio to future log interest rates:

$$c_t - w_t = (1 - \rho^{-1})\sum_{j=1}^{\infty}\xi^j\,r_{t+j} + \text{const}$$

- $(1 - \rho^{-1})$ governs the net effect:
  - $\rho < 1$: substitution dominates (save more)
  - $\rho = 1$: effects cancel
  - $\rho > 1$: income dominates (consume more)
- The human wealth channel $H_t \approx Y_t/(r-g)$ can dwarf the direct effects

---

## Asset Pricing (Lecture 07)

### The Lucas Tree Model

- An endowment economy: identical consumers hold identical trees; output is exogenous fruit
- Market clearing: $c_t = d_t$ (all fruit is eaten; you cannot plant more trees)
- **The stochastic discount factor** prices every asset:

$$\mathcal{M}_{t,t+n} = \beta^n \frac{u'(d_{t+n})}{u'(d_t)}$$

- **Asset price as PDV of dividends:**

$$P_t = \mathbb{E}_t\left[\sum_{n=1}^{\infty}\mathcal{M}_{t,t+n}\,d_{t+n}\right]$$

- With **log utility**: $P_t = d_t/\vartheta$ (income and substitution effects cancel exactly)
- **Gordon formula** (constant growth): $P_t \approx d_t/(r - g)$
- Prices follow a martingale: all known information is already in the price

### The Fallacy of Composition

- Any individual can save one more dollar and earn $\mathbf{R}$
- If everyone saves one more dollar, aggregate fruit is unchanged; the market clears through higher tree prices, not more output
- This distinction between individual and aggregate is central to the Lucas model

### Portfolio Choice

- **CARA:** optimal dollar investment $S = \phi/(\alpha\sigma^2)$ is independent of wealth (Buffett and Homer Simpson hold the same dollar position, which is implausible)
- **CRRA (Merton-Samuelson):** optimal portfolio *share* is independent of wealth:

$$\varsigma = \frac{\phi}{\rho\,\sigma_r^2}$$

- Surprising: portfolio risk *falls* when asset risk rises, because the consumer cuts exposure so aggressively
- After portfolio optimization, the MPC becomes:

$$\kappa \approx r^f - \rho^{-1}(r^f - \vartheta) + (\rho - 1)\frac{(\phi/\rho)^2}{2\sigma_r^2}$$

### The Consumption CAPM (C-CAPM)

- The expected excess return on any asset satisfies:

$$\mathbb{E}[\mathbf{R}_i] - R^f \approx \rho\,\text{cov}(\Delta\log c,\,\mathbf{R}_i)$$

- Only consumption covariance matters for pricing; the asset's own variance is irrelevant
- **Procyclical assets** (pay off when $c$ is high, $u'$ is low): must offer higher returns
- **Countercyclical assets**: expensive, low returns (they are insurance)

### The Equity Premium and Riskfree Rate Puzzles

- Equity premium puzzle: $0.08 \approx \rho \times 0.004$ requires $\rho \approx 20$
- Riskfree rate puzzle: $0.015 \approx 0.01/\rho$ requires $\rho < 1$
- The two puzzles demand opposite values of $\rho$; this is what makes the joint puzzle so hard
- Proposed resolutions: habit formation, rare disasters, long-run consumption risk, limited participation

### Rational Bubbles

- The Euler equation admits $P_t = P_t^* + B_t$ where $B_t$ grows at rate $R^f$
- **Blanchard (1979):** stochastically bursting bubbles grow faster than $R^f$ while alive to compensate for crash risk; every such bubble eventually bursts
- Arguments against: no negative bubbles, reproducible assets cap prices, risk aversion makes bubbles harder to sustain, GE prevents the bubble from exceeding total wealth

---

## Upcoming

:::{attention} Midterm Exam
The next lecture is the midterm exam. This study guide covers all material that may appear on the exam (Lectures 03--07).

**Format:**

- **30 multiple choice questions** covering concepts, definitions, and interpretation of results
- **10 free response questions** including short math derivations, fill-in-the-blank, and short written explanations
:::

:::{attention} Assignment 1: Computational Notebook
The first major computational assignment on consumption is due after spring break. Details are posted on Canvas.

**Due:** Check Canvas for the deadline.
:::

:::{attention} DataCamp
All DataCamp assignments should be completed by now. If you are behind, see [Lecture 01](./lecture_01.md) through [Lecture 06](./lecture_06.md) for the full list.
:::

:::{tip} Course Materials
- Course website: [jhu-econ.github.io/moma](https://jhu-econ.github.io/moma)
- Textbook: [A Gentle Introduction to Intertemporal Choice](https://jhu-econ.github.io/intertemporal-choice/)
:::
