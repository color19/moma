---
title: Snow Day
short_title: Lecture 02
subtitle: Modeling Macroeconomics | Lecture 02
label: lecture-02
date: 2025-01-27
description: Virtual session covering repository syncing, course website updates, JupyterLab notebooks, and DataCamp assignments.
tags:
  - snow-day
  - virtual
  - Jupyter
  - consumption
---

:::{warning} Schedule Change
Class will not meet in person today due to a snow day. We will hold a shortened virtual session instead.

- **Virtual meeting:** 1:00 pm to 2:00 pm
- **Zoom link:** Sent via email and Canvas announcement
:::

## Learning Objectives

By the end of this session, students will be able to:

1. Pull upstream changes and sync their local project
2. Fork the course repository to preserve personal changes
3. Navigate the updated course website and its interactive notebooks
4. Use Jupyter notebooks for computational work
5. Preview the course site locally
6. Understand DataCamp assignment expectations and workflow

## Part 1: Syncing Your Repository

The course repository is maintained by the instructor. When you pull changes, you are downloading the latest course materials, including new lectures, notebooks, and updated dependencies.

### Pull Changes

In GitHub Desktop, click **Fetch origin** and then **Pull origin** to download the latest updates.

From the command line:

```bash
cd ~/github/moma
git pull
```

### Sync Dependencies

After pulling, sync your environment to install any new packages:

```bash
uv sync
```

This ensures your local environment matches the project's updated `pyproject.toml`. This week, the updated dependencies include `jupytext` (for opening Markdown files as notebooks) and `jupyterlab-myst` (for rendering MyST Markdown in JupyterLab).

### Forking for Your Own Work

:::{important}
Pulling from the instructor's repository gives you read-only access to the course materials. If you want to make and save your own changes (notes, experiments, modified notebooks) while continuing to receive upstream updates, you should **fork** the repository:

1. Go to [github.com/jhu-econ/moma](https://github.com/jhu-econ/moma) and click **Fork**
2. Clone your fork to `~/github/moma`
3. Add the instructor's repository as an upstream remote:

```bash
git remote add upstream https://github.com/jhu-econ/moma.git
```

4. To pull new course materials into your fork:

```bash
git fetch upstream
git merge upstream/main
```

This way your personal changes are preserved on your fork, and you can still pull the latest course content.
:::

## Part 2: Course Website Updates

The course website at [jhu-econ.github.io/moma](https://jhu-econ.github.io/moma) has been updated with new content, including interactive notebooks that run directly in the browser.

### Interactive Notebooks

Several pages on the course website now include executable code cells powered by [MyBinder](https://mybinder.org/). MyBinder provides free cloud computing resources so you can run Python code without installing anything on your machine.

To launch a notebook interactively, click the power button at the top of any notebook page on the website. MyBinder builds a temporary environment with all the necessary packages and lets you execute and modify code cells directly in the browser.

:::{note}
MyBinder sessions are temporary. Any changes you make in a MyBinder session are not saved. Use it for exploration and practice, but do your graded work in your local environment.
:::

### Previewing the Site Locally

You can preview the full course website on your own machine:

```bash
uv run myst start
```

This launches a local development server. Open the URL shown in the terminal (typically `http://localhost:3000`) to browse the site. Changes to `.md` files will update in real time.

## Part 3: JupyterLab and Interactive Notebooks

Now that we have seen the notebooks rendered on the website, we will open them locally in JupyterLab.

### Launching JupyterLab

From your `~/github/moma` directory:

```bash
uv run jupyter lab
```

### Opening Markdown Files as Notebooks

In the JupyterLab file browser, navigate to `quantecon/foundations/` and click on one of the `.md` files (for example, `numpy.md`). It opens as a plain text file — just a flat Markdown document.

Now, right-click the same file and select **Open With > Notebook**. The file opens as an interactive Jupyter notebook. This works because `jupytext` (added as a project dependency and installed via `uv sync`) recognizes the notebook metadata embedded in these Markdown files. MyST directives like admonitions and math blocks render properly thanks to `jupyterlab-myst`.

Once open as a notebook, you can:

- Run cells one at a time with {kbd}`Shift+Enter`
- Modify code and re-run to see how the output changes
- Add new cells to experiment
- Save your changes locally

:::{tip}
The `.md` source file stays clean and version-control friendly, while JupyterLab gives you the full interactive notebook experience. Use this workflow to explore the course materials at your own pace.
:::

### Using Notebooks in VS Code

You can also work with notebooks directly in VS Code:

1. Open VS Code in your `moma` folder
2. Create a new file with the `.ipynb` extension
3. Select the Python kernel when prompted
4. Use {kbd}`Shift+Enter` to run a cell and advance to the next one

## Part 4: DataCamp Assignments

We will walk through the DataCamp platform and discuss expectations for the interactive Python assignments.

- How to access DataCamp through the course
- Assignment structure and deadlines
- How DataCamp grades contribute to your final grade (10%)

## Reading Assignment

:::{attention} Required Reading
Before Lecture 3, read the following chapters from the course textbook [A Gentle Introduction to Intertemporal Choice](https://jhu-econ.github.io/intertemporal-choice/):

1. [The Period Life Cycle Model](https://jhu-econ.github.io/intertemporal-choice/content/consumption/periodlcmodel/)
2. [Consumption and Labor Supply](https://jhu-econ.github.io/intertemporal-choice/content/consumption/consandlaborsupply/)
3. [The Overlapping Generations Model](https://jhu-econ.github.io/intertemporal-choice/content/consumption/olgmodel/)
4. [The Envelope Condition](https://jhu-econ.github.io/intertemporal-choice/content/consumption/envelope/)

These readings introduce the consumption theory foundations for Chapter 1, which covers dynamic optimization, Euler equations, and Bellman equations.
:::

## Homework

:::{attention} Assignment: DataCamp
Complete [Intermediate Python](https://app.datacamp.com/learn/courses/intermediate-python) on DataCamp.

**Due:** Check Canvas for the deadline.
:::

:::{tip} Course Materials
- Course website: [jhu-econ.github.io/moma](https://jhu-econ.github.io/moma)
- Textbook: [A Gentle Introduction to Intertemporal Choice](https://jhu-econ.github.io/intertemporal-choice/)
:::
