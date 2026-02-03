# Dynamic Stochastic General Equilibrium Modeling

**ECON 624 | Modeling Macroeconomics (MoMa)**

*Modern macroeconomic modeling is an art. And math... and code. Lots of code.*

Course materials for ECON 624 at Johns Hopkins University.

This course offers a rigorous introduction to modern macroeconomic theory, building dynamic models from first principles through the intertemporal optimization problems of households and firms. We cover the foundations of consumption theory, asset pricing, investment, and economic growth, culminating in Dynamic Stochastic General Equilibrium (DSGE) frameworks for understanding business cycles and policy effects.

The course emphasizes both analytical and computational methods, with extensive use of mathematical derivations complemented by numerical analysis using Python.

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/jhu-econ/moma.git
cd moma
```

### 2. Install uv

Follow the instructions at [docs.astral.sh/uv](https://docs.astral.sh/uv/getting-started/installation/), or:

```bash
# macOS/Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows (PowerShell)
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

### 3. Install dependencies

```bash
uv sync
```

### 4. Preview the site

```bash
uv run myst start
```

### 5. Run notebooks interactively

```bash
uv run jupyter lab
```

Then right-click any `.md` file and select **Open With > Notebook**.

For slides, see [slides/README.md](slides/README.md) for Quarto installation.

## Topics

- Consumption theory and dynamic optimization
- Asset pricing
- Investment
- Economic growth
- DSGE models and business cycles

## Author

Alan Lujan
Applied Economics, Krieger School of Arts and Sciences
Johns Hopkins University

## License

This work is licensed under [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/).
